//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim, Cheol Ju. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//      Cheol Ju      <moosoy@gmail.com>
//
//  This file is part of Movist.
//
//  Movist is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 3 of the License, or
//  (at your option) any later version.
//
//  Movist is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "MMovie_FFmpeg.h"
#import "FFTrack.h"
#import "FFIndexer.h"

#if defined(DEBUG)
void traceAVFormatContext(AVFormatContext* formatContext)
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableString* s = [NSMutableString stringWithCapacity:256];
    
    [s setString:@"  - format: "];
    [s appendFormat:@"%s", formatContext->iformat->name];
    TRACE(s);
    
    [s setString:@"  - duration: "];
    if (formatContext->duration == AV_NOPTS_VALUE) {
        [s appendString:@"N/A"];
    }
    else {
        int seconds = formatContext->duration / AV_TIME_BASE;
        int us      = formatContext->duration % AV_TIME_BASE;
        int minutes = seconds / 60;
        [s appendFormat:@"%02d:%02d:%02d.%01d",
         minutes / 60, minutes % 60, seconds % 60, (10 * us) / AV_TIME_BASE];
    }
    TRACE(s);
    
    [s setString:@"  - start: "];
    if (formatContext->start_time != AV_NOPTS_VALUE) {
        int seconds = formatContext->start_time / AV_TIME_BASE;
        int us      = formatContext->start_time % AV_TIME_BASE;
        [s appendFormat:@"%d.%06d",
         seconds, (int)av_rescale(us, 1000000, AV_TIME_BASE)];
        TRACE(s);
    }
    
    [s setString:@"  - bit-rate: "];
    if (formatContext->bit_rate == 0) {
        [s appendString:@"N/A"];
    }
    else {
        [s appendFormat:@"%d kb/s", formatContext->bit_rate / 1000];
    }
    TRACE(s);
    
    int i;
    char buf[256];
    AVStream* stream;
    for (i = 0; i < formatContext->nb_streams; i++) {
        stream = formatContext->streams[i];
        [s setString:@""];
        [s appendFormat:@"  - stream #%d", i];
        
        if (formatContext->iformat->flags & AVFMT_SHOW_IDS) {
            [s appendFormat:@"[0x%x]", stream->id];
        }
        if (stream->language[0] != '\0') {
            [s appendFormat:@"(%s)", stream->language];
        }
        
        avcodec_string(buf, sizeof(buf), stream->codec, 1);
        [s appendFormat:@": %s", buf];
        
        if (stream->codec->codec_type == CODEC_TYPE_VIDEO) {
            if (stream->r_frame_rate.den && stream->r_frame_rate.num) {
                [s appendFormat:@", %5.2f fps(r)", av_q2d(stream->r_frame_rate)];
            }
            else {
                [s appendFormat:@", %5.2f fps(c)", 1 / av_q2d(stream->codec->time_base)];
            }
        }
        TRACE(s);
    }
}
#else
#define traceAVFormatContext(fc)
#endif  // DEBUG

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie_FFmpeg

+ (NSString*)name { return @"FFmpeg"; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo
  digitalAudioOut:(BOOL)digitalAudioOut error:(NSError**)error
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, [url absoluteString]);
    if (![url isFileURL]) {
        *error = [NSError errorWithDomain:[MMovie_FFmpeg name]
                                     code:10000  // FIXME
                                 userInfo:nil];
        return nil;
    }

    if (self = [super initWithURL:url movieInfo:movieInfo
                  digitalAudioOut:digitalAudioOut error:error]) {
        _formatContext = movieInfo->formatContext;
        traceAVFormatContext(_formatContext);

        int errorCode;
        if (![self initAVCodec:&errorCode digitalAudioOut:digitalAudioOut] ||
            ![self initPlayback:&errorCode]) {
            *error = [NSError errorWithDomain:[MMovie_FFmpeg name]
                                         code:errorCode userInfo:nil];
            [self release];
            return nil;
        }

        _running = FALSE;
        _currentTime = 0;
        _lastDecodedTime = 0;
        _hostTimeFreq = CVGetHostClockFrequency();
        //TRACE(@"host time frequency %f", s_hostTimeFreq);
        _avFineTuningTime = 0;

        [self setAspectRatio:_aspectRatio]; // for _adjustedSize

        // rebuilding index if needed
        BOOL needsIndexing = FALSE;
        if (strstr(_formatContext->iformat->name, "avi")) {
            needsIndexing = ![_mainVideoTrack isIndexComplete];
        }
        if (!needsIndexing) {
            _indexedDuration = _duration;
        }
        else {
            _indexedDuration = 0;
            _indexer = [[FFIndexer alloc] initWithMovie:self
                                          formatContext:_formatContext
                                            streamIndex:[_mainVideoTrack streamIndex]
                                         frameReadMutex:_frameReadMutex];
        }
    }
    return self;
}

- (void)cleanup
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _quitRequested = TRUE;

    [_indexer waitForFinish];
    [_indexer release];

    [self cleanupPlayback];
    [self cleanupAVCodec];

    av_close_input_file(_formatContext);
    _formatContext = 0;
    
    [super cleanup];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)initAVCodec:(int*)errorCode digitalAudioOut:(BOOL)digitalAudioOut
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _trackMutex = [[NSLock alloc] init];
    MTrack* track;
    FFVideoTrack* vTrack;
    NSEnumerator* enumerator = [_videoTracks objectEnumerator];
    while (track = (MTrack*)[enumerator nextObject]) {
        vTrack = (FFVideoTrack*)[track impl];
        if ([vTrack initTrack:errorCode]) {
            if (!_mainVideoTrack) {
                _mainVideoTrack = vTrack;
            }
            [track setEnabled:vTrack == _mainVideoTrack];
        }
        else {
            [track setEnabled:FALSE];
        }
        [vTrack setMovie:self];
        [track setMovie:self];
    }
    BOOL passThrough = FALSE;
    FFAudioTrack* aTrack;
    enumerator = [_audioTracks objectEnumerator];
    while (track = (MTrack*)[enumerator nextObject]) {
        aTrack = (FFAudioTrack*)[track impl];
        passThrough = digitalAudioOut && [aTrack isAc3Dts];
        if ([aTrack initTrack:errorCode passThrough:passThrough]) {
            if (!_mainAudioTrack) {
                _mainAudioTrack = aTrack;
            }
            [track setEnabled:aTrack == _mainAudioTrack];
        }
        else {
            [track setEnabled:FALSE];
        }
        [aTrack setSpeakerCount:2]; // FIXME
        [aTrack setMovie:self];
        [track setMovie:self];
    }
    return (0 != _mainVideoTrack);
}

- (void)cleanupAVCodec
{
    MTrack* track;
    NSEnumerator* enumerator = [_videoTracks objectEnumerator];
    FFVideoTrack* videoTrack;
    while (track = [enumerator nextObject]) {
        videoTrack = (FFVideoTrack*)[track impl];
        [_trackMutex lock];
        if (videoTrack == _mainVideoTrack) {
            _mainVideoTrack = 0;
        }
        [videoTrack cleanupTrack];
        [videoTrack waitForFinish];
        [_trackMutex unlock];
    }

    enumerator = [_audioTracks objectEnumerator];
    while (track = [enumerator nextObject]) {
        [(FFTrack*)[track impl] cleanupTrack];
        [(FFTrack*)[track impl] waitForFinish];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)trackEnabled:(MTrack*)track
{
    if (![track isVideoTrack]) {
        FFAudioTrack* aTrack = (FFAudioTrack*)[track impl];
        [aTrack startAudio];
        if (!_mainAudioTrack) {
            _mainAudioTrack = aTrack;
        }
    }
    [super trackEnabled:track];
}

- (void)trackDisabled:(MTrack*)track
{
    if ([track isVideoTrack]) {
        FFVideoTrack* vTrack = (FFVideoTrack*)[track impl];
        if (vTrack == _mainVideoTrack) {
            NSEnumerator* enumerator = [_videoTracks objectEnumerator];
            while (vTrack = [enumerator nextObject]) {
                if ([vTrack isEnabled]) {
                    break;
                }
            }
            assert(vTrack != 0);
            _mainVideoTrack = vTrack;
        }
    }
    else {
        [(FFAudioTrack*)[track impl] stopAudio];

        FFAudioTrack* aTrack = (FFAudioTrack*)[track impl];
        if (aTrack == _mainAudioTrack) {
            NSEnumerator* enumerator = [_audioTracks objectEnumerator];
            while (aTrack = [enumerator nextObject]) {
                if ([aTrack isEnabled]) {
                    break;
                }
            }
            // _mainAudioTrack can be null;
            _mainAudioTrack = aTrack;
        }
    }
    [super trackEnabled:track];
}

- (void)indexingFinished
{
    [_indexer release];
    _indexer = nil;

    [super indexingFinished];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)supportsAC3DigitalOut { return TRUE; }
- (BOOL)supportsDTSDigitalOut { return TRUE; }

- (void)setVolume:(float)volume
{
    NSEnumerator* enumerator = [_audioTracks objectEnumerator];
    FFAudioTrack* aTrack;
    while (aTrack = (FFAudioTrack*)[[enumerator nextObject] impl]) {
        [aTrack setVolume:volume];
    }
    [super setVolume:volume];
}

- (void)setMuted:(BOOL)muted
{
    NSEnumerator* enumerator = [_audioTracks objectEnumerator];
    FFAudioTrack* aTrack;
    float volume = muted ? 0 : _volume;
    while (aTrack = (FFAudioTrack*)[[enumerator nextObject] impl]) {
        [aTrack setVolume:volume];
    }
    [super setMuted:muted];
}


@end

//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim, Cheol Ju. All rights reserved.
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

@implementation MTrack_FFmpeg

+ (id)trackWithMovie:(MMovie*)movie formatContext:(AVFormatContext*)formatContext
         streamIndex:(int)streamIndex streamId:(int)streamId
{
    MTrack_FFmpeg* track = [MTrack_FFmpeg alloc];
    return [[track initWithMovie:movie formatContext:formatContext
                     streamIndex:streamIndex streamId:streamId] autorelease];
}

- (id)initWithMovie:(MMovie*)movie formatContext:(AVFormatContext*)formatContext
        streamIndex:(int)streamIndex streamId:(int)streamId
{
    if (self = [super initWithMovie:movie]) {
        _streamId = streamId;

        if (streamId < 0) { // video
            _name = NSLocalizedString(@"Video Track", nil);
            NSSize ds = [movie displaySize], es = [movie encodedSize];
            if (NSEqualSizes(ds, es)) {
                _summary = [NSString stringWithFormat:@"%@, %d x %d",
                            videoCodecDescription([movie videoCodecId]),
                            (int)ds.width, (int)ds.height];
            }
            else {
                _summary = [NSString stringWithFormat:@"%@, %d x %d (%d x %d)",
                            videoCodecDescription([movie videoCodecId]),
                            (int)ds.width, (int)ds.height, (int)es.width, (int)es.height];
            }
        }
        else {              // audio
            _name = NSLocalizedString(@"Sound Track", nil);
            if ([movie audioChannels] == 0) {
                _summary = @"";
            }
            else {
                int chs = [movie audioChannels];
                _summary = [NSString stringWithFormat:@"%@, %.0f Hz, %@",
                            audioCodecDescription([movie audioCodecId]),
                            [movie audioSampleRate],
                            (chs == 1) ? NSLocalizedString(@"Mono", nil) :
                            (chs == 2) ? NSLocalizedString(@"Stereo", nil) :
                            (chs == 6) ? NSLocalizedString(@"5.1", nil) :
                            [NSString stringWithFormat:@"%d", chs]];
            }
        }
        [_name retain];
        [_summary retain];
        /*
        char buf[256];
        AVCodecContext* codec = formatContext->streams[streamIndex]->codec;
        avcodec_string(buf, sizeof(buf), codec, 1);
        TRACE(@"avcodec_string=\"%s\"", buf);

        // init name
        //NSStringEncoding encoding = [NSString defaultCStringEncoding]; 
        //NSMutableString* string = [NSMutableString stringWithCString:buf encoding:encoding];
        //NSRange range = [string rangeOfString:@":"];
        //range.length = range.location;
        //range.location = 0;
        //_name = [[string substringWithRange:range] retain];
        _name = (_streamId < 0) ? @"Video" : @"Audio";

        // init summary
        char ss[256];
        int i, len = strlen(buf), pos = 0;
        for (i = 0; i < len; i++) {
            if (strncmp(&buf[i], "Audio: ", 7) == 0 ||
                strncmp(&buf[i], "Video: ", 7) == 0) {
                i += 7;
            }
            if (buf[i] == '/') {
                i++;
            }
            if (strncmp(&buf[i], " 0x", 3) == 0 ||
                pos == 0 && strncmp(&buf[i], "0x", 2) == 0) {
                i += 3;
                while('0' <= buf[i] && buf[i] <= '9') {
                    i++;
                }
                if (strncmp(&buf[i], ", ", 2) == 0) {
                    i += 2;
                }
            }
            if (strncmp(&buf[i], "yuv420p, ", 7) == 0) {
                i += 9;
            }
            ss[pos++] = buf[i];
        }
        ss[pos] = '\0';
        _summary = [[NSString alloc] initWithCString:ss];
         */
    }
    return self;
}

- (int)streamId { return _streamId; }
- (float)volume { return _volume; }
- (void)setVolume:(float)volume { _volume = volume; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

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

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo error:(NSError**)error
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, [url absoluteString]);
    if (![url isFileURL]) {
        *error = [NSError errorWithDomain:[MMovie_FFmpeg name]
                                     code:10000  // FIXME
                                 userInfo:nil];
        return nil;
    }

    if (self = [super initWithURL:url movieInfo:movieInfo error:error]) {
        _formatContext = [MMovie formatContextForMovieURL:url error:error];
        if (!_formatContext) {
            return nil;
        }
        traceAVFormatContext(_formatContext);

        int errorCode;
        if (![self initAVCodec:&errorCode] ||
            ![self initPlayback:&errorCode] ||
            ![self initAudioPlayback:&errorCode]) {
            *error = [NSError errorWithDomain:[MMovie_FFmpeg name]
                                         code:errorCode userInfo:nil];
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)cleanup
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _quitRequested = TRUE;
    [self cleanupPlayback];
    [self cleanupAudioPlayback];
    [self cleanupAVCodec];

    av_close_input_file(_formatContext);
    _formatContext = 0;

    [super cleanup];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)trackEnabled:(MTrack*)track
{
    int streamId = [(MTrack_FFmpeg*)track streamId];
    if (0 <= streamId) {   // for audio
        [self startAudio:streamId];
        [self updateFirstAudioStreamId];
    }
}

- (void)trackDisabled:(MTrack*)track
{
    int streamId = [(MTrack_FFmpeg*)track streamId];
    if (0 <= streamId) {   // for audio
        [self stopAudio:streamId];
        [self updateFirstAudioStreamId];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark common utils.

- (BOOL)initDecoder:(AVCodecContext*)context codec:(AVCodec*)codec
           forVideo:(BOOL)forVideo
{
    context->debug_mv = 0;
    context->debug = 0;
    context->workaround_bugs = 1;
    context->lowres = 0;
    if (context->lowres) {
        context->flags |= CODEC_FLAG_EMU_EDGE;
    }
    context->idct_algo = FF_IDCT_AUTO;
    if (0/*fast*/) {
        context->flags2 |= CODEC_FLAG2_FAST;
    }
    context->skip_frame = AVDISCARD_DEFAULT;
    context->skip_idct = AVDISCARD_DEFAULT;
    context->skip_loop_filter = AVDISCARD_DEFAULT;
    context->error_resilience = FF_ER_CAREFUL;
    context->error_concealment = 3;
    
    if (forVideo) {
        //context->get_buffer = getBuffer;
        //context->release_buffer = releaseBuffer;
        /*
         if (1000 < context->frame_rate && context->frame_rate_base == 1) {
         context->frame_rate_base = 1000;
         }
         */
    }
    int ret = avcodec_open(context, codec);
    TRACE(@"%s avcodec_open() returns %d", __PRETTY_FUNCTION__, ret);
    return (0 <= ret);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark video

- (BOOL)initVideo:(int)videoStreamIndex errorCode:(int*)errorCode
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, videoStreamIndex);
    NSAssert(0 <= _videoStreamIndex, @"Video Stream Already Init");

    // find decoder for video-stream
    _videoStreamIndex = videoStreamIndex;
    if (_info.encodedSize.width == 0 || _info.encodedSize.height == 0) {
        *errorCode = ERROR_INVALID_VIDEO_DIMENSION;
        return FALSE;
    }

    // update _adjustedSize by _info.displaySize
    [self setAspectRatio:_aspectRatio];

    AVCodec* codec = avcodec_find_decoder(_videoContext->codec_id);
    if (!codec) {
        *errorCode = ERROR_FFMPEG_DECODER_NOT_FOUND;
        return FALSE;
    }
    if (![self initDecoder:_videoContext codec:codec forVideo:TRUE]) {
        *errorCode = ERROR_FFMPEG_CODEC_OPEN_FAILED;
        return FALSE;
    }

    // allocate video frame
    _videoFrame = avcodec_alloc_frame();
    if (_videoFrame == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }
    
    // init sw-scaler context
    _scalerContext =
        sws_getContext(_info.encodedSize.width, _info.encodedSize.height, _videoContext->pix_fmt,
                       _info.encodedSize.width, _info.encodedSize.height, RGB_PIXEL_FORMAT,
                       SWS_FAST_BILINEAR, 0, 0, 0);
    if (!_scalerContext) {
        TRACE(@"cannot initialize conversion context");
        *errorCode = ERROR_FFMPEG_SW_SCALER_INIT_FAILED;
        return FALSE;
    }

    [_videoTracks addObject:
     [MTrack_FFmpeg trackWithMovie:self formatContext:_formatContext
                       streamIndex:videoStreamIndex streamId:-1]];

    MTrack_FFmpeg* track = [_videoTracks objectAtIndex:0];
    [track setEnabled:TRUE];

    int i, bufWidth, bufSize;
    for (i = 0; i < MAX_VIDEO_DATA_BUF_SIZE; i++) {
        _videoFrameData[i] = avcodec_alloc_frame();
        if (_videoFrameData[i] == 0) {
            *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
            return FALSE;
        }    
        bufWidth = _info.encodedSize.width + 37;
        if (bufWidth < 512) {
            bufWidth = 512 + 37;
        }
        bufSize = avpicture_get_size(RGB_PIXEL_FORMAT, bufWidth , _info.encodedSize.height);
        avpicture_fill((AVPicture*)_videoFrameData[i], malloc(bufSize),
                       RGB_PIXEL_FORMAT, bufWidth, _info.encodedSize.height);
        
    }
    return TRUE;
}

- (void)cleanupVideo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_scalerContext) {
        av_free(_scalerContext);
        _scalerContext = 0;
    }
    int i;
    for (i = 0; i < MAX_VIDEO_DATA_BUF_SIZE; i++) {
        if (_videoFrameData[i]) {
            free(_videoFrameData[i]->data[0]);
            av_free(_videoFrameData[i]);
            _videoFrameData[i] = 0;
        }
    }
    if (_videoFrame) {
        av_free(_videoFrame);
        _videoFrame = 0;
    }
    if (_videoContext) {
        avcodec_close(_videoContext);
        _videoStreamIndex = -1;
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)initAVCodec:(int*)errorCode
{
    int i;
    for (i = 0; i < _formatContext->nb_streams; i++) {
        switch (_formatContext->streams[i]->codec->codec_type) {
            case CODEC_TYPE_VIDEO :
                if (![self initVideo:i errorCode:errorCode]) {
                    return FALSE;
                }
                break;
            case CODEC_TYPE_AUDIO :
                if (_audioStreamCount < MAX_AUDIO_STREAM_COUNT) {
                    [self initAudio:i errorCode:errorCode];
                    // continue even if init audio failed
                }
                break;
        }
    }
    if (_videoStreamIndex < 0) {
        *errorCode = ERROR_FFMPEG_VIDEO_STREAM_NOT_FOUND;
        return FALSE;
    }
    // continue even if no audio found
    
    //av_read_play(_formatContext);
    
    return TRUE;
}

- (void)cleanupAVCodec
{
    [self cleanupVideo];
    [self cleanupAudio];
}

@end

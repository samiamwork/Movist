//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
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

#import "MMovie.h"
#import "FFTrack.h"

@implementation MTrack

+ (id)trackWithImpl:(id)impl
{
    return [[[MTrack alloc] initWithImpl:impl] autorelease];
}

- (id)initWithImpl:(id)impl
{
    if (self = [super init]) {
        _impl = [impl retain];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_summary release];
    [_name release];
    [_movie release];
    [_impl release];
    [super dealloc];
}

- (id)impl { return _impl; }
- (int)codecId { return _codecId; }
- (NSString*)name { return _name; }
- (NSString*)summary { return _summary; }
- (BOOL)isVideoTrack { return _encodedSize.width != 0; }
- (void)setImpl:(id)impl { [impl retain], [_impl release], _impl = impl; }
- (void)setMovie:(MMovie*)movie { [movie retain], [_movie release], _movie = movie; }
- (void)setCodecId:(int)codecId { _codecId = codecId; }
- (void)setName:(NSString*)name { [name retain], [_name release], _name = name; }
- (void)setSummary:(NSString*)summary { [summary retain], [_summary release], _summary = summary; }

- (NSSize)encodedSize { return _encodedSize; }
- (NSSize)displaySize { return _displaySize; }
- (float)fps { return _fps; }
- (void)setEncodedSize:(NSSize)encodedSize { _encodedSize = encodedSize; }
- (void)setDisplaySize:(NSSize)displaySize { _displaySize = displaySize; }
- (void)setFps:(float)fps { _fps = fps; }

- (int)audioChannels { return _audioChannels; }
- (float)audioSampleRate { return _audioSampleRate; }
- (void)setAudioChannels:(int)channels { _audioChannels = channels; }
- (void)setAudioSampleRate:(float)rate { _audioSampleRate = rate; }

- (BOOL)isEnabled { return [_impl isEnabled]; }
- (void)setEnabled:(BOOL)enabled
{
    [_impl setEnabled:enabled];

    if (enabled) {
        [_movie trackEnabled:self];
    }
    else {
        [_movie trackDisabled:self];
    }
}

- (float)volume { return [_impl volume]; }
- (void)setVolume:(float)volume { [_impl setVolume:volume]; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie

+ (NSArray*)fileExtensions
{
    static NSArray* fileExtensions = nil;
    if (!fileExtensions) {
        NSMutableArray* exts = [[NSMutableArray alloc] initWithCapacity:32];

        NSDictionary* dict = [[NSBundle mainBundle] infoDictionary];
        NSDictionary* type;
        NSString* bundleTypeName;
        NSArray* types = [dict objectForKey:@"CFBundleDocumentTypes"];
        NSEnumerator* typeEnumerator = [types objectEnumerator];
        while (type = [typeEnumerator nextObject]) {
            bundleTypeName = [type objectForKey:@"CFBundleTypeName"];
            if ([bundleTypeName hasPrefix:@"Movie-"]) {
                [exts addObjectsFromArray:[type objectForKey:@"CFBundleTypeExtensions"]];
            }
        }
        fileExtensions = exts;
    }
    //TRACE(@"fileExtentions=%@", [fileExtensions retainCount], fileExtensions);
    return fileExtensions;  // don't send autorelease. it should be alive forever.

    // add following extensions to Info.plist in future.
    // .swf : Flash
    // .dmb : DMB-TS
    // .dmskm, .k3g, .lmp4 : Mobile Phone
}

+ (BOOL)checkMovieURL:(NSURL*)url error:(NSError**)error
{
    if ([url isFileURL]) {
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString* path = [url path];
        if (![fileManager fileExistsAtPath:path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Movist"
                                             code:ERROR_FILE_NOT_EXIST userInfo:nil];
            }
            return FALSE;
        }
        if (![fileManager isReadableFileAtPath:path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Movist"
                                             code:ERROR_FILE_NOT_READABLE userInfo:nil];
            }
            return FALSE;
        }
    }
    return TRUE;
}

+ (MTrack*)videoTrackWithAVStream:(AVStream*)stream streamIndex:(int)streamIndex
{
    AVCodecContext* codecContext = stream->codec;

    NSString* fourCC = nil;
    if (codecContext->codec_tag != 0) {
        unsigned int tag = codecContext->codec_tag;
        if (isprint((tag      ) & 0xFF) && isprint((tag >>  8) & 0xFF) &&
            isprint((tag >> 16) & 0xFF) && isprint((tag >> 24) & 0xFF)) {
            fourCC = [NSString stringWithFormat:@"%c%c%c%c",
                      (tag      ) & 0xFF, (tag >>  8) & 0xFF,
                      (tag >> 16) & 0xFF, (tag >> 24) & 0xFF];
        }
    }
    int codecId = [self videoCodecIdFromFFmpegCodecId:codecContext->codec_id fourCC:fourCC];
    NSSize encodedSize = NSMakeSize(codecContext->coded_width, codecContext->coded_height);
    NSSize displaySize = NSMakeSize(codecContext->width,       codecContext->height);
    if (0 < codecContext->sample_aspect_ratio.num &&
        0 < codecContext->sample_aspect_ratio.den) {
        displaySize.width *= (float)codecContext->sample_aspect_ratio.num /
                                    codecContext->sample_aspect_ratio.den;
        // FIXME: ignore strange(vertically long) pixel-aspect-ratio.
        if (displaySize.width < displaySize.height) {
            displaySize.width = encodedSize.width;
        }
    }
    float fps;
    if (stream->r_frame_rate.den && stream->r_frame_rate.num) {
        fps = av_q2d(stream->r_frame_rate);
    }
    else {
        fps = 1 / av_q2d(codecContext->time_base);
    }

    NSString* summary;
    NSString* name = NSLocalizedString(@"Video Track ##", nil);
    if (NSEqualSizes(displaySize, encodedSize)) {
        summary = [NSString stringWithFormat:@"%@, %d x %d",
                   codecDescription(codecId),
                   (int)displaySize.width, (int)displaySize.height];
    }
    else {
        summary = [NSString stringWithFormat:@"%@, %d x %d (%d x %d)",
                   codecDescription(codecId),
                   (int)encodedSize.width, (int)encodedSize.height,
                   (int)displaySize.width, (int)displaySize.height];
    }

    MTrack* track = [MTrack trackWithImpl:
                     [FFVideoTrack videoTrackWithAVStream:stream index:streamIndex]];
    [track setName:name];
    [track setSummary:summary];
    [track setCodecId:codecId];
    [track setEncodedSize:encodedSize];
    [track setDisplaySize:displaySize];
    [track setFps:fps];
    return track;
}

+ (MTrack*)audioTrackWithAVStream:(AVStream*)stream streamIndex:(int)streamIndex
{
    AVCodecContext* codecContext = stream->codec;

    int codecId = [self audioCodecIdFromFFmpegCodecId:codecContext->codec_id];
    int channels = codecContext->channels;
    float sampleRate = codecContext->sample_rate;

    NSString* summary;
    NSString* name = NSLocalizedString(@"Sound Track ##", nil);
    if (channels == 0) {
        summary = @"";
    }
    else {
        summary = [NSString stringWithFormat:@"%@, %@, %.03f kHz",
                   codecDescription(codecId),
                   (channels == 1) ? NSLocalizedString(@"Mono", nil) :
                   (channels == 2) ? NSLocalizedString(@"Stereo", nil) :
                   (channels == 6) ? NSLocalizedString(@"5.1 Ch.", nil) :
                                     [NSString stringWithFormat:@"%d", channels],
                   sampleRate / 1000];
    }

    MTrack* track = [MTrack trackWithImpl:
                     [FFAudioTrack audioTrackWithAVStream:stream index:streamIndex]];
    [track setName:name];
    [track setSummary:summary];
    [track setCodecId:codecId];
    [track setAudioChannels:channels];
    [track setAudioSampleRate:sampleRate];
    return track;
}

+ (BOOL)getMovieInfo:(MMovieInfo*)info forMovieURL:(NSURL*)url error:(NSError**)error
{
    if (![self checkMovieURL:url error:error]) {
        return FALSE;
    }

    AVFormatContext* formatContext = 0;
    const char* path = [[url path] UTF8String];
    if (av_open_input_file(&formatContext, path, NULL, 0, NULL) != 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"Movist"
                                         code:ERROR_FFMPEG_FILE_OPEN_FAILED
                                     userInfo:nil];
        }
        return FALSE;
    }
    if (av_find_stream_info(formatContext) < 0) {
        av_close_input_file(formatContext);
        if (error) {
            *error = [NSError errorWithDomain:@"Movist"
                                         code:ERROR_FFMPEG_STREAM_INFO_NOT_FOUND
                                     userInfo:nil];
        }
        return FALSE;
    }

    int i;
    float fps = 0;
    MTrack* track;
    AVStream* stream;
    BOOL hasDigitalAudio = FALSE;
    NSMutableArray* videoTracks = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray* audioTracks = [NSMutableArray arrayWithCapacity:1];
    for (i = 0; i < formatContext->nb_streams; i++) {
        stream = formatContext->streams[i];
        if (stream->codec->codec_type == CODEC_TYPE_VIDEO) {
            track = [self videoTrackWithAVStream:stream streamIndex:i];
            [videoTracks addObject:track];
            if (!fps && 0 < [track fps]) {
                fps = [track fps];
            }
        }
        else if (stream->codec->codec_type == CODEC_TYPE_AUDIO) {
            track = [self audioTrackWithAVStream:stream streamIndex:i];
            [audioTracks addObject:track];
            if (!hasDigitalAudio &&
                ([track codecId] == MCODEC_AC3 ||
                 [track codecId] == MCODEC_DTS)) {
                hasDigitalAudio = TRUE;
            }
        }
    }
    if ([videoTracks count] == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"Movist"
                                         code:ERROR_FFMPEG_VIDEO_STREAM_NOT_FOUND
                                     userInfo:nil];
        }
        return FALSE;
    }
    
    info->formatContext = formatContext;
    info->videoTracks = videoTracks;
    info->audioTracks = audioTracks;
    info->hasDigitalAudio = hasDigitalAudio;
    info->startTime = (formatContext->start_time == AV_NOPTS_VALUE) ? 0 :
                                formatContext->start_time / AV_TIME_BASE;
    info->duration = (formatContext->duration == AV_NOPTS_VALUE) ? 0 :
                                formatContext->duration / AV_TIME_BASE;
    info->fileSize = formatContext->file_size;
    info->bitRate = formatContext->bit_rate;
    info->fps = fps;
    return TRUE;
}

+ (NSString*)name { return @""; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo
  digitalAudioOut:(BOOL)digitalAudioOut error:(NSError**)error
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [url absoluteString]);
    if (![MMovie checkMovieURL:url error:error]) {
        return nil;
    }
    if (self = [super init]) {
        _url = [url retain];
        _videoTracks = [movieInfo->videoTracks retain];
        _audioTracks = [movieInfo->audioTracks retain];
        _hasDigitalAudio = movieInfo->hasDigitalAudio;
        _startTime = movieInfo->startTime;
        _duration = movieInfo->duration;
        _fileSize = movieInfo->fileSize;
        _bitRate = movieInfo->bitRate;
        _fps = movieInfo->fps;
        _indexedDuration = 0;

        _preferredVolume = DEFAULT_VOLUME;
        _volume = DEFAULT_VOLUME;
        _muted = FALSE;

        _aspectRatio = ASPECT_RATIO_DEFAULT;
    }
    return self;
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return TRUE;
}

- (void)cleanup
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_audioTracks release];
    [_videoTracks release];
    [_url release];
    [self release];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSURL*)url { return _url; }
- (int64_t)fileSize { return _fileSize; }
- (int)bitRate { return _bitRate; }
- (NSArray*)videoTracks { return _videoTracks; }
- (NSArray*)audioTracks { return _audioTracks; }
- (NSSize)displaySize { return [[_videoTracks objectAtIndex:0] displaySize]; }
- (NSSize)encodedSize { return [[_videoTracks objectAtIndex:0] encodedSize]; }
- (float)startTime { return _startTime; }
- (float)duration { return _duration; }
- (float)fps { return _fps; }

- (void)trackEnabled:(MTrack*)track {}
- (void)trackDisabled:(MTrack*)track {}

- (float)indexedDuration { return _indexedDuration; }
- (void)indexedDurationUpdated:(float)indexedDuration
{
    if (_indexedDuration != indexedDuration) {
        _indexedDuration = indexedDuration;
        //TRACE(@"_indexedDuration=%.1f %@", _indexedDuration);
        [[NSNotificationCenter defaultCenter]
         postNotificationName:MMovieIndexedDurationNotification object:self];
    }
}
- (void)indexingFinished {}

- (BOOL)hasDigitalAudio { return _hasDigitalAudio; }
- (float)preferredVolume { return _preferredVolume; }
- (float)volume { return _volume; }
- (BOOL)muted { return _muted; }
- (void)setVolume:(float)volume { _volume = volume; }
- (void)setMuted:(BOOL)muted { _muted = muted; }

- (int)aspectRatio { return _aspectRatio; }
- (NSSize)adjustedSizeByAspectRatio { return _adjustedSize; }
- (void)setAspectRatio:(int)aspectRatio
{
    _aspectRatio = aspectRatio;

    if (_aspectRatio == ASPECT_RATIO_DEFAULT) {
        _adjustedSize = [[_videoTracks objectAtIndex:0] displaySize];
    }
    else {
        float ratio[] = {
            4.0  / 3.0,     // ASPECT_RATIO_4_3
            16.0 / 9.0,     // ASPECT_RATIO_16_9
            1.85 / 1.0,     // ASPECT_RATIO_1_85
            2.35 / 1.0,     // ASPECT_RATIO_2_35
        };
        NSSize displaySize = [[_videoTracks objectAtIndex:0] displaySize];
        _adjustedSize.width  = displaySize.width;
        _adjustedSize.height = displaySize.width / ratio[_aspectRatio - 1];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (float)currentTime { return 0.0; }
- (float)rate { return 0.0; }
- (void)setRate:(float)rate {}
- (void)stepBackward {}
- (void)stepForward {}
- (void)gotoBeginning {}
- (void)gotoEnd {}
- (void)gotoTime:(float)time {}
- (void)seekByTime:(float)dt {}
- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp { return 0; }
- (void)idleTask {}

@end

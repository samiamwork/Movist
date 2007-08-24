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

#if defined(_SUPPORT_FFMPEG)

#import "MMovie_FFMPEG.h"

@implementation MMovie_FFMPEG (Init)

- (void)movieInfo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableString* s = [NSMutableString stringWithCapacity:256];
    
    [s setString:@"- format: "];
    [s appendFormat:@"%s", _formatContext->iformat->name];
    TRACE(s);
    
    [s setString:@"- duration: "];
    if (_formatContext->duration == AV_NOPTS_VALUE) {
        [s appendString:@"N/A"];
    }
    else {
        int seconds = _formatContext->duration / AV_TIME_BASE;
        int us      = _formatContext->duration % AV_TIME_BASE;
        int minutes = seconds / 60;
        [s appendFormat:@"%02d:%02d:%02d.%01d",
            minutes / 60, minutes % 60, seconds % 60, (10 * us) / AV_TIME_BASE];
    }
    TRACE(s);
    
    [s setString:@"- start: "];
    if (_formatContext->start_time != AV_NOPTS_VALUE) {
        int seconds = _formatContext->start_time / AV_TIME_BASE;
        int us      = _formatContext->start_time % AV_TIME_BASE;
        [s appendFormat:@"%d.%06d",
            seconds, (int)av_rescale(us, 1000000, AV_TIME_BASE)];
        TRACE(s);
    }
    
    [s setString:@"- bit-rate: "];
    if (_formatContext->bit_rate == 0) {
        [s appendString:@"N/A"];
    }
    else {
        [s appendFormat:@"%d kb/s", _formatContext->bit_rate / 1000];
    }
    TRACE(s);
    
    int i;
    char buf[256];
    AVStream* stream;
    for (i = 0; i < _formatContext->nb_streams; i++) {
        stream = _formatContext->streams[i];
        [s setString:@""];
        [s appendFormat:@"- stream #%d", i];
        
        if (_formatContext->iformat->flags & AVFMT_SHOW_IDS) {
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

- (NSString*)streamName:(BOOL)isVideo streamId:(int)streamId
{
    /*
    char buf[256];
    if (isVideo) {
        avcodec_string(buf, sizeof(buf), _videoContext, 1);
    }
    else {
        avcodec_string(buf, sizeof(buf), _audioContext(streamId), 1);
    }
    NSStringEncoding encoding = [NSString defaultCStringEncoding]; 
    NSMutableString* string = [NSMutableString stringWithCString:buf encoding:encoding];
    NSRange range = [string rangeOfString:@":"];
    range.length = range.location;
    range.location = 0;
    return [string substringWithRange:range];
    */
    if (isVideo) {
        return @"Video";
    }
    else {
        return @"Audio";        
    }
}

- (NSString*)streamFormat:(BOOL)isVideo streamId:(int)streamId
{
    char buf[256];
    if (isVideo) {
        avcodec_string(buf, sizeof(buf), _videoContext, 1);
    }
    else {
        avcodec_string(buf, sizeof(buf), _audioContext(streamId), 1);
    }
    char result[256];
    int i, pos = 0;
    for (i = 0; i < strlen(buf); i++) {
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
        result[pos++] = buf[i];
    }
    result[pos] = 0;
    return [NSString stringWithCString:result];
    NSStringEncoding encoding = [NSString defaultCStringEncoding]; 
    NSMutableString* string = [NSMutableString stringWithCString:buf encoding:encoding];
    NSRange range = [string rangeOfString:@":"];
    range.location += 2;
    range.length = [string length] - range.location;
    return [string substringWithRange:range];
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
    _scalerContext = sws_getContext(_videoWidth, _videoHeight, _videoContext->pix_fmt,
                                    _videoWidth, _videoHeight, RGB_PIXEL_FORMAT,
                                    SWS_FAST_BILINEAR, 0, 0, 0);
    if (!_scalerContext) {
        TRACE(@"cannot initialize conversion context");
        *errorCode = ERROR_FFMPEG_SW_SCALER_INIT_FAILED;
        return FALSE;
    }

    [_videoTracks addObject:[[[MTrack_FFMPEG alloc] 
                              initWithStreamId:-1 movie:self] 
                             autorelease]];
    
    MTrack_FFMPEG* track = [_videoTracks objectAtIndex:0];
    [track setEnabled:TRUE];
    
    _videoFrameRGB = avcodec_alloc_frame();
    if (_videoFrameRGB == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }    
	int bufWidth = _videoWidth + 37;
    if (bufWidth < 512) {
        bufWidth = 512 + 37;
    }
    int bufferSize = avpicture_get_size(RGB_PIXEL_FORMAT, bufWidth , _videoHeight);
    avpicture_fill((AVPicture*)_videoFrameRGB, malloc(bufferSize),
                   RGB_PIXEL_FORMAT, bufWidth, _videoHeight);

    return TRUE;
}

- (void)cleanupVideo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_scalerContext) {
        av_free(_scalerContext);
        _scalerContext = 0;
    }
    if (_videoFrameRGB) {
        free(_videoFrameRGB->data[0]);
        av_free(_videoFrameRGB);
        _videoFrameRGB = 0;
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

- (BOOL)initFFMPEGWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode
{
    const char* path = [[movieURL path] UTF8String];
    if (av_open_input_file(&_formatContext, path, NULL, 0, NULL) != 0) {
        *errorCode = ERROR_FFMPEG_FILE_OPEN_FAILED;
        return FALSE;
    }
    if (av_find_stream_info(_formatContext) < 0) {
        *errorCode = ERROR_FFMPEG_STREAM_INFO_NOT_FOUND;
        return FALSE;
    }
    [self movieInfo];

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

- (void)cleanupFFMPEG
{
    [self cleanupVideo];
    [self cleanupAudio];
    av_close_input_file(_formatContext);
    _formatContext = 0;
}

@end

#endif  // _SUPPORT_FFMPEG

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

#import "FFTrack.h"
#import "MMovie_FFmpeg.h"

@interface PacketQueue : NSObject
{
    AVPacket* _packet;
    unsigned int _capacity;
    unsigned int _front;
    unsigned int _rear;
    NSLock* _mutex;
}

- (id)initWithCapacity:(unsigned int)capacity;

#pragma mark -
- (void)clear;
- (BOOL)isEmpty;
- (BOOL)isFull;
- (BOOL)putPacket:(const AVPacket*)packet;
- (BOOL)getPacket:(AVPacket*)packet;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation PacketQueue

- (id)initWithCapacity:(unsigned int)capacity
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, capacity);
    self = [super init];
    if (self) {
        _packet = malloc(sizeof(AVPacket) * capacity);
        _capacity = capacity;
        _front = 0;
        _rear = 0;
    }
    _mutex = [[NSRecursiveLock alloc] init];
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    free(_packet);
    [_mutex dealloc];
    [super dealloc];
}

- (BOOL)isEmpty { return (_front == _rear); }
- (BOOL)isFull { return (_front == (_rear + 1) % _capacity); }

- (void)clear 
{ 
    [_mutex lock];
    _rear = _front; 
    [_mutex unlock];
}

- (BOOL)putPacket:(const AVPacket*)packet
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isFull]) {
        return FALSE;
    }
    _packet[_rear] = *packet;
    _rear = (_rear + 1) % _capacity;
    return TRUE;
}

- (BOOL)getPacket:(AVPacket*)packet
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_mutex lock];
    if ([self isEmpty]) {
        [_mutex unlock];
        return FALSE;
    }
    *packet = _packet[_front];
    _front = (_front + 1) % _capacity;
    [_mutex unlock];
    return TRUE;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define RGB_PIXEL_FORMAT    PIX_FMT_YUV422
//#define RGB_PIXEL_FORMAT    PIX_FMT_BGRA    // PIX_FMT_ARGB is not supported by ffmpeg

@implementation FFVideoTrack

+ (id)videoTrackWithAVStream:(AVStream*)stream index:(int)index
{
    return [[[FFVideoTrack alloc] initWithAVStream:stream index:index] autorelease];
}

- (BOOL)initTrack:(int*)errorCode
{
    if (![super initTrack:errorCode]) {
        return FALSE;
    }

    AVCodecContext* context = _stream->codec;

    // allocate frame
    _frame = avcodec_alloc_frame();
    if (_frame == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }

    // init sw-scaler context
    float width = context->coded_width;
    float height= context->coded_height;
    _scalerContext = sws_getContext(width, height, context->pix_fmt,
                                    width, height, RGB_PIXEL_FORMAT,
                                    SWS_FAST_BILINEAR, 0, 0, 0);
    if (!_scalerContext) {
        TRACE(@"cannot initialize conversion context");
        *errorCode = ERROR_FFMPEG_SW_SCALER_INIT_FAILED;
        return FALSE;
    }

    int i, bufWidth, bufSize;
    for (i = 0; i < MAX_VIDEO_DATA_BUF_SIZE; i++) {
        _frameData[i] = avcodec_alloc_frame();
        if (_frameData[i] == 0) {
            *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
            return FALSE;
        }    
        bufWidth = width + 37;
        if (bufWidth < 512) {
            bufWidth = 512 + 37;
        }
        bufSize = avpicture_get_size(RGB_PIXEL_FORMAT, bufWidth , height);
        avpicture_fill((AVPicture*)_frameData[i], malloc(bufSize),
                       RGB_PIXEL_FORMAT, bufWidth, height);
    }

    // init playback
    _packetQueue = [[PacketQueue alloc] initWithCapacity:30 * 5];  // 30 fps * 5 sec.

    _decodedImageCount = 0;
    _decodedImageBufCount = 0;
    _dataBufId = 0;
    _nextDataBufId = 0;
    _prevImageTime = 0;
    for (i = 0; i < MAX_VIDEO_DATA_BUF_SIZE; i++) {
        _decodedImageTime[i] = 0;
    }
    _needKeyFrame = FALSE;
    _useFrameDrop = _stream->r_frame_rate.num / _stream->r_frame_rate.den > 30;
    _frameInterval = 1. / (_stream->r_frame_rate.num / _stream->r_frame_rate.den);

    _running = TRUE;
    [NSThread detachNewThreadSelector:@selector(decodeThreadFunc:)
                             toTarget:self withObject:nil];

    return TRUE;
}

- (void)cleanupTrack
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_scalerContext) {
        av_free(_scalerContext);
        _scalerContext = 0;
    }
    int i;
    for (i = 0; i < MAX_VIDEO_DATA_BUF_SIZE; i++) {
        if (_frameData[i]) {
            free(_frameData[i]->data[0]);
            av_free(_frameData[i]);
            _frameData[i] = 0;
        }
    }
    if (_frame) {
        av_free(_frame);
        _frame = 0;
    }
    [_packetQueue release];
    _packetQueue = 0;

    [super cleanupTrack];
}

- (BOOL)isIndexComplete
{
    return (1 < _stream->nb_index_entries);
}

- (BOOL)isQueueEmpty
{
    return [_packetQueue isEmpty];
}

- (BOOL)isQueueFull
{
    return [_packetQueue isFull];
}

- (void)putPacket:(const AVPacket*)packet
{
    [_packetQueue putPacket:packet];
}

- (void)clearQueue
{
    [_packetQueue clear];
    [self putPacket:&s_flushPacket];
}

- (double)decodePacket
{
    //TRACE(@"%s(%d) %d %d", __PRETTY_FUNCTION__, _nextDataBufId, _decodedImageCount, _decodedImageBufCount);
    AVPacket packet;
    if (![_packetQueue getPacket:&packet]) {
        //TRACE(@"%s no more packet", __PRETTY_FUNCTION__);
        return -1;
    }

    if (packet.stream_index != _streamIndex) {
        TRACE(@"%s invalid stream_index %d", __PRETTY_FUNCTION__, packet.stream_index);
        return -1;
    }
    assert(packet.stream_index == _streamIndex);

    if (packet.data == s_flushPacket.data) {
        TRACE(@"%s avcodec_flush_buffers", __PRETTY_FUNCTION__);
        avcodec_flush_buffers(_stream->codec);
        return -1;
    }

    int gotFrame;
    int bytesDecoded = avcodec_decode_video(_stream->codec, _frame,
                                            &gotFrame, packet.data, packet.size);
    av_free_packet(&packet);
    if (bytesDecoded < 0) {
        TRACE(@"%s error while decoding frame", __PRETTY_FUNCTION__);
        return -1;
    }
    if (!gotFrame) {
        TRACE(@"%s incomplete decoded frame", __PRETTY_FUNCTION__);
        return -1;
    }

    double pts = 0;
    if (packet.dts != AV_NOPTS_VALUE) {
        pts = packet.dts;
    }
    else if (_frame->opaque && *(uint64_t*)_frame->opaque != AV_NOPTS_VALUE) {
        pts = *(uint64_t*)_frame->opaque;
    }
    return (double)(pts * av_q2d(_stream->time_base));
}

- (BOOL)convertImage
{
    // sw-scaler should be used under GPL only!
    int ret = sws_scale(_scalerContext,
                        _frame->data, _frame->linesize,
                        0, [_movie encodedSize].height,
                        _frameData[_nextDataBufId]->data,
                        _frameData[_nextDataBufId]->linesize);
    if (ret < 0) {
        TRACE(@"%s sws_scale() failed : %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }
    
    return TRUE;
}

- (double)nextDecodedImageTime
{
    return (0 <= _decodedImageCount) ? _decodedImageTime[_dataBufId] : -1.0;
}

- (BOOL)discardImage
{
    assert(0 < _decodedImageCount);
    _decodedImageCount--;
    _decodedImageBufCount--;
    _dataBufId = (_dataBufId + 1) % MAX_VIDEO_DATA_BUF_SIZE;
    TRACE(@"discard image");

    return (0 <= _decodedImageCount);
}

- (void)decodeThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    /*
    TRACE(@"cur thread priority %f", [NSThread threadPriority]);
    [NSThread setThreadPriority:0.9];
    TRACE(@"set thread priority %f", [NSThread threadPriority]);
     */
    while (![_movie quitRequested]) {
        if (MAX_VIDEO_DATA_BUF_SIZE - 3 <= _decodedImageCount ||
            ![_movie canDecodeVideo]) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            continue;
        }

        _decodedImageTime[_nextDataBufId] = [self decodePacket];
        if (_decodedImageTime[_nextDataBufId] < 0) {
            continue;
        }
        [self convertImage];
        [_movie videoTrack:self decodedTime:_decodedImageTime[_nextDataBufId]];

        //TRACE(@"decoded(%d,%d:%d) %f", _decodedImageBufCount, 
        //                               _decodedImageCount, 
        //                               _nextDataBufId, 
        //                               _lastDecodedTime);
        _decodedImageBufCount++;
        _decodedImageCount++;
        _nextDataBufId = (_nextDataBufId + 1) % MAX_VIDEO_DATA_BUF_SIZE;
    }
    [pool release];
    _running = FALSE;

    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

- (BOOL)isNewImageAvailable:(double)hostTime
             hostTime0point:(double*)hostTime0point
{
    if (_decodedImageCount < 1) {
        //TRACE(@"not decoded %f", current);
        return FALSE;
    }
    double current = hostTime - *hostTime0point;
    double imageTime = _decodedImageTime[_dataBufId];
    if (imageTime + 0.5 < current || current + 0.5 < imageTime) {
        TRACE(@"reset av sync %f %f", current, imageTime);
        *hostTime0point = hostTime - imageTime;
        current = imageTime;
    }
    //#define _FRAME_DROP
#ifdef _FRAME_DROP
    while (([_movie avFineTuningTime] || _useFrameDrop) && 
           imageTime + _frameInterval < current) {
        if (_decodedImageCount < 0) {
            break;
        }
        [self discardImage];
        imageTime = _decodedImageTime[_dataBufId];
    }
#endif
    if (current < imageTime) {
        //TRACE(@"wait(%d) %f < %f", _dataBufId, current, imageTime);
        return FALSE;
    }
    /*
    if (_prevImageTime < current && 
        current - _prevImageTime < _frameInterval * 0.5) {
        return FALSE;
    }
     */
    _prevImageTime = current;
    _decodedImageCount--;
    //TRACE(@"draw(%d) %f %f", _dataBufId, current, imageTime);
    return TRUE;
}

- (CVOpenGLTextureRef)nextImage:(double*)currentTime
{
    //[_avSyncMutex lock];
    *currentTime = _decodedImageTime[_dataBufId];
    //[_avSyncMutex unlock];

    CVPixelBufferRef bufferRef = 0;
    NSSize size = [_movie encodedSize];
    int ret = CVPixelBufferCreateWithBytes(0, size.width, size.height,
                                           kYUVSPixelFormat,    // k32ARGBPixelFormat
                                           _frameData[_dataBufId]->data[0], 
                                           _frameData[_dataBufId]->linesize[0],
                                           0, 0, 0, // pixelBufferReleaseCallback, self, 0,
                                           &bufferRef);
    if (ret == kCVReturnSuccess) {
        //TRACE(@"display(%d) %f", _dataBufId, _currentTime);
    }
    else {
        TRACE(@"CVPixelBufferCreateWithBytes() failed : %d", ret);
    }

    _dataBufId = (_dataBufId + 1) % MAX_VIDEO_DATA_BUF_SIZE;    
    return bufferRef;
}

@end

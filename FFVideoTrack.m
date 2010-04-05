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
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, capacity);
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
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self clear];
    free(_packet);
    [_mutex release];
    [super dealloc];
}

- (BOOL)isEmpty { return (_front == _rear); }
- (BOOL)isFull { return (_front == (_rear + 1) % _capacity); }

- (void)clear 
{ 
    [_mutex lock];
    unsigned int i;
    for (i = _front; i != _rear; i = (i + 1) % _capacity) {
        av_free_packet(&_packet[i]);
    }
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

#define RGB_PIXEL_FORMAT    PIX_FMT_YUYV422
//#undef RGB_PIXEL_FORMAT
//#define RGB_PIXEL_FORMAT    PIX_FMT_BGRA    // PIX_FMT_ARGB is not supported by ffmpeg

//#define _EXPERIMENTAL_AV_SYNC

@interface ImageQueue : NSObject
{
    CVPixelBufferRef* _pixelBuffer;
	AVFrame** _frame;
	double* _time;
    unsigned int _capacity;
    unsigned int _front;
    unsigned int _rear;
    BOOL _full;
    NSLock* _mutex;
}
@end

@implementation ImageQueue

- (id)initWithCapacity:(unsigned int)capacity width:(int)width	height:(int)height
{
    self = [super init];
	if (!self) {
		return 0;
	}

    _pixelBuffer = (CVPixelBufferRef*)malloc(sizeof(CVPixelBufferRef) * capacity);
    _frame = (AVFrame**)malloc(sizeof(AVFrame*) * capacity);
    _time = (double*)malloc(sizeof(double) * capacity);
	_capacity = capacity;
    _front = _rear = 0;
    _full = FALSE;

    int bufWidth = width;
    if (isSystemTiger()) {
        bufWidth += 37;
        if (bufWidth < 512) {
            bufWidth = 512 + 37;
        }
    }
    bufWidth = (bufWidth + 31) / 32 * 32;
    int bufSize = avpicture_get_size(RGB_PIXEL_FORMAT, bufWidth , height);
    int i, ret;
    for (i = 0; i < _capacity; i++) {
        _frame[i] = avcodec_alloc_frame();
        if (_frame[i] == 0) {
            TRACE(@"ERROR_FFMPEG_FRAME_ALLOCATE_FAILED");
            return FALSE;
        }
        avpicture_fill((AVPicture*)_frame[i], malloc(bufSize),
                       RGB_PIXEL_FORMAT, bufWidth, height);

        ret = CVPixelBufferCreateWithBytes(0, width, height, k2vuyPixelFormat,
                                           _frame[i]->data[0], _frame[i]->linesize[0],
                                           0, 0, 0, &_pixelBuffer[i]);
        if (ret != kCVReturnSuccess) {
            TRACE(@"kCVPixelBufferCreateWithBytes() failed : %d", ret);
            return FALSE;
        }
    }
    _mutex = [[NSRecursiveLock alloc] init];
    return self;
}

- (void)dealloc
{
    [_mutex release];
    int i;
    for (i = 0; i < _capacity; i++) {
        if (_frame[i]) {
            CVOpenGLTextureRelease(_pixelBuffer[i]);
            free(_frame[i]->data[0]);
            av_free(_frame[i]);
            _frame[i] = 0;
        }
    }
    free(_pixelBuffer);
    free(_frame);
    free(_time);
    [super dealloc];
}

- (int)capacity
{
    return _capacity;
}

- (int)count 
{ 
    return (_capacity + _rear - _front) % _capacity; 
}

- (BOOL)isEmpty 
{
    return (_front == _rear && !_full); 
}

- (BOOL)isFull 
{ 
    return (_front == _rear && _full); 
}

- (void)clear 
{ 
    [_mutex lock];
    _rear = _front; 
    [_mutex unlock];
}

- (AVFrame*)front
{
    return _frame[_front];
}

- (AVFrame*)back 
{ 
    return _frame[_rear]; 
}

- (CVPixelBufferRef)pixelBuffer
{
    return _pixelBuffer[_front];
}

- (double)time 
{
    return _time[_front];
}

- (void)enqueue:(AVFrame*)frame time:(double)time
{
    _time[_rear] = time;
    _rear = (_rear + 1) % _capacity;
    if (_rear == _front) {
        _full = TRUE;
    }
}

- (void)dequeue
{
    _front = (_front + 1) % _capacity;
    _full = FALSE;
}

- (void)lock
{
    [_mutex lock];
}

- (void)unlock
{
    [_mutex unlock];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -


@implementation FFVideoTrack

+ (id)videoTrackWithAVStream:(AVStream*)stream index:(int)index
{
    return [[[FFVideoTrack alloc] initWithAVStream:stream index:index] autorelease];
}

- (BOOL)initTrack:(int*)errorCode videoQueueCapacity:(int)videoQueueCapacity
                                     useFastDecoding:(BOOL)useFastDecoding
{
    _enabled = FALSE;
    _running = FALSE;

    // context->coded_width/height can be reset by -initContext.
    // so, we should remember them before -initContext.
    AVCodecContext* context = _stream->codec;
    float width = context->coded_width;
    float height= context->coded_height;

    // FIXME: temp. impl for convenience.
    if (useFastDecoding) {
        context->flags2 |= CODEC_FLAG2_FAST;
    }

    if (![super initTrack:errorCode]) {
        return FALSE;
    }
    
    // allocate frame
    _frame = avcodec_alloc_frame();
    if (_frame == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }

#if 1
    OSType qtPixFmt = ColorConversionDstForPixFmt(_stream->codec->pix_fmt);
    ColorConversionFindFor(&_colorConvFunc, _stream->codec->pix_fmt, _frame, qtPixFmt);
#else
    // init sw-scaler context
    _scalerContext = sws_getContext(width, height, context->pix_fmt,
                                    width, height, RGB_PIXEL_FORMAT,
                                    SWS_FAST_BILINEAR, 0, 0, 0);
    if (!_scalerContext) {
        TRACE(@"cannot initialize conversion context");
        *errorCode = ERROR_FFMPEG_SW_SCALER_INIT_FAILED;
        return FALSE;
    }
#endif

    // init playback
#ifndef _EXPERIMENTAL_AV_SYNC
    _packetQueue = [[PacketQueue alloc] initWithCapacity:30 * 5];  // 30 fps * 5 sec.
#endif
	_imageQueue = [[ImageQueue alloc] initWithCapacity:videoQueueCapacity
                                                 width:width height:height];
    _needKeyFrame = FALSE;
    _useFrameDrop = _stream->r_frame_rate.num / _stream->r_frame_rate.den > 30;
    _frameInterval = 1. * _stream->r_frame_rate.den / _stream->r_frame_rate.num;
    _seeked = FALSE;
    _decodeStarted = FALSE;
    _nextFrameTime = 0;
    _nextFramePts = 0;

#ifndef _EXPERIMENTAL_AV_SYNC
    _running = TRUE;
    [NSThread detachNewThreadSelector:@selector(decodeThreadFunc:)
                             toTarget:self withObject:nil];
#endif

    return TRUE;
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    CVReturn cvRet = CVOpenGLTextureCacheCreate(0, 0,
                                                [openGLContext CGLContextObj],
                                                [openGLPixelFormat CGLPixelFormatObj],
                                                0, &_textureCache);
	if (cvRet != kCVReturnSuccess) {
        //TRACE(@"CVOpenGLTextureCacheCreate() failed: %d", cvRet);
        if (error) {
            NSDictionary* dict =
            [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:cvRet]
                                        forKey:@"returnCode"];
            *error = [NSError errorWithDomain:@"FFVideoTrack"
                                         code:ERROR_VISUAL_CONTEXT_CREATE_FAILED
                                     userInfo:dict];
        }
        return FALSE;
    }
    return TRUE;
}

- (void)cleanupTrack
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    assert(!_running);
    if (_scalerContext) {
        av_free(_scalerContext);
        _scalerContext = 0;
    }
    if (_frame) {
        av_free(_frame);
        _frame = 0;
    }
    if (_textureCache) {
        CVOpenGLTextureCacheRelease(_textureCache);
        _textureCache = nil;
    }
    [_imageQueue release];
#ifndef _EXPERIMENTAL_AV_SYNC
    [_packetQueue release];
    _packetQueue = 0;
#endif

    [super cleanupTrack];
}

- (BOOL)isIndexComplete
{
    return _stream->nb_index_entries == _stream->nb_frames ||
           128 < _stream->nb_index_entries;
}

- (BOOL)isQueueEmpty
{
#ifdef _EXPERIMENTAL_AV_SYNC
    return [_imageQueue isEmpty];
#else
    return [_packetQueue isEmpty];
#endif
}

- (BOOL)isQueueFull
{
#ifdef _EXPERIMENTAL_AV_SYNC
    return [_imageQueue capacity] - 2 <= [_imageQueue count] || ![_movie canDecodeVideo];
#else
    return [_packetQueue isFull];
#endif
}

- (BOOL)isDecodeStarted
{
    return _decodeStarted;
}

- (void)seek:(double)time
{
    _seeked = TRUE;
}

- (void)enablePtsAdjust:(BOOL)enable
{
    _needPtsAdjust = enable;
}

#ifdef _EXPERIMENTAL_AV_SYNC
- (double)decodePacket:(AVPacket*)packet
#else
- (double)decodePacket
#endif
{
#ifndef _EXPERIMENTAL_AV_SYNC
    AVPacket packetInst;
    AVPacket* packet = &packetInst;
    if (![_packetQueue getPacket:packet]) {
        //TRACE(@"%s no more packet", __PRETTY_FUNCTION__);
        return -1;
    }
#endif

    if (packet->stream_index != _streamIndex) {
        TRACE(@"%s invalid stream_index %d", __PRETTY_FUNCTION__, packet->stream_index);
        if (packet->data != s_flushPacket.data) {
            av_free_packet(packet);
        }
        return -1;
    }
    assert(packet->stream_index == _streamIndex);

    if (packet->data == s_flushPacket.data) {
        TRACE(@"%s avcodec_flush_buffers", __PRETTY_FUNCTION__);
        avcodec_flush_buffers(_stream->codec);
        return -1;
    }

    int gotFrame;
    int bytesDecoded = avcodec_decode_video2(_stream->codec, _frame,
                                            &gotFrame, packet);
    av_free_packet(packet);
    if (bytesDecoded < 0) {
        TRACE(@"%s error while decoding frame", __PRETTY_FUNCTION__);
        return -1;
    }
    if (!gotFrame) {
        TRACE(@"%s incomplete decoded frame", __PRETTY_FUNCTION__);
        return -1;
    }

    int64_t pts = 0;
    if (packet->dts != AV_NOPTS_VALUE) {
        pts = packet->dts;
    }
    else if (_frame->opaque && *(uint64_t*)_frame->opaque != AV_NOPTS_VALUE) {
        pts = *(uint64_t*)_frame->opaque;
    }
    double time;
    double timeErr = (_nextFramePts - pts) * av_q2d(_stream->time_base);
    if (_needPtsAdjust && _seeked &&
        _frame->pict_type != FF_I_TYPE && packet->duration &&
        -1. < timeErr && timeErr < 1.) {
        time = (double)(_nextFramePts) * av_q2d(_stream->time_base);
        _nextFramePts += _frameInterval / av_q2d(_stream->time_base);
    }
    else {
        time = (double)(pts) * av_q2d(_stream->time_base);
        _nextFramePts = pts + _frameInterval / av_q2d(_stream->time_base);
    }
    //TRACE(@"[%s] frame flag %d pts %lld dts %lld pos %lld time %f timeErr %f", __PRETTY_FUNCTION__, 
    //      _frame->pict_type, 
    //      packet.pts, packet.dts,
    //      packet.pos, time, timeErr);
    return time;
}

- (BOOL)convertImage:(AVFrame*) frame
{
#if 1
    unsigned width = [_movie encodedSize].width;
    unsigned height = [_movie encodedSize].height;
    _colorConvFunc.convert(_frame, frame->data[0], frame->linesize[0], width, height);
#else
    // sw-scaler should be used under GPL only!
    int ret = sws_scale(_scalerContext,
                        _frame->data, _frame->linesize,
                        0, [_movie encodedSize].height,
                        frame->data, frame->linesize);
    if (ret < 0) {
        TRACE(@"%s sws_scale() failed : %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }
#endif
    return TRUE;
}

- (void)clearQueue
{
#ifdef _EXPERIMENTAL_AV_SYNC
    [self decodePacket:&s_flushPacket];
#else
    [_packetQueue clear];
    [self putPacket:&s_flushPacket];
#endif
    [_imageQueue clear];
}

- (void)putPacket:(AVPacket*)packet
{
#ifdef _EXPERIMENTAL_AV_SYNC
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    double frameTime = [self decodePacket:packet];
    if (frameTime < 0) {
        [pool release];
        return;
    }
    AVFrame* frame = [_imageQueue back];
    [self convertImage:frame];
    [_imageQueue enqueue:frame time:frameTime];
    [_movie videoTrack:self decodedTime:frameTime];
    [pool release];
#else
    av_dup_packet(packet);
    [_packetQueue putPacket:packet];
#endif
}

#ifndef _EXPERIMENTAL_AV_SYNC
- (void)decodeThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    /*
    TRACE(@"cur thread priority %f", [NSThread threadPriority]);
    [NSThread setThreadPriority:0.9];
    TRACE(@"set thread priority %f", [NSThread threadPriority]);
     */
    NSAutoreleasePool* pool;
    while (![_movie quitRequested]) {
        pool = [[NSAutoreleasePool alloc] init];
        _decodeStarted = TRUE;
        if ([_imageQueue capacity] - 3 <= [_imageQueue count] ||
            [_movie isPlayLocked] ||
            ![_movie canDecodeVideo]) {
            _decodeStarted = FALSE;
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            [pool release];
            continue;
        }
        double frameTime = [self decodePacket];
        if (frameTime < 0) {
            [pool release];
            _decodeStarted = FALSE;
            continue;
        }
        AVFrame* frame = [_imageQueue back];
        [self convertImage:frame];
        [_imageQueue enqueue:frame time:frameTime];
        [_movie videoTrack:self decodedTime:frameTime];
        _decodeStarted = FALSE;
        [pool release];
    }
    _running = FALSE;

    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}
#endif

- (BOOL)isNewImageAvailable:(double)hostTime
             hostTime0point:(double*)hostTime0point
{
    if ([_imageQueue isEmpty]) {
        //TRACE(@"not decoded %f", hostTime - *hostTime0point);
        return FALSE;
    }
    double current = hostTime - *hostTime0point;
    double imageTime = [_imageQueue time];
    if (imageTime + 0.5 < current || current + 0.5 < imageTime) {
        TRACE(@"reset av sync %f %f", current, imageTime);
        *hostTime0point = hostTime - imageTime;
        current = imageTime;
    }
    if (current < imageTime) {
        //TRACE(@"wait %f < %f", current, imageTime);
        return FALSE;
    }
    //TRACE(@"draw %f %f", current, imageTime);
    return TRUE;
}

- (CVOpenGLTextureRef)nextImage:(double)hostTime
                    currentTime:(double*)currentTime
                 hostTime0point:(double*)hostTime0point
{
    _dataPoppingStarted = TRUE;
    if ([_movie isPlayLocked]) {
        _dataPoppingStarted = FALSE;
        return 0;
    }
    [_imageQueue lock];
	if (![self isNewImageAvailable:hostTime
					hostTime0point:hostTime0point]) {
        [_imageQueue unlock];
        _dataPoppingStarted = FALSE;
		return 0;
	}

    //NSDate* begin = [NSDate date];
#define _DROP_FRAME_DISPLAY
#if defined(_DROP_FRAME_DISPLAY)
    int i = 0;
    CVPixelBufferRef pixelBuffer;
    do {
        i++;
        pixelBuffer = [_imageQueue pixelBuffer];
        *currentTime = [_imageQueue time];
        [_imageQueue dequeue];
    } while ([self isNewImageAvailable:hostTime hostTime0point:hostTime0point]);

    CVOpenGLTextureRef texture;
    int ret = CVOpenGLTextureCacheCreateTextureFromImage(0, _textureCache,
                                                         pixelBuffer, 0, &texture);
    if (ret != kCVReturnSuccess) {
        TRACE(@"CVOpenGLTextureCacheCreateTextureFromImage() failed : %d", ret);
    }
    CVOpenGLTextureCacheFlush(_textureCache, 0);
#else
    *currentTime = [_imageQueue time];

    CVOpenGLTextureRef texture;
    int ret = CVOpenGLTextureCacheCreateTextureFromImage(0, _textureCache,
                                                         [_imageQueue pixelBuffer],
                                                         0, &texture);
    if (ret != kCVReturnSuccess) {
        TRACE(@"CVOpenGLTextureCacheCreateTextureFromImage() failed : %d", ret);
    }
    CVOpenGLTextureCacheFlush(_textureCache, 0);

    [_imageQueue dequeue];
#endif
    //TRACE(@"nextImage (%.1f sec)", -[begin timeIntervalSinceNow]);

    [_imageQueue unlock];
    _dataPoppingStarted = FALSE;

    return texture;
}

@end

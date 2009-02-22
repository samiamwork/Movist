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
    free(_packet);
    [_mutex release];
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

@interface ImageQueue : NSObject
{
	AVFrame* _frame[MAX_VIDEO_DATA_BUF_SIZE];
	double _time[MAX_VIDEO_DATA_BUF_SIZE];
    unsigned int _capacity;
    unsigned int _front;
    unsigned int _rear;
    NSLock* _mutex;
}
@end

@implementation ImageQueue

- (id)init:(unsigned int)bufSize
	 width:(int)width
	height:(int)height
{
    self = [super init];
	if (!self) {
		return 0;
	}
	
	_capacity = bufSize;
    int i;
    for (i = 0; i < bufSize; i++) {
        _frame[i] = avcodec_alloc_frame();
        if (_frame[i] == 0) {
            TRACE(@"ERROR_FFMPEG_FRAME_ALLOCATE_FAILED");
            return FALSE;
        }    
        int bufWidth = width + 37;
        if (bufWidth < 512) {
            bufWidth = 512 + 37;
        }
        int bufSize = avpicture_get_size(RGB_PIXEL_FORMAT, bufWidth , height);
        avpicture_fill((AVPicture*)_frame[i], malloc(bufSize),
                       RGB_PIXEL_FORMAT, bufWidth, height);
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
            free(_frame[i]->data[0]);
            av_free(_frame[i]);
            _frame[i] = 0;
        }
    }
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
	return (_front == _rear); 
}

- (BOOL)isFull 
{ 
	return (_front == (_rear + 1) % _capacity); 
}

- (void)clear 
{ 
    _rear = _front; 
}

- (AVFrame*)front
{
	return _frame[_front];
}

- (AVFrame*)back 
{ 
	return _frame[_rear]; 
}

- (double)time 
{
	return _time[_front];
}

- (void)enqueue:(AVFrame*)frame time:(double)time
{
	[_mutex lock];
	_time[_rear] = time;
	_rear = (_rear + 1) % _capacity;
    [_mutex unlock];
}

- (void)dequeue
{
	[_mutex lock];
	_front = (_front + 1) % _capacity;
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

- (BOOL)initTrack:(int*)errorCode
{    
    _enabled = FALSE;
    _running = FALSE;

    // context->coded_width/height can be reset by -initContext.
    // so, we should remember them before -initContext.
    AVCodecContext* context = _stream->codec;
    float width = context->coded_width;
    float height= context->coded_height;

    if (![super initTrack:errorCode]) {
        return FALSE;
    }
    
    // allocate frame
    _frame = avcodec_alloc_frame();
    if (_frame == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }

    // init sw-scaler context
    _scalerContext = sws_getContext(width, height, context->pix_fmt,
                                    width, height, RGB_PIXEL_FORMAT,
                                    SWS_FAST_BILINEAR, 0, 0, 0);
    if (!_scalerContext) {
        TRACE(@"cannot initialize conversion context");
        *errorCode = ERROR_FFMPEG_SW_SCALER_INIT_FAILED;
        return FALSE;
    }

    // init playback
    _packetQueue = [[PacketQueue alloc] initWithCapacity:30 * 5];  // 30 fps * 5 sec.
	_imageQueue = [[ImageQueue alloc] init:MAX_VIDEO_DATA_BUF_SIZE width:width height:height];
    _needKeyFrame = FALSE;
    _useFrameDrop = _stream->r_frame_rate.num / _stream->r_frame_rate.den > 30;
    _frameInterval = 1. / (_stream->r_frame_rate.num / _stream->r_frame_rate.den);
	_seeked = FALSE;
	_nextFrameTime = 0;
	_nextFramePts = 0;

    _running = TRUE;
    [NSThread detachNewThreadSelector:@selector(decodeThreadFunc:)
                             toTarget:self withObject:nil];

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
	[_imageQueue release];
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

- (void)seek:(double)time
{
	_seeked = TRUE;
}

- (void)enablePtsAdjust:(BOOL)enable
{
	_needPtsAdjust = enable;
}

- (double)decodePacket
{
    //TRACE(@"%s(%d) %d", __PRETTY_FUNCTION__, _nextDataBufId, _decodedImageCount);
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

    int64_t pts = 0;
    if (packet.dts != AV_NOPTS_VALUE) {
        pts = packet.dts;
    }
    else if (_frame->opaque && *(uint64_t*)_frame->opaque != AV_NOPTS_VALUE) {
        pts = *(uint64_t*)_frame->opaque;
    }
	double time;
	double timeErr = (_nextFramePts - pts) * av_q2d(_stream->time_base);
	if (_needPtsAdjust && _seeked &&
		_frame->pict_type != FF_I_TYPE && packet.duration &&
		-1. < timeErr && timeErr < 1.) {
		//time = _nextFrameTime;
		time = (double)(_nextFramePts) * av_q2d(_stream->time_base);
		_nextFramePts += packet.duration;
	}
	else {
		time = (double)(pts) * av_q2d(_stream->time_base);
		_nextFramePts = pts + packet.duration;
	}
	//_nextFrameTime = time + _frameInterval;

//	static int64_t prevPts;
//	if (pts - prevPts != packet.duration) {
//		TRACE(@"pts %lld prevPts %lld duration %d", pts, prevPts, packet.duration);
//	}
//	prevPts = pts;
	
	//TRACE(@"%s %f %f %f", __PRETTY_FUNCTION__, pts, av_q2d(_stream->time_base), (double)(pts * av_q2d(_stream->time_base)));
    return time;
}

- (BOOL)convertImage:(AVFrame*) frame
{
    // sw-scaler should be used under GPL only!
    int ret = sws_scale(_scalerContext,
                        _frame->data, _frame->linesize,
                        0, [_movie encodedSize].height,
                        frame->data, frame->linesize);
    if (ret < 0) {
        TRACE(@"%s sws_scale() failed : %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }
    
    return TRUE;
}

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
        if ([_imageQueue capacity] - 3 <= [_imageQueue count] ||
            ![_movie canDecodeVideo]) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            [pool release];
            continue;
        }
        double frameTime = [self decodePacket];
        if (frameTime < 0) {
            [pool release];
            continue;
        }
		AVFrame* frame = [_imageQueue back];
        [self convertImage:frame];
		[_imageQueue enqueue:frame time:frameTime];
        [_movie videoTrack:self decodedTime:frameTime];
        [pool release];
    }
    _running = FALSE;

    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

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
	if (![self isNewImageAvailable:hostTime
					hostTime0point:hostTime0point]) {
		return 0;
	}
	
    *currentTime = [_imageQueue time];

    CVPixelBufferRef bufferRef = 0;
    NSSize size = [_movie encodedSize];
	AVFrame* frame = [_imageQueue front];
    int ret = CVPixelBufferCreateWithBytes(0, size.width, size.height,
                                           kYUVSPixelFormat,    // k32ARGBPixelFormat
                                           frame->data[0], 
                                           frame->linesize[0],
                                           0, 0, 0, // pixelBufferReleaseCallback, self, 0,
                                           &bufferRef);
    if (ret != kCVReturnSuccess) {
        TRACE(@"CVPixelBufferCreateWithBytes() failed : %d", ret);
    }
	
	[_imageQueue dequeue];
    return bufferRef;
}

@end

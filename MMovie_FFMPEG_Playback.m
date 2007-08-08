//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Updated by moosoy <moosoy@gmail.com>
//  Copyright 2006 cocoable, moosoy. All rights reserved.
//

#if defined(_SUPPORT_FFMPEG)

#import "MMovie_FFMPEG.h"

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
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    free(_packet);
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)clear { _rear = _front; }
- (BOOL)isEmpty { return (_front == _rear); }
- (BOOL)isFull { return (_front == (_rear + 1) % _capacity); }

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
    if ([self isEmpty]) {
        return FALSE;
    }
    *packet = _packet[_front];
    _front = (_front + 1) % _capacity;
    return TRUE;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -


@implementation MMovie_FFMPEG (Playback)

- (BOOL)defaultFuncCondition 
{ 
    return !_quitRequested && _reservedCommand == COMMAND_NONE; 
}

- (BOOL)initPlayback:(int*)errorCode;
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _quitRequested = FALSE;
    _dispatchPacket = FALSE;
    _command = COMMAND_NONE;
    _reservedCommand = COMMAND_NONE;
    _commandLock = [[NSConditionLock alloc] initWithCondition:0];
    _avSyncMutex = [[NSLock alloc] init];

    _videoQueue = [[PacketQueue alloc] initWithCapacity:30];  // 30 fps * 5 sec.
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        _audioDataQueue[i] = [[AudioDataQueue alloc] initWithCapacity:AVCODEC_MAX_AUDIO_FRAME_SIZE * 20];
    }
    av_init_packet(&_flushPacket);
    _flushPacket.data = (uint8_t*)"FLUSH";

    _currentTime = 0;
    _decodedImageTime = 0;
    _waitTime = 0;
    _hostTime = 0;

    _rate = 1.0;
    _playAfterSeek = FALSE;
    _seekKeyFrame = TRUE;

    [NSThread detachNewThreadSelector:@selector(playThreadFunc:)
                             toTarget:self withObject:nil];

    return TRUE;
}

- (void)cleanupPlayback
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // quit and wait for play-thread is finished

    if (_command == COMMAND_NONE) { // awake if waiting for command
        TRACE(@"%s awake", __PRETTY_FUNCTION__);
        [_commandLock unlockWithCondition:1];
    }
    TRACE(@"%s waiting for finished...", __PRETTY_FUNCTION__);
    while (_playThreading) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    TRACE(@"%s waiting done", __PRETTY_FUNCTION__);
    [_videoQueue release], _videoQueue = 0;
    [_commandLock release];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define DEFAULT_FUNC_CONDITION  (!_quitRequested && _reservedCommand == COMMAND_NONE)

- (BOOL)readFrame
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    AVPacket packet;
    if (av_read_frame(_formatContext, &packet) < 0) {
        TRACE(@"%s read-error or end-of-file", __PRETTY_FUNCTION__);
        return FALSE;
    }
    PacketQueue* queue = nil;
    if (packet.stream_index == _videoStreamIndex) {
        queue = _videoQueue;
        if (!queue) {
            av_free_packet(&packet);
            return TRUE;
        }
        
        av_dup_packet(&packet);
        while (!_quitRequested && ![queue putPacket:&packet]) {
            //TRACE(@"%s queue full => retry", __PRETTY_FUNCTION__);
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
        return TRUE;
    }
    
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        if (packet.stream_index == _audioStreamIndex[i]) {
            [self decodeAudio:&packet trackId:i];
            break;
        }
    }
    return TRUE;
}

- (void)waitForQueueEmpty:(PacketQueue*)queue
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    while (DEFAULT_FUNC_CONDITION) {
        if ([queue isEmpty]) {
            break;
        }
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark command handler

- (void)reserveCommand:(int)cmd
{
    [_commandLock lock];
    TRACE(@"%s %@", __PRETTY_FUNCTION__,
          (cmd == COMMAND_STEP_BACKWARD) ? @"STEP_BACKWARD" :
          (cmd == COMMAND_STEP_FORWARD)  ? @"STEP_FORWARD" :
          (cmd == COMMAND_SEEK)          ? @"SEEK" :
          (cmd == COMMAND_PLAY)          ? @"PLAY" :
          (cmd == COMMAND_PAUSE)         ? @"PAUSE" : @"NONE");
    _reservedCommand = cmd;
    [_commandLock unlockWithCondition:1];
}

- (void)stepBackwardFunc
{
    TRACE(@"%s not implemented yet", __PRETTY_FUNCTION__);
    //_seekTime = _reservedSeekTime;
}

- (void)stepForwardFunc
{
    TRACE(@"%s not implemented yet", __PRETTY_FUNCTION__);
    //_seekTime = _reservedSeekTime;
}

- (void)seekFunc
{
    TRACE(@"%s seek to %g", __PRETTY_FUNCTION__, _seekTime);
    [_videoQueue clear];
    [_videoQueue putPacket:&_flushPacket];
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        //[_audioPacketQueue[i] putPacket:&_flushPacket]; // need to flush audio
        [_audioDataQueue[i] clear];
        _nextDecodedAudioTime[i] = 0;
    }
    _seekTime = _reservedSeekTime;
    int mode = 0;
    if (_seekTime < _currentTime) {
        mode |= AVSEEK_FLAG_BACKWARD;
    }
    int64_t pos = av_rescale_q((int64_t)(_seekTime * AV_TIME_BASE),
                               AV_TIME_BASE_Q, _videoStream->time_base);
    //TRACE(@"%s rescaled pos = %lld", __PRETTY_FUNCTION__, pos);
    int ret = av_seek_frame(_formatContext, _videoStreamIndex,
                            pos, mode);
    if (ret < 0) {
        TRACE(@"%s error while seeking", __PRETTY_FUNCTION__);
    }
    else {
        _imageDecoded = FALSE;
        _dispatchPacket = TRUE;
        while (DEFAULT_FUNC_CONDITION && _dispatchPacket) {
            if (![_videoQueue isFull]) {
                if (![self readFrame]) {
                    break;
                }
            }
        }
        _dispatchPacket = FALSE;
        if (_playAfterSeek) {
            TRACE(@"%s continue play", __PRETTY_FUNCTION__);
            [self setRate:_rate];
        }
    }
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

- (void)playFunc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    //_hostTime = 0;
    _playAfterSeek = TRUE;
    _dispatchPacket = TRUE;
    while (DEFAULT_FUNC_CONDITION) {
        if (![self readFrame]) {
            TRACE(@"%s read failed : no more frame", __PRETTY_FUNCTION__);
            break;
        }
    }
    if (!_quitRequested) {
        [self waitForQueueEmpty:_videoQueue];
        _dispatchPacket = FALSE;
    }
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

- (void)pauseFunc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _dispatchPacket = FALSE;
    _playAfterSeek = FALSE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark public interface

- (float)currentTime { return _currentTime; }
- (float)rate { return (_command == COMMAND_PLAY) ? _rate : 0.0; }

- (void)setRate:(float)rate
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, rate);
    if (rate == 0.0) {
        [self reserveCommand:COMMAND_PAUSE];
    }
    else {
        _rate = rate;
        [self reserveCommand:COMMAND_PLAY];
    }
}

- (void)stepBackward
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self reserveCommand:COMMAND_STEP_BACKWARD];
}

- (void)stepForward
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self reserveCommand:COMMAND_STEP_FORWARD];
}

- (void)gotoBeginning
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _reservedSeekTime = 0;
    [self reserveCommand:COMMAND_SEEK];
}

- (void)gotoEnd
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _reservedSeekTime = [self duration];
    [self reserveCommand:COMMAND_SEEK];
}

- (void)gotoTime:(float)time
{
    if (_command == COMMAND_SEEK) {
        if (_reservedSeekTime == time || _seekTime == time) {
            TRACE(@"%s %g : currently seeking to same time => ignored", __PRETTY_FUNCTION__, time);
            return;
        }
        if ([_videoQueue isFull]) {     // seeking can be pended to put a packet
            _dispatchPacket = FALSE;    // stop pending to continue new seek
            [_videoQueue clear];
        }
    }
    TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    _reservedSeekTime = time;
    [self reserveCommand:COMMAND_SEEK];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)playThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    _playThreading = TRUE;

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    int prevCommand = COMMAND_NONE;
    while (!_quitRequested) {
        //TRACE(@"%s waiting for command-reservation", __PRETTY_FUNCTION__);
        [_commandLock lockWhenCondition:1];
        //TRACE(@"%s _reservedCommand = %d", __PRETTY_FUNCTION__, _reservedCommand);
        _command = _reservedCommand;
        _reservedCommand = COMMAND_NONE;
        [_commandLock unlockWithCondition:0];
        
        if (_command == COMMAND_PLAY) {
            // if end-of-movie, then restart from first.
            if (_currentTime == [self duration]) {
                _reservedSeekTime = 0;
                [self seekFunc];
            }
            [nc postNotificationName:MMovieRateChangeNotification object:self];
        }
        
        switch (_command) {
            case COMMAND_STEP_BACKWARD  : [self stepBackwardFunc];  break;
            case COMMAND_STEP_FORWARD   : [self stepForwardFunc];   break;
            case COMMAND_SEEK           : [self seekFunc];          break;
            case COMMAND_PLAY           : [self playFunc];          break;
            case COMMAND_PAUSE          : [self pauseFunc];         break;
        }
        prevCommand = _command;
        _command = COMMAND_NONE;

        if (prevCommand == COMMAND_PLAY) {
            if (_reservedCommand == COMMAND_PAUSE) {
                [nc postNotificationName:MMovieRateChangeNotification object:self];
            }
            else if (DEFAULT_FUNC_CONDITION) {
                _currentTime = [self duration];
                [nc postNotificationName:MMovieCurrentTimeNotification object:self];
                [nc postNotificationName:MMovieEndNotification object:self];
            }
        }
    }

    _playThreading--;
    [pool release];
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)decodeVideo
{
    AVPacket packet;
    if (![_videoQueue getPacket:&packet]) {
        TRACE(@"%s no more packet", __PRETTY_FUNCTION__);
        return -1;
    }
    assert(packet.stream_index == _videoStreamIndex);

    if (packet.data == _flushPacket.data) {
        avcodec_flush_buffers(_videoStream->codec);
        return -1;
    }

    int gotFrame;
    int bytesDecoded = avcodec_decode_video(_videoContext, _videoFrame,
                                            &gotFrame, packet.data, packet.size);
    av_free_packet(&packet);
    if (bytesDecoded < 0) {
        TRACE(@"%s error while decoding frame", __PRETTY_FUNCTION__);
        return -1;
    }
    if (!gotFrame) {
        //TRACE(@"%s incomplete decoded frame", __PRETTY_FUNCTION__);
        return -1;
    }

    double pts = 0;
    if (packet.dts != AV_NOPTS_VALUE) {
        pts = packet.dts;
    }
    else if (_videoFrame->opaque && *(uint64_t*)_videoFrame->opaque != AV_NOPTS_VALUE) {
        pts = *(uint64_t*)_videoFrame->opaque;
    }
    return (float)(pts * av_q2d(_videoStream->time_base));
}

- (BOOL)convertImage
{
    /* img_convert() is deprecated...
    int ret = img_convert((AVPicture*)_videoFrameRGB, RGB_PIXEL_FORMAT,
                          (AVPicture*)_videoFrame, _videoContext->pix_fmt,
                          _videoWidth, _videoHeight);
    if (ret < 0) {
        TRACE(@"%s img_convert() failed: %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }
    */
    // sw-scaler should be used under GPL only!
    int ret = sws_scale(_scalerContext,
                        _videoFrame->data, _videoFrame->linesize, 0, _videoHeight,
                        _videoFrameRGB->data, _videoFrameRGB->linesize);
    if (ret < 0) {
        TRACE(@"%s sws_scale() failed : %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }

    #if RGB_PIXEL_FORMAT == PIX_FMT_BGRA
    // convert BGRA to ARGB
    unsigned int* p = (unsigned int*)_videoFrameRGB->data[0];
    unsigned int* e = p + (_videoWidth + 17) * _videoHeight;
    while (p < e) {
        #if defined(__i386__) && defined(__GNUC__)
        __asm__("bswap %0" : "+r" (*p));
        #elif defined(__ppc__) && defined(__GNUC__)
        __asm__("lwbrx %0,0,%1" : "=r" (*p) : "r" (p), "m" (*p));
        #else
        *p = ((*p >> 24) & 0x000000FF) | ((*p >> 8) & 0x0000FF00) |
             ((*p << 24) & 0xFF000000) | ((*p << 8) & 0x00FF0000);
        #endif
        p++;
    }
    #endif
    return TRUE;
}

- (BOOL)isNewImageAvailable:(const CVTimeStamp*)timeStamp
{
    if (!_dispatchPacket || [_videoQueue isEmpty]) {
        //TRACE(@"%s video-queue is empty", __PRETTY_FUNCTION__);
        return FALSE;
    }
    
    if (!_imageDecoded) {
        if (_command == COMMAND_SEEK) {
            BOOL seekComplete = FALSE;
            while (DEFAULT_FUNC_CONDITION && !seekComplete) {
                _decodedImageTime = [self decodeVideo];
                if (_decodedImageTime < 0) {
                    return FALSE;
                }
                if (_seekKeyFrame || _seekTime <= _decodedImageTime) {
                    TRACE(@"%s seek complete", __PRETTY_FUNCTION__);
                    seekComplete = TRUE;
                    _dispatchPacket = FALSE;
                    _waitTime = 0;
                }
                //TRACE(@"%s seeking (%g < %g)", __PRETTY_FUNCTION__, _decodedImageTime, _seekTime);
            }
            if (!seekComplete) {    // quit requested or command reserved
                return FALSE;
            }
        }
        else {
            _decodedImageTime = [self decodeVideo];
            if (_decodedImageTime < 0) {
                return FALSE;
            }
            _waitTime += _decodedImageTime - _currentTime;
        }
        _imageDecoded = TRUE;
    }

    //float videoTime = (float)timeStamp->videoTime / timeStamp->videoTimeScale;
    float hostTime = (float)timeStamp->hostTime / 1000 / 1000 / 1000;
    float dt = hostTime - _hostTime;
    if (dt < _waitTime) {
        if (_waitTime < -1 || 1 < _waitTime) {
            _waitTime = 0;
        }
        //TRACE(@"%s not yet", __PRETTY_FUNCTION__);
        return FALSE;
    }
    _waitTime -= dt;
    if (_waitTime < -1 || 1 < _waitTime) {
        _waitTime = 0;
    }
    
    [_avSyncMutex lock];
    _hostTime = hostTime;
    _currentTime = _decodedImageTime;
    [_avSyncMutex unlock];

    return [self convertImage];
}

- (BOOL)getDecodedImage:(CVPixelBufferRef*)bufferRef
{

    int ret = CVPixelBufferCreateWithBytes(0, _videoWidth, _videoHeight, k32ARGBPixelFormat,
                                           _videoFrameRGB->data[0], _videoFrameRGB->linesize[0],
                                           0, 0, 0, bufferRef);
    if (ret != kCVReturnSuccess) {
        TRACE(@"%s CVPixelBufferCreateWithBytes() failed : %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }
	_imageDecoded = FALSE;
    return TRUE;
}

- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp
{
    if (![self isNewImageAvailable:timeStamp]) {
        return 0;
    }

    CVPixelBufferRef bufferRef = 0;
    if ([self getDecodedImage:&bufferRef]) {
        //TRACE(@"video %2.1f %llu", _currentTime, timeStamp->hostTime / 1000000000);
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MMovieCurrentTimeNotification object:self];
    }
    return bufferRef;
}

@end

#endif  // _SUPPORT_FFMPEG

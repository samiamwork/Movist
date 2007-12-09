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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

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

#define WAITING_FOR_COMMAND 0
#define DISPATCHING_COMMAND 1

@implementation MMovie_FFMPEG (Playback)

- (BOOL)defaultFuncCondition 
{ 
    return !_quitRequested && _reservedCommand == COMMAND_NONE; 
}

- (BOOL)initPlayback:(int*)errorCode;
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _quitRequested = FALSE;
    _fileEnded = FALSE;
    _dispatchPacket = FALSE;
    _command = COMMAND_NONE;
    _reservedCommand = COMMAND_NONE;
    _commandLock = [[NSConditionLock alloc] initWithCondition:WAITING_FOR_COMMAND];
    _avSyncMutex = [[NSLock alloc] init];
    _frameReadMutex = [[NSLock alloc] init];

    _videoQueue = [[PacketQueue alloc] initWithCapacity:30];  // 30 fps * 5 sec.
    _audioDataQueue = [[NSMutableArray alloc] initWithCapacity:MAX_AUDIO_STREAM_COUNT];
    int i;
    AudioDataQueue* audioQ;
    for (i = 0; i < _audioStreamCount; i++) {
        audioQ = [[AudioDataQueue alloc] initWithCapacity:AVCODEC_MAX_AUDIO_FRAME_SIZE * 20];
        [_audioDataQueue addObject:audioQ];
        [audioQ release];
    }
    av_init_packet(&_flushPacket);
    _flushPacket.data = (uint8_t*)"FLUSH";

    _currentTime = 0;
    for (i = 0; i < MAX_VIDEO_DATA_BUF_SIZE; i++) {
        _decodedImageTime[i] = 0;
    }
    _avFineTuningTime = 0;
    _hostTimeFreq = CVGetHostClockFrequency( );
    //TRACE(@"host time frequency %f", _hostTimeFreq);
    _hostTime = 0;
    _hostTime0point = 0;
    _needKeyFrame = FALSE;

    _rate = 1.0;
    _playAfterSeek = FALSE;
    _seekKeyFrame = TRUE;

    _lastDecodedTime = 0;
    _decodedImageCount = 0;
    _decodedImageBufCount = 0;
    _videoDataBufId = 0;
    _nextVideoBufId = 0;

    _playThreading = 0;
    [NSThread detachNewThreadSelector:@selector(backgroundThreadFunc:)
                             toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(videoDecodeThreadFunc:)
                             toTarget:self withObject:nil];
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
        [_commandLock unlockWithCondition:DISPATCHING_COMMAND];
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
    if ([_videoQueue isFull]) {
        assert(FALSE);
        return TRUE;
    }
    AVPacket packet;
    [_frameReadMutex lock];
    if (av_read_frame(_formatContext, &packet) < 0) {
        [_frameReadMutex unlock];
        TRACE(@"%s read-error or end-of-file", __PRETTY_FUNCTION__);
        return FALSE;
    }
    [_frameReadMutex unlock];
    _needKeyFrame = FALSE;
    
    PacketQueue* queue = nil;
    if (packet.stream_index == _videoStreamIndex) {
        queue = _videoQueue;
        if (!queue) {
            av_free_packet(&packet);
            return TRUE;
        }        
        av_dup_packet(&packet);
        [queue putPacket:&packet];
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
    [_commandLock unlockWithCondition:DISPATCHING_COMMAND];
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
    _seekTime = _reservedSeekTime;
    TRACE(@"%s seek to %g", __PRETTY_FUNCTION__, _seekTime);
    if (_needIndexing && _indexingTime < _seekTime) {
        TRACE(@"not indexed time");
        return;
    }
    [_videoQueue clear];
    [_videoQueue putPacket:&_flushPacket];
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        [[_audioDataQueue objectAtIndex:i] clear];
        [self decodeAudio:&_flushPacket trackId:i];
        _nextDecodedAudioTime[i] = 0;
    }
    if ([self duration] < _seekTime) {
        TRACE(@"file end %f < %f", [self duration], _seekTime);
        _fileEnded = TRUE;
        return;
    }
    int mode = _lastDecodedTime < _seekTime ? 0 : AVSEEK_FLAG_BACKWARD;
    int64_t pos = av_rescale_q((int64_t)(_seekTime * AV_TIME_BASE),
                       AV_TIME_BASE_Q, _videoStream->time_base);
    [_frameReadMutex lock];
    int ret = av_seek_frame(_formatContext, _videoStreamIndex, pos, mode);
    [_frameReadMutex unlock];
    if (ret < 0) {
        TRACE(@"%s error while seeking", __PRETTY_FUNCTION__);
        _fileEnded = TRUE;
        return;
    }
    _dispatchPacket = TRUE;
    _seekComplete = FALSE;
    while (!_quitRequested && !_seekComplete) {
        if ([_videoQueue isFull]) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            continue;
        }
        if (![self readFrame]) {
            return;
        }
    }
    _seekComplete = FALSE;
    _dispatchPacket = FALSE;
    if (_playAfterSeek && _reservedCommand == COMMAND_NONE) {
        TRACE(@"%s continue play", __PRETTY_FUNCTION__);
        [self setRate:_rate];
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.03]];
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
        if ([_videoQueue isFull]) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            continue;
        }
        if (![self readFrame]) {
            TRACE(@"%s read failed : no more frame", __PRETTY_FUNCTION__);
            break;
        }
    }
    if (!_quitRequested) {
        [self waitForQueueEmpty:_videoQueue];
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
        if ((int)_reservedSeekTime == (int)time || 
            (int)_seekTime == (int)time) {
            TRACE(@"%s %g : currently seeking to same time => ignored", __PRETTY_FUNCTION__, time);
            return;
        }
    }
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    _reservedSeekTime = time;
    [self reserveCommand:COMMAND_SEEK];
}

- (void)seekByTime:(float)dt
{    
    TRACE(@"%s %g", __PRETTY_FUNCTION__, dt);
    float time = _lastDecodedTime + dt;
    if (time < 0) {
        time = 0;
    }
    //time = (dt < 0) ? MAX(0, time) : MIN(time, [self duration]);
    [self gotoTime:time];
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, dt);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)playThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    _playThreading++;

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    int prevCommand = COMMAND_NONE;
    while (!_quitRequested) {
        //TRACE(@"%s waiting for command-reservation", __PRETTY_FUNCTION__);
        [_commandLock lockWhenCondition:DISPATCHING_COMMAND];
        //TRACE(@"%s _reservedCommand = %d", __PRETTY_FUNCTION__, _reservedCommand);
        _command = _reservedCommand;
        _reservedCommand = COMMAND_NONE;
        [_commandLock unlockWithCondition:WAITING_FOR_COMMAND];
        
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
        if (_fileEnded) {
            [nc postNotificationName:MMovieEndNotification object:self];
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
    //TRACE(@"%s(%d) %d %d", __PRETTY_FUNCTION__, _nextVideoBufId, _decodedImageCount, _decodedImageBufCount);
    AVPacket packet;
    if (![_videoQueue getPacket:&packet]) {
        //TRACE(@"%s no more packet", __PRETTY_FUNCTION__);
        return -1;
    }
    if (packet.stream_index != _videoStreamIndex) {
        TRACE(@"%s invalid stream_index %d", __PRETTY_FUNCTION__, packet.stream_index);
        return -1;
    }
    assert(packet.stream_index == _videoStreamIndex);

    if (packet.data == _flushPacket.data) {
        TRACE(@"%s avcodec_flush_buffers", __PRETTY_FUNCTION__);
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
        TRACE(@"%s incomplete decoded frame", __PRETTY_FUNCTION__);
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
    // sw-scaler should be used under GPL only!
    int ret = sws_scale(_scalerContext,
                        _videoFrame->data, _videoFrame->linesize, 0, _videoHeight,
                        _videoFrameData[_nextVideoBufId]->data, _videoFrameData[_nextVideoBufId]->linesize);
    if (ret < 0) {
        TRACE(@"%s sws_scale() failed : %d", __PRETTY_FUNCTION__, ret);
        return FALSE;
    }
    
    return TRUE;
}

- (void)discardImage
{
    _decodedImageCount--;
    _decodedImageBufCount--;
    _videoDataBufId = (_videoDataBufId + 1) % MAX_VIDEO_DATA_BUF_SIZE;
    TRACE(@"discard image");
}

- (BOOL)isNewImageAvailable:(const CVTimeStamp*)timeStamp
{
    if (_decodedImageCount < 1) {
        //TRACE(@"not decoded %f", current);
        return FALSE;
    }
    //float videoTime = (float)timeStamp->videoTime / timeStamp->videoTimeScale;
    float hostTime = (float)timeStamp->hostTime / _hostTimeFreq;
    float current = hostTime - _hostTime0point;
    float imageTime = _decodedImageTime[_videoDataBufId];
    if (imageTime + 1 < current || current + 1 < imageTime) {
        TRACE(@"reset av sync %f %f", current, imageTime);
        _hostTime0point = hostTime - imageTime;
        current = imageTime;
    }
    //#define _FRAME_DROP
    #ifdef _FRAME_DROP
    while (imageTime + 1. / 60 < current) {
        if (_decodedImageCount > 0) {
            [self discardImage];
            imageTime = _decodedImageTime[_videoDataBufId];
        }
        else {
            return FALSE;
        }
    }
    #endif
    if (current + 0.002 < imageTime) {
        //TRACE(@"wait(%d) %f < %f", _videoDataBufId, current, imageTime);
        return FALSE;
    }
    _decodedImageCount--;
    _hostTime0point -= _avFineTuningTime;
    //TRACE(@"draw(%d) %f %f", _videoDataBufId, current, imageTime);
    return TRUE;
}

void pixelBufferReleaseCallback(void *releaseRefCon, const void *baseAddress)
{
    int* decodedImageBufCount = (int*)releaseRefCon;
    (*decodedImageBufCount)--;
    //TRACE(@"[%s] bufcount %d", __PRETTY_FUNCTION__, *decodedImageBufCount);
}

- (BOOL)getDecodedImage:(CVPixelBufferRef*)bufferRef
{
    OSType CV_PIXEL_FORMAT;
    if (RGB_PIXEL_FORMAT == PIX_FMT_BGRA) {
        CV_PIXEL_FORMAT = k32ARGBPixelFormat;
    }
    else {
        CV_PIXEL_FORMAT = kYUVSPixelFormat;
    }
    int ret = CVPixelBufferCreateWithBytes(0, _videoWidth, _videoHeight, CV_PIXEL_FORMAT,
                                           _videoFrameData[_videoDataBufId]->data[0], 
                                           _videoFrameData[_videoDataBufId]->linesize[0],
                                           pixelBufferReleaseCallback, &_decodedImageBufCount, 0, 
                                           bufferRef);
    if (ret != kCVReturnSuccess) {
        TRACE(@"%s CVPixelBufferCreateWithBytes() failed : %d", __PRETTY_FUNCTION__, ret);
        assert(FALSE);
        return FALSE;
    }
    return TRUE;
}

- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp
{
    if (![self isNewImageAvailable:timeStamp]) {
        return 0;
    }
    float hostTime = (float)timeStamp->hostTime / _hostTimeFreq;
    [_avSyncMutex lock];
    _hostTime = hostTime;
    _currentTime = _decodedImageTime[_videoDataBufId];
    [_avSyncMutex unlock];
    CVPixelBufferRef bufferRef = 0;
    if ([self getDecodedImage:&bufferRef]) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MMovieCurrentTimeNotification object:self];
    }
    //TRACE(@"display(%d) %f", _videoDataBufId, _currentTime);
    _videoDataBufId = (_videoDataBufId + 1) % MAX_VIDEO_DATA_BUF_SIZE;    
    return bufferRef;
}

- (void)videoDecodeThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _playThreading++;
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
/*
    TRACE(@"cur thread priority %f", [NSThread threadPriority]);
    [NSThread setThreadPriority:0.9];
    TRACE(@"set thread priority %f", [NSThread threadPriority]);
*/
    while (!_quitRequested) {
        if (_decodedImageBufCount >= MAX_VIDEO_DATA_BUF_SIZE - 1 ||
            !_dispatchPacket) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            continue;
        }
        if (_command == COMMAND_SEEK && _seekComplete) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            continue;
        }
        _decodedImageTime[_nextVideoBufId] = [self decodeVideo];
        if (_decodedImageTime[_nextVideoBufId] < 0) {
            continue;
        }
        [self convertImage];
        if (_command == COMMAND_SEEK) {
            _seekComplete = TRUE;
        }
        _lastDecodedTime = _decodedImageTime[_nextVideoBufId];
        //TRACE(@"decoded(%d,%d:%d) %f", _decodedImageBufCount, 
        //                               _decodedImageCount, 
        //                               _nextVideoBufId, 
        //                               _lastDecodedTime);
        _decodedImageBufCount++;
        _decodedImageCount++;
        _nextVideoBufId = (_nextVideoBufId + 1) % MAX_VIDEO_DATA_BUF_SIZE;
    }
    [pool release];
    _playThreading--;
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

@end

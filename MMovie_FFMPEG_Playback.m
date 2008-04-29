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

#define WAITING_FOR_COMMAND 0
#define DISPATCHING_COMMAND 1

@implementation MMovie_FFmpeg (Playback)

- (BOOL)initPlayback:(int*)errorCode;
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _quitRequested = FALSE;
    _fileEnded = FALSE;
    _dispatchPacket = FALSE;
    _command = COMMAND_NONE;
    _reservedCommand = COMMAND_NONE;
    _commandLock = [[NSConditionLock alloc] initWithCondition:WAITING_FOR_COMMAND];
    //_avSyncMutex = [[NSLock alloc] init];
    _frameReadMutex = [[NSLock alloc] init];

    _rate = 1.0;
    _playAfterSeek = FALSE;
    _seekKeyFrame = TRUE;

    _currentTime = 0;
    _hostTime = 0;
    _hostTime0point = 0;

    _running = TRUE;
    [NSThread detachNewThreadSelector:@selector(playThreadFunc:)
                             toTarget:self withObject:nil];
    return TRUE;
}

- (void)cleanupPlayback
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // quit and wait for play-thread is finished
    // awake if waiting for command
    [_commandLock lock];
    _reservedCommand = COMMAND_NONE;
    [_commandLock unlockWithCondition:DISPATCHING_COMMAND];

    TRACE(@"%s waiting for finished...", __PRETTY_FUNCTION__);
    while ([self isRunning]) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    TRACE(@"%s waiting done", __PRETTY_FUNCTION__);
    [_commandLock release];
}

- (int)command { return _command; }
- (int)reservedCommand { return _reservedCommand; }
- (BOOL)isRunning { return _running; }
- (BOOL)quitRequested { return _quitRequested; }

- (double)hostTimeFreq { return _hostTimeFreq; }
- (double)hostTime0point { return _hostTime0point; }

- (BOOL)canDecodeVideo
{
    return _dispatchPacket && (_command != COMMAND_SEEK || !_seekComplete);
}

- (void)videoTrack:(FFVideoTrack*)videoTrack decodedTime:(double)time
{
    if (videoTrack == _mainVideoTrack) {
        if (_command == COMMAND_SEEK) {
            _seekComplete = TRUE;
        }
        _lastDecodedTime = time;
    }
}

- (void)audioTrack:(FFAudioTrack*)audioTrack avFineTuningTime:(double)time
{
    if (audioTrack == _mainAudioTrack) {
        _avFineTuningTime = time;
        if (time != 0) {
            TRACE(@"finetuning %f", time);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define DEFAULT_FUNC_CONDITION  (!_quitRequested && _reservedCommand == COMMAND_NONE)

- (BOOL)readFrame
{
    FFVideoTrack* vTrack;
    NSEnumerator* enumerator = [_videoTracks objectEnumerator];
    while (vTrack = (FFVideoTrack*)[[enumerator nextObject] impl]) {
        if ([vTrack isQueueFull]) {
            return TRUE;
        }
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

    enumerator = [_videoTracks objectEnumerator];
    while (vTrack = (FFVideoTrack*)[[enumerator nextObject] impl]) {
        if ([vTrack isEnabled] && [vTrack streamIndex] == packet.stream_index) {
            av_dup_packet(&packet);
            [vTrack putPacket:&packet];
            return TRUE;
        }
    }

    FFAudioTrack* aTrack;
    enumerator = [_audioTracks objectEnumerator];
    while (aTrack = (FFAudioTrack*)[[enumerator nextObject] impl]) {
        if ([aTrack isEnabled] &&
            [aTrack streamIndex] == packet.stream_index) {
            [aTrack putPacket:&packet];
            return TRUE;
        }
    }
    return TRUE;
}

- (void)waitForVideoQueueEmpty:(FFVideoTrack*)track
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    while (DEFAULT_FUNC_CONDITION) {
        if ([track isQueueEmpty]) {
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
    if (_indexedDuration < _seekTime) {
        TRACE(@"not indexed time");
        return;
    }

    MTrack* track;
    NSEnumerator* enumerator = [_videoTracks objectEnumerator];
    while (track = [enumerator nextObject]) {
        [(FFVideoTrack*)[track impl] clearQueue];
    }
    enumerator = [_audioTracks objectEnumerator];
    while (track = [enumerator nextObject]) {
        if ([[track impl] isEnabled]) {
            [(FFAudioTrack*)[track impl] clearQueue];
        }
    }

    if ([self duration] < _seekTime) {
        TRACE(@"file end %f < %f", [self duration], _seekTime);
        _fileEnded = TRUE;
        return;
    }

    int mode = _lastDecodedTime < _seekTime ? 0 : AVSEEK_FLAG_BACKWARD;
    int64_t pos = av_rescale_q((int64_t)(_seekTime * AV_TIME_BASE),
                               AV_TIME_BASE_Q, [_mainVideoTrack stream]->time_base);
    [_frameReadMutex lock];
    int ret = av_seek_frame(_formatContext, [_mainVideoTrack streamIndex], pos, mode);
    [_frameReadMutex unlock];
    if (ret < 0) {
        TRACE(@"%s error while seeking", __PRETTY_FUNCTION__);
        _fileEnded = TRUE;
        return;
    }
    _dispatchPacket = TRUE;
    _seekComplete = FALSE;
    while (!_quitRequested && !_seekComplete) {
        if ([_mainVideoTrack isQueueFull]) {
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
        if ([_mainVideoTrack isQueueFull]) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            continue;
        }
        if (![self readFrame]) {
            TRACE(@"%s read failed : no more frame", __PRETTY_FUNCTION__);
            break;
        }
    }
    if (!_quitRequested) {
        [self waitForVideoQueueEmpty:_mainVideoTrack];
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

- (float)currentTime { return _currentTime - _startTime; }
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
            if (_currentTime == _duration) {
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
    [pool release];
    _running = FALSE;

    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp
{
    double hostTime = (double)timeStamp->hostTime / _hostTimeFreq;
    [_trackMutex lock];
    if (!_mainVideoTrack ||
        ![_mainVideoTrack isNewImageAvailable:hostTime
                               hostTime0point:&_hostTime0point]) {
        [_trackMutex unlock];
        return 0;
    }

    _hostTime = hostTime;
    _hostTime0point -= _avFineTuningTime;

    if (!_mainVideoTrack) {
        [_trackMutex unlock];
        return 0;
    }
    CVOpenGLTextureRef image = [_mainVideoTrack nextImage:&_currentTime];
    [_trackMutex unlock];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:MMovieCurrentTimeNotification object:self];

    return image;
}

@end

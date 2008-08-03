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

#import "MSubtitle.h"
#import "MSubtitleItem.h"

@interface MSubtitle (Private)

- (int)makeTexImagesFrom:(int)firstIndex to:(int)lastIndex baseTime:(float)baseTime;
- (void)releaseTexImagesFrom:(int)firstIndex to:(int)lastIndex;
- (void)remakeAllTexImages;
- (void)remakeTexImagesForBeyondBackwardSeek;
- (void)remakeTexImagesForBeyondForwardSeek;
- (void)remakeTexImagesForInsideReleaseRange:(int)index;

@end

@implementation MSubtitle (Render)

- (MMovieOSD*)movieOSD { return _movieOSD; }
- (float)forwardRenderInterval  { return _forwardRenderInterval; }
- (float)backwardRenderInterval { return _backwardRenderInterval; }
- (BOOL)renderingEnabled        { return _renderingEnabled; }

- (void)setMovieOSD:(MMovieOSD*)movieOSD
{
    [movieOSD retain], [_movieOSD release], _movieOSD = movieOSD;
}

- (void)setForwardRenderInterval:(float)interval  { _forwardRenderInterval = interval; }
- (void)setBackwardRenderInterval:(float)interval { _backwardRenderInterval = interval; }

- (void)setRenderingEnabled:(BOOL)enabled
{
    _renderingEnabled = enabled;

    if (_renderingEnabled) {
        [self setNeedsRemakeTexImages];
    }
}

- (void)initRenderInfo
{
    _releaseBeginIndex = 0;
    _releaseEndIndex = -1;
    _renderStamp = 0;
    _lastRenderStamp = -1;
    _lastSeekIndex = _seekIndex;
    _lastPlayIndex = _playIndex;
    _renderThreadRunning = FALSE;
    _quitRenderThreadRequested = FALSE;
    _renderingEnabled = TRUE;
}

- (void)startRenderThread
{
    TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [self name]);
    if (!_renderThreadRunning) {
        [self initRenderInfo];
        [NSThread detachNewThreadSelector:@selector(renderThreadFunc:)
                                 toTarget:self withObject:nil];
    }
}

- (void)quitRenderThread
{
    if (_renderThreadRunning && !_quitRenderThreadRequested) {
        TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [self name]);
        _quitRenderThreadRequested = TRUE;
        // wake up render thread
        [_renderConditionLock lock];
        [_renderConditionLock unlockWithCondition:1];

        while (_renderThreadRunning) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
        [self releaseTexImagesFrom:_releaseBeginIndex to:_releaseEndIndex];
    }
}

- (void)setNeedsRemakeTexImages
{
    _renderStamp++;
    
    // wake up renderh thread
    [_renderConditionLock lock];
    [_renderConditionLock unlockWithCondition:1];
}

- (void)updatePlaySeekIndexes:(int)index isSeek:(BOOL)isSeek
{
    BOOL remakeNeeded = FALSE;
    if (_playIndex != index) {
        _playIndex = index;
        remakeNeeded = TRUE;
        //TRACE(@"%s _playIndex : %d", __PRETTY_FUNCTION__, _playIndex);
    }
    if (isSeek && _seekIndex != index) {
        _seekIndex = index;
        remakeNeeded = TRUE;
        //TRACE(@"%s _seekIndex : %d", __PRETTY_FUNCTION__, _seekIndex);
    }
    if (remakeNeeded) {
        // wake up render thread
        [_renderConditionLock lock];
        [_renderConditionLock unlockWithCondition:1];
    }
}

- (NSImage*)texImageAtTime:(float)time direction:(int)direction
                renderFlag:(BOOL*)renderFlag
{
    if (!_renderingEnabled) {
        return nil;
    }

    BOOL seek = (1.0 <= ABS(_lastPlayTime - time));
    _lastPlayTime = time;

    int index = [self indexAtTime:time direction:direction];
    if (index < 0) {
        index = [self indexAtTime:time direction:+1];   // find forward item
        if (0 <= index) {
            [self updatePlaySeekIndexes:index isSeek:seek];
        }
        *renderFlag = FALSE;    // no subtitle-item at time
        return nil;
    }
    [self updatePlaySeekIndexes:index isSeek:seek];

    if (*renderFlag) {          // instant rendering
        // if valid tex-image is returned, then renderFlag is ignored.
        return [[_items objectAtIndex:index] makeTexImage:_movieOSD stamp:_renderStamp];
    }
    else {
        *renderFlag = TRUE;     // subtitle-item exist, but not rendered yet.
        return [[_items objectAtIndex:index] texImage:_renderStamp];
    }
}

- (void)renderThreadFunc:(id)anObject
{
    _renderThreadRunning = TRUE;

    NSAutoreleasePool* pool;
    while (!_quitRenderThreadRequested) {
        // waiting for new request.
        if (_lastRenderStamp == _renderStamp &&
            _lastSeekIndex == _seekIndex && _lastPlayIndex == _playIndex) {
            //TRACE(@"%s waiting for remake-request...", __PRETTY_FUNCTION__);
            [_renderConditionLock lockWhenCondition:1];
            [_renderConditionLock unlockWithCondition:0];
            //TRACE(@"%s waked up...", __PRETTY_FUNCTION__);
        }
        if (!_quitRenderThreadRequested && _renderingEnabled) {
            pool = [[NSAutoreleasePool alloc] init];
            if (_lastRenderStamp != _renderStamp) {
                _lastRenderStamp = _renderStamp;
                // sleep for too many remake-request in short times
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
                [self remakeAllTexImages];
            }
            else if (_lastSeekIndex != _seekIndex) {
                _lastSeekIndex = _seekIndex;
                if (_seekIndex < _releaseBeginIndex) {
                    [self remakeTexImagesForBeyondBackwardSeek];
                }
                else if (_releaseEndIndex < _seekIndex) {
                    [self remakeTexImagesForBeyondForwardSeek];
                }
                else if (_releaseBeginIndex != _seekIndex) {
                    [self remakeTexImagesForInsideReleaseRange:_seekIndex];
                }
            }
            else if (_lastPlayIndex != _playIndex) {
                _lastPlayIndex = _playIndex;
                if (_releaseBeginIndex != _playIndex) {
                    [self remakeTexImagesForInsideReleaseRange:_playIndex];
                }
            }
            [pool release];
        }
    }

    _renderThreadRunning = FALSE;
}

@end

@implementation MSubtitle (Private)

#define DIFF_TIME(t1, t2)    ((t2) - (t1))

- (int)makeTexImagesFrom:(int)firstIndex to:(int)lastIndex baseTime:(float)baseTime
{
    //TRACE(@"%s [%d]~[%d] %@", __PRETTY_FUNCTION__,
    //      firstIndex, lastIndex, NSStringFromMovieTime(baseTime));

    int i;
    float interval;
    MSubtitleItem* item;
    if (lastIndex < firstIndex) {
        lastIndex = [_items count] - 1;
    }
    for (i = firstIndex; i <= lastIndex; i++) {
        if (_quitRenderThreadRequested || _lastRenderStamp != _renderStamp ||
            _lastSeekIndex != _seekIndex || lastIndex < i ||
            _forwardRenderInterval < interval) {
            break;
        }
        item = [_items objectAtIndex:i];
        interval = DIFF_TIME(baseTime, [item beginTime]);
        #if defined(_DEBUG)
        //if (![item texImage:_renderStamp]) {
        //    TRACE(@"%s remaking [%d]", __PRETTY_FUNCTION__, i);
        //}
        #endif
        [item makeTexImage:_movieOSD stamp:_renderStamp];
        
        if (5.0 < interval) {   // if we have sufficient time, then sleep shortly.
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
        if (i < _playIndex) {
            //TRACE(@"%s i: %d => %d", __PRETTY_FUNCTION__, i, _playIndex);
            i = _playIndex;
        }
    }
    if (i <= lastIndex) {
        lastIndex = i;
    }
    if (_releaseEndIndex < lastIndex) {
        _releaseEndIndex = lastIndex;
    }
    return lastIndex;
}

- (void)releaseTexImagesFrom:(int)firstIndex to:(int)lastIndex
{
    //TRACE(@"%s [%d]~[%d]", __PRETTY_FUNCTION__, firstIndex, lastIndex);

    int i;
    MSubtitleItem* item;
    for (i = firstIndex; i <= lastIndex; i++) {
        item = [_items objectAtIndex:i];
        #if defined(_DEBUG)
        //if ([item texImage]) {
        //    TRACE(@"%s releasing [%d]", __PRETTY_FUNCTION__, i);
        //}
        #endif
        [item releaseTexImage];
    }
}

- (void)remakeAllTexImages
{
    //TRACE(@"%s remaking all", __PRETTY_FUNCTION__);

    // release all
    [self releaseTexImagesFrom:_releaseBeginIndex to:_releaseEndIndex];

    _releaseBeginIndex = _playIndex;
    _releaseEndIndex = -1;
    float time = [[_items objectAtIndex:_playIndex] endTime];
    [self makeTexImagesFrom:_playIndex to:-1 baseTime:time];

    //TRACE(@"%s release-range=[%d]~[%d]", __PRETTY_FUNCTION__,
    //      _releaseBeginIndex, _releaseEndIndex);
}

- (void)remakeTexImagesForBeyondBackwardSeek
{
    //TRACE(@"%s remaking for beyond backward seek : %d", __PRETTY_FUNCTION__, _seekIndex);

    int i;
    float interval, seekTime = [[_items objectAtIndex:_seekIndex] endTime];
    // release in release-range over _forwardRenderInterval.
    for (i = _releaseBeginIndex; i <= _releaseEndIndex; i++) {
        interval = DIFF_TIME(seekTime, [[_items objectAtIndex:i] beginTime]);
        if (_forwardRenderInterval < interval) {
            break;
        }
    }
    [self releaseTexImagesFrom:i to:_releaseEndIndex];
    _releaseEndIndex = (_releaseBeginIndex < i) ? (i - 1) : -1;

    // make between _seekIndex to _releaseEndIndex
    _releaseBeginIndex = _seekIndex;
    seekTime = [[_items objectAtIndex:_seekIndex] beginTime];
    [self makeTexImagesFrom:_seekIndex to:_releaseEndIndex baseTime:seekTime];

    //TRACE(@"%s release-range=[%d]~[%d]", __PRETTY_FUNCTION__,
    //      _releaseBeginIndex, _releaseEndIndex);
}

- (void)remakeTexImagesForBeyondForwardSeek
{
    //TRACE(@"%s remaking for beyond forward seek : %d", __PRETTY_FUNCTION__, _seekIndex);

    int i;
    float interval, seekTime = [[_items objectAtIndex:_seekIndex] beginTime];
    // release in release-range over _backwardRenderInterval.
    for (i = _releaseEndIndex; _releaseBeginIndex <= i; i--) {
        interval = DIFF_TIME([[_items objectAtIndex:i] endTime], seekTime);
        if (_backwardRenderInterval < interval) {
            break;
        }
    }
    [self releaseTexImagesFrom:_releaseBeginIndex to:i];
    _releaseBeginIndex = (i < _releaseEndIndex) ? (i + 1) : _seekIndex;

    // make between _seekIndex to _releaseEndIndex
    _releaseEndIndex = -1;
    [self makeTexImagesFrom:_seekIndex to:_releaseEndIndex baseTime:seekTime];

    //TRACE(@"%s release-range=[%d]~[%d]", __PRETTY_FUNCTION__,
    //      _releaseBeginIndex, _releaseEndIndex);
}

- (void)remakeTexImagesForInsideReleaseRange:(int)index
{
    //TRACE(@"%s remaking for inside release range : %d", __PRETTY_FUNCTION__, index);

    int i;
    float interval, time = [[_items objectAtIndex:index] beginTime];
    // release before index over _backwardRenderInterval.
    for (i = index; _releaseBeginIndex <= i; i--) {
        interval = DIFF_TIME([[_items objectAtIndex:i] endTime], time);
        if (_backwardRenderInterval < interval) {
            break;
        }
    }
    if (_releaseBeginIndex < i) {
        [self releaseTexImagesFrom:_releaseBeginIndex to:i];
        _releaseBeginIndex = (i < index) ? (i + 1) : index;
    }

    // make between index to _releaseEndIndex
    _releaseEndIndex = -1;
    [self makeTexImagesFrom:index to:_releaseEndIndex baseTime:time];

    //TRACE(@"%s release-range=[%d]~[%d]", __PRETTY_FUNCTION__,
    //      _releaseBeginIndex, _releaseEndIndex);
}

@end


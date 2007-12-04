//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim. All rights reserved.
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

#if defined(_USE_SUBTITLE_RENDERER)

#import "SubtitleRenderer.h"

#import "MMovieView.h"
#import "MSubtitle.h"
#import "MSubtitleOSD.h"

@interface MSubtitleStringImage : NSObject
{
    NSImage* _image;
    float _beginTime;
    float _endTime;
}

- (id)initWithStringImage:(NSImage*)image;

- (NSImage*)image;
- (float)beginTime;
- (float)endTime;
- (void)setBeginTime:(float)beginTime;
- (void)setEndTime:(float)endTime;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation MSubtitleStringImage

- (id)initWithStringImage:(NSImage*)image
{
    assert(image != nil);
    if (self = [super init]) {
        _image = [image retain];
    }
    return self;
}

- (void)dealloc
{
    [_image release];
    [super dealloc];
}

- (NSImage*)image { return _image; }
- (float)beginTime { return _beginTime; }
- (float)endTime { return _endTime; }
- (void)setBeginTime:(float)beginTime { _beginTime = beginTime; }
- (void)setEndTime:(float)endTime { _endTime = endTime; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation SubtitleRenderer

#define MAX_IMAGES_TIME_INTERVAL    10.0      // 10 sec.

#define WAITING         0
#define MAKING_IMAGE    1

- (id)initWithMovieView:(MMovieView*)movieView
            subtitleOSD:(MSubtitleOSD*)subtitleOSD;
{
    if (self = [super init]) {
        _movieView = [movieView retain];
        _subtitleOSD = [subtitleOSD retain];
        _subtitleImages = [[NSMutableArray alloc] initWithCapacity:5];
        _subtitlesLock = [[NSLock alloc] init];
        _conditionLock = [[NSConditionLock alloc] initWithCondition:WAITING];

        _subtitleImagesInterval = 0;
        _removeCount = 0;
        _requestedTime = 0;
        _canRequestNewTime = TRUE;
        _emptyImage = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];

        _quitRequested = FALSE;
        [NSThread detachNewThreadSelector:@selector(renderThreadFunc:)
                                 toTarget:self withObject:nil];
    }
    return self;
}

- (void)dealloc
{
    _quitRequested = TRUE;
    [_conditionLock unlockWithCondition:MAKING_IMAGE];
    while (_autoreleasePool != nil) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [_subtitleImages removeAllObjects];
    [_subtitleImages release];
    [_subtitleOSD release];
    [_subtitles release];
    [_movieView release];
    [_emptyImage release];
    [_subtitlesLock release];
    [_conditionLock release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setSubtitles:(NSArray*)subtitles
{
    [_subtitlesLock lock];
    [subtitles retain], [_subtitles release], _subtitles = subtitles;
    [self clearImages:0.0];
    [_subtitlesLock unlock];
}

- (void)clearImages:(float)requestedTime
{
    [_conditionLock lock];
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _removeCount = [_subtitleImages count];
    _requestedTime = requestedTime;
    _canRequestNewTime = FALSE;
    [_conditionLock unlockWithCondition:MAKING_IMAGE];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define NO_STRING       0
#define STRING_UPDATED  1
#define SAME_STRING     2

- (int)updateSubtitleOSD:(float)time
{
    [_subtitlesLock lock];

    int result = NO_STRING;
    MSubtitle* subtitle;
    NSMutableAttributedString* string;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        if ([subtitle isEnabled]) {
            string = [subtitle stringAtTime:time];
            if (string) {
                if ([_subtitleOSD setString:string forName:[subtitle name]]) {
                    result |= STRING_UPDATED;
                    //TRACE(@"%s subtitle(\"%@\"):[%.03f]\"%@\"", __PRETTY_FUNCTION__,
                    //      [subtitle name], time, [string string]);
                }
                else {
                    result |= SAME_STRING;
                    //TRACE(@"%s subtitle(\"%@\"):[%.03f]\"<same>\"", __PRETTY_FUNCTION__,
                    //      [subtitle name], time);
                }
            }
        }
    }
    [_subtitlesLock unlock];

    return result;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSImage*)imageAtTime:(float)time
{
    if ([_subtitles count] == 0) {
        //TRACE(@"%s [%.03f] no subtitles", __PRETTY_FUNCTION__, time);
        return _emptyImage;
    }

    [_conditionLock lock];
    MSubtitleStringImage* image;
    int i, count = [_subtitleImages count];
    for (i = 0; i < count; i++) {
        image = [_subtitleImages objectAtIndex:i];
        if (time < [image beginTime]) {
            break;
        }
        else if (time < [image endTime]) {
            if (0 == i) {
                //TRACE(@"%s [%.03f] image[%d] => ok", __PRETTY_FUNCTION__, time, i);
                int condition = (0 < _removeCount || 0 <= _requestedTime) ?
                                    MAKING_IMAGE : [_conditionLock condition];
                [_conditionLock unlockWithCondition:condition];
            }
            else {
                if (_removeCount < i) {
                    //TRACE(@"%s [%.03f] image[%d] => need to remove oldest %d",
                    //      __PRETTY_FUNCTION__, time, i, i);
                    _removeCount = i;
                }
                [_conditionLock unlockWithCondition:MAKING_IMAGE];
            }
            return [image image];
        }
    }
    // clear & remake _subtitleImages
    NSImage* resultImage = _emptyImage;
    if (_canRequestNewTime || [[_movieView movie] rate] == 0.0) {
        //TRACE(@"%s [%.03f] no image ==> need to remove all", __PRETTY_FUNCTION__, time);
        _removeCount = [_subtitleImages count];
        _canRequestNewTime = FALSE;
        _requestedTime = time;
        /*
        if ([[_movieView movie] rate] == 0.0) {
            [_subtitleOSD clearContent];
            if ([self updateSubtitleOSD:time]) {
                resultImage = [_subtitleOSD makeTexImage];
            }
        }
         */
    }
    [_conditionLock unlockWithCondition:MAKING_IMAGE];

    return resultImage;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)imagesTimeInterval
{
    return ([_subtitleImages count] == 0) ? 0 :
                                ([[_subtitleImages lastObject] endTime] -
                                 [[_subtitleImages objectAtIndex:0] beginTime]);
}

- (void)removeOldestImages
{
    if ([_subtitleImages count] == _removeCount) {
        //TRACE(@"%s removing all oldests (%d)...", __PRETTY_FUNCTION__, _removeCount);
        [_subtitleImages removeAllObjects];
        _removeCount = 0;
        _subtitleImagesInterval = 0;
        [_subtitleOSD clearContent];
    }
    else if (0 < _removeCount) {
        //TRACE(@"%s removing oldest %d...", __PRETTY_FUNCTION__, _removeCount);
        while (0 < _removeCount) {
            [_subtitleImages removeObjectAtIndex:0];
            _removeCount--;
        }
        _subtitleImagesInterval = [self imagesTimeInterval];
    }
}

- (void)renderThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _autoreleasePool = [[NSAutoreleasePool alloc] init];

    float time;
    NSImage* texImage;
    MSubtitleStringImage* image = nil;
    while (!_quitRequested) {
        //TRACE(@"%s waiting for resume", __PRETTY_FUNCTION__);
        [_conditionLock lockWhenCondition:MAKING_IMAGE];
        [self removeOldestImages];
        [_conditionLock unlockWithCondition:MAKING_IMAGE];  // maintain locking

        if (0 <= _requestedTime) {  // new time requested
            //TRACE(@"%s new time requested: %.03f", __PRETTY_FUNCTION__, _requestedTime);
            time = _requestedTime;
            _requestedTime = -1;
            [_subtitleOSD clearContent];
            [image release], image = nil;
        }
        //TRACE(@"%s making images at %.03f...", __PRETTY_FUNCTION__, time);
        while (_requestedTime < 0 &&     // stop if new time is requested
               _subtitleImagesInterval < MAX_IMAGES_TIME_INTERVAL) {
            if ([self updateSubtitleOSD:time] & STRING_UPDATED) {
                if (image) {
                    [_conditionLock lock];
                    [image setEndTime:time];
                    [_subtitleImages addObject:image];
                    //TRACE(@"%s image[%d] (%.03f~%.03f)", __PRETTY_FUNCTION__,
                    //      [_subtitleImages count] - 1,
                    //      [image beginTime], [image endTime]);
                    [image release], image = nil;
                    _subtitleImagesInterval = [self imagesTimeInterval];
                    _canRequestNewTime = TRUE;
                    [_conditionLock unlockWithCondition:MAKING_IMAGE];
                    //#if defined(_ASYNC_ON_PAUSED)
                    if (_requestedTime < 0 &&
                        [[_movieView movie] rate] == 0.0) {
                        [_movieView updateSubtitleString];
                        [_movieView performSelectorOnMainThread:@selector(redisplay)
                                                     withObject:nil waitUntilDone:FALSE];
                    }
                    //#endif  // _ASYNC_ON_PAUSED
                }
                texImage = [_subtitleOSD makeTexImage];
                if (texImage) {
                    image = [[MSubtitleStringImage alloc] initWithStringImage:texImage];
                    [image setBeginTime:time];
                    //TRACE(@"%s new-image at (%.03f)", __PRETTY_FUNCTION__, time);
                }
            }
            time += 0.01;
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
        }
        [_conditionLock lock];
        [_conditionLock unlockWithCondition:WAITING];
    }

    [_autoreleasePool release];
    _autoreleasePool = nil;
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

@end

#endif
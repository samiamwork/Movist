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

#import "SubtitleRenderer.h"

#import "MMovieView.h"
#import "MMovie.h"
#import "MSubtitle.h"
#import "MSubtitleOSD.h"

@interface MSubtitleStringImage : NSObject
{
#if defined(DEBUG)
    NSString* _string;
#endif
    NSImage* _image;
    float _beginTime;
    float _endTime;
}

- (id)initWithStringImage:(NSImage*)image;

#if defined(DEBUG)
- (NSString*)string;
- (void)setString:(NSString*)string;
#endif
- (NSImage*)image;
- (float)beginTime;
- (float)endTime;
- (float)duration;
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
#if defined(DEBUG)
    [_string release];
#endif
    [_image release];
    [super dealloc];
}

#if defined(DEBUG)
- (NSString*)string { return _string; }
- (void)setString:(NSString*)string
{
    assert(string != nil);
    _string = [string retain];
}
#endif
- (NSImage*)image { return _image; }
- (float)beginTime { return _beginTime; }
- (float)endTime { return _endTime; }
- (float)duration { return _endTime - _beginTime; }
- (void)setBeginTime:(float)beginTime { _beginTime = beginTime; }
- (void)setEndTime:(float)endTime { _endTime = endTime; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation SubtitleRenderer

#define WAITING         0
#define MAKING_IMAGE    1

- (id)initWithMovieView:(MMovieView*)movieView
{
    if (self = [super init]) {
        _movieView = [movieView retain];

        _subtitles = nil;
        _subtitlesBeginTime = FLT_MAX;
        _subtitlesEndTime = 0;
        _subtitlesLock = [[NSLock alloc] init];

        _subtitleOSD = [[MSubtitleOSD alloc] init];
        _subtitleImages = [[NSMutableArray alloc] initWithCapacity:5];
        _conditionLock = [[NSConditionLock alloc] initWithCondition:WAITING];
        _maxRenderInterval = 30.0;
        _renderInterval = 0.0;
        _lastRequestedTime = 0.0;
        _requestedTime = 0.0;
        _removeCount = 0;
        _canRequestNewTime = TRUE;

        _emptyImage = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];

        _running = FALSE;
        _quitRequested = FALSE;
        [NSThread detachNewThreadSelector:@selector(renderThreadFunc:)
                                 toTarget:self withObject:nil];
    }
    return self;
}

- (void)dealloc
{
    _quitRequested = TRUE;
    [_conditionLock lock];
    [_conditionLock unlockWithCondition:MAKING_IMAGE];
    while (_running) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    [_conditionLock release];

    [_subtitleImages removeAllObjects];
    [_subtitleImages release];
    [_subtitleOSD release];

    [_subtitlesLock release];
    [_subtitles release];

    [_emptyImage release];
    [_movieView release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)maxRenderInterval { return _maxRenderInterval; }
- (void)setMaxRenderInterval:(float)interval { _maxRenderInterval = interval; }

- (int)requestRemakeImages
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_subtitles && [[_movieView movie] rate] != 0.0) {
        _removeCount = [_subtitleImages count];
        _requestedTime = _lastRequestedTime;
        return MAKING_IMAGE;
    }
    return WAITING;
}

- (void)setSubtitles:(NSArray*)subtitles
{
    [_subtitlesLock lock];
    [subtitles retain], [_subtitles release], _subtitles = subtitles;

    _subtitlesBeginTime = FLT_MAX;
    _subtitlesEndTime = 0;
    if (_subtitles) {
        MSubtitle* subtitle;
        NSEnumerator* enumerator = [_subtitles objectEnumerator];
        while (subtitle = [enumerator nextObject]) {
            if ([subtitle isEnabled]) {
                if ([subtitle beginTime] < _subtitlesBeginTime) {
                    _subtitlesBeginTime = [subtitle beginTime];
                }
                if (_subtitlesEndTime < [subtitle endTime]) {
                    _subtitlesEndTime = [subtitle endTime];
                }
            }
        }
    }
    [_subtitleOSD clearContent];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    _lastRequestedTime = 0.0;
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setMovieRect:(NSRect)rect
{
    [_subtitlesLock lock];
    [_subtitleOSD setMovieRect:rect];
    [_subtitlesLock unlock];
}

- (void)setMovieSize:(NSSize)size
{
    [_subtitlesLock lock];
    [_subtitleOSD setMovieSize:size];
    [_subtitlesLock unlock];
}

- (void)clearSubtitleContent
{
    [_subtitlesLock lock];
    [_subtitleOSD clearContent];
    [_subtitlesLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSString*)fontName { return [_subtitleOSD fontName]; }
- (float)fontSize { return [_subtitleOSD fontSize]; }

- (void)setFontName:(NSString*)fontName size:(float)size
{
    [_subtitlesLock lock];
    [_subtitleOSD setFontName:fontName size:size];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setTextColor:(NSColor*)textColor
{
    [_subtitlesLock lock];
    [_subtitleOSD setTextColor:textColor];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setStrokeColor:(NSColor*)strokeColor
{
    [_subtitlesLock lock];
    [_subtitleOSD setStrokeColor:strokeColor];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setStrokeWidth:(float)strokeWidth
{
    [_subtitlesLock lock];
    [_subtitleOSD setStrokeWidth:strokeWidth];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowColor:(NSColor*)shadowColor
{
    [_subtitlesLock lock];
    [_subtitleOSD setShadowColor:shadowColor];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowBlur:(float)shadowBlur
{
    [_subtitlesLock lock];
    [_subtitleOSD setShadowBlur:shadowBlur];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowOffset:(float)shadowOffset
{
    [_subtitlesLock lock];
    [_subtitleOSD setShadowOffset:shadowOffset];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowDarkness:(int)shadowDarkness
{
    [_subtitlesLock lock];
    [_subtitleOSD setShadowDarkness:shadowDarkness];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)hMargin { return [_subtitleOSD hMargin]; }
- (float)lineSpacing { return [_subtitleOSD lineSpacing]; }

- (void)setHMargin:(float)hMargin
{
    [_subtitlesLock lock];
    [_subtitleOSD setHMargin:hMargin];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setLineSpacing:(float)lineSpacing
{
    [_subtitlesLock lock];
    [_subtitleOSD setLineSpacing:lineSpacing];
    [_subtitlesLock unlock];

    [_conditionLock lock];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define NO_SUBTITLE    -1
#define NO_STRING       0
#define STRING_UPDATED  1
#define SAME_STRING     2

- (int)updateSubtitleOSD:(float)time
{
    int result = NO_SUBTITLE;

    if (_subtitles) {
        result = NO_STRING;
        MSubtitle* subtitle;
        NSMutableAttributedString* string;
        NSEnumerator* enumerator = [_subtitles objectEnumerator];
        while (subtitle = [enumerator nextObject]) {
            if ([subtitle isEnabled]) {
                string = [subtitle stringAtTime:time];
                if (!string) {
                    string = @"";
                }
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

    return result;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSImage*)imageAtTime:(float)time
{
    if (!_subtitles) {
        //TRACE(@"%s [%.03f] no subtitles", __PRETTY_FUNCTION__, time);
        return _emptyImage;
    }

    float lastTime = _lastRequestedTime;
    _lastRequestedTime = time;

    if ([[_movieView movie] rate] == 0.0) { // make instantly on paused
        NSImage* resultImage = _emptyImage;
        [_subtitlesLock lock];
        [_subtitleOSD clearContent];
        if ([self updateSubtitleOSD:time]) {
            resultImage = [_subtitleOSD makeTexImage];
        }
        [_subtitlesLock unlock];

        if (0.1 <= ABS(time - lastTime)) {  // not to remake for toggling play/pause.
            [_conditionLock lock];
            _removeCount = [_subtitleImages count];
            _requestedTime = time;
            [_conditionLock unlockWithCondition:MAKING_IMAGE];
        }
        return resultImage;
    }

    if (0 <= _requestedTime) {  // new time is already requested
        [_conditionLock lock];
        //TRACE(@"%s [%.03f] new time is already requested", __PRETTY_FUNCTION__, time);
        [_conditionLock unlockWithCondition:MAKING_IMAGE];
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
        else if ([image endTime] <= time) {
            _removeCount = i + 1;
            //TRACE(@"%s [%.03f] image[%d]:\"%@\" expired",
            //      __PRETTY_FUNCTION__, time, i, [image string]);
        }
        else {  // [image beginTime] <= time < [image endTime]
            //TRACE(@"%s [%.03f] image[%d]:\"%@\" found",
            //      __PRETTY_FUNCTION__, time, i, [image string]);
            [_conditionLock unlockWithCondition:
                (0 < _removeCount) ? MAKING_IMAGE : [_conditionLock condition]];
            return [image image];
        }
    }
    // clear & remake _subtitleImages
    if ((i == 0 || i == count) && _canRequestNewTime) {
        //TRACE(@"%s [%.03f] no image ==> need to remove all", __PRETTY_FUNCTION__, time);
        _removeCount = [_subtitleImages count];
        _requestedTime = time;
        [_conditionLock unlockWithCondition:MAKING_IMAGE];
    }
    else {
        //if (0 < _removeCount) {
        //    TRACE(@"%s [%.03f] no image ==> need to remove oldest", __PRETTY_FUNCTION__, time);
        //}
        [_conditionLock unlockWithCondition:
                (0 < _removeCount) ? MAKING_IMAGE : [_conditionLock condition]];
    }
    return _emptyImage;
}

- (void)clearImages
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_subtitles) {
        [_conditionLock lock];
        _removeCount = [_subtitleImages count];
        _requestedTime = _lastRequestedTime;
        [_conditionLock unlockWithCondition:WAITING];   // will be awaken later
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)removeOldestImages
{
    if ([_subtitleImages count] == _removeCount) {
        [_subtitleImages removeAllObjects];
        _removeCount = 0;
        _renderInterval = 0;
        [_subtitleOSD clearContent];
        //TRACE(@"%s all removed", __PRETTY_FUNCTION__);
    }
    else if (0 < _removeCount) {
        MSubtitleStringImage* image;
        while (0 < _removeCount) {
            image = [_subtitleImages objectAtIndex:0];
            if ([image image] != _emptyImage) {
                _renderInterval -= [image duration];
            }
            [_subtitleImages removeObjectAtIndex:0];
            _removeCount--;
            //TRACE(@"%s oldest removed (%d:%.03f)", __PRETTY_FUNCTION__,
            //      [_subtitleImages count], _renderInterval);
        }
    }
}

- (MSubtitleStringImage*)newSubtitleStringImage:(NSImage*)texImage
                                      beginTime:(float)beginTime
{
    if (!texImage) {
        texImage = [[_emptyImage retain] autorelease];
    }
    MSubtitleStringImage* image = [[MSubtitleStringImage alloc]
                                        initWithStringImage:texImage];
#if defined(DEBUG)
    [image setString:(texImage == _emptyImage) ?
                     @"" : [[_subtitleOSD string] string]];
#endif
    [image setBeginTime:beginTime];
    //TRACE(@"%s new-image at %.03f", __PRETTY_FUNCTION__, time);
    return [image autorelease];
}

- (void)completeSubtitleStringImage:(MSubtitleStringImage*)image
                            endTime:(float)endTime
{
    [_conditionLock lock];

    assert(image != nil);
    [image setEndTime:endTime];
    [_subtitleImages addObject:image];
    if ([image image] != _emptyImage) {
        _renderInterval += [image duration];
    }
    _canRequestNewTime = TRUE;
    /*
    TRACE(@"%s image[%d] (%.03f~%.03f):\"%@\" (%d:%.03f)", __PRETTY_FUNCTION__,
          [_subtitleImages count] - 1,
          [[_subtitleImages lastObject] beginTime],
          [[_subtitleImages lastObject] endTime],
          [[_subtitleImages lastObject] string],
          [_subtitleImages count], _renderInterval);
     */
    [_conditionLock unlockWithCondition:MAKING_IMAGE];
}

- (void)renderThreadFunc:(id)anObject
{
    //TRACE(@"%s started", __PRETTY_FUNCTION__);
    _running = TRUE;

    float time;
    NSAutoreleasePool* outerPool;
    NSAutoreleasePool* innerPool;
    MSubtitleStringImage* image = nil;
    while (!_quitRequested) {
        //TRACE(@"%s waiting for resume", __PRETTY_FUNCTION__);
        outerPool = [[NSAutoreleasePool alloc] init];

        [_conditionLock lockWhenCondition:MAKING_IMAGE];
        if (_subtitles) {
            [self removeOldestImages];
            [_conditionLock unlockWithCondition:MAKING_IMAGE];  // maintain locking

            if (0 <= _requestedTime) {  // new time requested
                //TRACE(@"%s new time requested: %.03f", __PRETTY_FUNCTION__, _requestedTime);
                time = _requestedTime;
                _canRequestNewTime = FALSE;
                _requestedTime = -1;
                [_subtitlesLock lock];
                [_subtitleOSD clearContent];
                [_subtitlesLock unlock];
                [image release], image = nil;
            }
            //TRACE(@"%s making images from %.03f...", __PRETTY_FUNCTION__, time);
            while (!_quitRequested &&
                   _subtitles && time < _subtitlesEndTime &&
                   _renderInterval < _maxRenderInterval &&
                   _removeCount == 0 && _requestedTime < 0) {
                innerPool = [[NSAutoreleasePool alloc] init];
                [_subtitlesLock lock];
                if ([self updateSubtitleOSD:time] & STRING_UPDATED) {
                    if (image) {
                        [self completeSubtitleStringImage:image endTime:time];
                        [image release], image = nil;
                    }
                    image = [[self newSubtitleStringImage:[_subtitleOSD makeTexImage]
                                               beginTime:time] retain];
                }
                [_subtitlesLock unlock];
                [innerPool release];

                time += 0.01;
            }
            if (_subtitlesEndTime <= time) {
                BOOL lastEmptyImageNeeded = ([_subtitleImages count] == 0) ||
                                            (image && [image image] != _emptyImage);
                if (image) {
                    [self completeSubtitleStringImage:image endTime:time];
                    [image release], image = nil;
                }
                if (lastEmptyImageNeeded) {
                    image = [[self newSubtitleStringImage:nil beginTime:time] retain];
                    [self completeSubtitleStringImage:image
                                              endTime:[[_movieView movie] duration]];
                    [image release], image = nil;
                }
            }
            [_conditionLock lock];
        }
        else {
            _requestedTime = -1;
            _canRequestNewTime = TRUE;
        }
        [_conditionLock unlockWithCondition:(_requestedTime < 0) ? WAITING : MAKING_IMAGE];

        [outerPool release];
    }
    if (image) {
        [image release];
        image = nil;
    }
    
    _running = FALSE;
    //TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

@end

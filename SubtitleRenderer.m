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

#define WAITING         0
#define MAKING_IMAGE    1

- (id)initWithMovieView:(MMovieView*)movieView
{
    if (self = [super init]) {
        _movieView = [movieView retain];
        _subtitleOSD1 = [[MSubtitleOSD alloc] init];
        _subtitleOSD2 = [[MSubtitleOSD alloc] init];
        _subtitleImages = [[NSMutableArray alloc] initWithCapacity:5];
        _subtitlesLock = [[NSRecursiveLock alloc] init];
        _conditionLock = [[NSConditionLock alloc] initWithCondition:WAITING];

        _maxRenderInterval = 30.0;
        _renderInterval = 0.0;
        _lastRequestedTime = 0.0;
        _requestedTime = 0.0;
        _removeCount = 0;
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
    [_conditionLock lock];
    [_conditionLock unlockWithCondition:MAKING_IMAGE];
    while (_running) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [_subtitleImages removeAllObjects];
    [_subtitleImages release];
    [_subtitleOSD2 release];
    [_subtitleOSD1 release];
    [_subtitles release];
    [_movieView release];
    [_emptyImage release];
    [_subtitlesLock release];
    [_conditionLock release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)maxRenderInterval { return _maxRenderInterval; }
- (void)setMaxRenderInterval:(float)interval { _maxRenderInterval = interval; }

- (BOOL)hasSubtitle
{
    [_subtitlesLock lock];
    BOOL ret = (_subtitles && 0 < [_subtitles count]);
    [_subtitlesLock unlock];
    return ret;
}

- (int)requestRemakeImages
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self hasSubtitle]) {
        _removeCount = [_subtitleImages count];
        _requestedTime = _lastRequestedTime;
        _canRequestNewTime = FALSE;
        return MAKING_IMAGE;
    }
    return WAITING;
}

- (void)setSubtitles:(NSArray*)subtitles
{
    [_conditionLock lock];
    [_subtitlesLock lock];
    [subtitles retain], [_subtitles release], _subtitles = subtitles;
    [_subtitlesLock unlock];
    [_subtitleOSD1 clearContent];
    [_subtitleOSD2 clearContent];
    _lastRequestedTime = 0.0;
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setMovieRect:(NSRect)rect
{
    [_subtitleOSD1 setMovieRect:rect];
    [_subtitleOSD2 setMovieRect:rect];
}

- (void)setMovieSize:(NSSize)size
{
    [_subtitleOSD1 setMovieSize:size];
    [_subtitleOSD2 setMovieSize:size];
}

- (void)clearSubtitleContent
{
    [_subtitleOSD1 clearContent];
    [_subtitleOSD2 clearContent];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSString*)fontName { return [_subtitleOSD1 fontName]; }
- (float)fontSize { return [_subtitleOSD1 fontSize]; }

- (void)setFontName:(NSString*)fontName size:(float)size
{
    [_conditionLock lock];
    [_subtitleOSD1 setFontName:fontName size:size];
    [_subtitleOSD2 setFontName:fontName size:size];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setTextColor:(NSColor*)textColor
{
    [_conditionLock lock];
    [_subtitleOSD1 setTextColor:textColor];
    [_subtitleOSD2 setTextColor:textColor];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setStrokeColor:(NSColor*)strokeColor
{
    [_conditionLock lock];
    [_subtitleOSD1 setStrokeColor:strokeColor];
    [_subtitleOSD2 setStrokeColor:strokeColor];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setStrokeWidth:(float)strokeWidth
{
    [_conditionLock lock];
    [_subtitleOSD1 setStrokeWidth:strokeWidth];
    [_subtitleOSD2 setStrokeWidth:strokeWidth];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowColor:(NSColor*)shadowColor
{
    [_conditionLock lock];
    [_subtitleOSD1 setShadowColor:shadowColor];
    [_subtitleOSD2 setShadowColor:shadowColor];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowBlur:(float)shadowBlur
{
    [_conditionLock lock];
    [_subtitleOSD1 setShadowBlur:shadowBlur];
    [_subtitleOSD2 setShadowBlur:shadowBlur];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowOffset:(float)shadowOffset
{
    [_conditionLock lock];
    [_subtitleOSD1 setShadowOffset:shadowOffset];
    [_subtitleOSD2 setShadowOffset:shadowOffset];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

- (void)setShadowDarkness:(int)shadowDarkness
{
    [_conditionLock lock];
    [_subtitleOSD1 setShadowDarkness:shadowDarkness];
    [_subtitleOSD2 setShadowDarkness:shadowDarkness];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)hMargin { return [_subtitleOSD1 hMargin]; }

- (void)setHMargin:(float)hMargin
{
    [_conditionLock lock];
    [_subtitleOSD1 setHMargin:hMargin];
    [_subtitleOSD2 setHMargin:hMargin];
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define NO_SUBTITLE    -1
#define NO_STRING       0
#define STRING_UPDATED  1
#define SAME_STRING     2

- (int)updateSubtitleOSD:(MSubtitleOSD*)subtitleOSD forTime:(float)time
{
    [_subtitlesLock lock];

    int result = NO_SUBTITLE;
    if ([self hasSubtitle]) {
        result = NO_STRING;
        MSubtitle* subtitle;
        NSMutableAttributedString* string;
        NSEnumerator* enumerator = [_subtitles objectEnumerator];
        while (subtitle = [enumerator nextObject]) {
            if ([subtitle isEnabled]) {
                string = [subtitle stringAtTime:time];
                if (string) {
                    if ([subtitleOSD setString:string forName:[subtitle name]]) {
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
    }
    [_subtitlesLock unlock];

    return result;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSImage*)imageAtTime:(float)time
{
    if (![self hasSubtitle]) {
        //TRACE(@"%s [%.03f] no subtitles", __PRETTY_FUNCTION__, time);
        return _emptyImage;
    }

    NSImage* resultImage = _emptyImage;

    [_conditionLock lock];

    _lastRequestedTime = time;
    if ([[_movieView movie] rate] == 0.0) {
        [_subtitleOSD2 clearContent];
        if ([self updateSubtitleOSD:_subtitleOSD2 forTime:time]) {
            resultImage = [_subtitleOSD2 makeTexImage];
        }
        _removeCount = [_subtitleImages count];
        _canRequestNewTime = FALSE;
        _requestedTime = time;
    }
    else if (_requestedTime < 0) {
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
        if (_canRequestNewTime) {
            //TRACE(@"%s [%.03f] no image ==> need to remove all", __PRETTY_FUNCTION__, time);
            _removeCount = [_subtitleImages count];
            _canRequestNewTime = FALSE;
            _requestedTime = time;
        }
    }
    [_conditionLock unlockWithCondition:MAKING_IMAGE];

    return resultImage;
}

- (void)clearImages
{
    [_conditionLock lock];
    TRACE(@"%s", __PRETTY_FUNCTION__);
    int condition = [self requestRemakeImages];
    [_conditionLock unlockWithCondition:condition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)updateRenderInterval
{
    _renderInterval = ([_subtitleImages count] == 0) ? 0 :
                                ([[_subtitleImages lastObject] endTime] -
                                 [[_subtitleImages objectAtIndex:0] beginTime]);
}

- (void)removeOldestImages
{
    if ([_subtitleImages count] == _removeCount) {
        //TRACE(@"%s removing all oldests (%d)...", __PRETTY_FUNCTION__, _removeCount);
        [_subtitleImages removeAllObjects];
        _removeCount = 0;
        _renderInterval = 0;
        [_subtitleOSD1 clearContent];
    }
    else if (0 < _removeCount) {
        //TRACE(@"%s removing oldest %d...", __PRETTY_FUNCTION__, _removeCount);
        while (0 < _removeCount) {
            [_subtitleImages removeObjectAtIndex:0];
            _removeCount--;
        }
        [self updateRenderInterval];
    }
}

- (void)renderThreadFunc:(id)anObject
{
    TRACE(@"%s started", __PRETTY_FUNCTION__);
    _running = TRUE;

    float time;
    BOOL playing;
    NSImage* texImage;
    NSAutoreleasePool* outerPool;
    NSAutoreleasePool* innerPool;
    MSubtitleStringImage* image = nil;
    while (!_quitRequested) {
        //TRACE(@"%s waiting for resume", __PRETTY_FUNCTION__);
        outerPool = [[NSAutoreleasePool alloc] init];

        [_conditionLock lockWhenCondition:MAKING_IMAGE];
        if ([self hasSubtitle]) {
            [self removeOldestImages];
            [_conditionLock unlockWithCondition:MAKING_IMAGE];  // maintain locking

            if (0 <= _requestedTime) {  // new time requested
                //TRACE(@"%s new time requested: %.03f", __PRETTY_FUNCTION__, _requestedTime);
                time = _requestedTime;
                _requestedTime = -1;
                [_subtitleOSD1 clearContent];
                [image release], image = nil;
            }
            //TRACE(@"%s making images from %.03f...", __PRETTY_FUNCTION__, time);
            playing = TRUE;     // for adding one image at least on paused.
            while (!_quitRequested && [self hasSubtitle] && playing &&
                   _requestedTime < 0 && _renderInterval < _maxRenderInterval) {
                innerPool = [[NSAutoreleasePool alloc] init];
                if ([self updateSubtitleOSD:_subtitleOSD1 forTime:time] & STRING_UPDATED) {
                    if (image) {
                        [_conditionLock lock];
                        [image setEndTime:time];
                        [_subtitleImages addObject:image];
                        //TRACE(@"%s image[%d] (%.03f~%.03f)", __PRETTY_FUNCTION__,
                        //      [_subtitleImages count] - 1,
                        //      [image beginTime], [image endTime]);
                        [image release], image = nil;
                        [self updateRenderInterval];
                        _canRequestNewTime = TRUE;
                        playing = ([[_movieView movie] rate] != 0.0);
                        [_conditionLock unlockWithCondition:MAKING_IMAGE];
                    }
                    texImage = [_subtitleOSD1 makeTexImage];
                    if (texImage) {
                        image = [[MSubtitleStringImage alloc] initWithStringImage:texImage];
                        [image setBeginTime:time];
                        //TRACE(@"%s new-image at %.03f", __PRETTY_FUNCTION__, time);
                    }
                }
                [innerPool release];
                time += 0.01;
            }
            [_conditionLock lock];
        }
        if (_quitRequested && image) {
            [image release];
            image = nil;
        }
        [_conditionLock unlockWithCondition:WAITING];

        [outerPool release];
    }

    _running = FALSE;
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

@end

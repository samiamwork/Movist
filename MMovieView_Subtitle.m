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

#import "MMovieView.h"

#import "MMovie.h"
#import "MSubtitle.h"

#import "MTextOSD.h"
#import "MImageOSD.h"
#import "SubtitleRenderer.h"

@implementation MMovieView (Subtitle)

- (NSArray*)subtitles { return _subtitles; }

- (void)setSubtitles:(NSArray*)subtitles
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, subtitles);
    [subtitles retain], [_subtitles release], _subtitles = subtitles;
    MSubtitle* subtitle;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        [subtitle clearCache];
    }
    [_subtitleRenderer setSubtitles:_subtitles];
    [self updateSubtitle];
}

- (void)updateSubtitleString
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleImageOSD setImage:
        [_subtitleRenderer imageAtTime:[self currentSubtitleTime]]];
}

- (void)updateSubtitle
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer clearImages];
    [self updateSubtitleString];
    [self redisplay];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark visibility

- (BOOL)subtitleVisible { return _subtitleVisible; }

- (void)setSubtitleVisible:(BOOL)visible
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleVisible = visible;
    if (_subtitleVisible) {
        [self updateSubtitle];
    }
    [self redisplay];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle font & attributes

- (NSString*)subtitleFontName { return [_subtitleRenderer fontName]; }
- (float)subtitleFontSize { return [_subtitleRenderer fontSize]; }

- (void)setSubtitleFontName:(NSString*)fontName size:(float)size
{
    TRACE(@"%s \"%@\" %g", __PRETTY_FUNCTION__, fontName, size);
    [_subtitleRenderer setFontName:fontName size:size];
    [_messageOSD setFontName:fontName size:15.0];
    [_errorOSD setFontName:fontName size:24.0];
    [self updateMovieRect:TRUE];
    [self updateSubtitle];
}

- (void)setSubtitleTextColor:(NSColor*)textColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setTextColor:textColor];
    //[_messageOSD setTextColor:textColor];
    //[_errorOSD setTextColor:textColor];
    [self updateSubtitle];
}

- (void)setSubtitleStrokeColor:(NSColor*)strokeColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setStrokeColor:strokeColor];
    //[_messageOSD setStrokeColor:strokeColor];
    //[_errorOSD setStrokeColor:strokeColor];
    [self updateSubtitle];
}

- (void)setSubtitleStrokeWidth:(float)strokeWidth
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setStrokeWidth:strokeWidth];
    //[_messageOSD setStrokeWidth:strokeWidth];
    //[_errorOSD setStrokeWidth:strokeWidth];
    [self updateSubtitle];
}

- (void)setSubtitleShadowColor:(NSColor*)shadowColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setShadowColor:shadowColor];
    //[_messageOSD setShadowColor:shadowColor];
    //[_errorOSD setShadowColor:shadowColor];
    [self updateSubtitle];
}

- (void)setSubtitleShadowBlur:(float)shadowBlur
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setShadowBlur:shadowBlur];
    //[_messageOSD setShadowBlur:shadowBlur];
    //[_errorOSD setShadowBlur:shadowBlur];
    [self updateSubtitle];
}

- (void)setSubtitleShadowOffset:(float)shadowOffset
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setShadowOffset:shadowOffset];
    //[_messageOSD setShadowOffset:shadowOffset];
    //[_errorOSD setShadowOffset:shadowOffset];
    [self updateSubtitle];
}

- (void)setSubtitleShadowDarkness:(int)shadowDarkness
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleRenderer setShadowDarkness:shadowDarkness];
    //[_messageOSD setShadowDarkness:shadowDarkness];
    //[_errorOSD setShadowDarkness:shadowDarkness];
    [self updateSubtitle];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (BOOL)subtitleDisplayOnLetterBox { return [_subtitleImageOSD displayOnLetterBox]; }
- (int)subtitleLinesInLetterBox { return _subtitleLinesInLetterBox; }
- (float)subtitleHMargin { return [_subtitleImageOSD hMargin]; }
- (float)subtitleVMargin { return [_subtitleImageOSD vMargin]; }
- (float)subtitleSync { return _subtitleSync; }

- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (displayOnLetterBox != [self subtitleDisplayOnLetterBox]) {
        // need not update _subtitleRenderer.
        [_subtitleImageOSD setDisplayOnLetterBox:displayOnLetterBox];
        [_messageOSD setDisplayOnLetterBox:displayOnLetterBox];
        [self redisplay];
    }
}

- (void)setSubtitleLinesInLetterBox:(int)lines
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_subtitleLinesInLetterBox != lines) {
        _subtitleLinesInLetterBox = lines;
        [self updateMovieRect:TRUE];
    }
}

- (void)setSubtitleHMargin:(float)hMargin
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (hMargin != [self subtitleHMargin]) {
        [_subtitleRenderer setHMargin:hMargin];
        [_subtitleImageOSD setHMargin:hMargin];
        [_messageOSD setHMargin:hMargin];
        [self updateSubtitle];
    }
}

- (void)setSubtitleVMargin:(float)vMargin
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (vMargin != [self subtitleVMargin]) {
        // need not update _subtitleRenderer.
        [_subtitleImageOSD setVMargin:vMargin];
        [_messageOSD setVMargin:vMargin];
        // need not update subtitle
        [self redisplay];
    }
}

- (void)setSubtitleSync:(float)sync
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleSync = sync;
    [self updateSubtitle];
}

- (float)currentSubtitleTime
{
    return [_movie currentTime] + _subtitleSync;
}

- (float)prevSubtitleTime
{
    float ct = [self currentSubtitleTime];
    float t, prevTime = 0;

    MSubtitle* subtitle;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        t = [subtitle prevSubtitleTime:ct];
        if (prevTime < t) {
            prevTime = t;
        }
    }
    return prevTime;
}

- (float)nextSubtitleTime
{
    float ct = [self currentSubtitleTime];
    float t, nextTime = [_movie duration];
    
    MSubtitle* subtitle;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        t = [subtitle nextSubtitleTime:ct];
        if (t < nextTime) {
            nextTime = t;
        }
    }
    return nextTime;
}

@end

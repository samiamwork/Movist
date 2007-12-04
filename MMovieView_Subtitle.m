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
#import "MSubtitleOSD.h"
#if defined(_USE_SUBTITLE_RENDERER)
#import "SubtitleRenderer.h"
#endif

@implementation MMovieView (Subtitle)

- (NSArray*)subtitles { return _subtitles; }

- (void)setSubtitles:(NSArray*)subtitles
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, subtitles);
#if defined(_USE_SUBTITLE_RENDERER)
    [subtitles retain], [_subtitles release], _subtitles = subtitles;
    MSubtitle* subtitle;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        [subtitle clearCache];
    }
    [_subtitleRenderer setSubtitles:_subtitles];
    [self updateSubtitle];
#else
    [_drawLock lock];
    [subtitles retain], [_subtitles release], _subtitles = subtitles;
    [_subtitleOSD clearContent];

    MSubtitle* subtitle;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        [subtitle clearCache];
    }
    [self updateSubtitleString];
    [_drawLock unlock];
    [self redisplay];
#endif
}

- (void)updateSubtitleString
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    float currentTime = [_movie currentTime] + _subtitleSync;
#if defined(_USE_SUBTITLE_RENDERER)
    [_subtitleImageOSD setImage:[_subtitleRenderer imageAtTime:currentTime]];
#else
    MSubtitle* subtitle;
    NSMutableAttributedString* s;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        if ([subtitle isEnabled]) {
            s = [subtitle stringAtTime:currentTime];
            if (s) {
                [_subtitleOSD setString:s forName:[subtitle name]];
            }
        }
    }
#endif
}

#if defined(_USE_SUBTITLE_RENDERER)
- (void)updateSubtitle
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    float currentTime = [_movie currentTime] + _subtitleSync;
    [_subtitleRenderer clearImages:currentTime];
    [self updateSubtitleString];
    [self redisplay];
}
#endif

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark visibility

- (BOOL)subtitleVisible { return _subtitleVisible; }

- (void)setSubtitleVisible:(BOOL)visible
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleVisible = visible;
    [self redisplay];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle font & attributes

- (NSString*)subtitleFontName { return [_subtitleOSD fontName]; }
- (float)subtitleFontSize { return [_subtitleOSD fontSize]; }

- (void)setSubtitleFontName:(NSString*)fontName size:(float)size
{
    TRACE(@"%s \"%@\" %g", __PRETTY_FUNCTION__, fontName, size);
    [_messageOSD setFontName:fontName size:15.0];
    [_subtitleOSD setFontName:fontName size:size];
    [_errorOSD setFontName:fontName size:24.0];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

- (void)setSubtitleTextColor:(NSColor*)textColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setTextColor:textColor];
    [_subtitleOSD setTextColor:textColor];
    [_errorOSD setTextColor:textColor];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

- (void)setSubtitleStrokeColor:(NSColor*)strokeColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setStrokeColor:strokeColor];
    [_subtitleOSD setStrokeColor:strokeColor];
    [_errorOSD setStrokeColor:strokeColor];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

- (void)setSubtitleStrokeWidth:(float)strokeWidth
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setStrokeWidth:strokeWidth];
    [_subtitleOSD setStrokeWidth:strokeWidth];
    [_errorOSD setStrokeWidth:strokeWidth];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

- (void)setSubtitleShadowColor:(NSColor*)shadowColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setShadowColor:shadowColor];
    [_subtitleOSD setShadowColor:shadowColor];
    [_errorOSD setShadowColor:shadowColor];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

- (void)setSubtitleShadowBlur:(float)shadowBlur
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setShadowBlur:shadowBlur];
    [_subtitleOSD setShadowBlur:shadowBlur];
    [_errorOSD setShadowBlur:shadowBlur];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

- (void)setSubtitleShadowOffset:(float)shadowOffset
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setShadowOffset:shadowOffset];
    [_subtitleOSD setShadowOffset:shadowOffset];
    [_errorOSD setShadowOffset:shadowOffset];
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self redisplay];
#endif
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (BOOL)subtitleDisplayOnLetterBox { return [_subtitleOSD displayOnLetterBox]; }
- (float)minLetterBoxHeight { return _minLetterBoxHeight; }
- (float)subtitleHMargin { return [_subtitleOSD hMargin]; }
- (float)subtitleVMargin { return [_subtitleOSD vMargin]; }
- (float)subtitleSync { return _subtitleSync; }

- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (displayOnLetterBox != [self subtitleDisplayOnLetterBox]) {
        [_messageOSD setDisplayOnLetterBox:displayOnLetterBox];
        [_subtitleOSD setDisplayOnLetterBox:displayOnLetterBox];
#if defined(_USE_SUBTITLE_RENDERER)
        [_subtitleImageOSD setDisplayOnLetterBox:displayOnLetterBox];
#endif
        [self redisplay];
    }
}

- (void)setMinLetterBoxHeight:(float)height
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_minLetterBoxHeight != height) {
        _minLetterBoxHeight = height;
        [self updateMovieRect:TRUE];
    }
}

- (void)revertLetterBoxHeight
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setMinLetterBoxHeight:0.0];
}

- (void)increaseLetterBoxHeight
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float letterBoxHeight = _movieRect.origin.y + 1.0;
    if (_movieRect.size.height + letterBoxHeight < [self frame].size.height) {
        [self setMinLetterBoxHeight:letterBoxHeight];
    }
}

- (void)decreaseLetterBoxHeight
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float letterBoxHeight = _movieRect.origin.y - 1.0;
    if (([self frame].size.height - _movieRect.size.height) / 2 < letterBoxHeight) {
        [self setMinLetterBoxHeight:letterBoxHeight];
    }
}

- (void)setSubtitleHMargin:(float)hMargin
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (hMargin != [self subtitleHMargin]) {
        [_messageOSD setHMargin:hMargin];
        [_subtitleOSD setHMargin:hMargin];
#if defined(_USE_SUBTITLE_RENDERER)
        [_subtitleImageOSD setHMargin:hMargin];
        [self updateSubtitle];
#endif
        [self redisplay];
    }
}

- (void)setSubtitleVMargin:(float)vMargin
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (vMargin != [self subtitleVMargin]) {
        [_messageOSD setVMargin:vMargin];
        [_subtitleOSD setVMargin:vMargin];
#if defined(_USE_SUBTITLE_RENDERER)
        [_subtitleImageOSD setVMargin:vMargin];
        // need not [self updateSubtitle];
#endif
        [self redisplay];
    }
}

- (void)setSubtitleSync:(float)sync
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleSync = sync;
#if defined(_USE_SUBTITLE_RENDERER)
    [self updateSubtitle];
#else
    [self updateSubtitleString];
    [self redisplay];
#endif
}

@end

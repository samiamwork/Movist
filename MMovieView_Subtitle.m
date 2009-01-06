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

#import "MMovieView.h"

#import "MMovie.h"
#import "MSubtitle.h"
#import "MSubtitleItem.h"
#import "MMovieOSD.h"

#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView (Subtitle)

- (int)subtitleCount
{
    int i;
    for (i = 0; i < 3; i++) {
        if (!_subtitle[i]) {
            break;
        }
    }
    return i;
}

- (MSubtitle*)subtitleAtIndex:(int)index
{
    assert(0 <= index && index < 3);
    return _subtitle[index];
}

- (void)addSubtitle:(MSubtitle*)subtitle
{
    assert(subtitle != nil && [subtitle isEnabled]);
    int i;
    for (i = 0; i < 3; i++) {
        if (!_subtitle[i]) {
            break;
        }
    }
    if (i == 3) {
        return;
    }

    _subtitle[i] = [subtitle retain];
    TRACE(@"%s [%d]:%@", __PRETTY_FUNCTION__, i, [subtitle name]);
    [_subtitle[i] setMovieOSD:_subtitleOSD[i]];
    [self updateSubtitleOSDAtIndex:i sync:TRUE];   // for optimized rendering
    [_subtitle[i] startRenderThread];

    [self updateIndexOfSubtitleInLBOX];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    [self redisplay];
}

- (void)removeSubtitle:(MSubtitle*)subtitle
{
    assert(subtitle != nil);
    int i;
    for (i = 0; i < 3; i++) {
        if (_subtitle[i] == subtitle) {
            break;
        }
    }
    if (i == 3) {
        return;
    }

    [_subtitle[i] quitRenderThread];
    [_subtitle[i] setMovieOSD:nil];
    [_subtitle[i] release];
    for (; i < 2; i++) {
        _subtitle[i] = _subtitle[i + 1];
        [_subtitle[i] setMovieOSD:_subtitleOSD[i]];
    }
    _subtitle[i] = nil;
    for (i = 0; i < 3; i++) {
        [self updateSubtitleOSDAtIndex:i sync:TRUE];
    }

    [self updateIndexOfSubtitleInLBOX];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    [self redisplay];
}

- (void)removeAllSubtitles
{
    int i;
    for (i = 0; i < 3; i++) {
        if (_subtitle[i]) {
            [_subtitle[i] quitRenderThread];
            [_subtitle[i] setMovieOSD:nil];
            [_subtitle[i] release];
            _subtitle[i] = nil;
            [self updateSubtitleOSDAtIndex:i sync:TRUE];
        }
    }

    [self updateIndexOfSubtitleInLBOX];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    [self redisplay];
}

- (BOOL)updateSubtitleOSDAtIndex:(int)index sync:(BOOL)sync
{
    BOOL ret = TRUE;
    [_drawLock lock];
    if (!_movie || !_subtitle[index] || ![_subtitle[index] isEnabled]) {
        [_subtitleOSD[index] clearContent];
        _needsSubtitleUpdate[index] = FALSE;
        [_auxSubtitleOSD[index] clearContent];
    }
    else {
        BOOL renderFlag = sync && ([_movie rate] == 0.0);
        float time = [_movie currentTime] + [_subtitleOSD[index] subtitleSync];
        NSImage* texImage = [_subtitle[index] texImageAtTime:time direction:0
                                                  renderFlag:&renderFlag];
        [_subtitleOSD[index] setTexImage:texImage];

        if (texImage || !renderFlag) {
            _needsSubtitleUpdate[index] = FALSE;
            [_auxSubtitleOSD[index] clearContent];
        }
        else {
            MSubtitleItem* item = [_subtitle[index] itemAtTime:time direction:0];
            if (item && [item string]) {
                [_auxSubtitleOSD[index] setString:[item string]];
            }
            if ([_movie rate] == 0.0) {
                _needsSubtitleUpdate[index] = TRUE;
                ret = FALSE;
            }
        }
    }
    [_drawLock unlock];
    return ret;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark visibility

- (BOOL)subtitleVisible { return _subtitleVisible; }

- (void)setSubtitleVisible:(BOOL)visible
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_subtitleVisible != visible) {
        _subtitleVisible = visible;
        [_subtitle[0] setRenderingEnabled:_subtitleVisible];
        [_subtitle[1] setRenderingEnabled:_subtitleVisible];
        [_subtitle[2] setRenderingEnabled:_subtitleVisible];
        if (_subtitleVisible) {
            [self updateSubtitleOSDAtIndex:0 sync:TRUE];
            [self updateSubtitleOSDAtIndex:1 sync:TRUE];
            [self updateSubtitleOSDAtIndex:2 sync:TRUE];
        }
        [self redisplay];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (void)getSubtitleAttributes:(SubtitleAttributes*)attrs atIndex:(int)index
{
    assert(0 <= index && index < 3);
    if (attrs->mask & SUBTITLE_ATTRIBUTE_FONT) {
        attrs->fontName = [_subtitleOSD[index] fontName];
        attrs->fontSize = [_subtitleOSD[index] fontSize];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_TEXT_COLOR) {
        attrs->textColor = [_subtitleOSD[index] textColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_COLOR) {
        attrs->strokeColor = [_subtitleOSD[index] strokeColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_WIDTH) {
        attrs->strokeWidth = [_subtitleOSD[index] strokeWidth];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_COLOR) {
        attrs->shadowColor = [_subtitleOSD[index] shadowColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_BLUR) {
        attrs->shadowBlur = [_subtitleOSD[index] shadowBlur];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_OFFSET) {
        attrs->shadowOffset = [_subtitleOSD[index] shadowOffset];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_DARKNESS) {
        attrs->shadowDarkness = [_subtitleOSD[index] shadowDarkness];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_LINE_SPACING) {
        attrs->lineSpacing = [_subtitleOSD[index] lineSpacing];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_POSITION) {
        attrs->hPosition = [_subtitleOSD[index] hPosition];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_POSITION) {
        attrs->vPosition = [_subtitleOSD[index] vPosition];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_MARGIN) {
        attrs->hMargin = [_subtitleOSD[index] hMargin];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_MARGIN) {
        attrs->vMargin = [_subtitleOSD[index] vMargin];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SYNC) {
        attrs->sync = [_subtitleOSD[index] subtitleSync];
    }
}

- (void)setSubtitleAttributes:(const SubtitleAttributes*)attrs atIndex:(int)index
{
    assert(0 <= index && index < 3);
    BOOL remake = FALSE;
    if (attrs->mask & SUBTITLE_ATTRIBUTE_FONT) {
        if ([_subtitleOSD[index] setFontName:attrs->fontName size:attrs->fontSize]) {
            remake = TRUE;
        }
        [_auxSubtitleOSD[index] setFontName:attrs->fontName size:attrs->fontSize];
        if (index == 0) {
            [_messageOSD setFontName:attrs->fontName size:15.0];
            [_errorOSD setFontName:attrs->fontName size:24.0];
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_TEXT_COLOR) {
        if ([_subtitleOSD[index] setTextColor:attrs->textColor]) {
            remake = TRUE;
        }
        [_auxSubtitleOSD[index] setTextColor:attrs->textColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_COLOR) {
        if ([_subtitleOSD[index] setStrokeColor:attrs->strokeColor]) {
            remake = TRUE;
        }
        [_auxSubtitleOSD[index] setStrokeColor:attrs->strokeColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_WIDTH) {
        if ([_subtitleOSD[index] setStrokeWidth:attrs->strokeWidth]) {
            remake = TRUE;
        }
        // don't change _auxSubtitleOSD's strok-width
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_COLOR) {
        if ([_subtitleOSD[index] setShadowColor:attrs->shadowColor]) {
            remake = TRUE;
        }
        [_auxSubtitleOSD[index] setShadowColor:attrs->shadowColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_BLUR) {
        if ([_subtitleOSD[index] setShadowBlur:attrs->shadowBlur]) {
            remake = TRUE;
        }
        // don't change _auxSubtitleOSD's shadow-blur
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_OFFSET) {
        if ([_subtitleOSD[index] setShadowOffset:attrs->shadowOffset]) {
            remake = TRUE;
        }
        // don't change _auxSubtitleOSD's shadow-offset
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_DARKNESS) {
        if ([_subtitleOSD[index] setShadowDarkness:attrs->shadowDarkness]) {
            remake = TRUE;
        }
        // don't change _auxSubtitleOSD's shadow-darkness
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_LINE_SPACING) {
        if ([_subtitleOSD[index] setLineSpacing:attrs->lineSpacing]) {
            [self updateLetterBoxHeight];
            [self updateMovieRect:FALSE];
            remake = TRUE;
        }
        [_auxSubtitleOSD[index] setLineSpacing:attrs->lineSpacing];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_POSITION) {
        [_subtitleOSD[index] setHPosition:attrs->hPosition];
        [_auxSubtitleOSD[index] setHPosition:attrs->hPosition];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_POSITION) {
        [_subtitleOSD[index] setVPosition:attrs->vPosition];
        [_auxSubtitleOSD[index] setVPosition:attrs->vPosition];
        if (index == _indexOfSubtitleInLBOX ||
            attrs->vPosition == OSD_VPOSITION_LBOX) {
            [self updateIndexOfSubtitleInLBOX];
            [self updateLetterBoxHeight];
            [self updateMovieRect:FALSE];
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_MARGIN) {
        if ([_subtitleOSD[index] setHMargin:attrs->hMargin]) {
            remake = TRUE;
        }
        [_auxSubtitleOSD[index] setHMargin:attrs->hMargin];
        if (index == 0) {
            [_messageOSD setHMargin:attrs->hMargin];
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_MARGIN) {
        [_subtitleOSD[index] setVMargin:attrs->vMargin];
        [_auxSubtitleOSD[index] setVMargin:attrs->vMargin];
        if (index == 0) {
            [_messageOSD setVMargin:attrs->vMargin];
        }
        [self updateMovieRect:FALSE];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SYNC) {
        [_subtitleOSD[index] setSubtitleSync:attrs->sync];
    }

    if (_subtitle[index] && [_subtitle[index] isEnabled]) {
        if (remake) {
            [_subtitle[index] setNeedsRemakeTexImages];
        }
        [self updateSubtitleOSDAtIndex:index sync:TRUE];
    }
    [self redisplay];
}

- (void)updateIndexOfSubtitleInLBOX
{
    int i;
    for (i = 0; i < 3; i++) {
        if (_subtitle[i] && [_subtitleOSD[i] vPosition] == OSD_VPOSITION_LBOX) {
            break;
        }
    }
    _indexOfSubtitleInLBOX = (i < 3) ? i : -1;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (int)letterBoxHeight { return _letterBoxHeight; }
- (float)subtitleScreenMargin { return _subtitleScreenMargin; }

- (void)updateLetterBoxHeight
{
    if (!_movie ||
        ((!_subtitle[0] || ![_subtitle[0] isEnabled]) &&
         (!_subtitle[1] || ![_subtitle[0] isEnabled]) &&
         (!_subtitle[2] || ![_subtitle[0] isEnabled]))) {
        _letterBoxHeight = LETTER_BOX_HEIGHT_SAME;
    }
    else if (_letterBoxHeightPrefs != LETTER_BOX_HEIGHT_AUTO) {
        _letterBoxHeight = _letterBoxHeightPrefs;
    }
    else {
        int prevHeight = _letterBoxHeight;
        if (0 <= _indexOfSubtitleInLBOX) {
            MMovieOSD* subtitleOSD = _subtitleOSD[_indexOfSubtitleInLBOX];
            NSRect rect = [[[self window] screen] frame];
            if (0 < _fullScreenUnderScan) {
                rect = [self underScannedRect:rect];
            }
            NSSize bs = rect.size;
            NSSize ms = [_movie adjustedSizeByAspectRatio];
            if (bs.width / bs.height < ms.width / ms.height) {
                float lineHeight = [subtitleOSD adjustedLineHeight:bs.width];
                float letterBoxHeight = bs.height - (bs.width * ms.height / ms.width);
                int lines = (int)letterBoxHeight / (int)lineHeight;
                lines = MIN(lines, _autoLetterBoxHeightMaxLines);
                _letterBoxHeight = adjustToRange(lines,
                                                 LETTER_BOX_HEIGHT_1_LINE,
                                                 LETTER_BOX_HEIGHT_3_LINES);
            }
        }
        else {  // no subtitle in OSD_VPOSITION_LBOX
            _letterBoxHeight = LETTER_BOX_HEIGHT_SAME;
        }
        if (prevHeight != _letterBoxHeight) {
            BOOL onLetterBox = (_letterBoxHeight != LETTER_BOX_HEIGHT_SAME);
            if (0 <= _indexOfSubtitleInLBOX) {
                [_subtitleOSD[_indexOfSubtitleInLBOX] updateVPosition:onLetterBox];
                [_auxSubtitleOSD[_indexOfSubtitleInLBOX] updateVPosition:onLetterBox];
            }
            [_messageOSD updateVPosition:onLetterBox];
        }
    }
}

- (void)setAutoLetterBoxHeightMaxLines:(int)lines
{
    _autoLetterBoxHeightMaxLines = lines;

    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
}

- (void)setLetterBoxHeight:(int)height
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _letterBoxHeightPrefs = height;

    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
}

- (void)setSubtitleScreenMargin:(float)screenMargin
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleScreenMargin = screenMargin;
    // need not update _subtitleOSDs.
    // need not update subtitle
    [self updateMovieRect:TRUE];
}

- (float)prevSubtitleTime
{
    float t, prevTime = 0;
    int i;
    for (i = 0; i < 3; i++) {
        if (_subtitle[i] && [_subtitle[i] isEnabled]) {
            t = [_subtitle[i] prevSubtitleTime:
                 [_movie currentTime] + [_subtitleOSD[i] subtitleSync]];
            if (prevTime < t) {
                prevTime = t;
            }
        }
    }
    return prevTime;
}

- (float)nextSubtitleTime
{
    float t, nextTime = [_movie duration];
    int i;
    for (i = 0; i < 3; i++) {
        if (_subtitle[i] && [_subtitle[i] isEnabled]) {
            t = [_subtitle[i] nextSubtitleTime:
                 [_movie currentTime] + [_subtitleOSD[i] subtitleSync]];
            if (t < nextTime) {
                nextTime = t;
            }
        }
    }
    return nextTime;
}

@end

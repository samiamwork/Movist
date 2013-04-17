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
#import "MMOvieViewLayer.h"
#import "MMovieLayer.h"
#import "MMovieOSDLayer.h"

#import "MMovie.h"
#import "MSubtitle.h"
#import "MSubtitleItem.h"
#import "MMovieOSD.h"

#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView (Subtitle)

- (int)subtitleCount
{
	return 1;
}

- (MSubtitle*)subtitle
{
    return _subtitle;
}

- (void)addSubtitle:(MSubtitle*)subtitle
{
    assert(subtitle != nil && [subtitle isEnabled]);
    // If subtitle is already in use just return
	if(_subtitle)
		return;

    _subtitle = [subtitle retain];
    TRACE(@"%s :%@", __PRETTY_FUNCTION__, [subtitle name]);
    [_subtitle setMovieOSD:_subtitleOSD];
    [self updateSubtitleOSD];
    [_subtitle startRenderThread];

    [self updateIndexOfSubtitleInLBOX];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    [self redisplay];
}

- (void)removeSubtitle:(MSubtitle*)subtitle
{
    assert(subtitle != nil);
	if (subtitle != _subtitle)
		return;

    [_subtitle quitRenderThread];
    [_subtitle setMovieOSD:nil];
    [_subtitle release];
    _subtitle = nil;
	[self updateSubtitleOSD];

    [self updateIndexOfSubtitleInLBOX];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    [self redisplay];
}

- (void)removeAllSubtitles
{
	if (_subtitle) {
		[_subtitle quitRenderThread];
		[_subtitle setMovieOSD:nil];
		[_subtitle release];
		_subtitle = nil;
		[self updateSubtitleOSD];
	}

    [self updateIndexOfSubtitleInLBOX];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    [self redisplay];
}

- (BOOL)updateSubtitleOSD
{
    BOOL ret = TRUE;
    if (!self.movie || !_subtitle || ![_subtitle isEnabled]) {
        [_subtitleOSD clearContent];
        _needsSubtitleDrawing &= ~1;
    }
    else {
        BOOL isRendering;
        BOOL paused = (0 == [self.movie rate]);
        float time = [self.movie currentTime] + [_subtitleOSD subtitleSync];
        NSImage* texImage = [_subtitle texImageAtTime:time isSeek:paused
                                                 isRendering:&isRendering];
        [_subtitleOSD setTexImage:texImage];

        if (texImage || !isRendering) {
            _needsSubtitleDrawing &= ~1;
        }
        else {
            if (paused) {
                _needsSubtitleDrawing |= 1;
                ret = FALSE;
            }
        }
    }
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
		_rootLayer.subtitle.hidden = !visible;
        [_subtitle setRenderingEnabled:_subtitleVisible];
        if (_subtitleVisible) {
            [self updateSubtitleOSD];
        }
		[_rootLayer setSubtitleEnabled:visible];
        [self redisplay];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (void)getSubtitleAttributes:(SubtitleAttributes*)attrs
{
    if (attrs->mask & SUBTITLE_ATTRIBUTE_FONT) {
        attrs->fontName = [_subtitleOSD fontName];
        attrs->fontSize = [_subtitleOSD fontSize];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_TEXT_COLOR) {
        attrs->textColor = [_subtitleOSD textColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_COLOR) {
        attrs->strokeColor = [_subtitleOSD strokeColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_WIDTH) {
        attrs->strokeWidth = [_subtitleOSD strokeWidth];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_COLOR) {
        attrs->shadowColor = [_subtitleOSD shadowColor];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_BLUR) {
        attrs->shadowBlur = [_subtitleOSD shadowBlur];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_OFFSET) {
        attrs->shadowOffset = [_subtitleOSD shadowOffset];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_DARKNESS) {
        attrs->shadowDarkness = [_subtitleOSD shadowDarkness];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_LINE_SPACING) {
        attrs->lineSpacing = [_subtitleOSD lineSpacing];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_POSITION) {
        attrs->hPosition = [_subtitleOSD hPosition];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_POSITION) {
        attrs->vPosition = [_subtitleOSD vPosition];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_MARGIN) {
        attrs->hMargin = [_subtitleOSD hMargin];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_MARGIN) {
        attrs->vMargin = [_subtitleOSD vMargin];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SYNC) {
        attrs->sync = [_subtitleOSD subtitleSync];
    }
}

- (void)setSubtitleAttributes:(const SubtitleAttributes*)attrs
{
    BOOL remake = FALSE;
    if (attrs->mask & SUBTITLE_ATTRIBUTE_FONT) {
        if ([_subtitleOSD setFontName:attrs->fontName size:attrs->fontSize]) {
            [self updateLetterBoxHeight];
            [self updateMovieRect:FALSE];
            remake = TRUE;
        }
		[_messageOSD setFontName:attrs->fontName size:15.0];
		[_errorOSD setFontName:attrs->fontName size:24.0];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_TEXT_COLOR) {
        if ([_subtitleOSD setTextColor:attrs->textColor]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_COLOR) {
        if ([_subtitleOSD setStrokeColor:attrs->strokeColor]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_STROKE_WIDTH) {
        if ([_subtitleOSD setStrokeWidth:attrs->strokeWidth]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_COLOR) {
        if ([_subtitleOSD setShadowColor:attrs->shadowColor]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_BLUR) {
        if ([_subtitleOSD setShadowBlur:attrs->shadowBlur]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_OFFSET) {
        if ([_subtitleOSD setShadowOffset:attrs->shadowOffset]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SHADOW_DARKNESS) {
        if ([_subtitleOSD setShadowDarkness:attrs->shadowDarkness]) {
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_LINE_SPACING) {
        if ([_subtitleOSD setLineSpacing:attrs->lineSpacing]) {
            [self updateLetterBoxHeight];
            [self updateMovieRect:FALSE];
            remake = TRUE;
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_POSITION) {
        [_subtitleOSD setHPosition:attrs->hPosition];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_POSITION) {
        [_subtitleOSD setVPosition:attrs->vPosition];
        if (_subtitleInLBOX || attrs->vPosition == OSD_VPOSITION_LBOX) {
            [self updateIndexOfSubtitleInLBOX];
            [self updateLetterBoxHeight];
            [self updateMovieRect:FALSE];
        }
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_H_MARGIN) {
        if ([_subtitleOSD setHMargin:attrs->hMargin]) {
            remake = TRUE;
        }
		[_messageOSD setHMargin:attrs->hMargin];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_V_MARGIN) {
        [_subtitleOSD setVMargin:attrs->vMargin];
		[_messageOSD setVMargin:attrs->vMargin];
        [self updateMovieRect:FALSE];
    }
    if (attrs->mask & SUBTITLE_ATTRIBUTE_SYNC) {
        [_subtitleOSD setSubtitleSync:attrs->sync];
    }

    if (_subtitle && [_subtitle isEnabled]) {
        if (remake) {
            [_subtitle setNeedsRemakeTexImages];
        }
        [self updateSubtitleOSD];
    }
    [self redisplay];
}

// TODO: fix method name and check that it's correct. This looks very wrong
- (void)updateIndexOfSubtitleInLBOX
{
	if (_subtitle && [_subtitleOSD vPosition] == OSD_VPOSITION_LBOX) {
		_subtitleInLBOX = TRUE;
	}
	_subtitleInLBOX = FALSE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (int)letterBoxHeight { return _letterBoxHeight; }
- (float)subtitleScreenMargin { return _subtitleScreenMargin; }

- (void)updateLetterBoxHeight
{
    if (!self.movie || !_subtitle || ![_subtitle isEnabled]) {
        _letterBoxHeight = LETTER_BOX_HEIGHT_SAME;
    }
    else if (_letterBoxHeightPrefs != LETTER_BOX_HEIGHT_AUTO) {
        _letterBoxHeight = _letterBoxHeightPrefs;
    }
    else {
        int prevHeight = _letterBoxHeight;
        if (_subtitleInLBOX) {
            MMovieOSD* subtitleOSD = _subtitleOSD;
            NSRect rect = [[[self window] screen] frame];
            if (0 < _fullScreenUnderScan) {
                rect = [self underScannedRect:rect];
            }
            NSSize bs = rect.size;
            NSSize ms = [self.movie adjustedSizeByAspectRatio];
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
            if (_subtitleInLBOX) {
                [_subtitleOSD updateVPosition:onLetterBox];
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
    // need not update _subtitleOSD.
    // need not update subtitle
    [self updateMovieRect:TRUE];
}

- (float)prevSubtitleTime
{
    float t, prevTime = 0;
	if (_subtitle && [_subtitle isEnabled]) {
		t = [_subtitle prevSubtitleTime:
			 [self.movie currentTime] + [_subtitleOSD subtitleSync]];
		if (prevTime < t) {
			prevTime = t;
		}
	}
    return prevTime;
}

- (float)nextSubtitleTime
{
    float t, nextTime = [self.movie duration];
	if (_subtitle && [_subtitle isEnabled]) {
		t = [_subtitle nextSubtitleTime:
			 [self.movie currentTime] + [_subtitleOSD subtitleSync]];
		if (t < nextTime) {
			nextTime = t;
		}
	}
    return nextTime;
}

@end

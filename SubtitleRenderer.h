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

#import "Movist.h"

@class MMovieView;
@class MSubtitleOSD;

@interface SubtitleRenderer : NSObject
{
    MMovieView* _movieView;

    NSArray* _subtitles;
    float _subtitlesBeginTime;
    float _subtitlesEndTime;
    NSLock* _subtitlesLock;
    MSubtitleOSD* _subtitleOSD;
    NSMutableArray* _subtitleImages;    // for MSubtitleImage
    NSConditionLock* _conditionLock;
    float _maxRenderInterval;
    float _renderInterval;
    float _lastRequestedTime;
    float _requestedTime;
    int _removeCount;
    BOOL _canRequestNewTime;

    NSImage* _emptyImage;

    BOOL _running;
    BOOL _quitRequested;
}

- (id)initWithMovieView:(MMovieView*)movieView;

- (float)maxRenderInterval;
- (void)setMaxRenderInterval:(float)interval;

- (void)setSubtitles:(NSArray*)subtitles;

- (void)setMovieRect:(NSRect)rect;
- (void)setMovieSize:(NSSize)size;
- (void)clearSubtitleContent;

- (NSString*)fontName;
- (float)fontSize;
- (void)setFontName:(NSString*)fontName size:(float)size;
- (void)setTextColor:(NSColor*)textColor;
- (void)setStrokeColor:(NSColor*)strokeColor;
- (void)setStrokeWidth:(float)strokeWidth;
- (void)setShadowColor:(NSColor*)shadowColor;
- (void)setShadowBlur:(float)shadowBlur;
- (void)setShadowOffset:(float)shadowOffset;
- (void)setShadowDarkness:(int)shadowDarkness;

- (float)hMargin;
- (float)lineSpacing;
- (void)setHMargin:(float)hMargin;
- (void)setLineSpacing:(float)lineSpacing;

- (NSImage*)imageAtTime:(float)time;
- (void)clearImages;

@end

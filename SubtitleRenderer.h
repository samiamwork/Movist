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

#import "Movist.h"

@class MMovieView;
@class MSubtitleOSD;

@interface SubtitleRenderer : NSObject
{
    NSArray* _subtitles;
    MSubtitleOSD* _subtitleOSD1;        // for rendering on playing
    MSubtitleOSD* _subtitleOSD2;        // for rendering on paused
    NSMutableArray* _subtitleImages;    // for MSubtitleStringImage
    float _maxPreRenderInterval;
    float _curPreRenderInterval;
    float _lastRequestedTime;
    float _requestedTime;
    int _removeCount;
    BOOL _canRequestNewTime;
    MMovieView* _movieView;
    NSLock* _subtitlesLock;
    NSConditionLock* _conditionLock;

    NSImage* _emptyImage;

    NSAutoreleasePool* _autoreleasePool;
    BOOL _quitRequested;
}

- (id)initWithMovieView:(MMovieView*)movieView;

- (float)maxPreRenderInterval;
- (void)setMaxPreRenderInterval:(float)interval;

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
- (void)setHMargin:(float)hMargin;

- (NSImage*)imageAtTime:(float)time;
- (void)clearImages;

@end

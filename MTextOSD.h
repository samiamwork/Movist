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

#import "MMovieOSD.h"

enum {  // for _updateMask
    UPDATE_FONT     = 1 << 3,
};

@interface MTextOSD : MMovieOSD
{
    NSMutableAttributedString* _newString;
    NSMutableAttributedString* _string;

    NSFont* _font;
    NSString* _fontName;
    float _fontSize;            // for 640-width-of-movie

    NSColor* _textColor;
    NSColor* _strokeColor;
    NSNumber* _strokeWidth;    // for 640-width-of-movie
    NSNumber* _strokeWidth2;   // for redraw

    NSMutableParagraphStyle* _paragraphStyle;
    float _lineSpacing;
    //NSNumber* _kern;
}

#pragma mark -
- (NSMutableAttributedString*)string;
- (NSString*)fontName;
- (float)fontSize;
- (float)lineSpacing;
- (void)setTextAlignment:(NSTextAlignment)alignment;
- (BOOL)setString:(NSMutableAttributedString*)string;
- (void)setFontName:(NSString*)name size:(float)size;
- (void)setTextColor:(NSColor*)textColor;
- (void)setStrokeColor:(NSColor*)strokeColor;
- (void)setStrokeWidth:(float)strokeWidth;
- (void)setLineSpacing:(float)lineSpacing;
//- (void)setKern:(float)kern;

- (void)updateFont;

@end

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

#import <QuartzCore/QuartzCore.h>

@interface MMovieOSD : NSObject
{
    // shadow
    NSShadow* _shadow;
    NSShadow* _shadowNone;
    NSColor* _shadowColor;
    float _shadowBlur;          // for 640-width-of-movie
    float _shadowOffset;        // for 640-width-of-movie
    int _shadowDarkness;

    // text rendering
    NSFont* _font;
    NSString* _fontName;
    float _fontSize;            // for 640-width-of-movie
    NSColor* _textColor;
    NSColor* _strokeColor;
    NSNumber* _strokeWidth;     // for 640-width-of-movie
    NSNumber* _strokeWidth2;    // for redraw
    NSMutableParagraphStyle* _paragraphStyle;
    float _lineSpacing;

    // position & margin
    int _hPosition;             // OSD_HPOSITION_*
    int _vPosition;             // OSD_VPOSITION_*
    int _vPositionPrefs;        // OSD_VPOSITION_*
    float _hMargin;             // percentage of width
    float _vMargin;             // percentage of height
    float _subtitleSync;        // for subtitle only

    // texture rendering
    NSRect _viewBounds;
    NSRect _movieRect;
    NSRect _drawingRect;
    float _autoSizeWidth;
    unsigned int _updateMask;   // bit-mask of UPDATE_*
    NSImage* _texImage;         // final rendered image for texture
    GLuint _texName;            // OpenGL texture name for _texImage

    // for convenience
    NSAttributedString* _string;
    NSImage* _image;
    float _imageBaseWidth;

    NSRecursiveLock* _lock;
}

#pragma mark shadow
- (NSColor*)shadowColor;
- (float)shadowBlur;
- (float)shadowOffset;
- (int)shadowDarkness;
- (BOOL)setShadowColor:(NSColor*)shadowColor;
- (BOOL)setShadowBlur:(float)shadowBlur;
- (BOOL)setShadowOffset:(float)shadowOffset;
- (BOOL)setShadowDarkness:(int)darkness;

#pragma mark text
- (void)initTextRendering;
- (NSString*)fontName;
- (float)fontSize;
- (NSTextAlignment)textAlignment;
- (NSColor*)textColor;
- (NSColor*)strokeColor;
- (float)strokeWidth;
- (float)lineSpacing;
- (BOOL)setFontName:(NSString*)name size:(float)size;
- (BOOL)setTextAlignment:(NSTextAlignment)alignment;
- (BOOL)setTextColor:(NSColor*)textColor;
- (BOOL)setStrokeColor:(NSColor*)strokeColor;
- (BOOL)setStrokeWidth:(float)strokeWidth;
- (BOOL)setLineSpacing:(float)lineSpacing;

#pragma mark position
- (unsigned int)hPosition;
- (unsigned int)vPosition;
- (BOOL)setHPosition:(unsigned int)hPosition;
- (BOOL)setVPosition:(unsigned int)vPosition;
- (void)updateVPosition:(BOOL)displayOnLetterBox;

#pragma mark margin
- (float)hMargin;
- (float)vMargin;
- (BOOL)setHMargin:(float)hMargin;
- (BOOL)setVMargin:(float)vMargin;

#pragma mark subtitle-sync
- (float)subtitleSync;
- (void)setSubtitleSync:(float)sync;

#pragma mark making tex-image
- (float)adjustedLineHeight:(float)movieWidth;
- (float)adjustedLineSpacing:(float)movieWidth;
- (NSImage*)makeTexImageForString:(NSAttributedString*)string;
- (NSImage*)makeTexImageForImage:(NSImage*)image baseWidth:(float)baseWidth;
- (BOOL)setString:(NSAttributedString*)string;
- (BOOL)setImage:(NSImage*)image baseWidth:(float)baseWidth;
- (void)clearContent;

#pragma mark drawing
- (BOOL)hasContent;
- (NSImage*)texImage;
- (BOOL)setTexImage:(NSImage*)texImage;
- (BOOL)setViewBounds:(NSRect)viewBounds movieRect:(NSRect)movieRect
        autoSizeWidth:(float)autoSizeWidth;
- (void)drawOnScreen;

@end

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

#import <OpenGL/CGLContext.h>

@interface MMovieOSD (Private)

- (void)updateShadow;
- (void)updateFont;

- (void)renderString:(NSMutableAttributedString*)string inRect:(NSRect)rect;
- (void)renderImage:(NSImage*)image inRect:(NSRect)rect;

- (void)makeTexture:(CGLContextObj)glContext;
- (void)updateDrawingRect;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation MMovieOSD

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        // shadow
        _shadow = [[NSShadow alloc] init];
        _shadowNone = [[NSShadow alloc] init];
        _shadowColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1] retain];
        _shadowBlur = 1.0;
        _shadowOffset = 0.0;
        _shadowDarkness = 1;

        // position & align
        _hPosition = OSD_HPOSITION_CENTER;
        _vPosition = OSD_VPOSITION_CENTER;
        _vPositionPrefs = OSD_VPOSITION_CENTER;
        _hMargin = _vMargin = 0.0;

        _updateMask = 0;
        _texName = 0;

        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_lock release];

    [_texImage release];

    [_font release];
    [_fontName release];
    [_textColor release];
    [_strokeWidth release];
    [_strokeWidth2 release];
    [_strokeColor release];
    [_paragraphStyle release];
    
    [_shadowColor release];
    [_shadow release];
    [_shadowNone release];

    [self makeTexture:CGLGetCurrentContext()];  // delete texture

    [super dealloc];
}

enum {  // for _updateMask
    UPDATE_SHADOW       = 1 << 0,
    UPDATE_FONT         = 1 << 1,
    UPDATE_TEX_IMAGE    = 1 << 2,
    UPDATE_TEXTURE      = 1 << 3,
    UPDATE_DRAWING_RECT = 1 << 4,
};

#define AUTO_SIZE(size, movieWidth) ((size) * (movieWidth) / 640.0)

#define LT_MARGIN(movieWidth)   AUTO_SIZE(10, movieWidth)  // left/top
#define RB_MARGIN(movieWidth)   AUTO_SIZE(15, movieWidth)  // right/bottom (larger for shadow-offset)

////////////////////////////////////////////////////////////////////////////////
#pragma mark shadow

- (NSColor*)shadowColor { return _shadowColor; }
- (float)shadowBlur { return _shadowBlur; }
- (float)shadowOffset { return _shadowOffset; }
- (int)shadowDarkness { return _shadowDarkness; }

- (BOOL)setShadowColor:(NSColor*)shadowColor
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_shadowColor isEqualTo:shadowColor]) {
        [_lock lock];
        [_shadowColor release];
        _shadowColor = [shadowColor retain];
        _updateMask |= UPDATE_SHADOW | UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setShadowBlur:(float)shadowBlur
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_shadowBlur != shadowBlur) {
        [_lock lock];
        _shadowBlur = shadowBlur;
        _updateMask |= UPDATE_SHADOW | UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setShadowOffset:(float)shadowOffset
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_shadowOffset != shadowOffset) {
        [_lock lock];
        _shadowOffset = shadowOffset;
        _updateMask |= UPDATE_SHADOW | UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setShadowDarkness:(int)darkness
{
    assert(0 < darkness);
    if (_shadowDarkness != darkness) {
        [_lock lock];
        _shadowDarkness = darkness;
        _updateMask |= UPDATE_SHADOW | UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (void)updateShadow
{
    float blur = AUTO_SIZE(_shadowBlur, _movieRect.size.width);
    float offset = AUTO_SIZE(_shadowOffset, _movieRect.size.width);
    [_shadow setShadowOffset:NSMakeSize(offset, -offset)];
    [_shadow setShadowBlurRadius:blur];
    [_shadow setShadowColor:_shadowColor];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark text

- (void)initTextRendering
{
    _textColor = [[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1] retain];
    _strokeColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1] retain];
    _strokeWidth = [[NSNumber alloc] initWithFloat:10.0];
    _strokeWidth2= [[NSNumber alloc] initWithFloat:-0.01];
    _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [_paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [_paragraphStyle setAlignment:NSCenterTextAlignment];
    _lineSpacing = 0;
}

- (NSString*)fontName { return _fontName; }
- (float)fontSize { return _fontSize; }
- (NSTextAlignment)textAlignment { return [_paragraphStyle alignment]; }
- (NSColor*)textColor { return _textColor; }
- (NSColor*)strokeColor { return _strokeColor; }
- (float)strokeWidth { return [_strokeWidth floatValue]; }
- (float)lineSpacing { return _lineSpacing; }

- (BOOL)setFontName:(NSString*)name size:(float)size
{
    if (![_fontName isEqualToString:name] || _fontSize != size) {
        [_lock lock];
        [_fontName release];
        _fontName = [name retain];
        _fontSize = size;
        _updateMask |= UPDATE_FONT | UPDATE_TEXTURE | UPDATE_DRAWING_RECT;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (void)updateFont
{
    [_font release];
    float size = AUTO_SIZE(_fontSize, _movieRect.size.width);
    _font = [[NSFont fontWithName:_fontName size:MAX(10.0, size)] retain];
}

- (BOOL)setTextAlignment:(NSTextAlignment)alignment
{
    if ([_paragraphStyle alignment] != alignment) {
        [_lock lock];
        [_paragraphStyle setAlignment:alignment];
        _updateMask |= UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setTextColor:(NSColor*)textColor
{
    if (![_textColor isEqualTo:textColor]) {
        [_lock lock];
        [_textColor release];
        _textColor = [textColor retain];
        _updateMask |= UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setStrokeColor:(NSColor*)strokeColor
{
    if (![_strokeColor isEqualTo:strokeColor]) {
        [_lock lock];
        [_strokeColor release];
        _strokeColor = [strokeColor retain];
        _updateMask |= UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setStrokeWidth:(float)strokeWidth
{
    if ([_strokeWidth floatValue] != -strokeWidth) {
        [_lock lock];
        [_strokeWidth release];
        _strokeWidth = [[NSNumber alloc] initWithFloat:-strokeWidth];
        _updateMask |= UPDATE_TEXTURE;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setLineSpacing:(float)lineSpacing
{
    if (_lineSpacing != lineSpacing) {
        [_lock lock];
        _lineSpacing = lineSpacing;
        _updateMask |= UPDATE_TEXTURE | UPDATE_DRAWING_RECT;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark position

- (unsigned int)hPosition { return _hPosition; }
- (unsigned int)vPosition { return _vPosition; }

- (BOOL)setHPosition:(unsigned int)hPosition
{
    if (_hPosition != hPosition) {
        [_lock lock];
        _hPosition = hPosition;
        _updateMask |= UPDATE_DRAWING_RECT;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setVPosition:(unsigned int)vPosition
{
    if (_vPosition != vPosition) {
        [_lock lock];
        _vPosition = vPosition;
        _vPositionPrefs = vPosition;
        _updateMask |= UPDATE_DRAWING_RECT;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (void)updateVPosition:(BOOL)displayOnLetterBox
{
    if (_vPositionPrefs == OSD_VPOSITION_UBOX) {
        _vPosition = (displayOnLetterBox) ? OSD_VPOSITION_UBOX : OSD_VPOSITION_TOP;
        _updateMask |= UPDATE_DRAWING_RECT;
    }
    else if (_vPositionPrefs == OSD_VPOSITION_LBOX) {
        // _vPositionPrefs is OSD_VPOSITION_BOTTOM or OSD_VPOSITION_LBOX.
        _vPosition = (displayOnLetterBox) ? OSD_VPOSITION_LBOX : OSD_VPOSITION_BOTTOM;
        _updateMask |= UPDATE_DRAWING_RECT;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark margin

- (float)hMargin { return _hMargin * 100; }
- (float)vMargin { return _vMargin * 100; }

- (BOOL)setHMargin:(float)hMargin
{
    if (_hMargin != hMargin) {
        [_lock lock];
        _hMargin = hMargin / 100.0f; // percentage
        _updateMask |= UPDATE_TEXTURE | UPDATE_DRAWING_RECT;   // for line wrapping
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setVMargin:(float)vMargin
{
    if (_vMargin != vMargin) {
        [_lock lock];
        _vMargin = vMargin / 100.0f; // percentage
        _updateMask |= UPDATE_DRAWING_RECT;
        [_lock unlock];
        return TRUE;
    }
    return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark subtitle sync

- (float)subtitleSync { return _subtitleSync; }
- (void)setSubtitleSync:(float)sync { _subtitleSync = sync; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark making tex-image

- (float)adjustedLineHeight:(float)movieWidth
{
    float fontSize = AUTO_SIZE(_fontSize, movieWidth);
    //fontSize = MAX(15.0, fontSize);
    NSFont* font = [NSFont fontWithName:_fontName size:fontSize];

    NSMutableAttributedString* s = [[[NSMutableAttributedString alloc]
        initWithString:NSLocalizedString(@"SubtitleTestChar", nil)] autorelease];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];

    NSSize maxSize = NSMakeSize(1000, 1000);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin |
                                     NSStringDrawingUsesFontLeading |
                                     NSStringDrawingUsesDeviceMetrics;
    return [s boundingRectWithSize:maxSize options:options].size.height;
}

- (float)adjustedLineSpacing:(float)movieWidth
{
    return AUTO_SIZE(_lineSpacing, _movieRect.size.width);
}

- (void)renderString:(NSMutableAttributedString*)string inRect:(NSRect)rect
{
    //[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0] set];
    //NSFrameRect(rect);

    float ltMargin = LT_MARGIN(_movieRect.size.width);
    float rbMargin = RB_MARGIN(_movieRect.size.width);
    rect.origin.x += ltMargin;
    rect.origin.y += rbMargin;
    rect.size.width  -= ltMargin + rbMargin;
    rect.size.height -= ltMargin + rbMargin;

    // at first, draw with outline & shadow
    [_shadow set];
    int i, darkness = (0 < [_shadow shadowBlurRadius]) ? _shadowDarkness : 1;
    for (i = 0; i < darkness; i++) {
        [string drawInRect:rect];
    }

    // redraw with new-outline & no-shadow for sharpness
    [_shadowNone set];
    NSRange range = NSMakeRange(0, [string length]);
    [string addAttribute:NSStrokeWidthAttributeName
                   value:_strokeWidth2 range:range];
    [string fixAttributesInRange:range];
    [string drawInRect:rect];

    //[[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0] set];
    //NSFrameRect(rect);
}

- (void)renderImage:(NSImage*)image inRect:(NSRect)rect
{
    //[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0] set];
    //NSFrameRect(rect);

    float ltMargin = LT_MARGIN(_movieRect.size.width);
    float rbMargin = RB_MARGIN(_movieRect.size.width);
    rect.origin.x += ltMargin;
    rect.origin.y += rbMargin;
    rect.size.width  -= ltMargin + rbMargin;
    rect.size.height -= ltMargin + rbMargin;
    
    [_shadow set];
    int i, darkness = (0 < [_shadow shadowBlurRadius]) ? _shadowDarkness : 1;
    for (i = 0; i < darkness; i++) {
        [image drawInRect:rect fromRect:NSZeroRect
                operation:NSCompositeSourceOver fraction:1.0];
    }

    //[[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0] set];
    //NSFrameRect(rect);
}

- (NSImage*)makeTexImageForString:(NSAttributedString*)string
{
    if (!string || [[string string] isEqualToString:@""]) {
        return nil;
    }

    [_lock lock];
    if (_updateMask & UPDATE_SHADOW) {
        _updateMask &= ~UPDATE_SHADOW;
        [self updateShadow];
    }
    if (_updateMask & UPDATE_FONT) {
        _updateMask &= ~UPDATE_FONT;
        [self updateFont];
    }

    // set attributes : font & shadow should be applied before calculating size
    NSMutableAttributedString* s = [string mutableCopy];
    [_paragraphStyle setLineSpacing:AUTO_SIZE(_lineSpacing, _movieRect.size.width)];
    [s applyFont:_font textColor:_textColor strokeColor:_strokeColor
     strokeWidth:_strokeWidth paragraphStyle:_paragraphStyle];

    NSSize maxSize = _movieRect.size;
    maxSize.width -= (maxSize.width * _hMargin) * 2;
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin |
                                     NSStringDrawingUsesFontLeading |
                                     NSStringDrawingUsesDeviceMetrics;
    NSSize size = [s boundingRectWithSize:maxSize options:options].size;
    // add margins for outline & shadow
    float ltMargin = LT_MARGIN(_movieRect.size.width);
    float rbMargin = RB_MARGIN(_movieRect.size.width);
    size.width  += ltMargin + rbMargin;
    size.height += ltMargin + rbMargin;

    NSImage* img = [[NSImage alloc] initWithSize:size];
    [img setCacheMode:NSImageCacheNever];
    [img setCachedSeparately:TRUE]; // for thread safety
    [img lockFocus];
    [self renderString:s inRect:NSMakeRect(0, 0, size.width, size.height)];
    [img unlockFocus];
    [_lock unlock];

    return [img autorelease];
}

- (NSImage*)makeTexImageForImage:(NSImage*)image baseWidth:(float)baseWidth
{
    if (!image) {
        return nil;
    }

    [_lock lock];
    if (_updateMask & UPDATE_SHADOW) {
        _updateMask &= ~UPDATE_SHADOW;
        [self updateShadow];
    }

    NSSize size;
    NSSize imageSize = [image size];
    if (0 < baseWidth) {
        size.width = imageSize.width * _movieRect.size.width / baseWidth;
        size.height = imageSize.height * size.width / imageSize.width;
    }
    else if (imageSize.width < _movieRect.size.width &&
             imageSize.height< _movieRect.size.height) {
        size = imageSize;
    }
    else {
        float minSize = MIN(_movieRect.size.width, _movieRect.size.height);
        if (imageSize.width < imageSize.height) {
            size.width  = imageSize.width  * minSize / imageSize.height;
            size.height = imageSize.height * minSize / imageSize.width;
        }
        else {
            size.width  = imageSize.width  * minSize / imageSize.height;
            size.height = imageSize.height * minSize / imageSize.width;
        }
    }
    // add margins for outline & shadow
    float ltMargin = LT_MARGIN(_movieRect.size.width);
    float rbMargin = RB_MARGIN(_movieRect.size.width);
    size.width  += ltMargin + rbMargin;
    size.height += ltMargin + rbMargin;
    
    NSImage* img = [[NSImage alloc] initWithSize:size];
    [img setCacheMode:NSImageCacheNever];
    [img setCachedSeparately:TRUE]; // for thread safety
    [img lockFocus];
    [self renderImage:image inRect:NSMakeRect(0, 0, size.width, size.height)];
    [img unlockFocus];
    [_lock unlock];

    return [img autorelease];
}

- (BOOL)setString:(NSAttributedString*)string
{
    if (![_string isEqualToAttributedString:string]) {
        [string retain], [_string release], _string = string;
        _updateMask |= UPDATE_TEX_IMAGE;
        return TRUE;
    }
    return FALSE;
}

- (BOOL)setImage:(NSImage*)image baseWidth:(float)baseWidth
{
    if (![_image isEqualTo:image]) {
        [image retain], [_image release], _image = image;
        _imageBaseWidth = baseWidth;
        _updateMask |= UPDATE_TEX_IMAGE;
        return TRUE;
    }
    return FALSE;
}

- (void)clearContent
{
    [_texImage release], _texImage = nil;
    [_string release], _string = nil;
    [_image release], _image = nil;
    _updateMask &= ~UPDATE_TEX_IMAGE;
    _updateMask &= ~UPDATE_TEXTURE;
    _updateMask &= ~UPDATE_DRAWING_RECT;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark drawing

- (BOOL)hasContent { return _texImage || (_updateMask & UPDATE_TEX_IMAGE); }

- (NSImage*)texImage { return _texImage; }

- (BOOL)setTexImage:(NSImage*)texImage
{
    if (_texImage != texImage) {
        [texImage retain], [_texImage release], _texImage = texImage;
        _updateMask |= UPDATE_TEXTURE | UPDATE_DRAWING_RECT;
        _updateMask &= ~UPDATE_TEX_IMAGE;
        return TRUE;
    }
    return FALSE;
}

- (void)makeTexture:(CGLContextObj)glContext
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!glContext) {
        return;
    }
    // at first, delete previous texture
    if (_texName) {
        (*glContext->disp.delete_textures)(glContext->rend, 1, &_texName);
        _texName = 0;
    }

    if (!_texImage) {
        return;
    }

    NSSize size = [_texImage size];
    NSBitmapImageRep* bmp = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:0
                             pixelsWide:(int)size.width pixelsHigh:(int)size.height
                             bitsPerSample:8 samplesPerPixel:4 hasAlpha:TRUE
                             isPlanar:FALSE colorSpaceName:NSCalibratedRGBColorSpace
                             bitmapFormat:0 bytesPerRow:(int)size.width * 4 bitsPerPixel:32];

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:
     [NSGraphicsContext graphicsContextWithBitmapImageRep:bmp]];

    [_texImage drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect
                 operation:NSCompositeCopy fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];

    // make texture
    glGenTextures(1, &_texName);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _texName);
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, size.width, size.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, [bmp bitmapData]);
    [bmp release];
}

- (void)updateDrawingRect
{
    float hmargin = _movieRect.size.width * _hMargin;
    float vmargin = _movieRect.size.height* _vMargin;
    float ltMargin = LT_MARGIN(_movieRect.size.width);
    float rbMargin = RB_MARGIN(_movieRect.size.width);

    NSRect mr = _movieRect;
    mr.origin.x   += hmargin;
    mr.size.width -= hmargin * 2;
    if (mr.origin.x < _viewBounds.origin.x) {
        mr.origin.x = _viewBounds.origin.x;
        mr.size.width = _viewBounds.size.width;
    }
    if (mr.origin.y < _viewBounds.origin.y) {
        mr.origin.y = _viewBounds.origin.y;
        mr.size.height = _viewBounds.size.height;
    }

    NSRect rect;
    rect.size = [_texImage size];

    // horizontal position
    switch (_hPosition) {
        case OSD_HPOSITION_LEFT :
            rect.origin.x = mr.origin.x;
            rect.origin.x -= ltMargin;
            break;
        case OSD_HPOSITION_CENTER :
            rect.origin.x = mr.origin.x + (mr.size.width - rect.size.width) / 2;
            rect.origin.x += (rbMargin - ltMargin) / 2;
            break;
        case OSD_HPOSITION_RIGHT :
            rect.origin.x = mr.origin.x + mr.size.width - rect.size.width;
            rect.origin.x += rbMargin;
            break;
    }

    // vertical position : rect is flipped
    float tm = NSMinY(_viewBounds) + NSMaxY(_viewBounds) - NSMaxY(mr);
    switch (_vPosition) {
        case OSD_VPOSITION_UBOX :
            rect.origin.y = tm - vmargin - rect.size.height;
            rect.origin.y += rbMargin;
            float minContentY = NSMinY(rect) + ltMargin;
            float minBoundsY = NSMinY(_viewBounds);
            if (minContentY < minBoundsY) {
                rect.origin.y += minBoundsY - minContentY;
            }
            break;
        case OSD_VPOSITION_TOP :
            rect.origin.y = tm + vmargin;
            rect.origin.y -= ltMargin;
            break;
        case OSD_VPOSITION_CENTER :
            rect.origin.y = tm + (mr.size.height - rect.size.height) / 2;
            rect.origin.y += (rbMargin - ltMargin) / 2;
            break;
        case OSD_VPOSITION_BOTTOM :
            rect.origin.y = (tm + mr.size.height) - vmargin - rect.size.height;
            rect.origin.y += rbMargin;
            break;
        case OSD_VPOSITION_LBOX :
            rect.origin.y = (tm + mr.size.height) + vmargin;
            rect.origin.y -= ltMargin;
            float maxContentY = NSMaxY(rect) - rbMargin;
            float maxBoundsY = NSMaxY(_viewBounds);
            if (maxBoundsY < maxContentY) {
                rect.origin.y -= maxContentY - maxBoundsY;
            }
            break;
    }
    _drawingRect = rect;
}

- (BOOL)setViewBounds:(NSRect)viewBounds movieRect:(NSRect)movieRect
{
    if (!NSEqualRects(_viewBounds, viewBounds) ||
        !NSEqualRects(_movieRect, movieRect)) {
        _viewBounds = viewBounds;
        _movieRect = movieRect;

        if (_string || _image) {
            _updateMask |= UPDATE_TEX_IMAGE;
        }
        _updateMask |= UPDATE_SHADOW | UPDATE_FONT | UPDATE_TEXTURE | UPDATE_DRAWING_RECT;
        return TRUE;
    }
    return FALSE;
}

- (void)drawOnScreen
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    if (_updateMask & UPDATE_TEX_IMAGE) {
        _updateMask &= ~UPDATE_TEX_IMAGE;
        if (_string) {
            [self setTexImage:[self makeTexImageForString:_string]];
        }
        else if (_image) {
            [self setTexImage:[self makeTexImageForImage:_image
                                               baseWidth:_imageBaseWidth]];
        }
        else {
            [self setTexImage:nil];
        }
    }
    if (_updateMask & UPDATE_TEXTURE) {
        _updateMask &= ~UPDATE_TEXTURE;
        [self makeTexture:CGLGetCurrentContext()];
    }
    if (_updateMask & UPDATE_DRAWING_RECT) {
        _updateMask &= ~UPDATE_DRAWING_RECT;
        [self updateDrawingRect];
    }

    if (_texName) {
        glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _texName);
        glBegin(GL_QUADS);
            NSSize size = [_texImage size];
            float minX = NSMinX(_drawingRect), maxX = NSMaxX(_drawingRect);
            float minY = NSMinY(_drawingRect), maxY = NSMaxY(_drawingRect);
            glTexCoord2f(0.0,        0.0);          glVertex2f(minX, minY); // TL
            glTexCoord2f(0.0,        size.height);  glVertex2f(minX, maxY); // BL
            glTexCoord2f(size.width, size.height);  glVertex2f(maxX, maxY); // TR
            glTexCoord2f(size.width, 0.0);          glVertex2f(maxX, minY); // BR
        glEnd();
    }
}

@end

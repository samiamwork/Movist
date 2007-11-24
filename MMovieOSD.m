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

#import "MMovieOSD.h"

#import <OpenGL/CGLContext.h>

@implementation MMovieOSD

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _updateMask = 0;

        _shadow = [[NSShadow alloc] init];
        _shadowNone = [[NSShadow alloc] init];
        _strongShadow = FALSE;

        _hAlign = OSD_HALIGN_CENTER;
        _vAlign = OSD_VALIGN_CENTER;
        _hMargin = _vMargin = 0.0;

        _texName = 0;
        [self clearContent];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_shadowColor release];
    [_shadow release];
    [_shadowNone release];
    [self makeTexture:CGLGetCurrentContext()];  // delete texture
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)hasContent { return FALSE; }
- (void)updateContent {}
- (void)clearContent {}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setMovieSize:(NSSize)size
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromSize(size));
    _movieSize = size;
    _updateMask |= UPDATE_TEXTURE;
}

- (void)setMovieRect:(NSRect)rect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    _movieRect = rect;
    _updateMask |= UPDATE_SHADOW | UPDATE_TEXTURE;
}

- (float)autoSize:(float)defaultSize
{
    return defaultSize * _movieRect.size.width / 640.0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)strongShadow { return _strongShadow; }

- (void)setShadowColor:(NSColor*)shadowColor
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_shadowColor isEqualTo:shadowColor]) {
        [_shadowColor release];
        _shadowColor = [shadowColor retain];
        _updateMask |= UPDATE_TEXTURE | UPDATE_SHADOW;
    }
}

- (void)setShadowBlur:(float)shadowBlur
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_shadowBlur != shadowBlur) {
        _shadowBlur = shadowBlur;
        _updateMask |= UPDATE_TEXTURE | UPDATE_SHADOW;
    }
}

- (void)setShadowOffset:(float)shadowOffset
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_shadowOffset != shadowOffset) {
        _shadowOffset = shadowOffset;
        _updateMask |= UPDATE_TEXTURE | UPDATE_SHADOW;
    }
}

- (void)setShadowStrong:(BOOL)strong
{
    if (_strongShadow != strong) {
        _strongShadow = strong;
        _updateMask |= UPDATE_TEXTURE | UPDATE_SHADOW;
    }
}

- (void)updateShadow
{
    float blur = [self autoSize:_shadowBlur];
    float offset = [self autoSize:_shadowOffset];
    [_shadow setShadowOffset:NSMakeSize(offset, -offset)];
    [_shadow setShadowBlurRadius:blur];
    [_shadow setShadowColor:_shadowColor];
    //TRACE(@"shadow updated: offset=\"%@\" blurRadius=%g color=%@",
    //      NSStringFromSize([_shadow shadowOffset]), [_shadow shadowBlurRadius], _shadowColor);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (unsigned int)hAlign { return _hAlign; }
- (unsigned int)vAlign { return _vAlign; }

- (void)setHAlign:(unsigned int)hAlign
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, hAlign);
    _hAlign = hAlign;
}

- (void)setVAlign:(unsigned int)vAlign
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, vAlign);
    _vAlign = vAlign;
}

- (BOOL)displayOnLetterBox
{
    if (_vAlign == OSD_VALIGN_UPPER_FROM_MOVIE_TOP ||
        _vAlign == OSD_VALIGN_LOWER_FROM_MOVIE_TOP) {
        return (_vAlign & OSD_VALIGN_UPPER_FROM_MOVIE_TOP) ? TRUE : FALSE;
    }
    else {
        return (_vAlign & OSD_VALIGN_LOWER_FROM_MOVIE_BOTTOM) ? TRUE : FALSE;
    }
}

- (float)hMargin { return _hMargin * 100; }
- (float)vMargin { return _vMargin * 100; }

- (void)setDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    //TRACE(@"%s %@ (%g,%g)", __PRETTY_FUNCTION__,
    //      displayOnLetterBox ? @"displayOnLetterBox" : @"displayOnMovie",
    //      hMargin, vMargin);
    if (_vAlign == OSD_VALIGN_UPPER_FROM_MOVIE_TOP ||
        _vAlign == OSD_VALIGN_LOWER_FROM_MOVIE_TOP) {
        if (displayOnLetterBox) {
            _vAlign = OSD_VALIGN_UPPER_FROM_MOVIE_TOP;
        }
        else {
            _vAlign = OSD_VALIGN_LOWER_FROM_MOVIE_TOP;
        }
    }
    else {
        if (displayOnLetterBox) {
            _vAlign = OSD_VALIGN_LOWER_FROM_MOVIE_BOTTOM;
        }
        else {
            _vAlign = OSD_VALIGN_UPPER_FROM_MOVIE_BOTTOM;
        }
    }
}

- (void)setHMargin:(float)hMargin
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, hMargin);
    _hMargin = hMargin / 100.0f; // percentage
    
    _updateMask |= UPDATE_TEXTURE;
}

- (void)setVMargin:(float)vMargin
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, vMargin);
    _vMargin = vMargin / 100.0f; // percentage
    
    _updateMask |= UPDATE_TEXTURE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSRect)drawingRectForViewBounds:(NSRect)viewBounds
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    NSRect rect;
    rect.size = _contentSize;
    
    float hmargin = _movieRect.size.width * _hMargin;
    float vmargin = _movieRect.size.height* _vMargin;
    
    NSRect mr = _movieRect;
    mr.origin.x   += hmargin;
    mr.size.width -= hmargin * 2;
    
    // horizontal align
    switch (_hAlign) {
        case OSD_HALIGN_LEFT :
            rect.origin.x = mr.origin.x;
            break;
        case OSD_HALIGN_CENTER :
            rect.origin.x = mr.origin.x + (mr.size.width - rect.size.width) / 2;
            break;
        case OSD_HALIGN_RIGHT :
            rect.origin.x = mr.origin.x + mr.size.width - rect.size.width;
            break;
    }

    // vertical align : rect is flipped
    float tm = NSMaxY(viewBounds) - NSMaxY(mr);
    switch (_vAlign) {
        case OSD_VALIGN_CENTER :
            rect.origin.y = mr.origin.y + (mr.size.height - rect.size.height) / 2;
            break;
        case OSD_VALIGN_UPPER_FROM_MOVIE_TOP :
            rect.origin.y = tm - vmargin - rect.size.height;
            float minY = NSMinY(viewBounds);
            if (NSMinY(rect) < minY) {
                rect.origin.y += minY - NSMinY(rect);
            }
            break;
        case OSD_VALIGN_LOWER_FROM_MOVIE_TOP :
            rect.origin.y = tm + vmargin;
            break;
        case OSD_VALIGN_UPPER_FROM_MOVIE_BOTTOM :
            rect.origin.y = (tm + mr.size.height) - vmargin - rect.size.height;
            break;
        case OSD_VALIGN_LOWER_FROM_MOVIE_BOTTOM :
            rect.origin.y = (tm + mr.size.height) + vmargin;
            float maxY = NSMaxY(viewBounds);
            if (maxY < NSMaxY(rect)) {
                rect.origin.y -= NSMaxY(rect) - maxY;
            }
            break;
    }
    return rect;
}

- (void)drawInViewBounds:(NSRect)viewBounds
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    if (_updateMask & UPDATE_SHADOW) {
        _updateMask &= ~UPDATE_SHADOW;
        [self updateShadow];
    }
    if (_updateMask & UPDATE_CONTENT) {
        _updateMask &= ~UPDATE_CONTENT;
        [self updateContent];
    }
    if (_updateMask & UPDATE_TEXTURE) {
        _updateMask &= ~UPDATE_TEXTURE;
        [self makeTexture:CGLGetCurrentContext()];
    }
    
    if (_texName) {
        [self drawTexture:[self drawingRectForViewBounds:viewBounds]];
    }
}

- (NSSize)updateTextureSizes
{
    // _contentSize & _drawingSize must be updated here.
    return NSMakeSize(0, 0);
}

- (void)drawContent:(NSSize)texSize {}

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

    NSSize texSize = [self updateTextureSizes];
    if (texSize.width == 0 || texSize.height == 0) {
        return;
    }

    // draw content
    NSImage* img = [[NSImage alloc] initWithSize:texSize];
    NSBitmapImageRep* bmp;
    [img lockFocus];
        [self drawContent:texSize];

        NSRect texRect = NSMakeRect(0, 0, texSize.width, texSize.height);
        bmp = [[NSBitmapImageRep alloc] initWithFocusedViewRect:texRect];

        //[[NSColor yellowColor] set];
        //NSFrameRect(texRect);
        //[[NSColor blueColor] set];
        //NSFrameRect(drawingRect);
    [img unlockFocus];
    
    // make texture
    glGenTextures(1, &_texName);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _texName);
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, texSize.width, texSize.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, [bmp bitmapData]);
    [bmp release];
    [img release];
}

- (void)drawTexture:(NSRect)rect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    rect.size = _drawingSize;

    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _texName);
        glBegin(GL_QUADS);
        // upper-left
        glTexCoord2f(0.0,                0.0);
        glVertex2f  (NSMinX(rect),       NSMinY(rect));
        // lower-left
        glTexCoord2f(0.0,                _drawingSize.height);
        glVertex2f  (NSMinX(rect),       NSMaxY(rect));
        // upper-right
        glTexCoord2f(_drawingSize.width, _drawingSize.height);
        glVertex2f  (NSMaxX(rect),        NSMaxY(rect));
        // lower-right
        glTexCoord2f(_drawingSize.width, 0.0);
        glVertex2f  (NSMaxX(rect),        NSMinY(rect));
    glEnd();
}

@end

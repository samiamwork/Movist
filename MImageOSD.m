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

#import "MImageOSD.h"

@implementation MImageOSD

- (BOOL)hasContent { return (_newImage != nil); }
- (void)clearContent { [self setImage:nil]; }

- (NSImage*)image { return _image; }

- (BOOL)setImage:(NSImage*)image
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_newImage != image) {
        [_newImage release];
        _newImage = [image retain];
        _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
        return TRUE;
    }
    return FALSE;
}

- (void)updateContent
{
    [_newImage retain];
    [_image release];
    _image = _newImage;
    
    if (!_image) {
        _contentSize.width  = 0;
        _contentSize.height = 0;
    }
    else {
        float size = MIN(_movieRect.size.width, _movieRect.size.height);
        float minSize = 16, maxSize = [_image size].width;
        size = (size < minSize) ? minSize : (maxSize <= size) ? maxSize : size;
        _contentSize.width  = size;
        _contentSize.height = size;
    }
}

- (void)drawContent:(NSRect)rect
{
    int i;  assert(0 < _shadowDarkness);
    for (i = 0; i < _shadowDarkness; i++) {
        [_image drawInRect:rect fromRect:NSZeroRect
                 operation:NSCompositeSourceOver fraction:1.0];
    }
    //[[NSColor blueColor] set];
    //NSFrameRect(rect);
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation MTextImageOSD

- (id)init
{
    if (self = [super init]) {
        // for stroke & shadow
        _contentLeftMargin  = 10;
        _contentRightMargin = 30;
        _contentTopMargin   = 10;
        _contentBottomMargin= 30;
    }
    return self;
}

- (void)updateContent
{
    [super updateContent];

    if (!_image) {
        _contentSize.width  = 0;
        _contentSize.height = 0;
    }
    else {
        _contentSize = [_image size];
        if (_contentSize.width == _contentLeftMargin + _contentRightMargin) {
            // need not draw for no content without margins for outline & shadow.
            _contentSize.width = 0;
            _contentSize.height= 0;
        }
    }
}

- (void)drawContent:(NSRect)rect
{
    [_image drawInRect:rect fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
    //[[NSColor blueColor] set];
    //NSFrameRect(rect);
}

@end

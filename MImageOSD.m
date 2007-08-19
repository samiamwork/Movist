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

#import "MImageOSD.h"

@implementation MImageOSD : MMovieOSD

- (BOOL)hasContent { return (_newImage != nil); }
- (void)clearContent { [self setImage:nil]; }

- (void)updateContent
{
    [_newImage retain];
    [_image release];
    _image = _newImage;
}

- (void)setImage:(NSImage*)image
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [image retain], [_newImage release], _newImage = image;
    _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
}

- (NSSize)updateTextureSizes
{
    if (![self hasContent]) {
        return NSMakeSize(0, 0);
    }

    float size = MIN(_movieRect.size.width, _movieRect.size.height);
    float minSize = 16, maxSize = [_image size].width;
    size = (size < minSize) ? minSize : (maxSize <= size) ? maxSize : size;
    _drawingSize.width  = _drawingSize.height = size;
    _contentSize.width  = _contentSize.height = size;
    return _drawingSize;
}

- (void)drawContent:(NSSize)texSize
{
    [_image drawInRect:NSMakeRect(0, 0, _drawingSize.width, _drawingSize.height)
              fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

@end


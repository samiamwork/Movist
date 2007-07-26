//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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


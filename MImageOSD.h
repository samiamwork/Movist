//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovieOSD.h"

@interface MImageOSD : MMovieOSD
{
    NSImage* _newImage;
    NSImage* _image;
}

- (void)setImage:(NSImage*)image;

@end

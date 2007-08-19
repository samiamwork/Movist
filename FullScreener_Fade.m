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

#import "FullScreener.h"

#import "MMovieView.h"
#import "MainWindow.h"
#import "FullWindow.h"

@implementation FullScreener (Fade)

- (void)fadeOutScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float rate = [[_movieView movie] rate];
    [[_movieView movie] setRate:0.0];

    NSRect frame = [[_mainWindow screen] frame];
    NSWindow* blackWindow = [[NSWindow alloc] initWithContentRect:frame
                                                        styleMask:NSBorderlessWindowMask
                                                          backing:NSBackingStoreBuffered
                                                            defer:FALSE
                                                           screen:[_mainWindow screen]];
    [blackWindow setBackgroundColor:[NSColor blackColor]];
    [blackWindow setLevel:NSScreenSaverWindowLevel];
    [blackWindow useOptimizedDrawing:TRUE];
    [blackWindow setHasShadow:FALSE];
    [blackWindow setOpaque:FALSE];
    
    [blackWindow setAlphaValue:0.0];
    [blackWindow orderFront:self];
    [blackWindow fadeAnimationWithEffect:NSViewAnimationFadeInEffect
                            blockingMode:NSAnimationBlocking duration:0.5];
    [blackWindow release];

    [[_movieView movie] setRate:rate];
}

@end

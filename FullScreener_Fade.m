//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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

//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

#import <Carbon/Carbon.h>   // for SystemUIMode, Options

@class MMovieView;
@class MainWindow;
@class FullWindow;
@class PlayPanel;

@interface FullScreener : NSObject
{
    int _effect;
    MMovieView* _movieView;
    MainWindow* _mainWindow;
    FullWindow* _fullWindow;
    PlayPanel* _playPanel;

    NSURL* _movieURL;
    NSRect _movieViewRect;  // in _mainWindow
    SystemUIMode _normalSystemUIMode;
    SystemUIOptions _normalSystemUIOptions;
    NSTimer* _updateSystemActivityTimer;

    // for animation effect
    NSWindow* _blackWindow;
    NSRect _restoreRect;
    NSRect _maxMainRect;
    NSRect _fullMovieRect;
}

- (id)initWithMainWindow:(MainWindow*)mainWindow playPanel:(PlayPanel*)playPanel;

#if defined(_SUPPORT_FRONT_ROW)
- (BOOL)isNavigationMode;
#endif
- (FullWindow*)fullWindow;
- (void)setEffect:(int)effect;
- (void)setMovieURL:(NSURL*)movieURL;

- (void)beginFullScreen;
- (void)endFullScreen;

#if defined(_SUPPORT_FRONT_ROW)
- (void)selectUpper;
- (void)selectLower;
- (void)openSelectedItem;
- (void)closeCurrent;
#endif

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface FullScreener (Fade)

- (void)fadeOutScreen;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface FullScreener (Animation)

- (void)initAnimation;
- (void)runBeginAnimation;
- (void)runEndAnimation;

@end

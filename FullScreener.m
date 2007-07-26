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
#import "PlayPanel.h"

@implementation FullScreener

- (id)initWithMainWindow:(MainWindow*)mainWindow playPanel:(PlayPanel*)playPanel
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _mainWindow = [mainWindow retain];
        _movieView = [[_mainWindow movieView] retain];
        _playPanel = [playPanel retain];
        _fullWindow = [[FullWindow alloc] initWithFullScreener:self
                            screen:[_mainWindow screen] playPanel:_playPanel];

        _movieViewRect = [_movieView frame];

        // for animation effect
        [self initAnimation];
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullWindow release];
    [_mainWindow release];
    [_movieView release];
    [_movieURL release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#if defined(_SUPPORT_FRONT_ROW)
- (BOOL)isNavigationMode { return (_movieURL == nil); }
#endif
- (FullWindow*)fullWindow { return _fullWindow; }

- (void)setEffect:(int)effect
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, effect);
    _effect = effect;
}

- (void)setMovieURL:(NSURL*)movieURL
{
    TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    [movieURL retain], [_movieURL release], _movieURL = movieURL;
    [_fullWindow setMovieURL:_movieURL];
    [_playPanel setMovieURL:_movieURL];
}

- (void)beginFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // hide system UI elements(main-menu, dock) & cursor
    GetSystemUIMode(&_normalSystemUIMode, &_normalSystemUIOptions);
    SetSystemUIMode(kUIModeAllSuppressed, 0);
    [NSCursor setHiddenUntilMouseMoves:TRUE];

#if defined(_SUPPORT_FRONT_ROW)
    int effect = ([self isNavigationMode]) ? FS_EFFECT_FADE : _effect;
#else
    int effect = _effect;
#endif
    switch (effect) {
        case FS_EFFECT_FADE :
            [self fadeOutScreen];
            break;
        case FS_EFFECT_ANIMATION :
            [_fullWindow setFrame:_restoreRect display:TRUE];
            break;
        default :   // FS_EFFECT_NONE
            // do nothing
            break;
    }

    // move _movieView to _fullWindow from _mainWindow
    [_mainWindow setHasShadow:FALSE];
    [_mainWindow disableScreenUpdatesUntilFlush];
    [_movieView removeFromSuperviewWithoutNeedingDisplay];
    [_fullWindow setMovieView:_movieView];
    [_fullWindow makeKeyAndOrderFront:nil];

    switch (effect) {
        case FS_EFFECT_FADE :
            [_fullWindow setFrame:[[_fullWindow screen] frame] display:TRUE];
            [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
            break;
        case FS_EFFECT_ANIMATION :
            [self runBeginAnimation];
            break;
        default :   // FS_EFFECT_NONE
            [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
            break;
    }
    [_fullWindow setAcceptsMouseMovedEvents:TRUE];

    // update system activity periodically not to activate screen saver
    _updateSystemActivityTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
        target:self selector:@selector(updateSystemActivity:) userInfo:nil repeats:TRUE];
}

- (void)endFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_updateSystemActivityTimer invalidate];

    [_fullWindow setAcceptsMouseMovedEvents:FALSE];
    [_playPanel orderOut:self];

#if defined(_SUPPORT_FRONT_ROW)
    int effect = ([self isNavigationMode]) ? FS_EFFECT_FADE : _effect;
#else
    int effect = _effect;
#endif
    switch (effect) {
        case FS_EFFECT_FADE :
            [self fadeOutScreen];
            [_fullWindow removeChildWindow:_mainWindow];
            break;
        case FS_EFFECT_ANIMATION :
            [self runEndAnimation];
            break;
        default :   // FS_EFFECT_NONE
            [_fullWindow removeChildWindow:_mainWindow];
            break;
    }
    [_fullWindow orderOut:self];

    // move _movieView to _mainWindow from _fullWindow
    [_mainWindow disableScreenUpdatesUntilFlush];
    [_movieView removeFromSuperviewWithoutNeedingDisplay];
    [[_mainWindow contentView] addSubview:_movieView];
    [_movieView setFrame:_movieViewRect];
    [_mainWindow makeFirstResponder:_movieView];
    [_mainWindow makeKeyAndOrderFront:nil];

    // restore system UI elements and _mainWindow's shadow
    SetSystemUIMode(_normalSystemUIMode, _normalSystemUIOptions);
    [NSCursor setHiddenUntilMouseMoves:FALSE];
    [_mainWindow setHasShadow:TRUE];

    [_fullWindow release];
    _fullWindow = nil;
}

- (void)updateSystemActivity:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    UpdateSystemActivity(UsrActivity);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark navigation

#if defined(_SUPPORT_FRONT_ROW)
- (void)selectUpper
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isNavigationMode]) {
        [_fullWindow selectUpper];
    }
}

- (void)selectLower
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isNavigationMode]) {
        [_fullWindow selectLower];
    }
}

- (void)openSelectedItem
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isNavigationMode]) {
        [_fullWindow openSelectedItem];
    }
}

- (void)closeCurrent
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isNavigationMode]) {
        [_fullWindow closeCurrent];
    }
}
#endif

@end

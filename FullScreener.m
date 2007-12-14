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
#import "PlayPanel.h"

@implementation FullScreener

- (id)initWithMainWindow:(MainWindow*)mainWindow playPanel:(PlayPanel*)playPanel
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _mainWindow = [mainWindow retain];
        _movieView = [[_mainWindow movieView] retain];
        _playPanel = [playPanel retain];
        _fullWindow = [[FullWindow alloc] initWithScreen:[_mainWindow screen]
                                               playPanel:_playPanel];

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

    if ([self isNavigatable]) {
        [_fullWindow selectMovie:movieURL];
    }
}

#define FADE_EFFECT_DURATION   0.5

- (void)beginFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    GetSystemUIMode(&_normalSystemUIMode, &_normalSystemUIOptions);
    // if currently in main screen, hide system UI elements(main-menu, dock)
    if ([[_mainWindow screen] isEqualTo:[[NSScreen screens] objectAtIndex:0]]) {
        SetSystemUIMode(kUIModeAllSuppressed, 0);
    }
    [NSCursor setHiddenUntilMouseMoves:TRUE];

    BOOL forNavigation = (_movieURL == nil);
    int effect = (forNavigation) ? FS_EFFECT_FADE : _effect;
    float rate; // for FS_EFFECT_FADE
    switch (effect) {
        case FS_EFFECT_FADE :
            rate = [[_movieView movie] rate];
            [[_movieView movie] setRate:0.0];
            [[_mainWindow screen] fadeOut:FADE_EFFECT_DURATION];
            break;
        case FS_EFFECT_ANIMATION :
            [_fullWindow setFrame:_restoreRect display:TRUE];
            break;
        default :   // FS_EFFECT_NONE
            // do nothing
            break;
    }

    BOOL subtitleVisible = [_movieView subtitleVisible];
    if (subtitleVisible) {
        [_movieView setSubtitleVisible:FALSE];
    }
    // move _movieView to _fullWindow from _mainWindow
    [_mainWindow setHasShadow:FALSE];
    [_mainWindow disableScreenUpdatesUntilFlush];
    [_movieView lockDraw];
    [_movieView removeFromSuperviewWithoutNeedingDisplay];
    [_fullWindow setMovieView:_movieView];
    [_fullWindow makeKeyAndOrderFront:nil];
    [_movieView unlockDraw];

    switch (effect) {
        case FS_EFFECT_FADE :
            [_fullWindow setFrame:[[_fullWindow screen] frame] display:TRUE];
            [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
            [_fullWindow flushWindow];
            [_mainWindow flushWindow];
            [[_mainWindow screen] fadeIn:FADE_EFFECT_DURATION];
            [[_movieView movie] setRate:rate];
            break;
        case FS_EFFECT_ANIMATION :
            [self runBeginAnimation];
            break;
        default :   // FS_EFFECT_NONE
            [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
            break;
    }
    if (subtitleVisible) {
        [_movieView updateSubtitle];
        [_movieView setSubtitleVisible:TRUE];
    }

    [_fullWindow setAcceptsMouseMovedEvents:TRUE];

    // update system activity periodically not to activate screen saver
    _updateSystemActivityTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
        target:self selector:@selector(updateSystemActivity:) userInfo:nil repeats:TRUE];
}

- (void)endFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_updateSystemActivityTimer invalidate];

    [_fullWindow setAcceptsMouseMovedEvents:FALSE];
    [_playPanel orderOutWithFadeOut:self];

    BOOL subtitleVisible = [_movieView subtitleVisible];
    if (subtitleVisible) {
        [_movieView setSubtitleVisible:FALSE];
    }
    float rate; // for FS_EFFECT_FADE
    int effect = ([self isNavigatable]) ? FS_EFFECT_FADE : _effect;
    switch (effect) {
        case FS_EFFECT_FADE :
            rate = [[_movieView movie] rate];
            [[_movieView movie] setRate:0.0];
            [[_mainWindow screen] fadeOut:FADE_EFFECT_DURATION];
            [_fullWindow removeChildWindow:_mainWindow];
            break;
        case FS_EFFECT_ANIMATION :
            [self runEndAnimation];
            break;
        default :   // FS_EFFECT_NONE
            [_fullWindow removeChildWindow:_mainWindow];
            break;
    }
    [_mainWindow disableScreenUpdatesUntilFlush];
    [_mainWindow disableFlushWindow];
    [_fullWindow orderOut:self];

    // move _movieView to _mainWindow from _fullWindow
    [_movieView lockDraw];
    [_movieView removeFromSuperviewWithoutNeedingDisplay];
    [[_mainWindow contentView] addSubview:_movieView];
    [_movieView setFrame:_movieViewRect];
    [_movieView unlockDraw];

    [_mainWindow makeFirstResponder:_movieView];
    [_mainWindow makeKeyAndOrderFront:nil];
    [_mainWindow setHasShadow:TRUE];
    [_mainWindow enableFlushWindow];
    [_mainWindow flushWindowIfNeeded];

    if (subtitleVisible) {
        [_movieView updateSubtitle];
        [_movieView setSubtitleVisible:TRUE];
    }

    // restore system UI elements(main-menu, dock)
    SystemUIMode systemUIMode;
    GetSystemUIMode(&systemUIMode, 0);
    if (systemUIMode == kUIModeAllSuppressed) {
        SetSystemUIMode(_normalSystemUIMode, _normalSystemUIOptions);
    }
    [NSCursor setHiddenUntilMouseMoves:FALSE];

    [_fullWindow release];
    _fullWindow = nil;

    if (effect == FS_EFFECT_FADE) {
        [_mainWindow flushWindow];
        [_movieView display];
        [[_mainWindow screen] fadeIn:FADE_EFFECT_DURATION];
        [[_movieView movie] setRate:rate];
    }
}

- (void)updateSystemActivity:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    UpdateSystemActivity(UsrActivity);

    [_playPanel autoHidePanel];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark navigation

- (BOOL)isNavigatable   { return [_fullWindow isNavigatable]; }
- (BOOL)isNavigating    { return [_fullWindow isNavigating]; }
- (BOOL)isPreviewing    { return [_fullWindow isPreviewing]; }

- (void)selectUpper     { [_fullWindow selectUpper]; }
- (void)selectLower     { [_fullWindow selectLower]; }
- (void)selectCurrent   { [_fullWindow selectMovie:_movieURL]; }

- (void)openCurrent     { [_fullWindow openCurrent]; }
- (BOOL)closeCurrent    { return [_fullWindow closeCurrent]; }
- (BOOL)canCloseCurrent { return [_fullWindow canCloseCurrent]; }

@end

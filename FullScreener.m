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

#import "FullScreener.h"

#import "MMovieView.h"
#import "MainWindow.h"
#import "FullWindow.h"
#import "PlayPanel.h"
#import "UserDefaults.h"

@interface FullScreener (NoEffectTransition)

- (void)beginNoEffectTransition;
- (void)endNoEffectTransition;

@end

@interface FullScreener (FadeTransition)

- (void)beginFadeTransition:(float)fadeDuration;
- (void)endFadeTransition:(float)fadeDuration;

@end

@interface FullScreener (AnimationTransition)

- (void)initAnimationTransition;
- (void)beginAnimationTransition;
- (void)endAnimationTransition;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FullScreener

- (id)initWithMainWindow:(MainWindow*)mainWindow
               playPanel:(PlayPanel*)playPanel
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _mainWindow = [mainWindow retain];
        _movieView = [[_mainWindow movieView] retain];
        _playPanel = [playPanel retain];
        _fullWindow = [[FullWindow alloc] initWithScreen:[_mainWindow screen]
                                               playPanel:_playPanel];

        _movieViewRect = [_movieView frame];
        _autoShowDock = TRUE;
        _mainMenuAndDockIsHidden = FALSE;

        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        _effect = [defaults integerForKey:MFullScreenEffectKey];
        #if defined(AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER)
        if ([_mainWindow userSpaceScaleFactor] != 1.0 &&
            _effect == FS_EFFECT_ANIMATION) {
            _effect = FS_EFFECT_NONE;
        }
        #endif
        [self initAnimationTransition];

        if ([defaults boolForKey:MFullScreenBlackScreensKey] &&
            1 < [[NSScreen screens] count]) {
            NSMutableArray* screens = [NSMutableArray arrayWithArray:[NSScreen screens]];
            [screens removeObject:[_mainWindow screen]];    // except current screen
            _blackScreenFader = [[ScreenFader alloc] initWithScreens:screens];
        }
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_blackScreenFader release];
    [_fullWindow release];
    [_mainWindow release];
    [_movieView release];
    [_movieURL release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (FullWindow*)fullWindow { return _fullWindow; }

- (void)setMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    [movieURL retain], [_movieURL release], _movieURL = movieURL;
    [_fullWindow setMovieURL:_movieURL];
    [_playPanel setMovieURL:_movieURL];

    if ([self isNavigation]) {
        [_fullWindow selectMovie:movieURL];
    }
}

- (void)setAutoShowDock:(BOOL)autoShow
{
    _autoShowDock = autoShow;
}

#define SCREEN_FADE_DURATION    0.25
#define FADE_EFFECT_DURATION    0.5
#define NAV_FADE_DURATION       1.0

- (void)beginBlackScreens { [_blackScreenFader fadeOut:SCREEN_FADE_DURATION]; }
- (void)endBlackScreens   { [_blackScreenFader fadeIn:SCREEN_FADE_DURATION]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-screen

- (BOOL)isFullScreen { return ![self isDesktopBackground] && ![self isNavigating]; }

- (void)beginFullScreen
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_blackScreenFader) {
        [self beginBlackScreens];
    }

    BOOL subtitleVisible = [_movieView subtitleVisible];
    [_movieView setSubtitleVisible:FALSE];

    _fullScreenFromDesktopBackground = [self isDesktopBackground];
    if (_fullScreenFromDesktopBackground) {
        [self beginFullScreenFromDesktopBackground];
    }
    else {
        switch (_effect) {
            case FS_EFFECT_FADE :
                [self beginFadeTransition:FADE_EFFECT_DURATION];
                break;
            case FS_EFFECT_ANIMATION :
                [self beginAnimationTransition];
                break;
            default :   // FS_EFFECT_NONE
                [self beginNoEffectTransition];
                break;
        }
    }

    [_movieView setSubtitleVisible:subtitleVisible];

    [_fullWindow setAcceptsMouseMovedEvents:TRUE];
}

- (void)endFullScreen
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullWindow setAcceptsMouseMovedEvents:FALSE];
    [_playPanel orderOut:self];     // immediately without fade-effect

    BOOL subtitleVisible = [_movieView subtitleVisible];
    [_movieView setSubtitleVisible:FALSE];

    if (_fullScreenFromDesktopBackground) {
        [self endFullScreenToDesktopBackground];
    }
    else {
        switch (_effect) {
            case FS_EFFECT_FADE :
                [self endFadeTransition:FADE_EFFECT_DURATION];
                break;
            case FS_EFFECT_ANIMATION :
                [self endAnimationTransition];
                break;
            default :   // FS_EFFECT_NONE
                [self endNoEffectTransition];
                break;
        }
    }

    [_movieView setSubtitleVisible:subtitleVisible];

    if (_blackScreenFader) {
        [self endBlackScreens];
    }
}

- (void)autoHidePlayPanel { [_playPanel autoHidePanel]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark desktop-background

- (BOOL)isDesktopBackground { return ([_fullWindow level] == DesktopWindowLevel); }

- (void)beginDesktopBackground
{
    [_fullWindow setLevel:DesktopWindowLevel];
    [self attachMovieViewToFullWindow];
    [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
    [_mainWindow flushWindow];
    [_fullWindow flushWindow];
}

- (void)endDesktopBackground
{
    [_fullWindow removeChildWindow:_mainWindow];
    [_fullWindow setLevel:NSNormalWindowLevel];
    [self detachMovieViewFromFullWindow];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark navigation

- (BOOL)isNavigation { return [_fullWindow isNavigation]; }
- (BOOL)isNavigating { return [_fullWindow isNavigating]; }
- (BOOL)isPreviewing { return [_fullWindow isPreviewing]; }

- (void)beginNavigation
{
    if (_blackScreenFader) {
        [self beginBlackScreens];
    }
    
    [self beginFadeTransition:NAV_FADE_DURATION];

    [_fullWindow setAcceptsMouseMovedEvents:TRUE];
}

- (void)endNavigation
{
    [_fullWindow setAcceptsMouseMovedEvents:FALSE];
    
    [self endFadeTransition:NAV_FADE_DURATION];
    
    if (_blackScreenFader) {
        [self endBlackScreens];
    }
}

- (void)selectUpper     { [_fullWindow selectUpper]; }
- (void)selectLower     { [_fullWindow selectLower]; }
- (void)selectCurrent   { [_fullWindow selectMovie:_movieURL]; }

- (void)openCurrent     { [_fullWindow openCurrent]; }
- (BOOL)closeCurrent    { return [_fullWindow closeCurrent]; }
- (BOOL)canCloseCurrent { return [_fullWindow canCloseCurrent]; }

@end

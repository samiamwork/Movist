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

@implementation FullScreener (Transition)

- (void)showMainMenuAndDock
{
    SystemUIMode systemUIMode;
    GetSystemUIMode(&systemUIMode, 0);
    if (systemUIMode == kUIModeAllSuppressed) {
        SetSystemUIMode(_normalSystemUIMode, _normalSystemUIOptions);
    }
}

- (void)hideMainMenuAndDock
{
    GetSystemUIMode(&_normalSystemUIMode, &_normalSystemUIOptions);
    
    // if currently in menu-bar-screen, hide system UI elements(main-menu, dock)
    NSScreen* menuBarScreen = [[NSScreen screens] objectAtIndex:0];
    if (_screenFader || [[_mainWindow screen] isEqualTo:menuBarScreen]) {
        // if cursor is in dock, move cursor out of dock area to hide dock.
        NSRect rc = [menuBarScreen visibleFrame];
        NSPoint p = [NSEvent mouseLocation];
        if (!NSPointInRect(p, rc)) {
            float margin = 20;   // some margin needed
            if (p.x < NSMinX(rc)) {         // left-side dock
                p.x = NSMinX(rc) + margin;
            }
            else if (NSMaxX(rc) <= p.x) {   // right-side dock
                p.x = NSMaxX(rc) - margin;
            }
            else if (p.y < NSMinY(rc)) {    // bottom-side dock
                p.y = NSMinY(rc) + margin;
            }
            CGDisplayMoveCursorToPoint([_movieView displayID],
                                       CGPointMake(p.x, NSMaxY(rc) - p.y));
        }
        SetSystemUIMode(kUIModeAllSuppressed, 0);
    }
}

- (void)attachMovieViewToFullWindow
{
    [_mainWindow disableScreenUpdatesUntilFlush];
    [_movieView lockDraw];
    [_movieView removeFromSuperviewWithoutNeedingDisplay];
    [_fullWindow setMovieView:_movieView];
    [_movieView unlockDraw];

    if ([_fullWindow level] == DesktopWindowLevel) {
        [_fullWindow orderBack:nil];
        [_fullWindow makeKeyWindow];
    }
    else {
        [_fullWindow makeKeyAndOrderFront:nil];
    }
}

- (void)detachMovieViewFromFullWindow
{
    [_mainWindow disableScreenUpdatesUntilFlush];
    [_mainWindow disableFlushWindow];
    [_fullWindow orderOut:self];

    // move _movieView to _mainWindow from _fullWindow
    [_movieView lockDraw];
    [_movieView removeFromSuperviewWithoutNeedingDisplay];
    [[_mainWindow contentView] addSubview:_movieView];
    [_movieView setFrame:_movieViewRect];
    [_movieView updateMovieRect:FALSE];
    [_movieView unlockDraw];
    [_movieView display];

    [_mainWindow makeFirstResponder:_movieView];
    [_mainWindow makeKeyAndOrderFront:nil];
    [_mainWindow setHasShadow:TRUE];
    [_mainWindow enableFlushWindow];
    [_mainWindow flushWindowIfNeeded];
}

- (void)beginFullScreenFromDesktopBackground
{
    [self hideMainMenuAndDock];
    [NSCursor setHiddenUntilMouseMoves:TRUE];
    [_fullWindow setLevel:NSNormalWindowLevel];
    [_fullWindow makeKeyAndOrderFront:nil];
}

- (void)endFullScreenToDesktopBackground
{
    [_fullWindow setLevel:DesktopWindowLevel];
    [_fullWindow orderBack:nil];
    [_fullWindow makeKeyWindow];
    [NSCursor setHiddenUntilMouseMoves:FALSE];
    [self showMainMenuAndDock];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FullScreener (NoEffectTransition)

- (void)beginNoEffectTransition
{
    [self hideMainMenuAndDock];
    [NSCursor setHiddenUntilMouseMoves:TRUE];
    [self attachMovieViewToFullWindow];
    [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
}

- (void)endNoEffectTransition
{
    [_fullWindow removeChildWindow:_mainWindow];
    [self detachMovieViewFromFullWindow];
    [self showMainMenuAndDock];
    [NSCursor setHiddenUntilMouseMoves:FALSE];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FullScreener (FadeTransition)

- (void)beginFadeTransition:(float)fadeDuration
{
    [NSCursor setHiddenUntilMouseMoves:TRUE];
    float rate = [[_movieView movie] rate];
    [[_movieView movie] setRate:0.0];
    ScreenFader* fader = [ScreenFader screenFaderWithScreen:[_mainWindow screen]];
    [fader fadeOut:fadeDuration];

    [self hideMainMenuAndDock];
    [self attachMovieViewToFullWindow];
    [_fullWindow setFrame:[[_fullWindow screen] frame] display:TRUE];
    [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];
    [_fullWindow flushWindow];
    [_mainWindow flushWindow];

    [fader fadeIn:fadeDuration];
    [[_movieView movie] setRate:rate];
}

- (void)endFadeTransition:(float)fadeDuration
{
    float rate = [[_movieView movie] rate];
    [[_movieView movie] setRate:0.0];
    ScreenFader* fader = [ScreenFader screenFaderWithScreen:[_mainWindow screen]];
    [fader fadeOut:fadeDuration];

    [_fullWindow removeChildWindow:_mainWindow];
    [self detachMovieViewFromFullWindow];
    [self showMainMenuAndDock];
    [NSCursor setHiddenUntilMouseMoves:FALSE];

    [fader fadeIn:fadeDuration];
    [[_movieView movie] setRate:rate];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FullScreener (AnimationTransition)

//#define _USE_NSViewAnimation

- (void)animatedResizeForBegin:(BOOL)forBegin
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, forBegin ? @"begin" : @"end");
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(fullWindowResized:)
     name:NSWindowDidResizeNotification object:_fullWindow];

#if defined(_USE_NSViewAnimation)
    NSRect fullWindowRect;
    NSString* blackWindowEffect;
    if (forBegin) {
        fullWindowRect = _fullMovieRect;
        blackWindowEffect = NSViewAnimationFadeInEffect;
    }
    else {
        fullWindowRect = _restoreRect;
        blackWindowEffect = NSViewAnimationFadeOutEffect;
    }
    NSArray* array = [NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       _fullWindow, NSViewAnimationTargetKey,
                       [NSValue valueWithRect:fullWindowRect], NSViewAnimationEndFrameKey,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       _blackWindow, NSViewAnimationTargetKey,
                       blackWindowEffect, NSViewAnimationEffectKey,
                       nil],
                      nil];
    NSViewAnimation* animation = [[NSViewAnimation alloc] initWithViewAnimations:array];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setDuration:0.2];
    [animation startAnimation];
    [animation release];
#else   // !_USE_NSViewAnimation
    float beginAlpha, endAlpha;
    if (forBegin) { beginAlpha = 0.0, endAlpha = 1.0; } // transparent => opaque
    else          { beginAlpha = 1.0, endAlpha = 0.0; } // opaque => transparent
    NSRect fullWindowRect = (forBegin) ? _fullMovieRect : _restoreRect;
    [_blackWindow setAlphaValue:beginAlpha];
    [_fullWindow setFrame:fullWindowRect display:TRUE animate:TRUE];
    [_blackWindow setAlphaValue:endAlpha];
#endif

    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NSWindowDidResizeNotification object:_fullWindow];
}

- (void)fullWindowResized:(NSNotification*)notification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // resize _mainWindow for _fullWindow
    NSRect fr = [_fullWindow frame];
    NSRect mr = [_mainWindow frameRectForMovieRect:fr];
    if (_maxMainRect.size.width < mr.size.width) {
        mr.origin.x += (mr.size.width - _maxMainRect.size.width) / 2;
        mr.size.width = _maxMainRect.size.width;
    }
    if (_maxMainRect.size.height < mr.size.height) {
        mr.origin.y += (mr.size.height - _maxMainRect.size.height) / 2;
        mr.size.height = _maxMainRect.size.height;
    }
    [_mainWindow setFrame:mr display:TRUE];  // no animation

#if !defined(_USE_NSViewAnimation)
    // update _blackWindow transparency
    [_blackWindow setAlphaValue:fr.size.width / _fullMovieRect.size.width];
#endif
}

- (void)runBeginAnimation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // create _blackWindow
    NSRect frame = [[_mainWindow screen] frame];
    _blackWindow = [[NSWindow alloc] initWithContentRect:frame
                                               styleMask:NSBorderlessWindowMask
                                                 backing:NSBackingStoreBuffered
                                                   defer:FALSE
                                                  screen:[_mainWindow screen]];
    [_blackWindow useOptimizedDrawing:TRUE];
    [_blackWindow setBackgroundColor:[NSColor blackColor]];
    [_blackWindow setHasShadow:FALSE];
    [_blackWindow setOpaque:FALSE];
    [_blackWindow setAlphaValue:0.0];    // initially transparent

    [_fullWindow addChildWindow:_blackWindow ordered:NSWindowBelow];
    [_fullWindow addChildWindow:_mainWindow ordered:NSWindowBelow];

    BOOL subtitleVisible = [_movieView subtitleVisible];
    [_movieView setSubtitleVisible:FALSE];
    [_mainWindow setHasShadow:FALSE];

    // resizing-animation from movie-view-rect to full-movie-rect
    [self animatedResizeForBegin:TRUE];

    // resize to screen-rect
    NSRect screenRect = [[_fullWindow screen] frame];
    [_fullWindow setFrame:screenRect display:TRUE];

    [_mainWindow setHasShadow:TRUE];
    [_movieView setSubtitleVisible:subtitleVisible];
}

- (void)runEndAnimation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL subtitleVisible = [_movieView subtitleVisible];
    [_movieView setSubtitleVisible:FALSE];
    [_mainWindow setHasShadow:FALSE];

    // resize to full-movie-rect
    [_fullWindow setFrame:_fullMovieRect display:TRUE];

    // resizing-animation from full-movie-rect to movie-view-rect
    [self animatedResizeForBegin:FALSE];

    [_mainWindow setHasShadow:TRUE];
    [_movieView setSubtitleVisible:subtitleVisible];

    [_fullWindow removeChildWindow:_blackWindow];
    [_fullWindow removeChildWindow:_mainWindow];
    [_blackWindow release];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)initAnimationTransition
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // _restoreRect
    _restoreRect = [[_mainWindow contentView] convertRect:[_movieView frame] toView:nil];
    _restoreRect.origin = [_mainWindow convertBaseToScreen:_restoreRect.origin];
    
    // _fullMovieRect
    NSRect sr = [[_fullWindow screen] frame];
    _fullMovieRect = [_movieView calcMovieRectForBoundingRect:sr];
    
    // _maxMainRect
    _maxMainRect = [_mainWindow frameRectForMovieRect:_fullMovieRect];
    if (sr.size.width < _maxMainRect.size.width) {
        _maxMainRect.origin.x += (_maxMainRect.size.width - sr.size.width) / 2;
        _maxMainRect.size.width = sr.size.width;
    }
    if (sr.size.height < _maxMainRect.size.height) {
        _maxMainRect.origin.y += (_maxMainRect.size.height - sr.size.height) / 2;
        _maxMainRect.size.height = sr.size.height;
    }
}

- (void)beginAnimationTransition
{
    [self hideMainMenuAndDock];
    [NSCursor setHiddenUntilMouseMoves:TRUE];
    [self attachMovieViewToFullWindow];
    [_fullWindow setFrame:_restoreRect display:TRUE];
    [self runBeginAnimation];
}

- (void)endAnimationTransition
{
    [self runEndAnimation];
    [self detachMovieViewFromFullWindow];
    [self showMainMenuAndDock];
    [NSCursor setHiddenUntilMouseMoves:FALSE];
}

@end

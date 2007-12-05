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

@implementation FullScreener (Animation)

- (void)initAnimation
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

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

    // resizing-animation from movie-view-rect to full-movie-rect
    [self animatedResizeForBegin:TRUE];
    
    // resize to screen-rect
    NSRect screenRect = [[_fullWindow screen] frame];
    [_fullWindow setFrame:screenRect display:TRUE];
}

- (void)runEndAnimation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // resize to full-movie-rect
    [_fullWindow setFrame:_fullMovieRect display:TRUE];

    // resizing-animation from full-movie-rect to movie-view-rect
    [self animatedResizeForBegin:FALSE];

    [_fullWindow removeChildWindow:_blackWindow];
    [_fullWindow removeChildWindow:_mainWindow];
    [_blackWindow release];
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

@end

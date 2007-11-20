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

#import "PlayPanel.h"

@implementation PlayPanel

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(unsigned int)styleMask
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super initWithContentRect:contentRect
                                styleMask:NSBorderlessWindowMask
                                  backing:bufferingType
                                    defer:deferCreation]) {
        [self setOpaque:FALSE];
        [self setAlphaValue:1.0];
        [self setHasShadow:FALSE];
        [self useOptimizedDrawing:TRUE];
        [self setMovableByWindowBackground:TRUE];
    }
    return self;
}

- (void)awakeFromNib
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setBackgroundColor:[self makeHUDBackgroundColor]];
}

- (void)invalidateHideTimer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_hideTimer && [_hideTimer isValid]) {
        [_hideTimer invalidate];
        _hideTimer = nil;
    }
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self invalidateHideTimer];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return FALSE; }

- (void)setMovieURL:(NSURL*)movieURL
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* title = (movieURL) ? [[movieURL path] lastPathComponent] : @"";
    [_titleTextField setStringValue:title];
    [self setTitle:title];
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define PLAY_PANEL_FADE_DURATION     0.5

- (void)showPanel
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isVisible]) {
        [self setAlphaValue:0.0];
        [self orderFront:self];
        [self fadeWithEffect:NSViewAnimationFadeInEffect
                blockingMode:NSAnimationBlocking
                    duration:PLAY_PANEL_FADE_DURATION];
    }
}

- (void)hidePanel
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isVisible] && (!_hideTimer || ![_hideTimer isValid])) {
        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                    target:self selector:@selector(fadeHide:)
                                    userInfo:nil repeats:FALSE];
    }
}

- (void)fadeHide:(NSTimer*)timer
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _hideTimer = nil;

    if ([_movieView movie]) {
        [self fadeWithEffect:NSViewAnimationFadeOutEffect
                blockingMode:NSAnimationBlocking
                    duration:PLAY_PANEL_FADE_DURATION];
        [self orderOut:self];
        [NSCursor setHiddenUntilMouseMoves:TRUE];
    }
}

- (void)updateByMouseInScreen:(NSPoint)point
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromPoint(point));
    if (![_movieView movie] || [_movieView window] == [NSApp mainWindow]) {
        return;
    }

    if (NSPointInRect(point, [[_movieView window] frame])) {
        [self invalidateHideTimer];
        if (![self isVisible]) {
            [self showPanel];
        }
        else if (!NSPointInRect(point, [self frame])) {
            [self hidePanel];
        }
    }
    else if ([self isVisible]) {
        [self hidePanel];
    }
}

- (void)orderFront:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self screen] != [[_movieView window] screen]) {
        // FIXME: move self to [[_movieView window] screen].
    }
    [super orderFront:sender];
    [[_movieView window] addChildWindow:self ordered:NSWindowAbove];
}

- (void)orderOut:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[_movieView window] removeChildWindow:self];
    [super orderOut:sender];
}

- (void)scrollWheel:(NSEvent*)event
{
    //TRACE(@"%s (%g,%g,%g)", __PRETTY_FUNCTION__,
    //      [event deltaX], [event deltaY], [event deltaZ]);
    [[NSApp mainWindow] scrollWheel:event];
}

@end

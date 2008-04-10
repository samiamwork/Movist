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
        [self initHUDWindow];
    }
    return self;
}

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setDelegate:self];
    [self updateHUDBackground];
    [self initHUDSubview:[self contentView]];
    _movingByDragging = FALSE;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_lastShowTime release];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return FALSE; }

- (void)setControlPanel:(NSWindow*)panel { _controlPanel = panel; }

- (void)setMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* title = (movieURL) ? [[movieURL path] lastPathComponent] : @"";
    [_titleTextField setStringValue:title];
    [self setTitle:title];
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)windowWillMove:(NSNotification*)aNotification { _movingByDragging = TRUE; }
- (void)windowDidMove:(NSNotification*)aNotification  { _movingByDragging = FALSE; }

#define PLAY_PANEL_FADE_DURATION     0.5

- (void)orderFrontWithFadeIn:(id)sender
{
    [self setAlphaValue:0.0];
    [self orderFront:sender];
    [self fadeWithEffect:NSViewAnimationFadeInEffect
            blockingMode:NSAnimationBlocking
                duration:PLAY_PANEL_FADE_DURATION];
}

- (void)orderOutWithFadeOut:(id)sender
{
    if ([self isVisible]) {
        [self fadeWithEffect:NSViewAnimationFadeOutEffect
                blockingMode:NSAnimationBlocking
                    duration:PLAY_PANEL_FADE_DURATION];
    }
    [self orderOut:sender];
}

- (void)showPanel
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_movieView movie] &&
        [[_movieView window] isKeyWindow] &&
        NSPointInRect([NSEvent mouseLocation], [[_movieView window] frame]) &&
        (![_controlPanel isVisible] ||
         !NSPointInRect([NSEvent mouseLocation], [_controlPanel frame]))) {
        [_lastShowTime release];
        _lastShowTime = [[NSDate date] retain];
        if (![self isVisible]) {
            [self orderFrontWithFadeIn:self];
        }
    }
}

- (void)autoHidePanel
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isVisible]) {
        if (!_movingByDragging &&
            [[_movieView window] isKeyWindow] &&
            [_lastShowTime timeIntervalSinceNow] < -1.0 &&
            !NSPointInRect([NSEvent mouseLocation], [self frame])) {
            [self orderOutWithFadeOut:self];
            if (![_controlPanel isVisible]) {
                [NSCursor setHiddenUntilMouseMoves:TRUE];
            }
            [_lastShowTime release];
            _lastShowTime = nil;
        }
    }
    else if (CGCursorIsVisible() &&
             ![_controlPanel isVisible] &&
             [[_movieView window] isKeyWindow]) {
        [NSCursor setHiddenUntilMouseMoves:TRUE];
    }
}

- (void)orderFront:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self screen] != [[_movieView window] screen]) {
        // move self to [[_movieView window] screen].
        NSRect fr = [self frame];
        NSRect sr = [[self screen] frame];
        float dx = fr.origin.x - sr.origin.x;
        float dy = NSMaxY(sr) - (fr.origin.y - sr.origin.y);
        sr = [[[_movieView window] screen] frame];
        fr.origin.x = sr.origin.x + dx;
        fr.origin.y = sr.origin.y + (NSMaxY(sr) - dy);
        [self setFrameOrigin:fr.origin];
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

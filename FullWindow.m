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

#import "FullWindow.h"

#import "AppController.h"   // for NSApp's delegate
#import "MMovieView.h"
#import "PlayPanel.h"
#import "FullNavView.h"

@interface FullView : NSView
{
}

@end

@implementation FullView

- (void)drawRect:(NSRect)rect
{
    [[NSColor blackColor] set];
    NSRectFill([self bounds]);

    /* for test
    NSImage* image = [NSImage imageNamed:@"FrontRow_TEST_BACKGROUND"];
    [image drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];

    [[NSColor whiteColor] set];
    NSRect b = [self bounds];
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(b.size.width / 2, 0)];
    [path lineToPoint:NSMakePoint(b.size.width / 2, b.size.height)];
    [path closePath];
    [path stroke];
     */
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FullWindow

- (id)initWithScreen:(NSScreen*)screen playPanel:(PlayPanel*)playPanel
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    unsigned int styleMask = NSBorderlessWindowMask;
#if defined(AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER)
    styleMask |= NSUnscaledWindowMask;
#endif
    NSRect rect = [screen frame];
    rect.origin.x = rect.origin.y = 0;
    if (self = [super initWithContentRect:rect
                                styleMask:styleMask
                                  backing:NSBackingStoreBuffered
                                    defer:FALSE
                                   screen:screen]) {
        [self useOptimizedDrawing:TRUE];
        [self setHasShadow:FALSE];
        [self setAutorecalculatesKeyViewLoop:TRUE];
        [self setContentView:[[[FullView alloc] initWithFrame:NSZeroRect] autorelease]];

        _playPanel = [playPanel retain];
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playPanel release];
    [_movieView release];
    [_navView release];

    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return TRUE; }

//- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame { return 5.0; }

- (void)mouseMoved:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isNavigating]) {
        [_playPanel showPanel];
    }
}

- (void)orderOut:(id)sender
{
    [_movieView setHidden:FALSE];
    [_navView setHidden:TRUE];
    [super orderOut:sender];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setMovieView:(MMovieView*)movieView
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _movieView = [movieView retain];
    [[self contentView] addSubview:_movieView];

    if ([[NSApp delegate] movie]) {
        // full-screen transition from window-mode
        [_movieView setFrame:[[self contentView] bounds]];
    }
    else {
        // enter into navigation mode
        NSRect rc = [[self contentView] bounds];
        rc.size.width /= 2;

        float IN_MARGIN  = (float)(int)(rc.size.width * 0.075);
        float OUT_MARGIN = (float)(int)(rc.size.width * 0.195);
        rc.origin.x += rc.size.width + IN_MARGIN;
        rc.size.width -= IN_MARGIN + OUT_MARGIN;
        _navView = [[FullNavView alloc] initWithFrame:rc movieView:_movieView];
        [[self contentView] addSubview:_navView];
        [self makeFirstResponder:_navView];

        [_movieView setFrame:[_navView previewRect]];
        [_movieView setHidden:TRUE];
    }
}

@end

@implementation FullWindow (Navigation)

- (BOOL)isNavigatable   { return (nil != _navView); }
- (BOOL)isNavigating    { return (_navView && ![_navView isHidden]); }
- (BOOL)isPreviewing    { return ([self isNavigating] && ![_movieView isHidden]); }

- (void)selectUpper     { [_navView selectUpper]; }
- (void)selectLower     { [_navView selectLower]; }
- (void)selectMovie:(NSURL*)movieURL { [_navView selectMovie:movieURL]; }

- (void)openCurrent     { [_navView openCurrent]; }
- (BOOL)closeCurrent    { return (_navView) ? [_navView closeCurrent] : FALSE; }
- (BOOL)canCloseCurrent { return (_navView) ? [_navView canCloseCurrent] : FALSE; }

@end

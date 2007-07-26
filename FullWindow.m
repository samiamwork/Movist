//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "FullWindow.h"

#import "AppController.h"   // for NSApp's delegate
#import "FullScreener.h"
#if defined(_SUPPORT_FRONT_ROW)
#import "FullNavView.h"
#endif
#import "MMovieView.h"
#import "PlayPanel.h"

@implementation FullWindow

- (id)initWithFullScreener:(FullScreener*)fullScreener
                    screen:(NSScreen*)screen playPanel:(PlayPanel*)playPanel
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

        _fullScreener = [fullScreener retain];
        _playPanel = [playPanel retain];

        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeKey:)
                   name:NSWindowDidBecomeKeyNotification object:self];
        [nc addObserver:self selector:@selector(windowDidResignKey:)
                   name:NSWindowDidResignKeyNotification object:self];
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_fullScreener release];
    [_playPanel release];
    [_movieView release];
#if defined(_SUPPORT_FRONT_ROW)
    [_navView release];
#endif
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return TRUE; }

- (void)windowDidBecomeKey:(NSNotification*)aNotification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp delegate] updatePureArrowKeyEquivalents];
}

- (void)windowDidResignKey:(NSNotification*)aNotification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp delegate] updatePureArrowKeyEquivalents];
}

//- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame { return 5.0; }

- (void)mouseMoved:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
#if defined(_SUPPORT_FRONT_ROW)
    if (![_fullScreener isNavigationMode]) {
#else
    {
#endif
        NSPoint p = [self convertBaseToScreen:[event locationInWindow]];
        [_playPanel updateByMouseInScreen:p];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setMovieView:(MMovieView*)movieView
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _movieView = [movieView retain];

#if defined(_SUPPORT_FRONT_ROW)
    if ([_fullScreener isNavigationMode]) {
        _navView = [[FullNavView alloc] initWithFrame:[self frame]
                                            movieView:_movieView];
        [[self contentView] addSubview:_navView];
    }
    else {
#else
    {
        [[self contentView] addSubview:_movieView];
        [_movieView setFrame:[[self contentView] bounds]];
    }
#endif
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#if defined(_SUPPORT_FRONT_ROW)
- (void)selectUpper { [_navView selectUpper]; }
- (void)selectLower { [_navView selectLower]; }

- (void)openSelectedItem
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NavItem* item = [_navView selectedItem];
    if ([item type] == NAV_ITEM_MOVIE) {
        // open movie
    }
    else {
        [_navView openSelectedItem];
    }
}

- (void)closeCurrent
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_fullScreener isNavigationMode]) {
        [_navView closeCurrent];
    }
    else {
        // close movie
    }
}
#endif

@end

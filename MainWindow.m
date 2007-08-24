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

#import "MainWindow.h"

#import "MMovie_QuickTime.h"
#import "MMovie_FFMPEG.h"
#import "AppController.h"       // for NSApp's delegate

#import "MMovieView.h"
#import "PlayPanel.h"

//#import <ApplicationServices/ApplicationServices.h>

@implementation MainWindow

- (void)awakeFromNib
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSView* cv = [self contentView];
    NSRect cr = [cv bounds];
    NSRect mr = [_movieView frame];
    _movieViewMarginPoint.x = mr.origin.x;
    _movieViewMarginPoint.y = mr.origin.y;
    _movieViewMarginSize.width = _movieViewMarginPoint.x + NSMaxX(cr) - NSMaxX(mr);
    _movieViewMarginSize.height= _movieViewMarginPoint.y + NSMaxY(cr) - NSMaxY(mr);

    _alwaysOnTop = FALSE;

    [self setDelegate:self];    // for windowDidResize:
    [self useOptimizedDrawing:TRUE];
    [self setMovableByWindowBackground:TRUE];
    [self setAcceptsMouseMovedEvents:TRUE];
    [self setAutorecalculatesKeyViewLoop:TRUE];

    // move to screen-center with default size
    cr.size = [cv convertSize:cr.size toView:nil];
    mr.size = [cv convertSize:mr.size toView:nil];
    float titleBarHeight = [self frame].size.height - cr.size.height;
    float footerHeight = cr.size.height - mr.size.height;
    mr.size = [cv convertSize:NSMakeSize(640, 640 / 2.35) toView:nil]; // 2.35 : 1
    NSRect sr = [[self screen] frame];
    NSRect frame;
    frame.size.width = mr.size.width;
    frame.size.height = titleBarHeight + mr.size.height + footerHeight;
    frame.origin.x = sr.origin.x + (sr.size.width - frame.size.width) / 2;
    frame.origin.y = sr.origin.y + (sr.size.height- frame.size.height) * 2 / 3;
    [self setFrame:frame display:TRUE];

    // create image view for decoder
    NSButton* closeButton = [self standardWindowButton:NSWindowCloseButton];
    NSRect rc = [closeButton frame];
    rc.size.width = 16;
    rc.size.height = 16;
    rc.origin.x = NSMaxX([[closeButton superview] bounds]) - rc.origin.x - rc.size.width;
    rc.origin.y++;
    _decoderImageView = [[NSImageView alloc] initWithFrame:rc];
    [_decoderImageView setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [_decoderImageView setImageFrameStyle:NSImageFrameNone];
    [_decoderImageView setImageAlignment:NSImageAlignCenter];
    [_decoderImageView setImageScaling:NSScaleNone];
    [_decoderImageView setImage:nil];
    [[closeButton superview] addSubview:_decoderImageView];
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_decoderImageView release];
    [super dealloc];
}

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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (MMovieView*)movieView { return _movieView; }

- (void)setDecoder:(NSString*)decoder
{
    if (!decoder) {
        [_decoderImageView setImage:nil];
    }
    else if ([decoder isEqualToString:[MMovie_QuickTime name]]) {
        [_decoderImageView setImage:[NSImage imageNamed:@"QuickTime16"]];
    }
    else {  // [decoder isEqualToString:[MMovie_FFMPEG name]]
        [_decoderImageView setImage:[NSImage imageNamed:@"FFMPEG16"]];
    }
}

- (BOOL)alwaysOnTop { return _alwaysOnTop; }

- (void)setAlwaysOnTop:(BOOL)alwaysOnTop
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, alwaysOnTop);
    _alwaysOnTop = alwaysOnTop;
    [self setLevel:(_alwaysOnTop) ? kCGDraggingWindowLevel : NSNormalWindowLevel];
/*
    CGSWindow wid = [self windowNumber];
    CGSConnection cid = _CGSDefaultConnection();
    int tags[2] = { 0, 0 };
    OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
    if(!retVal) {
        if (_alwaysOnTop) {
            tags[0] = tags[0] | 0x00000800;
        }
        else {
            tags[0] = tags[0] & ~0x00000800;
        }
        retVal = CGSSetWindowTags(cid, wid, tags, 32);
    }
 */
}

- (void)orderFrontRegardless
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_alwaysOnTop) {
        [super orderFrontRegardless];
    }
}

- (void)setLevel:(int)newLevel
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, newLevel);
    [super setLevel:MIN(kCGDraggingWindowLevel, newLevel)];
}

- (void)makeKeyAndOrderFront:(id)sender
{
    [super makeKeyAndOrderFront:sender];

    if (_alwaysOnTop) {
        [self setLevel:kCGDraggingWindowLevel];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp delegate] closeMovie];
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume by scroll-wheel

- (void)scrollWheel:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([event deltaY] < 0.0) {
        [[NSApp delegate] volumeDown];
    }
    else if (0.0 < [event deltaY]) {
        [[NSApp delegate] volumeUp];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark resize

- (NSRect)windowWillUseStandardFrame:(NSWindow*)sender defaultFrame:(NSRect)defaultFrame
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(defaultFrame));
    return [self frameRectForScreen];
}

- (void)zoom:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_movieView movie]) {
        if ([self isZoomed]) {
            [self setFrame:_zoomRestoreRect display:TRUE animate:TRUE];
        }
        else {
            _zoomRestoreRect = [self frame];
            [self setFrame:[self frameRectForScreen] display:TRUE animate:TRUE];
        }
    }
}

- (NSSize)frameSizeForMovieSize:(NSSize)movieSize
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromSize(movieSize));
    NSRect cr;
    cr.origin.x = 0;
    cr.origin.y = 0;
    cr.size.width = movieSize.width + _movieViewMarginSize.width;
    cr.size.height= movieSize.height+ _movieViewMarginSize.height;
    NSSize size = [self frameRectForContentRect:cr].size;
    
    // if too big, then shrink to screen size
    NSSize ss = [[self screen] visibleFrame].size;
    if (ss.width < size.width) {
        size.height = ss.width * size.height / size.width;
        size.width = ss.width;
    }
    if (ss.height < size.height) {
        size.width = ss.height * size.width / size.height;
        size.height = ss.height;
    }
    // if too small, then expand to minimum size
    NSSize minSize = [self minSize];
    if (size.width < minSize.width) {
        size.width = minSize.width;
    }
    if (size.height < minSize.height) {
        size.height = minSize.height;
    }
    return size;
}

- (NSRect)frameRectForMovieSize:(NSSize)movieSize align:(int)align
{
    //TRACE(@"%s %@ (%d)", __PRETTY_FUNCTION__, NSStringFromSize(movieSize), align);
    NSRect sr = [[self screen] visibleFrame];
    NSSize frameSize = [self frameSizeForMovieSize:movieSize];
    NSRect frame;
    if (align == ALIGN_WINDOW_TITLE) {
        frame = [self frame];
        frame.origin.x -= (frameSize.width - frame.size.width) / 2;
        frame.origin.y -= frameSize.height - frame.size.height;
    }
    else if (align == ALIGN_SCREEN_CENTER) {
        frame.origin.x = sr.origin.x + (sr.size.width - frameSize.width) / 2;
        frame.origin.y = sr.origin.y + (sr.size.height- frameSize.height)/ 2;
    }
    frame.size = frameSize;
    
    if (NSMinX(frame) < NSMinX(sr)) {
        frame.origin.x += NSMinX(sr) - NSMinX(frame);
    }
    else if (NSMaxX(sr) < NSMaxX(frame)) {
        frame.origin.x -= NSMaxX(frame) - NSMaxX(sr);
    }
    if (NSMinY(frame) < NSMinY(sr)) {
        frame.origin.y += NSMinY(sr) - NSMinY(frame);
    }
    return frame;
}

- (NSRect)frameRectForMovieRect:(NSRect)movieRect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(movieRect));
    // movieRect is screen coord.
    movieRect = [[self contentView] convertRect:movieRect fromView:nil];

    NSRect cr;
    cr.origin.x = movieRect.origin.x - _movieViewMarginPoint.x;
    cr.origin.y = movieRect.origin.y - _movieViewMarginPoint.y;
    cr.size.width = movieRect.size.width + _movieViewMarginSize.width;
    cr.size.height= movieRect.size.height+ _movieViewMarginSize.height;
    return [self frameRectForContentRect:cr];
}

- (NSRect)frameRectForScreen
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSSize movieSize = [[_movieView movie] adjustedSize];
    NSSize size = [self frameSizeForMovieSize:movieSize];
    NSSize screenSize = [[self screen] visibleFrame].size;
    if (screenSize.width / screenSize.height < size.width / size.height) {
        // window is wider than screen => fit to window width
        NSRect rect;
        rect.size.width = screenSize.width;
        size.width = [self contentRectForFrameRect:rect].size.width;
        size.width -= _movieViewMarginSize.width;
        size.height = size.width * movieSize.height / movieSize.width;
    }
    else {
        // screen is wider than window => fit to window height
        NSRect rect;
        rect.size.height = screenSize.height;
        size.height = [self contentRectForFrameRect:rect].size.height;
        size.height -= _movieViewMarginSize.height;
        size.width = size.height * movieSize.width / movieSize.height;
    }
    return [self frameRectForMovieSize:size align:ALIGN_SCREEN_CENTER];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MainWindow (NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [menuItem title]);
    if ([menuItem action] == @selector(performClose:)) {
        return [self isVisible];
    }
    return TRUE;
}

@end

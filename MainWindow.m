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

#import "MainWindow.h"

#import "MMovie_QuickTime.h"
#import "MMovie_FFmpeg.h"
#import "AppController.h"       // for NSApp's delegate
#import "UserDefaults.h"

#import "MMovieView.h"
#import "PlayPanel.h"

@implementation MainWindow

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSView* cv = [self contentView];
    NSRect cr = [cv bounds];
    NSRect mr = [_movieView frame];
    _movieViewMarginPoint.x = mr.origin.x;
    _movieViewMarginPoint.y = mr.origin.y;
    _movieViewMarginSize.width = _movieViewMarginPoint.x + NSMaxX(cr) - NSMaxX(mr);
    _movieViewMarginSize.height= _movieViewMarginPoint.y + NSMaxY(cr) - NSMaxY(mr);

    _initialDragPoint.x = -1;
    _initialDragPoint.y = -1;

    _alwaysOnTop = FALSE;

    [self setDelegate:self];
    [self useOptimizedDrawing:TRUE];
    //[self setMovableByWindowBackground:TRUE];
    [self setAcceptsMouseMovedEvents:TRUE];
    [self setAutorecalculatesKeyViewLoop:TRUE];
    [self setMinSize:NSMakeSize(320, 100)];

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
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSButton*)createDecoderButton
{
    NSButton* closeButton = [self standardWindowButton:NSWindowCloseButton];
    NSView* superview = [closeButton superview];
    NSRect rc = [closeButton frame];
    rc.origin.x = NSMaxX([superview bounds]) - rc.origin.x - rc.size.width;
    NSButton* decoderButton = [[NSButton alloc] initWithFrame:rc];
    [decoderButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [decoderButton setBordered:FALSE];
    [decoderButton setTitle:@""];
    [decoderButton setTarget:[NSApp delegate]];
    [decoderButton setAction:@selector(reopenMovieAction:)];
    [decoderButton setToolTip:NSLocalizedString(@"Decoder", nil)];
    [superview addSubview:decoderButton];
    return decoderButton;
}

- (MMovieView*)movieView { return _movieView; }

- (BOOL)alwaysOnTop { return _alwaysOnTop; }

#define TopMostWindowLevel  kCGUtilityWindowLevel

- (void)setAlwaysOnTop:(BOOL)alwaysOnTop
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, alwaysOnTop);
    _alwaysOnTop = alwaysOnTop;

    // enhancement for Expose & Spaces
    // based on patch of Chan-gu Lee <maidaro@gmail.com>.
    if (_alwaysOnTop) {
        [self setLevel:TopMostWindowLevel];
    }
    else {
        [self setLevel:NSNormalWindowLevel];
    }

    HIWindowRef windowRef = (HIWindowRef)[self windowRef];
    HIWindowAvailability windowAvailability = 0;
    HIWindowGetAvailability(windowRef, &windowAvailability);
    if (!(windowAvailability & kHIWindowExposeHidden)) {
        HIWindowChangeAvailability(windowRef, kHIWindowExposeHidden, 0);
    }
    HIWindowChangeAvailability(windowRef, 0, kHIWindowExposeHidden);

    if (isSystemLeopard()) {
        const int kHIWindowVisibleInAllSpaces = 1 << 8;
        if (_alwaysOnTop) {
            HIWindowChangeAvailability(windowRef, kHIWindowVisibleInAllSpaces, 0);
        }
        else {
            HIWindowChangeAvailability(windowRef, 0, kHIWindowVisibleInAllSpaces);
        }
        [self orderFront:self];
    }
}

- (void)orderFrontRegardless
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_alwaysOnTop) {
        [super orderFrontRegardless];
    }
}

- (void)setLevel:(int)newLevel
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, newLevel);
    [super setLevel:MIN(TopMostWindowLevel, newLevel)];
}

- (void)makeKeyAndOrderFront:(id)sender
{
    [super makeKeyAndOrderFront:sender];

    [self setAlwaysOnTop:_alwaysOnTop];
}

- (BOOL)windowShouldClose:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp delegate] closeMovie];
    return TRUE;
}

- (void)performClose:(id)sender
{
    if ([NSApp keyWindow] == self) {
        [super performClose:sender];
    }
    else {
        [[NSApp keyWindow] performClose:sender];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark window-moving by dragging

- (void)mouseDown:(NSEvent*)event
{
    NSRect frame = [self frame];
    _initialDragPoint = [self convertBaseToScreen:[event locationInWindow]];
    _initialDragPoint.x -= frame.origin.x;
    _initialDragPoint.y -= frame.origin.y;
}

- (void)mouseUp:(NSEvent*)event
{
    _initialDragPoint.x = -1;
    _initialDragPoint.y = -1;
}

- (void)mouseDragged:(NSEvent*)event
{
    if (0 <= _initialDragPoint.x && 0 <= _initialDragPoint.y) {
        NSPoint p = [self convertBaseToScreen:[event locationInWindow]];
        NSRect sr = [[self screen] frame];
        NSRect wr = [self frame];

        NSPoint origin;
        origin.x = p.x - _initialDragPoint.x;
        origin.y = p.y - _initialDragPoint.y;
        if (NSMaxY(sr) < origin.y + wr.size.height) {
            origin.y = sr.origin.y + (sr.size.height - wr.size.height);
        }
        [self setFrameOrigin:origin];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark cursor position

- (void)mouseMoved:(NSEvent*)event
{
    [_seekSlider mouseMoved:[event locationInWindow]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume by scroll-wheel

- (void)scrollWheel:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([[NSApp delegate] isFullNavigating]) {
        return;     // volume-change-by-wheel doesn't work in preview of full-navigation.
    }

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

//- (void)windowDidResize:(NSNotification*)aNotification {}

- (NSRect)windowWillUseStandardFrame:(NSWindow*)sender defaultFrame:(NSRect)defaultFrame
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(defaultFrame));
    return [self frameRectForScreen];
}

- (void)zoom:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_movieView movie]) {
        [_movieView setSubtitleVisible:FALSE];
        if ([self isZoomed]) {
            [self setFrame:_zoomRestoreRect display:TRUE animate:TRUE];
        }
        else {
            _zoomRestoreRect = [self frame];
            [self setFrame:[self frameRectForScreen] display:TRUE animate:TRUE];
        }
        [_movieView setSubtitleVisible:TRUE];
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
    if (align == ALIGN_WINDOW_TITLE_CENTER) {
        frame = [self frame];
        frame.origin.x -= (frameSize.width - frame.size.width) / 2;
        frame.origin.y -= frameSize.height - frame.size.height;
    }
    else if (align == ALIGN_WINDOW_BOTTOM_CENTER) {
        frame = [self frame];
        frame.origin.x -= (frameSize.width - frame.size.width) / 2;
    }
    else if (align == ALIGN_WINDOW_BOTTOM_RIGHT) {
        frame = [self frame];
        frame.origin.x -= frameSize.width - frame.size.width;
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
    NSSize movieSize = [[_movieView movie] adjustedSizeByAspectRatio];
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

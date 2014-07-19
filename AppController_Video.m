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

#import "AppController.h"
#import "UserDefaults.h"

#import "MMovie.h"

#import "MMovieView.h"
#import "MainWindow.h"
#import "FullScreener.h"

@implementation AppController (Video)

- (void)setVideoTrackAtIndex:(unsigned int)index enabled:(BOOL)enabled
{
    MTrack* track = (MTrack*)[[_movie videoTracks] objectAtIndex:index];
    [track setEnabled:enabled];

    if (enabled) {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"%@ enabled", nil), [track name]]];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"%@ disabled", nil), [track name]]];
    }
    //[self updateVideoTrackMenuItems];
}

- (void)resizeWithMagnification:(float)magnification
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, magnification);
    if (!_movie) {
        return;
    }

    NSSize size = [_movie adjustedSizeByAspectRatio];
    if (magnification != 1.0) {
        size.width  *= magnification;
        size.height *= magnification;
    }
    BOOL subtitleVisible = [_movieView subtitleVisible];
    [_seekSlider hideMouseTimeToolTip];
    [_movieView setSubtitleVisible:FALSE];

    if ([self isFullScreen]) {
        [_movieView setFullScreenMovieSize:size];
    }
    else {
        int align = ALIGN_WINDOW_TITLE_CENTER;
        switch ([_defaults integerForKey:MMovieResizeCenterKey]) {
            case MOVIE_RESIZE_CENTER_TM : align = ALIGN_WINDOW_TITLE_CENTER;  break;
            case MOVIE_RESIZE_CENTER_TL : align = ALIGN_WINDOW_TITLE_LEFT;    break;
            case MOVIE_RESIZE_CENTER_TR : align = ALIGN_WINDOW_TITLE_RIGHT;   break;
            case MOVIE_RESIZE_CENTER_BM : align = ALIGN_WINDOW_BOTTOM_CENTER; break;
            case MOVIE_RESIZE_CENTER_BL : align = ALIGN_WINDOW_BOTTOM_LEFT;   break;
            case MOVIE_RESIZE_CENTER_BR : align = ALIGN_WINDOW_BOTTOM_RIGHT;  break;
        }
        NSRect frame = [_mainWindow frameRectForMovieSize:size align:align];
        if ([[_mainWindow screen] visibleFrame].size.height < frame.size.height) {
            frame = [_mainWindow frameRectForScreen];
        }
        [_mainWindow setFrame:frame display:TRUE animate:TRUE];
    }

    [_movieView setSubtitleVisible:subtitleVisible];
}

- (void)resizeToScreen
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isFullScreen]) {
        [_movieView setFullScreenMovieSize:NSZeroSize];
    }
    else {
        NSRect frame = [_mainWindow frameRectForScreen];

        BOOL subtitleVisible = [_movieView subtitleVisible];
        [_seekSlider hideMouseTimeToolTip];
        [_movieView setSubtitleVisible:FALSE];
        [_mainWindow setFrame:frame display:TRUE animate:TRUE];
        [_movieView setSubtitleVisible:subtitleVisible];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-screen

- (BOOL)isFullScreen { return _fullScreener && [_fullScreener isFullScreen]; }

- (void)beginFullScreen
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if (_movie && ![self isFullScreen]) {
        NSEvent* event = [NSApp currentEvent];
        unsigned int flags = [event modifierFlags];
        if (!(flags & NSCommandKeyMask)) {
            if (flags & NSControlKeyMask) {
                [self setFullScreenFill:FS_FILL_STRETCH];
            }
            else if (flags & NSAlternateKeyMask) {
                [self setFullScreenFill:FS_FILL_CROP];
            }
            else if (flags & NSShiftKeyMask) {
                [self setFullScreenFill:FS_FILL_NEVER];
            }
        }

        if (_alwaysOnTopEnabled) {
            [self updateAlwaysOnTop:FALSE];
        }
        if (!_fullScreener) {
            _fullScreener = [FullScreener alloc];
            [_fullScreener initWithMainWindow:_mainWindow playPanel:_playPanel];
            [_fullScreener setMovieURL:[self movieURL]];
            [_fullScreener setAutoShowDock:[_defaults boolForKey:MAutoShowDockKey]];
        }
        [_seekSlider hideMouseTimeToolTip];
        [_fullScreener beginFullScreen];
    }
    [_fullScreenLock unlock];
}

- (void)endFullScreen
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if ([self isFullScreen]) {
        [_fullScreener endFullScreen];
        if (![self isDesktopBackground]) {
            [_fullScreener release];
            _fullScreener = nil;
        }
        [_movieView updateMovieRect:TRUE];
        if (_alwaysOnTopEnabled) {
            [self updateAlwaysOnTop:TRUE];
        }
    }
    [_fullScreenLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark desktop-background

- (BOOL)isDesktopBackground { return _fullScreener && [_fullScreener isDesktopBackground]; }

- (void)beginDesktopBackground
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if (_movie && ![self isDesktopBackground]) {
        if (_alwaysOnTopEnabled) {
            [self updateAlwaysOnTop:FALSE];
        }
        if (!_fullScreener) {
            _fullScreener = [FullScreener alloc];
            [_fullScreener initWithMainWindow:_mainWindow playPanel:_playPanel];
            [_fullScreener setMovieURL:[self movieURL]];
        }
        [_seekSlider hideMouseTimeToolTip];
        [_fullScreener beginDesktopBackground];
    }
    [_fullScreenLock unlock];
}

- (void)endDesktopBackground
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if ([self isDesktopBackground]) {
        [_fullScreener endDesktopBackground];
        [_fullScreener release];
        _fullScreener = nil;
        [_movieView updateMovieRect:TRUE];
        if (_alwaysOnTopEnabled) {
            [self updateAlwaysOnTop:TRUE];
        }
    }
    [_fullScreenLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-navigation

- (BOOL)isFullNavigation { return _fullScreener && [_fullScreener isNavigation]; }

- (void)beginFullNavigation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_defaults boolForKey:MFullNavUseKey]) {
        return;
    }

    [_fullScreenLock lock];
    if (_alwaysOnTopEnabled) {
        [self updateAlwaysOnTop:FALSE];
    }
    [_controlPanel orderOut:self];
    if ([self isFullScreen]) {
        // enter from full-screen-mode with playing movie
        [_fullScreener setMovieURL:nil];
    }
    else if ([self isDesktopBackground]) {
        // enter from desktop-background with playing movie
        [_fullScreener setMovieURL:nil];
        [_fullScreener beginNavigation];
    }
    else {
        // enter from window-mode with no-movie
        _fullScreener = [FullScreener alloc];
        [_fullScreener initWithMainWindow:_mainWindow playPanel:_playPanel];
        [_fullScreener setMovieURL:nil];
        [_seekSlider hideMouseTimeToolTip];
        [_fullScreener beginNavigation];
    }
    [_fullScreenLock unlock];
}

- (void)endFullNavigation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if ([self isFullNavigation]) {
        [_movieView showLogo];
        [_fullScreener endNavigation];
        [_fullScreener release];
        _fullScreener = nil;
        [_movieView updateMovieRect:TRUE];
        if (_alwaysOnTopEnabled) {
            [self updateAlwaysOnTop:TRUE];
        }
    }
    [_fullScreenLock unlock];
}

- (void)setFullScreenFill:(int)fill forWideMovie:(BOOL)forWideMovie
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        NSSize ss = [[_mainWindow screen] frame].size;
        NSSize ms = [_movie adjustedSizeByAspectRatio];
        if (ss.width / ss.height < ms.width / ms.height) {
            if (forWideMovie) {
                [self setFullScreenFill:fill];
            }
        }
        else {
            if (!forWideMovie) {
                [self setFullScreenFill:fill];
            }
        }
    }
}

- (void)setFullScreenFill:(int)fill
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_movieView setFullScreenFill:fill];
    [_movieView updateMovieRect:TRUE];

    NSMenuItem* item;
    unsigned int i, count = [_fullScreenFillMenu numberOfItems];
    for (i = 0; i < count; i++) {
        item = [_fullScreenFillMenu itemAtIndex:i];
        if ([item tag] == fill) {
            break;
        }
    }
    [_movieView setMessage:[NSString stringWithFormat:
        @"%@: %@", [_fullScreenFillMenu title], [item title]]];
    [self updateFullScreenFillMenu];
}

- (void)setFullScreenUnderScan:(float)underScan
{
    //TRACE(@"%s %f", __PRETTY_FUNCTION__, underScan);
    [_movieView setFullScreenUnderScan:underScan];
    [_movieView updateMovieRect:TRUE];

    unsigned int count = [_fullScreenFillMenu numberOfItems];
    NSMenuItem* item = [_fullScreenFillMenu itemAtIndex:count - 1];
    [item setState:(underScan != 0)];
    if (underScan == 0) {
        [_movieView setMessage:[NSString stringWithFormat:
            @"%@ %@", [item title], NSLocalizedString(@"Never", nil)]];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            @"%@ %.1f %%", [item title], underScan]];
    }
}

- (void)updateFullScreenFillMenu
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMenuItem* item;
    unsigned int i, count = [_fullScreenFillMenu numberOfItems];
    for (i = 0; i < count; i++) {
        item = [_fullScreenFillMenu itemAtIndex:i];
        if ([item tag] <= FS_FILL_CROP) {
            [item setState:(_movie && [item tag] == [_movieView fullScreenFill])];
        }
        else {  // under scan
            [item setState:(0 < [_movieView fullScreenUnderScan])];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark aspect-ratio

- (int)aspectRatio { return (_movie) ? [_movie aspectRatio] : ASPECT_RATIO_DAR; }

- (void)setAspectRatio:(int)aspectRatio
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        NSMenuItem* item;
        unsigned int i, count = [_aspectRatioMenu numberOfItems];
        for (i = 0; i < count; i++) {
            item = [_aspectRatioMenu itemAtIndex:i];
            if ([item tag] == aspectRatio) {
                [_movieView setMessage:[item title]];
                break;
            }
        }
        [_movie setAspectRatio:aspectRatio];
        [_movieView setMessage:[NSString stringWithFormat:
                            @"%@: %@", [_aspectRatioMenu title], [item title]]];
        if (![self isFullScreen] && ![self isDesktopBackground]) {
            [self resizeWithMagnification:1.0];
        }
        [_movieView updateOSDImageBaseWidth];
        [_movieView updateLetterBoxHeight];
        [_movieView updateMovieRect:TRUE];
        [self updateAspectRatioMenu];
        [self updateLetterBoxHeightMenuItems];
    }
}

- (void)updateAspectRatioMenu
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMenuItem* item;
    unsigned int i, count = [_aspectRatioMenu numberOfItems];
    for (i = 0; i < count; i++) {
        item = [_aspectRatioMenu itemAtIndex:i];
        [item setState:(_movie) ? ([item tag] == [_movie aspectRatio]) : NSOffState];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)movieSizeAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    switch ([sender tag]) {
        case 0 : [self resizeWithMagnification:0.5];    break;
        case 1 : [self resizeWithMagnification:1.0];    break;
        case 2 : [self resizeWithMagnification:2.0];    break;
        case 3 : [self resizeToScreen];                 break;
    }
}

- (IBAction)fullScreenAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_movie) {
        if (!_fullScreener) {
            [self beginFullNavigation];
        }
        else {
            if (![_fullScreener closeCurrent]) {
                [self endFullNavigation];
            }
        }
    }
    else if ([self isFullNavigation]) {
        if (![_fullScreener closeCurrent]) {
            [self endFullNavigation];
        }
    }
    else if ([self isFullScreen]) {
        [self endFullScreen];
    }
    else {
        [self beginFullScreen];
        if ([_defaults boolForKey:MAutoPlayOnFullScreenKey]) {
            [_movie setRate:_playRate];  // auto play
        }
    }
}

- (IBAction)desktopBackgroundAction:(id)sender
{
    if ([self isDesktopBackground]) {
        [self endDesktopBackground];
    }
    else if (_movie && ![self isFullNavigation]) {
        [self beginDesktopBackground];
    }
}

- (IBAction)fullNavigationAction:(id)sender
{
    if ([self isFullNavigation]) {
        [self endFullNavigation];
    }
    else {
        if (_movie) {
            if ([self isFullScreen]) {
                [self endFullScreen];
            }
            [self closeMovie];
        }
        [self beginFullNavigation];
    }
}

- (IBAction)fullScreenFillAction:(id)sender
{
    if ([sender tag] < 0) {
        int fill = [_movieView fullScreenFill];
        switch (fill) {
            case FS_FILL_NEVER   : fill = FS_FILL_STRETCH;  break;
            case FS_FILL_STRETCH : fill = FS_FILL_CROP;     break;
            case FS_FILL_CROP    : fill = FS_FILL_NEVER;    break;
            default              : fill = FS_FILL_NEVER;    break;
        }
        [self setFullScreenFill:fill];
    }
    else {
        [self setFullScreenFill:[sender tag]];
    }
}

- (IBAction)fullScreenUnderScanAction:(id)sender
{
    BOOL underScan = ![sender state];
    [self setFullScreenUnderScan:
        ((underScan) ? [_defaults floatForKey:MFullScreenUnderScanKey] : 0)];
}

- (IBAction)aspectRatioAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setAspectRatio:[sender tag]];
}

- (IBAction)saveCurrentImage:(id)sender
{
    [_movieView saveCurrentImage:[sender tag] != 0];
}

- (IBAction)revealInFinder:(id)sender
{
    [_movie revealInFinder];
}

- (IBAction)moveToTrash:(id)sender
{
    NSLog(@"Moving to Trash...");
}

@end

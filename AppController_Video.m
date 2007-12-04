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

#import "AppController.h"
#import "UserDefaults.h"

#import "MMovie.h"

#import "MMovieView.h"
#import "MainWindow.h"
#import "FullScreener.h"

@implementation AppController (Video)

- (void)resizeWithMagnification:(float)magnification
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, magnification);
    if (_movie && ![self isFullScreen]) {
        NSSize size = [_movie adjustedSize];
        if (magnification != 1.0) {
            size.width  *= magnification;
            size.height *= magnification;
        }
        NSRect frame = [_mainWindow frameRectForMovieSize:size
                                                    align:ALIGN_WINDOW_TITLE];
        [_mainWindow setFrame:frame display:TRUE animate:TRUE];
#if defined(_USE_SUBTITLE_RENDERER)
        [_movieView updateSubtitle];
#endif
    }
}

- (void)resizeToScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {
        NSRect frame = [_mainWindow frameRectForScreen];
        [_mainWindow setFrame:frame display:TRUE animate:TRUE];
#if defined(_USE_SUBTITLE_RENDERER)
        [_movieView updateSubtitle];
#endif
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-screen

- (BOOL)isFullScreen { return (_fullScreener != nil); }

- (void)beginFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if (_movie && ![self isFullScreen]) {
        NSEvent* event = [NSApp currentEvent];
        if ([event type] == NSKeyDown &&
            !([event modifierFlags] & NSCommandKeyMask)) {
            if ([event modifierFlags] & NSControlKeyMask) {
                [self setFullScreenFill:FS_FILL_STRETCH];
            }
            else if ([event modifierFlags] & NSAlternateKeyMask) {
                [self setFullScreenFill:FS_FILL_CROP];
            }
        }

        int effect = [_defaults integerForKey:MFullScreenEffectKey];
        #if defined(AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER)
        if ([_mainWindow userSpaceScaleFactor] != 1.0 &&
            effect == FS_EFFECT_ANIMATION) {
            effect = FS_EFFECT_NONE;
        }
        #endif
        _fullScreener = [FullScreener alloc];
        [_fullScreener initWithMainWindow:_mainWindow playPanel:_playPanel];
        [_fullScreener setEffect:effect];
        [_fullScreener setMovieURL:[self movieURL]];
        [_fullScreener beginFullScreen];
    }
    [_fullScreenLock unlock];
}

- (void)endFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if ([self isFullScreen]) {
        [_fullScreener endFullScreen];
        [_fullScreener release];
        _fullScreener = nil;
        [_movieView updateMovieRect:TRUE];
    }
    [_fullScreenLock unlock];
}

- (void)beginFullNavigation
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if ([self isFullScreen]) {
        // enter from full-screen-mode with playing movie
        [_fullScreener setMovieURL:nil];
    }
    else {
        // enter from window-mode with no-movie
        _fullScreener = [FullScreener alloc];
        [_fullScreener initWithMainWindow:_mainWindow playPanel:_playPanel];
        [_fullScreener setMovieURL:nil];
        [_fullScreener beginFullScreen];
    }
    [_fullScreenLock unlock];
}

- (void)endFullNavigation
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if ([self isFullScreen]) {
        [_movieView showLogo];
        [_fullScreener endFullScreen];
        [_fullScreener release];
        _fullScreener = nil;
        [_movieView updateMovieRect:TRUE];
    }
    [_fullScreenLock unlock];
}

- (void)setFullScreenFill:(int)fill forWideMovie:(BOOL)forWideMovie
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        NSSize ss = [[_mainWindow screen] frame].size;
        NSSize ms = [_movie adjustedSize];
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
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_movieView setFullScreenFill:fill];
    [_movieView updateMovieRect:TRUE];

    NSString* s = (fill == 0) ? NSLocalizedString(@"Default", nil) :
                  (fill == 1) ? NSLocalizedString(@"Expand", nil) :
                                NSLocalizedString(@"Crop", nil);
    [_movieView setMessage:[NSString stringWithFormat:
        @"%@: %@", NSLocalizedString(@"Full Screen Filling", nil), s]];
}

- (void)setFullScreenUnderScan:(float)underScan
{
    TRACE(@"%s %f", __PRETTY_FUNCTION__, underScan);
    [_movieView setFullScreenUnderScan:underScan];
    [_movieView updateMovieRect:TRUE];

    [_underScanMenuItem setState:(underScan != 0)];
    if (underScan == 0) {
        [_movieView setMessage:[NSString stringWithFormat:
            @"%@ %@", [_underScanMenuItem title], NSLocalizedString(@"Never", nil)]];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            @"%@ %.1f %%", [_underScanMenuItem title], underScan]];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark aspect-ratio

- (int)aspectRatio { return (_movie) ? [_movie aspectRatio] : ASPECT_RATIO_DEFAULT; }

- (void)setAspectRatio:(int)aspectRatio
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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
        [_movieView updateMovieRect:TRUE];
        [_movieView setMessage:[NSString stringWithFormat:
                            @"%@: %@", [_aspectRatioMenu title], [item title]]];
        [self updateAspectRatioMenu];
    }
}

- (void)updateAspectRatioMenu
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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
    TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    switch ([sender tag]) {
        case 0 : [self resizeWithMagnification:0.5];    break;
        case 1 : [self resizeWithMagnification:1.0];    break;
        case 2 : [self resizeWithMagnification:2.0];    break;
        case 3 : [self resizeToScreen];                 break;
    }
}

- (IBAction)fullScreenAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {
        if (!_movie) {
            [self beginFullNavigation];
        }
        else {
            [self beginFullScreen];
        }
    }
    else {
        if ([_fullScreener isNavigatable]) {
            if (![_fullScreener closeCurrent]) {
                [self endFullNavigation];
            }
        }
        else {
            [self endFullScreen];
        }
    }
}

- (IBAction)fullScreenFillAction:(id)sender
{
    [self setFullScreenFill:([_movieView fullScreenFill] + 1) % 3];
}

- (IBAction)fullScreenUnderScanAction:(id)sender
{
    BOOL underScan = ![sender state];
    [self setFullScreenUnderScan:
        ((underScan) ? [_defaults floatForKey:MFullScreenUnderScanKey] : 0)];
}

- (IBAction)aspectRatioAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setAspectRatio:[sender tag]];
}

@end

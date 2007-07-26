//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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
    }
}

- (void)resizeToScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {
        NSRect frame = [_mainWindow frameRectForScreen];
        [_mainWindow setFrame:frame display:TRUE animate:TRUE];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-screen

- (BOOL)isFullScreen { return (_fullScreener != nil); }

- (void)beginFullNavigation
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if (![self isFullScreen]) {
        _fullScreener = [[FullScreener alloc] initWithMainWindow:_mainWindow
                                                       playPanel:_playPanel];
        [_fullScreener setEffect:FS_EFFECT_FADE];
        [_fullScreener setMovieURL:nil];    // navigation mode
        [_fullScreener beginFullScreen];
    }
    [_fullScreenLock unlock];
}

- (void)beginFullScreen
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenLock lock];
    if (_movie && ![self isFullScreen]) {
        NSEvent* event = [NSApp currentEvent];
        if ([event type] == NSKeyDown) {
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
        [_movieView hideBar];
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
    TRACE(@"%s %f", __PRETTY_FUNCTION__, underScan);
    [_movieView setFullScreenUnderScan:underScan];
    [_movieView updateMovieRect:TRUE];

    NSMenuItem* item;
    unsigned int i, count = [_fullScreenFillMenu numberOfItems];
    for (i = 0; i < count; i++) {
        item = [_fullScreenFillMenu itemAtIndex:i];
        if (FS_FILL_CROP < [item tag]) {
            break;
        }
    }
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
    TRACE(@"%s", __PRETTY_FUNCTION__);
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

#if defined(_SUPPORT_FRONT_ROW)
- (IBAction)fullNavigationAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isFullScreen]) {
        [self endFullScreen];
    }
    else if (!_movie) {
        [self beginFullNavigation];
    }
}
#endif

- (IBAction)fullScreenAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isFullScreen]) {
        [self endFullScreen];
    }
    else if (_movie) {
        [self beginFullScreen];
    }
#if defined(_SUPPORT_FRONT_ROW)
    else {
        [self beginFullNavigation];
    }
#endif
}

- (IBAction)fullScreenFillAction:(id)sender
{
    [self setFullScreenFill:[sender tag]];
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

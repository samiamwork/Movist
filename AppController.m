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
#import "UpdateChecker.h"
#import "UserDefaults.h"

#import "MMovie_FFmpeg.h"
#import "MMovie_QuickTime.h"
#import "Playlist.h"
#import "PlaylistController.h"
#import "PreferenceController.h"

#import "MMovieView.h"
#import "MainWindow.h"
#import "FullScreener.h"
#import "FullWindow.h"
#import "PlayPanel.h"
#import "CustomControls.h"
#import "ControlPanel.h"

@implementation AppController

NSString* videoCodecName(int codecId);

+ (void)initialize
{
    detectOperatingSystem();
    av_register_all();
    [[NSUserDefaults standardUserDefaults] registerMovistDefaults];
}

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _playlist = [[Playlist alloc] init];
        _audioTrackIndexSet = [[NSMutableIndexSet alloc] init];
        _subtitleNameSet = [[NSMutableSet alloc] init];
        _fullScreenLock = [[NSLock alloc] init];

        _defaults = [NSUserDefaults standardUserDefaults];
        [MMovie_QuickTime checkA52CodecAndPerianInstalled];
    }
    return self;
}

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self initDigitalAudioOut];
    [self initRemoteControl];

    // init UI
    [_mainWindow setReleasedWhenClosed:FALSE];
    [_mainWindow setExcludedFromWindowsMenu:TRUE];
    [_playPanel setControlPanel:_controlPanel];
    [self updatePlayUI];

    [_volumeSlider setMinValue:MIN_VOLUME];
    [_volumeSlider setMaxValue:MAX_VOLUME];
    [_volumeSlider replaceCell:[CustomSliderCell class]];
    CustomSliderCell* cell = [_volumeSlider cell];
    [cell setImageName:@"MainVolume" backColor:nil trackOffset:5.0 knobOffset:2.0];

    [_fsVolumeSlider setMinValue:MIN_VOLUME];
    [_fsVolumeSlider setMaxValue:MAX_VOLUME];
    [_fsVolumeSlider replaceCell:[CustomSliderCell class]];
    cell = [_fsVolumeSlider cell];
    [cell setImageName:@"FSVolume" backColor:HUDBackgroundColor trackOffset:0.0 knobOffset:2.0];

    _checkForAltVolumeChange = TRUE;
    _systemVolume = -1;
    [self updateVolumeUI];

    _playRate = DEFAULT_PLAY_RATE;
    _prevMovieTime = 0.0;
    _lastPlayedMovieURL = nil;
    _lastPlayedMovieTime = 0.0;
    _lastPlayedMovieRepeatRange.length = 0.0;
    _viewDuration = [_defaults boolForKey:MViewDurationKey];
    [_lTimeTextField setClickable:FALSE];   [_fsLTimeTextField setClickable:FALSE];
    [_rTimeTextField setClickable:TRUE];    [_fsRTimeTextField setClickable:TRUE];

    _decoderButton = [_mainWindow createDecoderButton];
    [self updateDecoderUI];
    [self updateDataSizeBpsUI];

    initSubtitleEncodingMenu(_subtitleEncodingMenu, @selector(reopenSubtitleAction:));

    // set modifier keys (I don't know how to set Shift key mask)
    unsigned int mask = NSAlternateKeyMask | NSShiftKeyMask;
    [_seekBackward3MenuItem setKeyEquivalentModifierMask:mask];
    [_seekForward3MenuItem setKeyEquivalentModifierMask:mask];

    mask = NSAlternateKeyMask | NSShiftKeyMask | NSControlKeyMask;
    [_seekPrevSubtitleMenuItem setKeyEquivalentModifierMask:mask];
    [_seekNextSubtitleMenuItem setKeyEquivalentModifierMask:mask];

    mask = NSCommandKeyMask | NSShiftKeyMask;
    [_rateSlowerMenuItem setKeyEquivalentModifierMask:mask];
    [_rateFasterMenuItem setKeyEquivalentModifierMask:mask];
    [_rateDefaultMenuItem setKeyEquivalentModifierMask:mask];

    mask = NSControlKeyMask | NSShiftKeyMask;
    [_syncLaterMenuItem setKeyEquivalentModifierMask:mask];
    [_syncEarlierMenuItem setKeyEquivalentModifierMask:mask];
    [_syncDefaultMenuItem setKeyEquivalentModifierMask:mask];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self cleanupRemoteControl];
    [self closeMovie];
    [_decoderButton release];
    [_fullScreenLock release];
    [_subtitleNameSet release];
    [_audioTrackIndexSet release];
    [_lastPlayedMovieURL release];
    [_playlist release];
    [_playlistController release];
    [_preferenceController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // hover-images should be set after -awakeFromNib.
    [_prevSeekButton setHoverImage:[NSImage imageNamed:@"MainPrevSeekHover"]];
    [_nextSeekButton setHoverImage:[NSImage imageNamed:@"MainNextSeekHover"]];
    [_controlPanelButton setHoverImage:[NSImage imageNamed:@"MainControlPanelHover"]];
    [_prevMovieButton setHoverImage:[NSImage imageNamed:@"MainPrevMovieHover"]];
    [_nextMovieButton setHoverImage:[NSImage imageNamed:@"MainNextMovieHover"]];
    [_playlistButton setHoverImage:[NSImage imageNamed:@"MainPlaylistHover"]];

    // initial update preferences: general
    [_mainWindow setAlwaysOnTop:[_defaults boolForKey:MAlwaysOnTopKey]];
    // don't set as-desktop-background. it will be set when movie is opened.
    [self setSeekInterval:[_defaults floatForKey:MSeekInterval0Key] atIndex:0];
    [self setSeekInterval:[_defaults floatForKey:MSeekInterval1Key] atIndex:1];
    [self setSeekInterval:[_defaults floatForKey:MSeekInterval2Key] atIndex:2];

    // initial update preferences: video
    [_movieView setFullScreenUnderScan:[_defaults floatForKey:MFullScreenUnderScanKey]];

    // initial update preferences: audio
    // ...

    // initial update preferences: subtitle
    // check if subtitle font exist. if not, then restore to default.
    NSString* fontName = [_defaults stringForKey:MSubtitleFontNameKey];
    NSFont* font = [NSFont fontWithName:fontName size:10.0];
    if (!font) {
        NSRunAlertPanel(NSLocalizedString(@"Subtitle Font Not Found", nil),
                        [NSString stringWithFormat:NSLocalizedString(
                         @"Subtitle font not found: \"%@\"\n"
                          "Subtitle font setting will be restored to default.", nil),
                         fontName],
                        NSLocalizedString(@"OK", nil), nil, nil);
        [_defaults setObject:[[NSFont boldSystemFontOfSize:1.0] fontName]
                      forKey:MSubtitleFontNameKey];
    }
    [_movieView setSubtitleFontName:[_defaults stringForKey:MSubtitleFontNameKey]
                               size:[_defaults floatForKey:MSubtitleFontSizeKey]];
    [_movieView setSubtitleTextColor:[_defaults colorForKey:MSubtitleTextColorKey]];
    [_movieView setSubtitleStrokeColor:[_defaults colorForKey:MSubtitleStrokeColorKey]];
    [_movieView setSubtitleStrokeWidth:[_defaults floatForKey:MSubtitleStrokeWidthKey]];
    [_movieView setSubtitleShadowColor:[_defaults colorForKey:MSubtitleShadowColorKey]];
    [_movieView setSubtitleShadowBlur:[_defaults floatForKey:MSubtitleShadowBlurKey]];
    [_movieView setSubtitleShadowOffset:[_defaults floatForKey:MSubtitleShadowOffsetKey]];
    [_movieView setSubtitleShadowDarkness:[_defaults integerForKey:MSubtitleShadowDarknessKey]];
    [_movieView setSubtitlePosition:[_defaults integerForKey:MSubtitlePositionKey]];
    [_movieView setSubtitleHMargin:[_defaults floatForKey:MSubtitleHMarginKey]];
    [_movieView setSubtitleVMargin:[_defaults floatForKey:MSubtitleVMarginKey]];
    [_movieView setSubtitleScreenMargin:[_defaults floatForKey:MSubtitleScreenMarginKey]];
    [_movieView setSubtitleLineSpacing:[_defaults floatForKey:MSubtitleLineSpacingKey]];

    // initial update preferences: advanced
    // ...

    // initial update preferences: advanced - details : general
    [_movieView setActivateOnDragging:[_defaults boolForKey:MActivateOnDraggingKey]];
    [_movieView setViewDragAction:[_defaults integerForKey:MViewDragActionKey]];

    // initial update preferences: advanced - details : video
    [_movieView setCaptureFormat:[_defaults integerForKey:MCaptureFormatKey]];
    [self setIncludeLetterBoxOnCapture:[_defaults boolForKey:MIncludeLetterBoxOnCaptureKey]];
    [_movieView setRemoveGreenBox:[_defaults boolForKey:MRemoveGreenBoxKey]];

    // initial update preferences: advanced - details : subtitle
    [_movieView setAutoSubtitlePositionMaxLines:[_defaults integerForKey:MAutoSubtitlePositionMaxLinesKey]];

    // initial update preferences: advanced - details : full-nav
    // ...

    [self updateUI];

    [self checkForUpdatesOnStartup];

    [self loadLastPlayedMovieInfo];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    if ([_defaults boolForKey:MFullNavUseKey] &&
        [_defaults boolForKey:MFullNavOnStartupKey]) {
        [self beginFullNavigation];
    }
    else if (!_movie && _lastPlayedMovieURL) {
        // open last played movie (but, no play)
        float rate = _playRate;
        _playRate = 0.0;    // no play
        [self openCurrentPlaylistItem];
        _playRate = rate;
    }
}

- (void)applicationWillBecomeActive:(NSNotification*)aNotification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_defaults boolForKey:MSupportAppleRemoteKey]) {
        [self startRemoteControl];
    }
}

- (void)applicationWillResignActive:(NSNotification*)aNotification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_defaults boolForKey:MSupportAppleRemoteKey]) {
        [self stopRemoteControl];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [_defaults boolForKey:MQuitWhenWindowCloseKey];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication*)theApplication
                    hasVisibleWindows:(BOOL)flag
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, flag);
    [_mainWindow makeKeyAndOrderFront:self];
    return FALSE;
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self closeMovie];
    [self saveLastPlayedMovieInfo];

    [_defaults synchronize];
}

- (void)checkProcessArguments
{
    /*
    NSArray* arguments = [[NSProcessInfo processInfo] arguments];

    NSArray* options = [NSArray arrayWithObjects:@"--decoder=", nil];
     "--fullNavMode"

    NSString* arg, *opt;
    NSEnumerator* optEnumerator;
    NSEnumerator* argEnumerator = [arguments objectEnumerator];
    while (arg = [enumerator nextObject]) {
        optEnumerator = [options objectEnumerator];
        while (opt = [optEnumerator nextObject]) {
            if (NSOrderedSame == [arg compare:opt options:0 range:NSMakeRange(0, [opt length])]) {
            }
        }
    }
    NSRunAlertPanel([NSApp localizedAppName], msg, NSLocalizedString(@"OK", nil), nil, nil);
     */
}

- (BOOL)application:(NSApplication*)theApplication openFile:(NSString*)filename
{
    //TRACE(@"%s:\"%@\"", __PRETTY_FUNCTION__, filename);
    [self checkProcessArguments];
    if ([self isFullNavigation] && [_fullScreener isNavigating]) {
        return FALSE;
    }
    return [self openFile:filename];
}

- (void)application:(NSApplication*)theApplication openFiles:(NSArray*)filenames
{
    //TRACE(@"%s:{%@}", __PRETTY_FUNCTION__, filenames);
    [self checkProcessArguments];
    if ([self isFullNavigation] && [_fullScreener isNavigating]) {
        return;
    }
    if ([self openFiles:filenames]) {
        [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
    }
    else {
        [NSApp replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
    }
}

- (void)windowWillClose:(NSNotification*)aNotification
{
    if ([aNotification object] != [_movieView window]) {
        [[_movieView window] makeKeyWindow];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (MMovie*)movie     { return _movie; }
- (NSURL*)movieURL    { return (_movie) ?     [[_playlist currentItem] movieURL] : nil; }

- (void)updateUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSURL* movieURL = [self movieURL];
    [_mainWindow setMovieURL:movieURL];
    [_fullScreener setMovieURL:movieURL];
    [_controlPanel setMovieURL:movieURL];
    [_propertiesView reloadData];
    [_seekSlider setDuration:(_movie) ? [_movie duration] : 0];
    [_fsSeekSlider setDuration:[_seekSlider duration]];
    [self updatePrevNextMovieButtons];
    [self updateAspectRatioMenu];
    [self updateFullScreenFillMenu];
    [self updateAudioTrackMenuItems];
    [self updateVolumeMenuItems];
    [self updateSubtitleLanguageMenuItems];
    [self updateSubtitlePositionMenuItems];
    [self updateRepeatUI];
    [self updateVolumeUI];
    [self updateTimeUI];
    [self updatePlayUI];
    [self updateDecoderUI];
    [self updateDataSizeBpsUI];
    [_playlistController updateUI];
}

- (void)setIncludeLetterBoxOnCapture:(BOOL)includeLetterBox
{
    [_movieView setIncludeLetterBoxOnCapture:includeLetterBox];

    [_altCopyImageMenuItem setTitle:(includeLetterBox) ?
                        NSLocalizedString(@"Copy (Excluding Letter Box)", nil) :
                        NSLocalizedString(@"Copy (Including Letter Box)", nil)];
    [_altSaveImageMenuItem setTitle:(includeLetterBox) ?
                        NSLocalizedString(@"Save Current Image (Excluding Letter Box)", nil) :
                        NSLocalizedString(@"Save Current Image (Including Letter Box)", nil)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)checkForUpdatesOnStartup
{
    NSTimeInterval timeInterval;
    switch ([_defaults integerForKey:MUpdateCheckIntervalKey]) {
        case CHECK_UPDATE_NEVER   : return; // don't check automatically
        case CHECK_UPDATE_DAILY   : timeInterval =  1 * 24 * 60 * 60;   break;
        case CHECK_UPDATE_WEEKLY  : timeInterval =  7 * 24 * 60 * 60;   break;
        case CHECK_UPDATE_MONTHLY :
        default                   : timeInterval = 30 * 24 * 60 * 60;   break;
    }
    NSDate* lastCheckTime = [_defaults objectForKey:MLastUpdateCheckTimeKey];
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:lastCheckTime];
    if (timeInterval <= interval) {
        [self checkForUpdates:FALSE];
    }
}

- (void)checkForUpdates:(BOOL)manual
{
    [_movieView setMessage:NSLocalizedString(@"Checking for Updates...", nil)];
    [_movieView display];

    NSError* error;
    UpdateChecker* checker = [[UpdateChecker alloc] init];
    int ret = [checker checkUpdate:&error];
    [_defaults setObject:[NSDate date] forKey:MLastUpdateCheckTimeKey];
    [_preferenceController updateLastUpdateCheckTimeTextField];

    if (ret == UPDATE_CHECK_FAILED) {
        NSString* s = [NSString stringWithFormat:@"%@", error];
        if (manual) {   // only for manual checking
            NSRunAlertPanel([NSApp localizedAppName], s,
                            NSLocalizedString(@"OK", nil), nil, nil);
        }
        else {
            [_movieView setMessage:s];
        }
    }
    else if (ret == NO_UPDATE_AVAILABLE) {
        NSString* s = NSLocalizedString(@"No update available.", nil);
        if (manual) {   // only for manual checking
            NSRunAlertPanel([NSApp localizedAppName], s,
                            NSLocalizedString(@"OK", nil), nil, nil);
        }
        else {
            [_movieView setMessage:s];
        }
    }
    else if (ret == NEW_VERSION_AVAILABLE) {
        // new version alert always show.
        NSString* newVersion = [checker newVersion];
        NSURL* homepageURL = [checker homepageURL];
        NSURL* downloadURL = [checker downloadURL];
        NSString* s = [NSString stringWithFormat:
                        NSLocalizedString(@"New version %@ is available.", nil),
                        newVersion];
        ret = NSRunAlertPanel([NSApp localizedAppName], s,
                              NSLocalizedString(@"Show Updates", nil),
                              NSLocalizedString(@"Download", nil),
                              NSLocalizedString(@"Cancel", nil), nil);
        if (ret == NSAlertDefaultReturn) {
            [[NSWorkspace sharedWorkspace] openURL:homepageURL];
        }
        else if (ret == NSAlertAlternateReturn) {
            [[NSWorkspace sharedWorkspace] openURL:downloadURL];
        }
    }
    [checker release];
}

- (IBAction)viewDurationAction:(id)sender
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    _viewDuration = !_viewDuration;
    [_defaults setBool:_viewDuration forKey:MViewDurationKey];
    [self updateTimeUI];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark panels

- (IBAction)controlPanelAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_controlPanel isVisible]) {
        [_controlPanel hidePanel];
    }
    else {
        [_controlPanel showPanel];
        //[_controlPanel makeKeyWindow];
    }
}

- (IBAction)preferencePanelAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_preferenceController) {
        _preferenceController = [[PreferenceController alloc]
                            initWithAppController:self mainWindow:_mainWindow];
    }
    [_preferenceController showWindow:self];
    [[_preferenceController window] setDelegate:self];
    [[_preferenceController window] makeKeyWindow];
    [_playPanel orderOutWithFadeOut:self];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation AppController (NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [menuItem title]);
    if ([[NSApp keyWindow] firstResponder] != _movieView) {
        if ([NSApp keyWindow] == [_fullScreener fullWindow]) {
            if ([menuItem action] == @selector(fullNavigationAction:)) {
                return TRUE;
            }
            if ([menuItem action] == @selector(prevNextMovieAction:)) {
                return ![_fullScreener isNavigating] && (0 < [_playlist count]);
            }
            if ([menuItem action] == @selector(seekAction:)) {
                if ([menuItem tag] == 40 || [menuItem tag] == -40) {
                    return (_movie != nil && _subtitles != nil);
                }
                else {
                    return (_movie != nil);
                }
            }
        }
        if ([NSApp keyWindow] == [_playlistController window] &&
            [menuItem action] == @selector(playlistAction:)) {
            return TRUE;
        }
        if ([menuItem action] == @selector(openFileAction:)) {
            return TRUE;
        }
        return FALSE;
    }
    if (![self isFullScreen] && _playlistController &&
        [[_playlistController window] isVisible]) {
        return FALSE;
    }

    // File
    if ([menuItem action] == @selector(openURLAction:)) {
        return FALSE;   // not supported yet
    }
    if ([menuItem action] == @selector(reopenMovieAction:)) {
        return (_movie != nil);
    }
    if ([menuItem action] == @selector(fullNavigationAction:)) {
        return [_defaults boolForKey:MFullNavUseKey];
    }

    // Controls
    if ([menuItem action] == @selector(seekAction:)) {
        if ([menuItem tag] == 40 || [menuItem tag] == -40) {
            return (_movie != nil && _subtitles != nil);
        }
        else {
            return (_movie != nil);
        }
    }
    if ([menuItem action] == @selector(prevNextMovieAction:)) {
        return (0 < [_playlist count]);
    }
    if ([menuItem action] == @selector(rangeRepeatAction:)) {
        return (_movie != nil);
    }
    
    // Movie
    if ([menuItem action] == @selector(movieSizeAction:)) {
        return _movie && ![self isFullScreen];
    }
    if ([menuItem action] == @selector(fullScreenAction:) ||
        [menuItem action] == @selector(fullScreenFillAction:)) {
        return (_movie != nil);
    }
    if ([menuItem action] == @selector(aspectRatioAction:)) {
        if ([menuItem tag] == ASPECT_RATIO_SAR) {
            return (_movie && !NSEqualSizes([_movie displaySize], [_movie encodedSize]));
        }
        else {
            return (_movie != nil);
        }
    }
    if ([menuItem action] == @selector(fullScreenUnderScanAction:)) {
        return (_movie && 0 < [_defaults floatForKey:MFullScreenUnderScanKey]);
    }
    if ([menuItem action] == @selector(audioTrackAction:)) {
        return (_movie && 0 < [[_movie audioTracks] count]);
    }
    if ([menuItem action] == @selector(saveCurrentImage:)) {
        return (_movie != nil);
    }

    // Subtitle
    if ([menuItem action] == @selector(openSubtitleFileAction:)) {
        return _movie && [_defaults boolForKey:MSubtitleEnableKey];
    }
    if ([menuItem action] == @selector(reopenSubtitleAction:)) {
        return (_subtitles != nil);
    }
    if ([menuItem action] == @selector(subtitleLanguageAction:) ||
        [menuItem action] == @selector(subtitleVisibleAction:) ||
        [menuItem action] == @selector(subtitleFontSizeAction:) ||
        [menuItem action] == @selector(subtitleVMarginAction:) ||
        [menuItem action] == @selector(subtitlePositionAction:) ||
        [menuItem action] == @selector(subtitleSyncAction:)) {
        return (_subtitles && 0 < [_subtitles count]);
    }

    return TRUE;
}

@end

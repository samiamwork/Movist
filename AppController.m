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
    if ((self = [super init])) {
        _playlist = [[Playlist alloc] init];
        _audioTrackIndexSet = [[NSMutableIndexSet alloc] init];
        _subtitleNameSet = [[NSMutableSet alloc] init];
        _fullScreenLock = [[NSLock alloc] init];

        _defaults = [NSUserDefaults standardUserDefaults];
        [MMovie_QuickTime checkA52CodecInstalled];
        [MMovie_QuickTime checkPerianInstalled];
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

    _alwaysOnTopEnabled = FALSE;
    _checkForAltVolumeChange = TRUE;
    _systemVolume = [self systemVolume];
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

    initSubtitleEncodingMenu(_subtitle0EncodingMenu, @selector(reopenSubtitleAction:));
    initSubtitleEncodingMenu(_subtitle1EncodingMenu, @selector(reopenSubtitleAction:));
    initSubtitleEncodingMenu(_subtitle2EncodingMenu, @selector(reopenSubtitleAction:));

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(subtitleTrackWillLoad:)
               name:MSubtitleTrackWillLoadNotification object:nil];
    [nc addObserver:self selector:@selector(subtitleTrackIsLoading:)
               name:MSubtitleTrackIsLoadingNotification object:nil];
    [nc addObserver:self selector:@selector(subtitleTrackDidLoad:)
               name:MSubtitleTrackDidLoadNotification object:nil];
    
    // modify menu-item shortcuts with shift modifier.
	for(NSMenuItem* item in [_controlMenu itemArray]) {
        if ([item action] == @selector(rateAction:) && [item tag] == 0) {
            [item setKeyEquivalent:@"\\"];
            [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
            break;
        }
    }

	for (NSMenuItem* item in [_subtitleMenu itemArray]) {
        if ([item action] == @selector(subtitleSyncAction:) && [item tag] == 0) {
            [item setKeyEquivalent:@"="];
            [item setKeyEquivalentModifierMask:NSControlKeyMask | NSShiftKeyMask];
            break;
        }
    }
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

- (void)checkLegacyPreferences
{
    // @"AutoFullScreen" is replaced with MOpeningViewKey.
    id value = [_defaults objectForKey:@"AutoFullScreen"];
    if (value) {
        [_defaults removeObjectForKey:@"AutoFullScreen"];
        if ([value boolValue] != FALSE) {    // default was FALSE
            [_defaults setInteger:OPENING_VIEW_FULL_SCREEN forKey:MOpeningViewKey];
        }
    }

    // @"BlackoutSecondaryScreen" is renamed to MFullScreenBlackScreensKey.
    value = [_defaults objectForKey:@"BlackoutSecondaryScreen"];
    if (value) {
        [_defaults removeObjectForKey:@"BlackoutSecondaryScreen"];
        if ([value boolValue] != FALSE) {   // default was FALSE
            [_defaults setBool:TRUE forKey:MFullScreenBlackScreensKey];
        }
    }

    // @"SubtitlePosition" is changed to MLetterBoxHeightKey and MSubtitleVPositionKey[0].
    value = [_defaults objectForKey:@"SubtitlePosition"];
    if (value) {
        [_defaults removeObjectForKey:@"SubtitlePosition"];
        if ([value intValue] != 100) {  // default was 100 ("auto")
            switch ([value intValue]) {
                case -1 :   // -1 is "on movie"
                    [_defaults setInteger:OSD_VPOSITION_BOTTOM forKey:MSubtitleVPositionKey];
                    [_defaults setInteger:LETTER_BOX_HEIGHT_SAME forKey:MLetterBoxHeightKey];
                    break;
                case 0 :    // 0 is "on letter-box"
                    [_defaults setInteger:OSD_VPOSITION_LBOX forKey:MSubtitleVPositionKey];
                    [_defaults setInteger:LETTER_BOX_HEIGHT_SAME forKey:MLetterBoxHeightKey];
                    break;
                case 1 :    // 1 is "on letter-box (1 line)"
                    [_defaults setInteger:OSD_VPOSITION_LBOX forKey:MSubtitleVPositionKey];
                    [_defaults setInteger:LETTER_BOX_HEIGHT_1_LINE forKey:MLetterBoxHeightKey];
                    break;
                case 2 :    // 2 is "on letter-box (2 lines)"
                    [_defaults setInteger:OSD_VPOSITION_LBOX forKey:MSubtitleVPositionKey];
                    [_defaults setInteger:LETTER_BOX_HEIGHT_2_LINES forKey:MLetterBoxHeightKey];
                    break;
                case 3 :    // 3 is "on letter-box (3 lines)"
                    [_defaults setInteger:OSD_VPOSITION_LBOX forKey:MSubtitleVPositionKey];
                    [_defaults setInteger:LETTER_BOX_HEIGHT_3_LINES forKey:MLetterBoxHeightKey];
                    break;
            }
        }
    }

    // @"OpeningResize" is changed to MOpeningViewKey and MMovieResizeCenterKey.
    value = [_defaults objectForKey:@"OpeningResize"];
    if (value) {
        [_defaults removeObjectForKey:@"OpeningResize"];
        switch ([value intValue]) {
            case 0 :    // 0 is "never resize"
                [_defaults setInteger:OPENING_VIEW_NONE forKey:MOpeningViewKey];
                break;
            case 1 :    // 1 is "title center"
                [_defaults setInteger:MOVIE_RESIZE_CENTER_TM forKey:MMovieResizeCenterKey];
                break;
            case 2 :    // 2 is "bottom center"
                [_defaults setInteger:MOVIE_RESIZE_CENTER_BM forKey:MMovieResizeCenterKey];
                break;
            case 3 :    // 3 is "bottom right"
                [_defaults setInteger:MOVIE_RESIZE_CENTER_BR forKey:MMovieResizeCenterKey];
                break;
        }
    }

    // @"WindowResize" is renamed to MWindowResizeModeKey.
    value = [_defaults objectForKey:@"WindowResize"];
    if (value) {
        [_defaults removeObjectForKey:@"WindowResize"];
        if ([value intValue] != 1) {   // default was "adjust to size"
            [_defaults setInteger:[value intValue] forKey:MWindowResizeModeKey];
        }
    }

    // @"DraggingAction" is renamed to MViewDragActionKey.
    value = [_defaults objectForKey:@"DraggingAction"];
    if (value) {
        [_defaults removeObjectForKey:@"DraggingAction"];
        if ([value intValue] != 0) {   // default was 0 ("none")
            [_defaults setInteger:[value intValue] forKey:MViewDragActionKey];
        }
    }

    // @"DisablePerianSubtitle" is renamed to MUseQuickTimeSubtitlesKey.
    value = [_defaults objectForKey:@"DisablePerianSubtitle"];
    if (value) {
        [_defaults removeObjectForKey:@"DisablePerianSubtitle"];
        if ([value boolValue] != TRUE) {   // default was TRUE.
            [_defaults setInteger:![value boolValue] forKey:MUseQuickTimeSubtitlesKey];
        }
    }

    // @"AutoSubtitlePositionMaxLines" is renamed to MAutoLetterBoxHeightMaxLinesKey.
    value = [_defaults objectForKey:@"AutoSubtitlePositionMaxLines"];
    if (value) {
        [_defaults removeObjectForKey:@"AutoSubtitlePositionMaxLines"];
        if ([value intValue] != 2) {   // default was 2.
            [_defaults setInteger:[value intValue] forKey:MAutoLetterBoxHeightMaxLinesKey];
        }
    }
}

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

    [self checkLegacyPreferences];

    // initial update preferences: general
    [self setAlwaysOnTopEnabled:[_defaults boolForKey:MAlwaysOnTopKey]];
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
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT          | SUBTITLE_ATTRIBUTE_TEXT_COLOR |
                 SUBTITLE_ATTRIBUTE_STROKE_COLOR  | SUBTITLE_ATTRIBUTE_STROKE_WIDTH |
                 SUBTITLE_ATTRIBUTE_SHADOW_COLOR  | SUBTITLE_ATTRIBUTE_SHADOW_BLUR |
                 SUBTITLE_ATTRIBUTE_SHADOW_OFFSET | SUBTITLE_ATTRIBUTE_SHADOW_DARKNESS |
                 SUBTITLE_ATTRIBUTE_LINE_SPACING  | SUBTITLE_ATTRIBUTE_V_POSITION |
                 SUBTITLE_ATTRIBUTE_H_MARGIN      | SUBTITLE_ATTRIBUTE_V_MARGIN;
    NSFont* font;
    NSString* fontName;

	fontName = [_defaults stringForKey:MSubtitleFontNameKey];
	font = [NSFont fontWithName:fontName size:10.0];
	if (!font) {
		runAlertPanel(_mainWindow,
					  NSLocalizedString(@"Subtitle Font Not Found", nil),
					  [NSString stringWithFormat:NSLocalizedString(
					   @"\"%@\" not found\n"
						"Subtitle font setting will be restored to default.", nil),
					   fontName],
					  NSLocalizedString(@"OK", nil), nil, nil);
		[_defaults setObject:[[NSFont boldSystemFontOfSize:1.0] fontName]
					  forKey:MSubtitleFontNameKey];
	}
	attrs.fontName      = [_defaults stringForKey:MSubtitleFontNameKey];
	attrs.fontSize      = [_defaults floatForKey:MSubtitleFontSizeKey];
	attrs.textColor     = [_defaults colorForKey:MSubtitleTextColorKey];
	attrs.strokeColor   = [_defaults colorForKey:MSubtitleStrokeColorKey];
	attrs.strokeWidth   = [_defaults floatForKey:MSubtitleStrokeWidthKey];
	attrs.shadowColor   = [_defaults colorForKey:MSubtitleShadowColorKey];
	attrs.shadowBlur    = [_defaults floatForKey:MSubtitleShadowBlurKey];
	attrs.shadowOffset  = [_defaults floatForKey:MSubtitleShadowOffsetKey];
	attrs.shadowDarkness= [_defaults integerForKey:MSubtitleShadowDarknessKey];
	attrs.vPosition     = [_defaults integerForKey:MSubtitleVPositionKey];
	attrs.hMargin       = [_defaults floatForKey:MSubtitleHMarginKey];
	attrs.vMargin       = [_defaults floatForKey:MSubtitleVMarginKey];
	attrs.lineSpacing   = [_defaults floatForKey:MSubtitleLineSpacingKey];
	[_movieView setSubtitleAttributes:&attrs];

    [_movieView setLetterBoxHeight:[_defaults integerForKey:MLetterBoxHeightKey]];
    [_movieView setSubtitleScreenMargin:[_defaults floatForKey:MSubtitleScreenMarginKey]];

    // initial update preferences: advanced
    // ...

    // initial update preferences: advanced - details : general
    [_movieView setActivateOnDragging:[_defaults boolForKey:MActivateOnDraggingKey]];
    [_movieView setViewDragAction:[_defaults integerForKey:MViewDragActionKey]];

    // initial update preferences: advanced - details : video
    [_movieView setCaptureFormat:[_defaults integerForKey:MCaptureFormatKey]];
    [self setIncludeLetterBoxOnCapture:[_defaults boolForKey:MIncludeLetterBoxOnCaptureKey]];

    // initial update preferences: advanced - details : subtitle
    [MMovie_QuickTime setUseQuickTimeSubtitles:[_defaults boolForKey:MUseQuickTimeSubtitlesKey]];
    [_movieView setAutoLetterBoxHeightMaxLines:[_defaults integerForKey:MAutoLetterBoxHeightMaxLinesKey]];

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
    if ([_playPanel isVisible]) {
        [_playPanel orderOut:self];
    }
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
    runAlertPanel(_mainWindow, title, @"", NSLocalizedString(@"OK", nil), nil, nil);
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
    [self updateSubtitlePositionMenuItem];
    [self updateLetterBoxHeightMenuItems];
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
        if (manual) {   // only for manual checking
            runAlertPanel(_mainWindow,
                          NSLocalizedString(@"Cannot check for update.", nil),
                          [error localizedDescription],
                          NSLocalizedString(@"OK", nil), nil, nil);
        }
        else {
            [_movieView setMessage:[error localizedDescription]];
        }
    }
    else if (ret == NO_UPDATE_AVAILABLE) {
        NSString* s = NSLocalizedString(@"No update available.", nil);
        if (manual) {   // only for manual checking
            runAlertPanel(_mainWindow, s, @"", NSLocalizedString(@"OK", nil), nil, nil);
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
        ret = runAlertPanel(_mainWindow, s, @"",
                            NSLocalizedString(@"Show Updates", nil),
                            NSLocalizedString(@"Download", nil),
                            NSLocalizedString(@"Cancel", nil));
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
        [_controlPanel setLevel:[_mainWindow level] + 1];
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
        [[_preferenceController window] setDelegate:self];
    }
    [_preferenceController showWindow:self];
    [[_preferenceController window] makeKeyWindow];
    [[_preferenceController window] setAlwaysOnTop:[_mainWindow alwaysOnTop]];
    [_playPanel orderOutWithFadeOut:self];
}

- (void)setAlwaysOnTopEnabled:(BOOL)enabled
{
    _alwaysOnTopEnabled = enabled;

    if ([_movieView window] == _mainWindow) {
        [self updateAlwaysOnTop:_alwaysOnTopEnabled];
    }
}

- (void)updateAlwaysOnTop:(BOOL)alwaysOnTop
{
    if ([_movieView window] != _mainWindow) {
        return;
    }

    if (alwaysOnTop) {
        alwaysOnTop = ![_defaults boolForKey:MAlwaysOnTopOnPlayingKey] ||
                      (_movie && [_movie rate] != 0.0);
    }

    [[_preferenceController window] setAlwaysOnTop:alwaysOnTop];
    [[_playlistController window] setAlwaysOnTop:alwaysOnTop];
    [_mainWindow setAlwaysOnTop:alwaysOnTop];
    [_controlPanel setLevel:[_mainWindow level] + 1];
}

- (IBAction)alwaysOnTopAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _alwaysOnTopEnabled = !_alwaysOnTopEnabled;

    NSString* s;
    if (_alwaysOnTopEnabled) {
        s = NSLocalizedString(@"Keep on Top of All Other Windows", nil);
        if ([_defaults boolForKey:MAlwaysOnTopOnPlayingKey]) {
            s = [s stringByAppendingFormat:@" (%@)",
                 NSLocalizedString(@"Apply on Playing Only", nil)];
        }
    }
    else {
        s = NSLocalizedString(@"Don't keep on Top of All Other Windows", nil);
    }
    [_movieView setMessage:s];

    [self updateAlwaysOnTop:_alwaysOnTopEnabled];
}

////////////////////////////////////////////////////////////////////////////////

- (void)showOpenAlert:(NSError*)error forURL:(NSURL*)url
{
    if ([_movieView window] == _mainWindow) {
        runAlertPanelForOpenError(_mainWindow, error, url);
    }
    else {
        [_movieView setError:error
                        info:[NSString stringWithFormat:@"%@\n\n%@",
                              NSLocalizedString(@"Cannot open file", nil),
                              [url isFileURL] ? [url path] : [url absoluteString]]];
    }
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
                if ([menuItem tag] == SEEK_TAG_PREV_SUBTITLE ||
                    [menuItem tag] == SEEK_TAG_NEXT_SUBTITLE) {
                    return (_movie != nil && _subtitles != nil);
                }
                else {
                    return (_movie != nil);
                }
            }
        }
        if ([menuItem action] == @selector(fullScreenAction:)) {
            return _movie && ![self playlistWindowVisible];
        }
        if ([menuItem action] == @selector(fullScreenFillAction:)) {
            return (_movie != nil);
        }
        if ([menuItem action] == @selector(desktopBackgroundAction:)) {
            return _movie && ![self playlistWindowVisible] && ![self isFullScreen];
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
    if (![self isFullScreen] &&
        [NSApp keyWindow] == [_playlistController window]) {
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
    if ([menuItem action] == @selector(movieSizeAction:) ||
        [menuItem action] == @selector(fullScreenAction:) ||
        [menuItem action] == @selector(fullScreenFillAction:)) {
        return (_movie != nil);
    }
    if ([menuItem action] == @selector(desktopBackgroundAction:)) {
        return _movie && ![self isFullScreen];
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
    if ([menuItem action] == @selector(revealInFinder:)) {
        return (_movie != nil);
    }
    if ([menuItem action] == @selector(moveToTrash:)) {
        return (_movie != nil);
    }

    // Subtitle
    if ([menuItem action] == @selector(openSubtitleFileAction:) ||
        [menuItem action] == @selector(addSubtitleFileAction:)) {
        return _movie && [_defaults boolForKey:MSubtitleEnableKey];
    }
    if ([menuItem action] == @selector(reopenSubtitleAction:)) {
        return (_subtitles != nil);
    }
    if ([menuItem action] == @selector(subtitleLanguageAction:)) {
        BOOL enabled = (_subtitles && 0 < [_subtitles count]);
        if (enabled && [menuItem isAlternate] && ![menuItem state]) {
            enabled = ([self enabledSubtitleCount] < 3);
        }
        return enabled;
    }
    if ([menuItem action] == @selector(subtitleVisibleAction:) ||
        [menuItem action] == @selector(subtitleFontSizeAction:) ||
        [menuItem action] == @selector(subtitleVMarginAction:) ||
        [menuItem action] == @selector(subtitlePositionAction:) ||
        [menuItem action] == @selector(subtitleSyncAction:)) {
        return (_subtitles && 0 < [_subtitles count]);
    }

    // Window
    if ([menuItem action] == @selector(alwaysOnTopAction:)) {
        [menuItem setState:_alwaysOnTopEnabled];//[_mainWindow alwaysOnTop]];
        return ([NSApp keyWindow] == _mainWindow);
    }

    return TRUE;
}

@end

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

#import "MMovie_FFMPEG.h"
#import "MMovie_QuickTime.h"
#import "Playlist.h"
#import "PlaylistController.h"
#import "PreferenceController.h"

#import "MMovieView.h"
#import "MainWindow.h"
#import "FullScreener.h"
#import "FullWindow.h"
#import "CustomControls.h"
#import "ControlPanel.h"

@implementation AppController

- (id)init
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _playlist = [[Playlist alloc] init];
        _audioTrackIndexSet = [[NSMutableIndexSet alloc] init];
        _subtitleNameSet = [[NSMutableSet alloc] init];
        _fullScreenLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)awakeFromNib
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self initRemoteControl];

    [_mainWindow setReleasedWhenClosed:FALSE];
    [_mainWindow setExcludedFromWindowsMenu:TRUE];

    _defaults = [NSUserDefaults standardUserDefaults];

    initSubtitleEncodingMenu(_subtitleEncodingMenu, @selector(reopenSubtitleAction:));

    [_volumeSlider      setMinValue:0.0];   [_volumeSlider      setMaxValue:MAX_VOLUME];
    [_panelVolumeSlider setMinValue:0.0];   [_panelVolumeSlider setMaxValue:MAX_VOLUME];
    [self updateVolumeUI];

    // add shift-key mask to backward/forward seek menu items
    unsigned int mask = NSAlternateKeyMask | NSShiftKeyMask;
    [_seekBackward3MenuItem setKeyEquivalentModifierMask:mask];
    [_seekForward3MenuItem setKeyEquivalentModifierMask:mask];
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self cleanupRemoteControl];
    [self closeMovie];
    [_fullScreenLock release];
    [_subtitleNameSet release];
    [_audioTrackIndexSet release];
    [_playlist release];
    [_playlistController release];
    [_preferenceController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)applicationWillBecomeActive:(NSNotification*)aNotification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self startRemoteControl];
}

- (void)applicationWillResignActive:(NSNotification*)aNotification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self stopRemoteControl];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    return _quitWhenWindowClose;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication*)theApplication
                    hasVisibleWindows:(BOOL)flag
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, flag);
    [_mainWindow makeKeyAndOrderFront:self];
    return FALSE;
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults synchronize];
}

- (BOOL)application:(NSApplication*)theApplication openFile:(NSString*)filename
{
    TRACE(@"%s:\"%@\"", __PRETTY_FUNCTION__, filename);
    return [self openFile:filename updatePlaylist:TRUE];
}

- (void)application:(NSApplication*)theApplication openFiles:(NSArray*)filenames
{
    TRACE(@"%s:{%@}", __PRETTY_FUNCTION__, filenames);
    if ([self openFiles:filenames updatePlaylist:TRUE]) {
        [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
    }
    else {
        [NSApp replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
    }
}

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);

    // initial update preferences: general
    [_mainWindow setAlwaysOnTop:[_defaults boolForKey:MAlwaysOnTopKey]];
    [_movieView setActivateOnDragging:[_defaults boolForKey:MActivateOnDraggingKey]];
    [self setQuitWhenWindowClose:[_defaults boolForKey:MQuitWhenWindowCloseKey]];
    [self setSeekInterval:[_defaults floatForKey:MSeekInterval0Key] atIndex:0];
    [self setSeekInterval:[_defaults floatForKey:MSeekInterval1Key] atIndex:1];
    [self setSeekInterval:[_defaults floatForKey:MSeekInterval2Key] atIndex:2];

    // initial update preferences: video
    [_movieView setFullScreenUnderScan:[_defaults floatForKey:MFullScreenUnderScanKey]];

    // initial update preferences: audio

    // initial update preferences: subtitle
    [_movieView setSubtitleFontName:[_defaults stringForKey:MSubtitleFontNameKey]
                               size:[_defaults floatForKey:MSubtitleFontSizeKey]];
    [_movieView setSubtitleTextColor:[_defaults colorForKey:MSubtitleTextColorKey]];
    [_movieView setSubtitleStrokeColor:[_defaults colorForKey:MSubtitleStrokeColorKey]];
    [_movieView setSubtitleStrokeWidth:[_defaults floatForKey:MSubtitleStrokeWidthKey]];
    [_movieView setSubtitleShadowColor:[_defaults colorForKey:MSubtitleShadowColorKey]];
    [_movieView setSubtitleShadowBlur:[_defaults floatForKey:MSubtitleShadowBlurKey]];
    [_movieView setSubtitleShadowOffset:[_defaults floatForKey:MSubtitleShadowOffsetKey]];
    [_movieView setSubtitleDisplayOnLetterBox:[_defaults boolForKey:MSubtitleDisplayOnLetterBoxKey]];
    [_movieView setMinLetterBoxHeight:[_defaults floatForKey:MSubtitleMinLetterBoxHeightKey]];
    [_movieView setSubtitleHMargin:[_defaults floatForKey:MSubtitleHMarginKey]];
    [_movieView setSubtitleVMargin:[_defaults floatForKey:MSubtitleVMarginKey]];
    
    // initial update preferences: advanced
    [_movieView setRemoveGreenBox:[_defaults boolForKey:MRemoveGreenBoxKey]];

    BOOL displayOnLetterBox = [_movieView subtitleDisplayOnLetterBox];
    [_subtitleDisplayOnLetterBoxMenuItem setState:displayOnLetterBox];
    [_subtitleDisplayOnLetterBoxButton setState:displayOnLetterBox];
    
    _playRate = 1.0;
    _prevMovieTime = 0.0;

    [self updateUI];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (MMovie*)movie     { return _movie; }
- (NSURL*)movieURL    { return (_movie) ?     [[_playlist currentItem] movieURL] : nil; }
- (NSURL*)subtitleURL { return (_subtitles) ? [[_playlist currentItem] subtitleURL] : nil; }

- (void)updateUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSURL* movieURL = [self movieURL];
    [_mainWindow setMovieURL:movieURL];
    [_fullScreener setMovieURL:movieURL];
    [_controlPanel setMovieURL:movieURL];
    [_propertiesView reloadData];
    [self updateFullScreenFillMenu];
    [self updateAspectRatioMenu];
    [self updateAudioTrackMenu];
    [self updateSubtitleLanguageMenu];
    [self updateRepeatUI];
    [self updateVolumeUI];
    [self updateTimeUI];
    [self updatePlayUI];
    [_playlistController updateUI];
}

- (void)clearPureArrowKeyEquivalents
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_seekBackward1MenuItem setKeyEquivalent:@""];
    [_seekForward1MenuItem setKeyEquivalent:@""];
    [_volumeUpMenuItem setKeyEquivalent:@""];
    [_volumeDownMenuItem setKeyEquivalent:@""];
}

- (void)setPureArrowKeyEquivalents
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_seekBackward1MenuItem setKeyEquivalent:[NSString stringWithUTF8String:"⇠"]];
    [_seekForward1MenuItem setKeyEquivalent:[NSString stringWithUTF8String:"⇢"]];
    [_volumeUpMenuItem setKeyEquivalent:[NSString stringWithUTF8String:"⇡"]];
    [_volumeDownMenuItem setKeyEquivalent:[NSString stringWithUTF8String:"⇣"]];

    // no key equivalent mask
    [_seekBackward1MenuItem setKeyEquivalentModifierMask:0];
    [_seekForward1MenuItem setKeyEquivalentModifierMask:0];
    [_volumeUpMenuItem setKeyEquivalentModifierMask:0];
    [_volumeDownMenuItem setKeyEquivalentModifierMask:0];
}

- (void)updatePureArrowKeyEquivalents
{
    //TRACE(@"key-win:\"%@\", movie-win:\"%@\" (%@)",
    //      [NSApp keyWindow], [_movieView window],
    //      [[_movieView window] isKeyWindow] ? @"is key-win" : @"is not key-win");
    NSWindow* keyWindow = [NSApp keyWindow];
    if (keyWindow) {    // app is currently activated
        if ([keyWindow isEqualTo:_mainWindow] ||
            [keyWindow isEqualTo:[_fullScreener fullWindow]]) {
            [self setPureArrowKeyEquivalents];
        }
        else {
            [self clearPureArrowKeyEquivalents];
        }
    }
}

- (void)setQuitWhenWindowClose:(BOOL)quitWhenWindowClose
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, quitWhenWindowClose);
    _quitWhenWindowClose = quitWhenWindowClose;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark panels

- (IBAction)controlPanelAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_controlPanel isVisible]) {
        [_controlPanel hidePanel];
    }
    else {
        [_controlPanel showPanel];
    }
}

- (IBAction)preferencePanelAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_preferenceController) {
        _preferenceController = [[PreferenceController alloc]
                            initWithAppController:self mainWindow:_mainWindow];
    }
    [_preferenceController showWindow:self];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation AppController (NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [menuItem title]);
    if (![self isFullScreen] && _playlistController &&
        [[_playlistController window] isVisible]) {
        return FALSE;
    }

    // File
    if ([menuItem action] == @selector(openURLAction:)) {
        return FALSE;   // not supported yet
    }
    if ([menuItem action] == @selector(reopenMovieAction:)) {
        #if defined(_SUPPORT_FFMPEG)
        if ([menuItem tag] == DECODER_FFMPEG) {
            return _movie && [_movie isMemberOfClass:[MMovie_QuickTime class]];
        }
        else {  // DECODER_QUICKTIME
            return _movie && [_movie isMemberOfClass:[MMovie_FFMPEG class]];
        }
        #else
        return FALSE;
        #endif
    }

    // Controls
    if ([menuItem action] == @selector(seekAction:) ||
        [menuItem action] == @selector(rangeRepeatAction:)) {
        return (_movie != nil);
    }
    if ([menuItem action] == @selector(prevNextMovieAction:)) {
        return (0 < [_playlist count]);
    }

    // Movie
    if ([menuItem action] == @selector(movieSizeAction:)) {
        return _movie && ![self isFullScreen];
    }
    if ([menuItem action] == @selector(fullScreenAction:) ||
        [menuItem action] == @selector(fullScreenFillAction:) ||
        [menuItem action] == @selector(aspectRatioAction:)) {
        return (_movie != nil);
    }
    if ([menuItem action] == @selector(fullScreenUnderScanAction:)) {
        float underScan = [_defaults floatForKey:MFullScreenUnderScanKey];
        return (_movie && 0 < (float)(int)(underScan * 10) / 10);   // make "x.x"
    }
    if ([menuItem action] == @selector(audioTrackAction:)) {
        return (_movie && 0 <= [menuItem tag]);
    }

    // Subtitle
    if ([menuItem action] == @selector(openSubtitleFileAction:)) {
        return _movie && [_defaults boolForKey:MSubtitleEnableKey];
    }
    if ([menuItem action] == @selector(subtitleLanguageAction:)) {
        return (_subtitles && 0 <= [menuItem tag]);
    }
    if ([menuItem action] == @selector(reopenSubtitleAction:) ||
        [menuItem action] == @selector(subtitleVisibleAction:) ||
        [menuItem action] == @selector(subtitleFontSizeAction:) ||
        [menuItem action] == @selector(subtitleVMarginAction:) ||
        [menuItem action] == @selector(subtitleLetterBoxHeightAction:) ||
        [menuItem action] == @selector(subtitleDisplayOnLetterBoxAction:) ||
        [menuItem action] == @selector(subtitleSyncAction:)) {
        return (_subtitles != nil);
    }

    return TRUE;
}

@end

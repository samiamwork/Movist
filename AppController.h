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

#import "Movist.h"
#import "CustomControls.h"
#import "SeekSlider.h"

#import "AppleRemote/RemoteControl.h"

@class MTrack;
@class MMovie;
@class MSubtitle;
@class Playlist;
@class PlaylistItem;
@class PlaylistController;
@class PreferenceController;

@class MultiClickRemoteBehavior;
@class RemoteControlContainer;

@class MMovieView;
@class MainWindow;
@class HoverButton;
@class ControlPanel;
@class FullScreener;
@class PlayPanel;

@interface AppController : NSObject
{
    MultiClickRemoteBehavior* _remoteControlBehavior;
    RemoteControlContainer* _remoteControlContainer;
    RemoteControlEventIdentifier _remoteControlRepeatButtonID;
    NSTimer* _remoteControlRepeatTimer;
    NSLock* _remoteControlRepeatTimerLock;

    PreferenceController* _preferenceController;
    PlaylistController* _playlistController;
    NSUserDefaults* _defaults;
    NSTimer* _updateSystemActivityTimer;
    BOOL _audioDeviceSupportsDigital;
    BOOL _alwaysOnTopEnabled;
    BOOL _checkForAltVolumeChange;
    float _systemVolume;

    // movie & subtitle
    MMovie* _movie;
    Playlist* _playlist;
    NSMutableArray* _subtitles;
    NSMutableIndexSet* _audioTrackIndexSet;
    NSMutableSet* _subtitleNameSet;
    float _playRate;
    float _seekInterval[3];

    // last-played-movie
    NSURL* _lastPlayedMovieURL;
    float _lastPlayedMovieTime;
    NSRange _lastPlayedMovieRepeatRange;
    int _lastPlayedMovieAspectRatio;

    // main-menu
    IBOutlet NSMenuItem* _reopenWithMenuItem;
    IBOutlet NSMenuItem* _altCopyImageMenuItem;
    IBOutlet NSMenuItem* _altSaveImageMenuItem;
    IBOutlet NSMenu* _movieMenu;
    IBOutlet NSMenu* _aspectRatioMenu;
    IBOutlet NSMenu* _fullScreenFillMenu;
    IBOutlet NSMenu* _controlMenu;
    IBOutlet NSMenuItem* _muteMenuItem;
    IBOutlet NSMenu* _subtitleMenu;
    IBOutlet NSMenuItem* _subtitle0MenuItem;
    IBOutlet NSMenuItem* _subtitle1MenuItem;
    IBOutlet NSMenuItem* _subtitle2MenuItem;
    IBOutlet NSMenu* _subtitle0EncodingMenu;
    IBOutlet NSMenu* _subtitle1EncodingMenu;
    IBOutlet NSMenu* _subtitle2EncodingMenu;
    IBOutlet NSMenuItem* _subtitleFontSizeSmallerMenuItem;
    IBOutlet NSMenuItem* _subtitleFontSizeBiggerMenuItem;
    IBOutlet NSMenuItem* _subtitleFontSizeDefaultMenuItem;
    IBOutlet NSMenuItem* _subtitleVMarginSmallerMenuItem;
    IBOutlet NSMenuItem* _subtitleVMarginBiggerMenuItem;
    IBOutlet NSMenuItem* _subtitleVMarginDefaultMenuItem;
    IBOutlet NSMenuItem* _subtitleSyncLaterMenuItem;
    IBOutlet NSMenuItem* _subtitleSyncEarlierMenuItem;
    IBOutlet NSMenuItem* _subtitleSyncDefaultMenuItem;

    // main window
    IBOutlet MainWindow* _mainWindow;
    IBOutlet MMovieView* _movieView;
    IBOutlet NSButton* _muteButton;
    IBOutlet NSSlider* _volumeSlider;
    IBOutlet MainSeekSlider* _seekSlider;
    IBOutlet TimeTextField* _lTimeTextField;
    IBOutlet TimeTextField* _rTimeTextField;
    IBOutlet NSButton* _playButton;
    IBOutlet HoverButton* _prevSeekButton;
    IBOutlet HoverButton* _nextSeekButton;
    IBOutlet HoverButton* _controlPanelButton;
    IBOutlet HoverButton* _prevMovieButton;
    IBOutlet HoverButton* _nextMovieButton;
    IBOutlet HoverButton* _playlistButton;
    NSButton* _decoderButton;
    float _prevMovieTime;
    BOOL _viewDuration;

    // control panel: A/V Control
    IBOutlet ControlPanel* _controlPanel;
    IBOutlet NSTextField* _audioDeviceTextField;
    IBOutlet NSTextField* _audioOutTextField;
    IBOutlet NSSegmentedControl* _subtitleLanguageSegmentedControl;
    IBOutlet NSTextField* _subtitleNameTextField;
    IBOutlet NSPopUpButton* _subtitlePositionPopUpButton;
    IBOutlet NSButton* _subtitlePositionDefaultButton;
    IBOutlet NSPopUpButton* _letterBoxHeightPopUpButton;
    IBOutlet NSTextField* _repeatBeginningTextField;
    IBOutlet NSTextField* _repeatEndTextField;

    // control panel: Properties
    IBOutlet NSButton* _cpDecoderButton;
    IBOutlet NSTextField* _dataSizeBpsTextField;
    IBOutlet NSTextField* _fpsTextField;
    IBOutlet NSTableView* _propertiesView;

    // full-screen & navigation
    NSLock* _fullScreenLock;
    FullScreener* _fullScreener;

    // play panel
    IBOutlet PlayPanel* _playPanel;
    IBOutlet NSButton* _fsMuteButton;
    IBOutlet NSSlider* _fsVolumeSlider;
    IBOutlet FSSeekSlider* _fsSeekSlider;
    IBOutlet TimeTextField* _fsLTimeTextField;
    IBOutlet TimeTextField* _fsRTimeTextField;
    IBOutlet NSButton* _fsPlayButton;
    IBOutlet NSButton* _fsPrevSeekButton;
    IBOutlet NSButton* _fsNextSeekButton;
    IBOutlet NSButton* _fsPlaylistButton;
    IBOutlet NSButton* _fsDecoderButton;
}

- (MMovie*)movie;
- (NSURL*)movieURL;

- (void)updateUI;
- (void)setIncludeLetterBoxOnCapture:(BOOL)includeLetterBox;
- (void)checkForUpdatesOnStartup;
- (void)checkForUpdates:(BOOL)manual;

- (IBAction)viewDurationAction:(id)sender;
- (IBAction)controlPanelAction:(id)sender;
- (IBAction)preferencePanelAction:(id)sender;

- (void)setAlwaysOnTopEnabled:(BOOL)enabled;
- (void)updateAlwaysOnTop:(BOOL)alwaysOnTop;
- (IBAction)alwaysOnTopAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Open)

- (BOOL)openFile:(NSString*)filename;
- (BOOL)openFiles:(NSArray*)filenames;
- (BOOL)openURL:(NSURL*)url;
- (BOOL)openFile:(NSString*)filename option:(int)option;
- (BOOL)openFiles:(NSArray*)filenames option:(int)option;
- (BOOL)openMovie:(NSURL*)movieURL movieClass:(Class)movieClass
        subtitles:(NSArray*)subtitleURLs subtitleEncoding:(CFStringEncoding)subtitleEncoding;
- (BOOL)openSubtitleFiles:(NSArray*)filenames;
- (BOOL)openSubtitles:(NSArray*)subtitleURLs encoding:(CFStringEncoding)encoding;
- (void)addSubtitles:(NSArray*)subtitleURLs;
- (BOOL)reopenMovieWithMovieClass:(Class)movieClass;
- (void)reopenSubtitles;
- (void)closeMovie;

- (void)updateDecoderUI;
- (void)updateDataSizeBpsUI;

- (IBAction)openFileAction:(id)sender;
- (IBAction)openSubtitleFileAction:(id)sender;
- (IBAction)addSubtitleFileAction:(id)sender;
- (IBAction)reopenMovieAction:(id)sender;
- (IBAction)reopenSubtitleAction:(id)sender;

- (IBAction)moviePropertyAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Playlist)

- (Playlist*)playlist;
- (void)addFiles:(NSArray*)filenames;
- (void)addSubtitleFiles:(NSArray*)filenames;
- (void)updatePrevNextMovieButtons;
- (BOOL)openCurrentPlaylistItem;
- (void)openPrevPlaylistItem;
- (void)openNextPlaylistItem;
- (void)playlistEnded;

- (BOOL)playlistWindowVisible;
- (void)showPlaylistWindow;
- (void)hidePlaylistWindow;

- (void)setRepeatMode:(unsigned int)mode;
- (void)updateRepeatUI;

- (void)loadLastPlayedMovieInfo;
- (void)saveLastPlayedMovieInfo;

- (IBAction)playlistAction:(id)sender;
- (IBAction)prevNextMovieAction:(id)sender;
- (IBAction)repeatAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Playback)

- (void)play;
- (void)pause;
- (void)gotoBeginning;
- (void)gotoEnd;
- (void)gotoTime:(float)time;
- (void)seekPrevSubtitle;
- (void)seekNextSubtitle;
- (void)seekBackward:(unsigned int)indexOfValue;
- (void)seekForward:(unsigned int)indexOfValue;
- (void)stepBackward;
- (void)stepForward;
- (void)setSeekInterval:(float)interval atIndex:(unsigned int)index;
- (void)setPlayRate:(float)rate;
- (void)changePlayRate:(int)tag;
- (void)setRangeRepeatRange:(NSRange)range;
- (void)setRangeRepeatBeginning:(float)beginning;
- (void)setRangeRepeatEnd:(float)end;
- (void)clearRangeRepeat;

- (void)updateTimeUI;
- (void)updatePlayUI;

- (IBAction)playAction:(id)sender;
- (IBAction)seekAction:(id)sender;
- (IBAction)rangeRepeatAction:(id)sender;
- (IBAction)rateAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Video)

- (void)setVideoTrackAtIndex:(unsigned int)index enabled:(BOOL)enabled;
- (void)resizeWithMagnification:(float)magnification;
- (void)resizeToScreen;

- (int)aspectRatio;
- (void)setAspectRatio:(int)aspectRatio;
- (void)updateAspectRatioMenu;

- (BOOL)isFullScreen;
- (void)beginFullScreen;
- (void)endFullScreen;

- (BOOL)isDesktopBackground;
- (void)beginDesktopBackground;
- (void)endDesktopBackground;

- (BOOL)isFullNavigation;
- (void)beginFullNavigation;
- (void)endFullNavigation;

- (void)setFullScreenFill:(int)fill forWideMovie:(BOOL)forWideMovie;
- (void)setFullScreenFill:(int)fill;
- (void)setFullScreenUnderScan:(float)underScan;
- (void)updateFullScreenFillMenu;

- (IBAction)movieSizeAction:(id)sender;
- (IBAction)fullScreenAction:(id)sender;
- (IBAction)desktopBackgroundAction:(id)sender;
- (IBAction)fullScreenFillAction:(id)sender;
- (IBAction)fullScreenUnderScanAction:(id)sender;
- (IBAction)aspectRatioAction:(id)sender;
- (IBAction)fullNavigationAction:(id)sender;
- (IBAction)saveCurrentImage:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Audio)

- (void)volumeUp;
- (void)volumeDown;
- (void)setVolume:(float)volume;
- (void)setMuted:(BOOL)muted;
- (void)updateVolumeUI;

- (void)setAudioTrackAtIndex:(unsigned int)index enabled:(BOOL)enabled;
- (void)enableAudioTracksInIndexSet:(NSIndexSet*)set;
- (void)autoenableAudioTracks;
- (void)changeAudioTrack:(int)tag;
- (void)updateAudioTrackMenuItems;
- (void)updateVolumeMenuItems;

- (void)scrollWheelAction:(NSEvent*)event;
- (IBAction)volumeAction:(id)sender;
- (IBAction)muteAction:(id)sender;
- (IBAction)audioTrackAction:(id)sender;

@end

@interface AppController (AudioDigital)

- (void)initDigitalAudioOut;
- (BOOL)updateDigitalAudioOut:(id)sender;
- (BOOL)isCurrentlyDigitalAudioOut;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Subtitle)

- (void)changeSubtitleVisible;

- (int)enabledSubtitleCount;
- (void)setSubtitleEnable:(BOOL)enable;

- (void)setSubtitleFontSize:(float)size atIndex:(int)index;
- (void)changeSubtitleFontSize:(int)tag atIndex:(int)index;
- (void)setSubtitlePosition:(int)position atIndex:(int)index;
- (void)changeSubtitlePositionAtIndex:(int)index;
- (void)setSubtitleHMargin:(float)hMargin atIndex:(int)index;
- (void)setSubtitleVMargin:(float)vMargin atIndex:(int)index;
- (void)changeSubtitleVMargin:(int)tag atIndex:(int)index;
- (void)setSubtitleLineSpacing:(float)spacing atIndex:(int)index;
- (void)setSubtitleSync:(float)sync atIndex:(int)index;
- (void)changeSubtitleSync:(int)tag atIndex:(int)index;

- (void)setLetterBoxHeight:(int)height;
- (void)changeLetterBoxHeight;
- (void)setSubtitleScreenMargin:(float)screenMargin;

- (void)setSubtitle:(MSubtitle*)subtitle enabled:(BOOL)enabled;
- (void)updateExternalSubtitleTrackNames;
- (void)autoenableSubtitles;
- (void)changeSubtitleLanguage:(int)tag;
- (void)updateMovieViewSubtitles;
- (void)updateSubtitleLanguageMenuItems;
- (void)updateSubtitlePositionMenuItems:(int)index;
- (void)updateLetterBoxHeightMenuItems;
- (void)updateControlPanelSubtitleUI;

- (IBAction)subtitleVisibleAction:(id)sender;
- (IBAction)subtitleLanguageAction:(id)sender;
- (IBAction)subtitleOrderAction:(id)sender;
- (IBAction)subtitleFontSizeAction:(id)sender;
- (IBAction)subtitleVMarginAction:(id)sender;
- (IBAction)subtitlePositionAction:(id)sender;
- (IBAction)subtitleSyncAction:(id)sender;
- (IBAction)letterBoxHeightAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Remote)

- (void)initRemoteControl;
- (void)cleanupRemoteControl;

- (void)startRemoteControl;
- (void)stopRemoteControl;

- (IBAction)remoteControlPlusAction:(id)sender;
- (IBAction)remoteControlPlusHoldAction:(id)sender;
- (IBAction)remoteControlMinusAction:(id)sender;
- (IBAction)remoteControlMinusHoldAction:(id)sender;
- (IBAction)remoteControlLeftAction:(id)sender;
- (IBAction)remoteControlLeftHoldAction:(id)sender;
- (IBAction)remoteControlRightAction:(id)sender;
- (IBAction)remoteControlRightHoldAction:(id)sender;
- (IBAction)remoteControlPlayAction:(id)sender;
- (IBAction)remoteControlPlayHoldAction:(id)sender;
- (IBAction)remoteControlMenuAction:(id)sender;
- (IBAction)remoteControlMenuHoldAction:(id)sender;

@end

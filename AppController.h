//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

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
@class FullScreener;
@class PlayPanel;
@class ControlPanel;

@class TimeTextField;
@class MainVolumeSlider;
@class MainSeekSlider;
@class FSVolumeSlider;
@class FSSeekSlider;

@interface AppController : NSObject
{
    MultiClickRemoteBehavior* _remoteControlBehavior;
    RemoteControlContainer* _remoteControlContainer;
    PreferenceController* _preferenceController;
    PlaylistController* _playlistController;
    NSUserDefaults* _defaults;
    BOOL _quitWhenWindowClose;

    // controls
    IBOutlet NSMenuItem* _playMenuItem;
    IBOutlet NSMenuItem* _seekBackward1MenuItem;
    IBOutlet NSMenuItem* _seekBackward2MenuItem;
    IBOutlet NSMenuItem* _seekBackward3MenuItem;
    IBOutlet NSMenuItem* _seekForward1MenuItem;
    IBOutlet NSMenuItem* _seekForward2MenuItem;
    IBOutlet NSMenuItem* _seekForward3MenuItem;
    IBOutlet NSMenuItem* _repeatOffMenuItem;
    IBOutlet NSMenuItem* _repeatAllMenuItem;
    IBOutlet NSMenuItem* _repeatOneMenuItem;
    IBOutlet NSMenuItem* _volumeUpMenuItem;
    IBOutlet NSMenuItem* _volumeDownMenuItem;
    IBOutlet NSMenuItem* _muteMenuItem;
    IBOutlet NSButton* _muteButton;
    MMovie* _movie;
    Playlist* _playlist;
    float _playRate;
    float _seekInterval[3];

    // movie
    IBOutlet NSMenu* _fullScreenFillMenu;
    IBOutlet NSMenu* _aspectRatioMenu;
    IBOutlet NSMenu* _audioTrackMenu;
    IBOutlet NSTableView* _propertiesView;
    NSMutableIndexSet* _audioTrackIndexSet;
    NSMutableSet* _subtitleNameSet;
    FullScreener* _fullScreener;
    NSLock* _fullScreenLock;

    // subtitle
    IBOutlet NSMenu* _subtitleEncodingMenu;
    IBOutlet NSMenu* _subtitleLanguageMenu;
    IBOutlet NSMenuItem* _subtitleVisibleMenuItem;
    IBOutlet NSMenuItem* _subtitleDisplayOnLetterBoxMenuItem;
    IBOutlet NSButton* _subtitleDisplayOnLetterBoxButton;
    NSArray* _subtitles;

    // main window
    IBOutlet MainWindow* _mainWindow;
    IBOutlet MMovieView* _movieView;
    IBOutlet MainVolumeSlider* _volumeSlider;
    IBOutlet MainSeekSlider* _seekSlider;
    IBOutlet NSButton* _playButton;
    IBOutlet TimeTextField* _lTimeTextField;
    IBOutlet TimeTextField* _rTimeTextField;
    IBOutlet NSButton* _playlistButton;
    float _prevMovieTime;

    // play panel
    IBOutlet PlayPanel* _playPanel;
    IBOutlet NSButton* _panelMuteButton;
    IBOutlet FSVolumeSlider* _panelVolumeSlider;
    IBOutlet FSSeekSlider* _panelSeekSlider;
    IBOutlet NSButton* _panelPlayButton;
    IBOutlet TimeTextField* _panelLTimeTextField;
    IBOutlet TimeTextField* _panelRTimeTextField;
    IBOutlet NSButton* _panelPlaylistButton;

    // control panel
    IBOutlet ControlPanel* _controlPanel;
    IBOutlet NSTextField* _repeatBeginningTextField;
    IBOutlet NSTextField* _repeatEndTextField;
}

- (MMovie*)movie;
- (NSURL*)movieURL;
- (NSURL*)subtitleURL;

- (void)updateUI;
- (void)clearPureArrowKeyEquivalents;
- (void)setPureArrowKeyEquivalents;
- (void)updatePureArrowKeyEquivalents;
- (void)setQuitWhenWindowClose:(BOOL)quitWhenClose;

- (IBAction)controlPanelAction:(id)sender;
- (IBAction)preferencePanelAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Open)

- (BOOL)openFile:(NSString*)filename updatePlaylist:(BOOL)updatePlaylist;
- (BOOL)openFiles:(NSArray*)filenames updatePlaylist:(BOOL)updatePlaylist;
- (BOOL)openURL:(NSURL*)url updatePlaylist:(BOOL)updatePlaylist;
- (BOOL)openMovie:(NSURL*)movieURL movieClass:(Class)movieClass
         subtitle:(NSURL*)subtitleURL subtitleEncoding:(CFStringEncoding)subtitleEncoding;
- (BOOL)openSubtitle:(NSURL*)subtitleURL encoding:(CFStringEncoding)encoding;
- (BOOL)reopenMovieWithMovieClass:(Class)movieClass;
- (void)reopenSubtitle;
- (void)closeMovie;

- (IBAction)openFileAction:(id)sender;
- (IBAction)openURLAction:(id)sender;
- (IBAction)openSubtitleFileAction:(id)sender;
- (IBAction)reopenMovieAction:(id)sender;
- (IBAction)reopenSubtitleAction:(id)sender;

- (IBAction)moviePropertyAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Playlist)

- (Playlist*)playlist;
- (void)addFiles:(NSArray*)filenames;
- (void)addURL:(NSURL*)url;
- (BOOL)openCurrentPlaylistItem;
- (BOOL)openPrevPlaylistItem;
- (BOOL)openNextPlaylistItem;

- (BOOL)playlistWindowVisible;
- (void)showPlaylistWindow;
- (void)hidePlaylistWindow;

- (void)setRepeatMode:(unsigned int)mode;
- (void)updateRepeatUI;

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
- (void)seekBackward:(unsigned int)indexOfValue;
- (void)seekForward:(unsigned int)indexOfValue;
- (void)stepBackward;
- (void)stepForward;

- (void)updateTimeUI;
- (void)updatePlayUI;
- (void)setPlayRate:(float)rate;
- (void)setSeekInterval:(float)interval atIndex:(unsigned int)index;

- (IBAction)playAction:(id)sender;
- (IBAction)seekAction:(id)sender;
- (IBAction)rangeRepeatAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Video)

- (void)resizeWithMagnification:(float)magnification;
- (void)resizeToScreen;

- (int)aspectRatio;
- (void)setAspectRatio:(int)aspectRatio;
- (void)updateAspectRatioMenu;

- (BOOL)isFullScreen;
- (void)beginFullScreen;
- (void)endFullScreen;
- (void)setFullScreenFill:(int)fill forWideMovie:(BOOL)forWideMovie;
- (void)setFullScreenFill:(int)fill;
- (void)setFullScreenUnderScan:(float)underScan;
- (void)updateFullScreenFillMenu;

- (IBAction)movieSizeAction:(id)sender;
- (IBAction)fullScreenAction:(id)sender;
- (IBAction)fullScreenFillAction:(id)sender;
- (IBAction)fullScreenUnderScanAction:(id)sender;
- (IBAction)aspectRatioAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Audio)

- (void)volumeUp;
- (void)volumeDown;
- (void)setVolume:(float)volume;
- (void)setMuted:(BOOL)muted;
- (void)updateVolumeUI;

- (void)setAudioTrackAtIndex:(unsigned int)index enabled:(BOOL)enabled;
- (void)autoenableAudioTracks;
- (void)updateAudioTrackMenu;

- (IBAction)volumeAction:(id)sender;
- (IBAction)muteAction:(id)sender;
- (IBAction)audioTrackAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Subtitle)

- (void)setSubtitleEnable:(BOOL)enable;

- (void)setSubtitleFontSize:(float)size;
- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox;
- (void)setMinLetterBoxHeight:(float)minLetterBoxHeight;
- (void)setSubtitleHMargin:(float)hMargin;
- (void)setSubtitleVMargin:(float)vMargin;

- (void)setSubtitle:(MSubtitle*)subtitle enabled:(BOOL)enabled;
- (void)setSubtitleSync:(float)sync;
- (void)updateSubtitleLanguageMenu;

- (IBAction)subtitleVisibleAction:(id)sender;
- (IBAction)subtitleLanguageAction:(id)sender;
- (IBAction)subtitleFontSizeAction:(id)sender;
- (IBAction)subtitleVMarginAction:(id)sender;
- (IBAction)subtitleLetterBoxHeightAction:(id)sender;
- (IBAction)subtitleDisplayOnLetterBoxAction:(id)sender;
- (IBAction)subtitleSyncAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////

@interface AppController (Remote)

- (void)initRemoteControl;
- (void)cleanupRemoteControl;

- (void)startRemoteControl;
- (void)stopRemoteControl;

- (void)appleRemotePlus:(BOOL)pressed;
- (void)appleRemotePlusHold;
- (void)appleRemoteMinus:(BOOL)pressed;
- (void)appleRemoteMinusHold;
- (void)appleRemoteLeft:(BOOL)pressed;
- (void)appleRemoteLeftHold;
- (void)appleRemoteRight:(BOOL)pressed;
- (void)appleRemoteRightHold;
- (void)appleRemotePlay:(BOOL)pressed;
- (void)appleRemotePlayHold;
- (void)appleRemoteMenu:(BOOL)pressed;
- (void)appleRemoteMenuHold;

@end

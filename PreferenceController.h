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

@class AppController;
@class MainWindow;
@class MMovieView;

@interface PreferenceController : NSWindowController
{
    // general
    IBOutlet NSView* _generalPane;
    IBOutlet NSButton* _autodetectMovieSeriesButton;
    IBOutlet NSButton* _autoFullScreenButton;
    IBOutlet NSButton* _autoPlayOnFullScreenButton;
    IBOutlet NSButton* _alwaysOnTopButton;
    IBOutlet NSButton* _deactivateScreenSaverButton;
    IBOutlet NSButton* _quitWhenWindowCloseButton;
    IBOutlet NSButton* _rememberLastPlayButton;
    IBOutlet NSButton* _supportAppleRemoteButton;
    IBOutlet NSButton* _fullNavUseButton;
    IBOutlet NSButton* _showiTunesMoviesButton;
    IBOutlet NSButton* _showiTunesPodcastsButton;
    IBOutlet NSButton* _showiTunesTVShowsButton;
    IBOutlet NSButton* _fullNavOnStartupButton;
    IBOutlet NSTextField* _seekInterval0TextField;
    IBOutlet NSTextField* _seekInterval1TextField;
    IBOutlet NSTextField* _seekInterval2TextField;
    IBOutlet NSStepper* _seekInterval0Stepper;
    IBOutlet NSStepper* _seekInterval1Stepper;
    IBOutlet NSStepper* _seekInterval2Stepper;
    
    // video
    IBOutlet NSView* _videoPane;
    IBOutlet NSPopUpButton* _fullScreenEffectPopUpButton;
    IBOutlet NSPopUpButton* _fullScreenFillForWideMoviePopUpButton;
    IBOutlet NSPopUpButton* _fullScreenFillForStdMoviePopUpButton;
    IBOutlet NSSlider* _fullScreenUnderScanSlider;

    // audio
    IBOutlet NSView* _audioPane;
    IBOutlet NSButton* _autodetectDigitalAudioOutButton;
    IBOutlet NSButton* _updateSystemVolumeButton;

    // subtitle
    IBOutlet NSView* _subtitlePane;
    IBOutlet NSButton*      _subtitleEnableButton;
    IBOutlet NSPopUpButton* _subtitleEncodingPopUpButton;
    IBOutlet NSButton*      _subtitleFontButton;
    IBOutlet NSButton*      _subtitleAutoFontSizeButton;
    IBOutlet NSTextField*   _subtitleAutoFontSizeLabelTextField;
    IBOutlet NSTextField*   _subtitleAutoFontSizeTextField;
    IBOutlet NSStepper*     _subtitleAutoFontSizeStepper;
    IBOutlet NSColorWell*   _subtitleTextColorWell;
    IBOutlet NSSlider*      _subtitleTextOpacitySlider;
    IBOutlet NSTextField*   _subtitleTextOpacityTextField;
    IBOutlet NSColorWell*   _subtitleStrokeColorWell;
    IBOutlet NSSlider*      _subtitleStrokeOpacitySlider;
    IBOutlet NSTextField*   _subtitleStrokeOpacityTextField;
    IBOutlet NSSlider*      _subtitleStrokeWidthSlider;
    IBOutlet NSTextField*   _subtitleStrokeWidthTextField;
    IBOutlet NSColorWell*   _subtitleShadowColorWell;
    IBOutlet NSSlider*      _subtitleShadowOpacitySlider;
    IBOutlet NSTextField*   _subtitleShadowOpacityTextField;
    IBOutlet NSSlider*      _subtitleShadowBlurSlider;
    IBOutlet NSTextField*   _subtitleShadowBlurTextField;
    IBOutlet NSSlider*      _subtitleShadowOffsetSlider;
    IBOutlet NSTextField*   _subtitleShadowOffsetTextField;
    IBOutlet NSSlider*      _subtitleShadowDarknessSlider;
    IBOutlet NSTextField*   _subtitleShadowDarknessTextField;
    IBOutlet NSPopUpButton* _subtitlePositionPopUpButton;
    IBOutlet NSSlider*      _subtitleHMarginSlider;
    IBOutlet NSTextField*   _subtitleHMarginTextField;
    IBOutlet NSSlider*      _subtitleVMarginSlider;
    IBOutlet NSTextField*   _subtitleVMarginTextField;
    IBOutlet NSSlider*      _subtitleScreenMarginSlider;
    IBOutlet NSTextField*   _subtitleScreenMarginTextField;
    IBOutlet NSSlider*      _subtitleLineSpacingSlider;
    IBOutlet NSTextField*   _subtitleLineSpacingTextField;
    
    // advanced
    IBOutlet NSView* _advancedPane;
    IBOutlet NSPopUpButton* _updateCheckIntervalPopUpButton;
    IBOutlet NSTextField*   _lastUpdateCheckTimeTextField;
    IBOutlet NSTableView* _fileBindingTableView;
    IBOutlet NSTableView* _codecBindingTableView;
    IBOutlet NSOutlineView* _detailsOutlineView;
    NSArray* _fileExtensions;
    NSArray* _fileExtensionDescriptions;
    NSArray* _bindingApps;
    NSArray* _codecIds;
    NSArray* _detailsCategories;

    NSUserDefaults* _defaults;
    AppController* _appController;
    MainWindow* _mainWindow;
    MMovieView* _movieView;
}

- (id)initWithAppController:(AppController*)appController
                 mainWindow:(MainWindow*)mainWindow;

- (void)selectPaneWithIdentifier:(NSString*)identifier;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark general

@interface PreferenceController (General)

- (void)initGeneralPane;
- (IBAction)autodetectMovieSeriesAction:(id)sender;
- (IBAction)autoFullScreenAction:(id)sender;
- (IBAction)autoPlayOnFullScreenAction:(id)sender;
- (IBAction)alwaysOnTopAction:(id)sender;
- (IBAction)deactivateScreenSaverAction:(id)sender;
- (IBAction)quitWhenWindowCloseAction:(id)sender;
- (IBAction)rememberLastPlayAction:(id)sender;
- (IBAction)supportAppleRemoteAction:(id)sender;
- (IBAction)fullNavUseAction:(id)sender;
- (IBAction)showFullNavItemsAction:(id)sender;
- (IBAction)fullNavOnStartupAction:(id)sender;
- (IBAction)seekIntervalAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark video

@interface PreferenceController (Video)

- (void)initVideoPane;
- (IBAction)fullScreenEffectAction:(id)sender;
- (IBAction)fullScreenFillAction:(id)sender;
- (IBAction)fullScreenUnderScanAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark audio

@interface PreferenceController (Audio)

- (void)initAudioPane;
- (IBAction)autodetectDigitalAudioOutAction:(id)sender;
- (IBAction)updateSystemVolumeAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle

@interface PreferenceController (Subtitle)

- (void)initSubtitlePane;
- (IBAction)subtitleEnbleAction:(id)sender;
- (IBAction)subtitleEncodingAction:(id)sender;
- (IBAction)subtitleFontAction:(id)sender;
- (IBAction)subtitleAutoFontSizeAction:(id)sender;
- (IBAction)subtitleAutoFontSizeCharsAction:(id)sender;
- (IBAction)subtitleAttributesAction:(id)sender;
- (IBAction)subtitlePositionAction:(id)sender;
- (void)initSubtitleEncodingPopUpButton;
- (void)updateSubtitleFontAndSizeUI;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced

@interface PreferenceController (Advanced)

- (void)initAdvancedPane;
- (void)updateLastUpdateCheckTimeTextField;
- (IBAction)updateCheckIntervalAction:(id)sender;
- (IBAction)checkUpdateNowAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced - file binding

@interface PreferenceController (Advanced_FileBinding)

- (void)initFileBinding;

- (int)numberOfRowsInFileBindingTableView;
- (id)objectValueForFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex;
- (void)setObjectValue:(id)object
forFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex;
- (void)willDisplayCell:(id)cell
forFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex;

- (IBAction)fileBindingAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced - codec binding

@interface PreferenceController (Advanced_CodecBinding)

- (void)initCodecBinding;

- (int)numberOfRowsInCodecBindingTableView;
- (id)objectValueForCodecBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex;
- (void)setObjectValue:(id)object
forCodecBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex;

- (IBAction)codecBindingAction:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced - details

@interface PreferenceController (Advanced_Details)

- (void)initDetails;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced - details table-column

@interface AdvancedDetailsTableColumn : NSTableColumn
{
}

@end

//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class AppController;
@class MainWindow;
@class MMovieView;

@interface PreferenceController : NSWindowController
{
    // general
    IBOutlet NSView* _generalPane;
    IBOutlet NSButton* _autoFullScreenButton;
    IBOutlet NSButton* _alwaysOnTopButton;
    IBOutlet NSButton* _activateOnDraggingButton;
    IBOutlet NSButton* _quitWhenWindowCloseButton;
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

    // subtitle
    IBOutlet NSView* _subtitlePane;
    IBOutlet NSButton*      _subtitleEnableButton;
    IBOutlet NSPopUpButton* _subtitleEncodingPopUpButton;
    IBOutlet NSButton*      _subtitleFontButton;
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
    IBOutlet NSButton*      _subtitleDisplayOnLetterBoxButton;
    IBOutlet NSSlider*      _subtitleMinLetterBoxHeightSlider;
    IBOutlet NSTextField*   _subtitleMinLetterBoxHeightTextField;
    IBOutlet NSSlider*      _subtitleHMarginSlider;
    IBOutlet NSTextField*   _subtitleHMarginTextField;
    IBOutlet NSSlider*      _subtitleVMarginSlider;
    IBOutlet NSTextField*   _subtitleVMarginTextField;
    IBOutlet NSButton*      _subtitleReplaceNLWithBRButton;
    
    // advanced
    IBOutlet NSView* _advancedPane;
    IBOutlet NSPopUpButton* _defaultDecoderPopUpButton;
    IBOutlet NSButton* _removeGreenBoxButton;

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
- (IBAction)autoFullScreenAction:(id)sender;
- (IBAction)alwaysOnTopAction:(id)sender;
- (IBAction)activateOnDraggingAction:(id)sender;
- (IBAction)quitWhenWindowCloseAction:(id)sender;
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

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle

@interface PreferenceController (Subtitle)

- (void)initSubtitlePane;
- (IBAction)subtitleEnbleAction:(id)sender;
- (IBAction)subtitleEncodingAction:(id)sender;
- (IBAction)subtitleFontAction:(id)sender;
- (IBAction)subtitleAttributesAction:(id)sender;
- (IBAction)subtitlePositionAction:(id)sender;
- (IBAction)subtitleReplaceNLWithBRAction:(id)sender;
- (void)initSubtitleEncodingPopUpButton;
- (void)updateSubtitleFontButtonUI;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced

@interface PreferenceController (Advanced)

- (void)initAdvancedPane;
- (IBAction)defaultDecoderAction:(id)sender;
- (IBAction)removeGreenBoxAction:(id)sender;

@end

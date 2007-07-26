//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class AppController;
@class MMovieView;

@interface WindowMoveTextField : NSTextField {} @end

@interface ControlPanel : NSPanel
{
    IBOutlet AppController* _appController;
    IBOutlet MMovieView* _movieView;
    IBOutlet NSTabView* _tabView;

    // Video
    IBOutlet NSSlider* _videoBrightnessSlider;
    IBOutlet NSSlider* _videoSaturationSlider;
    IBOutlet NSSlider* _videoContrastSlider;
    IBOutlet NSSlider* _videoHueSlider;

    // Audio

    // Subtitle

    // Playback
    IBOutlet NSSlider* _playbackRateSlider;
}

- (void)showPanel;
- (void)hidePanel;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark video

- (IBAction)videoColorControlsAction:(id)sender;
- (IBAction)videoColorControlsDefaultsAction:(id)sender;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark audio

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle

- (IBAction)subtitleSizeAction:(id)sender;
- (IBAction)subtitleVMarginAction:(id)sender;
- (IBAction)subtitleSyncAction:(id)sender;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback
- (IBAction)playbackRateAction:(id)sender;

@end

//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "ControlPanel.h"

#import "MMovieView.h"
#import "AppController.h"
#import "UserDefaults.h"

@implementation WindowMoveTextField

- (BOOL)mouseDownCanMoveWindow { return TRUE; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation ControlPanel

- (void)awakeFromNib
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_videoBrightnessSlider setMinValue:-1.0];
    [_videoBrightnessSlider setMaxValue:+1.0];
    [_videoBrightnessSlider setFloatValue:0.0];

    [_videoSaturationSlider setMinValue:0.0];
    [_videoSaturationSlider setMaxValue:2.0];
    [_videoSaturationSlider setFloatValue:1.0];

    [_videoContrastSlider setMinValue:0.0];
    [_videoContrastSlider setMaxValue:2.0];
    [_videoContrastSlider setFloatValue:1.0];

    [_videoHueSlider setMinValue:-3.14];
    [_videoHueSlider setMaxValue:+3.14];
    [_videoHueSlider setFloatValue:0.0];

    const float dv = (3.0 - 0.5) / 6;
    [_playbackRateSlider setMinValue:0.5];
    [_playbackRateSlider setMaxValue:3.0];
    [_playbackRateSlider setFloatValue:0.5 + dv * 2];

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* identifier = (NSString*)[defaults objectForKey:MControlTabKey];
    if ([identifier isEqualToString:@""]) {
        [_tabView selectFirstTabViewItem:self];
    }
    else {
        [_tabView selectTabViewItemWithIdentifier:identifier];
    }
}

- (void)orderOut:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* identifier = (NSString*)[[_tabView selectedTabViewItem] identifier];
    [defaults setObject:identifier forKey:MControlTabKey];
    [super orderOut:sender];
}

- (BOOL)canBecomeKeyWindow { return FALSE; }

///////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)showPanel { [self orderFront:self]; }
- (void)hidePanel { [self orderOut:self]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark video

- (IBAction)videoColorControlsAction:(id)sender
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, sender);
    if (sender == _videoBrightnessSlider) {
        [_movieView setBrightness:[sender floatValue]];
        [_movieView setMessage:[NSString localizedStringWithFormat:
            NSLocalizedString(@"Brightness %.1f", nil), [_movieView brightness]]];
    }
    else if (sender == _videoSaturationSlider) {
        [_movieView setSaturation:[sender floatValue]];
        [_movieView setMessage:[NSString localizedStringWithFormat:
            NSLocalizedString(@"Saturation %.1f", nil), [_movieView saturation]]];
    }
    else if (sender == _videoContrastSlider) {
        [_movieView setContrast:[sender floatValue]];
        [_movieView setMessage:[NSString localizedStringWithFormat:
            NSLocalizedString(@"Contrast %.1f", nil), [_movieView contrast]]];
    }
    else if (sender == _videoHueSlider) {
        [_movieView setHue:[sender floatValue]];
        [_movieView setMessage:[NSString localizedStringWithFormat:
            NSLocalizedString(@"Hue %.1f", nil), [_movieView hue]]];
    }
}

- (IBAction)videoColorControlsDefaultsAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    switch ([sender tag]) {
        case 0 :
            [_videoBrightnessSlider setFloatValue:0.0];
            [self videoColorControlsAction:_videoBrightnessSlider];
            break;
        case 1 :
            [_videoSaturationSlider setFloatValue:1.0];
            [self videoColorControlsAction:_videoSaturationSlider];
            break;
        case 2 :
            [_videoContrastSlider setFloatValue:1.0];
            [self videoColorControlsAction:_videoContrastSlider];
            break;
        case 3 :
            [_videoHueSlider setFloatValue:0.0];
            [self videoColorControlsAction:_videoHueSlider];
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark audio

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle

- (IBAction)subtitleSizeAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    float size;
    if ([sender tag] == 0) {    // default
        size = [[NSUserDefaults standardUserDefaults] floatForKey:MSubtitleFontSizeKey];
    }
    else if ([sender tag] < 0) {
        size = [_movieView subtitleFontSize] - 1.0;
        size = MAX(1.0, size);
    }
    else {
        size = [_movieView subtitleFontSize] + 1.0;
        size = MIN(size, 50.0);
    }
    [_movieView setSubtitleFontName:[_movieView subtitleFontName] size:size];

    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Size %.1f", nil), [_movieView subtitleFontSize]]];
}

- (IBAction)subtitleVMarginAction:(id)sender
{
    float margin;
    if ([sender tag] == 0) {    // default
        margin = [[NSUserDefaults standardUserDefaults] floatForKey:MSubtitleVMarginKey];
    }
    else if ([sender tag] < 0) {
        margin = [_movieView subtitleVMargin] - 1.0;
        margin = MAX(0.0, margin);
    }
    else {
        margin = [_movieView subtitleVMargin] + 1.0;
        margin = MIN(margin, 10.0);
    }
    [_appController setSubtitleVMargin:margin];
}

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    if ([sender tag] == 0) {    // default
        [_appController revertSubtitleSync];
    }
    else if ([sender tag] < 0) {// later
        [_appController decreaseSubtitleSync];
    }
    else {                      // earlier
        [_appController increaseSubtitleSync];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (IBAction)playbackRateAction:(id)sender
{
    const float dv = (3.0 - 0.5) / 6;
    if (sender == _playbackRateSlider) {
        float rate;
        float value = [_playbackRateSlider floatValue];
        if (value <= 0.5 + dv * 2) {        // 0.5 ~ 1.0 (2: 0.5, 0.75, 1.0)
            rate = 0.5 + (value - (0.5 + dv * 0)) * ((1.0 - 0.5) / 2) / dv;
        }
        else if (value <= 0.5 + dv * 5) {   // 1.0 ~ 2.0 (3: 1.0, 1.3, 1.6, 2.0)
            rate = 1.0 + (value - (0.5 + dv * 2)) * ((2.0 - 1.0) / 3) / dv;
        }
        else {                              // 2.0 ~ 3.0 (1: 2.0, 3.0)
            rate = 2.0 + (value - (0.5 + dv * 5)) * ((3.0 - 2.0) / 1) / dv;
        }
        [_appController setPlayRate:rate];
    }
    else {
        [_playbackRateSlider setFloatValue:0.5 + dv * 2];
        [_appController setPlayRate:1.0];
    }
}

@end

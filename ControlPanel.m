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

#import "ControlPanel.h"

#import "MMovieView.h"
#import "AppController.h"
#import "UserDefaults.h"
#import "MMovie_QuickTime.h"
#import "MMovie_FFMPEG.h"

@implementation WindowMoveTextField

- (BOOL)mouseDownCanMoveWindow { return TRUE; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation ControlPanel

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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

- (void)setMovieURL:(NSURL*)movieURL
{
    if (!movieURL) {
        [_filenameTextField setStringValue:@""];
    }
    else if ([movieURL isFileURL]) {
        [_filenameTextField setStringValue:[[movieURL path] lastPathComponent]];
    }
    else {
        [_filenameTextField setStringValue:[[movieURL absoluteString] lastPathComponent]];
    }
}

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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (void)setPlayRate:(float)rate
{
    float value;
    const float dv = (3.0 - 0.5) / 6;
    if (rate <= 1.0) {
        value = (0.5 + dv * 0) + (2 * dv * (rate - 0.5)) / (1.0 - 0.5);
    }
    else if (rate <= 2.0) {
        value = (0.5 + dv * 2) + (3 * dv * (rate - 1.0)) / (2.0 - 1.0);
    }
    else {  // rate <= 3.0
        value = (0.5 + dv * 5) + (1 * dv * (rate - 2.0)) / (3.0 - 2.0);
    }
    [_playbackRateSlider setFloatValue:value];
}

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

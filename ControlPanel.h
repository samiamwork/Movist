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

    // Properties
    IBOutlet NSTextField* _filenameTextField;
    IBOutlet NSImageView* _decoderImageView;
}

- (void)showPanel;
- (void)hidePanel;
- (void)setDecoder:(NSString*)decoder;

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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (IBAction)playbackRateAction:(id)sender;

@end

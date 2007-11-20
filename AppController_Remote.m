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
#import "FullScreener.h"

#import "MultiClickRemoteBehavior.h"
#import "RemoteControlContainer.h"
#import "AppleRemote.h"
#import "GlobalKeyboardDevice.h"
#import "KeyspanFrontRowControl.h"

@implementation AppController (Remote)

- (void)initRemoteControl
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _remoteControlBehavior = [[MultiClickRemoteBehavior alloc] init];
    [_remoteControlBehavior setDelegate:self];
    [_remoteControlBehavior setSimulateHoldEvent:TRUE];
    [_remoteControlBehavior setClickCountingEnabled:TRUE];

    _remoteControlContainer = [[RemoteControlContainer alloc] initWithDelegate:self];
    [_remoteControlContainer instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];
    [_remoteControlContainer instantiateAndAddRemoteControlDeviceWithClass:[KeyspanFrontRowControl class]];
    [_remoteControlContainer instantiateAndAddRemoteControlDeviceWithClass:[GlobalKeyboardDevice class]];
    [_remoteControlContainer setOpenInExclusiveMode:TRUE];
    //[self setValue:_remoteControlContainer forKey:@"remoteControl"];	
}

- (void)cleanupRemoteControl
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self stopRemoteControl];
    [_remoteControlContainer release];
    [_remoteControlBehavior release];
}

- (void)startRemoteControl
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_remoteControlContainer startListening:self];
}

- (void)stopRemoteControl
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_remoteControlContainer stopListening:self];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier
         pressedDown:(BOOL)pressed clickCount:(unsigned int)clickCount
{
    TRACE(@"%s pressed=%d, clickCount=%d", __PRETTY_FUNCTION__, pressed, clickCount);
    if (!pressed) {
        return;
    }
    switch (buttonIdentifier) {
        case kRemoteButtonPlus          : [self appleRemotePlusAction:self];        break;
        case kRemoteButtonPlus_Hold     : [self appleRemotePlusHoldAction:self];    break;
        case kRemoteButtonMinus         : [self appleRemoteMinusAction:self];       break;
        case kRemoteButtonMinus_Hold    : [self appleRemoteMinusHoldAction:self];   break;
        case kRemoteButtonLeft          : [self appleRemoteLeftAction:self];        break;
        case kRemoteButtonLeft_Hold     : [self appleRemoteLeftHoldAction:self];    break;
        case kRemoteButtonRight         : [self appleRemoteRightAction:self];       break;
        case kRemoteButtonRight_Hold    : [self appleRemoteRightHoldAction:self];   break;
        case kRemoteButtonPlay          : [self appleRemotePlayAction:self];        break;
        case kRemoteButtonPlay_Hold     : [self appleRemotePlayHoldAction:self];    break;
        case kRemoteButtonMenu          : [self appleRemoteMenuAction:self];        break;			
        case kRemoteButtonMenu_Hold     : [self appleRemoteMenuHoldAction:self];    break;
        case kRemoteControl_Switched    : TRACE(@"AppleRemote Switched");           break;
        default : TRACE(@"Unmapped event for button %d", buttonIdentifier);         break;
    }
}

- (void)sendRemoteButtonEvent:(RemoteControlEventIdentifier)buttonIdentifier
                  pressedDown:(BOOL)pressedDown remoteControl:(RemoteControl*)remoteControl
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self remoteButton:buttonIdentifier pressedDown:pressedDown clickCount:1];
}

- (IBAction)appleRemotePlusAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        [self volumeUp];
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        //[_movieView showVolumeBar];
        [self volumeUp];
    }
    else {                                      // full navigation mode
        [_fullScreener selectUpper];
    }
}

- (IBAction)appleRemotePlusHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemotePlusAction:sender];
}

- (IBAction)appleRemoteMinusAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        [self volumeDown];
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        //[_movieView showVolumeBar];
        [self volumeDown];
    }
    else {                                      // full navigation mode
        [_fullScreener selectLower];
    }
}

- (IBAction)appleRemoteMinusHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteMinusAction:sender];
}

- (void)appleRemoteSeekBackward:(int)seekIndex
{
    if (![self isFullScreen]) {                 // window mode
        [self seekBackward:seekIndex];
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        //[_movieView showSeekBar];
        [self seekBackward:seekIndex];
    }
    else {                                      // full navigation mode
        // do nothing
    }
}

- (void)appleRemoteSeekForward:(int)seekIndex
{
    if (![self isFullScreen]) {                 // window mode
        [self seekForward:seekIndex];
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        //[_movieView showSeekBar];
        [self seekForward:seekIndex];
    }
    else {                                      // full navigation mode
        // do nothing
    }
}

- (IBAction)appleRemoteLeftAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteSeekBackward:0];
}

- (IBAction)appleRemoteLeftHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteSeekBackward:1];
}

- (IBAction)appleRemoteRightAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteSeekForward:0];
}

- (IBAction)appleRemoteRightHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteSeekForward:1];
}

- (IBAction)appleRemotePlayAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        if (!_movie) {
            // go to folder navigation directly
            [self beginFullNavigation];
        }
        else {
            if ([_movie rate] == 0.0) {
                [self beginFullScreen]; // auto full-screen
                [self play];
            }
            else {
                [self pause];
            }
        }
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        [self playAction:self];
    }
    else {                                      // full navigation mode
        [_fullScreener openCurrent];
    }
}

- (IBAction)appleRemotePlayHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
}

- (IBAction)appleRemoteMenuAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self fullScreenAction:sender];
}

- (IBAction)appleRemoteMenuHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        // do nothing
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        // escape to alternative mode
        if ([_fullScreener isNavigatable]) {
            [self endFullScreen];
        }
        else {
            [self beginFullNavigation];
        }
    }
    else {                                      // full navigation mode
        // do nothing
    }
}

@end

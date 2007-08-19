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
    TRACE(@"%s", __PRETTY_FUNCTION__);
    switch (buttonIdentifier) {
        case kRemoteButtonPlus          : [self appleRemotePlus:pressed];   break;
        case kRemoteButtonPlus_Hold     : [self appleRemotePlusHold];       break;
        case kRemoteButtonMinus         : [self appleRemotePlus:pressed];   break;
        case kRemoteButtonMinus_Hold    : [self appleRemoteMinusHold];      break;
        case kRemoteButtonLeft          : [self appleRemoteLeft:pressed];   break;
        case kRemoteButtonLeft_Hold     : [self appleRemoteLeftHold];       break;
        case kRemoteButtonRight         : [self appleRemoteRight:pressed];  break;
        case kRemoteButtonRight_Hold    : [self appleRemoteRightHold];      break;
        case kRemoteButtonPlay          : [self appleRemotePlay:pressed];   break;
        case kRemoteButtonPlay_Hold     : [self appleRemotePlayHold];       break;
        case kRemoteButtonMenu          : [self appleRemoteMenu:pressed];   break;			
        case kRemoteButtonMenu_Hold     : [self appleRemoteMenuHold];       break;
        case kRemoteControl_Switched    : TRACE(@"AppleRemote Switched");   break;
        default : TRACE(@"Unmapped event for button %d", buttonIdentifier); break;
    }
}

- (void)sendRemoteButtonEvent:(RemoteControlEventIdentifier)buttonIdentifier
                  pressedDown:(BOOL)pressedDown remoteControl:(RemoteControl*)remoteControl
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self remoteButton:buttonIdentifier pressedDown:pressedDown clickCount:1];
}

- (void)appleRemotePlus:(BOOL)pressed
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (pressed) {
#if defined(_SUPPORT_FRONT_ROW)
        if ([self isFullScreen]) {
            if ([_fullScreener isNavigationMode]) {
                [_fullScreener selectUpper];
            }
            else {
                [self volumeUp];
                [_movieView showVolumeBar];
            }
        }
        else {
            [self volumeUp];
        }
#else
        [self volumeUp];
#endif
    }
}

- (void)appleRemotePlusHold
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemotePlus:TRUE];
}

- (void)appleRemoteMinus:(BOOL)pressed
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (pressed) {
#if defined(_SUPPORT_FRONT_ROW)
        if ([self isFullScreen]) {
            if ([_fullScreener isNavigationMode]) {
                [_fullScreener selectLower];
            }
            else {
                [self volumeDown];
                [_movieView showVolumeBar];
            }
        }
        else {
            [self volumeDown];
        }
#else
        [self volumeDown];
#endif
    }
}

- (void)appleRemoteMinusHold
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteMinus:TRUE];
}

- (void)appleRemoteSeekBackward:(int)seekIndex
{
#if defined(_SUPPORT_FRONT_ROW)
    if ([self isFullScreen]) {
        if ([_fullScreener isNavigationMode]) {
            // do nothing
        }
        else {
            [self seekBackward:seekIndex];
            [_movieView showSeekBar];
        }
    }
    else {
        [self seekBackward:seekIndex];
    }
#else
    [self seekBackward:seekIndex];
#endif
}

- (void)appleRemoteSeekForward:(int)seekIndex
{
#if defined(_SUPPORT_FRONT_ROW)
    if ([self isFullScreen]) {
        if ([_fullScreener isNavigationMode]) {
            // do nothing
        }
        else {
            [self seekForward:seekIndex];
            [_movieView showSeekBar];
        }
    }
    else {
        [self seekForward:seekIndex];
    }
#else
    [self seekForward:seekIndex];
#endif
}

- (void)appleRemoteLeft:(BOOL)pressed
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (pressed) {
        [self appleRemoteSeekBackward:0];
    }
}

- (void)appleRemoteLeftHold
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteSeekBackward:1];
}

- (void)appleRemoteRight:(BOOL)pressed
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (pressed) {
        [self appleRemoteSeekForward:0];
    }
}

- (void)appleRemoteRightHold
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self appleRemoteSeekForward:1];
}

- (void)appleRemotePlay:(BOOL)pressed
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (pressed) {
#if defined(_SUPPORT_FRONT_ROW)
        if ([self isFullScreen]) {
            if ([_fullScreener isNavigationMode]) {
                [_fullScreener openSelectedItem];
            }
            else {
                [self playAction:self];
            }
        }
        else {
            [self playAction:self];
        }
#else
        [self playAction:self];
#endif
    }
}

- (void)appleRemotePlayHold
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
}

- (void)appleRemoteMenu:(BOOL)pressed
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (pressed) {
#if defined(_SUPPORT_FRONT_ROW)
        if ([self isFullScreen]) {
            [_fullScreener closeCurrent];
        }
        else {
            [self fullScreenAction:self];
        }
#else
        [self fullScreenAction:self];
#endif
    }
}

- (void)appleRemoteMenuHold
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
}

@end

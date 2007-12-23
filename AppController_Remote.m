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

#import "AppleRemote/MultiClickRemoteBehavior.h"
#import "AppleRemote/RemoteControlContainer.h"
#import "AppleRemote/AppleRemote.h"
#import "AppleRemote/GlobalKeyboardDevice.h"
#import "AppleRemote/KeyspanFrontRowControl.h"

#import <IOKit/pwr_mgt/IOPMKeys.h>

@implementation AppController (Remote)

- (void)initRemoteControl
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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

    _remoteControlRepeatTimerLock = [[NSLock alloc] init];
}

- (void)cleanupRemoteControl
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self stopRemoteControl];
    [_remoteControlRepeatTimerLock release];
    [_remoteControlContainer release];
    [_remoteControlBehavior release];
}

- (void)startRemoteControl
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_remoteControlContainer isListeningToRemote]) {
        [_remoteControlContainer startListening:self];
    }
}

- (void)stopRemoteControl
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_remoteControlContainer isListeningToRemote]) {
        [_remoteControlContainer stopListening:self];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)sendRemoteButtonEvent:(RemoteControlEventIdentifier)buttonIdentifier
                  pressedDown:(BOOL)pressedDown remoteControl:(RemoteControl*)remoteControl
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self remoteButton:buttonIdentifier pressedDown:pressedDown clickCount:1];
}

- (void)startRemoteControlRepeatTimer:(NSTimeInterval)interval
{
    [_remoteControlRepeatTimerLock lock];
    [_remoteControlRepeatTimer invalidate];
    _remoteControlRepeatTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                            target:self selector:@selector(remoteControlRepeat:)
                            userInfo:nil repeats:TRUE];
    [_remoteControlRepeatTimerLock unlock];
}

- (void)stopRemoteControlRepeatTimer
{
    [_remoteControlRepeatTimerLock lock];
    if (_remoteControlRepeatTimer) {
        [_remoteControlRepeatTimer invalidate];
        _remoteControlRepeatTimer = nil;
    }
    [_remoteControlRepeatTimerLock unlock];
}

- (void)remoteControlRepeat:(NSTimer*)timer
{
    if (timer && 0.01 < [timer timeInterval]) {
        [self startRemoteControlRepeatTimer:0.01];
    }
    
    switch (_remoteControlRepeatButtonID) {
        case kRemoteButtonPlus      : [self remoteControlPlusAction:self];    break;
        case kRemoteButtonMinus     : [self remoteControlMinusAction:self];   break;
        case kRemoteButtonLeft_Hold : [self remoteControlLeftAction:self];    break;
        case kRemoteButtonRight_Hold: [self remoteControlRightAction:self];   break;
    }
}

- (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier
         pressedDown:(BOOL)pressed clickCount:(unsigned int)clickCount
{
    //TRACE(@"%s pressed=%d, clickCount=%d", __PRETTY_FUNCTION__, pressed, clickCount);
#define _TRACE_APPLE_REMOTE
#if defined(_TRACE_APPLE_REMOTE)
    NSString* button;
    switch (buttonIdentifier) {
        case kRemoteButtonPlus          : button = @"PLUS";         break;
        case kRemoteButtonPlus_Hold     : button = @"PLUS hold";    break;
        case kRemoteButtonMinus         : button = @"MINUS";        break;
        case kRemoteButtonMinus_Hold    : button = @"MINUS hold";   break;
        case kRemoteButtonLeft          : button = @"LEFT";         break;
        case kRemoteButtonLeft_Hold     : button = @"LEFT hold";    break;
        case kRemoteButtonRight         : button = @"RIGHT";        break;
        case kRemoteButtonRight_Hold    : button = @"RIGHT hold";   break;
        case kRemoteButtonPlay          : button = @"PLAY";         break;
        case kRemoteButtonPlay_Hold     : button = @"PLAY hold";    break;
        case kRemoteButtonMenu          : button = @"MENU";         break;
        case kRemoteButtonMenu_Hold     : button = @"MENU hold";    break;
        case kRemoteControl_Switched    : button = @"SWITCHED";     break;
        default : button = [NSString stringWithFormat:@"UNMAPPED[%d]", buttonIdentifier];   break;
    }
    TRACE(@"RemoteControl %@ %@(%d)", button, pressed ? @"pressed" : @"released", clickCount);
#endif  // _TRACE_APPLE_REMOTE

    if (pressed) {
        // pressed only buttons
        switch (buttonIdentifier) {
            case kRemoteButtonLeft      : [self remoteControlLeftAction:self];      break;
            case kRemoteButtonRight     : [self remoteControlRightAction:self];     break;
            case kRemoteButtonPlay      : [self remoteControlPlayAction:self];      break;
            case kRemoteButtonPlay_Hold : [self remoteControlPlayHoldAction:self];  break;
            case kRemoteButtonMenu      : [self remoteControlMenuAction:self];      break;
            case kRemoteButtonMenu_Hold : [self remoteControlMenuHoldAction:self];  break;
        }
    }
    // repeat-needed buttons
    switch (buttonIdentifier) {
        case kRemoteButtonPlus  :
        case kRemoteButtonMinus :
        case kRemoteButtonLeft_Hold :
        case kRemoteButtonRight_Hold :
            if (pressed) {
                _remoteControlRepeatButtonID = buttonIdentifier;
                [self remoteControlRepeat:nil];     // for current event
                [self startRemoteControlRepeatTimer:0.5];
            }
            else {
                [self stopRemoteControlRepeatTimer];
            }
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction)remoteControlPlusAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        [self volumeUp];
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        [self volumeUp];
    }
    else {                                      // full navigation mode
        [_fullScreener selectUpper];
    }
}

- (IBAction)remoteControlMinusAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        [self volumeDown];
    }
    else if (![_fullScreener isNavigating]) {   // full play mode
        [self volumeDown];
    }
    else {                                      // full navigation mode
        [_fullScreener selectLower];
    }
}

- (IBAction)remoteControlLeftAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self seekBackward:0];
}

- (IBAction)remoteControlRightAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self seekForward:0];
}

- (IBAction)remoteControlPlayAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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

- (IBAction)remoteControlPlayHoldAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    /* I don't know how to get a privilege to sleep machine.
    // go to sleep (emulating normal play-hold action)
    NSCalendarDate* date = [NSCalendarDate dateWithTimeIntervalSinceNow:100];
    IOReturn ret = IOPMSchedulePowerEvent((CFDateRef)date, 0, CFSTR(kIOPMAutoSleep));
    if (ret != kIOReturnSuccess) {
        TRACE(@"%s error=0x%x", __PRETTY_FUNCTION__, ret);
    }
     */
    // quit movist as temp-impl.
    [NSApp terminate:self];
}

- (IBAction)remoteControlMenuAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self fullScreenAction:sender];
}

- (IBAction)remoteControlMenuHoldAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isFullScreen]) {                 // window mode
        if (_movie) {
            [self closeMovie];
        }
        [self beginFullNavigation];
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

- (IBAction)remoteControlPlusHoldAction:(id)sender {}     // currently not used
- (IBAction)remoteControlMinusHoldAction:(id)sender {}    // currently not used
- (IBAction)remoteControlLeftHoldAction:(id)sender {}     // currently not used
- (IBAction)remoteControlRightHoldAction:(id)sender {}    // currently not used

@end

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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"
#import "MMovieView.h"
#import "MainWindow.h"

@implementation PreferenceController (General)

- (void)initGeneralPane
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_autoFullScreenButton setState:[_defaults boolForKey:MAutoFullScreenKey]];
    [_alwaysOnTopButton setState:[_defaults boolForKey:MAlwaysOnTopKey]];
    [_activateOnDraggingButton setState:[_defaults boolForKey:MActivateOnDraggingKey]];
    [_quitWhenWindowCloseButton setState:[_defaults boolForKey:MQuitWhenWindowCloseKey]];

    [_seekInterval0TextField setFloatValue:[_defaults floatForKey:MSeekInterval0Key]];
    [_seekInterval1TextField setFloatValue:[_defaults floatForKey:MSeekInterval1Key]];
    [_seekInterval2TextField setFloatValue:[_defaults floatForKey:MSeekInterval2Key]];
    [_seekInterval0Stepper setFloatValue:[_defaults floatForKey:MSeekInterval0Key]];
    [_seekInterval1Stepper setFloatValue:[_defaults floatForKey:MSeekInterval1Key]];
    [_seekInterval2Stepper setFloatValue:[_defaults floatForKey:MSeekInterval2Key]];
}

- (IBAction)autoFullScreenAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setBool:[_autoFullScreenButton state] forKey:MAutoFullScreenKey];
}

- (IBAction)alwaysOnTopAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL alwaysOnTop = [_alwaysOnTopButton state];
    [_defaults setBool:alwaysOnTop forKey:MAlwaysOnTopKey];

    [_mainWindow setAlwaysOnTop:alwaysOnTop];
}

- (IBAction)activateOnDraggingAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL activateOnDragging = [sender state];
    [_defaults setBool:activateOnDragging forKey:MActivateOnDraggingKey];
    [_movieView setActivateOnDragging:activateOnDragging];
}

- (IBAction)quitWhenWindowCloseAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL quitWhenWindowClose = [_quitWhenWindowCloseButton state];
    [_defaults setBool:quitWhenWindowClose forKey:MQuitWhenWindowCloseKey];
    
    [_appController setQuitWhenWindowClose:quitWhenWindowClose];
}

- (IBAction)seekIntervalAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSTextField* textField[3] = {
        _seekInterval0TextField, _seekInterval1TextField, _seekInterval2TextField,
    };
    NSStepper* stepper[3] = {
        _seekInterval0Stepper, _seekInterval1Stepper, _seekInterval2Stepper,
    };
    NSString* key[3] = {
        MSeekInterval0Key, MSeekInterval1Key, MSeekInterval2Key
    };

    int index = [sender tag];
    float interval = [sender floatValue];
    [textField[index] setFloatValue:interval];
    [stepper[index] setFloatValue:interval];
    [_defaults setFloat:interval forKey:key[index]];
    [_appController setSeekInterval:interval atIndex:index];
}

@end

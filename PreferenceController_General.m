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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"
#import "MMovieView.h"
#import "MainWindow.h"

@implementation PreferenceController (General)

- (void)setFullNavShowItemsEnabled:(BOOL)enabled
{
    [_fullNavOnStartupButton setEnabled:enabled];
    [_showiTunesMoviesButton setEnabled:enabled];
    [_showiTunesPodcastsButton setEnabled:enabled];
    [_showiTunesTVShowsButton setEnabled:enabled];
}

- (void)initGeneralPane
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_defaults boolForKey:MAutoFullScreenKey]) {
        [_defaults setBool:FALSE forKey:MDesktopBackgroundKey];
    }
    [_autodetectMovieSeriesButton setState:[_defaults boolForKey:MAutodetectMovieSeriesKey]];
    [_autoFullScreenButton setState:[_defaults boolForKey:MAutoFullScreenKey]];
    [_desktopBackgroundButton setState:[_defaults boolForKey:MDesktopBackgroundKey]];
    [_autoPlayOnFullScreenButton setState:[_defaults boolForKey:MAutoPlayOnFullScreenKey]];
    if ([_defaults boolForKey:MAutoFullScreenKey]) {
        [_desktopBackgroundButton setState:NSOffState];
        [_desktopBackgroundButton setEnabled:FALSE];
    }
    if ([_defaults boolForKey:MDesktopBackgroundKey]) {
        [_autoFullScreenButton setState:NSOffState];
        [_autoFullScreenButton setEnabled:FALSE];
    }

    [_alwaysOnTopButton setState:[_defaults boolForKey:MAlwaysOnTopKey]];
    [_deactivateScreenSaverButton setState:[_defaults boolForKey:MDeactivateScreenSaverKey]];

    [_quitWhenWindowCloseButton setState:[_defaults boolForKey:MQuitWhenWindowCloseKey]];
    [_rememberLastPlayButton setState:[_defaults boolForKey:MRememberLastPlayKey]];

    [_supportAppleRemoteButton setState:[_defaults boolForKey:MSupportAppleRemoteKey]];
    [_fullNavUseButton setState:[_defaults boolForKey:MFullNavUseKey]];
    [_showiTunesMoviesButton setState:[_defaults boolForKey:MFullNavShowiTunesMoviesKey]];
    [_showiTunesPodcastsButton setState:[_defaults boolForKey:MFullNavShowiTunesPodcastsKey]];
    [_showiTunesTVShowsButton setState:[_defaults boolForKey:MFullNavShowiTunesTVShowsKey]];
    [_fullNavOnStartupButton setState:[_defaults boolForKey:MFullNavOnStartupKey]];
    [self setFullNavShowItemsEnabled:[_defaults boolForKey:MFullNavUseKey]];

    [_seekInterval0TextField setFloatValue:[_defaults floatForKey:MSeekInterval0Key]];
    [_seekInterval1TextField setFloatValue:[_defaults floatForKey:MSeekInterval1Key]];
    [_seekInterval2TextField setFloatValue:[_defaults floatForKey:MSeekInterval2Key]];
    [_seekInterval0Stepper setFloatValue:[_defaults floatForKey:MSeekInterval0Key]];
    [_seekInterval1Stepper setFloatValue:[_defaults floatForKey:MSeekInterval1Key]];
    [_seekInterval2Stepper setFloatValue:[_defaults floatForKey:MSeekInterval2Key]];
}

- (IBAction)autodetectMovieSeriesAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL autodetect = [_autodetectMovieSeriesButton state];
    [_defaults setBool:autodetect forKey:MAutodetectMovieSeriesKey];
}

- (IBAction)autoFullScreenAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL autoFullScreen = [_autoFullScreenButton state];
    [_defaults setBool:autoFullScreen forKey:MAutoFullScreenKey];

    [_desktopBackgroundButton setEnabled:!autoFullScreen];
    if (autoFullScreen) {
        if ([_defaults boolForKey:MDesktopBackgroundKey]) {
            [_desktopBackgroundButton setState:NSOffState];
            [self desktopBackgroundAction:self];
        }
    }
}

- (IBAction)desktopBackgroundAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL desktopBackground = [_desktopBackgroundButton state];
    [_defaults setBool:desktopBackground forKey:MDesktopBackgroundKey];

    [_autoFullScreenButton setEnabled:!desktopBackground];
    if (desktopBackground) {
        if ([_defaults boolForKey:MAutoFullScreenKey]) {
            [_autoFullScreenButton setState:NSOffState];
            [self autoFullScreenAction:self];
        }
        [_appController beginDesktopBackground];
    }
    else {
        [_appController endDesktopBackground];
    }
}
             
- (IBAction)autoPlayOnFullScreenAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL autoPlay = [_autoPlayOnFullScreenButton state];
    [_defaults setBool:autoPlay forKey:MAutoPlayOnFullScreenKey];
}

- (IBAction)alwaysOnTopAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL alwaysOnTop = [_alwaysOnTopButton state];
    [_defaults setBool:alwaysOnTop forKey:MAlwaysOnTopKey];

    [_mainWindow setAlwaysOnTop:alwaysOnTop];
}

- (IBAction)deactivateScreenSaverAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL deactivateScreenSaver = [_deactivateScreenSaverButton state];
    [_defaults setBool:deactivateScreenSaver forKey:MDeactivateScreenSaverKey];
}

- (IBAction)quitWhenWindowCloseAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL quitWhenWindowClose = [_quitWhenWindowCloseButton state];
    [_defaults setBool:quitWhenWindowClose forKey:MQuitWhenWindowCloseKey];
}

- (IBAction)rememberLastPlayAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL rememberLastPlay = [_rememberLastPlayButton state];
    [_defaults setBool:rememberLastPlay forKey:MRememberLastPlayKey];
}

- (IBAction)supportAppleRemoteAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL supportAppleRemote = [_supportAppleRemoteButton state];
    [_defaults setBool:supportAppleRemote forKey:MSupportAppleRemoteKey];

    if (supportAppleRemote) {
        [_appController startRemoteControl];
    }
    else {
        [_appController stopRemoteControl];
    }
}

- (IBAction)fullNavUseAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL useFullNav = [_fullNavUseButton state];
    [_defaults setBool:useFullNav forKey:MFullNavUseKey];
    [self setFullNavShowItemsEnabled:useFullNav];
}

- (IBAction)showFullNavItemsAction:(id)sender
{
    NSString* key[] = {
        MFullNavShowiTunesMoviesKey,
        MFullNavShowiTunesPodcastsKey,
        MFullNavShowiTunesTVShowsKey,
    };
    [_defaults setBool:[sender state] forKey:key[[sender tag]]];
}

- (IBAction)fullNavOnStartupAction:(id)sender
{
    [_defaults setBool:[sender state] forKey:MFullNavOnStartupKey];
}

- (IBAction)seekIntervalAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    struct {
        NSTextField* textField;
        NSStepper* stepper;
        NSString* key;
    } seek[] = {
        { _seekInterval0TextField, _seekInterval0Stepper, MSeekInterval0Key },
        { _seekInterval1TextField, _seekInterval1Stepper, MSeekInterval1Key },
        { _seekInterval2TextField, _seekInterval2Stepper, MSeekInterval2Key }
    };
    
    int index = [sender tag];
    float interval = [sender floatValue];
    [seek[index].textField setFloatValue:interval];
    [seek[index].stepper setFloatValue:interval];
    [_defaults setFloat:interval forKey:seek[index].key];
    [_appController setSeekInterval:interval atIndex:index];
}

@end

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

@implementation PreferenceController (Video)

- (void)initVideoPane
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_fullScreenEffectPopUpButton selectItemWithTag:
                        [_defaults integerForKey:MFullScreenEffectKey]];
    [_fullScreenFillForWideMoviePopUpButton selectItemWithTag:
                        [_defaults integerForKey:MFullScreenFillForWideMovieKey]];
    [_fullScreenFillForStdMoviePopUpButton selectItemWithTag:
                        [_defaults integerForKey:MFullScreenFillForStdMovieKey]];
    [_fullScreenUnderScanSlider setFloatValue:
                        [_defaults floatForKey:MFullScreenUnderScanKey]];
    [_blackoutSecondaryScreensButton setState:
                        [_defaults boolForKey:MBlackoutSecondaryScreenKey]];
}

- (IBAction)fullScreenEffectAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setInteger:[[sender selectedItem] tag] forKey:MFullScreenEffectKey];
}

- (IBAction)fullScreenFillAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int fill = [[sender selectedItem] tag];
    if ([sender tag] == 0) {
        [_defaults setInteger:fill forKey:MFullScreenFillForWideMovieKey];
        [_appController setFullScreenFill:fill forWideMovie:TRUE];
    }
    else {
        [_defaults setInteger:fill forKey:MFullScreenFillForStdMovieKey];
        [_appController setFullScreenFill:fill forWideMovie:FALSE];
    }
}

- (IBAction)fullScreenUnderScanAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    float underScan = [_fullScreenUnderScanSlider floatValue];
    underScan = (float)(int)(underScan * 10) / 10;   // make "x.x"
    [_defaults setFloat:underScan forKey:MFullScreenUnderScanKey];
    [_appController setFullScreenUnderScan:underScan];
}

- (IBAction)blackoutSecondaryScreensAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL blackoutSecondaryScreens = [_blackoutSecondaryScreensButton state];
    [_defaults setBool:blackoutSecondaryScreens forKey:MBlackoutSecondaryScreenKey];
}

@end

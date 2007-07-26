//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"

@implementation PreferenceController (Video)

- (void)initVideoPane
{
    TRACE(@"%s", __PRETTY_FUNCTION__);

    [_fullScreenEffectPopUpButton selectItemWithTag:
                        [_defaults integerForKey:MFullScreenEffectKey]];
    [_fullScreenFillForWideMoviePopUpButton selectItemWithTag:
                        [_defaults integerForKey:MFullScreenFillForWideMovieKey]];
    [_fullScreenFillForStdMoviePopUpButton selectItemWithTag:
                        [_defaults integerForKey:MFullScreenFillForStdMovieKey]];
    [_fullScreenUnderScanSlider setFloatValue:
                        [_defaults floatForKey:MFullScreenUnderScanKey]];
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

@end

//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "MMovieView.h"

@implementation PreferenceController (Advanced)

- (void)initAdvancedPane
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
#if defined(_SUPPORT_FFMPEG)
    [_defaultDecoderPopUpButton selectItemWithTag:[_defaults integerForKey:MDefaultDecoderKey]];
#else
    [_defaultDecoderPopUpButton selectItemWithTag:DECODER_QUICKTIME];   // always!
    [_defaultDecoderPopUpButton setEnabled:FALSE];
#endif
    [_removeGreenBoxButton setState:[_defaults boolForKey:MRemoveGreenBoxKey]];
}

- (IBAction)defaultDecoderAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setInteger:[[sender selectedItem] tag] forKey:MDefaultDecoderKey];
}

- (IBAction)removeGreenBoxAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL remove = [sender state];
    [_defaults setBool:remove forKey:MRemoveGreenBoxKey];
    [_movieView setRemoveGreenBox:remove];
}

@end

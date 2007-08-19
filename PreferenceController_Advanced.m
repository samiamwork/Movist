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

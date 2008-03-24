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

#import "MMovie.h"

@implementation PreferenceController (Advanced_FileBinding)

- (void)initFileBinding
{
    _fileExtensions = [[MMovie movieFileExtensions] retain];
}

- (int)numberOfRowsInFileBindingTableView { return [_fileExtensions count]; }

- (id)objectValueForFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    if ([[tableColumn identifier] isEqualToString:@"extension"]) {
        return [NSString stringWithFormat:@".%@",
                [_fileExtensions objectAtIndex:rowIndex]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"desc"]) {
        NSString* ext = [_fileExtensions objectAtIndex:rowIndex];
        NSString* desc = [NSString stringWithFormat:@"%@ DESC.", ext];
        return NSLocalizedString(desc, nil);
    }
    else {  // @"application"
        return @"applicatoin";  // FIXME
    }
}

- (void)setObjectValue:(id)object
forFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
}

- (IBAction)fileBindingAction:(id)sender
{
}
@end

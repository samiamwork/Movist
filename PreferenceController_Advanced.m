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

@implementation PreferenceController (Advanced)

- (void)initAdvancedPane
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_updateCheckIntervalPopUpButton selectItemWithTag:[_defaults integerForKey:MUpdateCheckIntervalKey]];

    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    [_lastUpdateCheckTimeTextField setFormatter:formatter];
    [self updateLastUpdateCheckTimeTextField];

    NSTabView* tabView = (NSTabView*)[[_advancedPane subviews] objectAtIndex:0];
    NSString* identifier = (NSString*)[_defaults objectForKey:MPrefsAdvancedTabKey];
    if (NSNotFound == [tabView indexOfTabViewItemWithIdentifier:identifier]) {
        [tabView selectFirstTabViewItem:self];
    }
    else {
        [tabView selectTabViewItemWithIdentifier:identifier];
    }

//#define _SUPPORT_FILE_BINDING
#if defined(_SUPPORT_FILE_BINDING)
    [self initFileBinding];
#else
    [tabView removeTabViewItem:[tabView tabViewItemAtIndex:1]];
#endif
    [self initCodecBinding];
    [self initDetails];
}

- (void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
    [_defaults setObject:[tabViewItem identifier] forKey:MPrefsAdvancedTabKey];
}

- (void)updateLastUpdateCheckTimeTextField
{
    [_lastUpdateCheckTimeTextField setObjectValue:[_defaults objectForKey:MLastUpdateCheckTimeKey]];
}

- (IBAction)updateCheckIntervalAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setInteger:[[sender selectedItem] tag] forKey:MUpdateCheckIntervalKey];
}

- (IBAction)checkUpdateNowAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp delegate] checkForUpdates:TRUE];    // manual checking
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark file & codec binding

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    if (tableView == _fileBindingTableView) {
        return [self numberOfRowsInFileBindingTableView];
    }
    else {
        return [self numberOfRowsInCodecBindingTableView];
    }
}

- (id)tableView:(NSTableView*)tableView
objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    if (tableView == _fileBindingTableView) {
        return [self objectValueForFileBindingTableColumn:tableColumn row:rowIndex];
    }
    else {
        return [self objectValueForCodecBindingTableColumn:tableColumn row:rowIndex];
    }
}

- (void)tableView:(NSTableView*)tableView
   setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    if (tableView == _fileBindingTableView) {
        [self setObjectValue:object forFileBindingTableColumn:tableColumn row:rowIndex];
    }
    else {
        [self setObjectValue:object forCodecBindingTableColumn:tableColumn row:rowIndex];
    }
}

- (void)tableView:(NSTableView*)tableView willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    if (tableView == _fileBindingTableView) {
        [self willDisplayCell:cell forFileBindingTableColumn:tableColumn row:rowIndex];
    }
}

@end

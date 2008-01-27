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

@implementation PreferenceController (Advanced)

- (void)initAdvancedPane
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaultDecoderPopUpButton selectItemWithTag:[_defaults integerForKey:MDefaultDecoderKey]];

    [_updateCheckIntervalPopUpButton selectItemWithTag:[_defaults integerForKey:MUpdateCheckIntervalKey]];

    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    [_lastUpdateCheckTimeTextField setFormatter:formatter];
    [self updateLastUpdateCheckTimeTextField];

    [_detailsTableView reloadData];
}

- (void)updateLastUpdateCheckTimeTextField
{
    [_lastUpdateCheckTimeTextField setObjectValue:[_defaults objectForKey:MLastUpdateCheckTimeKey]];
}

- (IBAction)defaultDecoderAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setInteger:[[sender selectedItem] tag] forKey:MDefaultDecoderKey];
    [[NSApp delegate] updateDecoderUI];
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
#pragma mark details

#define DETAILS_BOOL(key)       [NSNumber numberWithBool:[_defaults boolForKey:key]]
#define DETAILS_SET_BOOL(key)   [_defaults setBool:[(NSNumber*)object boolValue] forKey:key]

enum {
    ACTIVATE_ON_DRAGGING,
    DISABLE_PERIAN_SUBTITLE,
    SHOW_ACTUAL_PATH_FOR_LINK,
    CAPTURE_INCULDING_LETTER_BOX,

    MAX_ADVANCED_DETAILS_COUNT
};

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    return MAX_ADVANCED_DETAILS_COUNT;
}

- (id)tableView:(NSTableView*)tableView
    objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    //TRACE(@"%s %@:%d", __PRETTY_FUNCTION__, [tableColumn identifier], rowIndex);
    NSString* identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"setting"]) {
        switch (rowIndex) {
            case ACTIVATE_ON_DRAGGING :
                return NSLocalizedString(@"Activate on Dragging over Main Window", nil);
            case DISABLE_PERIAN_SUBTITLE :
                return NSLocalizedString(@"Disable Perian Subtitle for using QuickTime *", nil);
            case SHOW_ACTUAL_PATH_FOR_LINK :
                return NSLocalizedString(@"Show Actual Path for Alias or Symbolic-Link", nil);
            case CAPTURE_INCULDING_LETTER_BOX :
                return NSLocalizedString(@"Capture Screenshot Including Letter Box", nil);
        }
    }
    else {  // if ([identifier isEqualToString:@"value"]) {
        switch (rowIndex) {
            case ACTIVATE_ON_DRAGGING :
                return DETAILS_BOOL(MActivateOnDraggingKey);
            case DISABLE_PERIAN_SUBTITLE :
                return DETAILS_BOOL(MDisablePerianSubtitleKey);
            case SHOW_ACTUAL_PATH_FOR_LINK :
                return DETAILS_BOOL(MShowActualPathForLinkKey);
            case CAPTURE_INCULDING_LETTER_BOX :
                return DETAILS_BOOL(MCaptureIncludingLetterBoxKey);
        }
    }
    return nil;
}

- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object
   forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    TRACE(@"%s column=%@ row=%d value=%@", __PRETTY_FUNCTION__,
          [tableColumn identifier], rowIndex, object);
    switch (rowIndex) {
        case ACTIVATE_ON_DRAGGING :
            DETAILS_SET_BOOL(MActivateOnDraggingKey);
            [_movieView setActivateOnDragging:
                            [_defaults boolForKey:MActivateOnDraggingKey]];
            break;
        case DISABLE_PERIAN_SUBTITLE :
            DETAILS_SET_BOOL(MDisablePerianSubtitleKey);
            break;
        case SHOW_ACTUAL_PATH_FOR_LINK :
            DETAILS_SET_BOOL(MShowActualPathForLinkKey);
            break;
        case CAPTURE_INCULDING_LETTER_BOX :
            DETAILS_SET_BOOL(MCaptureIncludingLetterBoxKey);
            [[NSApp delegate] setCaptureIncludingLetterBox:
                        [_defaults boolForKey:MCaptureIncludingLetterBoxKey]];
            break;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced-details table-column

@implementation AdvancedDetailsTableColumn

- (NSTextFieldCell*)textFieldCell
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    return [cell autorelease];
}

- (NSButtonCell*)checkButtonCell
{
    NSButtonCell* cell = [[NSButtonCell alloc] initTextCell:@""];
    [cell setButtonType:NSSwitchButton];
    [cell setControlSize:NSSmallControlSize];
    return [cell autorelease];
}

- (id)dataCellForRow:(int)rowIndex
{
    if ([[self identifier] isEqualToString:@"setting"]) {
        return [self textFieldCell];
    }
    else {  // if ([[self identifier] isEqualToString:@"value"]) {
        return [self checkButtonCell];  // currently all switchtes
    }
    return [super dataCellForRow:rowIndex];
}

@end

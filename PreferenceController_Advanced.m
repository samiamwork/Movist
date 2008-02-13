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
    [_detailsTableView setAction:@selector(detailsTableViewAction:)];
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
    AUTODETECT_DIGITAL_AUDIO_OUT,
    DEFAULT_LANGUAGE_IDENTIFIERS,
    AUTODETECT_MOVIE_SERIES,

    MAX_ADVANCED_DETAILS_COUNT
};

- (int)numberOfRowsInTableView:(NSTableView*)tableView { return MAX_ADVANCED_DETAILS_COUNT; }

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
                return [NSLocalizedString(@"Disable Perian Subtitle for using QuickTime", nil)
                        stringByAppendingString:@" *"];
            case SHOW_ACTUAL_PATH_FOR_LINK :
                return NSLocalizedString(@"Show Actual Path for Alias or Symbolic-Link", nil);
            case CAPTURE_INCULDING_LETTER_BOX :
                return NSLocalizedString(@"Capture Screenshot Including Letter Box", nil);
            case AUTODETECT_DIGITAL_AUDIO_OUT :
                return [NSLocalizedString(@"Auto-detect Digital Audio-Out", nil)
                        stringByAppendingString:@" *"];
            case DEFAULT_LANGUAGE_IDENTIFIERS :
                return NSLocalizedString(@"Default Subtitle Language Identifiers for SAMI", nil);
            case AUTODETECT_MOVIE_SERIES :
                return NSLocalizedString(@"Add Similar Files to Playlist for Opening File", nil);
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
            case AUTODETECT_DIGITAL_AUDIO_OUT :
                return DETAILS_BOOL(MAutodetectDigitalAudioOutKey);
            case DEFAULT_LANGUAGE_IDENTIFIERS :
                return [_defaults stringForKey:MDefaultLanguageIdentifiersKey];
            case AUTODETECT_MOVIE_SERIES :
                return DETAILS_BOOL(MAutodetectMovieSeriesKey);
        }
    }
    return nil;
}

- (void)tableView:(NSTableView*)tableView
   setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    //TRACE(@"%s column=%@ row=%d value=%@", __PRETTY_FUNCTION__,
    //      [tableColumn identifier], rowIndex, object);
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
        case AUTODETECT_DIGITAL_AUDIO_OUT :
            DETAILS_SET_BOOL(MAutodetectDigitalAudioOutKey);
            [[NSApp delegate] updateDigitalAudio];
            break;
        case DEFAULT_LANGUAGE_IDENTIFIERS :
            [_defaults setObject:object forKey:MDefaultLanguageIdentifiersKey];
            break;
        case AUTODETECT_MOVIE_SERIES :
            DETAILS_SET_BOOL(MAutodetectMovieSeriesKey);
            break;
    }
}

- (void)detailsTableViewAction:(id)sender
{
    //TRACE(@"%s column=%d, row=%d", __PRETTY_FUNCTION__,
    //      [_detailsTableView clickedColumn], [_detailsTableView clickedRow]);
    if ([_detailsTableView clickedColumn] == 1) {   // "value" column
        [_detailsTableView editColumn:[_detailsTableView clickedColumn]
                                  row:[_detailsTableView clickedRow]
                            withEvent:nil select:TRUE];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced-details table-column

@implementation AdvancedDetailsTableColumn

- (NSTextFieldCell*)textFieldCellWithEditable:(BOOL)editable
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:editable];
    return [cell autorelease];
}
- (NSTextFieldCell*)textFieldCell { return [self textFieldCellWithEditable:FALSE]; }
- (NSTextFieldCell*)editFieldCell { return [self textFieldCellWithEditable:TRUE]; }

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
        switch (rowIndex) {
            case ACTIVATE_ON_DRAGGING           : return [self checkButtonCell];
            case DISABLE_PERIAN_SUBTITLE        : return [self checkButtonCell];
            case SHOW_ACTUAL_PATH_FOR_LINK      : return [self checkButtonCell];
            case CAPTURE_INCULDING_LETTER_BOX   : return [self checkButtonCell];
            case AUTODETECT_DIGITAL_AUDIO_OUT   : return [self checkButtonCell];
            case DEFAULT_LANGUAGE_IDENTIFIERS   : return [self editFieldCell];
            case AUTODETECT_MOVIE_SERIES        : return [self checkButtonCell];
        }
    }
    return [super dataCellForRow:rowIndex];
}

@end

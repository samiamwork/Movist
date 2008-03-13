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

    [self initDetailsUI];
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

- (NSTextFieldCell*)textFieldCellWithEditable:(BOOL)editable
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:editable];
    return [cell autorelease];
}
- (NSTextFieldCell*)textFieldCell { return [self textFieldCellWithEditable:FALSE]; }
- (NSTextFieldCell*)editFieldCell { return [self textFieldCellWithEditable:TRUE]; }
/*
- (NSButtonCell*)pushButtonCell
{
    NSButtonCell* cell = [[NSButtonCell alloc] initTextCell:@""];
    [cell setButtonType:NSMomentaryLightButton];
    [cell setControlSize:NSSmallControlSize];
    return [cell autorelease];
}
 */
- (NSButtonCell*)checkButtonCell
{
    NSButtonCell* cell = [[NSButtonCell alloc] initTextCell:@""];
    [cell setButtonType:NSSwitchButton];
    [cell setControlSize:NSSmallControlSize];
    return [cell autorelease];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

enum {
    CATEGORY_GENERAL = 100,
        ACTIVATE_ON_DRAGGING,
        AUTODETECT_MOVIE_SERIES,
        AUTODETECT_DIGITAL_AUDIO_OUT,
        AUTO_PLAY_ON_FULL_SCREEN,
        CAPTURE_INCULDING_LETTER_BOX,
        CATEGORY_GENERAL_LAST,
        CATEGORY_GENERAL_COUNT = CATEGORY_GENERAL_LAST - CATEGORY_GENERAL - 1,

    CATEGORY_SUBTITLE = 200,
        DISABLE_PERIAN_SUBTITLE,
        SAMI_REPLACE_NL_WITH_BR,
        SAMI_DEFAULT_LANGUAGE,
        CATEGORY_SUBTITLE_LAST,
        CATEGORY_SUBTITLE_COUNT = CATEGORY_SUBTITLE_LAST - CATEGORY_SUBTITLE - 1,

    CATEGORY_FULL_NAV = 300,
        DEFAULT_NAV_PATH,
        SHOW_ITUNES_MOVIES,
        SHOW_ITUNES_TV_SHOWS,
        SHOW_ITUNES_PODCAST,
        SHOW_ACTUAL_PATH_FOR_LINK,
        CATEGORY_FULL_NAV_LAST,
        CATEGORY_FULL_NAV_COUNT = CATEGORY_FULL_NAV_LAST - CATEGORY_FULL_NAV - 1,

    CATEGORY_COUNT = 3,
};

#define IS_CATEGORY_ID(index)           (((index) % 100) == 0)
#define IS_CATEGORY_ITEM(item)          IS_CATEGORY_ID([item intValue])
#define CATEGORY_ID(subIndex)           ((subIndex + 1) * 100)
#define CATEGORY_SUB_ID(item, subIndex) ([item intValue] + subIndex + 1)

- (void)initDetailsUI
{
    _detailsArray = [[NSMutableArray alloc]
                        initWithCapacity:CATEGORY_COUNT +
                                         CATEGORY_GENERAL_COUNT +
                                         CATEGORY_SUBTITLE_COUNT +
                                         CATEGORY_FULL_NAV_COUNT];

#define INIT_CATEGORY(startID, lastID)  \
    for (i = startID; i < lastID; i++) {    \
        [_detailsArray addObject:[NSNumber numberWithInt:i]];   \
    }
    int i;
    INIT_CATEGORY(CATEGORY_GENERAL,  CATEGORY_GENERAL_LAST)
    INIT_CATEGORY(CATEGORY_SUBTITLE, CATEGORY_SUBTITLE_LAST)
    INIT_CATEGORY(CATEGORY_FULL_NAV, CATEGORY_FULL_NAV_LAST)

    [_detailsOutlineView reloadData];
    [_detailsOutlineView setAction:@selector(detailsOutlineViewAction:)];

    if (!isSystemLeopard()) {
        [_detailsOutlineView expandItem:nil expandChildren:TRUE];
    }
    else {
        NSNumber* number;
        NSEnumerator* enumerator = [_detailsArray objectEnumerator];
        while (number = [enumerator nextObject]) {
            if (IS_CATEGORY_ITEM(number)) {
                [_detailsOutlineView expandItem:number];
            }
        }
    }
}

- (int)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item
{
    //TRACE(@"%s item=%@", __PRETTY_FUNCTION__, item);
    if (item == nil) {
        return CATEGORY_COUNT;
    }
    switch ([item intValue]) {
        case CATEGORY_GENERAL  : return CATEGORY_GENERAL_COUNT;
        case CATEGORY_SUBTITLE : return CATEGORY_SUBTITLE_COUNT;
        case CATEGORY_FULL_NAV : return CATEGORY_FULL_NAV_COUNT;
        default                : return -1;
    }
}

- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item
{
    //TRACE(@"%s item=%@", __PRETTY_FUNCTION__, item);
    return (item == nil) ? TRUE : IS_CATEGORY_ITEM(item);
}

- (id)outlineView:(NSOutlineView*)outlineView child:(int)index ofItem:(id)item
{
    //TRACE(@"%s item=%@ child=%d", __PRETTY_FUNCTION__, item, index);
    int childID = (item == nil) ? CATEGORY_ID(index) : CATEGORY_SUB_ID(item, index);

    NSNumber* number;
    NSEnumerator* enumerator = [_detailsArray objectEnumerator];
    while (number = [enumerator nextObject]) {
        if ([number intValue] == childID) {
            return number;
        }
    }
    return nil;
}

- (id)outlineView:(NSOutlineView*)outlineView
   dataCellForRow:(int)rowIndex ofColumn:(NSTableColumn*)tableColumn
{
    int itemID = [[outlineView itemAtRow:rowIndex] intValue];
    switch (itemID) {
        //case CATEGORY_GENERAL :
        case ACTIVATE_ON_DRAGGING           : return [self checkButtonCell];
        case AUTODETECT_MOVIE_SERIES        : return [self checkButtonCell];
        case AUTODETECT_DIGITAL_AUDIO_OUT   : return [self checkButtonCell];
        case AUTO_PLAY_ON_FULL_SCREEN       : return [self checkButtonCell];
        case CAPTURE_INCULDING_LETTER_BOX   : return [self checkButtonCell];
            
        //case CATEGORY_SUBTITLE :
        case DISABLE_PERIAN_SUBTITLE        : return [self checkButtonCell];
        case SAMI_REPLACE_NL_WITH_BR        : return [self checkButtonCell];
        case SAMI_DEFAULT_LANGUAGE          : return [self editFieldCell];
            
        //case CATEGORY_FULL_NAV :
        case DEFAULT_NAV_PATH               : return [self editFieldCell];
        case SHOW_ITUNES_MOVIES             : return [self checkButtonCell];
        case SHOW_ITUNES_TV_SHOWS           : return [self checkButtonCell];
        case SHOW_ITUNES_PODCAST            : return [self checkButtonCell];
        case SHOW_ACTUAL_PATH_FOR_LINK      : return [self checkButtonCell];
    }
    return nil;
}

#define IS_LABEL_COLUMN(column)     [[column identifier] isEqualToString:@"setting"]
#define DETAILS_LABEL(s)            NSLocalizedString(s, nil)
#define DETAILS_LABEL_R(s)          [NSLocalizedString(s, nil) stringByAppendingString:@" *"]

#define DETAILS_BOOL(key)           [NSNumber numberWithBool:[_defaults boolForKey:key]]
#define DETAILS_SET_BOOL(bn, key)   [_defaults setBool:[(NSNumber*)bn boolValue] forKey:key]
#define DETAILS_STRING(key)         [_defaults stringForKey:key]
#define DETAILS_SET_STRING(s, key)  [_defaults setObject:s forKey:key];

- (id)outlineView:(NSOutlineView*)outlineView
    objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
    //TRACE(@"%s column=%@ item=%@", __PRETTY_FUNCTION__, [tableColumn identifier], item);
    switch ([item intValue]) {
        case CATEGORY_GENERAL :
            return (IS_LABEL_COLUMN(tableColumn)) ? DETAILS_LABEL(@"General") : @"";
        case ACTIVATE_ON_DRAGGING :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Activate on Dragging over Main Window") :
                (id)DETAILS_BOOL(MActivateOnDraggingKey);
        case AUTODETECT_MOVIE_SERIES :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Add Similar Files to Playlist for Opening File") :
                (id)DETAILS_BOOL(MAutodetectMovieSeriesKey);
        case AUTODETECT_DIGITAL_AUDIO_OUT :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL_R(@"Auto-detect Digital Audio-Out") :
                (id)DETAILS_BOOL(MAutodetectDigitalAudioOutKey);
        case AUTO_PLAY_ON_FULL_SCREEN :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Auto-Play On Full Screen") :
                (id)DETAILS_BOOL(MAutoPlayOnFullScreenKey);
        case CAPTURE_INCULDING_LETTER_BOX :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Capture Screenshot Including Letter Box") :
                (id)DETAILS_BOOL(MCaptureIncludingLetterBoxKey);

        case CATEGORY_SUBTITLE :
            return (IS_LABEL_COLUMN(tableColumn)) ? DETAILS_LABEL(@"Subtitle") : @"";
        case DISABLE_PERIAN_SUBTITLE :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL_R(@"Disable Perian Subtitle for using QuickTime") :
                (id)DETAILS_BOOL(MDisablePerianSubtitleKey);
        case SAMI_REPLACE_NL_WITH_BR :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Replace New-Line with <BR> for SAMI") :
                (id)DETAILS_BOOL(MSubtitleReplaceNLWithBRKey);
        case SAMI_DEFAULT_LANGUAGE :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Default Subtitle Language Identifiers for SAMI") :
                (id)DETAILS_STRING(MDefaultLanguageIdentifiersKey);

        case CATEGORY_FULL_NAV :
            return (IS_LABEL_COLUMN(tableColumn)) ? DETAILS_LABEL(@"Full Navigation") : @"";
        case DEFAULT_NAV_PATH :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Default Navigation Path") :
                (id)DETAILS_STRING(MFullNavPathKey);
        case SHOW_ITUNES_MOVIES :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Show iTunes Movies") :
                (id)DETAILS_BOOL(MFullNavShowiTunesMoviesKey);
        case SHOW_ITUNES_TV_SHOWS :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Show iTunes TV Shows") :
                (id)DETAILS_BOOL(MFullNavShowiTunesTVShowsKey);
        case SHOW_ITUNES_PODCAST :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Show iTunes Video Podcast") :
                (id)DETAILS_BOOL(MFullNavShowiTunesPodcastKey);
        case SHOW_ACTUAL_PATH_FOR_LINK :
            return (IS_LABEL_COLUMN(tableColumn)) ?
                (id)DETAILS_LABEL(@"Show Actual Path for Alias or Symbolic-Link") :
                (id)DETAILS_BOOL(MShowActualPathForLinkKey);
    }
    return nil;
}

- (void)outlineView:(NSOutlineView*)outlineView
     setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
    //TRACE(@"%s column=%@ item=%@ value=%@", __PRETTY_FUNCTION__, [tableColumn identifier], item, object);
    switch ([item intValue]) {
        // CATEGORY_GENERAL
        case ACTIVATE_ON_DRAGGING :
            DETAILS_SET_BOOL(object, MActivateOnDraggingKey);
            [_movieView setActivateOnDragging:
                [_defaults boolForKey:MActivateOnDraggingKey]];
            break;
        case AUTODETECT_MOVIE_SERIES :
            DETAILS_SET_BOOL(object, MAutodetectMovieSeriesKey);
            break;
        case AUTODETECT_DIGITAL_AUDIO_OUT :
            DETAILS_SET_BOOL(object, MAutodetectDigitalAudioOutKey);
            [[NSApp delegate] updateDigitalAudio];
            break;
        case AUTO_PLAY_ON_FULL_SCREEN :
            DETAILS_SET_BOOL(object, MAutoPlayOnFullScreenKey);
            break;
        case CAPTURE_INCULDING_LETTER_BOX :
            DETAILS_SET_BOOL(object, MCaptureIncludingLetterBoxKey);
            [[NSApp delegate] setCaptureIncludingLetterBox:
                [_defaults boolForKey:MCaptureIncludingLetterBoxKey]];
            break;

        // CATEGORY_SUBTITLE
        case DISABLE_PERIAN_SUBTITLE :
            DETAILS_SET_BOOL(object, MDisablePerianSubtitleKey);
            break;
        case SAMI_REPLACE_NL_WITH_BR :
            DETAILS_SET_BOOL(object, MSubtitleReplaceNLWithBRKey);
            [_appController reopenSubtitle];
            break;
        case SAMI_DEFAULT_LANGUAGE :
            DETAILS_SET_STRING(object, MDefaultLanguageIdentifiersKey);
            break;
            
        // CATEGORY_FULL_NAV
        case DEFAULT_NAV_PATH :
            DETAILS_SET_STRING(object, MFullNavPathKey);
            break;
        case SHOW_ITUNES_MOVIES :
            DETAILS_SET_BOOL(object, MFullNavShowiTunesMoviesKey);
            break;
        case SHOW_ITUNES_TV_SHOWS :
            DETAILS_SET_BOOL(object, MFullNavShowiTunesTVShowsKey);
            break;
        case SHOW_ITUNES_PODCAST :
            DETAILS_SET_BOOL(object, MFullNavShowiTunesPodcastKey);
            break;
        case SHOW_ACTUAL_PATH_FOR_LINK :
            DETAILS_SET_BOOL(object, MShowActualPathForLinkKey);
            break;
    }
}

- (void)detailsOutlineViewAction:(id)sender
{
    //TRACE(@"%s column=%d, row=%d", __PRETTY_FUNCTION__,
    //      [_detailsOutlineView clickedColumn], [_detailsOutlineView clickedRow]);
    if ([_detailsOutlineView clickedColumn] == 1) {   // "value" column
        [_detailsOutlineView editColumn:[_detailsOutlineView clickedColumn]
                                    row:[_detailsOutlineView clickedRow]
                              withEvent:nil select:TRUE];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced-details table-column

@implementation AdvancedDetailsTableColumn

- (id)dataCellForRow:(int)rowIndex
{
    NSOutlineView* outlineView = (NSOutlineView*)[self tableView];
    id cell = [[outlineView delegate] outlineView:outlineView
                                   dataCellForRow:rowIndex ofColumn:self];
    return (cell) ? cell : [super dataCellForRow:rowIndex];
}

@end

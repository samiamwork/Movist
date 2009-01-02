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

#import "PlaylistController.h"

#import "PlaylistCell.h"
#import "Playlist.h"
#import "MMovie.h"
#import "MSubtitle.h"
#import "AppController.h"

#define MPlayingColumnIdentifier   @"playing"
#define MMovieColumnIdentifier     @"movie"

@implementation PlaylistController

- (id)initWithAppController:(AppController*)appController
                   playlist:(Playlist*)playlist
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, playlist);
    if (self = [super initWithWindowNibName:@"Playlist"]) {
        [self setWindowFrameAutosaveName:@"PlaylistPanel"];
        _appController = [appController retain];
        _playlist = [playlist retain];
    }
    return self;
}

- (void)windowDidLoad
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSTableColumn* column;
    column = [_tableView tableColumnWithIdentifier:MPlayingColumnIdentifier];
    [column setDataCell:[[[NSCell alloc] initImageCell:nil] autorelease]];

    column = [_tableView tableColumnWithIdentifier:MMovieColumnIdentifier];
    [column setDataCell:[[[PlaylistMovieCell alloc] init] autorelease]];

    [_tableView setDoubleAction:@selector(playlistItemDoubleClicked:)];
    [_tableView registerForDraggedTypes:MOVIST_DRAG_TYPES];

    [self updateUI];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playlist release];
    [_appController release];
    [[self window] cleanupHUDWindow];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)showWindow:(id)sender
{
    [(NSPanel*)[self window] setFloatingPanel:TRUE];
    [super showWindow:sender];
}

- (void)runSheetForWindow:(NSWindow*)window
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, window);
    [self updateUI];

    [NSApp beginSheet:[self window] modalForWindow:window modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didEndSheet:(NSWindow*)sheet
         returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    //TRACE(@"%s %@ (ret=%d)", __PRETTY_FUNCTION__, sheet, returnCode);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)playlistItemDoubleClicked:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int row = [_tableView clickedRow];
    if (0 <= row && row < [_playlist count]) {
        [_playlist setCurrentItemAtIndex:row];
        if ([_appController openCurrentPlaylistItem]) {
            [_tableView reloadData];    // update current play
            [self closeAction:self];
        }
    }
}

- (void)keyDown:(NSEvent*)event
{
    //TRACE(@"%s \'0x%x\'", __PRETTY_FUNCTION__, [[event characters] characterAtIndex:0]);
    if (![event isARepeat]) {
        unichar key = [[event characters] characterAtIndex:0];
        if (key == NSDeleteCharacter ||     // backward delete
            key == NSDeleteFunctionKey) {   // forward delete
            [self removeAction:self];
        }
    }
}

- (IBAction)addAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:TRUE];
    [panel setCanChooseDirectories:TRUE];
    [panel setAllowsMultipleSelection:TRUE];
    if (NSOKButton == [panel runModalForTypes:nil]) {
        int row = MAX(0, [[_tableView selectedRowIndexes] firstIndex]);
        [_playlist insertFiles:[panel filenames] atIndex:row];
        [self updateUI];

        [_tableView selectRow:row byExtendingSelection:FALSE];
    }
}

- (IBAction)removeAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSIndexSet* indexes = [_tableView selectedRowIndexes];
    if (0 < [indexes count]) {
        int firstRow = [indexes firstIndex];
        [_playlist removeItemsAtIndexes:indexes];
        [self updateUI];

        firstRow = MIN(firstRow, [_playlist count] - 1);
        [_tableView selectRow:firstRow byExtendingSelection:FALSE];
    }
}

- (IBAction)modeAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_appController setRepeatMode:([_playlist repeatMode] + 1) % MAX_REPEAT_MODE];
}

- (IBAction)closeAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([[self window] isSheet]) {
        [[self window] orderOut:self];
        [NSApp endSheet:[self window]];
    }
    else {
        [[self window] performClose:self];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)updateRemoveButton
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL itemSelected = (0 <= [_tableView selectedRow]);
    NSString* imageName = (itemSelected) ? @"PlaylistRemove" : @"PlaylistRemoveDisabled";
    [_removeButton setEnabled:itemSelected];
    [_removeButton setImage:[NSImage imageNamed:imageName]];
}

- (void)updateRepeatUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_modeButton setImage:[NSImage imageNamed:
        ([_playlist repeatMode] == REPEAT_OFF) ? @"RepeatOff" :
        ([_playlist repeatMode] == REPEAT_ONE) ? @"RepeatOne" :
                                                 @"RepeatAll"]];
}

- (void)updateUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_tableView reloadData];
    if ([_playlist currentItem]) {
        int rowIndex = [_playlist indexOfItem:[_playlist currentItem]];
        if (0 <= rowIndex) {
            [_tableView scrollRowToVisible:rowIndex];
        }
    }
    [self updateRemoveButton];
    [self updateRepeatUI];

    [_statusTextField setStringValue:[NSString stringWithFormat:
        NSLocalizedString(@"%d items", nil), [_playlist count]]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark data-source

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [_playlist count];
}

- (float)tableView:(NSTableView*)tableView heightOfRow:(int)rowIndex
{
    PlaylistItem* item = [_playlist itemAtIndex:rowIndex];
    int subtitleURLCount = [[item subtitleURLs] count];
    if (subtitleURLCount <= 1) {
        return [tableView rowHeight];
    }
    else {
        return [tableView rowHeight] / 2 * (1 + subtitleURLCount);
    }
}

- (id)tableView:(NSTableView*)tableView
    objectValueForTableColumn:(NSTableColumn*)tableColumn
            row:(int)rowIndex
{
    //TRACE(@"%s %@ %d", __PRETTY_FUNCTION__, [tableColumn identifier], rowIndex);
    NSString* identifier = [tableColumn identifier];
    PlaylistItem* item = [_playlist itemAtIndex:rowIndex];
    if ([identifier isEqualToString:MPlayingColumnIdentifier]) {
        NSCell* cell = [tableColumn dataCellForRow:rowIndex];
        if (![item isEqualTo:[_playlist currentItem]]) {
            [cell setImage:nil];
        }
        else if (![_appController movie] ||
                 [[_appController movie] rate] == 0.0) {
            [cell setImage:[NSImage imageNamed:@"PlaylistCurrent"]];
        }
        else {
            [cell setImage:[NSImage imageNamed:@"PlaylistPlaying"]];
        }
        return nil;
    }
    else if ([identifier isEqualToString:MMovieColumnIdentifier]) {
        return item;
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark drag-and-drop

- (BOOL)tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes
     toPasteboard:(NSPasteboard*)pboard
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, rowIndexes);
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:MPlaylistItemDataType] owner:self];
    [pboard setData:data forType:MPlaylistItemDataType];
    return TRUE;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    //TRACE(@"%s row=%d, op=%d", __PRETTY_FUNCTION__, row, op);
    NSPasteboard* pboard = [info draggingPasteboard];
    unsigned int dragAction = dragActionFromPasteboard(pboard, FALSE);
    switch (dragAction) {
        case DRAG_ACTION_ADD_FILES :
            if (op == NSTableViewDropAbove) {
                return NSDragOperationCopy;
            }
            break;
        case DRAG_ACTION_REPLACE_SUBTITLE_FILES :
            if (op == NSTableViewDropOn) {
                return NSDragOperationGeneric;
            }
            break;
        case DRAG_ACTION_ADD_SUBTITLE_FILES :
            if (op == NSTableViewDropOn) {
                return NSDragOperationCopy;
            }
            break;
        case DRAG_ACTION_REORDER_PLAYLIST :
            if (op == NSTableViewDropAbove) {
                return NSDragOperationGeneric;
            }
            break;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id<NSDraggingInfo>)info
              row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    //TRACE(@"%s row=%d, op=%d", __PRETTY_FUNCTION__, row, op);
    NSPasteboard* pboard = [info draggingPasteboard];
    unsigned int dragAction = dragActionFromPasteboard(pboard, FALSE);
    switch (dragAction) {
        case DRAG_ACTION_ADD_FILES : {
            NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
            [_playlist insertFiles:filenames atIndex:row];
            [self updateUI];
            return TRUE;
        }
        case DRAG_ACTION_REPLACE_SUBTITLE_FILES : {
            NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
            PlaylistItem* item = [_playlist itemAtIndex:row];
            [item setSubtitleURLs:URLsFromFilenames(filenames)];
            if ([item isEqualTo:[_playlist currentItem]]) {
                [_appController reopenSubtitles];
            }
            [_tableView reloadData];
            return TRUE;
        }
        case DRAG_ACTION_ADD_SUBTITLE_FILES : {
            NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
            PlaylistItem* item = [_playlist itemAtIndex:row];
            [item addSubtitleURLs:URLsFromFilenames(filenames)];
            [_tableView reloadData];
            return TRUE;
        }
        case DRAG_ACTION_REORDER_PLAYLIST : {
            NSData* data = [pboard dataForType:MPlaylistItemDataType];
            NSIndexSet* indexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            int newFirstRow = [_playlist moveItemsAtIndexes:indexes toIndex:row];
            [_tableView reloadData];

            // re-select original selections
            NSRange range = NSMakeRange(newFirstRow, [indexes count]);
            [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:range]
                    byExtendingSelection:FALSE];
            return TRUE;
        }
    }
    return FALSE;
}
/*
- (NSDragOperation)dragOperation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    switch (_dragAction) {
        case DRAG_ACTION_ADD_FILES :
        case DRAG_ACTION_REPLACE_SUBTITLE_FILES :
        case DRAG_ACTION_REORDER_PLAYLIST :
            return NSDragOperationGeneric;
        case DRAG_ACTION_ADD_SUBTITLE_FILES :
            return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSPasteboard* pboard = [sender draggingPasteboard];
    _dragAction = dragActionFromPasteboard(pboard, TRUE);
    return [self dragOperation];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    unsigned int modifierFlags = [[NSApp currentEvent] modifierFlags];
    if (modifierFlags & NSAlternateKeyMask) {
        if (_dragAction == DRAG_ACTION_REPLACE_SUBTITLE_FILE) {
            _dragAction = DRAG_ACTION_ADD_SUBTITLE_FILE;
        }
        else if (_dragAction == DRAG_ACTION_REPLACE_SUBTITLE_URL) {
            _dragAction = DRAG_ACTION_ADD_SUBTITLE_URL;
        }
    }
    return [self dragOperation];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _dragAction = DRAG_ACTION_NONE;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _dragAction = DRAG_ACTION_NONE;
}
*/
////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark delegate

- (void)tableViewSelectionDidChange:(NSTableView*)tableView
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self updateRemoveButton];
}

@end

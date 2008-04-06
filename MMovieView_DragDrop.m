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

#import "MMovieView.h"

#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView (DragDrop)

- (void)setActivateOnDragging:(BOOL)activate
{
    _activateOnDragging = activate;
}

- (NSDragOperation)dragOperation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    switch (_dragAction) {
        case DRAG_ACTION_PLAY_FILES :
        case DRAG_ACTION_PLAY_URL :
            return NSDragOperationGeneric;
        case DRAG_ACTION_ADD_FILES :
        case DRAG_ACTION_ADD_URL :
        case DRAG_ACTION_REPLACE_SUBTITLE_FILE :
        case DRAG_ACTION_REPLACE_SUBTITLE_URL :
            return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([sender draggingSource] == self) {
        return NSDragOperationNone;
    }

    NSPasteboard* pboard = [sender draggingPasteboard];
    _dragAction = dragActionFromPasteboard(pboard, TRUE);
    if (_dragAction == DRAG_ACTION_PLAY_FILES ||
        _dragAction == DRAG_ACTION_PLAY_URL) {
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                target:self selector:@selector(draggingTimerElapsed:)
                                userInfo:nil repeats:FALSE];
    }
    if (_dragAction != DRAG_ACTION_NONE) {
        [self redisplay];
    }
    return [self dragOperation];
}

- (void)draggingTimerElapsed:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_dragAction != DRAG_ACTION_NONE) {
        [[self window] orderFrontRegardless];
        if (_activateOnDragging) {
            [NSApp activateIgnoringOtherApps:TRUE];
        }
    }
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    unsigned int modifierFlags = [[NSApp currentEvent] modifierFlags];
    if (modifierFlags & NSControlKeyMask) {
        if ([[NSApp delegate] playlistWindowVisible]) {
            [[NSApp delegate] hidePlaylistWindow];
        }
        else {
            [[NSApp delegate] showPlaylistWindow];
        }
    }
    else if (modifierFlags & NSAlternateKeyMask) {
        if (_dragAction == DRAG_ACTION_PLAY_FILES) {
            _dragAction = DRAG_ACTION_ADD_FILES;
        }
        else if (_dragAction == DRAG_ACTION_PLAY_URL) {
            _dragAction = DRAG_ACTION_ADD_URL;
        }
    }
    else {
        if (_dragAction == DRAG_ACTION_ADD_FILES) {
            _dragAction = DRAG_ACTION_PLAY_FILES;
        }
        else if (_dragAction == DRAG_ACTION_ADD_URL) {
            _dragAction = DRAG_ACTION_PLAY_URL;
        }
    }
    return [self dragOperation];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _dragAction = DRAG_ACTION_NONE;
    [self redisplay];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return TRUE;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSPasteboard* pboard = [sender draggingPasteboard];
    switch (_dragAction) {
        case DRAG_ACTION_PLAY_FILES :
        case DRAG_ACTION_REPLACE_SUBTITLE_FILE : {
            NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];
            [[NSApp delegate] performSelector:@selector(openFiles:)
                                   withObject:files afterDelay:0.01];
            return TRUE;
        }
        case DRAG_ACTION_ADD_FILES : {
            NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];
            [[NSApp delegate] addFiles:files];
            return TRUE;
        }
        case DRAG_ACTION_ADD_URL : {
            NSURL* movieURL = [NSURL URLFromPasteboard:pboard];
            [[NSApp delegate] addURL:movieURL];
            return TRUE;
        }
        case DRAG_ACTION_REPLACE_SUBTITLE_URL : {
            NSURL* subtitleURL = [NSURL URLFromPasteboard:pboard];
            [[NSApp delegate] performSelector:@selector(openURL:)
                                   withObject:subtitleURL afterDelay:0.01];
            return TRUE;
        }
    }
    return FALSE;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _dragAction = DRAG_ACTION_NONE;
    if ([[NSApp delegate] playlistWindowVisible]) {
        [[NSApp delegate] hidePlaylistWindow];
    }
    [self redisplay];
}

@end

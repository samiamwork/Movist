//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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
    TRACE(@"%s", __PRETTY_FUNCTION__);
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
        [self setNeedsDisplay:TRUE];
    }
    return [self dragOperation];
}

- (void)draggingTimerElapsed:(NSTimer*)timer
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _dragAction = DRAG_ACTION_NONE;
    [self setNeedsDisplay:TRUE];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    return TRUE;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSPasteboard* pboard = [sender draggingPasteboard];
    switch (_dragAction) {
        case DRAG_ACTION_PLAY_FILES :
        case DRAG_ACTION_REPLACE_SUBTITLE_FILE : {
            NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];
            [[NSApp delegate] performSelector:@selector(openFiles:updatePlaylist:)
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
            [[NSApp delegate] performSelector:@selector(openURL:updatePlaylist:)
                                   withObject:subtitleURL afterDelay:0.01];
            return TRUE;
        }
    }
    return FALSE;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _dragAction = DRAG_ACTION_NONE;
    if ([[NSApp delegate] playlistWindowVisible]) {
        [[NSApp delegate] hidePlaylistWindow];
    }
    [self setNeedsDisplay:TRUE];
}

@end

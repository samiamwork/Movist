//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "AppController.h"

#import "Playlist.h"
#import "PlaylistController.h"

#import "MainWindow.h"

@implementation AppController (Playlist)

- (Playlist*)playlist { return _playlist; }

- (void)addFiles:(NSArray*)filenames
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playlist addFiles:filenames];
    [_playlistController updateUI];
}

- (void)addURL:(NSURL*)url
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playlist addURL:url];
    [_playlistController updateUI];
}

- (BOOL)openCurrentPlaylistItem
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    PlaylistItem* item = [_playlist currentItem];
    return [self openMovie:[item movieURL] movieClass:nil
                  subtitle:[item subtitleURL] subtitleEncoding:kCFStringEncodingInvalidId];
}

- (BOOL)openPrevPlaylistItem
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playlist setPrevItem];
    return [self openCurrentPlaylistItem];
}

- (BOOL)openNextPlaylistItem
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playlist setNextItem];
    return [self openCurrentPlaylistItem];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setRepeatMode:(unsigned int)mode
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, mode);
    [_playlist setRepeatMode:mode];
    [self updateRepeatUI];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UI

- (void)updateRepeatUI
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    unsigned int repeatMode = [_playlist repeatMode];
    [_repeatOffMenuItem setState:(repeatMode == REPEAT_OFF)];
    [_repeatAllMenuItem setState:(repeatMode == REPEAT_ALL)];
    [_repeatOneMenuItem setState:(repeatMode == REPEAT_ONE)];
    [_playlistController updateUI];
}

- (BOOL)playlistWindowVisible
{
    return (_playlistController && [[_playlistController window] isVisible]);
}

- (void)showPlaylistWindow
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_playlistController) {
        _playlistController = [[PlaylistController alloc]
                                initWithAppController:self playlist:_playlist];
    }
    if (![self playlistWindowVisible]) {
        [_playlistController updateUI];
        if ([self isFullScreen]) {
            [_playlistController showWindow:self];
        }
        else {
            [_playlistController runSheetForWindow:_mainWindow];
        }
    }
}

- (void)hidePlaylistWindow
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self playlistWindowVisible]) {
        [_playlistController closeAction:self];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)playlistAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self playlistWindowVisible]) {
        [self hidePlaylistWindow];
    }
    else {
        [self showPlaylistWindow];
    }
}

- (IBAction)prevNextMovieAction:(id)sender
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    if ([sender tag] < 0) {
        [self openPrevPlaylistItem];
    }
    else {
        [self openNextPlaylistItem];
    }
}

- (IBAction)repeatAction:(id)sender
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    [self setRepeatMode:[sender tag]];
}

@end

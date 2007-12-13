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

#import "AppController.h"

#import "Playlist.h"
#import "PlaylistController.h"

#import "MainWindow.h"
#import "MMovieView.h"

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
            [[_playlistController window] setDelegate:self];
            [[_playlistController window] makeKeyWindow];
            [_playPanel orderOut:self];
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
    BOOL ret = ([sender tag] < 0) ? [self openPrevPlaylistItem] :
                                    [self openNextPlaylistItem];
    if (!ret) {
        if ([self isFullScreen]) {
            [self endFullScreen];
        }
        [_movieView setMessage:@""];
        [_movieView showLogo];
    }
}

- (IBAction)repeatAction:(id)sender
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    [self setRepeatMode:[sender tag]];
}

@end

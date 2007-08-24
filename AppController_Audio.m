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
#import "UserDefaults.h"

#import "MMovie.h"

@implementation AppController (Audio)

- (void)volumeUp   { [self setVolume:[_volumeSlider floatValue] + 0.1]; }
- (void)volumeDown { [self setVolume:[_volumeSlider floatValue] - 0.1]; }

- (void)setVolume:(float)volume
{
    TRACE(@"%s %f %g", __PRETTY_FUNCTION__, volume, volume);
    if ([_muteButton state] == NSOnState) {
        [self setMuted:FALSE];
    }
    volume = normalizedVolume(MIN(MAX(0.0, volume), MAX_VOLUME));
    [_movie setVolume:volume];
    [_movieView setMessage:[NSString stringWithFormat:
                                NSLocalizedString(@"Volume %.1f", nil), volume]];
    [_defaults setFloat:volume forKey:MVolumeKey];
    [self updateVolumeUI];
}

- (void)setMuted:(BOOL)muted
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, muted);
    [_movie setMuted:muted];
    [_movieView setMessage:(muted) ? NSLocalizedString(@"Mute", nil) :
                                     NSLocalizedString(@"Unmute", nil)];
    [self updateVolumeUI];
}

- (void)updateVolumeUI
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float volume = (_movie) ? [_movie volume] : [_defaults floatForKey:MVolumeKey];
    BOOL muted = (_movie) ? [_movie muted] : FALSE;

    int state = (muted) ? NSOnState : NSOffState;
    if ([_muteMenuItem state] != state) {
        [_muteMenuItem setState:state];
    }
    if ([_muteButton state] != state) {
        [_muteButton setState:state];
        [_panelMuteButton setState:state];
    }
    
    NSImage* mainMuteImage;
    NSImage* panelMuteImage;
    if (muted || volume == 0.0) {
        mainMuteImage  = [NSImage imageNamed:@"MainVolumeMute"];
        panelMuteImage = [NSImage imageNamed:@"FSVolumeMute"];
    }
    else if (volume < MAX_VOLUME * 1 / 3) {
        mainMuteImage  = [NSImage imageNamed:@"MainVolume1"];
        panelMuteImage = [NSImage imageNamed:@"FSVolume1"];
    }
    else if (volume < MAX_VOLUME * 2 / 3) {
        mainMuteImage  = [NSImage imageNamed:@"MainVolume2"];
        panelMuteImage = [NSImage imageNamed:@"FSVolume2"];
    }
    else {
        mainMuteImage  = [NSImage imageNamed:@"MainVolume3"];
        panelMuteImage = [NSImage imageNamed:@"FSVolume3"];
    }
    if ([_muteButton image] != mainMuteImage) {   // need not isEqual:
        [_muteButton setImage:mainMuteImage];
    }
    if ([_panelMuteButton image] != panelMuteImage) {
        [_panelMuteButton setImage:panelMuteImage];
    }
    
    if ([_volumeSlider floatValue] != volume) {
        [_volumeSlider setFloatValue:volume];
        [_panelVolumeSlider setFloatValue:volume];
    }
    if ([_volumeSlider isEnabled] != !muted) {
        [_volumeSlider setEnabled:!muted];
        [_panelVolumeSlider setEnabled:!muted];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setAudioTrackAtIndex:(unsigned int)index enabled:(BOOL)enabled
{
    MTrack* track = (MTrack*)[[_movie audioTracks] objectAtIndex:index];
    [track setEnabled:enabled];

    if (enabled) {
        [_audioTrackIndexSet addIndex:index];
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Sound Track %@ enabled", nil), [track name]]];
    }
    else {
        [_audioTrackIndexSet removeIndex:index];
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Sound Track %@ disabled", nil), [track name]]];
    }
    [self updateAudioTrackMenu];
}

- (void)autoenableAudioTracks
{
    if (0 == [_audioTrackIndexSet count]) {
        // enable the first track by default
        NSArray* tracks = [_movie audioTracks];
        if (0 < [tracks count]) {
            [[tracks objectAtIndex:0] setEnabled:TRUE];
            [_audioTrackIndexSet addIndex:0];
            unsigned int i, count = [tracks count];
            for (i = 1; i < count; i++) {
                [[tracks objectAtIndex:i] setEnabled:FALSE];
            }
        }
    }
    else if (0 < [_audioTrackIndexSet count]) {
        NSArray* tracks = [_movie audioTracks];
        unsigned int i, count = [tracks count];
        for (i = 0; i < count; i++) {
            [[tracks objectAtIndex:i] setEnabled:[_audioTrackIndexSet containsIndex:i]];
        }
        unsigned int lastIndex = [_audioTrackIndexSet lastIndex];
        for (; i <= lastIndex; i++) {
            if ([_audioTrackIndexSet containsIndex:i]) {
                [_audioTrackIndexSet removeIndex:i];
            }
        }
        // if no track is enabled, then enable the first track
        if (0 == [_audioTrackIndexSet count] && 0 < [tracks count]) {
            [[tracks objectAtIndex:0] setEnabled:TRUE];
            [_audioTrackIndexSet addIndex:0];
        }
    }
    [_propertiesView reloadData];
}

- (void)updateAudioTrackMenu
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // remove all items
    while (0 < [_audioTrackMenu numberOfItems]) {
        [_audioTrackMenu removeItemAtIndex:0];
    }
    
    NSArray* tracks = [_movie audioTracks];
    
    NSMenuItem* item;
    if ([tracks count] == 0) {
        item = [_audioTrackMenu
                    addItemWithTitle:NSLocalizedString(@"no audio", nil)
                              action:@selector(audioTrackAction:)
                       keyEquivalent:@""];
        [item setTag:-1];
    }
    else {
        MTrack* track;
        unsigned int i, count = [tracks count];
        for (i = 0; i < count; i++) {
            track = [tracks objectAtIndex:i];
            item = [_audioTrackMenu
                    addItemWithTitle:[track name]
                              action:@selector(audioTrackAction:)
                       keyEquivalent:@""];
            [item setTag:i];
            [item setState:[track isEnabled]];
            [item setKeyEquivalent:[NSString stringWithFormat:@"%d", i + 1]];
            [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
        }
    }
    [_audioTrackMenu update];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)volumeAction:(id)sender
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    if ([sender tag] < 0) {
        [self volumeDown];
    }
    else if (0 < [sender tag]) {
        [self volumeUp];
    }
    else {  // volume slider
        [self setVolume:[sender floatValue]];

        [_volumeSlider setFloatValue:[sender floatValue]];
        [_panelVolumeSlider setFloatValue:[sender floatValue]];
    }
}

- (IBAction)muteAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL muted;
    if ([sender isMemberOfClass:[NSButton class]]) {
        muted = ([sender state] == NSOnState);
    }
    else {  // menu-item
        muted = ([sender state] == NSOffState);
    }
    [self setMuted:muted];
}

- (IBAction)audioTrackAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float rate = [_movie rate];
    [_movie setRate:0.0];

    unsigned int index = [(NSMenuItem*)sender tag];
    NSArray* audioTracks = [_movie audioTracks];
    unsigned int i, count = [audioTracks count];
    for (i = 0; i < count; i++) {
        [[audioTracks objectAtIndex:i] setEnabled:(i == index)];
    }
    [_audioTrackIndexSet removeAllIndexes];
    [_audioTrackIndexSet addIndex:index];

    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Sound Track %@ selected", nil),
        [[audioTracks objectAtIndex:index] name]]];
    [self updateAudioTrackMenu];
    [_propertiesView reloadData];

    [_movie setRate:rate];
}

@end

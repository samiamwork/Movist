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

#import "AppController.h"
#import "UserDefaults.h"

#import "MMovie.h"

#import <CoreAudio/CoreAudio.h>

@implementation AppController (Audio)

// system volume setter/getter implementations are copied & modified
// from http://www.cocoadev.com/index.pl?SoundVolume

- (float)systemVolume
{
    // get device
    AudioDeviceID device;
    UInt32 size = sizeof(device);
    if (noErr != AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                          &size, &device)) {
        TRACE(@"audio-volume error get device");
        return -1;
    }

    // try get master volume (channel 0)
    float volume;
    size = sizeof(volume);
    if (noErr == AudioDeviceGetProperty(device, 0, 0,
                                        kAudioDevicePropertyVolumeScalar,
                                        &size, &volume)) {  //kAudioDevicePropertyVolumeScalarToDecibels
        return normalizedFloat2(adjustToRange(volume, MIN_SYSTEM_VOLUME, MAX_SYSTEM_VOLUME));
    }

    // otherwise, try seperate channels
    UInt32 channels[2];
    size = sizeof(channels);
    if (noErr != AudioDeviceGetProperty(device, 0, 0,
                                        kAudioDevicePropertyPreferredChannelsForStereo,
                                        &size, &channels)) {
        TRACE(@"error getting channel-numbers");
        return -1;
    }

    float volumes[2];
    size = sizeof(float);
    if (noErr != AudioDeviceGetProperty(device, channels[0], 0,
                                        kAudioDevicePropertyVolumeScalar,
                                        &size, &volumes[0])) {
        TRACE(@"error getting volume of channel %d", channels[0]);
        return -1;
    }
    if (noErr != AudioDeviceGetProperty(device, channels[1], 0,
                                        kAudioDevicePropertyVolumeScalar,
                                        &size, &volumes[1])) {
        TRACE(@"error getting volume of channel %d", channels[1]);
        return -1;
    }
    volume = (volumes[0] + volumes[1]) / 2.00;
    return normalizedFloat2(adjustToRange(volume, MIN_SYSTEM_VOLUME, MAX_SYSTEM_VOLUME));
}

- (void)setSystemVolume:(float)volume
{
    volume = normalizedFloat2(adjustToRange(volume, MIN_SYSTEM_VOLUME, MAX_SYSTEM_VOLUME));

    // get default device
    AudioDeviceID device;
    UInt32 size = sizeof(device);
    if (noErr != AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                          &size, &device)) {
        TRACE(@"audio-volume error get device");
        return;
    }

    // try set master-channel (0) volume
    Boolean canset = false;
    size = sizeof(canset);
    if (noErr == AudioDeviceGetPropertyInfo(device, 0, false,
                                            kAudioDevicePropertyVolumeScalar,
                                            &size, &canset) && canset) {
        size = sizeof(volume);
        AudioDeviceSetProperty(device, 0, 0, false,
                               kAudioDevicePropertyVolumeScalar,
                               size, &volume);
        return;
    }

    // else, try seperate channes
    UInt32 channels[2];
    size = sizeof(channels);
    if (noErr != AudioDeviceGetProperty(device, 0, false,
                                        kAudioDevicePropertyPreferredChannelsForStereo,
                                        &size,&channels)) {
        TRACE(@"error getting channel-numbers");
        return;
    }

    // set volume
    size = sizeof(float);
    if (noErr != AudioDeviceSetProperty(device, 0, channels[0], false,
                                        kAudioDevicePropertyVolumeScalar,
                                        size, &volume)) {
        TRACE(@"error setting volume of channel %d", channels[0]);
    }
    if (noErr != AudioDeviceSetProperty(device, 0, channels[1], false,
                                        kAudioDevicePropertyVolumeScalar,
                                        size, &volume)) {
        TRACE(@"error setting volume of channel %d", channels[1]);
    }
}

- (BOOL)isUpdateSystemVolume
{
    if (_checkForAltVolumeChange &&
        ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
        return ![_defaults boolForKey:MUpdateSystemVolumeKey];
    }
    return [_defaults boolForKey:MUpdateSystemVolumeKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)volumeUp
{
    if ([self isUpdateSystemVolume]) {
        [self setVolume:_systemVolume + 0.05];
    }
    else {
        [self setVolume:[_defaults floatForKey:MVolumeKey] + 0.1];
    }
}

- (void)volumeDown
{
    if ([self isUpdateSystemVolume]) {
        [self setVolume:_systemVolume - 0.05];
    }
    else {
        [self setVolume:[_defaults floatForKey:MVolumeKey] - 0.1];
    }
}

- (void)setVolume:(float)volume
{
    //TRACE(@"%s %f %g", __PRETTY_FUNCTION__, volume, volume);
    if ([_muteButton state] == NSOnState) {
        [self setMuted:FALSE];
    }

    if (_audioDeviceSupportsDigital) {
        if ([self isCurrentlyDigitalAudioOut]) {
            [_movie setVolume:DIGITAL_VOLUME];  // always DIGITAL_VOLUME for digital-audio
            [_movieView setMessage:NSLocalizedString(@"Volume cannot be changed in Digital-Out", nil)];
        }
        else if ([self isUpdateSystemVolume]) {
            [_movieView setMessage:NSLocalizedString(@"System Volume cannot be changed in Digital-Out Device", nil)];
        }
        else {  // movie volume
            volume = normalizedFloat1(adjustToRange(volume, MIN_VOLUME, MAX_VOLUME));
            [_movie setVolume:volume];
            [_defaults setFloat:volume forKey:MVolumeKey];
            [_movieView setMessage:[NSString stringWithFormat:
                                    NSLocalizedString(@"Volume %.1f", nil), volume]];
        }
    }
    else {
        if ([self isUpdateSystemVolume]) {
            _systemVolume = normalizedFloat2(adjustToRange(volume, MIN_SYSTEM_VOLUME, MAX_SYSTEM_VOLUME));
            [self setSystemVolume:_systemVolume];
            [_movieView setMessage:[NSString stringWithFormat:
                                    NSLocalizedString(@"System Volume %.2f", nil), _systemVolume]];
        }
        else {  // movie volume
            volume = normalizedFloat1(adjustToRange(volume, MIN_VOLUME, MAX_VOLUME));
            [_movie setVolume:volume];
            [_defaults setFloat:volume forKey:MVolumeKey];
            [_movieView setMessage:[NSString stringWithFormat:
                                    NSLocalizedString(@"Volume %.1f", nil), volume]];
        }
    }
    [self updateVolumeUI];
}

- (void)setMuted:(BOOL)muted
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, muted);
    [_movie setMuted:muted];
    [_movieView setMessage:(muted) ? NSLocalizedString(@"Mute", nil) :
                                     NSLocalizedString(@"Unmute", nil)];
    if (![self isCurrentlyDigitalAudioOut] && [self isUpdateSystemVolume]) {
        if (muted) {
            [self setSystemVolume:MIN_SYSTEM_VOLUME];
        }
        else if (valueInRange(_systemVolume, MIN_SYSTEM_VOLUME, MAX_SYSTEM_VOLUME)) {
            [self setSystemVolume:_systemVolume];
        }
    }
    [self updateVolumeUI];
}

- (void)updateVolumeUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    float volume;
    BOOL muted;
    if (!_audioDeviceSupportsDigital && [self isUpdateSystemVolume]) {
        if (_systemVolume < 0) {
            _systemVolume = [self systemVolume];
            if (_systemVolume < 0) {
                return;
            }
        }
        // adjust for using same slider min/max range
        volume = normalizedFloat2(MIN_VOLUME +
                                  _systemVolume * (MAX_VOLUME - MIN_VOLUME) /
                                  (MAX_SYSTEM_VOLUME - MIN_SYSTEM_VOLUME));
        muted  = [_movie muted];
    }
    else if (_movie) {
        volume = [_movie volume];
        muted  = [_movie muted];
    }
    else {
        volume = [_defaults floatForKey:MVolumeKey];
        muted = FALSE;
    }

    int state = (muted) ? NSOnState : NSOffState;
    if ([_muteMenuItem state] != state) {
        [_muteMenuItem setState:state];
    }
    if ([_muteButton state] != state) {
        [_muteButton setState:state];
        [_fsMuteButton setState:state];
    }
    
    NSImage* muteImage;
    NSImage* fsMuteImage, *fsMuteImagePressed;
    if (muted || volume == MIN_VOLUME) {
        muteImage          = [NSImage imageNamed:@"MainVolumeMute"];
        fsMuteImage        = [NSImage imageNamed:@"FSVolumeMute"];
        fsMuteImagePressed = [NSImage imageNamed:@"FSVolumeMutePressed"];
    }
    else if (volume < MAX_VOLUME * 1 / 3) {
        muteImage          = [NSImage imageNamed:@"MainVolume1"];
        fsMuteImage        = [NSImage imageNamed:@"FSVolume1"];
        fsMuteImagePressed = [NSImage imageNamed:@"FSVolume1Pressed"];
    }
    else if (volume < MAX_VOLUME * 2 / 3) {
        muteImage          = [NSImage imageNamed:@"MainVolume2"];
        fsMuteImage        = [NSImage imageNamed:@"FSVolume2"];
        fsMuteImagePressed = [NSImage imageNamed:@"FSVolume2Pressed"];
    }
    else {
        muteImage          = [NSImage imageNamed:@"MainVolume3"];
        fsMuteImage        = [NSImage imageNamed:@"FSVolume3"];
        fsMuteImagePressed = [NSImage imageNamed:@"FSVolume3Pressed"];
    }
    if ([_muteButton image] != muteImage) {   // need not isEqual:
        [_muteButton setImage:muteImage];
    }
    if ([_fsMuteButton image] != fsMuteImage) {
        [_fsMuteButton setImage:fsMuteImage];
        [_fsMuteButton setAlternateImage:fsMuteImagePressed];
    }
    
    if ([_volumeSlider floatValue] != volume) {
        [_volumeSlider setFloatValue:volume];
        [_fsVolumeSlider setFloatValue:volume];
    }
    BOOL enabled = !muted && ![self isCurrentlyDigitalAudioOut];
    if ([_volumeSlider isEnabled] != enabled) {
        [_volumeSlider setEnabled:enabled];
        [_fsVolumeSlider setEnabled:enabled];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setAudioTrackAtIndex:(unsigned int)index enabled:(BOOL)enabled
{
    MTrack* track = (MTrack*)[[_movie audioTracks] objectAtIndex:index];
    if (enabled != [track isEnabled]) {
        [track setEnabled:enabled];
    }

    if (enabled) {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"%@ enabled", nil), [track name]]];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"%@ disabled", nil), [track name]]];
    }
    [self updateAudioTrackMenuItems];
}

- (void)enableAudioTracksInIndexSet:(NSIndexSet*)set
{
    int i = 0;
    MTrack* track;
    NSEnumerator* enumerator = [[_movie audioTracks] objectEnumerator];
    while (track = [enumerator nextObject]) {
        if (![set containsIndex:i++]/* && [track isEnabled]*/) {
            [track setEnabled:FALSE];
        }
    }
    i = 0;
    enumerator = [[_movie audioTracks] objectEnumerator];
    while (track = [enumerator nextObject]) {
        if ([set containsIndex:i++]/* && ![track isEnabled]*/) {
            [track setEnabled:TRUE];
        }
    }
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
        if ([self isCurrentlyDigitalAudioOut] && 1 < [_audioTrackIndexSet count]) {
            // only one audio track should be enabled for digial audio.
            unsigned int index = [_audioTrackIndexSet firstIndex];
            [_audioTrackIndexSet removeAllIndexes];
            [_audioTrackIndexSet addIndex:index];
        }
        [self enableAudioTracksInIndexSet:_audioTrackIndexSet];

        NSArray* tracks = [_movie audioTracks];
        unsigned int i, lastIndex = [_audioTrackIndexSet lastIndex];
        for (i = [tracks count]; i <= lastIndex; i++) {
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

- (void)changeAudioTrack:(int)tag
{
    float rate = [_movie rate];
    [_movie setRate:0.0];
    
    int index = tag;
    if (index < 0) { // rotation
        int i = 0;
        MTrack* track;
        NSEnumerator* enumerator = [[_movie audioTracks] objectEnumerator];
        while (track = [enumerator nextObject]) {
            if ([track isEnabled]) {
                break;
            }
            i++;
        }
        index = (i + 1) % [[_movie audioTracks] count];
    }
    [self enableAudioTracksInIndexSet:[NSIndexSet indexSetWithIndex:index]];

    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"%@ selected", nil),
                          [[[_movie audioTracks] objectAtIndex:index] name]]];
    [self updateAudioTrackMenuItems];
    [_propertiesView reloadData];
    
    [_movie setRate:rate];
}

- (void)updateAudioTrackMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // remove all items
    int i, index;
    NSMenuItem* item;
    for (i = 0; i < [[_movieMenu itemArray] count]; i++) {
        item = (NSMenuItem*)[[_movieMenu itemArray] objectAtIndex:i];
        if ([item action] == @selector(audioTrackAction:)) {
            [_movieMenu removeItem:item];
            index = i--;  // remember index of last audio track item
        }
    }

    NSArray* tracks = [_movie audioTracks];
    if ([tracks count] == 0) {
        item = [_movieMenu
                    insertItemWithTitle:NSLocalizedString(@"No Sound Track", nil)
                                     action:@selector(audioTrackAction:)
                              keyEquivalent:@"" atIndex:index];
    }
    else {
        // insert before rotation item
        MTrack* track;
        unsigned int mask = NSCommandKeyMask | NSShiftKeyMask;
        unsigned int i, count = [tracks count];
        for (i = 0; i < count; i++) {
            track = [tracks objectAtIndex:i];
            item = [_movieMenu
                        insertItemWithTitle:[track name]
                                     action:@selector(audioTrackAction:)
                              keyEquivalent:@"" atIndex:index++];
            [item setTag:i];
            [item setState:[track isEnabled]];
            [item setKeyEquivalent:[NSString stringWithFormat:@"%d", i + 1]];
            [item setKeyEquivalentModifierMask:mask];
        }
        if (1 < [tracks count]) {   // add rotate item
            item = [_movieMenu
                        insertItemWithTitle:NSLocalizedString(@"Sound Track Rotation", nil)
                                 action:@selector(audioTrackAction:)
                          keyEquivalent:@"s" atIndex:index++];
            [item setKeyEquivalentModifierMask:mask];
            [item setTag:-1];
        }
    }
    [_movieMenu update];
}

- (void)updateVolumeMenuItems
{
    if ([_defaults boolForKey:MUpdateSystemVolumeKey]) {
        [_volumeUpMenuItem setTitle:NSLocalizedString(@"System Volume Up", nil)];
        [_volumeDownMenuItem setTitle:NSLocalizedString(@"System Volume Down", nil)];
        [_altVolumeUpMenuItem setTitle:NSLocalizedString(@"Volume Up", nil)];
        [_altVolumeDownMenuItem setTitle:NSLocalizedString(@"Volume Down", nil)];
    }
    else {
        [_volumeUpMenuItem setTitle:NSLocalizedString(@"Volume Up", nil)];
        [_volumeDownMenuItem setTitle:NSLocalizedString(@"Volume Down", nil)];
        [_altVolumeUpMenuItem setTitle:NSLocalizedString(@"System Volume Up", nil)];
        [_altVolumeDownMenuItem setTitle:NSLocalizedString(@"System Volume Down", nil)];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)volumeAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    if ([sender tag] < 0) {
        [self volumeDown];
    }
    else if (0 < [sender tag]) {
        [self volumeUp];
    }
    else {  // volume slider
        float volume = [sender floatValue];
        if ([self isUpdateSystemVolume]) {
            volume = (volume - MIN_VOLUME) *
                        (MAX_SYSTEM_VOLUME - MIN_SYSTEM_VOLUME) /
                        (MAX_VOLUME - MIN_VOLUME);
        }
        [self setVolume:volume];
    }
}

- (IBAction)muteAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _checkForAltVolumeChange = FALSE;
    [self setMuted:([_muteMenuItem state] == NSOffState)];
    _checkForAltVolumeChange = TRUE;
}

- (IBAction)audioTrackAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeAudioTrack:[sender tag]];
}

@end

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

#import "MMovie.h"
#import "Playlist.h"

#import "MMovieView.h"
#import "ControlPanel.h"
#import "CustomControls.h"  // for SeekSlider
#import "FullScreener.h"

@implementation AppController (Playback)

- (void)play
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie && [_movie rate] == 0.0) {
        [_movieView setMessage:NSLocalizedString(@"Play", nil)];
        [_movie setRate:_playRate];
    }
}

- (void)pause
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie && [_movie rate] != 0.0) {
        [_movieView setMessage:NSLocalizedString(@"Pause", nil)];
        [_movie setRate:0.0];
    }
}

- (void)gotoBeginning
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"Beginning", nil)];
        [_movie gotoBeginning];
    }
}

- (void)gotoEnd
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"End", nil)];
        //[_movie gotoEnd];
        // call gotoTime with (duration - 0.01)
        // not to next movie by movieEnded notification
        [_movie gotoTime:[_movie duration] - 0.01];
    }
}

- (NSString*)stringByGotoTime:(float)time
{
    float duration = [_movie duration];
    return [NSString stringWithFormat:@"%@/%@ (%d%%)",
            NSStringFromMovieTime(time), NSStringFromMovieTime(duration),
            (int)(time * 100 / duration)];
}

- (void)gotoTime:(float)time
{
    //TRACE(@"%s %f sec", __PRETTY_FUNCTION__, time);
    if (_movie) {
        [_movieView setMessage:[self stringByGotoTime:time]];
        [_movie gotoTime:time];
    }
}

- (void)seekPrevSubtitle
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        float time = [_movieView prevSubtitleTime];
        [_movieView setMessage:[NSString stringWithFormat:@"%@ %@",
                                NSLocalizedString(@"Previous Subtitle", nil),
                                [self stringByGotoTime:time]]];
        [_movie gotoTime:time];
    }
}

- (void)seekNextSubtitle
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        float time = [_movieView nextSubtitleTime];
        [_movieView setMessage:[NSString stringWithFormat:@"%@ %@",
                                NSLocalizedString(@"Next Subtitle", nil),
                                [self stringByGotoTime:time]]];
        [_movie gotoTime:time];
    }
}

- (void)seekBackward:(unsigned int)indexOfValue
{
    //TRACE(@"%s %.1f sec.", __PRETTY_FUNCTION__, _seekInterval[indexOfValue]);
    if (_movie) {
        float dt = _seekInterval[indexOfValue];
        float t = MAX(0, [_movie currentTime] - dt);
        [_movieView setMessage:[NSString stringWithFormat:@"%@ %@",
                                [NSString stringWithFormat:
                                 NSLocalizedString(@"Backward %d sec.", nil), (int)dt],
                                [self stringByGotoTime:t]]];
        [_movie seekByTime:-dt];
    }
}

- (void)seekForward:(unsigned int)indexOfValue
{
    //TRACE(@"%s %.1f sec.", __PRETTY_FUNCTION__, _seekInterval[indexOfValue]);
    if (_movie) {
        float dt = _seekInterval[indexOfValue];
        float t = MIN([_movie currentTime] + dt, [_movie duration]);
        [_movieView setMessage:[NSString stringWithFormat:@"%@ %@",
                                [NSString stringWithFormat:
                                 NSLocalizedString(@"Forward %d sec.", nil), (int)dt],
                                [self stringByGotoTime:t]]];
        [_movie seekByTime:+dt];
    }
}

- (void)stepBackward
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"Previous Frame", nil)];
        [_movie setRate:0.0];
        [_movie stepBackward];
    }
}

- (void)stepForward
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"Next Frame", nil)];
        [_movie setRate:0.0];
        [_movie stepForward];
    }
}

- (void)setSeekInterval:(float)interval atIndex:(unsigned int)index
{
    //TRACE(@"%s [%d]:%.1f sec", __PRETTY_FUNCTION__, index, interval);
    _seekInterval[index] = interval;
    
    NSMenuItem* backwardItem[3] = {
        _seekBackward1MenuItem, _seekBackward2MenuItem, _seekBackward3MenuItem
    };
    NSMenuItem* forwardItem[3] = {
        _seekForward1MenuItem, _seekForward2MenuItem, _seekForward3MenuItem
    };
    [backwardItem[index] setTitle:[NSString stringWithFormat:
        NSLocalizedString(@"Backward %d sec.", nil), (int)_seekInterval[index]]];
    [forwardItem[index] setTitle:[NSString stringWithFormat:
        NSLocalizedString(@"Forward %d sec.", nil), (int)_seekInterval[index]]];
}

- (void)setPlayRate:(float)rate
{
    //TRACE(@"%s %.1f", __PRETTY_FUNCTION__, rate);
    _playRate = normalizedFloat1(adjustToRange(rate, MIN_PLAY_RATE, MAX_PLAY_RATE));
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Play Rate %.1fx", nil), _playRate]];
    [_controlPanel updatePlaybackRateSlider:_playRate];

    if ([_movie rate] != 0.0) {
        [_movie setRate:0.0];
        [_movie setRate:_playRate];
    }
}

- (void)changePlayRate:(int)tag
{
    switch (tag) {
        case -1 : [self setPlayRate:_playRate - 0.1];   break;
        case  0 : [self setPlayRate:DEFAULT_PLAY_RATE]; break;
        case +1 : [self setPlayRate:_playRate + 0.1];   break;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)updateRangeRepeatUI
{
    if ([_seekSlider repeatEnabled]) {
        [_repeatBeginningTextField setStringValue:
            NSStringFromMovieTime([_seekSlider repeatBeginning])];
        [_repeatEndTextField setStringValue:
            NSStringFromMovieTime([_seekSlider repeatEnd])];
    }
    else {
        [_repeatBeginningTextField setStringValue:@"--:--:--"];
        [_repeatEndTextField setStringValue:@"--:--:--"];
    }
}

- (void)setRangeRepeatRange:(NSRange)range
{
    if (0 < range.length) {
        [_seekSlider setRepeatRange:range];
        [_fsSeekSlider setRepeatRange:range];
    }
    else {
        [_seekSlider clearRepeat];
        [_fsSeekSlider clearRepeat];
    }
    [self updateRangeRepeatUI];
    // no OSD message for range
}

- (void)setRangeRepeatBeginning:(float)beginning
{
    [_seekSlider setRepeatBeginning:beginning];
    [_fsSeekSlider setRepeatBeginning:beginning];
    [self updateRangeRepeatUI];

    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Range Repeat Beginning %@", nil),
        NSStringFromMovieTime([_seekSlider repeatBeginning])]];
}

- (void)setRangeRepeatEnd:(float)end
{
    [_seekSlider setRepeatEnd:end];
    [_fsSeekSlider setRepeatEnd:end];
    [self updateRangeRepeatUI];

    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Range Repeat End %@", nil),
        NSStringFromMovieTime([_seekSlider repeatEnd])]];
}

- (void)clearRangeRepeat
{
    [_seekSlider clearRepeat];
    [_fsSeekSlider clearRepeat];
    [self updateRangeRepeatUI];

    [_movieView setMessage:NSLocalizedString(@"Range Repeat Clear", nil)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark notifications

- (void)movieIndexDurationChanged:(NSNotification*)notification
{
    if (notification) {
        [self performSelectorOnMainThread:@selector(movieIndexDurationChanged:)
                               withObject:nil waitUntilDone:FALSE];   // don't wait
    }
    else {
        //TRACE(@"%s", __PRETTY_FUNCTION__);
        [self updateTimeUI];
    }
}

- (void)movieRateChanged:(NSNotification*)notification
{
    if (notification) {
        [self performSelectorOnMainThread:@selector(movieRateChanged:)
                               withObject:nil waitUntilDone:FALSE];   // don't wait
    }
    else {
        //TRACE(@"%s", __PRETTY_FUNCTION__);
        [self updatePlayUI];
    }
}

- (void)movieCurrentTimeChanged:(NSNotification*)notification
{
    if (notification) {
        [self performSelectorOnMainThread:@selector(movieCurrentTimeChanged:)
                               withObject:nil waitUntilDone:FALSE];   // don't wait
    }
    else {
        //TRACE(@"%s %.2f", __PRETTY_FUNCTION__, [_movie currentTime]);
        if ([_movie rate] != 0.0 &&
            [_seekSlider repeatEnabled] &&
            [_seekSlider repeatEnd] < [_movie currentTime]) {
            [_movie gotoTime:[_seekSlider repeatBeginning]];
        }
        [self performSelectorOnMainThread:@selector(updateTimeUI)
                               withObject:nil waitUntilDone:FALSE];   // don't wait
    }
}

- (void)movieEnded:(NSNotification*)notification
{
    if (notification) {
        [self performSelectorOnMainThread:@selector(movieEnded:)
                               withObject:nil waitUntilDone:FALSE];   // don't wait
    }
    else {
        //TRACE(@"%s", __PRETTY_FUNCTION__);
        [self updateTimeUI];
        [self updatePlayUI];
        [_playlistController updateUI];

        [self openNextPlaylistItem];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UI

- (void)updateTimeUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        if (![_seekSlider isEnabled]) {
            [_seekSlider setEnabled:TRUE];
            [_fsSeekSlider setEnabled:TRUE];
        }
        float ct = [_movie currentTime];
        float dt = ABS(ct - _prevMovieTime);
        if (1.0 <= dt * [_seekSlider bounds].size.width / [_movie duration]) {
            [_seekSlider setFloatValue:ct];
            [_fsSeekSlider setFloatValue:ct];
            _prevMovieTime = ct;
        }

        ct = [_movie indexedDuration];
        dt = ABS(ct - [_seekSlider indexedDuration]);
        if (1.0 <= dt * [_seekSlider bounds].size.width / [_movie duration]) {
            [_seekSlider setIndexedDuration:ct];
            [_fsSeekSlider setIndexedDuration:ct];
        }

        NSString* s = NSStringFromMovieTime([_movie currentTime]);
        if (![s isEqualToString:[_lTimeTextField stringValue]]) {
            [_lTimeTextField setStringValue:s];
            [_fsLTimeTextField setStringValue:s];
        }
        s = NSStringFromMovieTime((_viewDuration) ? [_movie duration] :
                                    [_movie currentTime] - [_movie duration]);
        if (![s isEqualToString:[_rTimeTextField stringValue]]) {
            [_rTimeTextField setStringValue:s];
            [_fsRTimeTextField setStringValue:s];
        }

        if ([_movie rate] == 0) {   // paused
            s = [NSString stringWithFormat:@"--.-- / %.2f", [_movie fps]];
        }
        else {
            s = [NSString stringWithFormat:@"%.2f / %.2f", [_movieView currentFps], [_movie fps]];
        }
        if (![s isEqualToString:[_fpsTextField stringValue]]) {
            [_fpsTextField setStringValue:s];
        }
    }
    else {
        [_seekSlider setEnabled:FALSE];
        [_seekSlider setFloatValue:0.0];
        [_seekSlider setIndexedDuration:0.0];
        [_fsSeekSlider setEnabled:FALSE];
        [_fsSeekSlider setFloatValue:0.0];
        [_fsSeekSlider setIndexedDuration:0.0];

        [_lTimeTextField setStringValue:@"--:--:--"];
        [_rTimeTextField setStringValue:@"--:--:--"];
        [_fsLTimeTextField setStringValue:@"--:--:--"];
        [_fsRTimeTextField setStringValue:@"--:--:--"];

        [_fpsTextField setStringValue:@""];
    }
}

- (void)updatePlayUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie && [_movie rate] != 0) {
        NSImage* mainPauseImage, *mainPausePressedImage;
        if (isSystemTiger()) {
            mainPauseImage = [NSImage imageNamed:@"MainPauseTiger"];
            mainPausePressedImage = [NSImage imageNamed:@"MainPausePressedTiger"];
        }
        else {
            mainPauseImage = [NSImage imageNamed:@"MainPause"];
            mainPausePressedImage = [NSImage imageNamed:@"MainPausePressed"];
        }
        [_playMenuItem setTitle:NSLocalizedString(@"Pause_space", nil)];
        [_playButton setImage:mainPauseImage];
        [_playButton setAlternateImage:mainPausePressedImage];
        [_fsPlayButton setImage:[NSImage imageNamed:@"FSPause"]];
        [_fsPlayButton setAlternateImage:[NSImage imageNamed:@"FSPausePressed"]];
    }
    else {
        NSImage* mainPlayImage, *mainPlayPressedImage;
        if (isSystemTiger()) {
            mainPlayImage = [NSImage imageNamed:@"MainPlayTiger"];
            mainPlayPressedImage = [NSImage imageNamed:@"MainPlayPressedTiger"];
        }
        else {
            mainPlayImage = [NSImage imageNamed:@"MainPlay"];
            mainPlayPressedImage = [NSImage imageNamed:@"MainPlayPressed"];
        }
        [_playMenuItem setTitle:NSLocalizedString(@"Play_space", nil)];
        [_playButton setImage:mainPlayImage];
        [_playButton setAlternateImage:mainPlayPressedImage];
        [_fsPlayButton setImage:[NSImage imageNamed:@"FSPlay"]];
        [_fsPlayButton setAlternateImage:[NSImage imageNamed:@"FSPlayPressed"]];
    }
    [_prevSeekButton setEnabled:(_movie != nil)];
    [_nextSeekButton setEnabled:(_movie != nil)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)playAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        if ([_movie rate] == 0.0) {
            if ([_seekSlider repeatEnabled] &&
                ([_movie currentTime] < [_seekSlider repeatBeginning] ||
                 [_seekSlider repeatEnd] < [_movie currentTime])) {
                [_movie gotoTime:[_seekSlider repeatBeginning]];
            }
            [_movie setRate:_playRate];
            [_movieView setMessage:NSLocalizedString(@"Play", nil)];
        }
        else {
            [_movie setRate:0.0];
            [_movieView setMessage:NSLocalizedString(@"Pause", nil)];
        }
    }
    else if ([_playlist count] == 0) {
        [self openFileAction:self];
    }
    else {
        if (![_playlist currentItem]) {
            [_playlist setNextItem];
        }
        [self openCurrentPlaylistItem];
    }
}

- (IBAction)seekAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    int tag = [sender tag];
    unsigned int flags = [[NSApp currentEvent] modifierFlags];
    if (flags & NSAlternateKeyMask) {
        if (flags & NSShiftKeyMask) {
            if (flags & NSControlKeyMask) {
                tag = (tag < 0) ? -40 : +40;
            }
            else {
                tag = (tag < 0) ? -30 : +30;
            }
        }
        else {
            tag = (tag < 0) ? -20 : +20;
        }
    }
    switch (tag) {
        case -100 : [self gotoBeginning];       break;
        case  -40 : [self seekPrevSubtitle];    break;
        case  -30 : [self seekBackward:2];      break;
        case  -20 : [self seekBackward:1];      break;
        case  -10 : [self seekBackward:0];      break;
        case   -1 : [self stepBackward];        break;
        case    0 :
            if ([[NSApp currentEvent] type] != NSLeftMouseUp) {
                [self gotoTime:[sender floatValue]];
            }
            break;
        case   +1 : [self stepForward];         break;
        case  +10 : [self seekForward:0];       break;
        case  +20 : [self seekForward:1];       break;
        case  +30 : [self seekForward:2];       break;
        case  +40 : [self seekNextSubtitle];    break;
        case +100 : [self gotoEnd];             break;
    }
}

- (IBAction)rangeRepeatAction:(id)sender
{
    if ([sender tag] == -1) {
        [self setRangeRepeatBeginning:[_movie currentTime]];
    }
    else if ([sender tag] == 1) {
        [self setRangeRepeatEnd:[_movie currentTime]];
    }
    else if ([sender tag] == 0) {
        [self clearRangeRepeat];
    }
    /*
    else if ([sender tag] == -100) {    // 10 sec.
        [self setRangeRepeatRange:NSMakeRange([_movie currentTime], 10);
        [_movieView setMessage:NSLocalizedString(@"Range Repeat 10 sec.", nil)];
    }
    */
}

- (IBAction)rateAction:(id)sender
{
    [self changePlayRate:[sender tag]];
}

@end

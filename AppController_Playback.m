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

#import "MMovie.h"
#import "Playlist.h"

#import "MMovieView.h"
#import "CustomControls.h"  // for SeekSlider
#import "FullScreener.h"

@implementation AppController (Playback)

- (void)play
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie && [_movie rate] == 0.0) {
        [_movieView setMessage:NSLocalizedString(@"Play", nil)];
        [_movie setRate:_playRate];
    }
}

- (void)pause
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie && [_movie rate] != 0.0) {
        [_movieView setMessage:NSLocalizedString(@"Pause", nil)];
        [_movie setRate:0.0];
    }
}

- (void)gotoBeginning
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"Beginning", nil)];
        [_movie gotoBeginning];
    }
}

- (void)gotoEnd
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"End", nil)];
        //[_movie gotoEnd];
        // call gotoTime with (duration - 0.01)
        // not to next movie by movieEnded notification
        [_movie gotoTime:[_movie duration] - 0.01];
    }
}

- (void)gotoTime:(float)time
{
    TRACE(@"%s %f sec", __PRETTY_FUNCTION__, time);
    if (_movie) {
        [_movieView setMessage:[NSString stringWithFormat:
            @"%@/%@", NSStringFromMovieTime(time),
                      NSStringFromMovieTime([_movie duration])]];
        [_movie gotoTime:time];
    }
}

- (void)seekBackward:(unsigned int)indexOfValue
{
    TRACE(@"%s %.1f sec.", __PRETTY_FUNCTION__, _seekInterval[indexOfValue]);
    if (_movie) {
        float dt = _seekInterval[indexOfValue];
        float t = MAX(0, [_movie currentTime] - dt);
        [_movie seekByTime:-dt];
        [_movieView setMessage:[NSString stringWithFormat:@"%@ %@/%@",
            [NSString stringWithFormat:NSLocalizedString(@"Backward %d sec.", nil), (int)dt],
            NSStringFromMovieTime(t), NSStringFromMovieTime([_movie duration])]];
    }
}

- (void)seekForward:(unsigned int)indexOfValue
{
    TRACE(@"%s %.1f sec.", __PRETTY_FUNCTION__, _seekInterval[indexOfValue]);
    if (_movie) {
        float dt = _seekInterval[indexOfValue];
        float t = MIN([_movie currentTime] + dt, [_movie duration]);
        [_movie seekByTime:+dt];
        [_movieView setMessage:[NSString stringWithFormat:@"%@ %@/%@",
            [NSString stringWithFormat:NSLocalizedString(@"Forward %d sec.", nil), (int)dt],
            NSStringFromMovieTime(t), NSStringFromMovieTime([_movie duration])]];
    }
}

- (void)stepBackward
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"Previous Frame", nil)];
        [_movie setRate:0.0];
        [_movie stepBackward];
    }
}

- (void)stepForward
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_movieView setMessage:NSLocalizedString(@"Next Frame", nil)];
        [_movie setRate:0.0];
        [_movie stepForward];
    }
}

- (void)setSeekInterval:(float)interval atIndex:(unsigned int)index
{
    TRACE(@"%s [%d]:%.1f sec", __PRETTY_FUNCTION__, index, interval);
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
    TRACE(@"%s %.1f", __PRETTY_FUNCTION__, rate);
    rate = MAX(MIN_PLAY_RATE, rate);
    rate = MIN(rate, MAX_PLAY_RATE);
    
    _playRate = rate;
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Play Rate %.1fx", nil), _playRate]];
    [_controlPanel setPlayRate:_playRate];

    if ([_movie rate] != 0.0) {
        [_movie setRate:0.0];
        [_movie setRate:_playRate];
    }
}

- (void)changePlayRate:(int)tag
{
    switch (tag) {
        case -1 : [self setPlayRate:_playRate - 0.1];   break;
        case  0 : [self setPlayRate:1.0];               break;
        case +1 : [self setPlayRate:_playRate + 0.1];   break;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark notifications

- (void)movieRateChanged:(NSNotification*)notification
{
    if (notification) {
        [self performSelectorOnMainThread:@selector(movieRateChanged:)
                               withObject:nil waitUntilDone:FALSE];   // don't wait
    }
    else {
        TRACE(@"%s", __PRETTY_FUNCTION__);
        [self updatePlayUI];
        [_playlistController updateUI];
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
        TRACE(@"%s", __PRETTY_FUNCTION__);
        [self updateTimeUI];
        [self updatePlayUI];
        [_playlistController updateUI];

        if (![self openNextPlaylistItem]) {
            if ([self isFullScreen]) {
                if ([_fullScreener isNavigating]) {
                    // preview is over => do nothing
                }
                else if ([_fullScreener isNavigatable]) {
                    [_fullScreener closeCurrent];
                }
                else {
                    [self endFullScreen];
                    [_movieView setMessage:@""];
                    [_movieView showLogo];
                }
            }
            else {
                [_movieView setMessage:@""];
                [_movieView showLogo];
            }
        }
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
            [_panelSeekSlider setEnabled:TRUE];
        }
        float dt = ABS([_movie currentTime] - _prevMovieTime);
        if (1.0 <= dt * [_seekSlider bounds].size.width / [_movie duration]) {
            [_seekSlider setFloatValue:[_movie currentTime]];
            [_panelSeekSlider setFloatValue:[_movie currentTime]];
            _prevMovieTime = [_movie currentTime];
        }

        NSString* s = NSStringFromMovieTime([_movie currentTime]);
        if (![s isEqualToString:[_lTimeTextField stringValue]]) {
            [_lTimeTextField setStringValue:s];
            [_panelLTimeTextField setStringValue:s];
        }
        s = NSStringFromMovieTime((_viewDuration) ? [_movie duration] :
                                    [_movie currentTime] - [_movie duration]);
        if (![s isEqualToString:[_rTimeTextField stringValue]]) {
            [_rTimeTextField setStringValue:s];
            [_panelRTimeTextField setStringValue:s];
        }
    }
    else {
        [_seekSlider setEnabled:FALSE];
        [_seekSlider setFloatValue:0.0];
        [_panelSeekSlider setEnabled:FALSE];
        [_panelSeekSlider setFloatValue:0.0];

        [_lTimeTextField setStringValue:@"--:--:--"];
        [_rTimeTextField setStringValue:@"--:--:--"];
        [_panelLTimeTextField setStringValue:@"--:--:--"];
        [_panelRTimeTextField setStringValue:@"--:--:--"];
    }
}

- (void)updatePlayUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        if ([_movie rate] != 0) {
            [_playMenuItem setTitle:NSLocalizedString(@"Pause_space", nil)];
            [_playButton setImage:[NSImage imageNamed:@"MainPause"]];
            [_playButton setAlternateImage:[NSImage imageNamed:@"MainPausePressed"]];
            [_panelPlayButton setImage:[NSImage imageNamed:@"FSPause"]];
            [_panelPlayButton setAlternateImage:[NSImage imageNamed:@"FSPausePressed"]];
        }
        else {
            [_playMenuItem setTitle:NSLocalizedString(@"Play_space", nil)];
            [_playButton setImage:[NSImage imageNamed:@"MainPlay"]];
            [_playButton setAlternateImage:[NSImage imageNamed:@"MainPlayPressed"]];
            [_panelPlayButton setImage:[NSImage imageNamed:@"FSPlay"]];
            [_panelPlayButton setAlternateImage:[NSImage imageNamed:@"FSPlayPressed"]];
        }
    }
    else {
        [_playMenuItem setTitle:NSLocalizedString(@"Play_space", nil)];
        [_playButton setImage:[NSImage imageNamed:@"MainPlay"]];
        [_panelPlayButton setImage:[NSImage imageNamed:@"FSPlay"]];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)playAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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
    TRACE(@"%s %d", __PRETTY_FUNCTION__, [sender tag]);
    switch ([sender tag]) {
        case -100 : [self gotoBeginning];       break;
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
        case +100 : [self gotoEnd];             break;
    }
}

- (IBAction)rangeRepeatAction:(id)sender
{
    if ([sender tag] == -1) {   // beginning
        float beginning = [_movie currentTime];
        [_seekSlider setRepeatBeginning:beginning];
        [_panelSeekSlider setRepeatBeginning:beginning];
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Range Repeat Beginning %@", nil),
            NSStringFromMovieTime([_seekSlider repeatBeginning])]];
    }
    else if ([sender tag] == 1) {   // end
        float end = [_movie currentTime];
        [_seekSlider setRepeatEnd:end];
        [_panelSeekSlider setRepeatEnd:end];
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Range Repeat End %@", nil),
            NSStringFromMovieTime([_seekSlider repeatEnd])]];
    }
    else if ([sender tag] == 0) {   // clear
        [_seekSlider clearRepeat];
        [_panelSeekSlider clearRepeat];
        [_movieView setMessage:NSLocalizedString(@"Range Repeat Clear", nil)];
    }
    /*
    else if ([sender tag] == -100) {    // 10 sec.
        float beginning = [_movie currentTime];
        float end = beginning + 10;
        if ([_movie duration] < end) {
            end = [_movie duration];
        }
        [_seekSlider setRepeatBeginning:beginning];
        [_panelSeekSlider setRepeatBeginning:beginning];
        [_seekSlider setRepeatEnd:end];
        [_panelSeekSlider setRepeatEnd:end];
        [_movieView setMessage:NSLocalizedString(@"Range Repeat 10 sec.", nil)];
    }
    */

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

- (IBAction)rateAction:(id)sender
{
    [self changePlayRate:[sender tag]];
}

@end

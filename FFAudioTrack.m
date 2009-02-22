//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim, Cheol Ju. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//      Cheol Ju      <moosoy@gmail.com>
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

#import "FFTrack.h"

@implementation FFAudioTrack

+ (id)audioTrackWithAVStream:(AVStream*)stream index:(int)index
{
    return [[[FFAudioTrack alloc] initWithAVStream:stream index:index] autorelease];
}

- (BOOL)initTrack:(int*)errorCode passThrough:(BOOL)passThrough
{
    PTS_TO_SEC = av_q2d(_stream->time_base);
    _passThrough = passThrough;
    _enabled = FALSE;
    _running = FALSE;
    
    AVCodecContext* context = _stream->codec;
    if (!_passThrough) {
        context->request_channels = 2;
    }
    // FIXME: hack for DTS;
    if (context->codec_id == CODEC_ID_DTS && context->channels == 5) {
        TRACE(@"dts audio channel is 5? maybe 6...");
        context->channels = 6;
    }  

    if (![super initTrack:errorCode]) {
        return FALSE;
    }
    return TRUE;
}

- (void)cleanupTrack
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    assert(!_running);
    
    [super cleanupTrack];
}

- (void)quit
{
    [self stopAudio];
    [super quit];
}

- (BOOL)isAc3Dts
{
    return _stream->codec->codec_id == CODEC_ID_DTS ||
           _stream->codec->codec_id == CODEC_ID_AC3;
}

- (void)startAudio
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _running = TRUE;
    int error;
    if (_passThrough) {
        assert(!_audioUnit);
        if (![self initDigitalAudio:&error]) {
            _enabled = FALSE;
            _running = FALSE;
            return;
        }
        [self startDigitalAudio];
    }
    else {
        assert(!_audioDev);
        if (![self initAnalogAudio:&error]) {
            _enabled = FALSE;
            _running = FALSE;
            return;
        }
        [self startAnalogAudio];
    }       
}

- (void)stopAudio
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!_running) {
        return;
    }
    if (_passThrough) {
        [self stopDigitalAudio];
        [self cleanupDigitalAudio];
    }
    else {
        [self stopAnalogAudio];
        [self cleanupAnalogAudio];
    }
    assert(!_running);
}

- (float)volume { return _volume; }
- (void)setVolume:(float)volume { _volume = volume; }
- (void)setSpeakerCount:(int)count { _speakerCount = count; }

- (void)putPacket:(AVPacket*)packet
{
    if (_passThrough) {
        [self putDigitalAudioPacket:packet];
    }
    else {
        [self decodePacket:packet];
    }
}

- (void)clearQueue
{
    if (_passThrough) {
        [self clearDigitalDataQueue];
    }
    else {
        [self clearAnalogDataQueue];
    }
}
@end

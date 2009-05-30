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

#import "MMovie.h"

#ifdef __BIG_ENDIAN__
    #import <ffmpeg/avcodec.h>
    #import <ffmpeg/avformat.h>
#else
    #import <libavcodec/avcodec.h>
    #import <libavformat/avformat.h>
#endif

enum {
    COMMAND_NONE,
    COMMAND_STEP_BACKWARD,
    COMMAND_STEP_FORWARD,
    COMMAND_SEEK,
    COMMAND_PLAY,
    COMMAND_PAUSE,
};

@class FFTrack;
@class FFVideoTrack;
@class FFAudioTrack;
@class FFIndexer;

@interface MMovie_FFmpeg : MMovie
{
    AVFormatContext* _formatContext;

    FFVideoTrack* _mainVideoTrack;
    FFAudioTrack* _mainAudioTrack;
    FFIndexer* _indexer;

    // playback: control
    int _command;
    int _reservedCommand;
    NSConditionLock* _commandLock;
    //NSLock* _avSyncMutex;
    NSLock* _frameReadMutex;
    NSLock* _trackMutex;
    BOOL _running;
    BOOL _quitRequested;
    BOOL _dispatchPacket;
    BOOL _seekComplete;
    BOOL _fileEnded;
    BOOL _movieEndNotificationPosted;

    // playback: play
    float _rate;
    BOOL _playAfterSeek;   // for continuous play after seek
    double _frameInterval;
    BOOL _useFrameDrop;

    // playback: seek
    float _seekTime;
    float _reservedSeekTime;
    double _lastDecodedTime;
    BOOL _needKeyFrame;
    BOOL _seekKeyFrame;

    double _currentTime;
    double _hostTimeFreq;
    double _hostTime;
    double _hostTime0point;
    double _avFineTuningTime;
}

+ (NSString*)name;

- (BOOL)initAVCodec:(int*)errorCode digitalAudioOut:(BOOL)digitalAudioOut;
- (void)cleanupAVCodec;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovie_FFmpeg (Playback)

- (BOOL)initPlayback:(int*)errorCode;
- (void)cleanupPlayback;

- (int)command;
- (int)reservedCommand;
- (BOOL)isRunning;
- (BOOL)quitRequested;

- (double)hostTimeFreq;
- (double)hostTime0point;
- (BOOL)canDecodeVideo;

- (void)videoTrack:(FFVideoTrack*)videoTrack decodedTime:(double)time;
- (void)audioTrack:(FFAudioTrack*)audioTrack avFineTuningTime:(double)time;

@end

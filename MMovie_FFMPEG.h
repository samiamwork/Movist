//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim, Cheol Ju. All rights reserved.
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

#if defined(_SUPPORT_FFMPEG)

#import "MMovie.h"

#import <avcodec.h>
#import <avformat.h>
#import <swscale.h>
#include <AudioUnit/AudioUnit.h>

@class MMovie_FFMPEG;

@interface MTrack_FFMPEG : MTrack
{
    BOOL _enable;
    float _volume;
    int _streamId;
    MMovie_FFMPEG* _movie;
}

- (id)initWithStreamId:(int)streamId movie:(MMovie_FFMPEG*)movie;
- (NSString*)name;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (float)volume;
- (void)setVolume:(float)volume;
- (int)streamId;
- (MMovie_FFMPEG*)movie;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface PacketQueue : NSObject
{
    AVPacket* _packet;
    unsigned int _capacity;
    unsigned int _front;
    unsigned int _rear;
}

- (id)initWithCapacity:(unsigned int)capacity;

#pragma mark -
- (void)clear;
- (BOOL)isEmpty;
- (BOOL)isFull;
- (BOOL)putPacket:(const AVPacket*)packet;
- (BOOL)getPacket:(AVPacket*)packet;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface AUCallbackInfo : NSObject
{
    MMovie_FFMPEG* _movie;
    int _streamId;
}
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@class AudioDataQueue;

enum {
    COMMAND_NONE,
    COMMAND_STEP_BACKWARD,
    COMMAND_STEP_FORWARD,
    COMMAND_SEEK,
    COMMAND_PLAY,
    COMMAND_PAUSE,
};

@interface MMovie_FFMPEG : MMovie
{
    AVFormatContext* _formatContext;

    // video
    int _videoStreamIndex;
    #define _videoStream        _formatContext->streams[_videoStreamIndex]
    #define _videoContext       _videoStream->codec
    #define _videoWidth         _videoContext->width
    #define _videoHeight        _videoContext->height

    // audio
    int _speakerCount;
    #define MAX_AUDIO_STREAM_COUNT  8
    int _audioStreamCount;
    int _audioStreamIndex[MAX_AUDIO_STREAM_COUNT];
    int _firstAudioStreamId;
    #define _audioStream(i)     _formatContext->streams[_audioStreamIndex[i]]
    #define _audioContext(i)    _audioStream(i)->codec

    // playback: control
    int _command;
    int _reservedCommand;
    NSConditionLock* _commandLock;
    NSLock* _avSyncMutex;
    BOOL _quitRequested;
    BOOL _dispatchPacket;
    BOOL _playThreading;
    BOOL _fileEnded;

    // playback: play
    float _rate;
    BOOL _playAfterSeek;   // for continuous play after seek

    // playback: seek
    float _seekTime;
    float _reservedSeekTime;
    BOOL _needKeyFrame;
    BOOL _seekKeyFrame;
    
    // playback: decoding
    #define RGB_PIXEL_FORMAT    PIX_FMT_YUV422
    //#define RGB_PIXEL_FORMAT    PIX_FMT_BGRA    // PIX_FMT_ARGB is not supported by ffmpeg
    #define MAX_VIDEO_DATA_BUF_SIZE 4
    PacketQueue* _videoQueue;
    AudioUnit _audioUnit[MAX_AUDIO_STREAM_COUNT];
    AVFrame* _videoFrame;    // for decoding
    AVFrame* _videoFrameData[MAX_VIDEO_DATA_BUF_SIZE]; // for display
    NSMutableArray* _audioDataQueue;
    struct SwsContext* _scalerContext;
    AVPacket _flushPacket;
    int _decodedImageCount;
    int _decodedImageBufCount;
    float _currentTime;
    float _decodedImageTime[MAX_VIDEO_DATA_BUF_SIZE];
    int _videoDataBufId;
    int _nextVideoBufId;
    float _nextDecodedAudioTime[MAX_AUDIO_STREAM_COUNT];
    float _hostTime;
    float _hostTime0point;
    float _avFineTuningTime;
    
    // audio
    float _volume;
    bool _muted;
}

+ (NSString*)name;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovie_FFMPEG (Init)

- (BOOL)initFFMPEGWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode;
- (void)cleanupFFMPEG;
- (BOOL)initDecoder:(AVCodecContext*)context codec:(AVCodec*)codec
           forVideo:(BOOL)forVideo;
- (NSString*)streamName:(BOOL)isVideo streamId:(int)streamId;
- (NSString*)streamFormat:(BOOL)isVideo streamId:(int)streamId;

@end

@interface MMovie_FFMPEG (Playback)

- (BOOL)defaultFuncCondition;
- (BOOL)initPlayback:(int*)errorCode;
- (void)cleanupPlayback;

@end

@interface MMovie_FFMPEG (Audio)

- (BOOL)initAudio:(int)audioStreamIndex errorCode:(int*)errorCode;
- (void)cleanupAudio;
- (BOOL)initAudioPlayback:(int*)errorCode;
- (void)cleanupAudioPlayback;
- (void)decodeAudio:(AVPacket*)packet trackId:(int)trackId;
- (void)updateFirstAudioStreamId;

@end

#endif  // _SUPPORT_FFMPEG

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

#import "MMovie.h"

#import <avcodec.h>
#import <avformat.h>
#import <swscale.h>
#include <AudioUnit/AudioUnit.h>

@class MMovie_FFmpeg;

@interface MTrack_FFmpeg : MTrack
{
    int _streamId;
    float _volume;
}

+ (id)trackWithMovie:(MMovie*)movie formatContext:(AVFormatContext*)formatContext
         streamIndex:(int)streamIndex streamId:(int)streamId;

- (id)initWithMovie:(MMovie*)movie formatContext:(AVFormatContext*)formatContext
        streamIndex:(int)streamIndex streamId:(int)streamId;

- (int)streamId;
- (float)volume;
- (void)setVolume:(float)volume;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface PacketQueue : NSObject
{
    AVPacket* _packet;
    unsigned int _capacity;
    unsigned int _front;
    unsigned int _rear;
    NSLock* _mutex;
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
    MMovie_FFmpeg* _movie;
    int _streamId;
}
@end

@interface AudioDataQueue : NSObject
{
    int _bitRate;
    UInt8* _data;
    NSRecursiveLock* _mutex;
    double _time;
    unsigned int _capacity;
    unsigned int _front;
    unsigned int _rear;
}
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

enum {
    COMMAND_NONE,
    COMMAND_STEP_BACKWARD,
    COMMAND_STEP_FORWARD,
    COMMAND_SEEK,
    COMMAND_PLAY,
    COMMAND_PAUSE,
};

@interface MMovie_FFmpeg : MMovie
{
    AVFormatContext* _formatContext;

    // video
    int _videoStreamIndex;
    #define _videoStream        _formatContext->streams[_videoStreamIndex]
    #define _videoContext       _videoStream->codec

    // audio
    int _speakerCount;
    #define MAX_AUDIO_STREAM_COUNT  8
    int _audioStreamCount;
    int _audioStreamIndex[MAX_AUDIO_STREAM_COUNT];
    int _firstAudioStreamId;
    #define _audioStream(i)     _formatContext->streams[_audioStreamIndex[i]]
    #define _audioContext(i)    _audioStream(i)->codec

    // rebuild index
    int _indexStreamId;
    AVFormatContext* _indexContext;
    AVCodecContext* _indexCodec;
    BOOL _indexingCompleted;
    BOOL _needIndexing;
    int _maxFrameSize;
    int64_t _currentIndexingPosition;

    // playback: control
    int _command;
    int _reservedCommand;
    NSConditionLock* _commandLock;
    NSLock* _avSyncMutex;
    NSLock* _frameReadMutex;
    BOOL _quitRequested;
    BOOL _dispatchPacket;
    BOOL _seekComplete;
    BOOL _playThreading;
    BOOL _fileEnded;

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
    
    // playback: decoding
    #define RGB_PIXEL_FORMAT    PIX_FMT_YUV422
    //#define RGB_PIXEL_FORMAT    PIX_FMT_BGRA    // PIX_FMT_ARGB is not supported by ffmpeg
    #define MAX_VIDEO_DATA_BUF_SIZE 8
    PacketQueue* _videoQueue;
    AudioUnit _audioUnit[MAX_AUDIO_STREAM_COUNT];
    AVFrame* _videoFrame;    // for decoding
    AVFrame* _videoFrameData[MAX_VIDEO_DATA_BUF_SIZE]; // for display
    NSMutableArray* _audioDataQueue;
    struct SwsContext* _scalerContext;
    AVPacket _flushPacket;
    int _decodedImageCount;
    int _decodedImageBufCount;
    double _currentTime;
    double _prevImageTime;
    double _decodedImageTime[MAX_VIDEO_DATA_BUF_SIZE];
    int _videoDataBufId;
    int _nextVideoBufId;
    double _nextDecodedAudioTime[MAX_AUDIO_STREAM_COUNT];
    double _hostTimeFreq;
    double _hostTime;
    double _hostTime0point;
    double _avFineTuningTime;
}

+ (NSString*)name;

- (BOOL)initFFmpegWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode;
- (void)cleanupFFmpeg;
- (BOOL)initDecoder:(AVCodecContext*)context codec:(AVCodec*)codec
           forVideo:(BOOL)forVideo;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
/*
@interface MMovie_FFmpeg (Init)

- (BOOL)initFFmpegWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode;
- (void)cleanupFFmpeg;
- (BOOL)initDecoder:(AVCodecContext*)context codec:(AVCodec*)codec
           forVideo:(BOOL)forVideo;

@end
*/
@interface MMovie_FFmpeg (Playback)

- (BOOL)defaultFuncCondition;
- (BOOL)initPlayback:(int*)errorCode;
- (void)cleanupPlayback;

@end

@interface MMovie_FFmpeg (Audio)

- (BOOL)initAudio:(int)audioStreamIndex errorCode:(int*)errorCode;
- (void)cleanupAudio;
- (BOOL)initAudioPlayback:(int*)errorCode;
- (void)cleanupAudioPlayback;
- (void)decodeAudio:(AVPacket*)packet trackId:(int)trackId;
- (void)updateFirstAudioStreamId;
- (void)startAudio:(int)streamId;
- (void)stopAudio:(int)streamId;

@end

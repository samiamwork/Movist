//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Updated by moosoy <moosoy@gmail.com>
//  Copyright 2006 cocoable, moosoy. All rights reserved.
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
    #define _audioStream(i)     _formatContext->streams[_audioStreamIndex[i]]
    #define _audioContext(i)    _audioStream(i)->codec

    // playback: control
    enum {
        COMMAND_NONE,
        COMMAND_STEP_BACKWARD,
        COMMAND_STEP_FORWARD,
        COMMAND_SEEK,
        COMMAND_PLAY,
        COMMAND_PAUSE,
    };
    int _command;
    int _reservedCommand;
    NSConditionLock* _commandLock;
    NSLock* _avSyncMutex;
    BOOL _quitRequested;
    BOOL _dispatchPacket;
    BOOL _playThreading;

    // playback: play
    float _rate;
    BOOL _playAfterSeek;   // for continuous play after seek

    // playback: seek
    float _seekTime;
    float _reservedSeekTime;
    BOOL _seekKeyFrame;
    
    // playback: decoding
    PacketQueue* _videoQueue;
    AudioUnit _audioUnit[MAX_AUDIO_STREAM_COUNT];
    AVFrame* _videoFrame;    // for decoding
    AVFrame* _videoFrameRGB; // for display
    AudioDataQueue* _audioDataQueue[MAX_AUDIO_STREAM_COUNT];
    #define RGB_PIXEL_FORMAT    PIX_FMT_BGRA    // PIX_FMT_ARGB is not supported by ffmpeg
    struct SwsContext* _scalerContext;
    AVPacket _flushPacket;
    BOOL _imageDecoded;
    float _currentTime;
    float _decodedImageTime;
    float _nextDecodedAudioTime[MAX_AUDIO_STREAM_COUNT];
    float _hostTime;
    float _waitTime;
    
    // audio
    float _volume;
    bool _muted;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovie_FFMPEG (Init)

- (BOOL)initFFMPEGWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode;
- (void)cleanupFFMPEG;
- (BOOL)initDecoder:(AVCodecContext*)context codec:(AVCodec*)codec
           forVideo:(BOOL)forVideo;

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
/*
- (void)nextAudio:(MTrack_FFMPEG*)mTrack
        timeStamp:(const AudioTimeStamp*)timeStamp 
        busNumber:(UInt32)busNumber
      frameNumber:(UInt32)frameNumber
        audioData:(AudioBufferList*)ioData;
*/
//- (void)makeEmptyAudio:(int16_t**)buf channelNumber:(int)channelNumber bufSize:(int)bufSize;

@end

#endif  // _SUPPORT_FFMPEG

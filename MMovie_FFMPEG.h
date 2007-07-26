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
    int _audioStreamId;
    #define _audioStream(i)     _formatContext->streams[_audioStreamIndex[i]]
    #define _audioContext(i)    _audioStream(i)->codec

    // playback: control
    int _command;
    int _reservedCommand;
    NSConditionLock* _commandLock;
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
    PacketQueue* _audioPacketQueue[MAX_AUDIO_STREAM_COUNT];
    AudioUnit _audioUnit[MAX_AUDIO_STREAM_COUNT];
    AVFrame* _videoFrame;    // for decoding
    AVFrame* _videoFrameRGB; // for display
    AudioDataQueue* _audioDataQueue[MAX_AUDIO_STREAM_COUNT];
    UInt8 _audioBuf[AVCODEC_MAX_AUDIO_FRAME_SIZE];
    #define RGB_PIXEL_FORMAT    PIX_FMT_BGRA    // PIX_FMT_ARGB is not supported by ffmpeg
    struct SwsContext* _scalerContext;
    AVPacket _flushPacket;
    BOOL _imageDecoded;
    BOOL _audioDecoded;
    float _currentTime;
    float _decodedImageTime;
    float _decodedAudioTime;
    float _nextDecodedAudioTime[MAX_AUDIO_STREAM_COUNT];
    float _prevVideoTime;
    float _waitTime;
    int _decodedAudioDataSize;
    int _usedAudioDataSize;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovie_FFMPEG (Init)

- (BOOL)initFFMPEGWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode;
- (void)cleanupFFMPEG;

@end

@interface MMovie_FFMPEG (Playback)

- (BOOL)initPlayback:(int*)errorCode;
- (void)cleanupPlayback;

@end

@interface MMovie_FFMPEG (Audio)

- (BOOL)initAudioPlayback:(int*)errorCode;
- (void)cleanupAudioPlayback;
- (void)nextAudio:(MTrack_FFMPEG*)mTrack
        timeStamp:(const AudioTimeStamp*)timeStamp 
        busNumber:(UInt32)busNumber
      frameNumber:(UInt32)frameNumber
        audioData:(AudioBufferList*)ioData;

@end

#endif  // _SUPPORT_FFMPEG

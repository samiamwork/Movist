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

#import "Movist.h"

#include <CoreVideo/CVOpenGLTexture.h>
#include <CoreVideo/CVOpenGLTextureCache.h>
#include <AudioUnit/AudioUnit.h>
#include "ColorConversions.h"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
//#import <libswscale/swscale.h>

@interface FFContext : NSObject
{
    int _streamIndex;
    AVStream* _stream;
}

+ (id)contextWithAVStream:(AVStream*)stream index:(int)index;
- (id)initWithAVStream:(AVStream*)stream index:(int)index;

- (int)streamIndex;
- (AVStream*)stream;

- (BOOL)initContext:(int*)errorCode;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

extern AVPacket s_flushPacket;

@class MMovie_FFmpeg;

@interface FFTrack : FFContext
{
    MMovie_FFmpeg* _movie;
    BOOL _enabled;
    BOOL _running;
    BOOL _dataPoppingStarted;
}

- (void)setMovie:(MMovie_FFmpeg*)movie;

- (BOOL)initTrack:(int*)errorCode;
- (void)cleanupTrack;
- (void)quit;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (void)putPacket:(AVPacket*)packet;
- (BOOL)isDataPoppingStarted;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@class PacketQueue;
@class ImageQueue;

@interface FFVideoTrack : FFTrack
{
    PacketQueue* _packetQueue;
    AVFrame* _frame;   // for decoding
    ImageQueue* _imageQueue;
    ColorConversionFuncs _colorConvFunc;
    struct SwsContext* _scalerContext;
    CVOpenGLTextureCacheRef _textureCache;
    BOOL _needKeyFrame;
    BOOL _useFrameDrop;
    BOOL _seeked;
    BOOL _decodeStarted;
    BOOL _needPtsAdjust;
    double _frameInterval;
    double _nextFrameTime;
    double _nextFramePts;
}

+ (id)videoTrackWithAVStream:(AVStream*)stream index:(int)index;

- (BOOL)initTrack:(int*)errorCode videoQueueCapacity:(int)videoQueueCapacity;
- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error;
- (BOOL)isIndexComplete;
- (BOOL)isQueueEmpty;
- (BOOL)isQueueFull;
- (BOOL)isDecodeStarted;
- (void)clearQueue;
- (void)seek:(double)time;
- (void)enablePtsAdjust:(BOOL)enable;
- (CVOpenGLTextureRef)nextImage:(double)hostTime
                    currentTime:(double*)currentTime
                 hostTime0point:(double*)hostTime0point;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@class AudioDataQueue;
@class AudioRawDataQueue;

@interface FFAudioTrack : FFTrack
{
    float _volume;
    int _speakerCount;
    BOOL _passThrough;
    BOOL _started;
    double PTS_TO_SEC;

    AudioUnit _audioUnit;
    AudioDataQueue* _dataQueue;
    AudioRawDataQueue* _rawDataQueue;
	int16_t* _audioDataBufNotAligned;
	int16_t* _audioDataBuf;
    BOOL _bigEndian;
    AudioDeviceID _audioDev;
    AudioStreamID _digitalStream;
    AudioStreamBasicDescription _originalDesc;
    AudioStreamBasicDescription _currentDesc;
    double _nextDecodedTime;
    int _nextAudioPts;
}

+ (id)audioTrackWithAVStream:(AVStream*)stream index:(int)index;

- (BOOL)initTrack:(int*)errorCode passThrough:(BOOL)passThrough;
- (BOOL)isAc3Dts;

- (void)startAudio;
- (void)stopAudio;

- (float)volume;
- (void)setVolume:(float)volume;
- (void)setSpeakerCount:(int)count;

- (void)clearQueue;

@end

@interface FFAudioTrack (Analog)
- (BOOL)initAnalogAudio:(int*)errorCode;
- (void)cleanupAnalogAudio;
- (void)startAnalogAudio;
- (void)stopAnalogAudio;
- (void)decodePacket:(AVPacket*)packer;
- (void)clearAnalogDataQueue;
@end

@interface FFAudioTrack (Digital)
- (BOOL)initDigitalAudio:(int*)error;
- (void)cleanupDigitalAudio;
- (void)startDigitalAudio;
- (void)stopDigitalAudio;
- (void)putDigitalAudioPacket:(AVPacket*)packer;
- (void)clearDigitalDataQueue;
@end

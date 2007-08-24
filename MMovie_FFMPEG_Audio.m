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

#import "MMovie_FFMPEG.h"

#define _USE_AUDIO_DATA_FLOAT_BIT

@implementation MTrack_FFMPEG

- (id)initWithStreamId:(int)streamId movie:(MMovie_FFMPEG*)movie
{
    if (self = [super init]) {
        _streamId = streamId;
        _movie = movie;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled
{ 
    _enable = enabled; 
    [_movie updateFirstAudioStreamId];
}

- (NSString*)name 
{ 
    return [_movie streamName:(_streamId < 0) streamId:_streamId];
}

- (NSString*)format
{
    return [_movie streamFormat:(_streamId < 0) streamId:_streamId];
}

- (void)dealloc { [super dealloc]; }
- (BOOL)isEnabled { return _enable; }
- (float)volume { return _volume; }
- (void)setVolume:(float)volume { _volume = volume; }
- (int)streamId { return _streamId; }
- (MMovie_FFMPEG*)movie { return _movie; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

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

@implementation AudioDataQueue

- (id)initWithCapacity:(unsigned int)capacity
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, capacity);
    self = [super init];
    if (self) {
        _data = malloc(sizeof(UInt8) * capacity);
        _mutex = [[NSRecursiveLock alloc] init];
        _capacity = capacity;
        _front = 0;
        _rear = 0;
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    free(_data);
    [_mutex dealloc];
    [super dealloc];
}

- (void)clear { 
    [_mutex lock];
    _rear = _front;
    [_mutex unlock];
}

- (BOOL)isEmpty { return (_front == _rear); }
- (BOOL)isFull { return (_front == (_rear + 1) % _capacity); }
- (int)bitRate { return _bitRate; }

- (int)dataSize
{
    [_mutex lock];
    int size = (_capacity + _rear - _front) % _capacity;
    [_mutex unlock];
    return size;
}

- (int)freeSize
{
    return _capacity - 1 - [self dataSize];
}

- (void)setBitRate:(int)bitRate
{
    _bitRate = bitRate;
}

- (BOOL)putData:(UInt8*)data size:(int)size time:(double)time;
{
    [_mutex lock];
    if ([self freeSize] < size) {
        [_mutex unlock];
        return FALSE;
    }
    int i;
    int rear = _rear;
    for (i = 0; i < size; i++) {
        _data[rear] = data[i];
        rear = (rear + 1) % _capacity;
    }
    _time = time + 1. * size / _bitRate;
    _rear = rear;
    [_mutex unlock];
    return TRUE;
}

- (BOOL)getData:(UInt8*)data size:(int)size time:(float*)time;
{
    [_mutex lock];
    if ([self dataSize] < size) {
        [_mutex unlock];
        return FALSE;
    }
    *time = _time -  1. * ([self dataSize] - size)/ _bitRate;
    int i;
    for (i = 0; i < size; i++) {
        data[i] = _data[_front];
        _front = (_front + 1) % _capacity;
    }
    [_mutex unlock];
    return TRUE;
}

- (void)removeDataDuring:(float)dt time:(float*)time;
{
    int size = 1. * dt * _bitRate;
    [_mutex lock];
    int dataSize = [self dataSize];
    if (dataSize < size) {
        size = dataSize;
    }
    _front = (_front + size) % _capacity;
    *time = _time - 1. * ([self dataSize] - size) / _bitRate;
    [_mutex unlock];
}

/*
- (void)removeDate:(float)upTo time:(float*)time;
{
    [_mutex lock];
    if (_time <= upTo) {
        [_mutex unlock];
        return;
    }    
    int size = (_time - upTo) * _bitRate;
    int dataSize = [self dataSize];
    if (dataSize < size) {
        size = dataSize;
    }
    _front = (_front + size) % _capacity;
    *time = _time - 1. * ([self dataSize] - size) / _bitRate;
    [_mutex unlock];
}
*/

- (void)getFirstTime:(float*)time;
{
    [_mutex lock];
    *time = _time - 1. * [self dataSize] / _bitRate;
    [_mutex unlock];
}
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
OSStatus audioProc(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags,
                   const AudioTimeStamp* inTimeStamp,
                   UInt32 inBusNumber, UInt32 inNumberFrames,
                   AudioBufferList* ioData);


////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie_FFMPEG (Audio)

- (BOOL)createAudioUnit:(AudioUnit*)audioUnit
          audioStreamId:(int)audioStreamId
             sampleRate:(Float64)sampleRate audioFormat:(UInt32)formatID
            formatFlags:(UInt32)formatFlags bytesPerPacket:(UInt32)bytesPerPacket
        framesPerPacket:(UInt32)framesPerPacket bytesPerFrame:(UInt32)bytesPerFrame
       channelsPerFrame:(SInt32)channelsPerFrame bitsPerChannel:(UInt32)bitsPerChannel
{
    ComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_DefaultOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    Component component = FindNextComponent(0, &desc);
    if (!component) {
        TRACE(@"%s FindNextComponent() failed", __PRETTY_FUNCTION__);
        return FALSE;
    }
    OSStatus err = OpenAComponent(component, audioUnit);
    if (!component) {
        TRACE(@"%s OpenAComponent() failed : %ld\n", err);
        return FALSE;
    }
    
    AURenderCallbackStruct input;
    input.inputProc = audioProc;
    input.inputProcRefCon = [_audioTracks objectAtIndex:audioStreamId];
    err = AudioUnitSetProperty(*audioUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0, &input, sizeof(input));
    if (err != noErr) {
        TRACE(@"%s AudioUnitSetProperty(callback) failed : %ld\n", __PRETTY_FUNCTION__, err);
        return FALSE;
    }
    
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mFormatID = formatID;
    streamFormat.mFormatFlags = formatFlags;
    streamFormat.mBytesPerPacket = bytesPerPacket;
    streamFormat.mFramesPerPacket = framesPerPacket;
    streamFormat.mBytesPerFrame = bytesPerFrame;
    streamFormat.mChannelsPerFrame = channelsPerFrame;
    streamFormat.mBitsPerChannel = bitsPerChannel;
    err = AudioUnitSetProperty(*audioUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               0, &streamFormat, sizeof(streamFormat));
    if (err != noErr) {
        TRACE(@"%s AudioUnitSetProperty(streamFormat) failed : %ld\n", __PRETTY_FUNCTION__, err);
        return FALSE;
    }
    
    // Initialize unit
    err = AudioUnitInitialize(*audioUnit);
    if (err) {
        TRACE(@"AudioUnitInitialize=%ld", err);
        return FALSE;
    }
    
    Float64 outSampleRate;
    UInt32 size = sizeof(Float64);
    err = AudioUnitGetProperty (*audioUnit,
                                kAudioUnitProperty_SampleRate,
                                kAudioUnitScope_Output,
                                0,
                                &outSampleRate,
                                &size);
    if (err) {
        TRACE(@"AudioUnitSetProperty-GF=%4.4s, %ld", (char*)&err, err);
        return FALSE;
    }
    return TRUE;
}

- (BOOL)initAudio:(int)audioStreamIndex errorCode:(int*)errorCode
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, audioStreamIndex);

    _speakerCount = 2;
    [_audioTracks addObject:[[[MTrack_FFMPEG alloc] 
                              initWithStreamId:_audioStreamCount movie:self] 
                             autorelease]];

    AVCodecContext* audioContext = _formatContext->streams[audioStreamIndex]->codec;
    
    // FIXME: hack for DTS;
    if (audioContext->codec_id == CODEC_ID_DTS && 
        audioContext->channels == 5) {
        TRACE(@"dts audio channel is 5? maybe 6...");
        audioContext->channels = 6;
    }  
    /*
    if (audioContext->codec_id == CODEC_ID_DTS && 
        audioContext->channels > 2 && 
        _speakerCount == 2) {
        TRACE(@"dts audio downmix to 2");
        audioContext->channels = 2;
    } 
    */
    AVCodec* codec = avcodec_find_decoder(audioContext->codec_id);
    if (!codec) {
        *errorCode = ERROR_FFMPEG_DECODER_NOT_FOUND;
        return FALSE;
    }
    if (![self initDecoder:audioContext codec:codec forVideo:FALSE]) {
        *errorCode = ERROR_FFMPEG_CODEC_OPEN_FAILED;
        return FALSE;
    }
	UInt32 formatFlags, bytesPerFrame, bytesInAPacket, bitsPerChannel;
    assert(audioContext->sample_fmt == SAMPLE_FMT_S16);
#ifdef _USE_AUDIO_DATA_FLOAT_BIT
    formatFlags =  kAudioFormatFlagsNativeFloatPacked
                                | kAudioFormatFlagIsNonInterleaved;
    bytesPerFrame = 4;
    bytesInAPacket = 4;
    bitsPerChannel = 32;    
#else
    formatFlags =  kLinearPCMFormatFlagIsSignedInteger
								| kAudioFormatFlagsNativeEndian
								| kLinearPCMFormatFlagIsPacked
								| kAudioFormatFlagIsNonInterleaved;
    bytesPerFrame = 2;
    bytesInAPacket = 2;
    bitsPerChannel = 16;    
#endif
    // create audio unit
    if (![self createAudioUnit:&_audioUnit[_audioStreamCount]
                 audioStreamId:_audioStreamCount
                    sampleRate:audioContext->sample_rate
				   audioFormat:kAudioFormatLinearPCM
                   formatFlags:formatFlags
                bytesPerPacket:bytesInAPacket
               framesPerPacket:1
                 bytesPerFrame:bytesPerFrame
              channelsPerFrame:audioContext->channels
                bitsPerChannel:bitsPerChannel]) {
        *errorCode = ERROR_FFMPEG_AUDIO_UNIT_CREATE_FAILED;
        return FALSE;
    }
    _audioStreamIndex[_audioStreamCount++] = audioStreamIndex;
    return TRUE;
}

- (void)cleanupAudio
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        avcodec_close(_audioContext(i));
        _audioStreamIndex[i] = -1;
    }
}

- (BOOL) initAudioPlayback:(int*)errorCode
{
    if (_audioStreamCount <= 0) {
        return true;
    }
    int i;
    for (i = 0 ; i < _audioStreamCount; i++) {
        [[_audioDataQueue objectAtIndex:i] setBitRate: sizeof(int16_t) * _audioContext(i)->sample_rate * _audioContext(i)->channels];
        _nextDecodedAudioTime[i] = 0;
        verify_noerr(AudioOutputUnitStart (_audioUnit[i]));
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, false);
    }
    [[_audioTracks objectAtIndex:0] setEnabled:TRUE];
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
    return true;
}

- (void)cleanupAudioPlayback
{   
    TRACE(@"%s", __PRETTY_FUNCTION__);    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        verify_noerr(AudioOutputUnitStop(_audioUnit[i]));
        verify_noerr(AudioUnitUninitialize(_audioUnit[i]));
        CloseComponent(_audioUnit[i]);
    }
    while (_playThreading) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    [_audioDataQueue release];
    _audioDataQueue = 0;
}

- (void)decodeAudio:(AVPacket*)packet trackId:(int)trackId
{
    MTrack_FFMPEG* mTrack = [_audioTracks objectAtIndex:trackId];
    if (![mTrack isEnabled]) {
        return;
    }
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if (packet->data == _flushPacket.data) {
        avcodec_flush_buffers(_audioContext(trackId));
        return;
    }
    if (packet->stream_index != _audioStreamIndex[trackId]) {
        NSLog(@"packet.stream_index != _audioStreamIndex");
        assert(FALSE);
    }
    UInt8* packetPtr = packet->data;
    int packetSize = packet->size;
    int16_t audioBuf[AVCODEC_MAX_AUDIO_FRAME_SIZE];
    AudioDataQueue* audioDataQueue = [_audioDataQueue objectAtIndex:trackId];
    int dataSize, decodedSize, pts, nextPts;
    double decodedAudioTime;
    BOOL newPacket = true;
    while (0 < packetSize) {
        dataSize = AVCODEC_MAX_AUDIO_FRAME_SIZE;
        decodedSize = avcodec_decode_audio2(_audioContext(trackId),
                                            audioBuf, &dataSize,
                                            packetPtr, packetSize);
        if (decodedSize < 0) { 
            NSLog(@"decodedSize < 0");
            break;
        }
        packetPtr  += decodedSize;
        packetSize -= decodedSize;
        if (newPacket) {
            newPacket = FALSE;
            if (packet->dts != AV_NOPTS_VALUE) {
                pts = packet->dts;
                nextPts = pts;
            }
            else {
                NSLog(@"packet.dts == AV_NOPTS_VALUE");
                assert(FALSE);
            }
        }
        if (dataSize > 0) {
            nextPts = pts +  1. * dataSize / [audioDataQueue bitRate] / av_q2d(_audioStream(trackId)->time_base);
        }
        decodedAudioTime = 1. * pts * av_q2d(_audioStream(trackId)->time_base);
        pts = nextPts;
        if (0 < dataSize) {
            if (AVCODEC_MAX_AUDIO_FRAME_SIZE < dataSize) {
                NSLog(@"AVCODEC_MAX_AUDIO_FRAME_SIZE < dataSize");
                assert(FALSE);
            }
            while (!_quitRequested && [audioDataQueue freeSize] < dataSize) {
                if (_reservedCommand == COMMAND_SEEK || 
                    ![mTrack isEnabled]) {
                    break;
                }
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            }
            [audioDataQueue putData:(UInt8*)audioBuf size:dataSize time:decodedAudioTime];
        }
    }
    if (packet->data) {
        av_free_packet(packet);
    }
    [pool release];
}

#ifdef _USE_AUDIO_DATA_FLOAT_BIT
    #define AUDIO_DATA_TYPE float
#else
    #define AUDIO_DATA_TYPE int16_t
#endif

- (void)updateFirstAudioStreamId
{
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        if ([[_audioTracks objectAtIndex:i] isEnabled]) {
            _firstAudioStreamId = i;
            return;
        }
    }
    _firstAudioStreamId = -1;
}

- (void)makeEmptyAudio:(AUDIO_DATA_TYPE**)buf channelNumber:(int)channelNumber bufSize:(int)bufSize
{
    int i;
    for (i = 0; i < channelNumber; i++) {
        memset(buf[i], 0, bufSize * sizeof(AUDIO_DATA_TYPE));
    }
}

- (void)setAvFineTuning:(int)streamId fineTuningTime:(float)time
{
    if (streamId == _firstAudioStreamId) {
        _avFineTuningTime = time;
        if (time != 0) {
            TRACE(@"finetuning %f", time);
        }
    }
}

- (void)nextAudio:(MTrack_FFMPEG*)mTrack
        timeStamp:(const AudioTimeStamp*)timeStamp 
        busNumber:(UInt32)busNumber
      frameNumber:(UInt32)frameNumber
        audioData:(AudioBufferList*)ioData
{
    const int MAX_AUDIO_CHANNEL_SIZE = 8;
    const int AUDIO_BUF_SIZE = 44000 * MAX_AUDIO_CHANNEL_SIZE / 30;

	int i, j;
    int frameSize = sizeof(int16_t);  // int16
    int streamId = [mTrack streamId];
    int channelNumber = ioData->mNumberBuffers;
	int requestSize = frameNumber * frameSize * channelNumber;
    float* audioTime = &_nextDecodedAudioTime[streamId];
    AudioDataQueue* dataQueue = [_audioDataQueue objectAtIndex:streamId];
    AUDIO_DATA_TYPE* dst[MAX_AUDIO_CHANNEL_SIZE];
    assert(AUDIO_BUF_SIZE > requestSize);
	for (i = 0; i < channelNumber; i++) {
		dst[i] = ioData->mBuffers[i].mData;
        assert(ioData->mBuffers[i].mDataByteSize == 4 * frameNumber);
        assert(ioData->mBuffers[i].mNumberChannels == 1);
	}
    
    if (![mTrack isEnabled] || 
        ![self defaultFuncCondition] || _command != COMMAND_PLAY ||
        [dataQueue dataSize] < requestSize) {
        [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
        [dataQueue getFirstTime:audioTime];
        [self setAvFineTuning:streamId fineTuningTime:0];
        return;
    }
    
    float currentAudioTime = 1. * timeStamp->mHostTime / 1000 / 1000 / 1000;
    [_avSyncMutex lock];
    float currentTime = _currentTime + (currentAudioTime - _hostTime);
    [_avSyncMutex unlock];    
    [dataQueue getFirstTime:audioTime];
    
    if (currentTime + 0.05 < *audioTime) {
        if (currentTime + 0.2 < *audioTime) {
            [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
            [self setAvFineTuning:streamId fineTuningTime:0];
            TRACE(@"currentTime(%f) < audioTime[%d] %f", currentTime, streamId, *audioTime);
            return;
        }
        float dt = *audioTime - currentTime;
        [self setAvFineTuning:streamId fineTuningTime:dt];
    }
    else if (*audioTime != 0 && *audioTime + 0.05 < currentTime) {
        if (*audioTime + 0.2 < currentTime) {
            float gap = 0.2/*currentTime - *audioTime*/; // FIXME
            TRACE(@"currentTime(%f) > audioTime[%d] %f", currentTime, streamId, *audioTime);
            [dataQueue removeDataDuring:gap time:audioTime];
            [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
            [self setAvFineTuning:streamId fineTuningTime:0];
            return;
        }
        float dt = *audioTime - currentTime;
        [self setAvFineTuning:streamId fineTuningTime:dt];
    }
    else {
        [self setAvFineTuning:streamId fineTuningTime:0];
    }

    int16_t audioBuf[AUDIO_BUF_SIZE];
    [dataQueue getData:(UInt8*)audioBuf size:requestSize time:audioTime];
    float volume = _muted ? 0 : _volume;
    for (i = 0; i < frameNumber; i++) { 
		for (j = 0; j < channelNumber; j++) {
#ifdef _USE_AUDIO_DATA_FLOAT_BIT
            dst[j][i] = 1. * volume * audioBuf[channelNumber * i + j] / INT16_MAX;			
#else
            dst[j][i] = audioBuf[channelNumber * i + j];			
#endif
        } 
	}
    if (_speakerCount == 2 && channelNumber == 6) {
        for (i = 0; i < frameNumber; i++) {
            dst[0][i] += dst[4][i] + (dst[2][i] + dst[3][i]) / 2;
            dst[1][i] += dst[5][i] + (dst[2][i] + dst[3][i]) / 2;
        }
    }
}

@end


OSStatus audioProc(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags,
                   const AudioTimeStamp* inTimeStamp,
                   UInt32 inBusNumber, UInt32 inNumberFrames,
                   AudioBufferList* ioData)
{
    MTrack_FFMPEG* mTrack = (MTrack_FFMPEG*)inRefCon;
    [[mTrack movie] nextAudio:mTrack
                    timeStamp:inTimeStamp 
                    busNumber:inBusNumber 
                  frameNumber:inNumberFrames
                    audioData:ioData];
    return noErr;
}

#endif  // _SUPPORT_FFMPEG

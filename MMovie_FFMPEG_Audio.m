#if defined(_SUPPORT_FFMPEG)

#import "MMovie_FFMPEG.h"

@interface AudioDataQueue : NSObject
{
    int _bitRate;
    UInt8* _data;
    NSLock* _mutex;
    float _time;
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
        _mutex = [[NSLock alloc] init];
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
    return (_capacity + _rear - _front) % _capacity;
}

- (int)freeSize
{
    return _capacity - 1 - [self dataSize];
}

- (void)setBitRate:(int)bitRate
{
    _bitRate = bitRate;
}

- (BOOL)putData:(UInt8*)data size:(int)size time:(float)time;
{
    if ([self freeSize] < size) {
        return FALSE;
    }
    int i;
    int rear = _rear;
    for (i = 0; i < size; i++) {
        _data[rear] = data[i];
        rear = (rear + 1) % _capacity;
    }
    [_mutex lock];
    _time = time + 1. * size / _bitRate;
    _rear = rear;
    [_mutex unlock];
    return TRUE;
}

- (BOOL)getData:(UInt8*)data size:(int)size time:(float*)time;
{
    if ([self dataSize] < size) {
        return FALSE;
    }
    [_mutex lock];
    *time = _time -  1. * ([self dataSize] - size)/ _bitRate;
    [_mutex unlock];
    int i;
    for (i = 0; i < size; i++) {
        data[i] = _data[_front];
        _front = (_front + 1) % _capacity;
    }
    return TRUE;
}

- (void)removeDataDuring:(float)dt time:(float*)time;
{
    int size = 1. * dt * _bitRate;
    int dataSize = [self dataSize];
    if (dataSize < size) {
        size = dataSize;
    }
    [_mutex lock];
    _front = (_front + size) % _capacity;
    *time = _time - 1. * ([self dataSize] - size) / _bitRate;
    [_mutex unlock];
}

- (void)getFirstTime:(float*)time;
{
    [_mutex lock];
    *time = _time - 1. * [self dataSize] / _bitRate;
    [_mutex unlock];
}
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie_FFMPEG (Audio)

- (BOOL) initAudioPlayback:(int*)errorCode
{
    _decodedAudioTime = 0;
    _audioStreamId = 1;
    _speakerCount = 2;
    
    int i;
    OSStatus err;
    for (i = 0 ; i < _audioStreamCount; i++) {
        // FIXME support only one stream for the time being.
        /*if (i != _audioStreamId) {
        continue;
        } */
        [_audioDataQueue[i] setBitRate: 2 * _audioContext(i)->sample_rate * _audioContext(i)->channels];
        _nextDecodedAudioTime[i] = 0;
        err = AudioOutputUnitStart (_audioUnit[i]);
        if (err) { printf ("AudioOutputUnitStart=%ld\n", err); return FALSE; }
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, false);
    }
    [[_audioTracks objectAtIndex:0] setEnabled:TRUE];
    [NSThread detachNewThreadSelector:@selector(audioDecodeThreadFunc:)
                             toTarget:self withObject:nil];
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
    return true;
}

- (void)cleanupAudioPlayback
{   
    verify_noerr (AudioOutputUnitStop(_audioUnit[0]));
    OSStatus err = AudioUnitUninitialize(_audioUnit[0]);
    if (err) {
        TRACE(@"AudioUnitUninitialize=%ld", err);
        return;
    }
    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        [_audioPacketQueue[i] release], _audioPacketQueue[i] = 0;
        [_audioDataQueue[i] release], _audioDataQueue[i] = 0;
    }
    
    TRACE(@"%s", __PRETTY_FUNCTION__);
}

- (void)audioDecodeThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    int i;
    UInt8 audioBuf[AVCODEC_MAX_AUDIO_FRAME_SIZE];
    AVPacket packet;
	UInt8* packetPtr;
	int packetSize, dataSize, decodedSize;
    float decodedAudioTime;
    double pts;
    MTrack_FFMPEG* mTrack;
    while (1) {
        for (i = 0; i < _audioStreamCount; i++) {
            mTrack = [_audioTracks objectAtIndex:i];
            if (![mTrack isEnabled]) {
                while ([_audioPacketQueue[i] getPacket:&packet]);
                continue;
            }
            if (![_audioPacketQueue[i] getPacket:&packet]) {
                continue;
            }
            if (packet.data == _flushPacket.data) {
                avcodec_flush_buffers(_audioContext(i));
                continue;
            }
            if (packet.stream_index != _audioStreamIndex[i]) {
                TRACE(@"packet.stream_index != _audioStreamIndex");
            }
            packetPtr = packet.data;
            packetSize = packet.size;
            while (0 < packetSize) {
                dataSize = AVCODEC_MAX_AUDIO_FRAME_SIZE;   // FIXME
                decodedSize = avcodec_decode_audio2(_audioContext(i),
                                                    (int16_t*)audioBuf, &dataSize,
                                                    packetPtr, packetSize);
                if (decodedSize < 0) { 
                    // error => skip the frame
                    TRACE(@"decodedSize < 0");
					exit(-1);
                    break;
                }
                packetPtr  += decodedSize;
                packetSize -= decodedSize;
                pts = 0;
                if (packet.dts != AV_NOPTS_VALUE) {
                    pts = packet.dts;
                }
                else {//if (_videoFrame->opaque && *(uint64_t*)_videoFrame->opaque != AV_NOPTS_VALUE) {
                    assert(FALSE);
                }
                decodedAudioTime = (float)(pts * av_q2d(_audioStream(i)->time_base));
                if (0 < dataSize) {
					if (AVCODEC_MAX_AUDIO_FRAME_SIZE < dataSize) {
						exit(-1);
					}
                    while ([_audioDataQueue[i] freeSize] < dataSize) {
                        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                    }
                    [_audioDataQueue[i] putData:audioBuf size:dataSize time:decodedAudioTime];
                }
                }
            }
        }
    [pool release];
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
    
    } 

- (void)makeEmptyAudio:(int16_t**)buf channelNumber:(int)channelNumber bufSize:(int)bufSize
{
    int i;
    for (i = 0; i < channelNumber; i++) {
        memset(buf[i], 0, bufSize * sizeof(UInt16));
    }
}

- (void)nextAudio:(MTrack_FFMPEG*)mTrack
        timeStamp:(const AudioTimeStamp*)timeStamp 
        busNumber:(UInt32)busNumber
      frameNumber:(UInt32)frameNumber
        audioData:(AudioBufferList*)ioData
{
    int streamId = [mTrack streamId];
	const int MAX_AUDIO_CHANNEL_SIZE = 8;
	int i, j;
	int frameSize = sizeof(int16_t);  // int16
    int channelNumber = ioData->mNumberBuffers;
	int16_t audioBuf[AVCODEC_MAX_AUDIO_FRAME_SIZE * 2];
	int requestSize = frameNumber * frameSize * channelNumber;
    int16_t* dst[MAX_AUDIO_CHANNEL_SIZE];
	for (i = 0; i < channelNumber; i++) {
		dst[i] = ioData->mBuffers[i].mData;
	}
    
    if (![mTrack isEnabled]) {
        //[_audioDataQueue[streamId] clear];
        [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
        return;
    }
    float currentAudioTime = 1. * timeStamp->mHostTime / 1000 / 1000 / 1000;
    float currentTime = _currentTime + (currentAudioTime - _prevVideoTime);
    
    if (currentTime < _nextDecodedAudioTime[streamId]) {
        if (currentTime + 0.1 < _nextDecodedAudioTime[streamId]) {
            [_audioDataQueue[streamId] getFirstTime:&_nextDecodedAudioTime[streamId]];
        }
        [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
        //TRACE(@"currentTime < audioTime[%d]", streamId);
        return;
    }
    else if (_nextDecodedAudioTime[streamId] != 0 && _nextDecodedAudioTime[streamId] + 0.1 < currentTime) {
        float gap = currentTime - _nextDecodedAudioTime[streamId];
        [_audioDataQueue[streamId] removeDataDuring:gap time:&_nextDecodedAudioTime[streamId]];
        if ([_audioDataQueue[streamId] dataSize] < requestSize) {
            [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
            return;
        }
    }
	if ([_audioDataQueue[streamId] dataSize] < requestSize) {
        //		TRACE(@"audio data is empty");
        [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
		return;
	}
    
    
	[_audioDataQueue[streamId] getData:(UInt8*)audioBuf size:requestSize time:&_nextDecodedAudioTime[streamId]];
	for (i = 0; i < frameNumber; i++) {
		for (j = 0; j < channelNumber; j++) {
            dst[j][i] = audioBuf[channelNumber * i + j];			
        }
	}
    if (_speakerCount == 2 && channelNumber == 6) {
        for (i = 0; i < frameNumber; i++) {
            dst[0][i] += dst[4][i] + (dst[2][i] + dst[3][i]) / 2;
            dst[1][i] += dst[5][i] + (dst[2][i] + dst[3][i]) / 2;
        }
    }
    //_nextDecodedAudioTime[i] += 1. * requestSize / frameSize / channelNumber / 
    //                              _audioContext(streamId)->sample_rate;
}

@end

#endif  // _SUPPORT_FFMPEG

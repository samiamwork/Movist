#if defined(_SUPPORT_FFMPEG)

#import "MMovie_FFMPEG.h"

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

@implementation MMovie_FFMPEG (Audio)

- (BOOL) initAudioPlayback:(int*)errorCode
{
    if (_audioStreamCount <= 0) {
        return true;
    }
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
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
    return true;
}

- (void)cleanupAudioPlayback
{   
    TRACE(@"%s", __PRETTY_FUNCTION__);    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        verify_noerr (AudioOutputUnitStop(_audioUnit[i]));
        OSStatus err = AudioUnitUninitialize(_audioUnit[i]);
    if (err) {
        TRACE(@"AudioUnitUninitialize=%ld", err);
        return;
    }
        CloseComponent(_audioUnit[i]);
    }
    while (_playThreading) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    for (i = 0; i < _audioStreamCount; i++) {
        [_audioDataQueue[i] release], _audioDataQueue[i] = 0;
    }
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
        TRACE(@"packet.stream_index != _audioStreamIndex");
        exit(-1);
    }
    UInt8* packetPtr = packet->data;
    int packetSize = packet->size;
    int16_t audioBuf[AVCODEC_MAX_AUDIO_FRAME_SIZE];
    int dataSize, decodedSize, pts;
    double decodedAudioTime;
    while (0 < packetSize) {
        dataSize = AVCODEC_MAX_AUDIO_FRAME_SIZE;
        decodedSize = avcodec_decode_audio2(_audioContext(trackId),
                                            audioBuf, &dataSize,
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
        if (packet->dts != AV_NOPTS_VALUE) {
            pts = packet->dts;
        }
        else {//if (_videoFrame->opaque && *(uint64_t*)_videoFrame->opaque != AV_NOPTS_VALUE) {
            TRACE(@"packet.dts == AV_NOPTS_VALUE");
            exit(-1);
        }
        decodedAudioTime = 1. * pts * av_q2d(_audioStream(trackId)->time_base);
        if (0 < dataSize) {
            if (AVCODEC_MAX_AUDIO_FRAME_SIZE < dataSize) {
                exit(-1);
            }
            while (/*[self defaultFuncCondition] && */!_quitRequested && [_audioDataQueue[trackId] freeSize] < dataSize) {
                if (_reservedCommand == COMMAND_SEEK) {
                    break;
                }
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            }
            [_audioDataQueue[trackId] putData:(UInt8*)audioBuf size:dataSize time:decodedAudioTime];
        }
    }
    [pool release];
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
    
    if (![mTrack isEnabled] || _command != COMMAND_PLAY) {
        //[_audioDataQueue[streamId] clear];
        [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
        return;
    }
    float currentAudioTime = 1. * timeStamp->mHostTime / 1000 / 1000 / 1000;
    [_avSyncMutex lock];
    float currentTime = _currentTime + (currentAudioTime - _hostTime);
    [_avSyncMutex unlock];
    
    if (currentTime < _nextDecodedAudioTime[streamId]) {
        if (currentTime + 0.1 < _nextDecodedAudioTime[streamId]) {
            [_audioDataQueue[streamId] getFirstTime:&_nextDecodedAudioTime[streamId]];
        }
        [self makeEmptyAudio:dst channelNumber:channelNumber bufSize:frameNumber];
        TRACE(@"DEBUG:currentTime(%f) < audioTime[%d] %f", currentTime, streamId, _nextDecodedAudioTime[streamId]);
        return;
    }
    else if (_nextDecodedAudioTime[streamId] != 0 && _nextDecodedAudioTime[streamId] + 0.1 < currentTime) {
        float gap = currentTime - _nextDecodedAudioTime[streamId];
        //[_audioDataQueue[streamId] removeDataDuring:gap time:&_nextDecodedAudioTime[streamId]];
        //TRACE(@"delete audio data %f", currentTime);
        TRACE(@"DEBUG:currentTime(%f) > audioTime[%d] %f", currentTime, streamId, _nextDecodedAudioTime[streamId]);
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

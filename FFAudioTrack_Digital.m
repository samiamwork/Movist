//
//  Movist
//
//  Copyright 2006, 2007, 2008 Cheol Ju. All rights reserved.
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
#import "MMovie_FFmpeg.h"

OSStatus digitalAudioProc(AudioDeviceID           device,
                          const AudioTimeStamp*   now,
                          const AudioBufferList*  inputData,
                          const AudioTimeStamp*   inputTime,
                          AudioBufferList*        outputData,
                          const AudioTimeStamp*   outputTime,
                          void*                   clientData);
static int AudioStreamChangeFormat(AudioStreamID i_stream_id, AudioStreamBasicDescription change_format );

@interface AudioRawDataQueue : NSObject
{
    UInt8* _data;
    double* _time;
    NSRecursiveLock* _mutex;
    unsigned int _capacity;
    unsigned int _bufferCount;
    unsigned int _front;
    unsigned int _rear;
    unsigned int _remnant;
}
@end

@implementation AudioRawDataQueue

- (id)initWithCapacity:(unsigned int)capacity
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, capacity);
    self = [super init];
    if (self) {
        _capacity = capacity;
        _bufferCount = capacity / 6144;
        _data = malloc(sizeof(UInt8) * _bufferCount * 6144);
        _time = malloc(sizeof(double) * _bufferCount);
        _mutex = [[NSRecursiveLock alloc] init];
        _front = 0;
        _rear = 0;
        _remnant = 0;
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    free(_data);
    free(_time);
    [_mutex dealloc];
    [super dealloc];
}

- (void)clear { 
    [_mutex lock];
    _rear = _front;
    [_mutex unlock];
}

- (BOOL)isEmpty { return (_front == _rear); }
- (BOOL)isFull { return (_front == (_rear + 1) % _bufferCount); }

- (int)dataSize
{
    [_mutex lock];
    int size = (_bufferCount + _rear - _front) % _bufferCount * 6144;
    [_mutex unlock];
    return size;
}

- (double)current
{
    if ([self isEmpty]) {
        return -1.;
    }
    return _time[_front];
}

- (BOOL)putData:(UInt8*)data size:(int)size time:(double)time
{
    [_mutex lock];
    if ([self isFull]) {
        [_mutex unlock];
        return FALSE;
    }
    assert(_remnant + size <= 6144);
    memcpy(&_data[6144 * _rear + _remnant], data, size);
    if (_remnant == 0) {
        _time[_rear] = time;
    }
    if (_remnant + size == 6144) {
        _rear = (_rear + 1) % _bufferCount;
        _remnant = 0;
    } 
    else {
        _remnant += size;
    }
    [_mutex unlock];
    return TRUE;
}

- (BOOL)getData:(UInt8*)data
{
    [_mutex lock];
    if ([self isEmpty]) {
        [_mutex unlock];
        return FALSE;
    }
    memcpy(data, &_data[6144 * _front], 6144);
    _front = (_front + 1) % _bufferCount;
    [_mutex unlock];
    return TRUE;
}

- (void)removeData:(double)time
{
    [_mutex lock];
    while (![self isEmpty]) {
        if (time <= _time[_front]) {
            break;
        }
        _front = (_front + 1) % _bufferCount;
    }
    [_mutex unlock];
}

@end


@implementation FFAudioTrack (Digital)

static AudioDeviceID s_audioDeviceId = 0;
static BOOL s_first = TRUE;
static AudioStreamBasicDescription s_orgDesc;

- (AudioDeviceID)getDeviceId
{
	AudioDeviceID audioDev = 0;
    UInt32 paramSize = sizeof(AudioDeviceID);
	OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
								   &paramSize, &audioDev);
	TRACE(@"%s device id=%u", __PRETTY_FUNCTION__, audioDev);
	if (err != noErr) {
		TRACE(@"failed to get device id : [%4.4s]\n", (char *)&err);
		assert(FALSE);
		return 0;
	}
	return audioDev;
}

- (BOOL)setDeviceHogMode:(BOOL)hog
{
    pid_t pid = hog ? getpid() : -1;
    OSStatus err = AudioDeviceSetProperty(_audioDev, 0, 0, FALSE, 
                                 kAudioDevicePropertyHogMode, sizeof(pid_t), &pid );
    if (err != noErr ) {
        TRACE(@"failed to set hogmode %d : [%4.4s]", hog, (char *)&err );
		assert(FALSE);
		return FALSE;
    }
	return TRUE;
}

- (BOOL)setDeviceMixable:(BOOL)mixable
{
    UInt32 paramSize = 0;
    Boolean writable, mix;
    OSStatus err = AudioDeviceGetPropertyInfo(_audioDev, 0, FALSE,
                                     kAudioDevicePropertySupportsMixing,
                                     &paramSize, &writable);
    err = AudioDeviceGetProperty(_audioDev, 0, FALSE,
                                 kAudioDevicePropertySupportsMixing,
                                 &paramSize, &mix);
    if (err != noErr && writable) {
        mix = mixable;
        err = AudioDeviceSetProperty(_audioDev, 0, 0, FALSE,
                                     kAudioDevicePropertySupportsMixing,
                                     paramSize, &mix);
    }
    if (err != noErr) {
        TRACE(@"failed to set mixmode %d : [%4.4s]\n", mixable, (char *)&err);
		return FALSE;
    }
	return TRUE;
}

- (BOOL)initDigitalAudio:(int*)error
{
	TRACE(@"%s", __PRETTY_FUNCTION__);
    OSStatus err = noErr;
    UInt32 paramSize = sizeof(AudioDeviceID);
    if (s_audioDeviceId) {
        _audioDev = s_audioDeviceId;
    }
    else {
		_audioDev = [self getDeviceId];
		if (!_audioDev) {
			return FALSE;
		}
        s_audioDeviceId = _audioDev;
    }

	[self setDeviceHogMode:TRUE];
	[self setDeviceMixable:FALSE];

    /* Retrieve all the output streams. */
    err = AudioDeviceGetPropertyInfo(_audioDev, 0, FALSE,
                                     kAudioDevicePropertyStreams,
                                     &paramSize, NULL);
    if (err != noErr) {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    int i_streams = paramSize / sizeof(AudioStreamID);
    AudioStreamID* p_streams = (AudioStreamID*)malloc(paramSize);
	assert(p_streams);
    
    err = AudioDeviceGetProperty(_audioDev, 0, FALSE,
                                 kAudioDevicePropertyStreams,
                                 &paramSize, p_streams);
    if (err != noErr) {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char *)&err);
        free(p_streams);
        return FALSE;
    }

    int i, digitalIndex = -1;
    AudioStreamBasicDescription desc;

    for( i = 0; i < i_streams && digitalIndex < 0 ; i++ ) {
        /* Find a stream with a cac3 stream */
        AudioStreamBasicDescription *p_format_list = NULL;
        int i_formats = 0, j = 0;
                
        /* Retrieve all the stream formats supported by each output stream */
        err = AudioStreamGetPropertyInfo(p_streams[i], 0,
                                         kAudioStreamPropertyPhysicalFormats,
                                         &paramSize, NULL );
        if (err != noErr ) {
            TRACE(@"could not get number of streamformats: [%4.4s]", (char *)&err );
            continue;
        }
        i_formats = paramSize / sizeof(AudioStreamBasicDescription);
        p_format_list = (AudioStreamBasicDescription*)malloc(paramSize);
		assert(p_format_list);

        err = AudioStreamGetProperty(p_streams[i], 0,
                                     kAudioStreamPropertyPhysicalFormats,
                                     &paramSize, p_format_list );
        if (err != noErr) {
            TRACE(@"could not get the list of streamformats: [%4.4s]", (char *)&err );
            if (p_format_list) {
                free(p_format_list);
            }
            continue;
        }
        
        /* Check if one of the supported formats is a digital format */
        for (j = 0; j < i_formats; j++) {
            if (p_format_list[j].mFormatID == 'IAC3' ||
                p_format_list[j].mFormatID == kAudioFormat60958AC3) {
                break;
            }
        }
        if (j == i_formats) {
            free(p_format_list);
            free(p_streams);
            return FALSE;
        }
        /* if this stream supports a digital (cac3) format, then go set it. */
        _digitalStream = p_streams[i];
        digitalIndex = i;
        
        if (s_first) {
            /* Retrieve the original format of this stream first if not done so already */
            paramSize = sizeof(s_orgDesc);
            err = AudioStreamGetProperty(_digitalStream, 0,
                                         kAudioStreamPropertyPhysicalFormat,
                                         &paramSize,
                                         &s_orgDesc);
            if (err != noErr) {
                TRACE(@"could not retrieve the original streamformat: [%4.4s]", (char *)&err );
				assert(FALSE);
            }
			s_first = FALSE;
        }
        
        for (j = 0; j < i_formats; j++) {
            if (p_format_list[j].mFormatID == 'IAC3' ||
                p_format_list[j].mFormatID == kAudioFormat60958AC3) {
                if ((int)(p_format_list[j].mSampleRate) == _stream->codec->sample_rate) {
                    TRACE(@"%s %d", __PRETTY_FUNCTION__, _stream->codec->sample_rate);
                    desc = p_format_list[j];
                    break;
                }
            }
        }
        free( p_format_list );
    }
    free( p_streams );

    if (!AudioStreamChangeFormat(_digitalStream, desc)) {
        return FALSE;
    }
    err = AudioDeviceAddIOProc(_audioDev, digitalAudioProc, (void *)self);
    if (err != noErr) {
        TRACE(@"AudioDeviceAddIOProc failed: [%4.4s]", (char *)&err );
        return FALSE;
    }
    _rawDataQueue = [[AudioRawDataQueue alloc] initWithCapacity:6144 * 256];
    return TRUE;
}

-(void) startDigitalAudio
{
	TRACE(@"%s", __PRETTY_FUNCTION__);
    if (noErr !=  AudioDeviceStart(_audioDev, digitalAudioProc)) {
        TRACE(@"AudioDeviceStart failed");
        assert(FALSE);
    }
    return;
}

-(void) stopDigitalAudio
{
	TRACE(@"%s", __PRETTY_FUNCTION__);
    if (noErr != AudioDeviceStop(_audioDev, digitalAudioProc)) {
        //_started = FALSE;
        TRACE(@"AudioDeviceStop failed");
        return;
    }
}

-(void) cleanupDigitalAudio
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    
    /* Remove IOProc callback */
    OSStatus err = AudioDeviceRemoveIOProc(_audioDev, digitalAudioProc);
    if (err != noErr) {
        TRACE(@"AudioDeviceRemoveIOProc failed: [%4.4s]", (char *)&err );
    }
    if (!AudioStreamChangeFormat(_digitalStream, s_orgDesc)) {
        assert(FALSE);
    }
	[self setDeviceMixable:TRUE];
    
/*
    err = AudioHardwareRemovePropertyListener(kAudioHardwarePropertyDevices,
                                              HardwareListener );
    
    if (err != noErr) {
        TRACE(@"AudioHardwareRemovePropertyListener failed: [%4.4s]", (char *)&err );
    }    
*/
	[self setDeviceHogMode:FALSE];
    _audioDev = 0;
    [_rawDataQueue release];
    _rawDataQueue = 0;
}

-(void) enqueueAc3Data:(AVPacket*)packet
{
    static const UInt8 HEADER[] = {0x72, 0xf8, 0x1f, 0x4e, 0x01, 0x00};        
    UInt8 buffer[6144];
    UInt8* packetPtr = packet->data;
    int packetSize = packet->size;
    int i;
    for (i = 0; i < sizeof(HEADER); i++) {
        buffer[i] = HEADER[i];
    }
    buffer[5] = packetPtr[5] & 0x07; /* bsmod */
    buffer[6] = ((packetSize / 2)<< 4) & 0xff;
    buffer[7] = ((packetSize / 2)>> 4) & 0xff;
    swab(packetPtr, buffer + 8, packetSize);
    for (i = packetSize + 8; i < 6144; i++) {
        buffer[i] = 0;
    }
    double decodedAudioTime = (double)1. * packet->dts * PTS_TO_SEC;
    [_rawDataQueue putData:buffer size:6144 time:decodedAudioTime];
}

-(void) enqueueDtsData:(AVPacket*)packet
{
    static const uint8_t HEADER[6] = { 0x72, 0xF8, 0x1F, 0x4E, 0x00, 0x00 };
    uint32_t i_ac5_spdif_type = 0x0B; // FIXME what is it?
    UInt8 buffer[6144];
    UInt8* packetPtr = packet->data;
    int packetSize = packet->size;
    memcpy(buffer, HEADER, sizeof(HEADER));
    buffer[4] = i_ac5_spdif_type;
    buffer[6] = (packetSize<< 3) & 0xFF;
    buffer[7] = (packetSize>> 5) & 0xFF;
    swab(packetPtr, buffer + 8, packetSize);
    double decodedAudioTime = (double)1. * packet->dts * PTS_TO_SEC;
	assert(packetSize + 8 <= 6144/3);
    [_rawDataQueue putData:buffer size:6144/3 time:decodedAudioTime];        
}

-(void) putDigitalAudioPacket:(AVPacket*)packet
{
    if (packet->data == s_flushPacket.data) {
        return;
    }    
    if (_stream->codec->codec_id == CODEC_ID_DTS) {
        [self enqueueDtsData:packet];
        return;
    }
    [self enqueueAc3Data:packet];
}

-(void) nextDigitalAudio:(AudioBuffer)audioBuf
               timeStamp:(const AudioTimeStamp*)timeStamp
{
	int requestSize = audioBuf.mDataByteSize;
    if (requestSize != 6144) {
        TRACE(@"request audio data size %d", requestSize);
    }
    
    if (![self isEnabled] || 
        [_movie quitRequested] ||
        [_movie reservedCommand] != COMMAND_NONE ||
        [_movie command] != COMMAND_PLAY ||
        [_rawDataQueue isEmpty]) {
        memset((uint8_t*)(audioBuf.mData), 0, audioBuf.mDataByteSize);
		//TRACE(@"no audio data");
        [_movie audioTrack:self avFineTuningTime:(double)0];
        return;
    }
    double currentAudioTime = 1. * timeStamp->mHostTime / [_movie hostTimeFreq];
    double currentTime = currentAudioTime - [_movie hostTime0point];
    double audioTime;
    audioTime = [_rawDataQueue current];
    if (currentTime + 0.02 < audioTime) {
        if (currentTime + 0.2 < audioTime) {
			memset((uint8_t*)(audioBuf.mData), 0, audioBuf.mDataByteSize);
            //TRACE(@"currentTime(%f) < audioTime[%d] %f", currentTime, streamId, audioTime);
            [_movie audioTrack:self avFineTuningTime:(double)0];
            return;
        }
        double dt = audioTime - currentTime;
        [_movie audioTrack:self avFineTuningTime:dt];
    }
    else if (audioTime != 0 && audioTime + 0.02 < currentTime) {
        if (audioTime + 0.2 < currentTime) {
            //TRACE(@"currentTime(%f) > audioTime[%d] %f data removed", currentTime, streamId, audioTime);
            [_rawDataQueue removeData:currentTime];
			memset((uint8_t*)(audioBuf.mData), 0, audioBuf.mDataByteSize);
            [_movie audioTrack:self avFineTuningTime:(double)0];
            return;
        }
        double dt = audioTime - currentTime;
        [_movie audioTrack:self avFineTuningTime:dt];
    }
    else {
        [_movie audioTrack:self avFineTuningTime:(double)0];
    }
    [_rawDataQueue getData:(UInt8*)(audioBuf.mData)];
}

- (void) clearDigitalDataQueue
{
    [_rawDataQueue clear];
}

@end

OSStatus digitalAudioProc(AudioDeviceID           device,
                          const AudioTimeStamp*   now,
                          const AudioBufferList*  inputData,
                          const AudioTimeStamp*   inputTime,
                          AudioBufferList*        outputData,
                          const AudioTimeStamp*   outputTime,
                          void*                   clientData) {
//    TRACE(@"%llu %llu", inputTime->mHostTime, outputTime->mHostTime);
    FFAudioTrack* track = (FFAudioTrack*)clientData;
    [track nextDigitalAudio:outputData->mBuffers[0]
                  timeStamp:(const AudioTimeStamp*)outputTime];
    return noErr;
}

/*****************************************************************************
 * StreamListener
 *****************************************************************************/
static OSStatus StreamListener( AudioStreamID inStream,
                               UInt32 inChannel,
                               AudioDevicePropertyID inPropertyID,
                               void * inClientData )
{
    OSStatus err = noErr;
    return err;
}

/*****************************************************************************
 * AudioStreamChangeFormat: Change i_stream_id to change_format
 *****************************************************************************/
static int AudioStreamChangeFormat(AudioStreamID i_stream_id, AudioStreamBasicDescription change_format )
{
    OSStatus            err = noErr;
    UInt32              paramSize = 0;
    int i;

#if 0
    /* Install the callback */
    err = AudioStreamAddPropertyListener( i_stream_id, 0,
                                         kAudioStreamPropertyPhysicalFormat,
                                         StreamListener, 0 );
    if( err != noErr )
    {
        TRACE(@"AudioStreamAddPropertyListener failed: [%4.4s]", (char *)&err );
        return FALSE;
    }
#endif
    
    /* change the format */
    err = AudioStreamSetProperty( i_stream_id, 0, 0,
                                 kAudioStreamPropertyPhysicalFormat,
                                 sizeof( AudioStreamBasicDescription ),
                                 &change_format );
    if( err != noErr )
    {
        TRACE(@"could not set the stream format: [%4.4s]", (char *)&err );
        return FALSE;
    }
    /* The AudioStreamSetProperty is not only asynchronious (requiring the locks)
     * it is also not atomic in its behaviour.
     * Therefore we check 5 times before we really give up.
     * FIXME: failing isn't actually implemented yet. */
    for( i = 0; i < 5; i++ )
    {
        AudioStreamBasicDescription actual_format;
        paramSize = sizeof( AudioStreamBasicDescription );
        err = AudioStreamGetProperty( i_stream_id, 0,
                                     kAudioStreamPropertyPhysicalFormat,
                                     &paramSize,
                                     &actual_format );
        
        //msg_Dbg( p_aout, STREAM_FORMAT_MSG( "actual format in use: ", actual_format ) );
        if (actual_format.mSampleRate == change_format.mSampleRate &&
            actual_format.mFormatID == change_format.mFormatID &&
            actual_format.mFramesPerPacket == change_format.mFramesPerPacket) {
            /* The right format is now active */
            break;
        }
        else {
            TRACE(@"[%s] we wait", __PRETTY_FUNCTION__);
        }
        /* We need to check again */
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
#if 0        
    /* Removing the property listener */
    err = AudioStreamRemovePropertyListener( i_stream_id, 0,
                                            kAudioStreamPropertyPhysicalFormat,
                                            StreamListener );
    if( err != noErr )
    {
        TRACE(@"AudioStreamRemovePropertyListener failed: [%4.4s]", (char *)&err );
        return FALSE;
    }
#endif
    return TRUE;
}


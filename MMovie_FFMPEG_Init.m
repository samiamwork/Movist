//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Updated by moosoy <moosoy@gmail.com>
//  Copyright 2006 cocoable, moosoy. All rights reserved.
//

#if defined(_SUPPORT_FFMPEG)

#import "MMovie_FFMPEG.h"

@implementation MMovie_FFMPEG (Init)

- (void)movieInfo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableString* s = [NSMutableString stringWithCapacity:256];
    
    [s setString:@"- format: "];
    [s appendFormat:@"%s", _formatContext->iformat->name];
    TRACE(s);
    
    [s setString:@"- duration: "];
    if (_formatContext->duration == AV_NOPTS_VALUE) {
        [s appendString:@"N/A"];
    }
    else {
        int seconds = _formatContext->duration / AV_TIME_BASE;
        int us      = _formatContext->duration % AV_TIME_BASE;
        int minutes = seconds / 60;
        [s appendFormat:@"%02d:%02d:%02d.%01d",
            minutes / 60, minutes % 60, seconds % 60, (10 * us) / AV_TIME_BASE];
    }
    TRACE(s);
    
    [s setString:@"- start: "];
    if (_formatContext->start_time != AV_NOPTS_VALUE) {
        int seconds = _formatContext->start_time / AV_TIME_BASE;
        int us      = _formatContext->start_time % AV_TIME_BASE;
        [s appendFormat:@"%d.%06d",
            seconds, (int)av_rescale(us, 1000000, AV_TIME_BASE)];
        TRACE(s);
    }
    
    [s setString:@"- bit-rate: "];
    if (_formatContext->bit_rate == 0) {
        [s appendString:@"N/A"];
    }
    else {
        [s appendFormat:@"%d kb/s", _formatContext->bit_rate / 1000];
    }
    TRACE(s);
    
    int i;
    char buf[256];
    AVStream* stream;
    for (i = 0; i < _formatContext->nb_streams; i++) {
        stream = _formatContext->streams[i];
        [s setString:@""];
        [s appendFormat:@"- stream #%d", i];
        
        if (_formatContext->iformat->flags & AVFMT_SHOW_IDS) {
            [s appendFormat:@"[0x%x]", stream->id];
        }
        if (stream->language[0] != '\0') {
            [s appendFormat:@"(%s)", stream->language];
        }
        
        avcodec_string(buf, sizeof(buf), stream->codec, 1);
        [s appendFormat:@": %s", buf];
        
        if (stream->codec->codec_type == CODEC_TYPE_VIDEO) {
            if (stream->r_frame_rate.den && stream->r_frame_rate.num) {
                [s appendFormat:@", %5.2f fps(r)", av_q2d(stream->r_frame_rate)];
            }
            else {
                [s appendFormat:@", %5.2f fps(c)", 1 / av_q2d(stream->codec->time_base)];
            }
        }
        TRACE(s);
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark common utils.

- (BOOL)initDecoder:(AVCodecContext*)context codec:(AVCodec*)codec
           forVideo:(BOOL)forVideo
{
    context->debug_mv = 0;
    context->debug = 0;
    context->workaround_bugs = 1;
    context->lowres = 0;
    if (context->lowres) {
        context->flags |= CODEC_FLAG_EMU_EDGE;
    }
    context->idct_algo = FF_IDCT_AUTO;
    if (0/*fast*/) {
        context->flags2 |= CODEC_FLAG2_FAST;
    }
    context->skip_frame = AVDISCARD_DEFAULT;
    context->skip_idct = AVDISCARD_DEFAULT;
    context->skip_loop_filter = AVDISCARD_DEFAULT;
    context->error_resilience = FF_ER_CAREFUL;
    context->error_concealment = 3;

    if (forVideo) {
        //context->get_buffer = getBuffer;
        //context->release_buffer = releaseBuffer;
        /*
         if (1000 < context->frame_rate && context->frame_rate_base == 1) {
             context->frame_rate_base = 1000;
         }
         */
    }
    int ret = avcodec_open(context, codec);
    TRACE(@"%s avcodec_open() returns %d", __PRETTY_FUNCTION__, ret);
    return (0 <= ret);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark video

- (BOOL)initVideo:(int)videoStreamIndex errorCode:(int*)errorCode
{
    TRACE(@"%s %d", __PRETTY_FUNCTION__, videoStreamIndex);
    NSAssert(0 <= _videoStreamIndex, @"Video Stream Already Init");

    // find decoder for video-stream
    _videoStreamIndex = videoStreamIndex;
    AVCodec* codec = avcodec_find_decoder(_videoContext->codec_id);
    if (!codec) {
        *errorCode = ERROR_FFMPEG_DECODER_NOT_FOUND;
        return FALSE;
    }
    if (![self initDecoder:_videoContext codec:codec forVideo:TRUE]) {
        *errorCode = ERROR_FFMPEG_CODEC_OPEN_FAILED;
        return FALSE;
    }
    
    // allocate video frame
    _videoFrame = avcodec_alloc_frame();
    if (_videoFrame == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }
    
    _videoFrameRGB = avcodec_alloc_frame();
    if (_videoFrameRGB == 0) {
        *errorCode = ERROR_FFMPEG_FRAME_ALLOCATE_FAILED;
        return FALSE;
    }

    // init sw-scaler context
    _scalerContext = sws_getContext(_videoWidth, _videoHeight, _videoContext->pix_fmt,
                                    _videoWidth, _videoHeight, RGB_PIXEL_FORMAT,
                                    SWS_BICUBIC, 0, 0, 0);
    if (!_scalerContext) {
        TRACE(@"cannot initialize conversion context");
        *errorCode = ERROR_FFMPEG_SW_SCALER_INIT_FAILED;
        return FALSE;
    }

    int bufferSize = avpicture_get_size(RGB_PIXEL_FORMAT, _videoWidth, _videoHeight);
    avpicture_fill((AVPicture*)_videoFrameRGB, malloc(bufferSize),
                   RGB_PIXEL_FORMAT, _videoWidth, _videoHeight);

    return TRUE;
}

- (void)cleanupVideo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_scalerContext) {
        av_free(_scalerContext);
        _scalerContext = 0;
    }
    if (_videoFrameRGB) {
        free(_videoFrameRGB->data[0]);
        av_free(_videoFrameRGB);
        _videoFrameRGB = 0;
    }
    if (_videoFrame) {
        av_free(_videoFrame);
        _videoFrame = 0;
    }
    if (_videoContext) {
        avcodec_close(_videoContext);
        _videoStreamIndex = -1;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark audio

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
    
    [_audioTracks addObject:[[[MTrack_FFMPEG alloc] 
                              initWithStreamId:_audioStreamCount movie:self] 
                             autorelease]];
    //AVCodecContext* audioContext = _audioContext(_audioStreamCount);
    AVCodecContext* audioContext = _formatContext->streams[audioStreamIndex]->codec;

    // find decoder for audio-stream
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
	if (audioContext->sample_fmt == SAMPLE_FMT_S16) {
		formatFlags =  kLinearPCMFormatFlagIsSignedInteger
								| kAudioFormatFlagsNativeEndian
								| kLinearPCMFormatFlagIsPacked
								| kAudioFormatFlagIsNonInterleaved;
		bytesPerFrame = 2;
        bytesInAPacket = 2;
		bitsPerChannel = 16;
	}
	else {
		assert(FALSE);
	}
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
    //SDL_CloseAudio();

    int i;
    for (i = 0; i < _audioStreamCount; i++) {
        CloseComponent(_audioUnit[i]);
        avcodec_close(_audioContext(i));
        _audioStreamIndex[i] = -1;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)initFFMPEGWithMovieURL:(NSURL*)movieURL errorCode:(int*)errorCode
{
    const char* path = [[movieURL path] UTF8String];
    if (av_open_input_file(&_formatContext, path, NULL, 0, NULL) != 0) {
        *errorCode = ERROR_FFMPEG_FILE_OPEN_FAILED;
        return FALSE;
    }
    if (av_find_stream_info(_formatContext) < 0) {
        *errorCode = ERROR_FFMPEG_STREAM_INFO_NOT_FOUND;
        return FALSE;
    }
    [self movieInfo];

    int i;
    for (i = 0; i < _formatContext->nb_streams; i++) {
        switch (_formatContext->streams[i]->codec->codec_type) {
            case CODEC_TYPE_VIDEO :
                if (![self initVideo:i errorCode:errorCode]) {
                    return FALSE;
                }
                break;
            case CODEC_TYPE_AUDIO :
                if (_audioStreamCount < MAX_AUDIO_STREAM_COUNT) {
                    [self initAudio:i errorCode:errorCode];
                    // continue even if init audio failed
                }
                break;
        }
    }
    if (_videoStreamIndex < 0) {
        *errorCode = ERROR_FFMPEG_VIDEO_STREAM_NOT_FOUND;
        return FALSE;
    }
    // continue even if no audio found

    //av_read_play(_formatContext);

    return TRUE;
}

- (void)cleanupFFMPEG
{
    [self cleanupVideo];
    [self cleanupAudio];
    av_close_input_file(_formatContext);
    _formatContext = 0;
}

@end

#endif  // _SUPPORT_FFMPEG

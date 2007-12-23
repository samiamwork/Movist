//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim. All rights reserved.
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

/* Check digital output 
 * From http://lists-archives.org/mplayer-dev-eng/20119-ac3-dts-passthrough-for-mac-os-x.html
 */

#import "AppController.h"
#import "UserDefaults.h"

#import <CoreAudio/CoreAudio.h>

static BOOL supportDigitalAudio(AudioStreamID* streamID);
static void registerAudioDeviceListener(AudioDevicePropertyListenerProc func, void* data);

static AudioStreamID _audioStreamID;

static OSStatus DeviceListener(AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput,
                               AudioDevicePropertyID inPropertyID, void* inClientData)
{
    switch (inPropertyID) {
        case kAudioDevicePropertyDeviceHasChanged: {
            //TRACE(@"got notify kAudioDevicePropertyDeviceHasChanged.\n");
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            [(AppController*)inClientData updateDigitalAudio];
            [pool release];
            break;
        }
        default:
            break;
    }
    return noErr;
}

@implementation AppController (AudioDigital)

- (BOOL)supportDigitalAudio { return _supportDigitalAudio; }

- (BOOL)updateAudioOutput:(id)dummy
{
    if (!_supportDigitalAudio) {
        [self setVolume:[_defaults floatForKey:MVolumeKey]];    // restore analog volume
        return TRUE;
    }

    OSStatus err;

    // get current format
    UInt32 paramSize = sizeof(AudioStreamBasicDescription);
    AudioStreamBasicDescription format;
    err = AudioStreamGetProperty(_audioStreamID, 0,
                                 kAudioStreamPropertyPhysicalFormat,
                                 &paramSize, &format);
    if (err != noErr) {
        TRACE(@"could not get the stream format: [%4.4s]\n", (char*)&err);
        return FALSE;
    }

    // change to 48 kHz
    format.mSampleRate = 48000.000000;

    // set as current format
    err = AudioStreamSetProperty(_audioStreamID, 0, 0,
                                 kAudioStreamPropertyPhysicalFormat,
                                 sizeof(AudioStreamBasicDescription),
                                 &format);
    if (err != noErr) {
        TRACE(@"could not set the stream format: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    [self setVolume:1.0];   // always 1.0
    return TRUE;
}

- (BOOL)updateA52CodecProperties
{
    // update "com.cod3r.a52codec.plist" for A52Codec.component if exist.
    NSString* rootPath = @"/Library/Audio/Plug-Ins/Components/A52Codec.component";
    NSString* homePath = [[@"~" stringByExpandingTildeInPath]
                                                stringByAppendingString:rootPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath] ||
        [[NSFileManager defaultManager] fileExistsAtPath:homePath]) {
        NSTask* defaults = [[NSTask alloc] init];
        [defaults setLaunchPath:@"/usr/bin/defaults"];
        [defaults setArguments:[NSArray arrayWithObjects:
                        @"write", @"com.cod3r.a52codec", @"attemptPassthrough",
                                            _supportDigitalAudio ? @"1" : @"0", nil]];
        //TRACE(@"%s \"defaults write com.cod3r.a52codec attemptPassthrough %d\"",
        //      __PRETTY_FUNCTION__, _supportDigitalAudio ? 1 : 0);
        [defaults launch];
        [defaults waitUntilExit];
        return TRUE;
    }
    return FALSE;
}

- (void)initDigitalAudio
{
    _supportDigitalAudio = supportDigitalAudio(&_audioStreamID);
    [self updateAudioOutput:nil];
    [self updateA52CodecProperties];

    registerAudioDeviceListener(DeviceListener, self);
}

- (void)updateDigitalAudio
{
    BOOL support = supportDigitalAudio(&_audioStreamID);
    if (support == _supportDigitalAudio) {
        return;
    }

    _supportDigitalAudio = support;

    [self performSelectorOnMainThread:@selector(updateAudioOutput:)
                           withObject:nil waitUntilDone:FALSE];
    BOOL a52Updated = [self updateA52CodecProperties];
    if (a52Updated && _movie) {
        // reopen current movie to use new audio device
        [self performSelectorOnMainThread:@selector(reopenMovieWithMovieClass:)
                               withObject:[_movie class] waitUntilDone:FALSE];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

static int AudioStreamSupportsDigital( AudioStreamID i_stream_id )
{
    OSStatus err = noErr;
    UInt32 paramSize;
    AudioStreamBasicDescription *p_format_list = NULL;
    int i, i_formats, b_return = FALSE;
    
    /* Retrieve all the stream formats supported by each output stream. */
    err = AudioStreamGetPropertyInfo(i_stream_id, 0,
                                     kAudioStreamPropertyPhysicalFormats,
                                     &paramSize, NULL);
    if (err != noErr) {
        TRACE(@"could not get number of streamformats: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    i_formats = paramSize / sizeof(AudioStreamBasicDescription);
    p_format_list = (AudioStreamBasicDescription *)malloc(paramSize);
    if (p_format_list == NULL) {
        TRACE(@"could not malloc the memory\n" );
        return FALSE;
    }
    
    err = AudioStreamGetProperty(i_stream_id, 0,
                                 kAudioStreamPropertyPhysicalFormats,
                                 &paramSize, p_format_list);
    if (err != noErr) {
        TRACE(@"could not get the list of streamformats: [%4.4s]\n", (char *)&err);
        free(p_format_list);
        return FALSE;
    }
    
    for (i = 0; i < i_formats; ++i) {
        //TRACE(@"supported format:", &p_format_list[i]);
        if (p_format_list[i].mFormatID == 'IAC3' ||
            p_format_list[i].mFormatID == kAudioFormat60958AC3)
            b_return = TRUE;
    }
    
    free(p_format_list);
    return b_return;
}

static int AudioDeviceSupportsDigital( AudioDeviceID i_dev_id, AudioStreamID* streamID )
{
    OSStatus                    err = noErr;
    UInt32                      paramSize = 0;
    AudioStreamID               *p_streams = NULL;
    int                         i = 0, i_streams = 0;
    
    /* Retrieve all the output streams. */
    err = AudioDeviceGetPropertyInfo(i_dev_id, 0, FALSE,
                                     kAudioDevicePropertyStreams,
                                     &paramSize, NULL);
    if (err != noErr) {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    i_streams = paramSize / sizeof(AudioStreamID);
    p_streams = (AudioStreamID *)malloc(paramSize);
    if (p_streams == NULL) {
        TRACE(@"out of memory\n");
        return FALSE;
    }
    
    err = AudioDeviceGetProperty(i_dev_id, 0, FALSE,
                                 kAudioDevicePropertyStreams,
                                 &paramSize, p_streams);
    
    if (err != noErr) {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char *)&err);
        free(p_streams);
        return FALSE;
    }
    
    for (i = 0; i < i_streams; ++i) {
        if (AudioStreamSupportsDigital(p_streams[i])) {
            *streamID = p_streams[i];
            /* Install the callback. */
            /*
            err = AudioStreamAddPropertyListener(p_streams[i], 0,
                                                 kAudioStreamPropertyPhysicalFormat,
                                                 StreamListener, 0);
            if (err != noErr) {
                TRACE(@"AudioStreamAddPropertyListener failed: [%s]\n", (char *)&err);
                return FALSE;
            }
            */
            break;
        }
    }    
    free(p_streams);
    return i < i_streams;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

static BOOL supportDigitalAudio(AudioStreamID* streamID)
{
    /* Find the ID of the default Device. */
    UInt32 paramSize = sizeof(AudioDeviceID);
    AudioDeviceID audioDev = 0;
    OSStatus err;
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                   &paramSize, &audioDev);
    if (err != noErr) {
        TRACE(@"could not get default audio device: [%4.4s]\n", (char *)&err);
        return FALSE;
    }

    /* Retrieve the length of the device name. */
    paramSize = 0;
    err = AudioDeviceGetPropertyInfo(audioDev, 0, 0,
                                     kAudioDevicePropertyDeviceName,
                                     &paramSize, NULL);
    if (err != noErr) {
        TRACE(@"could not get default audio device name length: [%4.4s]\n", (char *)&err);
        return FALSE;
    }

    /* Retrieve the name of the device. */
    char* psz_name = (char *)malloc(paramSize);
    err = AudioDeviceGetProperty(audioDev, 0, 0,
                                 kAudioDevicePropertyDeviceName,
                                 &paramSize, psz_name);
    if (err != noErr) {
        TRACE(@"could not get default audio device name: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    //TRACE(@"got default audio output device ID: %#lx Name: %s\n", audioDev, psz_name);
    
    BOOL isDigital = AudioDeviceSupportsDigital(audioDev, streamID);
    //TRACE(@"support digital s/pdif output:%d\n", isDigital);

    free( psz_name);
    return isDigital;
}

static void registerAudioDeviceListener(AudioDevicePropertyListenerProc func, void* data)
{
    /* Find the ID of the default Device. */
    UInt32 paramSize = sizeof(AudioDeviceID);
    AudioDeviceID audioDev = 0;
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &paramSize, &audioDev);
    if (err != noErr) {
        TRACE(@"could not get default audio device: [%4.4s]\n", (char *)&err);
        return;
    }
    /* add callback func */
    err = AudioDeviceAddPropertyListener(audioDev,
                                         kAudioPropertyWildcardChannel,
                                         0,
                                         kAudioDevicePropertyDeviceHasChanged,
                                         func,
                                         data);
    if (err != noErr) {
        TRACE(@"AudioDeviceAddPropertyListener failed: [%4.4s]\n", (char *)&err);
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#if 0

/*****************************************************************************
 * Setup a encoded digital stream (SPDIF)
 *****************************************************************************/
static int OpenSPDIF()
{
    OSStatus err = noErr;
    UInt32 paramSize, b_mix = 0;
    BOOL writeable;
    AudioStreamID *p_streams = NULL;
    int i, i_streams = 0;
    
    /* Start doing the SPDIF setup process. */
    // ao->b_digital = 1;
    
    /* Hog the device. */
    /*
     paramSize = sizeof(pid_t);
     ao->i_hog_pid = getpid() ;
     */
    
    err = AudioDeviceSetProperty(audioDev, 0, 0, FALSE,
                                 kAudioDevicePropertyHogMode, sizeof(pid_t), &getpid());
    
    if (err != noErr) {
        TRACE(@"failed to set hogmode: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    /* Set mixable to false if we are allowed to. */
    err = AudioDeviceGetPropertyInfo(audioDev, 0, FALSE,
                                     kAudioDevicePropertySupportsMixing,
                                     &paramSize, &writeable);
    err = AudioDeviceGetProperty(audioDev, 0, FALSE,
                                 kAudioDevicePropertySupportsMixing,
                                 &paramSize, &b_mix);
    if (err != noErr && writeable) {
        b_mix = 0;
        err = AudioDeviceSetProperty(audioDev, 0, 0, FALSE,
                                     kAudioDevicePropertySupportsMixing,
                                     paramSize, &b_mix);
        //ao->b_changed_mixing = 1;
    }
    if (err != noErr) {
        TRACE(@"failed to set mixmode: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    /* Get a list of all the streams on this device. */
    err = AudioDeviceGetPropertyInfo(audioDev, 0, FALSE,
                                     kAudioDevicePropertyStreams,
                                     &paramSize, NULL);
    if (err != noErr)
    {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    i_streams = paramSize / sizeof(AudioStreamID);
    p_streams = (AudioStreamID *)malloc(paramSize);
    if (p_streams == NULL)
    {
        TRACE(@"out of memory\n" );
        return FALSE;
    }
    
    err = AudioDeviceGetProperty(audioDev, 0, FALSE,
                                 kAudioDevicePropertyStreams,
                                 &paramSize, p_streams);
    if (err != noErr)
    {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char *)&err);
        if (p_streams) free(p_streams);
        return FALSE;
    }
    
    ao_msg(MSGT_AO, MSGL_V, "current device stream number: %d\n", i_streams);
    
    for (i = 0; i < i_streams && ao->i_stream_index < 0; ++i)
    {
        /* Find a stream with a cac3 stream. */
        AudioStreamBasicDescription *p_format_list = NULL;
        int i_formats = 0, j = 0, b_digital = 0;
        
        /* Retrieve all the stream formats supported by each output stream. */
        err = AudioStreamGetPropertyInfo(p_streams[i], 0,
                                         kAudioStreamPropertyPhysicalFormats,
                                         &paramSize, NULL);
        if (err != noErr)
        {
            TRACE(@"could not get number of streamformats: [%4.4s]\n", (char *)&err);
            continue;
        }
        
        i_formats = paramSize / sizeof(AudioStreamBasicDescription);
        p_format_list = (AudioStreamBasicDescription *)malloc(paramSize);
        if (p_format_list == NULL)
        {
            TRACE(@"could not malloc the memory\n" );
            continue;
        }
        
        err = AudioStreamGetProperty(p_streams[i], 0,
                                     kAudioStreamPropertyPhysicalFormats,
                                     &paramSize, p_format_list);
        if (err != noErr)
        {
            TRACE(@"could not get the list of streamformats: [%4.4s]\n", (char *)&err);
            if (p_format_list) free(p_format_list);
            continue;
        }
        
        /* Check if one of the supported formats is a digital format. */
        for (j = 0; j < i_formats; ++j)
        {
            if (p_format_list[j].mFormatID == 'IAC3' ||
                p_format_list[j].mFormatID == kAudioFormat60958AC3)
            {
                b_digital = 1;
                break;
            }
        }
        
        if (b_digital)
        {
            /* If this stream supports a digital (cac3) format, then set it. */
            int i_requested_rate_format = -1;
            int i_current_rate_format = -1;
            int i_backup_rate_format = -1;
            
            ao->i_stream_id = p_streams[i];
            ao->i_stream_index = i;
            
            if (ao->b_revert == 0)
            {
                /* Retrieve the original format of this stream first if not done so already. */
                paramSize = sizeof(ao->sfmt_revert);
                err = AudioStreamGetProperty(ao->i_stream_id, 0,
                                             kAudioStreamPropertyPhysicalFormat,
                                             &paramSize,
                                             &ao->sfmt_revert);
                if (err != noErr)
                {
                    TRACE(@"could not retrieve the original streamformat: [%4.4s]\n", (char *)&err);
                    if (p_format_list) free(p_format_list);
                    continue;
                }
                ao->b_revert = 1;
            }
            
            for (j = 0; j < i_formats; ++j)
                if (p_format_list[j].mFormatID == 'IAC3' ||
                    p_format_list[j].mFormatID == kAudioFormat60958AC3)
                {
                    if (p_format_list[j].mSampleRate == ao->stream_format.mSampleRate)
                    {
                        i_requested_rate_format = j;
                        break;
                    }
                    if (p_format_list[j].mSampleRate == ao->sfmt_revert.mSampleRate)
                        i_current_rate_format = j;
                    else if (i_backup_rate_format < 0 || p_format_list[j].mSampleRate > p_format_list[i_backup_rate_format].mSampleRate)
                        i_backup_rate_format = j;
                }
            
            if (i_requested_rate_format >= 0) /* We prefer to output at the samplerate of the original audio. */
                ao->stream_format = p_format_list[i_requested_rate_format];
            else if (i_current_rate_format >= 0) /* If not possible, we will try to use the current samplerate of the device. */
                ao->stream_format = p_format_list[i_current_rate_format];
            else ao->stream_format = p_format_list[i_backup_rate_format]; /* And if we have to, any digital format will be just fine (highest rate possible). */
        }
        if (p_format_list) free(p_format_list);
    }
    if (p_streams) free(p_streams);
    
    if (ao->i_stream_index < 0)
    {
        TRACE(@"can not find any digital output stream format when OpenSPDIF().\n");
        return FALSE;
    }
    
    print_format(MSGL_V, "original stream format:", &ao->sfmt_revert);
    
    if (!AudioStreamChangeFormat(ao->i_stream_id, ao->stream_format))
        return FALSE;
    
    err = AudioDeviceAddPropertyListener(ao->i_selected_dev,
                                         kAudioPropertyWildcardChannel,
                                         0,
                                         kAudioDevicePropertyDeviceHasChanged,
                                         DeviceListener,
                                         NULL);
    if (err != noErr)
        TRACE(@"AudioDeviceAddPropertyListener for kAudioDevicePropertyDeviceHasChanged failed: [%4.4s]\n", (char *)&err);
    
    
    /* FIXME: If output stream is not native byte-order, we need change endian somewhere. */
    /*        Although there's no such case reported.                                     */
#ifdef WORDS_BIGENDIAN
    if (!(ao->stream_format.mFormatFlags & kAudioFormatFlagIsBigEndian))
#else
        if (ao->stream_format.mFormatFlags & kAudioFormatFlagIsBigEndian)
#endif
            TRACE(@"output stream has a no-native byte-order, digital output may failed.\n", (char *)&err);
    
    /* For ac3/dts, just use packet size 6144 bytes as chunk size. */
    ao->chunk_size = ao->stream_format.mBytesPerPacket;
    
    ao_data.samplerate = ao->stream_format.mSampleRate;
    ao_data.channels = ao->stream_format.mChannelsPerFrame;
    ao_data.bps = ao_data.samplerate * (ao->stream_format.mBytesPerPacket/ao->stream_format.mFramesPerPacket);
    ao_data.outburst = ao->chunk_size;
    ao_data.buffersize = ao_data.bps;
    
    ao->num_chunks = (ao_data.bps+ao->chunk_size-1)/ao->chunk_size;
    ao->buffer_len = (ao->num_chunks + 1) * ao->chunk_size;
    ao->buffer = NULL!=ao->buffer ? realloc(ao->buffer,(ao->num_chunks + 1)*ao->chunk_size)
    : calloc(ao->num_chunks + 1, ao->chunk_size);
    
    ao_msg(MSGT_AO,MSGL_V, "using %5d chunks of %d bytes (buffer len %d bytes)\n", (int)ao->num_chunks, (int)ao->chunk_size, (int)ao->buffer_len);
    
    
    /* Add IOProc callback. */
    err = AudioDeviceAddIOProc(ao->i_selected_dev,
                               (AudioDeviceIOProc)RenderCallbackSPDIF,
                               (void *)ao);
    if (err != noErr)
    {
        TRACE(@"AudioDeviceAddIOProc failed: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    reset();
    
    return TRUE;
}


/*****************************************************************************
 * AudioStreamChangeFormat: Change i_stream_id to change_format
 *****************************************************************************/

static int AudioStreamChangeFormat( AudioStreamID i_stream_id, AudioStreamBasicDescription change_format )
{
    OSStatus err = noErr;
    UInt32 paramSize = 0;
    int i;
    
    struct timeval now;
    struct timespec timeout;
    struct { pthread_mutex_t lock; pthread_cond_t cond; } w;
    
    TRACE(@"setting stream format:", &change_format);
    
    /* Condition because SetProperty is asynchronious. */
    pthread_cond_init(&w.cond, NULL);
    pthread_mutex_init(&w.lock, NULL);
    pthread_mutex_lock(&w.lock);
    
    /* Install the callback. */
    err = AudioStreamAddPropertyListener(i_stream_id, 0,
                                         kAudioStreamPropertyPhysicalFormat,
                                         StreamListener, (void *)&w);
    if (err != noErr) {
        TRACE(@"AudioStreamAddPropertyListener failed: [%4.4s]\n", (char *)&err);
        return CONTROL_FALSE;
    }
    
    /* Change the format. */
    err = AudioStreamSetProperty(i_stream_id, 0, 0,
                                 kAudioStreamPropertyPhysicalFormat,
                                 sizeof(AudioStreamBasicDescription),
                                 &change_format);
    if (err != noErr) {
        TRACE(@"could not set the stream format: [%4.4s]\n", (char *)&err);
        return CONTROL_FALSE;
    }
    
    /* The AudioStreamSetProperty is not only asynchronious (requiring the locks),
     * it is also not Atomic, in its behaviour.
     * Therefore we check 5 times before we really give up.
     * FIXME: failing isn't actually implemented yet. */
    for (i = 0; i < 5; ++i) {
        AudioStreamBasicDescription actual_format;
        
        gettimeofday(&now, NULL);
        timeout.tv_sec = now.tv_sec;
        timeout.tv_nsec = (now.tv_usec + 500000) * 1000;
        
        if (pthread_cond_timedwait(&w.cond, &w.lock, &timeout))
            ao_msg(MSGT_AO, MSGL_V, "reached timeout\n" );
        
        paramSize = sizeof(AudioStreamBasicDescription);
        err = AudioStreamGetProperty(i_stream_id, 0,
                                     kAudioStreamPropertyPhysicalFormat,
                                     &paramSize,
                                     &actual_format);
        
        print_format(MSGL_V, "actual format in use:", &actual_format);
        if (actual_format.mSampleRate == change_format.mSampleRate &&
            actual_format.mFormatID == change_format.mFormatID &&
            actual_format.mFramesPerPacket == change_format.mFramesPerPacket) {
            /* The right format is now active. */
            break;
        }
        /* We need to check again. */
    }
    
    /* Removing the property listener. */
    err = AudioStreamRemovePropertyListener(i_stream_id, 0,
                                            kAudioStreamPropertyPhysicalFormat,
                                            StreamListener);
    if (err != noErr) {
        TRACE(@"AudioStreamRemovePropertyListener failed: [%4.4s]\n", (char *)&err);
        return CONTROL_FALSE;
    }
    
    /* Destroy the lock and condition. */
    pthread_mutex_unlock(&w.lock);
    pthread_mutex_destroy(&w.lock);
    pthread_cond_destroy(&w.cond);
    
    return CONTROL_TRUE;
}

/*****************************************************************************
 * RenderCallbackSPDIF: callback for SPDIF audio output
 *****************************************************************************/
static OSStatus RenderCallbackSPDIF( AudioDeviceID inDevice,
                                    const AudioTimeStamp * inNow,
                                    const void * inInputData,
                                    const AudioTimeStamp * inInputTime,
                                    AudioBufferList * outOutputData,
                                    const AudioTimeStamp * inOutputTime,
                                    void * threadGlobals )
{
    int amt = buf_used();
    int req = outOutputData->mBuffers[ao->i_stream_index].mDataByteSize;
    
    if (amt > req)
        amt = req;
    if (amt)
        read_buffer((unsigned char *)outOutputData->mBuffers[ao->i_stream_index].mData, amt);
    
    return noErr;
}


static int play(void* output_samples,int num_bytes,int flags)
{  
    int wrote, b_digital;
    
    // Check whether we need to reset the digital output stream.
    if (ao->b_digital && ao->b_stream_format_changed)
    {
        ao->b_stream_format_changed = 0;
        b_digital = AudioStreamSupportsDigital(ao->i_stream_id);
        if (b_digital)
        {
            /* Current stream support digital format output, let's set it. */
            ao_msg(MSGT_AO, MSGL_V, "detected current stream support digital, try to restore digital output...\n");
            
            if (!AudioStreamChangeFormat(ao->i_stream_id, ao->stream_format))
            {
                TRACE(@"restore digital output failed.\n");
            }
            else
            {
                TRACE(@"restore digital output succeed.\n");
                reset();
            }
        }
        else
            ao_msg(MSGT_AO, MSGL_V, "detected current stream do not support digital.\n");
    }
    
    wrote=write_buffer(output_samples, num_bytes);
    audio_resume();
    return wrote;
}

/* set variables and buffer to initial state */
@@ -402,17 +1026,64 @@
/* unload plugin and deregister from coreaudio */
static void uninit(int immed)
{
    OSStatus            err = noErr;
    UInt32              paramSize = 0;
    
    if (!immed) {
        long long timeleft=(1000000LL*buf_used())/ao_data.bps;
        ao_msg(MSGT_AO,MSGL_DBG2, "%d bytes left @%d bps (%d usec)\n", buf_used(), ao_data.bps, (int)timeleft);
        usec_sleep((int)timeleft);
    }
    
    if (!ao->b_digital) {
        AudioOutputUnitStop(ao->theOutputUnit);
        AudioUnitUninitialize(ao->theOutputUnit);
        CloseComponent(ao->theOutputUnit);
    }
    else {
        /* Stop device. */
        err = AudioDeviceStop(ao->i_selected_dev,
                              (AudioDeviceIOProc)RenderCallbackSPDIF);
        if (err != noErr)
            TRACE(@"AudioDeviceStop failed: [%4.4s]\n", (char *)&err);
        
        /* Remove IOProc callback. */
        err = AudioDeviceRemoveIOProc(ao->i_selected_dev,
                                      (AudioDeviceIOProc)RenderCallbackSPDIF);
        if (err != noErr)
            TRACE(@"AudioDeviceRemoveIOProc failed: [%4.4s]\n", (char *)&err);
        
        if (ao->b_revert)
            AudioStreamChangeFormat(ao->i_stream_id, ao->sfmt_revert);
        
        if (ao->b_changed_mixing && ao->sfmt_revert.mFormatID != kAudioFormat60958AC3)
        {
            int b_mix;
            Boolean b_writeable;
            /* Revert mixable to true if we are allowed to. */
            err = AudioDeviceGetPropertyInfo(ao->i_selected_dev, 0, FALSE, kAudioDevicePropertySupportsMixing,
                                             &paramSize, &b_writeable);
            err = AudioDeviceGetProperty(ao->i_selected_dev, 0, FALSE, kAudioDevicePropertySupportsMixing,
                                         &paramSize, &b_mix);
            if (err != noErr && b_writeable)
            {
                b_mix = 1;
                err = AudioDeviceSetProperty(ao->i_selected_dev, 0, 0, FALSE,
                                             kAudioDevicePropertySupportsMixing, paramSize, &b_mix);
            }
            if (err != noErr)
                TRACE(@"failed to set mixmode: [%4.4s]\n", (char *)&err);
        }
        if (ao->i_hog_pid == getpid())
        {
            ao->i_hog_pid = -1;
            paramSize = sizeof(ao->i_hog_pid);
            err = AudioDeviceSetProperty(ao->i_selected_dev, 0, 0, FALSE,
                                         kAudioDevicePropertyHogMode, paramSize, &ao->i_hog_pid);
            if (err != noErr) TRACE(@"Could not release hogmode: [%4.4s]\n", (char *)&err);
        }
    }
    
    free(ao->buffer);
    free(ao);
    ao = NULL;
}
/* stop playing, keep buffers (for pause) */
static void audio_pause(void)
{
    OSErr err=noErr;
    
    /* Stop callback. */
    if (!ao->b_digital)
    {
        err=AudioOutputUnitStop(ao->theOutputUnit);
        if (err != noErr)
            ao_msg(MSGT_AO,MSGL_WARN, "AudioOutputUnitStop returned [%4.4s]\n", (char *)&err);
    }
    else
    {
        err = AudioDeviceStop(ao->i_selected_dev, (AudioDeviceIOProc)RenderCallbackSPDIF);
        if (err != noErr)
            TRACE(@"AudioDeviceStop failed: [%4.4s]\n", (char *)&err);
    }
    ao->paused = 1;
}


/* resume playing, after audio_pause() */
static void audio_resume(void)
{
    OSErr err=noErr;
    
    if (!ao->paused)
        return;
    
    /* Start callback. */
    if (!ao->b_digital)
    {
        err = AudioOutputUnitStart(ao->theOutputUnit);
        if (err != noErr)
            ao_msg(MSGT_AO,MSGL_WARN, "AudioOutputUnitStart returned [%4.4s]\n", (char *)&err);
    }
    else
    {
        err = AudioDeviceStart(ao->i_selected_dev, (AudioDeviceIOProc)RenderCallbackSPDIF);
        if (err != noErr)
            TRACE(@"AudioDeviceStart failed: [%4.4s]\n", (char *)&err);
    }
    ao->paused = 0;
}

/*****************************************************************************
 * StreamListener
 *****************************************************************************/
static OSStatus StreamListener( AudioStreamID inStream,
                               UInt32 inChannel,
                               AudioDevicePropertyID inPropertyID,
                               void * inClientData )
{
    struct { pthread_mutex_t lock; pthread_cond_t cond; } * w = inClientData;
    
    switch (inPropertyID)
    {
        case kAudioStreamPropertyPhysicalFormat:
            if (NULL!=w)
            {
                pthread_mutex_lock(&w->lock);
                pthread_cond_signal(&w->cond);
                pthread_mutex_unlock(&w->lock);
            }
            default:
            break;
    }
    return noErr;
}

static OSStatus DeviceListener( AudioDeviceID inDevice,
                               UInt32 inChannel,
                               Boolean isInput,
                               AudioDevicePropertyID inPropertyID,
                               void* inClientData )
{
    switch (inPropertyID)
    {
        case kAudioDevicePropertyDeviceHasChanged:
            TRACE(@"got notify kAudioDevicePropertyDeviceHasChanged.\n");
            // FIXME:
            // ao->b_stream_format_changed = 1;
        default:
            break;
    }
    return noErr;
}

#endif
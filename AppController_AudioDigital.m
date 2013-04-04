//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
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
#import "MMovie_QuickTime.h"

#import <CoreAudio/CoreAudio.h>

static BOOL audioDeviceSupportsDigital(AudioStreamID* streamID);
static void registerAudioDeviceListener(AudioObjectPropertyListenerProc proc, void* data);
static OSStatus audioDeviceListener(AudioObjectID device, UInt32 inNumberOfAddresses,
									const AudioObjectPropertyAddress inAddresses[], void* inClientData);
static AudioStreamID _audioStreamID;

@implementation AppController (AudioDigital)

- (BOOL)isCurrentlyDigitalAudioOut
{
    if (!_movie || !_audioDeviceSupportsDigital ||
        ![_defaults boolForKey:MAutodetectDigitalAudioOutKey]) {
        return FALSE;
    }

    return ([_movie hasAC3Codec] && [_movie supportsAC3DigitalOut]) ||
           ([_movie hasDTSCodec] && [_movie supportsDTSDigitalOut]);
}

- (void)initDigitalAudioOut
{
    _audioDeviceSupportsDigital = audioDeviceSupportsDigital(&_audioStreamID);
    [self updateDigitalAudioOut:nil];   // nil: not to set volume

    registerAudioDeviceListener(audioDeviceListener, self);
}

- (BOOL)updateDigitalAudioOut:(id)sender
{
    [_audioDeviceTextField setStringValue:
            (_audioDeviceSupportsDigital) ? NSLocalizedString(@"Digital", nil) :
                                            NSLocalizedString(@"Analog", nil)];

    BOOL currentlyDigitalOut = [self isCurrentlyDigitalAudioOut];
    [_audioOutTextField setStringValue:
            (_movie == nil) ?       NSLocalizedString(@"None", nil) :
            (currentlyDigitalOut) ? NSLocalizedString(@"Digital", nil) :
                                    NSLocalizedString(@"Analog", nil)];

    if (currentlyDigitalOut) {
        if (_movie && [_movie isMemberOfClass:[MMovie_QuickTime class]]) {
            // get current format
            OSStatus err;
            UInt32 paramSize = sizeof(AudioStreamBasicDescription);
            AudioStreamBasicDescription format;
			AudioObjectPropertyAddress propertyAddress = {
				kAudioStreamPropertyPhysicalFormat,
				kAudioObjectPropertyScopeGlobal,
				kAudioObjectPropertyElementMaster
			};
			err = AudioObjectGetPropertyData(_audioStreamID, &propertyAddress, 0, NULL, &paramSize, &format);
            if (err != noErr) {
                TRACE(@"could not get the stream format: [%4.4s]\n", (char*)&err);
                return FALSE;
            }
            // change sample-rate
            format.mSampleRate = 48000.000000;    // 48.000 kHz by default
			for(MTrack* track in [_movie audioTracks]) {
                // use sample-rate of first enabled audio track
                if ([track isEnabled] && [track audioSampleRate] != 0) {
                    format.mSampleRate = [track audioSampleRate];
                    break;
                }
            }
            // set as current format
			err = AudioObjectSetPropertyData(_audioStreamID, &propertyAddress, 0, NULL, sizeof(AudioStreamBasicDescription), &format);
            if (err != noErr) {
                TRACE(@"could not set the stream format: [%4.4s]\n", (char *)&err);
                return FALSE;
            }
        }
        if (sender) {
            [self setVolume:DIGITAL_VOLUME];   // always
        }
    }
    else {
        if (sender && ![_defaults boolForKey:MUpdateSystemVolumeKey]) {
            [self setVolume:[_defaults floatForKey:MVolumeKey]];    // restore analog volume
        }
    }
    return TRUE;
}

- (void)audioDeviceChanged
{
    BOOL digital = audioDeviceSupportsDigital(&_audioStreamID);
    if (digital == _audioDeviceSupportsDigital) {
        return;
    }

    _audioDeviceSupportsDigital = digital;
    [self performSelectorOnMainThread:@selector(updateDigitalAudioOut:)
                           withObject:self waitUntilDone:FALSE];

    if (_movie) {   // reopen current movie to use new audio device
        [self performSelectorOnMainThread:@selector(reopenMovieWithMovieClass:)
                               withObject:[_movie class] waitUntilDone:FALSE];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

static int AudioDeviceSupportsDigital(AudioDeviceID i_dev_id, AudioStreamID* streamID);

static BOOL audioDeviceSupportsDigital(AudioStreamID* streamID)
{
    /* Find the ID of the default Device. */
    UInt32 paramSize = sizeof(AudioDeviceID);
    AudioDeviceID audioDev = 0;
    OSStatus err;
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &paramSize, &audioDev);
    if (err != noErr) {
        TRACE(@"could not get default audio device: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    /* Retrieve the length of the device name. */
    paramSize = 0;
	propertyAddress.mSelector = kAudioDevicePropertyDeviceName;
	err = AudioObjectGetPropertyDataSize(audioDev, &propertyAddress, 0, NULL, &paramSize);
	if (err != noErr) {
        TRACE(@"could not get default audio device name length: [%4.4s]\n", (char *)&err);
        return FALSE;
    }
    
    /* Retrieve the name of the device. */
    char* psz_name = (char *)malloc(paramSize);
	err = AudioObjectGetPropertyData(audioDev, &propertyAddress, 0, NULL, &paramSize, psz_name);
    if (err != noErr) {
        TRACE(@"could not get default audio device name: [%4.4s]\n", (char *)&err);
		free(psz_name);
        return FALSE;
    }
    
    //TRACE(@"got default audio output device ID: %#lx Name: %s\n", audioDev, psz_name);
    
    BOOL isDigital = AudioDeviceSupportsDigital(audioDev, streamID);
    //TRACE(@"support digital s/pdif output:%d\n", isDigital);
    
    free( psz_name);
    return isDigital;
}

static void registerAudioDeviceListener(AudioObjectPropertyListenerProc proc, void* data)
{
    /* Find the ID of the default Device. */
    UInt32 paramSize = sizeof(AudioDeviceID);
    AudioDeviceID audioDev = 0;
	AudioObjectPropertyAddress propertyAddress = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	OSStatus err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &paramSize, &audioDev);
    if (err != noErr) {
        TRACE(@"could not get default audio device: [%4.4s]\n", (char *)&err);
        return;
    }
    /* add callback func */
	propertyAddress.mSelector = kAudioDevicePropertyDeviceHasChanged;
	propertyAddress.mScope    = kAudioObjectPropertyScopeGlobal;
	err = AudioObjectAddPropertyListener(audioDev, &propertyAddress, proc, data);
    if (err != noErr) {
        TRACE(@"AudioDeviceAddPropertyListener failed: [%4.4s]\n", (char *)&err);
    }
}

static OSStatus audioDeviceListener(AudioObjectID device, UInt32 inNumberOfAddresses,
									const AudioObjectPropertyAddress inAddresses[], void* inClientData)
{
	int i;
	for (i = 0; i < inNumberOfAddresses; ++i)
	{
		if(inAddresses[i].mSelector == kAudioDevicePropertyDeviceHasChanged)
		{
            //TRACE(@"got notify kAudioDevicePropertyDeviceHasChanged.\n");
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            [(AppController*)inClientData audioDeviceChanged];
            [pool release];
            break;
        }
	}
    return noErr;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

static int AudioStreamSupportsDigital(AudioStreamID i_stream_id)
{
    OSStatus err = noErr;
    UInt32 paramSize;
    AudioStreamBasicDescription *p_format_list = NULL;
    int i, i_formats, b_return = FALSE;
	AudioObjectPropertyAddress propertyAddress = {
		kAudioStreamPropertyPhysicalFormats,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};

    /* Retrieve all the stream formats supported by each output stream. */
	err = AudioObjectGetPropertyDataSize(i_stream_id, &propertyAddress, 0, NULL, &paramSize);
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

	err = AudioObjectGetPropertyData(i_stream_id, &propertyAddress, 0, NULL, &paramSize, p_format_list);
    if (err != noErr) {
        TRACE(@"could not get the list of streamformats: [%4.4s]\n", (char *)&err);
        free(p_format_list);
        return FALSE;
    }
    
    for (i = 0; i < i_formats; ++i) {
        //TRACE(@"supported format:", &p_format_list[i]);
        if (p_format_list[i].mFormatID == kAudioFormatAC3 ||
            p_format_list[i].mFormatID == kAudioFormat60958AC3 ||
            p_format_list[i].mFormatID == 'IAC3') {
            //TRACE(@"[%d]sampleRate = %lf", i, p_format_list[i].mSampleRate);
            b_return = TRUE;
        }
    }
    
    free(p_format_list);
    return b_return;
}

static int AudioDeviceSupportsDigital(AudioDeviceID i_dev_id, AudioStreamID* streamID)
{
    OSStatus err = noErr;
    UInt32 paramSize = 0;
    AudioStreamID* p_streams = NULL;
    int i = 0, i_streams = 0;
	AudioObjectPropertyAddress propertyAddress = {
		kAudioDevicePropertyStreams,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};

    /* Retrieve all the output streams. */
	err = AudioObjectGetPropertyDataSize(i_dev_id, &propertyAddress, 0, NULL, &paramSize);
    if (err != noErr) {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char*)&err);
        return FALSE;
    }
    
    i_streams = paramSize / sizeof(AudioStreamID);
    p_streams = (AudioStreamID *)malloc(paramSize);
    if (p_streams == NULL) {
        TRACE(@"out of memory\n");
        return FALSE;
    }

	err = AudioObjectGetPropertyData(i_dev_id, &propertyAddress, 0, NULL, &paramSize, p_streams);
    if (err != noErr) {
        TRACE(@"could not get number of streams: [%4.4s]\n", (char*)&err);
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
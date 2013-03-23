//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
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

#import "MMovie_QuickTime.h"
#import "UserDefaults.h"

// TODO: make something like this for AVAssetTrack
//
//@interface QTTrack (Movist)
//
//- (NSString*)summary;
//
//@end
//
//@implementation QTTrack (Movist)
//
//- (NSString*)summary
//{
//    NSString* result = @"";
//
//    ImageDescriptionHandle idh;
//    idh = (ImageDescriptionHandle)NewHandleClear(sizeof(ImageDescription));
//    GetMediaSampleDescription([[self media] quickTimeMedia], 1,
//                              (SampleDescriptionHandle)idh);
//
//    NSString* mediaType = [self attributeForKey:QTTrackMediaTypeAttribute];
//    if ([mediaType isEqualToString:QTMediaTypeVideo]) {
//        CFStringRef s;
//        if (noErr == ICMImageDescriptionGetProperty(idh,
//                                kQTPropertyClass_ImageDescription,
//                                kICMImageDescriptionPropertyID_SummaryString,
//                                sizeof(CFStringRef), &s, 0)) {
//            result = [NSString stringWithString:(NSString*)s];
//            CFRelease(s);
//        }
//    }
//    else if ([mediaType isEqualToString:QTMediaTypeMPEG]) {
//        NSRect rc = [[self attributeForKey:QTTrackBoundsAttribute] rectValue];
//        NSString* name = [self attributeForKey:QTTrackDisplayNameAttribute];
//        result = [NSString stringWithFormat:@"%@, %g x %g",
//                  /*FIXME*/name, rc.size.width, rc.size.height];
//    }
//    else if ([mediaType isEqualToString:QTMediaTypeSound]) {
//        // temporary impl. : how to get audio properties?
//        CFStringRef s;
//        if (noErr == ICMImageDescriptionGetProperty(idh,
//                                kQTPropertyClass_ImageDescription,
//                                kICMImageDescriptionPropertyID_SummaryString,
//                                sizeof(CFStringRef), &s, 0)) {
//            // remove strange contents after codec name.
//            NSRange range = [(NSString*)s rangeOfString:@", "];
//            result = [(NSString*)s substringToIndex:range.location];
//            CFRelease(s);
//        }
//    }
//    DisposeHandle((Handle)idh);
//    return result;
//}
//
//@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

// a52Codec digital-audio
BOOL _a52CodecInstalled = FALSE;
BOOL _a52CodecAttemptPassthrough = FALSE;

// perian subtitle
static BOOL _perianInstalled = FALSE;
static BOOL _perianSubtitleEnabled = FALSE;

static BOOL _useQuickTimeSubtitles = FALSE;

@implementation MMovie_QuickTime

+ (NSString*)name { return @"QuickTime"; }

+ (void)setUseQuickTimeSubtitles:(BOOL)use
{
    _useQuickTimeSubtitles = use;
}

+ (void)checkA52CodecInstalled
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* root = @"/Library/Audio/Plug-Ins/Components/A52Codec.component";
    NSString* home = [[@"~" stringByExpandingTildeInPath] stringByAppendingString:root];
    _a52CodecInstalled = [fm fileExistsAtPath:root] || [fm fileExistsAtPath:home];
}

- (void)initA52Codec:(BOOL)digitalAudioOut
{
    // remember original settings & update new settings
    if (_a52CodecInstalled) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        _a52CodecAttemptPassthrough = [defaults a52CodecAttemptPassthrough];
        [defaults setA52CodecAttemptPassthrough:digitalAudioOut];
    }
}

- (void)cleanupA52Codec
{
    // restore original settings
    if (_a52CodecInstalled) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setA52CodecAttemptPassthrough:_a52CodecAttemptPassthrough];
    }
}

+ (void)checkPerianInstalled
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* root = @"/Library/QuickTime/Perian.component";
    NSString* home = [[@"~" stringByExpandingTildeInPath] stringByAppendingString:root];
    _perianInstalled = [fm fileExistsAtPath:root] || [fm fileExistsAtPath:home];
}

- (void)initPerianSubtitle
{
    // remember original settings & update new settings
    if (_perianInstalled) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        _perianSubtitleEnabled = [defaults isPerianSubtitleEnabled];
        [defaults setPerianSubtitleEnabled:[defaults boolForKey:MUseQuickTimeSubtitlesKey]];
    }
}

- (void)cleanupPerianSubtitle
{
    // restore original settings
    if (_perianInstalled) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setPerianSubtitleEnabled:_perianSubtitleEnabled];
    }
}

- (MTrack*)videoTrackWithIndex:(NSInteger)index avTrack:(AVAssetTrack*)avTrack
{
	CGSize displaySize = [avTrack naturalSize];
	CGSize encodedSize = displaySize;

	MTrack* newTrack = [MTrack trackWithImpl:avTrack];
	// TODO: replace this line with one that matches old behavior better
    //[newTrack setName:[avTrack attributeForKey:QTTrackDisplayNameAttribute]];
	[newTrack setName:avTrack.mediaType];
	// TODO: replace this line with one that works with AVFoundation
    //[newTrack setSummary:[avTrack summary]];
    [newTrack setEncodedSize:NSSizeFromCGSize(encodedSize)];
    [newTrack setDisplaySize:displaySize];
    [newTrack setEnabled:index == 0];  // enable first track only
    [newTrack setMovie:self];
    if (index < [_videoTracks count]) {
        MTrack* track = [_videoTracks objectAtIndex:index];
        [newTrack setCodecId:[track codecId]];
        [newTrack setFps:[track fps]];
    }
    return newTrack;
}

- (MTrack*)audioTrackWithIndex:(int)index avTrack:(AVAssetTrack*)avTrack
{
    MTrack* newTrack = [MTrack trackWithImpl:avTrack];
	// TODO: replace this line with one that matches old behavior better
	//[newTrack setName:[qtTrack attributeForKey:QTTrackDisplayNameAttribute]];
	[newTrack setName:avTrack.mediaType];
	// TODO: replace this line with one that works with AVFoundation
	//[newTrack setSummary:[qtTrack summary]];
    [newTrack setEnabled:index == 0];  // enable first track only
    [newTrack setMovie:self];
    if (index < [_audioTracks count]) {
        MTrack* track = [_audioTracks objectAtIndex:index];
        [newTrack setCodecId:[track codecId]];
        [newTrack setAudioChannels:[track audioChannels]];
        [newTrack setAudioSampleRate:[track audioSampleRate]];
    }
    return newTrack;
}

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo
  digitalAudioOut:(BOOL)digitalAudioOut error:(NSError**)error
{
    // currently, A52Codec supports AC3 only (not DTS).
    [self initA52Codec:(digitalAudioOut && movieInfo->hasAC3Codec)];

    //TRACE(@"%s %@", __PRETTY_FUNCTION__, [url absoluteString]);
    [self initPerianSubtitle];
	AVPlayer* avPlayer = [AVPlayer playerWithURL:url];
    [self cleanupPerianSubtitle];
    if (!avPlayer) {
        [self release];
        return nil;
    }
	AVPlayerItem* playerItem  = [avPlayer currentItem];
	NSArray*      videoTracks = [[playerItem asset] tracksWithMediaType:AVMediaTypeVideo];
	if([videoTracks count] == 0)
	{
		if(error != nil)
		{
			*error = [NSError errorWithDomain:[MMovie_QuickTime name]
										 code:ERROR_NO_VIDEO_TRACK_FOUND
									 userInfo:nil];
		}
        [self release];
        return nil;
	}
    CGSize        movieSize   = [(AVAssetTrack*)[videoTracks objectAtIndex:0] naturalSize];
    if (movieSize.width == 0 || movieSize.height == 0) {
        NSError* err = [NSError errorWithDomain:[MMovie_QuickTime name]
                                     code:ERROR_INVALID_VIDEO_DIMENSION
                                 userInfo:nil];
		if(error != nil)
			*error = err;
        [self release];
        return nil;
    }

    if ((self = [super initWithURL:url movieInfo:movieInfo
                   digitalAudioOut:digitalAudioOut error:error])) {
		avformat_close_input(&movieInfo->formatContext);
        _avPlayer = [avPlayer retain];

        // override video/audio tracks
        NSMutableArray* vTracks = [NSMutableArray arrayWithCapacity:1];
        NSMutableArray* aTracks = [NSMutableArray arrayWithCapacity:1];
        NSString* mediaType;
        int vi = 0, ai = 0;
		for(AVAssetTrack* avTrack in [[playerItem asset] tracks]) {
			mediaType = [avTrack mediaType];
			if([mediaType isEqualToString:AVMediaTypeVideo]) {
				[vTracks addObject:[self videoTrackWithIndex:vi++ avTrack:avTrack]];
			}
			else if([mediaType isEqualToString:AVMediaTypeAudio]) {
				[aTracks addObject:[self audioTrackWithIndex:ai++ avTrack:avTrack]];
			}
		}
        [_videoTracks setArray:vTracks];
        [_audioTracks setArray:aTracks];
        [self setAspectRatio:_aspectRatio]; // for _adjustedSize

        // override _duration & _startTime by QuickTime
		CMTime t = [playerItem duration];
		_duration = CMTimeGetSeconds(t);
		// TODO: since "indexedDuration" also appears to stand for "loadedDuration" this isn't strictly correct
		_indexedDuration = _duration;
        _startTime = 0;

		if([_audioTracks count] > 0)
		{
			AVAssetTrack* audioAsset = (AVAssetTrack*)[(MTrack*)[_audioTracks objectAtIndex:0] impl];
			_preferredVolume = audioAsset.preferredVolume;
		}
		_volume = _avPlayer.volume;
		_muted = _avPlayer.muted;
		_playbackPeriodicObserver = [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0, 100) queue:NULL usingBlock:^(CMTime time) {
			[[NSNotificationCenter defaultCenter] postNotificationName:MMovieCurrentTimeNotification object:self];
			if(0 == CMTimeCompare(time, _avPlayer.currentItem.duration))
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:MMovieEndNotification object:self];
			}
		}];

        // loading-state cannot be get by QTMovieLoadStateDidChangeNotification.
        // I think that it may be already posted before _qtMovie is returned.
        _indexingUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                target:self selector:@selector(updateIndexedDuration:)
                                userInfo:nil repeats:TRUE];
    }
    return self;
}

- (AVPlayer*)player
{
	return _avPlayer;
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    return TRUE;
}

- (void)cleanup
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_indexingUpdateTimer isValid]) {
        [_indexingUpdateTimer invalidate];
        _indexingUpdateTimer = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[_avPlayer removeTimeObserver:_playbackPeriodicObserver];
    [_avPlayer release];
	_avPlayer = nil;
    [self cleanupA52Codec];

    [super cleanup];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)updateIndexedDuration:(NSTimer*)timer
{
//    float duration = _indexedDuration;
//    long ret = GetMovieLoadState([_qtMovie quickTimeMovie]);
//    if (ret == kMovieLoadStateComplete) {
//        [_indexingUpdateTimer invalidate];
//        _indexingUpdateTimer = nil;
//        duration = [self duration];
//    }
//    else {
//        TimeValue tv;
//        if (noErr == GetMaxLoadedTimeInMovie([_qtMovie quickTimeMovie], &tv)) {
//            duration = tv / 1000.0;
//        }
//    }
//    [self indexedDurationUpdated:duration];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

// currently, A52Codec supports AC3 only (not DTS)
- (BOOL)supportsAC3DigitalOut { return _a52CodecInstalled; }
- (BOOL)supportsDTSDigitalOut { return FALSE; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume

- (void)setVolume:(float)volume
{
	[_avPlayer setVolume:volume];
    [super setVolume:volume];
}

- (void)setMuted:(BOOL)muted
{
	[_avPlayer setMuted:muted];
    [super setMuted:muted];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (float)currentTime
{
	CMTime t = [_avPlayer currentTime];
	return CMTimeGetSeconds(t);
}

- (float)rate { return [_avPlayer rate]; }
- (void)setRate:(float)rate
{
	[_avPlayer setRate:rate];
	[[NSNotificationCenter defaultCenter] postNotificationName:MMovieRateChangeNotification object:self];
}
- (void)stepBackward { [[_avPlayer currentItem] stepByCount:-1]; }
- (void)stepForward { [[_avPlayer currentItem] stepByCount:1]; }
- (void)gotoBeginning { [_avPlayer seekToTime:CMTimeMake(0, 100)]; }
- (void)gotoEnd { [_avPlayer seekToTime:[[_avPlayer currentItem] duration]]; }

- (void)gotoTime:(float)time
{
	//TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
	CMTime t = [_avPlayer currentTime];
	t = CMTimeMakeWithSeconds(time, t.timescale);

    if (t.value < 0) {
        [self gotoBeginning];
    }
	else if (CMTimeCompare([[_avPlayer currentItem] duration], t) == -1) {
        [self gotoEnd];
    }
    else {
		float rate = [_avPlayer rate];
		[_avPlayer seekToTime:t];
		[_avPlayer setRate:rate];   // play continue...
    }
}

- (void)seekByTime:(float)dt
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, dt);
    float time = [self currentTime] + dt;
    time = (dt < 0) ? MAX(0, time) : MIN(time, [self duration]);
    [self gotoTime:time];
}

- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp
{
	return 0;
}

- (void)idleTask
{
}

@end

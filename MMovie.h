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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import <avformat.h>    // for AVFormatContext

#import "Movist.h"

@class MMovie;

@interface MTrack : NSObject
{
    id _impl;       // QTTrack or FFTrack
    MMovie* _movie;

    int _codecId;
    NSString* _name;
    NSString* _summary;

    NSSize _encodedSize;
    NSSize _displaySize;
    float _fps;

    int _audioChannels;
    float _audioSampleRate;
}

+ (id)trackWithImpl:(id)impl;
- (id)initWithImpl:(id)impl;

- (id)impl;
- (int)codecId;
- (NSString*)name;
- (NSString*)summary;
- (BOOL)isVideoTrack;
- (void)setImpl:(id)impl;
- (void)setMovie:(MMovie*)movie;
- (void)setCodecId:(int)codecId;
- (void)setName:(NSString*)name;
- (void)setSummary:(NSString*)summary;

- (NSSize)encodedSize;
- (NSSize)displaySize;
- (float)fps;
- (void)setEncodedSize:(NSSize)encodedSize;
- (void)setDisplaySize:(NSSize)displaySize;
- (void)setFps:(float)fps;

- (int)audioChannels;
- (float)audioSampleRate;
- (void)setAudioChannels:(int)channels;
- (void)setAudioSampleRate:(float)rate;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (float)volume;
- (void)setVolume:(float)volume;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

typedef struct {
    AVFormatContext* formatContext;
    NSArray* videoTracks;
    NSArray* audioTracks;
    BOOL hasDigitalAudio;
    float startTime;
    float duration;
    int64_t fileSize;
    int bitRate;
    float fps;
} MMovieInfo;

@interface MMovie : NSObject
{
    NSURL* _url;
    NSMutableArray* _videoTracks;
    NSMutableArray* _audioTracks;
    BOOL _hasDigitalAudio;
    float _startTime;
    float _duration;
    int64_t _fileSize;
    int _bitRate;
    float _fps;

    float _indexedDuration;

    float _preferredVolume;
    float _volume;
    BOOL _muted;

    int _aspectRatio;       // ASPECT_RATIO_*
    NSSize _adjustedSize;   // by _aspectRatio
}

+ (NSArray*)fileExtensions;
+ (BOOL)checkMovieURL:(NSURL*)url error:(NSError**)error;
+ (BOOL)getMovieInfo:(MMovieInfo*)info forMovieURL:(NSURL*)url error:(NSError**)error;
+ (NSString*)name;

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo
  digitalAudioOut:(BOOL)digitalAudioOut error:(NSError**)error;
- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error;
- (void)cleanup;

#pragma mark -
- (NSURL*)url;
- (int64_t)fileSize;
- (int)bitRate;
- (NSArray*)videoTracks;
- (NSArray*)audioTracks;
- (NSSize)displaySize;
- (NSSize)encodedSize;
- (float)startTime;
- (float)duration;
- (float)fps;

- (void)trackEnabled:(MTrack*)track;
- (void)trackDisabled:(MTrack*)track;

- (float)indexedDuration;
- (void)indexedDurationUpdated:(float)indexedDuration;
- (void)indexingFinished;

- (BOOL)hasDigitalAudio;
- (float)preferredVolume;
- (float)volume;
- (BOOL)muted;
- (void)setVolume:(float)volume;
- (void)setMuted:(BOOL)muted;

- (int)aspectRatio;
- (NSSize)adjustedSizeByAspectRatio;
- (void)setAspectRatio:(int)aspectRatio;

#pragma mark -
#pragma mark playback
- (float)currentTime;
- (float)rate;
- (void)setRate:(float)rate;
- (void)stepBackward;
- (void)stepForward;
- (void)gotoBeginning;
- (void)gotoEnd;
- (void)gotoTime:(float)time;
- (void)seekByTime:(float)dt;
- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp;
- (void)idleTask;

@end

////////////////////////////////////////////////////////////////////////////////

@interface MMovie (Codec)

+ (int)videoCodecIdFromFFmpegCodecId:(int)ffmpegCodecId fourCC:(NSString*)fourCC;
+ (int)audioCodecIdFromFFmpegCodecId:(int)ffmpegCodecId;

@end


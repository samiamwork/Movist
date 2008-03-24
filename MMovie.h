//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim. All rights reserved.
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
    MMovie* _movie;
    NSString* _name;
    NSString* _summary;
    BOOL _enabled;
}

- (id)initWithMovie:(MMovie*)movie;

- (MMovie*)movie;
- (NSString*)name;
- (NSString*)summary;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

typedef struct {
    int videoCodecId;
    NSSize encodedSize;
    NSSize displaySize;
    float startTime;
    float duration;

    int audioCodecId;
    int audioChannels;
    float audioSampleRate;
    float preferredVolume;
} MMovieInfo;

@interface MMovie : NSObject
{
    NSURL* _url;
    MMovieInfo _info;
    NSMutableArray* _videoTracks;
    NSMutableArray* _audioTracks;

    float _indexedDuration;
    float _volume;
    BOOL _muted;

    int _aspectRatio;       // ASPECT_RATIO_*
    NSSize _adjustedSize;   // by _aspectRatio
}

+ (NSArray*)movieFileExtensions;
+ (BOOL)checkMovieURL:(NSURL*)url error:(NSError**)error;
+ (AVFormatContext*)formatContextForMovieURL:(NSURL*)url error:(NSError**)error;
+ (BOOL)getMovieInfo:(MMovieInfo*)info forMovieURL:(NSURL*)url error:(NSError**)error;
+ (NSString*)name;

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo error:(NSError**)error;
- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error;
- (void)cleanup;

#pragma mark -
- (NSURL*)url;
- (NSArray*)videoTracks;
- (NSArray*)audioTracks;
- (NSSize)displaySize;
- (NSSize)encodedSize;
- (float)startTime;
- (float)duration;
- (float)preferredVolume;

- (float)indexedDuration;
- (float)volume;
- (BOOL)muted;
- (void)setVolume:(float)volume;
- (void)setMuted:(BOOL)muted;

- (int)aspectRatio;
- (NSSize)adjustedSizeByAspectRatio;
- (void)setAspectRatio:(int)aspectRatio;

- (void)trackEnabled:(MTrack*)track;
- (void)trackDisabled:(MTrack*)track;

// FIXME
- (int)videoCodecId;
- (int)audioCodecId;
- (int)audioChannels;
- (float)audioSampleRate;

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

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

@interface MMovie : NSObject
{
    NSURL* _url;
    NSMutableArray* _videoTracks;
    NSMutableArray* _audioTracks;
    NSSize _displaySize;
    NSSize _encodedSize;
    NSSize _adjustedSize;   // by _aspectRatio
    float _duration;

    float _indexedDuration;
    float _preferredVolume;
    float _volume;
    BOOL _muted;

    int _aspectRatio;   // ASPECT_RATIO_*
}

+ (NSArray*)movieFileExtensions;
+ (NSString*)name;

- (id)initWithURL:(NSURL*)url error:(NSError**)error;
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
- (NSSize)adjustedSizeByAspectRatio;
- (float)duration;
- (void)trackEnabled:(MTrack*)track;
- (void)trackDisabled:(MTrack*)track;

- (float)indexedDuration;
- (float)preferredVolume;
- (float)volume;
- (BOOL)muted;
- (void)setVolume:(float)volume;
- (void)setMuted:(BOOL)muted;

- (int)aspectRatio;
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

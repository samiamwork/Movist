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

@interface MTrack : NSObject
{
}

- (NSString*)name;
- (NSString*)format;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (float)volume;
- (void)setVolume:(float)volume;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovie : NSObject
{
    NSMutableArray* _videoTracks;
    NSMutableArray* _audioTracks;
    int _aspectRatio;   // ASPECT_RATIO_*
}

+ (NSArray*)movieTypes;
+ (NSString*)name;

- (id)initWithURL:(NSURL*)url error:(NSError**)error;
- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error;
- (void)cleanup;

#pragma mark -
- (NSArray*)videoTracks;
- (float)duration;
- (NSSize)size;

- (int)aspectRatio;
- (void)setAspectRatio:(int)aspectRatio;
- (NSSize)adjustedSize;

#pragma mark -
#pragma mark audio
- (NSArray*)audioTracks;
- (float)preferredVolume;
- (float)volume;
- (BOOL)muted;
- (void)setVolume:(float)volume;
- (void)setMuted:(BOOL)muted;

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

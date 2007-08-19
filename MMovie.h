//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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
- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp;
- (void)idleTask;

@end

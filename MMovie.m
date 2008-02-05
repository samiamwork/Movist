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

#import "MMovie.h"

@implementation MTrack

- (NSString*)name { return nil; }
- (NSString*)format { return nil; }
- (BOOL)isEnabled { return FALSE; }
- (void)setEnabled:(BOOL)enabled {}
- (float)volume { return 0; }
- (void)setVolume:(float)volume {}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie

+ (NSArray*)movieTypes
{
    return [NSArray arrayWithObjects:
        @"avi", @"divx",                            // movie
        @"mpe", @"mpeg", @"mpg", @"m1v", @"m2v",    // MPEG
        @"dat", @"ifo", @"vob", @"ts", @"tp",       // MPEG
        @"mp4", @"m4v",                             // MPEG4
        @"asf", @"asx",                             // Windows Media
        @"wm", @"wmp", @"wmv", @"wmx", @"wvx",      // Windows Media
        @"rm", @"rmvb",                             // Real Media
        @"ogm",                                     // OGM
        @"mov",                                     // MOV
        @"mqv",                                     // MQV
        @"mkv",                                     // Matroska
        @"flv",                                     // Flash
        // @"swf",                                  // Flash
        //@"dmb",                                   // DMB-TS
        //@"3gp", @"dmskm", @"k3g", @"skm", @"lmp4",// Mobile Phone
        nil];
}

+ (NSString*)name { return @""; }

- (id)initWithURL:(NSURL*)url error:(NSError**)error
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [url absoluteString]);
    if ([url isFileURL]) {
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString* path = [url path];
        if (![fileManager fileExistsAtPath:path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Movist"
                                    code:ERROR_FILE_NOT_EXIST userInfo:nil];
            }
            return nil;
        }
        if (![fileManager isReadableFileAtPath:path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Movist"
                                    code:ERROR_FILE_NOT_READABLE userInfo:nil];
            }
            return nil;
        }
    }
    _videoTracks = [[NSMutableArray alloc] initWithCapacity:1];
    _audioTracks = [[NSMutableArray alloc] initWithCapacity:5];
    _aspectRatio = ASPECT_RATIO_DEFAULT;
    return [super init];
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return TRUE;
}

- (void)cleanup
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_audioTracks release];
    [_videoTracks release];
    [self release];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSArray*)videoTracks { return _videoTracks; }

- (float)duration { return 0; }
- (float)indexDuration { return 0; }
- (NSSize)size { return NSMakeSize(0, 0); }

- (int)aspectRatio { return _aspectRatio; }

- (void)setAspectRatio:(int)aspectRatio
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _aspectRatio = aspectRatio;
}

- (NSSize)adjustedSize
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_aspectRatio == ASPECT_RATIO_DEFAULT) {
        return [self size];
    }
    else {
        float ratio[] = {
            4.0  / 3.0,     // ASPECT_RATIO_4_3
            16.0 / 9.0,     // ASPECT_RATIO_16_9
            1.85 / 1.0,     // ASPECT_RATIO_1_85
            2.35 / 1.0,     // ASPECT_RATIO_2_35
        };
        NSSize size = [self size];
        size.height = size.width / ratio[_aspectRatio - 1];
        return size;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark audio

- (NSArray*)audioTracks { return _audioTracks; }

- (float)preferredVolume { return 0; }
- (float)volume { return 0; }
- (BOOL)muted { return FALSE; }

- (void)setVolume:(float)volume
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, volume);
}

- (void)setMuted:(BOOL)muted
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, muted ? @"muted" : @"unmuted");
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (float)currentTime { TRACE(@"%s", __PRETTY_FUNCTION__); return 0; }
- (float)rate { TRACE(@"%s", __PRETTY_FUNCTION__); return 0; }
- (void)setRate:(float)rate { TRACE(@"%s %g", __PRETTY_FUNCTION__, rate); }
- (void)stepBackward { TRACE(@"%s", __PRETTY_FUNCTION__); }
- (void)stepForward { TRACE(@"%s", __PRETTY_FUNCTION__); }
- (void)gotoBeginning { TRACE(@"%s", __PRETTY_FUNCTION__); }
- (void)gotoEnd { TRACE(@"%s", __PRETTY_FUNCTION__); }
- (void)gotoTime:(float)time { TRACE(@"%s %g", __PRETTY_FUNCTION__, time); }
- (void)seekByTime:(float)dt { TRACE(@"%s %g", __PRETTY_FUNCTION__, dt); }
- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp
  { TRACE(@"%s", __PRETTY_FUNCTION__); return 0; }
- (void)idleTask { /*TRACE(@"%s", __PRETTY_FUNCTION__);*/ }

@end

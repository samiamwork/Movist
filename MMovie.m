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

- (id)initWithMovie:(MMovie*)movie
{
    if (self = [super init]) {
        _movie = [movie retain];
        _enabled = TRUE;
    }
    return self;
}

- (void)dealloc
{
    [_summary release];
    [_name release];
    [_movie release];
    [super dealloc];
}

- (MMovie*)movie { return _movie; }
- (NSString*)name { return _name; }
- (NSString*)summary { return _summary; }
- (BOOL)isEnabled { return _enabled; }
- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;

    if (_enabled) {
        [_movie trackEnabled:self];
    }
    else {
        [_movie trackDisabled:self];
    }
}

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
    if (self = [super init]) {
        _url = [url retain];
        _videoTracks = [[NSMutableArray alloc] initWithCapacity:1];
        _audioTracks = [[NSMutableArray alloc] initWithCapacity:5];

        _preferredVolume = DEFAULT_VOLUME;
        _volume = DEFAULT_VOLUME;
        _muted = FALSE;

        _aspectRatio = ASPECT_RATIO_DEFAULT;
    }
    return self;
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
    [_url release];
    [self release];
}
/*
- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [super dealloc];
}
*/
////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSURL*)url { return _url; }
- (NSArray*)videoTracks { return _videoTracks; }
- (NSArray*)audioTracks { return _audioTracks; }
- (NSSize)displaySize { return _displaySize; }
- (NSSize)encodedSize { return _encodedSize; }
- (NSSize)adjustedSizeByAspectRatio { return _adjustedSize; }
- (float)duration { return _duration; }
- (void)trackEnabled:(MTrack*)track {}
- (void)trackDisabled:(MTrack*)track {}

- (float)indexedDuration { return _indexedDuration; }
- (float)preferredVolume { return _preferredVolume; }
- (float)volume { return _volume; }
- (BOOL)muted { return _muted; }
- (void)setVolume:(float)volume { _volume = volume; }
- (void)setMuted:(BOOL)muted { _muted = muted; }

- (int)aspectRatio { return _aspectRatio; }
- (void)setAspectRatio:(int)aspectRatio
{
    _aspectRatio = aspectRatio;

    if (_aspectRatio == ASPECT_RATIO_DEFAULT) {
        _adjustedSize = _displaySize;
    }
    else {
        float ratio[] = {
            4.0  / 3.0,     // ASPECT_RATIO_4_3
            16.0 / 9.0,     // ASPECT_RATIO_16_9
            1.85 / 1.0,     // ASPECT_RATIO_1_85
            2.35 / 1.0,     // ASPECT_RATIO_2_35
        };
        _adjustedSize.width  = _displaySize.width;
        _adjustedSize.height = _displaySize.width / ratio[_aspectRatio - 1];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (float)currentTime { return 0.0; }
- (float)rate { return 0.0; }
- (void)setRate:(float)rate {}
- (void)stepBackward {}
- (void)stepForward {}
- (void)gotoBeginning {}
- (void)gotoEnd {}
- (void)gotoTime:(float)time {}
- (void)seekByTime:(float)dt {}
- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp { return 0; }
- (void)idleTask {}

@end

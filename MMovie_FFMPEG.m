//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim, Cheol Ju. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
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

#import "MMovie_FFMPEG.h"

@implementation MMovie_FFMPEG

+ (void)initialize
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    av_register_all();
}

+ (NSString*)name { return @"FFMPEG"; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (id)initWithURL:(NSURL*)url error:(NSError**)error
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, [url absoluteString]);
    if (![url isFileURL]) {
        *error = [NSError errorWithDomain:@"FFMPEG"
                                     code:10000  // FIXME
                                 userInfo:nil];
        return nil;
    }

    if (self = [super initWithURL:url error:error]) {
        int errorCode;
        if (![self initFFMPEGWithMovieURL:url errorCode:&errorCode] ||
            ![self initPlayback:&errorCode] ||
            ![self initAudioPlayback:&errorCode]) {
            *error = [NSError errorWithDomain:@"FFMPEG" code:errorCode userInfo:nil];
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)cleanup
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _quitRequested = TRUE;
    [self cleanupPlayback];
    [self cleanupAudioPlayback];
    [self cleanupFFMPEG];
    [super cleanup];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)duration
{
    return (_formatContext->duration == AV_NOPTS_VALUE) ? 0 : // not available
                    (_formatContext->duration / AV_TIME_BASE);
}

- (float)indexDuration
{
    if (_needIndexing) {
        return _indexingTime;
    }
    return [self duration];     // FIXME
}

- (NSSize)size
{
    return NSMakeSize(_videoWidth, _videoHeight);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume

- (float)preferredVolume { return 1; }
- (float)volume { return _volume;}
- (BOOL)muted { return _muted; }
- (void)setMuted:(BOOL)muted { _muted = muted; }
- (void)setVolume:(float)volume
{ 
    _volume = volume;
}

@end

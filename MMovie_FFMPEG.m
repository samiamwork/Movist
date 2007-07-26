//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Updated by moosoy <moosoy@gmail.com>
//  Copyright 2006 cocoable, moosoy. All rights reserved.
//

#if defined(_SUPPORT_FFMPEG)

#import "MMovie_FFMPEG.h"

@implementation MTrack_FFMPEG

- (id)initWithStreamId:(int)streamId movie:(MMovie_FFMPEG*)movie
{
    if (self = [super init]) {
        _streamId = streamId;
        _movie = movie;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString*)name
{
    return @"...";
    //TRACE(@"%s not implemented yet", __PRETTY_FUNCTION__);
}

- (BOOL)isEnabled { return _enable; }
- (void)setEnabled:(BOOL)enabled { _enable = enabled; }
- (float)volume { return _volume; }
- (void)setVolume:(float)volume { _volume = volume; }
- (int)streamId { return _streamId; }
- (MMovie_FFMPEG*)movie { return _movie; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie_FFMPEG

+ (void)initialize
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    av_register_all();
}

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
    [self cleanupAudioPlayback];
    [self cleanupPlayback];
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

- (NSSize)size
{
    return NSMakeSize(_videoWidth, _videoHeight);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume

- (float)volume
{
    TRACE(@"%s is not impleneted yet", __PRETTY_FUNCTION__);
    return 0;
}

- (BOOL)muted
{
    TRACE(@"%s is not implemented yet", __PRETTY_FUNCTION__);
    return FALSE;
}

- (void)setVolume:(float)volume
{
    TRACE(@"%s is not implemented yet", __PRETTY_FUNCTION__);
}

- (void)setMuted:(BOOL)muted
{
    TRACE(@"%s is not implemented yet", __PRETTY_FUNCTION__);
}

@end

#endif  // _SUPPORT_FFMPEG

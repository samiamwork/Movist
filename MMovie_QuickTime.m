//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovie_QuickTime.h"

@implementation MTrack_QuickTime

- (id)initWithQTTrack:(QTTrack*)qtTrack
{
    if (self = [super init]) {
        _qtTrack = [qtTrack retain];
    }
    return self;
}

- (void)dealloc
{
    [_qtTrack release];
    [super dealloc];
}

- (NSString*)name
{
    return [_qtTrack attributeForKey:QTTrackDisplayNameAttribute];
}

- (NSString*)format
{
    NSString* type = (NSString*)[_qtTrack attributeForKey:QTTrackMediaTypeAttribute];
    if ([type isEqualToString:QTMediaTypeVideo]) {
        NSRect rect = [[_qtTrack attributeForKey:QTTrackBoundsAttribute] rectValue];
        return [NSString stringWithFormat:@"%g x %g", rect.size.width, rect.size.height];
    }
    else {
        return @"";
    }
}

- (BOOL)isEnabled { return [_qtTrack isEnabled]; }
- (void)setEnabled:(BOOL)enabled { [_qtTrack setEnabled:enabled]; }
- (float)volume { return [_qtTrack volume]; }
- (void)setVolume:(float)volume { [_qtTrack setVolume:volume]; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie_QuickTime

- (id)initWithURL:(NSURL*)url error:(NSError**)error
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, [url absoluteString]);
    if ((self = [super initWithURL:url error:error])) {
        if ([url isFileURL]) {
            _qtMovie = [[QTMovie movieWithFile:[url path] error:error] retain];
        }
        else {
            _qtMovie = [[QTMovie movieWithURL:url error:error] retain];
        }
        if (!_qtMovie) {
            [self release];
            return nil;
        }
        // init video tracks
        QTTrack* track;
        NSArray* tracks = [_qtMovie tracksOfMediaType:QTMediaTypeVideo];
        NSEnumerator* enumerator = [tracks objectEnumerator];
        while (track = [enumerator nextObject]) {
            [_videoTracks addObject:[[[MTrack_QuickTime alloc]
                                        initWithQTTrack:track] autorelease]];
        }
        // init audio tracks
        tracks = [_qtMovie tracksOfMediaType:QTMediaTypeSound];
        enumerator = [tracks objectEnumerator];
        while (track = [enumerator nextObject]) {
            [_audioTracks addObject:[[[MTrack_QuickTime alloc]
                                        initWithQTTrack:track] autorelease]];
        }
    }
    return self;
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // create visual context
    OSStatus ret = QTOpenGLTextureContextCreate(kCFAllocatorDefault,
                                                [openGLContext CGLContextObj],
                                                [openGLPixelFormat CGLPixelFormatObj],
                                                0, &_visualContext);
    if (ret != noErr) {
        TRACE(@"QTOpenGLTextureContextCreate() failed: %d", ret);
        if (error) {
            NSDictionary* dict =
            [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ret]
                                        forKey:@"returnCode"];
            *error = [NSError errorWithDomain:@"QuickTime"
                                         code:ERROR_VISUAL_CONTEXT_CREATE_FAILED
                                     userInfo:dict];
        }
        return FALSE;
    }

    SetMovieVisualContext([_qtMovie quickTimeMovie], _visualContext);

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(qtMovieRateChanged:)
               name:QTMovieRateDidChangeNotification object:_qtMovie];
    [nc addObserver:self selector:@selector(qtMovieEnded:)
               name:QTMovieDidEndNotification object:_qtMovie];
    return TRUE;
}

- (void)cleanup
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    SetMovieVisualContext([_qtMovie quickTimeMovie], 0);
    if (_visualContext) {
        CFRelease(_visualContext);
    }
    [_qtMovie release], _qtMovie = nil;
    [super cleanup];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (float)duration
{
    QTTime t = [_qtMovie duration];
    return (float)t.timeValue / t.timeScale;
}

- (NSSize)size
{
    return [[_qtMovie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume

- (float)preferredVolume
{
    return [[_qtMovie attributeForKey:QTMoviePreferredVolumeAttribute] floatValue];
}

- (float)volume { return [_qtMovie volume]; }
- (BOOL)muted   { return [_qtMovie muted]; }

- (void)setVolume:(float)volume
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, volume);
    [_qtMovie setVolume:volume];
}

- (void)setMuted:(BOOL)muted
{
    TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, muted ? @"muted" : @"unmuted");
    [_qtMovie setMuted:muted];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (float)currentTime
{
    QTTime t = [_qtMovie currentTime];
    return (float)t.timeValue / t.timeScale;
}

- (float)rate { return [_qtMovie rate]; }

- (void)setRate:(float)rate
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, rate);
    [_qtMovie setRate:rate];
}

- (void)stepBackward
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_qtMovie stepBackward];
}

- (void)stepForward
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_qtMovie stepForward];
}

- (void)gotoBeginning
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_qtMovie gotoBeginning];
}

- (void)gotoEnd
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_qtMovie gotoEnd];
}

- (void)gotoTime:(float)time
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    QTTime t = [_qtMovie currentTime];    // to fill timeScale & flags
    t.timeValue = (long long)(time * t.timeScale);

    if (t.timeValue < 0) {
        [_qtMovie gotoBeginning];
    }
    else if ([_qtMovie duration].timeValue < t.timeValue) {
        [_qtMovie gotoEnd];
    }
    else {
        float rate = [_qtMovie rate];
        [_qtMovie setCurrentTime:t];
        [_qtMovie setRate:rate];   // play continue...
    }
}

- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (!QTVisualContextIsNewImageAvailable(_visualContext, timeStamp)) {
        return 0;
    }

    CVOpenGLTextureRef image;
    OSStatus ret = QTVisualContextCopyImageForTime(_visualContext, 0, timeStamp, &image);
    if (ret != noErr || !image) {
        return 0;
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:MMovieCurrentTimeNotification object:self];
    return image;
}

- (void)idleTask
{
    QTVisualContextTask(_visualContext);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark notifications

- (void)qtMovieRateChanged:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MMovieRateChangeNotification object:self];
}

- (void)qtMovieEnded:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MMovieEndNotification object:self];
}

@end

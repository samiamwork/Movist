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

#import "MMovie_QuickTime.h"

@interface QTTrack (Movist)

- (NSString*)summary;

@end

@implementation QTTrack (Movist)

- (NSString*)summary
{
    NSString* result = @"";

    ImageDescriptionHandle idh;
    idh = (ImageDescriptionHandle)NewHandleClear(sizeof(ImageDescription));
    GetMediaSampleDescription([[self media] quickTimeMedia], 1,
                              (SampleDescriptionHandle)idh);

    NSString* mediaType = [self attributeForKey:QTTrackMediaTypeAttribute];
    if ([mediaType isEqualToString:QTMediaTypeVideo]) {
        CFStringRef s;
        if (noErr == ICMImageDescriptionGetProperty(idh,
                                kQTPropertyClass_ImageDescription,
                                kICMImageDescriptionPropertyID_SummaryString,
                                sizeof(CFStringRef), &s, 0)) {
            result = [NSString stringWithString:(NSString*)s];
            CFRelease(s);
        }
    }
    else if ([mediaType isEqualToString:QTMediaTypeMPEG]) {
        NSRect rc = [[self attributeForKey:QTTrackBoundsAttribute] rectValue];
        NSString* name = [self attributeForKey:QTTrackDisplayNameAttribute];
        result = [NSString stringWithFormat:@"%@, %g x %g",
                  /*FIXME*/name, rc.size.width, rc.size.height];
    }
    else if ([mediaType isEqualToString:QTMediaTypeSound]) {
        // temporary impl. : how to get audio properties?
        CFStringRef s;
        if (noErr == ICMImageDescriptionGetProperty(idh,
                                kQTPropertyClass_ImageDescription,
                                kICMImageDescriptionPropertyID_SummaryString,
                                sizeof(CFStringRef), &s, 0)) {
            NSString* ss = [NSString stringWithString:(NSString*)s];
            CFRelease(s);
            // remove strange contents after codec name.
            NSRange range = [ss rangeOfString:@", "];
            result = [ss substringToIndex:range.location];
        }
        /*
        CodecInfo ci;
        ImageDescription* desc = *idh;
        GetCodecInfo(&ci, desc->cType, 0);
        NSString* name = [self attributeForKey:QTTrackDisplayNameAttribute];
        result = (codecInfo.typeName[0] == '\0') ?
                            name : [NSString stringWithUTF8String:ci.typeName];
         */
    }
    DisposeHandle((Handle)idh);
    return result;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation MTrack_QuickTime

+ (id)trackWithMovie:(MMovie*)movie qtTrack:(QTTrack*)qtTrack
{
    MTrack_QuickTime* track = [MTrack_QuickTime alloc];
    return [[track initWithMovie:movie qtTrack:qtTrack] autorelease];
}

- (id)initWithMovie:(MMovie*)movie qtTrack:(QTTrack*)qtTrack
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, qtTrack);
    if (self = [super initWithMovie:movie]) {
        _qtTrack = [qtTrack retain];
        _name = [[_qtTrack attributeForKey:QTTrackDisplayNameAttribute] retain];
        _summary = [[_qtTrack summary] retain];
        _enabled = [_qtTrack isEnabled];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_qtTrack release];
    [super dealloc];
}

- (QTTrack*)qtTrack { return _qtTrack; }

- (void)setEnabled:(BOOL)enabled
{
    [_qtTrack setEnabled:enabled];
    [super setEnabled:enabled];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie_QuickTime

+ (NSString*)name { return @"QuickTime"; }

- (id)initWithURL:(NSURL*)url error:(NSError**)error
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, [url absoluteString]);
    QTMovie* qtMovie;
    if ([url isFileURL]) {
        qtMovie = [QTMovie movieWithFile:[url path] error:error];
    }
    else {
        qtMovie = [QTMovie movieWithURL:url error:error];
    }
    if (!qtMovie) {
        return nil;
    }
    NSSize movieSize = [[qtMovie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
    if (movieSize.width == 0 || movieSize.height == 0) {
        return nil;
    }

    if ((self = [super initWithURL:url error:error])) {
        _qtMovie = [qtMovie retain];
        
        // init video/audio tracks
        NSString* mediaType;
        QTTrack* track, *firstVideoTrack = 0;
        NSEnumerator* enumerator = [[_qtMovie tracks] objectEnumerator];
        while (track = [enumerator nextObject]) {
            mediaType = [track attributeForKey:QTTrackMediaTypeAttribute];
            if ([mediaType isEqualToString:QTMediaTypeVideo] ||
                [mediaType isEqualToString:QTMediaTypeMPEG]/* ||
                [mediaType isEqualToString:QTMediaTypeMovie]*/) {
                [_videoTracks addObject:
                 [MTrack_QuickTime trackWithMovie:self qtTrack:track]];
                if (firstVideoTrack == nil) {
                    firstVideoTrack = track;
                }
                else {
                    // initially enable the first video track only
                    [[_videoTracks lastObject] setEnabled:FALSE];
                }
            }
            else if ([mediaType isEqualToString:QTMediaTypeSound]/* ||
                     [mediaType isEqualToString:QTMediaTypeMusic]*/) {
                [_audioTracks addObject:
                 [MTrack_QuickTime trackWithMovie:self qtTrack:track]];
            }
        }

        // init _displaySize & _encodedSize
        _displaySize = _encodedSize = movieSize;
        /* ... in 10.5 or later
        if ([[_qtMovie attributeForKey:QTMovieApertureModeAttribute]
                            isEqualToString:QTMovieApertureModeEncodedPixels]) {
            _encodedSize = [[firstVideoTrack apertureModeDimensionsForMode:
                             QTMovieApertureModeEncodedPixels] sizeValue];
        }
         */
        /**/
        ImageDescriptionHandle idh;
        idh = (ImageDescriptionHandle)NewHandleClear(sizeof(ImageDescription));
        GetMediaSampleDescription([[firstVideoTrack media] quickTimeMedia], 1,
                                  (SampleDescriptionHandle)idh);
        FixedPoint esp;
        if (noErr == ICMImageDescriptionGetProperty(idh, kQTPropertyClass_ImageDescription,
            kICMImageDescriptionPropertyID_EncodedPixelsDimensions, sizeof(esp), &esp, 0)) {
            NSSize es = NSMakeSize(FixedToFloat(esp.x), FixedToFloat(esp.y));
            if (es.width <= _displaySize.width && es.height <= _displaySize.height) {
                _encodedSize = es;
            }
        }
        DisposeHandle((Handle)idh);
        /**/
        [self setAspectRatio:_aspectRatio]; // for _adjustedSize
        //TRACE(@"_displaySize=%@, _encodedSize=%@", NSStringFromSize(_displaySize),
        //                                           NSStringFromSize(_encodedSize));

        // init _duration
        QTTime t = [_qtMovie duration];
        _duration = (float)t.timeValue / t.timeScale;

        // init volumes
        _preferredVolume = [[_qtMovie attributeForKey:QTMoviePreferredVolumeAttribute] floatValue];
        _volume = [_qtMovie volume];
        _muted = [_qtMovie muted];

        // loading-state cannot be get by QTMovieLoadStateDidChangeNotification.
        // I think that it may be already posted before _qtMovie is returned.
        _indexingUpdateTimer =
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(updateIndexedDuration:)
                                           userInfo:nil
                                            repeats:TRUE];
    }
    return self;
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // create visual context
    OSStatus ret = QTOpenGLTextureContextCreate(kCFAllocatorDefault,
                                                [openGLContext CGLContextObj],
                                                [openGLPixelFormat CGLPixelFormatObj],
                                                0, &_visualContext);
    if (ret != noErr) {
        //TRACE(@"QTOpenGLTextureContextCreate() failed: %d", ret);
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
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    SetMovieVisualContext([_qtMovie quickTimeMovie], 0);
    if (_visualContext) {
        CFRelease(_visualContext);
    }
    [_qtMovie release], _qtMovie = nil;
    if ([_indexingUpdateTimer isValid]) {
        [_indexingUpdateTimer invalidate];
        _indexingUpdateTimer = nil;
    }
    [super cleanup];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)updateIndexedDuration:(NSTimer*)timer
{
    float duration = _indexedDuration;
    long ret = GetMovieLoadState([_qtMovie quickTimeMovie]);
    if (ret == kMovieLoadStateComplete) {
        [_indexingUpdateTimer invalidate];
        _indexingUpdateTimer = nil;
        duration = [self duration];
    }
    else {
        TimeValue tv;
        if (noErr == GetMaxLoadedTimeInMovie([_qtMovie quickTimeMovie], &tv)) {
            duration = tv / 1000.0;
        }
    }
    if (_indexedDuration != duration) {
        _indexedDuration = duration;
        //TRACE(@"%s _indexDuration=%.1f %@", __PRETTY_FUNCTION__, _indexDuration,
        //      (ret == kMovieLoadStateComplete) ? @"(complete)" : @"");
        [[NSNotificationCenter defaultCenter]
         postNotificationName:MMovieIndexedDurationNotification object:self];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark volume

- (void)setVolume:(float)volume
{
    [_qtMovie setVolume:volume];
    [super setVolume:volume];
}

- (void)setMuted:(BOOL)muted
{
    [_qtMovie setMuted:muted];
    [super setMuted:muted];
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
- (void)setRate:(float)rate { [_qtMovie setRate:rate]; }
- (void)stepBackward { [_qtMovie stepBackward]; }
- (void)stepForward { [_qtMovie stepForward]; }
- (void)gotoBeginning { [_qtMovie gotoBeginning]; }
- (void)gotoEnd { [_qtMovie gotoEnd]; }

- (void)gotoTime:(float)time
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
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

- (void)seekByTime:(float)dt
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, dt);
    float time = [self currentTime] + dt;
    time = (dt < 0) ? MAX(0, time) : MIN(time, [self duration]);
    [self gotoTime:time];
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

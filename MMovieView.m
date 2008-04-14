//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
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

#import "MMovieView.h"

#import "MMovie.h"
#import "MSubtitle.h"

#import "MTextOSD.h"
#import "MImageOSD.h"
#import "SubtitleRenderer.h"

#import "AppController.h"   // for NSApp's delegate

static CVReturn displayLinkOutputCallback(CVDisplayLinkRef displayLink,
                                          const CVTimeStamp* inNow,
                                          const CVTimeStamp* inOutputTime,
                                          CVOptionFlags flagsIn,
                                          CVOptionFlags* flagsOut,
                                          void* displayLinkContext)
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
	return [(MMovieView*)displayLinkContext updateImage:inOutputTime];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovieView

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // _displayLink
    _displayID = CGMainDisplayID();
    CVReturn cvRet = CVDisplayLinkCreateWithCGDisplay(_displayID, &_displayLink);
    if (cvRet != kCVReturnSuccess) {
        //TRACE(@"CVDisplayLinkCreateWithCGDisplay() failed: %d", cvRet);
        // FIXME: alert...
        return;
    }
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink,
                                                      [[self openGLContext] CGLContextObj],
                                                      [[self pixelFormat] CGLPixelFormatObj]);
    CVDisplayLinkSetOutputCallback(_displayLink, &displayLinkOutputCallback, self);
    CVDisplayLinkStart(_displayLink);
    _drawLock = [[NSRecursiveLock alloc] init];

    // image
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (id)colorSpace, kCIContextOutputColorSpace,
                                        (id)colorSpace, kCIContextWorkingColorSpace, nil];
    _ciContext = [[CIContext contextWithCGLContext:[[self openGLContext] CGLContextObj]
                                       pixelFormat:[[self pixelFormat] CGLPixelFormatObj]
                                           options:dict] retain];
    CGColorSpaceRelease(colorSpace);

    _colorFilter = [[CIFilter filterWithName:@"CIColorControls"] retain];
    _hueFilter = [[CIFilter filterWithName:@"CIHueAdjust"] retain];
    _cropFilter = [[CIFilter filterWithName:@"CICrop"] retain];
    [_colorFilter setDefaults];
    [_hueFilter setDefaults];

    // OSD: icon, message, subtitle
    NSRect rect = [self bounds];
    _subtitleRenderer = [[SubtitleRenderer alloc] initWithMovieView:self];
    _subtitleImageOSD = [[MTextImageOSD alloc] init];
    [_subtitleImageOSD setMovieRect:rect];
    [_subtitleImageOSD setHAlign:OSD_HALIGN_CENTER];
    [_subtitleImageOSD setVAlign:OSD_VALIGN_LOWER_FROM_MOVIE_BOTTOM];
    _subtitleVisible = TRUE;
    _autoSubtitlePositionMaxLines = 3;
    _subtitlePosition = SUBTITLE_POSITION_AUTO; // for initial update

    _messageOSD = [[MTextOSD alloc] init];
    [_messageOSD setMovieRect:rect];
    [_messageOSD setHAlign:OSD_HALIGN_LEFT];
    [_messageOSD setVAlign:OSD_VALIGN_UPPER_FROM_MOVIE_TOP];
    _messageHideInterval = 2.0;

    _errorOSD = [[MTextOSD alloc] init];
    [_errorOSD setMovieRect:rect];
    [_errorOSD setTextAlignment:NSCenterTextAlignment];
    [_errorOSD setHAlign:OSD_HALIGN_CENTER];
    [_errorOSD setVAlign:OSD_VALIGN_CENTER];

    _iconOSD = [[MImageOSD alloc] init];
    [_iconOSD setMovieRect:rect];
    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    [_iconOSD setHAlign:OSD_HALIGN_CENTER];
    [_iconOSD setVAlign:OSD_VALIGN_CENTER];

    // etc. options
    _fullScreenFill = FS_FILL_NEVER;
    _fullScreenUnderScan = 0.0;
    _draggingAction = DRAGGING_ACTION_NONE;
    _captureFormat = CAPTURE_FORMAT_PNG;
    _includeLetterBoxOnCapture = TRUE;
    _removeGreenBox = FALSE;

    // drag-and-drop
    [self registerForDraggedTypes:MOVIST_DRAG_TYPES];

    // notifications
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowMoved:)
               name:NSWindowDidMoveNotification object:[self window]];
    [nc addObserver:self selector:@selector(frameResized:)
               name:NSViewFrameDidChangeNotification object:self];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self invalidateMessageHideTimer];
    if (_displayLink) {
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
    }
    [_drawLock release];

    if (_image) {
        CVOpenGLTextureRelease(_image);
        _image = nil;
    }
    [_cropFilter release];
    [_hueFilter release];
    [_colorFilter release];
    [_ciContext release];

    [_iconOSD release];
    [_errorOSD release];
    [_messageOSD release];
    [_subtitleImageOSD release];
    [_subtitleRenderer release];
    [_subtitles release];
    [_movie release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

- (void)windowMoved:(NSNotification*)aNotification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSDictionary* deviceDesc = [[[self window] screen] deviceDescription];
    NSNumber* screenNumber = [deviceDesc objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID displayID = (CGDirectDisplayID)[screenNumber intValue];
    if (displayID && displayID != _displayID) {
        CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
        _displayID = displayID;
        TRACE(@"main window moved: display changed");
        [self updateSubtitlePosition];
        [[NSApp delegate] updateSubtitlePositionMenuItems];
    }
}

- (CGDirectDisplayID)displayID { return _displayID; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL

- (void)prepareOpenGL
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
	GLint swapInterval = 1;
	[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
}

- (void)update
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_drawLock lock];
        [super update];
    [_drawLock unlock];
}

- (void)reshape
{ 
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSRect bounds = [self bounds];
    glViewport(0, 0, bounds.size.width, bounds.size.height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, bounds.size.width, 0, bounds.size.height, -1.0f, 1.0f);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

- (void)drawOSD
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // set OpenGL states
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    NSRect frame = [self frame];
    glScalef(2.0f / frame.size.width, -2.0f / frame.size.height, 1.0f);
    glTranslatef(-frame.size.width / 2.0f, -frame.size.height / 2.0f, 0.0f);

    NSRect bounds = [self bounds];
    if ([_iconOSD hasContent]) {
        [_iconOSD drawInViewBounds:bounds];
    }
    if (_subtitleVisible && [_subtitleImageOSD hasContent]) {
        [_subtitleImageOSD drawInViewBounds:bounds];
    }
    if ([_messageOSD hasContent]) {
        [_messageOSD drawInViewBounds:bounds];
    }
    if ([_errorOSD hasContent]) {
        [_errorOSD drawInViewBounds:bounds];
    }

    // restore OpenGL status
    glPopMatrix(); // GL_MODELVIEW
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);

    glDisable(GL_TEXTURE_RECTANGLE_EXT);
    glDisable(GL_BLEND);
}

- (void)drawDragHighlight
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    NSRect rect = [self bounds];
    float x1 = NSMinX(rect), y1 = NSMinY(rect);
    float x2 = NSMaxX(rect), y2 = NSMaxY(rect);
    float w = 8.0;
    glColor4f(0.0, 0.0, 1.0, 0.25);
    glBegin(GL_QUADS);
        // bottom
        glVertex2f(x1, y1);         glVertex2f(x2,     y1);
        glVertex2f(x2, y1 + w);     glVertex2f(x1,     y1 + w);
        // right
        glVertex2f(x2 - w, y1 + w); glVertex2f(x2,     y1 + w);
        glVertex2f(x2,     y2 - w); glVertex2f(x2 - w, y2 - w);
        // top
        glVertex2f(x1, y2 - w);     glVertex2f(x2,     y2 - w);
        glVertex2f(x2, y2);         glVertex2f(x1,     y2);
        // left
        glVertex2f(x1,     y1 + w); glVertex2f(x1 + w, y1 + w);
        glVertex2f(x1 + w, y2 - w); glVertex2f(x1,     y2 - w);
    glEnd();
    glColor3f(1.0, 1.0, 1.0);

    glDisable(GL_BLEND);
}

- (void)drawRect:(NSRect)rect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    [_drawLock lock];
        [[self openGLContext] makeCurrentContext];
        glClear(GL_COLOR_BUFFER_BIT);

        if (_image) {
            CIImage* img = [CIImage imageWithCVImageBuffer:_image];
            if (_removeGreenBox) {
                [_cropFilter setValue:img forKey:@"inputImage"];
                img = [_cropFilter valueForKey:@"outputImage"];
            }
            if ([self brightness] != 0.0 ||
                [self saturation] != 1.0 ||
                [self contrast] != 1.0) {
                [_colorFilter setValue:img forKey:@"inputImage"];
                img = [_colorFilter valueForKey:@"outputImage"];
            }
            if ([self hue] != 0.0) {
                [_hueFilter setValue:img forKey:@"inputImage"];
                img = [_hueFilter valueForKey:@"outputImage"];
            }
            [_ciContext drawImage:img inRect:_movieRect fromRect:_imageRect];
        }

        if ([_iconOSD hasContent] ||
            [_messageOSD hasContent] || [_errorOSD hasContent] ||
            (_subtitleVisible && [_subtitleImageOSD hasContent])) {
            [self drawOSD];
        }

        if (_dragAction != DRAG_ACTION_NONE) {
            [self drawDragHighlight];
        }
        glFlush();
        [_movie idleTask];
    [_drawLock unlock];
}

- (void)frameResized:(NSNotification*)notification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self updateMovieRect:FALSE];
    if ([self subtitleVisible]) {
        [self updateSubtitle];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark movie

- (MMovie*)movie { return _movie; }
- (NSRect)movieRect { return *(NSRect*)&_movieRect; }
- (float)currentFps { return _currentFps; }

- (void)setMovie:(MMovie*)movie
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, movie);
    [_drawLock lock];
    [movie retain], [_movie release], _movie = movie;
    [_subtitles release], _subtitles = nil;
    if (_image) {
        CVOpenGLTextureRelease(_image);
        _image = nil;
    }

    if (_movie) {
        NSSize es = [_movie encodedSize];
        CIVector* vector = [CIVector vectorWithX:1.0 Y:1.0
                                               Z:es.width - 2.0 W:es.height - 2.0];
        [_cropFilter setValue:vector forKey:@"inputRectangle"];
        NSSize movieSize = [_movie adjustedSizeByAspectRatio];
        [_messageOSD setMovieSize:movieSize];
        [_subtitleImageOSD setMovieSize:movieSize];
        [_subtitleRenderer setMovieSize:movieSize];
    }
    [_subtitleRenderer clearSubtitleContent];
    [_subtitleImageOSD clearContent];
    [self updateSubtitlePosition];
    [_drawLock unlock];
    [self updateMovieRect:TRUE];

    _lastFpsCheckTime = 0.0;
    _fpsElapsedTime = 0.0;
    _fpsFrameCount = 0;
}

- (void)showLogo
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_drawLock lock];
    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    [_drawLock unlock];
}

- (void)hideLogo
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_drawLock lock];
    [_iconOSD clearContent];
    [_drawLock unlock];
}

- (void)updateMovieRect:(BOOL)display
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, display ? @"display" : @"no-display");
    [_drawLock lock];
    if (!_movie) {
        NSRect mr = [self bounds];
        [_iconOSD setMovieRect:mr];
        [_messageOSD setMovieRect:mr];
    }
    else {
        // update _imageRect
        NSSize es = [_movie encodedSize];
        _imageRect.origin.x = 0;
        _imageRect.origin.y = 0;
        _imageRect.size.width = es.width;
        _imageRect.size.height = es.height;
        // always crop!!!
        _imageRect.origin.x++, _imageRect.size.width  -= 2;
        _imageRect.origin.y++, _imageRect.size.height -= 2;

        if ([[NSApp delegate] isFullScreen] && _fullScreenFill == FS_FILL_CROP) {
            NSSize bs = [self bounds].size;
            NSSize ms = [_movie adjustedSizeByAspectRatio];
            if (bs.width / bs.height < ms.width / ms.height) {
                float mw = ms.width * bs.height / ms.height;
                float dw = (mw - bs.width) * ms.width / mw;
                _imageRect.origin.x += dw / 2;
                _imageRect.size.width -= dw;
            }
            else {
                float mh = ms.height * bs.width / ms.width;
                float dh = (mh - bs.height) * ms.height / mh;
                _imageRect.origin.y += dh / 2;
                _imageRect.size.height -= dh;
            }
        }
        // update _movieRect
        NSRect mr = [self calcMovieRectForBoundingRect:[self bounds]];
        _movieRect = *(CGRect*)&mr;
        [_iconOSD setMovieRect:mr];
        [_messageOSD setMovieRect:mr];
        [_subtitleImageOSD setMovieRect:mr];
        [_subtitleRenderer setMovieRect:mr];
    }
    [_errorOSD setMovieRect:NSInsetRect([self bounds], 50, 0)];
    [_drawLock unlock];

    if (display) {
        [self redisplay];
    }
}

- (float)subtitleLineHeightForMovieWidth:(float)movieWidth
{
    float fontSize = [_subtitleRenderer fontSize] * movieWidth / 640.0;
    //fontSize = MAX(15.0, fontSize);
    NSFont* font = [NSFont fontWithName:[_subtitleRenderer fontName] size:fontSize];

    NSMutableAttributedString* s = [[[NSMutableAttributedString alloc]
        initWithString:NSLocalizedString(@"SubtitleTestChar", nil)] autorelease];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];
    
    NSSize maxSize = NSMakeSize(1000, 1000);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin |
                                     NSStringDrawingUsesFontLeading |
                                     NSStringDrawingUsesDeviceMetrics;
    return [s boundingRectWithSize:maxSize options:options].size.height;
}

- (float)calcLetterBoxHeight:(NSRect)movieRect
{
    if (_subtitlePosition == SUBTITLE_POSITION_ON_MOVIE ||
        _subtitlePosition == SUBTITLE_POSITION_ON_LETTER_BOX) {
        return 0.0;
    }

    float lineHeight = [self subtitleLineHeightForMovieWidth:movieRect.size.width];
    float lineSpacing = [_subtitleRenderer lineSpacing] * movieRect.size.width / 640.0;
    int lines = _subtitlePosition - SUBTITLE_POSITION_ON_LETTER_BOX;
    // FIXME: how to apply line-spacing for line-height?  it's estimated roughly...
    return lines * (lineHeight + lineSpacing / 2);
}

- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromSize(boundingSize));
    if ([[NSApp delegate] isFullScreen] && 0 < _fullScreenUnderScan) {
        float underScan = _fullScreenUnderScan / 100.0;
        boundingRect = NSInsetRect(boundingRect,
                                   boundingRect.size.width  * underScan / 2,
                                   boundingRect.size.height * underScan / 2);
    }

    if ([[NSApp delegate] isFullScreen] && _fullScreenFill != FS_FILL_NEVER) {
        return boundingRect;
    }
    else {
        NSRect rect;
        rect.origin = boundingRect.origin;

        NSSize bs = boundingRect.size;
        NSSize ms = [_movie adjustedSizeByAspectRatio];
        if (bs.width / bs.height < ms.width / ms.height) {
            rect.size.width = bs.width;
            rect.size.height = rect.size.width * ms.height / ms.width;

            float letterBoxMinHeight = [self calcLetterBoxHeight:rect];
            float letterBoxHeight = (bs.height - rect.size.height) / 2;
            if (letterBoxHeight < letterBoxMinHeight) {
                if (bs.height < rect.size.height + letterBoxMinHeight) {
                    letterBoxHeight = bs.height - rect.size.height;
                }
                else if (bs.height < rect.size.height + letterBoxMinHeight * 2) {
                    letterBoxHeight = letterBoxMinHeight;
                }
            }
            /*
            else if (0 < letterBoxMinHeight) {
                letterBoxHeight = letterBoxMinHeight;
            }
             */
            rect.origin.y += letterBoxHeight;
        }
        else {
            rect.size.height = bs.height;
            rect.size.width = rect.size.height * ms.width / ms.height;
            rect.origin.x += (bs.width - rect.size.width) / 2;
        }
        return rect;
    }
}

- (void)lockDraw   { [_drawLock lock]; }
- (void)unlockDraw { [_drawLock unlock]; }
- (void)redisplay { [self setNeedsDisplay:TRUE]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark display-link

- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    [_drawLock lock];
    if (_movie) {
        CVOpenGLTextureRef image = [_movie nextImage:timeStamp];
        if (image) {
            if (_image) {
                CVOpenGLTextureRelease(_image);
            }
            _image = image;
            [self updateSubtitleString];
            if ([self canDraw]) {
                [self drawRect:NSZeroRect];
            }
            _fpsFrameCount++;
        }
        // calc. fps
        double ct = (double)timeStamp->videoTime / timeStamp->videoTimeScale;
        _fpsElapsedTime += ABS(ct - _lastFpsCheckTime);
        _lastFpsCheckTime = ct;
        if (1.0 <= _fpsElapsedTime) {
            _currentFps = (float)(_fpsFrameCount / _fpsElapsedTime);
            _fpsElapsedTime = 0.0;
            _fpsFrameCount = 0;
        }
    }
    [_drawLock unlock];
    
    [pool release];
    
	return kCVReturnSuccess;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setDraggingAction:(int)action { _draggingAction = action; }
- (void)setCaptureFormat:(int)format { _captureFormat = format; }
- (void)setIncludeLetterBoxOnCapture:(BOOL)include { _includeLetterBoxOnCapture = include; }
- (void)setRemoveGreenBox:(BOOL)remove { _removeGreenBox = remove; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSRect)rectForCapture:(BOOL)alternative
{
    if (_includeLetterBoxOnCapture) {
        return (alternative) ? *(NSRect*)&_movieRect : [self bounds];
    }
    else {
        return (alternative) ? [self bounds] : *(NSRect*)&_movieRect;
    }
}

- (NSImage*)captureRect:(NSRect)rect
{
    float width = MAX(rect.size.width, _movieRect.size.width);
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:0
        pixelsWide:rect.size.width pixelsHigh:rect.size.height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:TRUE isPlanar:FALSE
        colorSpaceName:NSCalibratedRGBColorSpace
        bytesPerRow:width * 4 bitsPerPixel:0] autorelease];

    [_drawLock lock];
    [[self openGLContext] makeCurrentContext];
    glReadPixels((int)rect.origin.x, (int)rect.origin.y,
                 (int)rect.size.width, (int)rect.size.height,
                 GL_RGBA, GL_UNSIGNED_BYTE, [imageRep bitmapData]);
    [NSOpenGLContext clearCurrentContext];
    [_drawLock unlock];

    NSImage* image = [[NSImage alloc] initWithSize:rect.size];
    [image addRepresentation:imageRep];

    // image is flipped. so, flip again. teach me better idea...
    NSImage* imageFlipped = [[NSImage alloc] initWithSize:rect.size];
    [imageFlipped lockFocus];
        [image setFlipped:TRUE];
        [image drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect
                 operation:NSCompositeSourceOver fraction:1.0];
        [image release];
    [imageFlipped unlockFocus];
    return [imageFlipped autorelease];
}

- (NSData*)dataWithImage:(NSImage*)image
{
    NSBitmapImageFileType fileType = NSTIFFFileType;
    NSMutableDictionary* properties = [NSMutableDictionary dictionary];
    if (_captureFormat == CAPTURE_FORMAT_TIFF) {
        fileType = NSTIFFFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:??? forKey:NSImageCompressionMethod];
    }
    else if (_captureFormat == CAPTURE_FORMAT_JPEG) {
        fileType = NSJPEGFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
        //[properties setObject:??? forKey:NSImageProgressive];
    }
    else if (_captureFormat == CAPTURE_FORMAT_PNG) {
        fileType = NSPNGFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:??? forKey:NSImageGamma];
        //[properties setObject:??? forKey:NSImageInterlaced];
    }
    else if (_captureFormat == CAPTURE_FORMAT_BMP) {
        fileType = NSBMPFileType;
    }
    else if (_captureFormat == CAPTURE_FORMAT_GIF) {
        fileType = NSGIFFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:??? forKey:NSImageDitherTransparency];
        //[properties setObject:??? forKey:NSImageRGBColorTable];
    }

    return [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]]
            representationUsingType:fileType properties:properties];
}

- (NSString*)fileExtensionForCaptureFormat:(int)format
{
    /*
    NSString * NSFileTypeForHFSTypeCode(OSType hfsFileTypeCode);
     */
    return (format == CAPTURE_FORMAT_JPEG) ? @"jpeg" :
           (format == CAPTURE_FORMAT_PNG)  ? @"png" :
           (format == CAPTURE_FORMAT_BMP)  ? @"bmp" :
           (format == CAPTURE_FORMAT_GIF)  ? @"gif" :
                   /* CAPTURE_FORMAT_TIFF */ @"tiff";
}

- (NSString*)capturePathAtDirectory:(NSString*)directory
{
    NSString* name = [[[[NSApp delegate] movieURL] path] lastPathComponent];
    NSString* ext = [self fileExtensionForCaptureFormat:_captureFormat];
    directory = [[directory stringByExpandingTildeInPath]
                 stringByAppendingPathComponent:[name stringByDeletingPathExtension]];
    int i = 1;
    NSString* path;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    while (TRUE) {
        path = [directory stringByAppendingFormat:@" %d.%@", i++, ext];
        if (![fileManager fileExistsAtPath:path]) {
            break;
        }
    }
    return path;
}

- (void)copyCurrentImage:(BOOL)alternative
{
    NSImage* image = [self captureRect:[self rectForCapture:alternative]];
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    [pboard setData:[self dataWithImage:image] forType:NSTIFFPboardType];
}

- (void)saveCurrentImage:(BOOL)alternative
{
    NSImage* image = [self captureRect:[self rectForCapture:alternative]];
    NSString* path = [self capturePathAtDirectory:@"~/Desktop"];
    [[self dataWithImage:image] writeToFile:path atomically:TRUE];
}

- (IBAction)copy:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self copyCurrentImage:[sender tag] != 0];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-screen fill

- (int)fullScreenFill { return _fullScreenFill; }
- (float)fullScreenUnderScan { return _fullScreenUnderScan; }
- (void)setFullScreenFill:(int)fill { _fullScreenFill = fill; }
- (void)setFullScreenUnderScan:(float)underScan { _fullScreenUnderScan = underScan; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark color-controls

- (float)brightness { return [[_colorFilter valueForKey:@"inputBrightness"] floatValue]; }
- (float)saturation { return [[_colorFilter valueForKey:@"inputSaturation"] floatValue]; }
- (float)contrast   { return [[_colorFilter valueForKey:@"inputContrast"] floatValue]; }
- (float)hue        { return [[_hueFilter valueForKey:@"inputAngle"] floatValue]; }

- (void)setBrightness:(float)brightness
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, brightness);
    [_drawLock lock];
    [_colorFilter setValue:[NSNumber numberWithFloat:brightness]
                    forKey:@"inputBrightness"];
    [_drawLock unlock];
    [self redisplay];
}

- (void)setSaturation:(float)saturation
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, saturation);
    [_drawLock lock];
    [_colorFilter setValue:[NSNumber numberWithFloat:saturation]
                    forKey:@"inputSaturation"];
    [_drawLock unlock];
    [self redisplay];
}

- (void)setContrast:(float)contrast
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, contrast);
    [_drawLock lock];
    [_colorFilter setValue:[NSNumber numberWithFloat:contrast]
                    forKey:@"inputContrast"];
    [_drawLock unlock];
    [self redisplay];
}

- (void)setHue:(float)hue
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, hue);
    [_drawLock lock];
    [_hueFilter setValue:[NSNumber numberWithFloat:hue]
                  forKey:@"inputAngle"];
    [_drawLock unlock];
    [self redisplay];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark event-handling

- (BOOL)acceptsFirstResponder { return TRUE; }

- (void)keyDown:(NSEvent*)event
{
    //TRACE(@"%s \"%@\" (modifierFlags=%u)", __PRETTY_FUNCTION__,
    //      [event characters], [event modifierFlags]);
    unichar key = [[event characters] characterAtIndex:0];
    BOOL shiftPressed = ([event modifierFlags] & NSShiftKeyMask) ? TRUE : FALSE;
    switch (key) {
        case ' ' :  // space: toggle play/pause
            [[NSApp delegate] playAction:self];
            break;
        case NSCarriageReturnCharacter :    // return : toggle full-screen
        case NSEnterCharacter :             // enter (in keypad)
            if (_movie) {
                [[NSApp delegate] fullScreenAction:self];
            }
            break;
        case 27 :   // escape
            if ([[NSApp delegate] isFullScreen]) {
                [[NSApp delegate] fullScreenAction:self];
            }
            else if (_movie) {
                [[NSApp delegate] closeMovie];
                [self showLogo];
            }
            else {
                [[NSApp mainWindow] performClose:self];
            }
            break;

        case 'n' : case 'N' : [[NSApp delegate] fullNavigationAction:self]; break;

        case '[' : case '{' : [[NSApp delegate] stepBackward];              break;
        case ']' : case '}' : [[NSApp delegate] stepForward];               break;

        case 'c' : case 'C' : [[NSApp delegate] changePlayRate:+1];         break;
        case 'x' : case 'X' : [[NSApp delegate] changePlayRate:-1];         break;
        case 'z' : case 'Z' : [[NSApp delegate] changePlayRate: 0];         break;

        case 'v' : case 'V' : [[NSApp delegate] changeSubtitleVisible];     break;
        case 's' : case 'S' : [[NSApp delegate] changeSubtitleLanguage:-1]; break;

        case 'h' : case 'H' : [[NSApp delegate] changeSubtitlePosition: 0]; break;
        case 'j' : case 'J' : [[NSApp delegate] changeSubtitlePosition:-1]; break;
        case 'k' : case 'K' : [[NSApp delegate] changeSubtitlePosition:+1]; break;

        case ',' : case '<' : [[NSApp delegate] changeSubtitleSync:-1];     break;
        case '.' : case '>' : [[NSApp delegate] changeSubtitleSync:+1];     break;
        case '/' : case '?' : [[NSApp delegate] changeSubtitleSync: 0];     break;

        case 'm' : case 'M' : [[NSApp delegate] setMuted:![_movie muted]];  break;

        case 'i' : case 'I' : [self saveCurrentImage:shiftPressed];         break;
    }
}

- (int)draggingActionWithModifierFlags:(unsigned int)flags
{
    return (flags & NSControlKeyMask)   ? DRAGGING_ACTION_MOVE_WINDOW :
           (flags & NSAlternateKeyMask) ? DRAGGING_ACTION_CAPTURE_MOVIE :
                                          _draggingAction;
}

- (void)mouseDown:(NSEvent*)event
{
    //TRACE(@"%s clickCount=%d", __PRETTY_FUNCTION__, [event clickCount]);
    if (2 <= [event clickCount]) {
        [[NSApp delegate] fullScreenAction:self];
    }
    else {
        int action = [self draggingActionWithModifierFlags:[event modifierFlags]];
        if (action == DRAGGING_ACTION_MOVE_WINDOW) {
            if (![[NSApp delegate] isFullScreen]) {
                [[self window] mouseDown:event];
            }
        }
    }
}

- (NSSize)thumbnailSizeForImageSize:(NSSize)imageSize
{
    const float MAX_SIZE = 192;
    return (imageSize.width < imageSize.height) ?
        NSMakeSize(MAX_SIZE * imageSize.width / imageSize.height, MAX_SIZE) :
        NSMakeSize(MAX_SIZE, MAX_SIZE * imageSize.height / imageSize.width);
}

- (void)mouseDragged:(NSEvent*)event
{
    int action = [self draggingActionWithModifierFlags:[event modifierFlags]];
    if (action == DRAGGING_ACTION_MOVE_WINDOW) {
        if (![[NSApp delegate] isFullScreen]) {
            [[self window] mouseDragged:event];
        }
    }
    else if (action == DRAGGING_ACTION_CAPTURE_MOVIE) {
        BOOL alt = ([event modifierFlags] & NSShiftKeyMask) ? TRUE : FALSE;
        _captureImage = [[self captureRect:[self rectForCapture:alt]] retain];

//#define _REAL_SIZE_DRAGGING
#if defined(_REAL_SIZE_DRAGGING)
        _draggingPoint = [event locationInWindow];
        _draggingPoint.x -= [self frame].origin.x;
        _draggingPoint.y -= [self frame].origin.y;
        NSRect rect;
        rect.size = [_captureImage size];
        rect.origin = NSMakePoint(0, 0);
#else
        NSRect rect;
        rect.size = [self thumbnailSizeForImageSize:[_captureImage size]];
        rect.origin = [self convertPoint:[event locationInWindow] fromView:nil];
        rect.origin.x -= rect.size.width / 2;
        rect.origin.y -= rect.size.height / 2;
#endif
        NSString* ext = [self fileExtensionForCaptureFormat:_captureFormat];
        [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:ext]
                              fromRect:rect source:self slideBack:TRUE event:event];
    }
}

- (void)dragImage:(NSImage*)image at:(NSPoint)imageLoc offset:(NSSize)mouseOffset
            event:(NSEvent*)event pasteboard:(NSPasteboard*)pboard
           source:(id)sourceObject slideBack:(BOOL)slideBack
{
#if defined(_REAL_SIZE_DRAGGING)
    NSSize size = [_captureImage size];
#else
    NSSize size = [self thumbnailSizeForImageSize:[_captureImage size]];
#endif
    NSImage* dragImage = [[[NSImage alloc] initWithSize:size] autorelease];
    [dragImage lockFocus];
        [dragImage setBackgroundColor:[NSColor clearColor]];
        [_captureImage drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSZeroRect
                    operation:NSCompositeSourceOver fraction:0.5];
    [dragImage unlockFocus];

    [super dragImage:dragImage at:imageLoc offset:mouseOffset
               event:event pasteboard:pboard source:sourceObject slideBack:slideBack];
}

- (NSArray*)namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination
{
    _capturePath = [[self capturePathAtDirectory:[dropDestination path]] retain];
    return [NSArray arrayWithObject:_capturePath];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)forLocal
{
    return (forLocal) ? NSDragOperationNone : NSDragOperationCopy;
}
/*
#if defined(_REAL_SIZE_DRAGGING)
- (void)draggedImage:(NSImage*)image movedTo:(NSPoint)screenPoint
{
    screenPoint.x += _draggingPoint.x;
    screenPoint.y += _draggingPoint.y;
    NSSize size;
    if (NSPointInRect(screenPoint, [[self window] frame])) {
        size = [_captureImage size];
    }
    else {
        size = [self thumbnailSizeForImageSize:[_captureImage size]];
    }
    if (!NSEqualSizes([image size], size)) {
        // FIXME: I don't know how to change image size???
        TRACE(@"change to %@",NSEqualSizes([_captureImage size], size) ?
                                        @"real size" : @"thumbnail size");
        [image lockFocus];
        [image setSize:size];
        [image setBackgroundColor:[NSColor clearColor]];
        [_captureImage drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSZeroRect
                        operation:NSCompositeSourceOver fraction:0.5];
        [image unlockFocus];
    }
}
#endif
*/
- (void)draggedImage:(NSImage*)image
             endedAt:(NSPoint)point operation:(NSDragOperation)operation
{
    [[self dataWithImage:_captureImage] writeToFile:_capturePath atomically:TRUE];

    [_capturePath release], _capturePath = nil;
    [_captureImage release], _captureImage = nil;
}

- (void)scrollWheel:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[self window] scrollWheel:event];
}

@end

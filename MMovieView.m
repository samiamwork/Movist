//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovieView.h"

#import "MMovie.h"
#import "MSubtitle.h"

#import "MImageOSD.h"
#import "MTextOSD.h"
#import "MSubtitleOSD.h"
#import "MBarOSD.h"

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
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // _displayLink
    _displayID = CGMainDisplayID();
    CVReturn cvRet = CVDisplayLinkCreateWithCGDisplay(_displayID, &_displayLink);
    if (cvRet != kCVReturnSuccess) {
        TRACE(@"CVDisplayLinkCreateWithCGDisplay() failed: %d", cvRet);
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
    _fullScreenFill = FS_FILL_NEVER;
    _removeGreenBox = FALSE;

    // OSD: icon, message, subtitle & bar
    NSRect rect = [self bounds];
    _iconOSD = [[MImageOSD alloc] init];        [_iconOSD setMovieRect:rect];
    _messageOSD = [[MTextOSD alloc] init];      [_messageOSD setMovieRect:rect];
    _subtitleOSD = [[MSubtitleOSD alloc] init]; [_subtitleOSD setMovieRect:rect];
    _barOSD = [[MBarOSD alloc] init];           [_barOSD setMovieRect:rect];
    _messageHideInterval = 2.0;
    _subtitleVisible = TRUE;
    _barHideInterval = 2.0;

    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    [_iconOSD setHAlign:OSD_HALIGN_CENTER];
    [_iconOSD setVAlign:OSD_VALIGN_CENTER];

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
    TRACE(@"%s", __PRETTY_FUNCTION__);
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

    [self invalidateMessageHideTimer];
    [_iconOSD release];
    [_messageOSD release];
    [_subtitleOSD release];
    [_barOSD release];
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
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL

- (void)prepareOpenGL
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    
	long swapInterval = 1;
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
    if (_subtitleVisible && [_subtitleOSD hasContent]) {
        [_subtitleOSD drawInViewBounds:bounds];
    }
    if ([_barOSD hasContent]) {
        [_barOSD drawInViewBounds:bounds];
    }
    if ([_messageOSD hasContent]) {
        [_messageOSD drawInViewBounds:bounds];
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

        if ([_iconOSD hasContent] || [_barOSD hasContent] ||
            [_messageOSD hasContent] ||
            (_subtitleVisible && [_subtitleOSD hasContent])) {
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
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark movie

- (MMovie*)movie { return _movie; }
- (NSRect)movieRect { return *(NSRect*)&_movieRect; }

- (void)setMovie:(MMovie*)movie
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, movie);
    [_drawLock lock];
    [movie retain], [_movie release], _movie = movie;
    [_subtitles release], _subtitles = nil;
    if (_image) {
        CVOpenGLTextureRelease(_image);
        _image = nil;
    }

    if (_movie) {
        [_cropFilter setValue:[CIVector vectorWithX:1.0
                                                  Y:1.0
                                                  Z:[_movie size].width - 2.0
                                                  W:[_movie size].height - 2.0]
                       forKey:@"inputRectangle"];
        [_iconOSD clearContent];
        [_messageOSD setMovieSize:[_movie adjustedSize]];
        [_subtitleOSD setMovieSize:[_movie adjustedSize]];
        [_barOSD setMovieSize:[_movie adjustedSize]];
    }
    else {
        [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    }
    [_subtitleOSD clearContent];
    [_barOSD clearContent];
    [_drawLock unlock];
    [self updateMovieRect:TRUE];
}

- (void)updateMovieRect:(BOOL)display
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, display ? @"display" : @"no-display");
    [_drawLock lock];
    if (!_movie) {
        [_iconOSD setMovieRect:[self bounds]];
    }
    else {
        NSSize bs = [self bounds].size;
        NSSize ms = [_movie adjustedSize];
        // update _imageRect
        _imageRect.origin.x = 0;
        _imageRect.origin.y = 0;
        _imageRect.size.width = [_movie size].width;
        _imageRect.size.height = [_movie size].height;
        if (_removeGreenBox) {
            _imageRect.origin.x++, _imageRect.size.width  -= 2;
            _imageRect.origin.y++, _imageRect.size.height -= 2;
        }
        if ([[NSApp delegate] isFullScreen] && _fullScreenFill == FS_FILL_CROP) {
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
        [_messageOSD setMovieRect:mr];
        [_subtitleOSD setMovieRect:mr];
        [_barOSD setMovieRect:mr];
    }
    [_drawLock unlock];

    if (display) {
        [self setNeedsDisplay:TRUE];
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MMovieRectUpdateNotification object:self];
}

- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromSize(boundingSize));
    if ([[NSApp delegate] isFullScreen] && 0 < _fullScreenUnderScan) {
        float underScan = _fullScreenUnderScan / 100.0;
        float dx = boundingRect.size.width  * underScan;
        float dy = boundingRect.size.height * underScan;
        boundingRect.origin.x += dx / 2, boundingRect.size.width  -= dx;
        boundingRect.origin.y += dy / 2, boundingRect.size.height -= dy;
    }

    if ([[NSApp delegate] isFullScreen] && _fullScreenFill != FS_FILL_NEVER) {
        return boundingRect;
    }
    else {
        NSRect rect;
        rect.origin = boundingRect.origin;

        NSSize bs = boundingRect.size;
        NSSize ms = [_movie adjustedSize];
        if (bs.width / bs.height < ms.width / ms.height) {
            rect.size.width = bs.width;
            rect.size.height = rect.size.width * ms.height / ms.width;

            float letterBoxHeight = (bs.height - rect.size.height) / 2;
            if (letterBoxHeight < _minLetterBoxHeight) {
                if (bs.height < rect.size.height + _minLetterBoxHeight) {
                    letterBoxHeight = bs.height - rect.size.height;
                }
                else if (bs.height < rect.size.height + _minLetterBoxHeight * 2) {
                    letterBoxHeight = _minLetterBoxHeight;
                }
            }
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
            [self drawRect:NSZeroRect];
        }
    }
    [_drawLock unlock];
    
    [pool release];
    
	return kCVReturnSuccess;
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
    TRACE(@"%s %g", __PRETTY_FUNCTION__, brightness);
    [_drawLock lock];
    [_colorFilter setValue:[NSNumber numberWithFloat:brightness]
                    forKey:@"inputBrightness"];
    [_drawLock unlock];
    [self setNeedsDisplay:TRUE];
}

- (void)setSaturation:(float)saturation
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, saturation);
    [_drawLock lock];
    [_colorFilter setValue:[NSNumber numberWithFloat:saturation]
                    forKey:@"inputSaturation"];
    [_drawLock unlock];
    [self setNeedsDisplay:TRUE];
}

- (void)setContrast:(float)contrast
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, contrast);
    [_drawLock lock];
    [_colorFilter setValue:[NSNumber numberWithFloat:contrast]
                    forKey:@"inputContrast"];
    [_drawLock unlock];
    [self setNeedsDisplay:TRUE];
}

- (void)setHue:(float)hue
{
    TRACE(@"%s %g", __PRETTY_FUNCTION__, hue);
    [_drawLock lock];
    [_hueFilter setValue:[NSNumber numberWithFloat:hue]
                  forKey:@"inputAngle"];
    [_drawLock unlock];
    [self setNeedsDisplay:TRUE];
}

- (BOOL)removesGreenBox { return _removeGreenBox; }

- (void)setRemoveGreenBox:(BOOL)remove
{
    _removeGreenBox = remove;
    [self updateMovieRect:TRUE];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark event-handling

- (BOOL)acceptsFirstResponder { return TRUE; }
- (BOOL)resignFirstResponder  { return TRUE; }

- (void)keyDown:(NSEvent*)event
{
    //TRACE(@"%s \"%@\" (modifierFlags=%u)", __PRETTY_FUNCTION__,
    //      [event characters], [event modifierFlags]);
    unichar key = [[event characters] characterAtIndex:0];
    //unsigned int modifierFlags = [event modifierFlags] &
    //    (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask | NSShiftKeyMask);
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
            
        case 'p' : case 'P' : [[NSApp delegate] stepBackward];  break;
        case 'n' : case 'N' : [[NSApp delegate] stepForward];   break;

        /*
        // if AppController's setPureArrowKeyEquivalents does not work, then use these.
        case NSLeftArrowFunctionKey  : [[NSApp delegate] seekBackward:0];   break;
        case NSRightArrowFunctionKey : [[NSApp delegate] seekForward:0];    break;
        case NSUpArrowFunctionKey    : [[NSApp delegate] volumeUp];         break;
        case NSDownArrowFunctionKey  : [[NSApp delegate] volumeDown];       break;
        */
    }
}

- (void)mouseDown:(NSEvent*)event
{
    //TRACE(@"%s clickCount=%d", __PRETTY_FUNCTION__, [event clickCount]);
    if ([event clickCount] == 2) {
        [[NSApp delegate] fullScreenAction:self];
    }
}

- (void)scrollWheel:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp mainWindow] scrollWheel:event];
}

@end

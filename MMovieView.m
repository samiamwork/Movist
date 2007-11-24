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

    // OSD: icon, message, subtitle & bar
    NSRect rect = [self bounds];
    _iconOSD = [[MImageOSD alloc] init];        [_iconOSD setMovieRect:rect];
    _messageOSD = [[MTextOSD alloc] init];      [_messageOSD setMovieRect:rect];
    _subtitleOSD = [[MSubtitleOSD alloc] init]; [_subtitleOSD setMovieRect:rect];
    _barOSD = [[MBarOSD alloc] init];           [_barOSD setMovieRect:rect];
    _errorOSD = [[MTextOSD alloc] init];        [_errorOSD setMovieRect:rect];
    _messageHideInterval = 2.0;
    _subtitleVisible = TRUE;
    _barHideInterval = 2.0;

    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    [_iconOSD setHAlign:OSD_HALIGN_CENTER];
    [_iconOSD setVAlign:OSD_VALIGN_CENTER];

    [_errorOSD setTextAlignment:NSCenterTextAlignment];
    [_errorOSD setHAlign:OSD_HALIGN_CENTER];
    [_errorOSD setVAlign:OSD_VALIGN_CENTER];

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
    [_errorOSD release];
    [_barOSD release];
    [_iconOSD release];
    [_messageOSD release];
    [_subtitleOSD release];
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
    if (_subtitleVisible && [_subtitleOSD hasContent]) {
        [_subtitleOSD drawInViewBounds:bounds];
    }
    if ([_barOSD hasContent]) {
        [_barOSD drawInViewBounds:bounds];
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
            // always crop!!!
            [_cropFilter setValue:img forKey:@"inputImage"];
            img = [_cropFilter valueForKey:@"outputImage"];

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
            [_messageOSD hasContent] || [_errorOSD hasContent] ||
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
        [_messageOSD setMovieSize:[_movie adjustedSize]];
        [_subtitleOSD setMovieSize:[_movie adjustedSize]];
        [_barOSD setMovieSize:[_movie adjustedSize]];
    }
    [_subtitleOSD clearContent];
    [_barOSD clearContent];
    [_drawLock unlock];
    [self updateMovieRect:TRUE];
}

- (void)showLogo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_drawLock lock];
    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    [_drawLock unlock];
}

- (void)hideLogo
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_drawLock lock];
    [_iconOSD clearContent];
    [_drawLock unlock];
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
        // always crop!!!
        _imageRect.origin.x++, _imageRect.size.width  -= 2;
        _imageRect.origin.y++, _imageRect.size.height -= 2;

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
    [_errorOSD setMovieRect:NSInsetRect([self bounds], 50, 0)];
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

- (void)lockDraw   { [_drawLock lock]; }
- (void)unlockDraw { [_drawLock unlock]; }

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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark event-handling

- (BOOL)acceptsFirstResponder { return TRUE; }

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
        /*
        case 'f' : case 'F' :
            if (!_movie && ![[NSApp delegate] isFullScreen]) {
                [[NSApp delegate] fullScreenAction:self];   // begin navigation
            }
            break;
        */
        case 'p' : case 'P' : [[NSApp delegate] stepBackward];          break;
        case 'n' : case 'N' : [[NSApp delegate] stepForward];           break;

        case 'c' : case 'C' : [[NSApp delegate] changePlayRate:+1];     break;
        case 'x' : case 'X' : [[NSApp delegate] changePlayRate:-1];     break;
        case 'z' : case 'Z' : [[NSApp delegate] changePlayRate: 0];     break;

        case 'v' : case 'V' : [[NSApp delegate] changeSubtitleVisible]; break;

        case 'l' : case 'L' : [[NSApp delegate] subtitleDisplayOnLetterBoxAction:self];break;
        case 'u' : case 'U' : [[NSApp delegate] changeMinLetterBoxHeight:+1];   break;
        case 'd' : case 'D' : [[NSApp delegate] changeMinLetterBoxHeight:-1];   break;
        case '0' :            [[NSApp delegate] changeMinLetterBoxHeight: 0];   break;

        case ',' : case '<' : [[NSApp delegate] changePlayRate:-1];     break;
        case '.' : case '>' : [[NSApp delegate] changePlayRate:+1];     break;
        case '/' : case '?' : [[NSApp delegate] changePlayRate: 0];     break;

        case 'm' : case 'M' : [[NSApp delegate] setMuted:![_movie muted]];  break;
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

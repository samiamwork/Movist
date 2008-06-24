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

#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self initCoreVideo]) {
        // FIXME: alert...
        return;
    }
    _drawLock = [[NSRecursiveLock alloc] init];

    if (![self initCoreImage]) {
        // FIXME: alert...
        return;
    }

    if (![self initOSD]) {
        // FIXME: alert...
        return;
    }

    // etc. options
    _fullScreenFill = FS_FILL_NEVER;
    _fullScreenUnderScan = 0.0;
    _viewDragAction = VIEW_DRAG_ACTION_NONE;
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
    [self cleanupCoreImage];
    [self cleanupCoreVideo];
    [_drawLock release];

    [self cleanupOSD];
    [_subtitles release];
    [_movie release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

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
    [self lockDraw];

    [super update];

    [self unlockDraw];
}

- (void)reshape
{ 
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self lockDraw];

    NSRect bounds = [self bounds];
    glViewport(0, 0, bounds.size.width, bounds.size.height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, bounds.size.width, 0, bounds.size.height, -1.0f, 1.0f);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    [self unlockDraw];
}

- (void)drawRect:(NSRect)rect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    if ([_drawLock tryLock]) {
        [self drawImage];
        [_drawLock unlock];
    }
}

- (void)lockDraw   { [_drawLock lock]; }
- (void)unlockDraw { [_drawLock unlock]; }
- (void)redisplay { [self setNeedsDisplay:TRUE]; }

- (BOOL)isOpaque { return TRUE; }
- (BOOL)wantsDefaultClipping { return FALSE; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark movie

- (MMovie*)movie { return _movie; }
- (float)currentFps { return _currentFps; }

- (void)setMovie:(MMovie*)movie
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, movie);
    [self lockDraw];

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
        //[self updateRemoveGreenBox];
    }
    [self clearOSD];
    [self updateSubtitlePosition];
    [self updateMovieRect:TRUE];
    _lastFpsCheckTime = 0.0;
    _fpsElapsedTime = 0.0;
    _fpsFrameCount = 0;

    [self unlockDraw];
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

- (void)mouseDown:(NSEvent*)event
{
    //TRACE(@"%s clickCount=%d", __PRETTY_FUNCTION__, [event clickCount]);
    if (2 <= [event clickCount]) {
        [[NSApp delegate] fullScreenAction:self];
    }
    else {
        int action = [self viewDragActionWithModifierFlags:[event modifierFlags]];
        if (action == VIEW_DRAG_ACTION_MOVE_WINDOW) {
            if (![[NSApp delegate] isFullScreen]) {
                [[self window] mouseDown:event];
            }
        }
    }
}

- (void)scrollWheel:(NSEvent*)event
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[NSApp delegate] scrollWheelAction:event];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark notification

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

- (void)frameResized:(NSNotification*)notification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self updateMovieRect:FALSE];
    if ([self subtitleVisible]) {
        [self updateSubtitle];
    }
}

@end

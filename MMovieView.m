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
#import "MMovie_QuickTime.h"
#import "MMovieLayer_FFMPEG.h"
#import "MMovieLayer_AVFoundation.h"
#import "MSubtitle.h"
#import "RigidConstraintLayoutManager.h"

#import "MMovieOSD.h"

#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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

	// add layer
	_rootLayer = [CALayer layer];
	CGColorRef orange = CGColorCreateGenericRGB(1.0, 0.5, 0.0, 1.0);
	CGColorRef lightBlue = CGColorCreateGenericRGB(0.0, 0.5, 1.0, 1.0);
	_rootLayer.backgroundColor = orange;
	_rootLayer.layoutManager   = [RigidConstraintLayoutManager layoutManager];
	_rootLayer.borderColor     = lightBlue;
	CGColorRelease(lightBlue);
	CGColorRelease(orange);
	[self setLayer:_rootLayer];
	[self setWantsLayer:YES];

	_iconOSDLayer = [CALayer layer];
	_iconOSDLayer.zPosition = 1.0;
	[_iconOSDLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:0.0]];
	[_iconOSDLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0]];
	[_iconOSDLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:0.0]];
	[_iconOSDLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX offset:0.0]];
	[_rootLayer addSublayer:_iconOSDLayer];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self invalidateMessageHideTimer];
    [self cleanupCoreImage];
    [_drawLock release];

    [self cleanupOSD];
    [_subtitle[0] release];
    [_subtitle[1] release];
    [_subtitle[2] release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)redisplay { [self setNeedsDisplay:TRUE]; }

// TODO: remove these. They're just here to ease the CoreAnimation conversion process
- (NSOpenGLContext*)openGLContext
{
	if([_movieLayer isKindOfClass:[CAOpenGLLayer class]])
		return [(NSOpenGLLayer*)_movieLayer openGLContext];
	return nil;
}

- (NSOpenGLPixelFormat*)pixelFormat
{
	if([_movieLayer isKindOfClass:[CAOpenGLLayer class]])
		return [(NSOpenGLLayer*)_movieLayer openGLPixelFormat];
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark movie

- (MMovie*)movie { return [_movieLayer movie]; }
- (float)currentFps { return _currentFps; }

- (void)setMovie:(MMovie*)movie
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, movie);
    [_drawLock lock];

	[_movieLayer removeFromSuperlayer];
	_movieLayer = nil;

	Class c = [movie class];
	if(c == [MMovie_QuickTime class])
	{
		// use AVPlayerLayer
		_movieLayer = [[MMovieLayer_AVFoundation alloc] init];
	}
	else
	{
		_movieLayer = [[MMovieLayer_FFMPEG alloc] init];
	}
	[_movieLayer setName:@"Movie"];
	// TODO: preserve proper aspect ratio. Probably need to use our own layoutmanager
	[_movieLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:0.0]];
	[_movieLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0]];
	[_movieLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:0.0]];
	[_movieLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX offset:0.0]];
	[_rootLayer addSublayer:[_movieLayer autorelease]];
	[_movieLayer setMovie:movie];

    [self removeAllSubtitles];
	[self clearOSD];
    [self updateOSDImageBaseWidth];
    [self updateLetterBoxHeight];
    [self updateMovieRect:TRUE];
    _lastFpsCheckTime = 0.0;
    _fpsElapsedTime = 0.0;
    _fpsFrameCount = 0;

    [_drawLock unlock];
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
            if ([_movieLayer movie]) {
                [[NSApp delegate] fullScreenAction:self];
            }
            break;
        case 27 :   // escape
            if ([[NSApp delegate] isFullScreen]) {
                [[NSApp delegate] fullScreenAction:self];
            }
            else if ([[NSApp delegate] isDesktopBackground]) {
                [[NSApp delegate] desktopBackgroundAction:self];
            }
            else if ([_movieLayer movie]) {
                [[NSApp delegate] closeMovie];
                [self showLogo];
            }
            else {
                [[NSApp mainWindow] performClose:self];
            }
            break;

        case 'n' : case 'N' : [[NSApp delegate] fullNavigationAction:self];         break;

        case '[' : case '{' : [[NSApp delegate] stepBackward];                      break;
        case ']' : case '}' : [[NSApp delegate] stepForward];                       break;

        case 'c' : case 'C' : [[NSApp delegate] changePlayRate:+1];                 break;
        case 'x' : case 'X' : [[NSApp delegate] changePlayRate:-1];                 break;
        case 'z' : case 'Z' : [[NSApp delegate] changePlayRate: 0];                 break;

        case 'v' : case 'V' : [[NSApp delegate] changeSubtitleVisible];             break;
        case 's' : case 'S' : [[NSApp delegate] changeSubtitleLanguage:-1];         break;

        case 'l' : case 'L' : [[NSApp delegate] changeLetterBoxHeight];             break;
        case 'p' : case 'P' : [[NSApp delegate] changeSubtitlePositionAtIndex:0];   break;

        case ',' : case '<' : [[NSApp delegate] changeSubtitleSync:-1 atIndex:0];   break;
        case '.' : case '>' : [[NSApp delegate] changeSubtitleSync:+1 atIndex:0];   break;
        case '/' : case '?' : [[NSApp delegate] changeSubtitleSync: 0 atIndex:0];   break;

        case 'm' : case 'M' : [[NSApp delegate] setMuted:![[_movieLayer movie] muted]];          break;

        case 'i' : case 'I' : [self saveCurrentImage:shiftPressed];                 break;
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
        _displayID = displayID;
        TRACE(@"main window moved: display changed");
        [self updateLetterBoxHeight];
        [[NSApp delegate] updateLetterBoxHeightMenuItems];
    }
}

- (void)frameResized:(NSNotification*)notification
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self updateMovieRect:FALSE];
}

@end

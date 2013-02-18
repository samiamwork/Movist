//
//  MMovieLayer_FFMPEG.m
//  Movist
//
//  Created by Nur Monson on 7/29/12.
//
//

#import "MMovieLayer_FFMPEG.h"
#import "MMovie_FFMPEG.h"

@interface MMovieLayer_FFMPEG ()
- (void)configure;
- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp;
@end

static CVReturn displayLinkOutputCallback(CVDisplayLinkRef displayLink,
                                          const CVTimeStamp* inNow,
                                          const CVTimeStamp* inOutputTime,
                                          CVOptionFlags flagsIn,
                                          CVOptionFlags* flagsOut,
                                          void* displayLinkContext)
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
	return [(MMovieLayer_FFMPEG*)displayLinkContext updateImage:inOutputTime];
}

@implementation MMovieLayer_FFMPEG

- (id)init
{
	if((self = [super init]))
	{
		[self setOpaque:YES];
		_configured = NO;
		CGColorRef blue = CGColorCreateGenericRGB(0.0, 0.5, 1.0, 1.0);
		self.backgroundColor = blue;
		CGColorRelease(blue);
		self.asynchronous = YES;
		[self setNeedsDisplayOnBoundsChange:YES];
		
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(windowMoved:)
				   name:NSWindowDidMoveNotification object:self.view.window];

		//[self initCoreVideo];
	}
	return self;
}

- (void)dealloc
{
	[self cleanupCoreVideo];
	CVOpenGLTextureRelease(_image);
	[_ciContext release];
	[_movie release];

	[super dealloc];
}

- (BOOL)initCoreVideo
{
	// TODO: not sure we can assume that the current display will be the main display on init
    _displayID = CGMainDisplayID();
    CVReturn cvRet = CVDisplayLinkCreateWithCGDisplay(_displayID, &_displayLink);
    if (cvRet != kCVReturnSuccess) {
        //TRACE(@"CVDisplayLinkCreateWithCGDisplay() failed: %d", cvRet);
        return FALSE;
    }
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink,
                                                      [[self openGLContext] CGLContextObj],
                                                      [[self openGLPixelFormat] CGLPixelFormatObj]);
    CVDisplayLinkSetOutputCallback(_displayLink, &displayLinkOutputCallback, self);
    CVDisplayLinkStart(_displayLink);
    return TRUE;
}

- (void)cleanupCoreVideo
{
	if (_displayLink)
	{
		CVDisplayLinkStop(_displayLink);
		CVDisplayLinkRelease(_displayLink);
	}
}

- (void)setMovie:(MMovie_FFmpeg*)newMovie
{
	if(newMovie == _movie)
		return;
	
	[_movie release];
	_movie = [newMovie retain];
	_movieNeedsGLContext = YES;
}

- (MMovie*)movie
{
	return _movie;
}

- (void)reshape
{
//    //TRACE(@"%s", __PRETTY_FUNCTION__);
//    [_drawLock lock];
//	
//    NSRect bounds = [self bounds];
//    glViewport(0, 0, bounds.size.width, bounds.size.height);
//	
//    glMatrixMode(GL_PROJECTION);
//    glLoadIdentity();
//    glOrtho(0, bounds.size.width, 0, bounds.size.height, -1.0f, 1.0f);
//	
//    glMatrixMode(GL_MODELVIEW);
//    glLoadIdentity();
//	
//    [_drawLock unlock];
}

- (CGDirectDisplayID)currentDisplayID
{
	NSDictionary* deviceDesc = [[self.view.window screen] deviceDescription];
	NSNumber* screenNumber   = [deviceDesc objectForKey:@"NSScreenNumber"];

	return (CGDirectDisplayID)[screenNumber intValue];
}

- (void)windowMoved:(NSNotification*)aNotification
{
	//TRACE(@"%s", __PRETTY_FUNCTION__);
	CGDirectDisplayID displayID = [self currentDisplayID];
	if (displayID != _displayID)
	{
		CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
		_displayID = displayID;
	}
}

- (void)configure
{
	// TODO: put this in copyCGLContextForPixelFormat:
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          (id)colorSpace, kCIContextOutputColorSpace,
                          (id)colorSpace, kCIContextWorkingColorSpace, nil];
	_ciContext = [[CIContext contextWithCGLContext:[self.openGLContext CGLContextObj]
									   pixelFormat:[self.openGLPixelFormat CGLPixelFormatObj]
										colorSpace:colorSpace
										   options:dict] retain];
    CGColorSpaceRelease(colorSpace);

	//GLint swapInterval = 1;
	//[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	_configured = YES;
}

- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp
{
	if(timeStamp == NULL)
		return kCVReturnSuccess;
//	if([_drawLock tryLock])
	{
		CVOpenGLTextureRef image = [_movie nextImage:timeStamp];
		if(image)
		{
			CVOpenGLTextureRelease(_image);
			_image = image;
		}
//		[_drawLock unlock];
	}

	return kCVReturnSuccess;
}

- (void)drawInCGLContext:(CGLContextObj)glContext pixelFormat:(CGLPixelFormatObj)pixelFormat forLayerTime:(CFTimeInterval)timeInterval displayTime:(const CVTimeStamp *)timeStamp
{
//	[_drawLock lock];

	if(!_configured)
	{
		[self configure];
	}
	if(_movieNeedsGLContext)
	{
		NSError* error;
		if(![_movie setOpenGLContext:self.openGLContext pixelFormat:self.openGLPixelFormat error:&error])
		{
			// TODO: return an bool FALSE and the NSError object
			NSLog(@"error: %@", error);
		}
		_movieNeedsGLContext = NO;
	}

	// since we're async and not using displaylink callbacks
	[self updateImage:timeStamp];
	glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, self.bounds.size.width, 0, self.bounds.size.height, -1.0f, 1.0f);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

	if(_image)
	{
		CIImage* img = [CIImage imageWithCVImageBuffer:_image];
		[_ciContext drawImage:img inRect:self.bounds fromRect:CVImageBufferGetCleanRect(_image)];
	}

//	[[self openGLContext] flushBuffer];
//	[_drawLock unlock];
}

@end

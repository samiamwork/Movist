//
//  MMovieLayer_FFMPEG.m
//  Movist
//
//  Created by Nur Monson on 7/29/12.
//
//

#import "MMovieLayer_FFMPEG.h"
#import "MMovie_FFMPEG.h"
#import <OpenGL/gl.h>

@interface MMovieLayer_FFMPEG ()
- (void)configure;
- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp;
@end

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
		self.asynchronous = NO;
		[self setNeedsDisplayOnBoundsChange:YES];
	}
	return self;
}

- (void)dealloc
{
	CVOpenGLTextureRelease(_image);
	[_ciContext release];
	[self setMovie:nil];

	[super dealloc];
}

- (void)setMovie:(MMovie_FFmpeg*)newMovie
{
	if(newMovie == _movie)
		return;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MMovieCurrentTimeNotification object:_movie];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MMovieRateChangeNotification object:_movie];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_movie release];
	_movie = [newMovie retain];
	if(_movie != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChanged:) name:MMovieCurrentTimeNotification object:_movie];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackRateChanged:) name:MMovieRateChangeNotification object:_movie];
	}
	if([_movie rate] > 0.0)
	{
		self.asynchronous = YES;
	}
	else
	{
		self.asynchronous = NO;
	}
	_movieNeedsGLContext = YES;
}

- (MMovie*)movie
{
	return _movie;
}

- (void)playbackRateChanged:(NSNotification*)theNotification
{
	if([_movie rate] == 0.0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			self.asynchronous = NO;
		});
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			self.asynchronous = YES;
		});
	}
}

- (void)currentTimeChanged:(NSNotification*)theNotification
{
	if([_movie rate] == 0.0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setNeedsDisplay];
		});
	}
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

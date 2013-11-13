//
//  MMovieViewLayer.m
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import "MMovieViewLayer.h"
#import "MMovieLayer.h"
#import "MMovie.h"
#import "MMovieOSDLayer.h"

@implementation MMovieViewLayer

- (id)init
{
	if ((self = [super init]))
	{
		CGColorRef black = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
		CGColorRef lightBlue = CGColorCreateGenericRGB(0.0, 0.5, 1.0, 1.0);
		self.backgroundColor = black;
		self.borderColor     = lightBlue;
		CGColorRelease(lightBlue);
		CGColorRelease(black);

		_subtitle = [MMovieOSDLayer layer];
		_subtitle.name                 = @"subtitle";
		_subtitle.hidden               = NO;
		_subtitle.zPosition            = 1.0;
		_subtitle.horizontalPlacement  = OSD_HPOSITION_CENTER;
		_subtitle.verticalPlacement    = OSD_VPOSITION_LBOX;

		[self replaceOldOSD:nil withNew:self.subtitle];
	}

	return self;
}

- (void)setMovie:(CALayer<MMovieLayer>*)newMovie
{
	if(newMovie == _movie)
		return;
	[_movie removeFromSuperlayer];
	[self addSublayer:newMovie];
	_movie = newMovie;
}

- (void)setIcon:(CALayer*)newIcon
{
	if(newIcon == _icon)
		return;
	[_icon removeFromSuperlayer];
	[self addSublayer:newIcon];
	_icon = newIcon;
}

- (void)replaceOldOSD:(MMovieOSDLayer*)oldOSD withNew:(MMovieOSDLayer*)newOSD
{
	[oldOSD removeObserver:self forKeyPath:@"horizontalPlacement"];
	[oldOSD removeObserver:self forKeyPath:@"verticalPlacement"];
	[oldOSD removeFromSuperlayer];
	newOSD.zPosition = 1.0;
	[self addSublayer:newOSD];
	[newOSD addObserver:self forKeyPath:@"horizontalPlacement" options:NSKeyValueObservingOptionNew context:NULL];
	[newOSD addObserver:self forKeyPath:@"verticalPlacement" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setMessage:(MMovieOSDLayer*)newMessage
{
	if(newMessage == _message)
		return;
	[self replaceOldOSD:_message withNew:newMessage];
	_message = newMessage;
}

- (void)setError:(MMovieOSDLayer*)newError
{
	if(newError == _error)
		return;
	[self replaceOldOSD:_error withNew:newError];
	_error = newError;
}


- (void)setSubtitleEnabled:(BOOL)isEnabled
{
	if(_subtitleEnabled == isEnabled)
		return;

	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		self.subtitle.hidden = !isEnabled;
	}
	[CATransaction commit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == _message)
	{
		[self setNeedsLayout];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)layoutIcon
{
	if(!_icon)
		return;

	_icon.position = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
	CGImageRef iconImageRef = (CGImageRef)_icon.contents;
	_icon.bounds = (CGRect){
		.origin = CGPointZero,
		.size = (CGSize){.width = CGImageGetWidth(iconImageRef), .height = CGImageGetHeight(iconImageRef)}
	};
}

- (void)layoutMovie
{
	NSSize movieSize = [_movie.movie adjustedSizeByAspectRatio];
	if(!_movie || movieSize.width*movieSize.height <= 0.0)
	{
		_movie.frame = self.bounds;
		return;
	}

	// TODO: to match the old way, the y-offset should be at least the height of
	//       one (to three) line(s) of the first subtitle that's in the letterbox.
	CGFloat movieAspectRatio = movieSize.width/movieSize.height;
	CGFloat boundsAspectRation = self.bounds.size.width/self.bounds.size.height;
	if(movieAspectRatio > boundsAspectRation)
	{
		CGSize size = (CGSize){.width = self.bounds.size.width, .height = self.bounds.size.width/movieAspectRatio};
		_movie.frame = (CGRect){
			.origin = (CGPoint){.x = 0.0, .y = (self.bounds.size.height-size.height)/2.0},
			.size   = size,
		};
	}
	else
	{
		CGSize size = (CGSize){.width = self.bounds.size.height*movieAspectRatio, .height = self.bounds.size.height};
		_movie.frame = (CGRect){
			.origin = (CGPoint){.x = (self.bounds.size.width-size.width)/2.0, .y = 0.0},
			.size   = size,
		};
	}
}

- (void)layoutOSD:(MMovieOSDLayer*)osd
{
	CGPoint newPosition = CGPointZero;
	switch(osd.horizontalPlacement)
	{
		case OSD_HPOSITION_LEFT:   newPosition.x = 0.0; break;
		case OSD_HPOSITION_CENTER: newPosition.x = self.bounds.size.width/2.0; break;
		case OSD_HPOSITION_RIGHT:  newPosition.x = self.bounds.size.width; break;
		default: break;
	}

	// Assumes that the movie layer has been layed-out already
	switch(osd.verticalPlacement)
	{
		case OSD_VPOSITION_LBOX:   newPosition.y = 0.0; break;
		case OSD_VPOSITION_BOTTOM: newPosition.y = _movie.frame.origin.y; break;
		case OSD_VPOSITION_CENTER: newPosition.y = self.bounds.size.height/2.0; break;
		case OSD_VPOSITION_UBOX:   newPosition.y = self.bounds.size.height; break;
		case OSD_VPOSITION_TOP:    newPosition.y = CGRectGetMaxY(_movie.frame); break;
		default: break;
	}

	osd.position = newPosition;
}

- (void)layoutSublayers
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		[self layoutIcon];
		[self layoutMovie];
		[self layoutOSD:_message];
		[self layoutOSD:_subtitle];
	}
	[CATransaction commit];
}

@end

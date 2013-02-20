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

- (void)layoutIcon
{
	if(!_icon)
		return;

	_icon.position = self.position;
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

- (void)layoutSublayers
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		[self layoutIcon];
		[self layoutMovie];
	}
	[CATransaction commit];
}

@end

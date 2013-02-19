//
//  MMovieViewLayer.m
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import "MMovieViewLayer.h"

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

- (void)setMovie:(CALayer*)newMovie
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
	if(!_movie)
		return;

	_movie.frame = self.bounds;
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

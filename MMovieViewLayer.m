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

- (void)layoutMessage
{
	CGPoint newPosition;
	switch(_message.horizontalPlacement)
	{
		case OSD_HPOSITION_LEFT:   newPosition.x = 0.0; break;
		case OSD_HPOSITION_CENTER: newPosition.x = self.bounds.size.width/2.0; break;
		case OSD_HPOSITION_RIGHT:  newPosition.x = self.bounds.size.width; break;
		default: break;
	}

	switch(_message.verticalPlacement)
	{
		case OSD_VPOSITION_LBOX:   // TODO: should be bottom of video (I think)
		case OSD_VPOSITION_BOTTOM: newPosition.y = 0.0; break;
		case OSD_VPOSITION_CENTER: newPosition.y = self.bounds.size.height/2.0; break;
		case OSD_VPOSITION_UBOX:   // TODO: should be top of video (I think)
		case OSD_VPOSITION_TOP:    newPosition.y = self.bounds.size.height; break;
		default: break;
	}

	_message.position = newPosition;
}

- (void)layoutSublayers
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		[self layoutIcon];
		[self layoutMovie];
		[self layoutMessage];
	}
	[CATransaction commit];
}

@end

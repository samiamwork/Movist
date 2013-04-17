//
//  MMovieOSDLayer.m
//  Movist
//
//  Created by Nur Monson on 2/23/13.
//
//

#import "MMovieOSDLayer.h"
#import "Movist.h"
#import <Cocoa/Cocoa.h>

@interface MMovieOSDLayer ()
{
	NSImage* _currentImage;
}

@end
@implementation MMovieOSDLayer

- (id)init
{
	if((self = [super init]))
	{
		self.anchorPoint = (CGPoint){ .x = 0.0, .y = 0.0 };
	}

	return self;
}

- (void)setTextImage:(NSImage*)newImage
{
	if(newImage == _currentImage)
		return;

	_currentImage = newImage;
	dispatch_async(dispatch_get_main_queue(), ^{
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
		{
			if(newImage == nil)
			{
				self.contents = nil;
			}
			else
			{
				CGImageRef cgImage = [newImage CGImageForProposedRect:NULL context:nil hints:nil];
				self.contents = (id)cgImage;
				self.bounds   = (CGRect){ .origin = CGPointZero, .size = NSSizeToCGSize([newImage size]) };
			}
		}
		[CATransaction commit];
	});
}

- (void)setVerticalPlacement:(int)newPlacement
{
	if(newPlacement == _verticalPlacement)
		return;

	_verticalPlacement = newPlacement;
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		// TODO: should probably be handled by MMovieViewLayer in layout
		CGPoint newAnchorPoint = self.anchorPoint;
		switch(_verticalPlacement)
		{
			case OSD_VPOSITION_BOTTOM:
			case OSD_VPOSITION_LBOX:   newAnchorPoint.y = 0.0; break;
			case OSD_VPOSITION_CENTER: newAnchorPoint.y = 0.5; break;
			case OSD_VPOSITION_TOP:
			case OSD_VPOSITION_UBOX:   newAnchorPoint.y = 1.0; break;
			default: break;
		}
		self.anchorPoint = newAnchorPoint;
	}
	[CATransaction commit];
}

- (void)setHorizontalPlacement:(int)newPlacement
{
	if(newPlacement == _horizontalPlacement)
		return;

	_horizontalPlacement = newPlacement;
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		// TODO: should probably be handled by MMovieViewLayer in layout
		CGPoint newAnchorPoint = self.anchorPoint;
		switch(_horizontalPlacement)
		{
			case OSD_HPOSITION_LEFT:   newAnchorPoint.x = 0.0; break;
			case OSD_HPOSITION_CENTER: newAnchorPoint.x = 0.5; break;
			case OSD_HPOSITION_RIGHT:  newAnchorPoint.x = 1.0; break;
			default: break;
		}
		self.anchorPoint = newAnchorPoint;
	}
	[CATransaction commit];
}

@end

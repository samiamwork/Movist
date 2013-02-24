//
//  MMovieOSDLayer.m
//  Movist
//
//  Created by Nur Monson on 2/23/13.
//
//

#import "MMovieOSDLayer.h"
#import <Cocoa/Cocoa.h>

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

@end

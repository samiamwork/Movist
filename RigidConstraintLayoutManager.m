//
//  RigidConstraintLayoutManager.m
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import "RigidConstraintLayoutManager.h"

@implementation RigidConstraintLayoutManager
- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		[super layoutSublayersOfLayer:layer];
	}
	[CATransaction commit];
}
@end

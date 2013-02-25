//
//  MMovieOSDLayer.h
//  Movist
//
//  Created by Nur Monson on 2/23/13.
//
//

#import <QuartzCore/QuartzCore.h>

@class NSImage;

@interface MMovieOSDLayer : CALayer

- (void)setTextImage:(NSImage*)newImage;

@property (readwrite,assign,nonatomic) int horizontalPlacement;
@property (readwrite,assign,nonatomic) int verticalPlacement;
@end

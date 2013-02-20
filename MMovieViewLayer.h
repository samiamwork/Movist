//
//  MMovieViewLayer.h
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import <QuartzCore/QuartzCore.h>

@protocol MMovieLayer;

@interface MMovieViewLayer : CALayer
- (id)init;

@property (readwrite,nonatomic,assign) CALayer<MMovieLayer>* movie;
@property (readwrite,nonatomic,assign) CALayer* icon;
@end

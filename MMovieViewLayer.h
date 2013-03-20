//
//  MMovieViewLayer.h
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import <QuartzCore/QuartzCore.h>

@protocol MMovieLayer;
@class MMovieOSDLayer;

@interface MMovieViewLayer : CALayer
- (id)init;

@property (readwrite,nonatomic,assign) CALayer<MMovieLayer>* movie;
@property (readwrite,nonatomic,assign) CALayer* icon;
@property (readwrite,nonatomic,assign) MMovieOSDLayer* message;
@property (readwrite,nonatomic,assign) MMovieOSDLayer* error;
@property (readonly,nonatomic,assign)  MMovieOSDLayer* subtitle;
@property (readwrite,assign,nonatomic) BOOL subtitleEnabled;
@end

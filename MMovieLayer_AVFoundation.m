//
//  MMovieLayer_AVFoundation.m
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import "MMovieLayer_AVFoundation.h"
#import "MMovie_QuickTime.h"

@implementation MMovieLayer_AVFoundation

- (id)init
{
	if((self = [super init]))
	{
		self.videoGravity = AVLayerVideoGravityResize;
	}
	return self;
}

- (void)setMovie:(MMovie_QuickTime*)newMovie
{
	if(newMovie == _movie)
		return;
	[_movie release];
	_movie = [newMovie retain];
	self.player = [newMovie player];
}

- (MMovie*)movie
{
	return _movie;
}

@end

//
//  MMovieLayer_AVFoundation.h
//  Movist
//
//  Created by Nur Monson on 2/18/13.
//
//

#import <AVFoundation/AVFoundation.h>
#import "MMovieLayer.h"

@class MMovie_QuickTime;

@interface MMovieLayer_AVFoundation : AVPlayerLayer <MMovieLayer>
{
	MMovie_QuickTime* _movie;
}

- (void)setMovie:(MMovie_QuickTime*)newMovie;
- (MMovie*)movie;
@end

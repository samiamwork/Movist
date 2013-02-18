//
//  MMovieLayer.h
//  Movist
//
//  Created by Nur Monson on 2/16/13.
//
//

#import <Foundation/Foundation.h>

@class MMovie;

@protocol MMovieLayer <NSObject>
- (void)setMovie:(MMovie*)newMovie;
- (MMovie*)movie;
@end

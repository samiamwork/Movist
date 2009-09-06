//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//
//  This file is part of Movist.
//
//  Movist is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 3 of the License, or
//  (at your option) any later version.
//
//  Movist is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "Movist.h"

@class MMovieOSD;

@interface MSubtitleItem : NSObject
{
    NSMutableAttributedString* _string;
    NSImage* _image;
    float _beginTime;
    float _endTime;

    NSLock* _texLock;
    NSImage* _texImage;
    int _texStamp;
}

+ (id)itemWithString:(NSAttributedString*)string
           beginTime:(float)beginTime endTime:(float)endTime;
+ (id)itemWithImage:(NSImage*)image
          beginTime:(float)beginTime endTime:(float)endTime;
- (id)initWithString:(NSAttributedString*)string
           beginTime:(float)beginTime endTime:(float)endTime;
- (id)initWithImage:(NSImage*)image
           beginTime:(float)beginTime endTime:(float)endTime;

#pragma mark -
- (NSAttributedString*)string;
- (NSImage*)image;
- (float)beginTime;
- (float)endTime;
- (void)setBeginTime:(float)time;
- (void)setEndTime:(float)time;
- (void)appendString:(NSAttributedString*)string;

- (int)texStamp;
- (NSImage*)texImage;
- (NSImage*)texImage:(int)stamp;
- (NSImage*)makeTexImage:(MMovieOSD*)movieOSD stamp:(int)stamp;
- (void)releaseTexImage;

@end

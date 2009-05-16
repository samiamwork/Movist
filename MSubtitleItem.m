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

#import "MSubtitleItem.h"

#import "MMovieOSD.h"

@implementation MSubtitleItem

+ (id)itemWithString:(NSAttributedString*)string
           beginTime:(float)beginTime endTime:(float)endTime
{
    return [[[MSubtitleItem alloc]
             initWithString:string beginTime:beginTime endTime:endTime] autorelease];
}

+ (id)itemWithImage:(NSImage*)image baseWidth:(float)baseWidth
          beginTime:(float)beginTime endTime:(float)endTime
{
    return [[[MSubtitleItem alloc] initWithImage:image baseWidth:baseWidth
                                       beginTime:beginTime endTime:endTime] autorelease];
}

- (id)initWithString:(NSAttributedString*)string
           beginTime:(float)beginTime endTime:(float)endTime
{
    if (self = [super init]) {
        _string = [[NSMutableAttributedString alloc] initWithAttributedString:string];
        _beginTime = beginTime;
        _endTime = endTime;
        _texLock = [[NSLock alloc] init];
    }
    return self;
}

- (id)initWithImage:(NSImage*)image baseWidth:(float)baseWidth
          beginTime:(float)beginTime endTime:(float)endTime
{
    //TRACE(@"%s (%g ~ %g)", __PRETTY_FUNCTION__, beginTime, endTime);
    if (self = [super init]) {
        _image = [image retain];
        _imageBaseWidth = baseWidth;
        _beginTime = beginTime;
        _endTime = endTime;
        _texLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_texImage release];
    [_texLock release];
    [_string release];
    [_image release];

    [super dealloc];
}

- (NSAttributedString*)string { return _string; }
- (NSImage*)image { return _image; }
- (float)beginTime { return _beginTime; }
- (float)endTime { return _endTime; }
- (void)setBeginTime:(float)time { _beginTime = time; }
- (void)setEndTime:(float)time { _endTime = time; }
- (void)appendString:(NSAttributedString*)s { [_string appendAttributedString:s]; }

- (int)texStamp { return _texStamp; }
- (NSImage*)texImage { return _texImage; }

- (NSImage*)texImage:(int)stamp
{
    if ([_texLock tryLock]) {
        [_texLock unlock];
        return (_texStamp == stamp) ? _texImage : nil;
    }
    return nil;     // currently making or releasing tex-image
}

- (NSImage*)makeTexImage:(MMovieOSD*)movieOSD stamp:(int)stamp
{
    if (!_texImage || _texStamp != stamp) {
        [_texLock lock];
        [_texImage release];
        _texImage = (_string) ? [[movieOSD makeTexImageForString:_string] retain] :
                    (_image)  ? [[movieOSD makeTexImageForImage:_image
                                                      baseWidth:_imageBaseWidth] retain] : nil;
        _texStamp = stamp;
        //TRACE(@"%s stamp=%d: [%@~%@] %@", __PRETTY_FUNCTION__, _texStamp,
        //      NSStringFromMovieTime(_beginTime), NSStringFromMovieTime(_endTime),
        //      [_string string]);
        [_texLock unlock];
    }
    return _texImage;
}

- (void)releaseTexImage
{
    [_texLock lock];
    //TRACE(@"%s stamp=%d: [%@~%@]", __PRETTY_FUNCTION__, _texStamp,
    //      NSStringFromMovieTime(_beginTime), NSStringFromMovieTime(_endTime));
    [_texImage release], _texImage = nil;
    _texStamp = 0;
    [_texLock unlock];
}

@end

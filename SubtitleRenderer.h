//
//  Movist
//
//  Copyright 2006, 2007 Yong-Hoe Kim. All rights reserved.
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
#if defined(_USE_SUBTITLE_RENDERER)

#import "Movist.h"

@class MMovieView;
@class MSubtitleOSD;

@interface SubtitleRenderer : NSObject
{
    NSArray* _subtitles;
    MSubtitleOSD* _subtitleOSD;
    NSMutableArray* _subtitleImages;    // for MSubtitleStringImage
    float _subtitleImagesInterval;
    int _removeCount;
    float _requestedTime;
    BOOL _canRequestNewTime;
    MMovieView* _movieView;
    NSLock* _subtitlesLock;
    NSConditionLock* _conditionLock;

    NSImage* _emptyImage;

    NSAutoreleasePool* _autoreleasePool;
    BOOL _quitRequested;
}

- (id)initWithMovieView:(MMovieView*)movieView
            subtitleOSD:(MSubtitleOSD*)subtitleOSD;

- (void)setSubtitles:(NSArray*)subtitles;
- (void)clearImages:(float)requestedTime;
- (NSImage*)imageAtTime:(float)time;

@end

#endif
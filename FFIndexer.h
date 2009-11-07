//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim, Cheol Ju. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//      Cheol Ju      <moosoy@gmail.com>
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

#import "FFTrack.h"     // for FFContext

@class MMovie_FFmpeg;

@interface FFIndexer : FFContext
{
    MMovie_FFmpeg* _movie;
    AVFormatContext* _formatContext;
    AVFormatContext* _indexContext;
    NSLock* _frameReadMutex;
    int _maxFrameSize;
    float _indexingTime;
    int64_t _indexingPosition;
    BOOL _running;
    BOOL _finished;
}

- (id)initWithMovie:(MMovie_FFmpeg*)movie
      formatContext:(AVFormatContext*)formatContext
        streamIndex:(int)streamIndex
     frameReadMutex:(NSLock*)frameReadMutex;

- (void)waitForFinish;

@end

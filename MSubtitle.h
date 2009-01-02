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

@class MSubtitleItem;
@class MMovieOSD;

@interface MSubtitle : NSObject
{
    NSURL* _url;
    NSString* _type;
    NSString* _name;
    BOOL _enabled;
    NSMutableArray* _items; // of MSubtitleItem
    int _indexCache;        // for performance of -indexAtTime:

    // for render-threading
    MMovieOSD* _movieOSD;
    float _forwardRenderInterval;
    float _backwardRenderInterval;
    int _releaseBeginIndex;
    int _releaseEndIndex;
    float _lastPlayTime;
    int _seekIndex;
    int _playIndex;
    int _renderStamp;
    int _lastSeekIndex;
    int _lastPlayIndex;
    int _lastRenderStamp;
    BOOL _renderThreadRunning;
    BOOL _quitRenderThreadRequested;
    BOOL _renderingEnabled;
    NSConditionLock* _renderConditionLock;
}

+ (NSArray*)fileExtensions;

#pragma mark -
- (id)initWithURL:(NSURL*)url type:(NSString*)type;
- (NSURL*)url;
- (NSString*)type;
- (NSString*)name;
- (NSString*)summary;
- (void)setName:(NSString*)name;

- (BOOL)isEmpty;
- (float)beginTime;
- (float)endTime;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

#pragma mark loading
- (void)addString:(NSMutableAttributedString*)string time:(float)time;
- (void)addString:(NSMutableAttributedString*)string
        beginTime:(float)beginTime endTime:(float)endTime;
- (void)addImage:(NSImage*)string
        beginTime:(float)beginTime endTime:(float)endTime;
- (void)checkEndTimes;

#pragma mark seeking
- (MSubtitleItem*)itemAtTime:(float)time direction:(int)direction;
- (int)indexAtTime:(float)time direction:(int)direction;
- (float)prevSubtitleTime:(float)time;
- (float)nextSubtitleTime:(float)time;

@end

@interface MSubtitle (Render)

- (MMovieOSD*)movieOSD;
- (float)forwardRenderInterval;
- (float)backwardRenderInterval;
- (BOOL)renderingEnabled;
- (void)setMovieOSD:(MMovieOSD*)movieOSD;
- (void)setForwardRenderInterval:(float)interval;
- (void)setBackwardRenderInterval:(float)interval;
- (void)initRenderInfo;
- (void)setRenderingEnabled:(BOOL)enabled;
- (void)startRenderThread;
- (void)quitRenderThread;
- (void)setNeedsRemakeTexImages;
- (NSImage*)texImageAtTime:(float)time direction:(int)direction
                renderFlag:(BOOL*)renderFlag;

@end

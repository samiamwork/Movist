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

@interface MSubtitle : NSObject
{
    NSURL* _url;
    NSString* _type;
    NSString* _name;
    BOOL _enabled;
    NSMutableArray* _strings;   // for MSubtitleString

    // for performance of -stringAtTime:
    int _lastSearchedIndex;
    NSMutableAttributedString* _emptyString;
}

+ (NSArray*)fileExtensions;

#pragma mark -
- (id)initWithURL:(NSURL*)url type:(NSString*)type;
- (NSURL*)url;
- (NSString*)type;
- (NSString*)name;
- (void)setName:(NSString*)name;

- (BOOL)isEmpty;
- (float)beginTime;
- (float)endTime;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (void)addString:(NSMutableAttributedString*)string time:(float)time;
- (void)addString:(NSMutableAttributedString*)string
        beginTime:(float)beginTime endTime:(float)endTime;
- (void)addImage:(NSImage*)string
        beginTime:(float)beginTime endTime:(float)endTime;
- (void)checkEndTimes;

- (NSMutableAttributedString*)stringAtTime:(float)time;
- (void)clearCache;

- (float)prevSubtitleTime:(float)time;
- (float)nextSubtitleTime:(float)time;

@end

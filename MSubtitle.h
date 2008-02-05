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

#import "Movist.h"

@interface MSubtitle : NSObject
{
    NSString* _type;
    NSString* _name;
    BOOL _enabled;
    NSMutableArray* _strings;   // for MSubtitleString

    // for performance of -stringAtTime:
    int _lastIndexOfStringAtTime;
    NSMutableAttributedString* _emptyString;
}

+ (NSArray*)subtitleTypes;
+ (Class)subtitleParserClassForType:(NSString*)type;

#pragma mark -
- (id)initWithType:(NSString*)type;
- (NSString*)type;
- (NSString*)name;
- (BOOL)isEmpty;
- (float)beginTime;
- (float)endTime;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (void)setName:(NSString*)name;
- (void)addString:(NSMutableAttributedString*)string time:(float)time;
- (void)addString:(NSMutableAttributedString*)string
        beginTime:(float)beginTime endTime:(float)endTime;
- (void)checkEndTimes;
- (NSMutableAttributedString*)stringAtTime:(float)time;
- (void)clearCache;
- (float)prevSubtitleTime:(float)time;
- (float)nextSubtitleTime:(float)time;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@protocol MSubtitleParser

- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSString (MSubtitleParser)

- (NSRange)rangeOfString:(NSString*)s range:(NSRange)range;
- (NSRange)rangeOfString:(NSString*)s rangePtr:(NSRange*)range;
- (NSRange)tokenRangeForDelimiterSet:(NSCharacterSet*)delimiterSet rangePtr:(NSRange*)range;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSMutableString (MSubtitleParser)

- (void)removeLeftWhitespaces;
- (void)removeRightWhitespaces;
- (void)removeNewLineCharacters;
- (unsigned int)replaceOccurrencesOfString:(NSString*)target
                                withString:(NSString*)replacement;

@end

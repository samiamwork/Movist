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

#import "MSubtitle.h"

@interface MSubtitleString : NSObject
{
    NSMutableAttributedString* _string; // mutable for changing font-size
    float _beginTime;
    float _endTime;
}

- (id)initWithString:(NSMutableAttributedString*)s
           beginTime:(float)beginTime endTime:(float)endTime;

#pragma mark -
- (NSMutableAttributedString*)string;
- (float)beginTime;
- (float)endTime;
- (void)setString:(NSMutableAttributedString*)string;
- (void)setBeginTime:(float)time;
- (void)setEndTime:(float)time;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MSubtitleString

- (id)initWithString:(NSMutableAttributedString*)s
           beginTime:(float)beginTime endTime:(float)endTime
{
    //TRACE(@"%s \"%@\" (%g ~ %g)", __PRETTY_FUNCTION__, [s string], beginTime, endTime);
    if (self = [super init]) {
        _string = [s retain];
        _beginTime = beginTime;
        _endTime = endTime;
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_string release];
    [super dealloc];
}

- (void)setString:(NSMutableAttributedString*)string
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [string string]);
    [string retain], [_string release], _string = string;
}

- (void)setBeginTime:(float)time
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    _beginTime = time;
}

- (void)setEndTime:(float)time
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    _endTime = time;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSMutableAttributedString*)string { return _string; }
- (float)beginTime { return _beginTime; }
- (float)endTime { return _endTime; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MSubtitle

+ (NSDictionary*)subtitleTypesAndParsers
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MSubtitleParser_SMI", @"smi",
                            @"MSubtitleParser_SRT", @"srt",
                            //@"MSubtitleParser_SUB", @"sub",
                            nil];
}

+ (NSArray*)subtitleTypes
{
    return [[self subtitleTypesAndParsers] allKeys];
}

+ (Class)subtitleParserClassForType:(NSString*)type
{
    return NSClassFromString([[MSubtitle subtitleTypesAndParsers]
                                            objectForKey:[type lowercaseString]]);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (id)initWithType:(NSString*)type
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, type);
    if (self = [super init]) {
        _type = [type retain];
        _name = [NSLocalizedString(@"Unnamed", nil) retain];
        _enabled = TRUE;
        _strings = [[NSMutableArray alloc] init];

        _lastIndexOfStringAtTime = -1;     // for initial comparison
        _emptyString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_strings removeAllObjects];
    [_strings release];
    [_name release];
    [_type release];
    [_emptyString release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSString*)type { return _type; }
- (NSString*)name { return _name; }

- (void)setName:(NSString*)name
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, name);
    [name retain], [_name release], _name = name;
}

- (BOOL)isEmpty { return ([_strings count] == 0); }
- (float)beginTime { return [self isEmpty] ? 0 : [[_strings objectAtIndex:0] beginTime]; }
- (float)endTime   { return [self isEmpty] ? 0 : [[_strings lastObject] endTime]; }

- (BOOL)isEnabled { return _enabled; }
- (void)setEnabled:(BOOL)enabled { _enabled = enabled; }

- (void)addString:(NSMutableAttributedString*)string time:(float)time
{
    //TRACE(@"%s \"%@\" %g", __PRETTY_FUNCTION__, [string string], time);
    int index;
    MSubtitleString* ss;
    for (index = [_strings count] - 1; 0 <= index; index--) {
        ss = [_strings objectAtIndex:index];
        if ([ss beginTime] < time) {
            if ([ss endTime] < 0.0) {
                [ss setEndTime:time];
                //TRACE(@"add subtitle: [%g~%g] \"%@\"",
                //      [ss beginTime], [ss endTime], [[ss string] string]);
            }
            break;
        }
        else if ([ss beginTime] == time) {
            [[ss string] appendAttributedString:string];
            return;
        }
    }
    if (0 < [string length]) {
        ss = [[MSubtitleString alloc] initWithString:string
                                            beginTime:time endTime:-1.0];
        [_strings insertObject:ss atIndex:index + 1];
    }
}

- (void)addString:(NSMutableAttributedString*)string
        beginTime:(float)beginTime endTime:(float)endTime
{
    //TRACE(@"%s \"%@\" %g", __PRETTY_FUNCTION__, [string string], time);
    int index;
    MSubtitleString* ss;
    for (index = [_strings count] - 1; 0 <= index; index--) {
        ss = [_strings objectAtIndex:index];
        if ([ss beginTime] <= beginTime) {
            break;
        }
    }
    if (index < 0) {
        if (0 < [_strings count]) {
            ss = [_strings objectAtIndex:0];
            if ([ss beginTime] < endTime) {
                NSAttributedString* as = [[NSAttributedString alloc] initWithString:@"\n"];
                [[ss string] appendAttributedString:[as autorelease]];
                [[ss string] appendAttributedString:string];
                endTime = [ss beginTime];
            }
        }
        ss = [[MSubtitleString alloc] initWithString:string
                                           beginTime:beginTime endTime:endTime];
        [_strings insertObject:ss atIndex:0];
    }
    else if ([ss endTime] <= beginTime) {
        ss = [[MSubtitleString alloc] initWithString:string
                                           beginTime:beginTime endTime:endTime];
        [_strings insertObject:ss atIndex:index + 1];
    }
    else if ([ss beginTime] == beginTime) {
        if (endTime == [ss endTime]) {
            NSAttributedString* as = [[NSAttributedString alloc] initWithString:@"\n"];
            [[ss string] appendAttributedString:[as autorelease]];
            [[ss string] appendAttributedString:string];
        }
        else if (endTime < [ss endTime]) {
            [ss setBeginTime:endTime];

            NSMutableAttributedString* mas = [[ss string] mutableCopy];
            NSAttributedString* as = [[NSAttributedString alloc] initWithString:@"\n"];
            [mas appendAttributedString:[as autorelease]];
            [mas appendAttributedString:string];
            ss = [[MSubtitleString alloc] initWithString:mas
                                               beginTime:beginTime endTime:endTime];
            [_strings insertObject:ss atIndex:index];
        }
        else {
            NSAttributedString* as = [[NSAttributedString alloc] initWithString:@"\n"];
            [[ss string] appendAttributedString:[as autorelease]];
            [[ss string] appendAttributedString:string];
            [self addString:string beginTime:[ss endTime] endTime:endTime];
        }
    }
    else if ([ss beginTime] < beginTime) {
        float bt = [ss beginTime];
        [ss setBeginTime:beginTime];
        NSMutableAttributedString* mas = [[ss string] copy];
        ss = [[MSubtitleString alloc] initWithString:mas
                                           beginTime:bt endTime:beginTime];
        [_strings insertObject:ss atIndex:index];
        [self addString:string beginTime:beginTime endTime:endTime];
    }
}

- (NSMutableAttributedString*)stringAtTime:(float)time
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    int index = (_lastIndexOfStringAtTime < 0) ? 0 : _lastIndexOfStringAtTime;
    if (index < 0 || [_strings count] <= index) {
        //TRACE(@"%s(\"%@\")[%.03f]: <none>", __PRETTY_FUNCTION__, _name, time);
        _lastIndexOfStringAtTime = -1;
        return nil;
    }

    MSubtitleString* ss = (MSubtitleString*)[_strings objectAtIndex:index];
    if (time < [ss beginTime]) {
        while (0 < index--) {         // find in previous strings
            ss = (MSubtitleString*)[_strings objectAtIndex:index];
            if ([ss beginTime] <= time) {
                break;
            }
        }
        if (0 <= index && time < [ss endTime]) {
            //TRACE(@"%s(\"%@\")[%.03f:%d=>%d]:\"%@\"", __PRETTY_FUNCTION__, _name,
            //      time, _lastIndexOfStringAtTime, index, [[ss string] string]);
            _lastIndexOfStringAtTime = index;
            return [ss string];
        }
    }
    else if ([ss endTime] < time) {
        int maxIndex = [_strings count] - 1;
        while (index++ < maxIndex) {  // find in next strings
            ss = (MSubtitleString*)[_strings objectAtIndex:index];
            if (time < [ss endTime]) {
                break;
            }
        }
        if (index <= maxIndex && [ss beginTime] <= time) {
            //TRACE(@"%s(\"%@\")[%.03f:%d=>%d]:\"%@\"", __PRETTY_FUNCTION__, _name,
            //      time, _lastIndexOfStringAtTime, index, [[ss string] string]);
            _lastIndexOfStringAtTime = index;
            return [ss string];
        }
    }
    else {
        //TRACE(@"%s(\"%@\")[%.03f:%d=>%d]:\"%@\"", __PRETTY_FUNCTION__, _name,
        //      time, _lastIndexOfStringAtTime, index, [[ss string] string]);
        _lastIndexOfStringAtTime = index;
        return [ss string];
    }

    // string not found
    //TRACE(@"%s(\"%@\")[%.03f]: <none>", __PRETTY_FUNCTION__, _name, time);
    _lastIndexOfStringAtTime = -1;
    return _emptyString;
}

- (void)clearCache
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _lastIndexOfStringAtTime = -1;
}

////////////////////////////////////////////////////////////////////////////////

- (float)nearestSubtitleTime:(float)time nextNeighbor:(BOOL)nextNeighbor
{
    MSubtitleString* s;
    int i, count = [_strings count];
    for (i = 0; i < count; i++) {
        s = [_strings objectAtIndex:i];
        if (time < [s beginTime]) {
            if (nextNeighbor) {
                // i
            }
            else if (0 < i) {
                i--;
            }
            break;
        }
        else if (time < [s endTime]) {
            if (nextNeighbor) {
                if (i < count - 1) {
                    i++;
                }
            }
            else if (0 < i) {
                i--;
            }
            break;
        }
    }
    s = (i < count) ? [_strings objectAtIndex:i] : [_strings lastObject];
    return [s beginTime] + 0.1;   // add margin to ensure to display subtitle
}

- (float)prevSubtitleTime:(float)time
{
    return [self nearestSubtitleTime:time nextNeighbor:FALSE];
}

- (float)nextSubtitleTime:(float)time
{
    return [self nearestSubtitleTime:time nextNeighbor:TRUE];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSString (MSubtitleParser)

#define rangeOfStringOption (NSCaseInsensitiveSearch | NSLiteralSearch)

- (NSRange)rangeOfString:(NSString*)s range:(NSRange)range
{
    //TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, NSStringFromRange(range));
    return [self rangeOfString:s options:rangeOfStringOption range:range];
}

- (NSRange)rangeOfString:(NSString*)s rangePtr:(NSRange*)range
{
    //TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, s, NSStringFromRange(*range));
    NSRange r = [self rangeOfString:s range:*range];
    if (r.location != NSNotFound) {
        int n = NSMaxRange(r) - range->location;
        range->location += n;
        range->length   -= n;
    }
    return r;
}

- (NSRange)tokenRangeForDelimiterSet:(NSCharacterSet*)delimiterSet rangePtr:(NSRange*)range
{
    //TRACE(@"%s %@ (%@)", __PRETTY_FUNCTION__, delimiterSet, NSStringFromRange(*range));
    NSRange result;
    int i = range->location, end = NSMaxRange(*range);
    while (i < end && [delimiterSet characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    result.location = i;
    while (i < end && ![delimiterSet characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    result.length = i - result.location;

    int n = NSMaxRange(result) - range->location;
    range->location += n;
    range->length   -= n;

    return result;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSMutableString (MSubtitleParser)

- (void)removeLeftWhitespaces
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSCharacterSet* set = [NSCharacterSet whitespaceCharacterSet];

    int i, length = [self length];
    for (i = 0; i < length; i++) {
        if (![set characterIsMember:[self characterAtIndex:i]]) {
            if (0 < i) {
                [self deleteCharactersInRange:NSMakeRange(0, i)];
            }
            break;
        }
    }
}

- (void)removeRightWhitespaces
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSCharacterSet* set = [NSCharacterSet whitespaceCharacterSet];

    int i, length = [self length];
    for (i = length - 1; 0 <= i; i--) {
        if (![set characterIsMember:[self characterAtIndex:i]]) {
            if (i < length - 1) {
                [self deleteCharactersInRange:NSMakeRange(i + 1, length - (i + 1))];
            }
            break;
        }
    }
}

- (void)removeNewLineCharacters
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self replaceOccurrencesOfString:@"\r" withString:@""
                             options:0 range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"\n" withString:@""
                             options:0 range:NSMakeRange(0, [self length])];
}

- (unsigned int)replaceOccurrencesOfString:(NSString*)target
                                withString:(NSString*)replacement
{
    //TRACE(@"%s \"%@\" with \"%@\"", __PRETTY_FUNCTION__, target, replacement);
    return [self replaceOccurrencesOfString:target
                                 withString:replacement
                                    options:rangeOfStringOption
                                      range:NSMakeRange(0, [self length])];
}

@end

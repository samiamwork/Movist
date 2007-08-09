//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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

@class MSubtitleParser_SMI;
//@class MSubtitleParser_SRT;
//@class MSubtitleParser_SUB;

@implementation MSubtitle

+ (NSDictionary*)subtitleTypesAndParsers
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                            [MSubtitleParser_SMI class], @"smi",
                            //[MSubtitleParser_SRT class], @"srt",
                            //[MSubtitleParser_SUB class], @"sub",
                            nil];
}

+ (NSArray*)subtitleTypes
{
    return [[self subtitleTypesAndParsers] allKeys];
}

+ (Class)subtitleParserClassForType:(NSString*)type
{
    return [[MSubtitle subtitleTypesAndParsers] objectForKey:[type lowercaseString]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (id)initWithType:(NSString*)type
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, type);
    if (self = [super init]) {
        _type = [type retain];
        _name = [NSLocalizedString(@"no name", nil) retain];
        _enabled = TRUE;
        _strings = [[NSMutableArray alloc] init];

        _lastLoadedIndex = -1;     // for initial comparison
        _emptyString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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
    TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, name);
    [name retain], [_name release], _name = name;
}

- (BOOL)isEmpty { return ([_strings count] == 0); }
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

- (NSMutableAttributedString*)nextString:(float)time
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, time);
    int index = (_lastLoadedIndex < 0) ? 0 : _lastLoadedIndex;
    if (index < 0 || [_strings count] <= index) {
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
            TRACE(@"next subtitle:(\"%@\")[%.03f:%d=>%d]:\"%@\"", _name,
                  time, _lastLoadedIndex, index, [[ss string] string]);
            _lastLoadedString = [ss string];
            _lastLoadedIndex = index;
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
            TRACE(@"next subtitle:(\"%@\")[%.03f:%d=>%d]:\"%@\"", _name,
                  time, _lastLoadedIndex, index, [[ss string] string]);
            _lastLoadedString = [ss string];
            _lastLoadedIndex = index;
            return [ss string];
        }
    }
    else {
        if (_lastLoadedString != [ss string]) {
            TRACE(@"next subtitle:(\"%@\")[%.03f:%d=>%d]:\"%@\"", _name,
                  time, _lastLoadedIndex, index, [[ss string] string]);
            _lastLoadedString = [ss string];
            _lastLoadedIndex = index;
            return [ss string];
        }
        // _lastLoadedString is continued...
        return nil;
    }
    
    // string not found
    if (_lastLoadedString != _emptyString) {
        TRACE(@"next subtitle:(\"%@\")[%.03f]: <none>", _name, time);
        _lastLoadedString = _emptyString;
        return _emptyString;
    }
    // <none> is continued...
    return nil;
}

- (void)clearCache
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _lastLoadedIndex = -1;
    _lastLoadedString = nil;
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

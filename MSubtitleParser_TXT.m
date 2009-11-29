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

// based on MSubtitleParser_SRT for SubRip and
// added patch of macnow@hoax.pl for MicroDVD, MPL2 and TMPlayer.

#import "MSubtitleParser_TXT.h"
#import "CSRegex.h"

enum {
    TAG_NONE            = -1,
    TAG_UNKNOWN         = 0,
    
    // contents tags
    TAG_FONT_OPEN,      TAG_FONT_CLOSE,
    TAG_I_OPEN,         TAG_I_CLOSE,
    TAG_B_OPEN,         TAG_B_CLOSE,
};

typedef struct _TXTTag {
    int type;          // TAG_*
    NSString* attr;
    NSRange range;
} TXTTag;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSString (MSubtitleParser_TXT)

- (TXTTag)txtTagWithRangePtr:(NSRange*)range delimSet:(NSCharacterSet*)delimSet;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSColor (MSubtitleParser_SMI)

+ (NSColor*)colorFromSMIString:(NSString*)string;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MSubtitleParser_TXT

- (BOOL)isIndexString:(NSString*)s
{
    int i;
    unichar c;
    for (i = 0; i < [s length]; i++) {
        c = [s characterAtIndex:i];
        if (c < '0' || '9' < c) {
            return FALSE;
        }
    }
    return TRUE;
}

- (void)parse_TIMES:(NSString*)s
          beginTime:(float*)beginTime endTime:(float*)endTime
{
    if ([s length] < 29 ||
        [s characterAtIndex:2] != ':' ||
        [s characterAtIndex:5] != ':' ||
        [s characterAtIndex:8] != ',') {
        return;
    }

    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, s);
    NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:@":, "];
    NSRange cr = NSMakeRange(0, [s length]);

    // begin time
    NSRange r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    int hour = [[s substringWithRange:r] intValue];
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    int min = [[s substringWithRange:r] intValue];
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    int sec = [[s substringWithRange:r] intValue];
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    int msec = [[s substringWithRange:r] intValue];
    *beginTime = (hour * 60 * 60) + (min * 60) + (sec) + (msec / 1000.0);

    // "-->"
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];

    // end time
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    hour = [[s substringWithRange:r] intValue];
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    min = [[s substringWithRange:r] intValue];
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    sec = [[s substringWithRange:r] intValue];
    r = [s tokenRangeForDelimiterSet:set rangePtr:&cr];
    msec = [[s substringWithRange:r] intValue];
    *endTime = (hour * 60 * 60) + (min * 60) + (sec) + (msec / 1000.0);
}

- (NSColor*)parse_FONT:(NSString*)attr
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, attr);
    NSRange ar = NSMakeRange(0, [attr length]);
    NSRange tr = [attr tokenRangeForDelimiterSet:_fontDelimSet rangePtr:&ar];
    if (![attr compare:@"COLOR" options:NSCaseInsensitiveSearch range:tr]) {
        tr = [attr tokenRangeForDelimiterSet:_fontDelimSet rangePtr:&ar];
        return [NSColor colorFromSMIString:[attr substringWithRange:tr]];
    }
    return nil;
}

- (NSMutableAttributedString*)parseSubtitleString:(NSString*)string
{
    //TRACE(@"%s \"%@\")", __PRETTY_FUNCTION__, string);

    // this method can be called independently for parsing embedded subtitle.

    NSMutableString* ms = [NSMutableString stringWithString:string];
    [ms removeRightWhitespaces];

    // apply text-attributes : italic, bold, ...
    NSMutableAttributedString* mas = [[[NSMutableAttributedString alloc]
                                initWithString:@"" attributes:nil] autorelease];
    if (0 < [ms length]) {
        NSCharacterSet* set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        TXTTag tag;
        NSColor* color = nil;
        BOOL italic = FALSE, bold = FALSE;
        NSRange r, range = NSMakeRange(0, [ms length]);
        if (_replacePipeCharacterWithNewLine) {
            [ms replaceOccurrencesOfString:@"|" withString:@"\n"];
        }
        while (0 < range.length) {
            r.location = range.location;
            tag = [ms txtTagWithRangePtr:&range delimSet:set];
            if (TAG_UNKNOWN < tag.type) {
                r.length = tag.range.location - r.location;
                if (0 < r.length) {
                    [self mutableAttributedString:mas
                                     appendString:[ms substringWithRange:r]
                                        withColor:color italic:italic bold:bold];
                }
                r.location = NSMaxRange(tag.range);
                switch (tag.type) {
                    case TAG_FONT_OPEN  : color = [self parse_FONT:tag.attr];   break;
                    case TAG_FONT_CLOSE : color = nil;                          break;
                    case TAG_I_OPEN     : italic = TRUE;                        break;
                    case TAG_I_CLOSE    : italic = FALSE;                       break;
                    case TAG_B_OPEN     : bold = TRUE;                          break;
                    case TAG_B_CLOSE    : bold = FALSE;                         break;
                }
            }
        }
        r.length = [ms length] - r.location;
        if (0 < r.length) {
            [self mutableAttributedString:mas
                             appendString:[ms substringWithRange:r]
                                withColor:color italic:italic bold:bold];
        }
        [mas fixAttributesInRange:NSMakeRange(0, [mas length])];
    }
    return mas;
}

- (void)parseSubtitleString:(NSString*)string
                  beginTime:(float)beginTime endTime:(float)endTime
{
    MSubtitle* subtitle = [_subtitles objectAtIndex:0];
    [subtitle addString:[self parseSubtitleString:string]
              beginTime:beginTime endTime:endTime];
}

- (void)readyWithOptions:(NSDictionary*)options
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableCharacterSet* mset;
    mset = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    [mset addCharactersInString:@"{}:;='\""];
    _fontDelimSet = [mset autorelease];

    // for MicroDVD
    id obj = [options objectForKey:MSubtitleParserOptionKey_movieFps];
    if (obj) {
        _fps = [obj floatValue];
        TRACE(@"Movie FPS: %f", _fps);
    }
}

- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _source = [[string retain] autorelease];
    _sourceRange = NSMakeRange(0, [_source length]);
    _subtitles = [NSMutableArray arrayWithCapacity:1];
    [self readyWithOptions:options];

    MSubtitle* subtitle = [[[MSubtitle alloc] initWithURL:_subtitleURL] autorelease];
    [subtitle setType:@"TXT"];
    [subtitle setTrackName:NSLocalizedString(@"External Subtitle", nil)];
    [subtitle setEmbedded:FALSE];
    [_subtitles addObject:subtitle];

    NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];

    SEL parseTokenStringSelector;
    if ([_source matchedByPattern:@"^{"]) {
        parseTokenStringSelector = @selector(parseTokenString_MicroDVD:);
        _replacePipeCharacterWithNewLine = TRUE;
    }
    else if ([_source matchedByPattern:@"^\\["]) {
        parseTokenStringSelector = @selector(parseTokenString_MPL2:);
        _replacePipeCharacterWithNewLine = TRUE;
    }
    else if ([_source matchedByPattern:@"^[0-9]"]) {
        NSRange r = [_source tokenRangeForDelimiterSet:set rangePtr:&_sourceRange];
        if ([self isIndexString:[_source substringWithRange:r]]) {
            parseTokenStringSelector = @selector(parseTokenString_SRT:);
            _replacePipeCharacterWithNewLine = FALSE;
        }
        else {
            parseTokenStringSelector = @selector(parseTokenString_TMPlayer:);
            _replacePipeCharacterWithNewLine = TRUE;
        }
    }
    else {
        return nil;
    }
    _ms = nil;
    _beginTime = _endTime = -1;

    NSRange r;
    NSString* s;
    while (0 < _sourceRange.length) {
        r = [_source tokenRangeForDelimiterSet:set rangePtr:&_sourceRange];
        if (r.length != 0) {
            s = [_source substringWithRange:r];
            [self performSelector:parseTokenStringSelector withObject:s];
        }
    }
    if (0 <= _beginTime && _ms) {
        [self parseSubtitleString:_ms beginTime:_beginTime endTime:_endTime];
    }

    // remove empty subtitle if exist and
    // make complete not-ended-string if exist.
    int i;
    for (i = [_subtitles count] - 1; 0 <= i; i--) {
        subtitle = [_subtitles objectAtIndex:i];
        if ([subtitle isEmpty]) {
            [_subtitles removeObjectAtIndex:i];
        }
        else {
            [subtitle checkEndTimes];
        }
    }

    return _subtitles;
}

////////////////////////////////////////////////////////////////////////////////

- (void)parseTokenString_MicroDVD:(NSString*)string
{
    NSArray* sub = [string substringsCapturedByPattern:@"{([0-9]+)}{([0-9]+)}(.*)"];
    _beginTime = [[sub objectAtIndex:1] floatValue] / _fps;
    _endTime   = [[sub objectAtIndex:2] floatValue] / _fps;
    _ms = [NSMutableString stringWithString:[sub objectAtIndex:3]];
    [self parseSubtitleString:_ms beginTime:_beginTime endTime:_endTime];
}

- (void)parseTokenString_MPL2:(NSString*)string
{
    NSArray* sub = [string substringsCapturedByPattern:@"\\[([0-9]+)\\]\\[([0-9]+)\\](.*)"];
    _beginTime = [[sub objectAtIndex:1] floatValue] / 10.0f;
    _endTime   = [[sub objectAtIndex:2] floatValue] / 10.0f;
    _ms = [NSMutableString stringWithString:[sub objectAtIndex:3]];
    [self parseSubtitleString:_ms beginTime:_beginTime endTime:_endTime];
}

- (void)parseTokenString_TMPlayer:(NSString*)string
{
    NSArray* sub = [string substringsCapturedByPattern:@"([0-9]+)\\:([0-9]+)\\:([0-9]+).(.*)"];
    int hour = [[sub objectAtIndex:1] intValue];
    int min  = [[sub objectAtIndex:2] intValue];
    int sec  = [[sub objectAtIndex:3] intValue];

    _beginTime = (hour * 60 * 60) + (min * 60) + (sec);
    _endTime = -1;
    _ms = [NSMutableString stringWithString:[sub objectAtIndex:4]];
    [self parseSubtitleString:_ms beginTime:_beginTime endTime:_endTime];
}

- (void)parseTokenString_SRT:(NSString*)string
{
    // ignore index...
    if (_beginTime < 0) {
        [self parse_TIMES:string beginTime:&_beginTime endTime:&_endTime];
    }
    else {
        if (![self isIndexString:string]) {
            if (!_ms) {
                _ms = [NSMutableString stringWithString:string];
            }
            else {
                [_ms appendString:@"\n"];
                [_ms appendString:string];
            }
        }
        else {
            if (_ms) {
                [self parseSubtitleString:_ms beginTime:_beginTime endTime:_endTime];
                _ms = nil;
            }
            _beginTime = -1;
        }
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSString (MSubtitleParser_TXT)

TXTTag MMakeTXTTag(int type, int location, int length, NSString* attr)
{
    TXTTag tag;
    tag.type = type;
    tag.range.location = location;
    tag.range.length = length;
    tag.attr = attr;
    return tag;
}

- (TXTTag)txtTagWithRangePtr:(NSRange*)range delimSet:(NSCharacterSet*)delimSet
{
    //TRACE(@"%s %@ (%@)", __PRETTY_FUNCTION__, NSStringFromRange(*range), delimSet);
    NSRange or = [self rangeOfString:@"<" rangePtr:range];
    if (or.location == NSNotFound) {
        range->location = [self length];
        range->length = 0;
        return MMakeTXTTag(TAG_NONE, NSNotFound, 0, nil);
    }

    NSRange cr = [self rangeOfString:@">" rangePtr:range];
    if (cr.location == NSNotFound) {
        range->location = [self length];
        range->length = 0;
        return MMakeTXTTag(TAG_NONE, NSNotFound, 0, nil);
    }

    // find tag name
    int i, c = ([self characterAtIndex:or.location + 1] == '/') ? 1 : 0;
    NSRange ar;
    ar.location = or.location + 1 + c;
    ar.length = NSMaxRange(cr) - ar.location - 1;
    NSRange nr = [self tokenRangeForDelimiterSet:delimSet rangePtr:&ar];

    static const struct {
        NSString* name;
        int type[2];
    } nameType[] = {
        { @"FONT",  TAG_FONT_OPEN,  TAG_FONT_CLOSE },
        { @"I",     TAG_I_OPEN,     TAG_I_CLOSE },
        { @"B",     TAG_B_OPEN,     TAG_B_CLOSE },
    };
    for (i = 0; i < sizeof(nameType) / sizeof(nameType[0]); i++) {
        if (![self compare:nameType[i].name options:NSCaseInsensitiveSearch range:nr]) {
            return MMakeTXTTag(nameType[i].type[c],
                               or.location, NSMaxRange(cr) - or.location,
                               (0 < ar.length) ? [self substringWithRange:ar] : nil);
        }
    }
    return MMakeTXTTag(TAG_UNKNOWN, NSNotFound, 0, nil);
}

@end

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

#import "MSubtitleParser_SSA.h"

enum {
    TAG_NONE            = -1,
    TAG_UNKNOWN         = 0,

    // contents tags
    TAG_B_OPEN,     TAG_B_CLOSE,
    TAG_I_OPEN,     TAG_I_CLOSE,
    TAG_C,
    TAG_R,
};

typedef struct _SSATag {
    int type;          // TAG_*
    NSString* attr;
    NSRange range;
} SSATag;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSString (MSubtitleParser_SSA)

- (SSATag)ssaTagWithRangePtr:(NSRange*)range delimSet:(NSCharacterSet*)delimSet;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSColor (MSubtitleParser_SSA)

+ (NSColor*)colorFromSSAString:(NSString*)string;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MSubtitleParser_SSA

NSString* const STYLE_KEY_NAME      = @"Name";
NSString* const STYLE_KEY_COLOR     = @"PrimaryColour";
NSString* const STYLE_KEY_ITALIC    = @"Italic";
NSString* const STYLE_KEY_BOLD      = @"Bold";

#if defined(DEBUG)
//#define _TRACE_TEXT
#endif

- (id)initWithURL:(NSURL*)subtitleURL
{
    if (self = [super initWithURL:subtitleURL]) {
        _styles = [[NSMutableDictionary alloc] initWithCapacity:1];
        _defaultColor = nil;
        _defaultBold = FALSE;
        _defaultItalic = FALSE;
    }
    return self;
}

- (NSMutableArray*)formatForTitle:(NSString*)title
                           styles:(NSString*)styles rangePtr:(NSRange*)rangePtr
{
    NSRange r = [styles rangeOfString:title rangePtr:rangePtr];
    if (r.location == NSNotFound) {
        return nil;
    }

    NSMutableString* ms;
    NSRange sr = [styles rangeOfString:@"\n" rangePtr:rangePtr];
    sr.length = sr.location - NSMaxRange(r) - 1;
    sr.location = NSMaxRange(r);
    NSString* s = [styles substringWithRange:sr];
    NSArray* as = [s componentsSeparatedByString:@","];
    NSMutableArray* format = [NSMutableArray arrayWithCapacity:[as count]];
    NSEnumerator* e = [as objectEnumerator];
    while (s = [e nextObject]) {
        ms = [NSMutableString stringWithString:s];
        [ms removeLeftWhitespaces];
        [ms removeRightWhitespaces];
        [format addObject:ms];
    }
    return format;
}

- (void)setStyles:(NSString*)string forSubtitleNumber:(int)subtitleNumber
{
    TRACE(@"[%d]styles=%@", subtitleNumber, string);
    NSRange range = NSMakeRange(0, [string length]);
    NSMutableArray* format = [self formatForTitle:@"Format:" styles:string rangePtr:&range];
    if (!format) {
        range.location = [string length];
        range.length = 0;
        return;
    }

    NSMutableDictionary* styles = [NSMutableDictionary dictionaryWithCapacity:2];

    int i;
    NSColor* color;
    NSMutableArray* as;
    NSMutableDictionary* style;
    int nameIndex = [format indexOfObject:STYLE_KEY_NAME];
    int colorIndex = [format indexOfObject:STYLE_KEY_COLOR];
    while (0 < range.length) {
        as = [self formatForTitle:@"Style:" styles:string rangePtr:&range];
        if (!as) {
            range.location = [string length];
            range.length = 0;
            continue;
        }
        color = [NSColor colorFromSSAString:[as objectAtIndex:colorIndex]];
        [as replaceObjectAtIndex:colorIndex withObject:color];

        style = [NSMutableDictionary dictionaryWithCapacity:[as count]];
        for (i = 0; i < [as count]; i++) {
            [style setObject:[as objectAtIndex:i] forKey:[format objectAtIndex:i]];
        }
#if defined(_TRACE_TEXT)
        TRACE(@"[%d]style={ name=\"%@\", color=%@, bold=%@, italic=%@ }",
              subtitleNumber,
              [style objectForKey:STYLE_KEY_NAME],
              [style objectForKey:STYLE_KEY_COLOR],
              [style objectForKey:STYLE_KEY_BOLD],
              [style objectForKey:STYLE_KEY_ITALIC]);
#endif
        [styles setObject:style forKey:[as objectAtIndex:nameIndex]];
    }
    
    [_styles setObject:styles forKey:[NSNumber numberWithInt:subtitleNumber]];
}

- (NSString*)eventStringWithString:(NSString*)string rangePtr:(NSRange*)rangePtr
{
    NSRange r = [string rangeOfString:@"," options:0 range:*rangePtr];
    if (r.location == NSNotFound) {
        return [string substringWithRange:*rangePtr];
    }

    // make r to range of eventString
    r.length = r.location - rangePtr->location;
    r.location = rangePtr->location;

    rangePtr->location += r.length + 1;
    rangePtr->length -= r.length + 1;
    return [string substringWithRange:r];
}

- (NSMutableAttributedString*)styleAppliedString:(NSString*)s
{
    NSMutableString* ms = [NSMutableString stringWithString:s];
    [ms replaceOccurrencesOfString:@"\\n" withString:@"\n"];
    [ms replaceOccurrencesOfString:@"\\N" withString:@"\n"];
    [ms replaceOccurrencesOfString:@"\\h" withString:@" "];

    NSMutableAttributedString* mas = [[[NSMutableAttributedString alloc]
                                       initWithString:@"" attributes:nil] autorelease];
    if (0 < [ms length]) {
        SSATag tag;
        NSColor* color = _defaultColor;
        BOOL italic = _defaultItalic;
        BOOL bold = _defaultBold;
        NSCharacterSet* delimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSRange r, range = NSMakeRange(0, [ms length]);
        while (0 < range.length) {
            r.location = range.location;
            tag = [ms ssaTagWithRangePtr:&range delimSet:delimSet];
            if (tag.type != TAG_NONE) {
                if (tag.range.location != NSNotFound) {
                    r.length = tag.range.location - r.location;
                    if (0 < r.length) {
                        [self mutableAttributedString:mas
                                         appendString:[ms substringWithRange:r]
                                            withColor:color italic:italic bold:bold];
                    }
                }
                switch (tag.type) {
                    case TAG_B_OPEN  : bold = TRUE;      break;
                    case TAG_B_CLOSE : bold = FALSE;     break;
                    case TAG_I_OPEN  : italic = TRUE;    break;
                    case TAG_I_CLOSE : italic = FALSE;   break;
                    case TAG_C :
                        color = [NSColor colorFromSSAString:tag.attr];
                        break;
                    case TAG_R :
                        bold = _defaultBold;
                        italic = _defaultItalic;
                        color = _defaultColor;
                        break;
                }
            }
        }
        if (tag.type == TAG_NONE) {
            r.length = [ms length] - r.location;
            if (0 < r.length) {
                [self mutableAttributedString:mas
                                 appendString:[ms substringWithRange:r]
                                    withColor:color italic:italic bold:bold];
            }
        }
        [mas fixAttributesInRange:NSMakeRange(0, [mas length])];
    }
    return mas;
}

- (NSMutableAttributedString*)parseSubtitleString_MKV:(NSString*)string
                                    forSubtitleNumber:(int)subtitleNumber
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);

    // this method is called independently for parsing embedded subtitle in MKV.
    // string is formatted with following predefined order:
    //   ReadOrder, Layer, Style, Name, MarginL, MarginR, MarginV, Effect, Text.

    // apply text-attributes : italic, bold, ...
    NSRange range = NSMakeRange(0, [string length]);
    /*NSString* readOrder =*/ [self eventStringWithString:string rangePtr:&range];
    /*NSString* layer =*/ [self eventStringWithString:string rangePtr:&range];
    NSString* style = [self eventStringWithString:string rangePtr:&range];
    /*NSString* name =*/ [self eventStringWithString:string rangePtr:&range];
    /*NSString* marginL =*/ [self eventStringWithString:string rangePtr:&range];
    /*NSString* marginR =*/ [self eventStringWithString:string rangePtr:&range];
    /*NSString* marginV =*/ [self eventStringWithString:string rangePtr:&range];
    /*NSString* effect =*/ [self eventStringWithString:string rangePtr:&range];
    NSString* text = [string substringWithRange:range];

    NSNumber* number = [NSNumber numberWithInt:subtitleNumber];
    NSDictionary* dict = [[_styles objectForKey:number] objectForKey:style];
    if (!dict) {
        dict = [[_styles objectForKey:number] objectForKey:@"Default"];
    }
    if (!dict) {
        dict = [[_styles objectForKey:number] objectForKey:@"*Default"];
    }
    _defaultColor = [dict objectForKey:STYLE_KEY_COLOR];
    _defaultBold = [[dict objectForKey:STYLE_KEY_BOLD] isEqualToString:@"1"];
    _defaultItalic = [[dict objectForKey:STYLE_KEY_ITALIC] isEqualToString:@"1"];

#if defined(_TRACE_TEXT)
    if ([[dict objectForKey:STYLE_KEY_NAME] isEqualToString:style]) {
        TRACE(@"[%2d]style=\"%@\":{ color=%@, bold=%@, italic=%@ }, text=\"%@\"",
              subtitleNumber, style,
              [dict objectForKey:STYLE_KEY_COLOR],
              [dict objectForKey:STYLE_KEY_BOLD],
              [dict objectForKey:STYLE_KEY_ITALIC],
              text);
    }
    else {
        TRACE(@"[%d]style=\"%@\" => \"%@\":{ color=%@, bold=%@, italic=%@ } text=\"%@\"",
              subtitleNumber, style, [dict objectForKey:STYLE_KEY_NAME],
              [dict objectForKey:STYLE_KEY_COLOR],
              [dict objectForKey:STYLE_KEY_BOLD],
              [dict objectForKey:STYLE_KEY_ITALIC],
              text);
    }
#endif

    NSMutableAttributedString* mas = [self styleAppliedString:text];
    [mas fixAttributesInRange:NSMakeRange(0, [mas length])];
    return mas;
}
/*
- (void)parseSubtitleString:(NSString*)string
                  beginTime:(float)beginTime endTime:(float)endTime
{
    MSubtitle* subtitle = [_subtitles objectAtIndex:0];
    [subtitle addString:[self parseSubtitleString:string]
              beginTime:beginTime endTime:endTime];
}
*/
- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _source = [[string retain] autorelease];
    _sourceRange = NSMakeRange(0, [_source length]);
    _subtitles = [NSMutableArray arrayWithCapacity:1];
    if (options) {
    }

    /*
    MSubtitle* subtitle = [[[MSubtitle alloc] initWithURL:_subtitleURL] autorelease];
    [subtitle setType:@"SSA"];
    [subtitle setTrackName:NSLocalizedString(@"External Subtitle", nil)];
    [subtitle setEmbedded:FALSE];
    [_subtitles addObject:subtitle];

    NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];

    NSRange r;
    NSString* s;
    NSMutableString* ms = nil;
    float beginTime = -1, endTime;
    while (0 < _sourceRange.length) {
        r = [_source tokenRangeForDelimiterSet:set rangePtr:&_sourceRange];
        if (r.length != 0) {
            s = [_source substringWithRange:r];
            // ignore index...
            if (beginTime < 0) {
                [self parse_TIMES:s beginTime:&beginTime endTime:&endTime];
            }
            else {
                if (![self isIndexString:s]) {
                    if (!ms) {
                        ms = [NSMutableString stringWithString:s];
                    }
                    else {
                        [ms appendString:@"\n"];
                        [ms appendString:s];
                    }
                }
                else {
                    if (ms) {
                        [self parseSubtitleString:ms beginTime:beginTime endTime:endTime];
                        ms = nil;
                    }
                    beginTime = -1;
                }
            }
        }
    }
    if (0 <= beginTime && ms) {
        [self parseSubtitleString:ms beginTime:beginTime endTime:endTime];
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
     */
    return _subtitles;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSString (MSubtitleParser_SSA)

SSATag MMakeSSATag(int type, int location, int length, NSString* attr)
{
    SSATag tag;
    tag.type = type;
    tag.range.location = location;
    tag.range.length = length;
    tag.attr = attr;
    return tag;
}

- (SSATag)ssaTagWithRangePtr:(NSRange*)range delimSet:(NSCharacterSet*)delimSet
{
    //TRACE(@"%s %@ (%@)", __PRETTY_FUNCTION__, NSStringFromRange(*range), delimSet);
    NSRange or = [self rangeOfString:@"{\\" rangePtr:range];
    if (or.location == NSNotFound) {
        range->location = [self length];
        range->length = 0;
        return MMakeSSATag(TAG_NONE, NSNotFound, 0, nil);
    }

    NSRange cr = [self rangeOfString:@"}" rangePtr:range];
    if (cr.location == NSNotFound) {
        return MMakeSSATag(TAG_UNKNOWN, NSNotFound, 0, nil);
    }

    // find tag name & attributes
    NSRange ar;
    int tag = TAG_UNKNOWN;
    int location = NSMaxRange(or);
    if (![self compare:@"b" options:0 range:NSMakeRange(location, 1)]) {
        tag = ([self characterAtIndex:location + 1] == '1') ? TAG_B_OPEN : TAG_B_CLOSE;
        ar.length = 0;
    }
    else if (![self compare:@"i" options:0 range:NSMakeRange(location, 1)]) {
        tag = ([self characterAtIndex:location + 1] == '1') ? TAG_I_OPEN : TAG_I_CLOSE;
        ar.length = 0;
    }
    else if (![self compare:@"c"  options:0 range:NSMakeRange(location, 1)]) {
        tag = TAG_C;
        ar.location = location + 1;
        ar.length = NSMaxRange(cr) - ar.location - 1;
    }
    else if (![self compare:@"1c" options:0 range:NSMakeRange(location, 2)] ||
             ![self compare:@"2c" options:0 range:NSMakeRange(location, 2)] ||
             ![self compare:@"3c" options:0 range:NSMakeRange(location, 2)] ||
             ![self compare:@"4c" options:0 range:NSMakeRange(location, 2)]) {
        tag = TAG_C;
        ar.location = location + 2;
        ar.length = NSMaxRange(cr) - ar.location - 1;
    }
    else if (![self compare:@"r"  options:0 range:NSMakeRange(location, 1)]) {
        tag = TAG_R;
        ar.location = location + 1;
        ar.length = NSMaxRange(cr) - ar.location - 1;
    }
    if (tag != TAG_UNKNOWN) {
        return MMakeSSATag(tag,
                           or.location, NSMaxRange(cr) - or.location,
                           (0 < ar.length) ? [self substringWithRange:ar] : nil);
    }
    return MMakeSSATag(TAG_UNKNOWN, or.location, NSMaxRange(cr) - or.location, nil);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSColor (MSubtitleParser_SSA)

+ (NSColor*)colorFromSSAString:(NSString*)string
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);
    unsigned int red = 0xFF, green = 0xFF, blue = 0xFF;

    if (![string compare:@"&H" options:0 range:NSMakeRange(0, 2)]) {
        int n = ([string characterAtIndex:[string length] - 1] == '&') ? 1 : 0;
        NSString* cs = [string substringWithRange:NSMakeRange(2, [string length] - 2 - n)];
        int length = [cs length];
        if (length == 2) {
            sscanf([cs UTF8String], "%2x", &red);
        }
        else if (length == 4) {
            sscanf([cs UTF8String], "%2x%2x", &green, &red);
        }
        else if (length == 6) {
            sscanf([cs UTF8String], "%2x%2x%2x", &blue, &green, &red);
        }
        else {
            unsigned int alpha;
            sscanf([cs UTF8String], "%2x%2x%2x%2x", &alpha, &blue, &green, &red);
        }
    }
    return [NSColor colorWithCalibratedRed:red  / 255.0 green:green / 255.0
                                      blue:blue / 255.0 alpha:1.0];
}

@end

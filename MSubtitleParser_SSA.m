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

- (void)dealloc
{
    [_formats release];
    [super dealloc];
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
    if (sr.location != NSNotFound) {
        sr.length = sr.location - NSMaxRange(r);
        sr.location = NSMaxRange(r);
    }
    else {
        sr = *rangePtr;
    }
    if ([styles characterAtIndex:NSMaxRange(sr) - 1] == '\r') {
        sr.length--;    // remove last '\r'
    }
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

- (void)mkvTrackNumber:(int)trackNumber setStyles:(NSString*)string
{
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
    
    [_styles setObject:styles forKey:[NSNumber numberWithInt:trackNumber]];
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
                        if (tag.attr) {
                            color = [NSColor colorFromSSAString:tag.attr];
                        }
                        else {
                            color = _defaultColor;
                        }
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

static float movieTimeFromString(NSString* string)
{
    // string is like this: "0:00:00.00"
    int h, m, s, ms;
    sscanf([string UTF8String], "%d:%d:%d.%d", &h, &m, &s, &ms);
    return (float)(h * 60 * 60) + (m * 60) + s + (ms * 0.01);
}

- (NSMutableAttributedString*)mkvTrackNumber:(int)trackNumber
                         parseSubtitleString:(NSString*)string
                                        beginTime:(float*)beginTime
                                          endTime:(float*)endTime
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);
    // apply text-attributes : italic, bold, ...
    NSRange range = NSMakeRange(0, [string length]);
    NSString* s, *format, *style, *text;
    NSEnumerator* e = [_formats objectEnumerator];
    while (format = [e nextObject]) {
        if ([format isEqualToString:@"Text"]) {
            // text may be the last formatted string.
            // remove last '\r' and '\n'.
            unichar c;
            while (0 < range.length) {
                c = [string characterAtIndex:NSMaxRange(range) - 1];
                if (c != '\r' && c != '\n') {
                    break;
                }
                range.length--;
            }
            text = [string substringWithRange:range];
        }
        else {
            s = [self eventStringWithString:string rangePtr:&range];
            if ([format isEqualToString:@"Style"]) {
                style = s;
            }
            else if ([format isEqualToString:@"Start"]) {
                *beginTime = movieTimeFromString(s);
            }
            else if ([format isEqualToString:@"End"]) {
                *endTime = movieTimeFromString(s);
            }
        }
    }

    NSNumber* number = [NSNumber numberWithInt:trackNumber];
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

- (NSMutableAttributedString*)mkvTrackNumber:(int)trackNumber
                         parseSubtitleString:(NSString*)string
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);
    
    if (!_formats) {
        // if this method is called for parsing embedded subtitle in MKV,
        // then _formats is not initialized yet. in this case, string is
        // formatted with following predefined order:
        _formats = [[NSArray alloc] initWithObjects:
                    @"ReadOrder", @"Layer", @"Style", @"Name",
                    @"MarginL", @"MarginR", @"MarginV", @"Effect", @"Text", nil];
    }
    float beginTime, endTime;
    return [self mkvTrackNumber:trackNumber parseSubtitleString:string
                           beginTime:&beginTime endTime:&endTime];
}

- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _source = [[string retain] autorelease];
    _sourceRange = NSMakeRange(0, [_source length]);
    _subtitles = [NSMutableArray arrayWithCapacity:1];
    if (options) {
    }

    MSubtitle* subtitle = [[[MSubtitle alloc] initWithURL:_subtitleURL] autorelease];
    [subtitle setType:@"SSA"];
    [subtitle setTrackName:NSLocalizedString(@"External Subtitle", nil)];
    [subtitle setEmbedded:FALSE];
    [_subtitles addObject:subtitle];

    NSRange r = [_source rangeOfString:@"[V4 Styles]" rangePtr:&_sourceRange];
    if (r.location == NSNotFound) {
        r = [_source rangeOfString:@"[V4+ Styles]" rangePtr:&_sourceRange];
    }
    if (r.location == NSNotFound) {
        return _subtitles;
    }

    NSRange er = [_source rangeOfString:@"[Events]" rangePtr:&_sourceRange];
    if (er.location == NSNotFound) {
        return _subtitles;
    }

    // parse styles
    NSRange sr = NSMakeRange(r.location, er.location - r.location);
    [self mkvTrackNumber:0 setStyles:[_source substringWithRange:sr]];

    // parser events: formats
    _formats = [self formatForTitle:@"Format:" styles:_source rangePtr:&_sourceRange];
    [_formats retain];

    // parser events: dialogues
    float beginTime, endTime;
    NSMutableAttributedString* mas;
    r = [_source rangeOfString:@"Dialogue:" rangePtr:&_sourceRange];
    while (0 < _sourceRange.length) {
        r.location = NSMaxRange(r);
        er = [_source rangeOfString:@"Dialogue:" rangePtr:&_sourceRange];
        if (er.location != NSNotFound) {
            r.length = er.location - r.location;
        }
        else {
            r.length = NSMaxRange(_sourceRange) - r.location;
            _sourceRange.length = 0;
        }
        mas = [self mkvTrackNumber:0
               parseSubtitleString:[_source substringWithRange:r]
                         beginTime:&beginTime endTime:&endTime];
        [subtitle addString:mas beginTime:beginTime endTime:endTime];
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

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

#import "MSubtitleParser_SMI.h"

enum {
    TAG_NONE            = -1,
    TAG_UNKNOWN         = 0,

    TAG_SAMI_OPEN,      TAG_SAMI_CLOSE,
    TAG_HEAD_OPEN,      TAG_HEAD_CLOSE,
    TAG_TITLE_OPEN,     TAG_TITLE_CLOSE,
    TAG_STYLE_OPEN,     TAG_STYLE_CLOSE,
    TAG_BODY_OPEN,      TAG_BODY_CLOSE,
    TAG_SYNC,
    TAG_P,
    TAG_COMMENT,

    // contents tags
    TAG_BR,
    TAG_FONT_OPEN,      TAG_FONT_CLOSE,
    TAG_I_OPEN,         TAG_I_CLOSE,
    TAG_B_OPEN,         TAG_B_CLOSE,
};

#define isContentsTag(tagType)  (TAG_BR <= tagType)

typedef struct _SMITag {
    int type;          // TAG_*
    NSString* attr;
    NSRange range;
} SMITag;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSString (MSubtitleParser_SMI)

- (SMITag)smiTagWithRangePtr:(NSRange*)range delimSet:(NSCharacterSet*)delimSet;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSColor (MSubtitleParser_SMI)

+ (NSColor*)colorFromSMIString:(NSString*)string;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

NSString* MSubtitleParserOptionKey_SMI_replaceNewLineWithBR = @"replaceNewLineWithBR";

@implementation MSubtitleParser_SMI

- (MSubtitle*)addSubtitleClass:(NSString*)class
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, class);
    MSubtitle* subtitle = [[[MSubtitle alloc] initWithURL:_subtitleURL] autorelease];
    [subtitle setType:@"SMI"];
    [subtitle setName:class];   // name will be updated later by "Name:" field.
    [subtitle setExtraInfo:class];
    [subtitle setTrackName:NSLocalizedString(@"External Subtitle", nil)];
    [subtitle setEmbedded:FALSE];
    [_subtitles addObject:subtitle];
    [_classes setObject:subtitle forKey:class];
    return subtitle;
}

- (void)parse_STYLE:(NSString*)attr
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, attr);
    NSRange r = [attr rangeOfString:@"text/css" range:NSMakeRange(0, [attr length])];
    if (r.location == NSNotFound) {
        return;
    }

    SMITag tag = [_source smiTagWithRangePtr:&_sourceRange delimSet:_delimSet];
    if (tag.type != TAG_COMMENT) {
        return;
    }

    MSubtitle* subtitle = nil;
    NSRange tr, cr = tag.range;
    while (0 < cr.length) {
        tr = [_source tokenRangeForDelimiterSet:_styleDelimSet rangePtr:&cr];
        if (tr.length == 0) {
            break;
        }
        if ([_source characterAtIndex:tr.location] == '.') {
            tr.location++, tr.length--;
            NSString* class = [_source substringWithRange:tr];
            subtitle = [self addSubtitleClass:class];
        }
        else if ([_source characterAtIndex:tr.location] == '#') {
            tr.location++, tr.length--;
            subtitle = nil;
        }
        else if (subtitle) {
            if (![_source compare:@"NAME" options:NSCaseInsensitiveSearch range:tr]) {
                tr = [_source tokenRangeForDelimiterSet:_styleDelimSet rangePtr:&cr];
                [subtitle setName:[_source substringWithRange:tr]];
            }
            else if (![_source compare:@"LANG" options:NSCaseInsensitiveSearch range:tr]) {
                tr = [_source tokenRangeForDelimiterSet:_styleDelimSet rangePtr:&cr];
                [subtitle setLanguage:[_source substringWithRange:tr]];
            }
        }
    }
}

- (float)parse_SYNC:(NSString*)attr
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, attr);
    NSRange ar = NSMakeRange(0, [attr length]);
    NSRange tr = [attr tokenRangeForDelimiterSet:_syncDelimSet rangePtr:&ar];
    if (![attr compare:@"START" options:NSCaseInsensitiveSearch range:tr]) {
        tr = [attr tokenRangeForDelimiterSet:_syncDelimSet rangePtr:&ar];
        return [[attr substringWithRange:tr] intValue] / 1000.f;
    }
    return -1.0;
}

- (NSString*)parse_P:(NSString*)attr
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, attr);
    NSRange ar = NSMakeRange(0, [attr length]);
    NSRange tr = [attr tokenRangeForDelimiterSet:_pDelimSet rangePtr:&ar];
    if (![attr compare:@"CLASS" options:NSCaseInsensitiveSearch range:tr]) {
        tr = [attr tokenRangeForDelimiterSet:_pDelimSet rangePtr:&ar];
        return [attr substringWithRange:tr];
    }
    return nil;
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
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);

    // this method can be called independently for parsing embedded subtitle.
    // following instance variables should be initializaed before calling.
    // _delimSet, _fontDelimSet, _replaceNewLineWithBR, _removeLastBR

    NSMutableString* ms = [NSMutableString stringWithCapacity:[string length]];

    // make ms without new-lines
    NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
    NSRange r, range = NSMakeRange(0, [string length]);
    while (0 < range.length) {
        r = [string tokenRangeForDelimiterSet:set rangePtr:&range];
        if (r.length != 0) {
            int i;
            for (i = NSMaxRange(r) - 1; r.location <= i; i--) {
                if ([_delimSet characterIsMember:[string characterAtIndex:i]]) {
                    r.length--;
                }
                else {
                    [ms appendString:[string substringWithRange:r]];
                    if ([string characterAtIndex:i] != '>') {
                        [ms appendString:_replaceNewLineWithBR ? @"<BR>" : @" "];
                    }
                    break;
                }
            }
        }
    }
    [ms removeRightWhitespaces];

    // remove <!-- -->
    SMITag tag;
    range = NSMakeRange(0, [ms length]);
    while (0 < range.length) {
        tag = [ms smiTagWithRangePtr:&range delimSet:_delimSet];
        if (tag.type == TAG_COMMENT) {
            [ms deleteCharactersInRange:tag.range];
            range.location -= tag.range.length;
        }
    }
    // replace "<BR>" with "\n" and remove leading white-spaces in each line
    set = [NSCharacterSet whitespaceCharacterSet];
    range = NSMakeRange(0, [ms length]);
    while (0 < range.length) {
        tag = [ms smiTagWithRangePtr:&range delimSet:_delimSet];
        if (tag.type == TAG_BR) {
            if (0 < range.length || !_removeLastBR) {
                // remove leading white-spaces
                while (0 < tag.range.location &&
                       [set characterIsMember:[ms characterAtIndex:tag.range.location - 1]]) {
                    tag.range.location--;
                    tag.range.length++;
                }
                // replace "<BR>" with "\n"
                [ms replaceCharactersInRange:tag.range withString:@"\n"];
                range.location -= tag.range.length - 1; // - 1 for "\n"
            }
            else {
                [ms deleteCharactersInRange:tag.range];
                range.location -= tag.range.length;
            }
        }
    }

    // replace '&'-leading sequences
    [ms replaceOccurrencesOfString:@"&lt;" withString:@"<"];
    [ms replaceOccurrencesOfString:@"&lt"  withString:@"<"];
    [ms replaceOccurrencesOfString:@"&gt;" withString:@">"];
    [ms replaceOccurrencesOfString:@"&gt"  withString:@">"];
    [ms replaceOccurrencesOfString:@"&nbsp;" withString:@""];
    [ms replaceOccurrencesOfString:@"&nbsp"  withString:@""];

    // apply text-attributes : font-color, italic, bold, ...
    NSMutableAttributedString* mas = [[[NSMutableAttributedString alloc]
                                initWithString:@"" attributes:nil] autorelease];
    if (0 < [ms length]) {
        NSColor* color = nil;
        BOOL italic = FALSE, bold = FALSE;
        range = NSMakeRange(0, [ms length]);
        while (0 < range.length) {
            r.location = range.location;
            tag = [ms smiTagWithRangePtr:&range delimSet:_delimSet];
            if (isContentsTag(tag.type)) {
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

- (void)parseSubtitleString:(NSString*)string time:(float)time forClass:(NSString*)class
{
    //TRACE(@"%s \"%@\" (%g) (\"%@\")", __PRETTY_FUNCTION__, string, time, class);
    if (!class) {
        class = NSLocalizedString(@"Unnamed", nil);
    }
    MSubtitle* subtitle = [_classes objectForKey:class];
    if (!subtitle) {
        subtitle = [self addSubtitleClass:class];
    }
    [subtitle addString:[self parseSubtitleString:string] time:time];
}

////////////////////////////////////////////////////////////////////////////////

- (void)readyWithOptions:(NSDictionary*)options
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _removeLastBR = TRUE;   // always true
    _replaceNewLineWithBR = TRUE;
    if (options) {
        NSNumber* n = (NSNumber*)[options objectForKey:
                                  MSubtitleParserOptionKey_SMI_replaceNewLineWithBR];
        if (n) {
            _replaceNewLineWithBR = [n boolValue];
        }
    }

    _delimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableCharacterSet* mset = [_delimSet mutableCopy];
    [mset addCharactersInString:@"{}:;"];
    _styleDelimSet = mset;
    mset = [_delimSet mutableCopy];
    [mset addCharactersInString:@"='\""];
    _syncDelimSet = _pDelimSet = _fontDelimSet = mset;

    _classes = [NSMutableDictionary dictionaryWithCapacity:2];
}

- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _source = [[string retain] autorelease];
    _sourceRange = NSMakeRange(0, [_source length]);
    _subtitles = [NSMutableArray arrayWithCapacity:2];
    [self readyWithOptions:options];

    float time = -1.0;
    NSString* class = nil;
    NSRange range = NSMakeRange(-1, 0);

    SMITag tag;
    while (0 < _sourceRange.length) {
        tag = [_source smiTagWithRangePtr:&_sourceRange delimSet:_delimSet];
        switch (tag.type) {
            case TAG_NONE :
                break;
            case TAG_UNKNOWN :
                break;
            case TAG_STYLE_OPEN :
                [self parse_STYLE:tag.attr];
                break;
            case TAG_SYNC :
                if (0.0 <= time) {
                    range.length = tag.range.location - range.location;
                    [self parseSubtitleString:[_source substringWithRange:range]
                                         time:time forClass:class];
                    time = -1.0;    // reset
                }
                time = [self parse_SYNC:tag.attr];
                range.location = NSMaxRange(tag.range);
                range.length = 0;
                break;
            case TAG_P :
                range.location = NSMaxRange(tag.range);
                range.length = 0;
                class = [self parse_P:tag.attr];
                break;
            case TAG_COMMENT :
                break;
            default :
                if (!isContentsTag(tag.type) &&
                    0.0 <= time && range.length == 0) {
                    range.length = tag.range.location - range.location;
                }
                // don't call parseSubtitle here for non-closing-tag
                break;
        }
    }
    if (0.0 <= time) {  // for non-closing-tag
        if (range.length == 0) {    // for non-sami-ending-tags
            range.length = [_source length] - range.location;
        }
        [self parseSubtitleString:[_source substringWithRange:range]
                             time:time forClass:class];
    }

    // remove empty subtitle if exist and
    // make complete not-ended-string if exist.
    int i;
    MSubtitle* subtitle;
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

@implementation NSString (MSubtitleParser_SMI)

SMITag MMakeSMITag(int type, int location, int length, NSString* attr)
{
    SMITag tag;
    tag.type = type;
    tag.range.location = location;
    tag.range.length = length;
    tag.attr = attr;
    return tag;
}

- (SMITag)smiTagWithRangePtr:(NSRange*)range delimSet:(NSCharacterSet*)delimSet
{
    //TRACE(@"%s %@ (%@)", __PRETTY_FUNCTION__, NSStringFromRange(*range), delimSet);
    NSRange or = [self rangeOfString:@"<" rangePtr:range];
    if (or.location == NSNotFound) {
        range->location = [self length];
        range->length = 0;
        return MMakeSMITag(TAG_NONE, NSNotFound, 0, nil);
    }

    NSRange cr;
    if ([self characterAtIndex:or.location + 1] == '!') {  // may be a comment tag
        [self rangeOfString:@"--" rangePtr:range];
        [self rangeOfString:@"--" rangePtr:range];
        cr = [self rangeOfString:@">" rangePtr:range];
        return MMakeSMITag(TAG_COMMENT, or.location, NSMaxRange(cr) - or.location, nil);
    }
    cr = [self rangeOfString:@">" rangePtr:range];
    if (cr.location == NSNotFound) {
        return MMakeSMITag(TAG_UNKNOWN, NSNotFound, 0, nil);
    }

    // find tag name & attributes
    int i, c = ([self characterAtIndex:or.location + 1] == '/') ? 1 : 0;
    NSRange ar;
    ar.location = or.location + 1 + c;
    ar.length = NSMaxRange(cr) - ar.location - 1;
    NSRange nr = [self tokenRangeForDelimiterSet:delimSet rangePtr:&ar];

    static const struct {
        NSString* name;
        int type[2];
    } nameType[] = {
        { @"SAMI",  TAG_SAMI_OPEN,  TAG_SAMI_CLOSE },
        { @"HEAD",  TAG_HEAD_OPEN,  TAG_HEAD_CLOSE },
        { @"TITLE", TAG_TITLE_OPEN, TAG_TITLE_CLOSE },
        { @"STYLE", TAG_STYLE_OPEN, TAG_STYLE_CLOSE },
        { @"BODY",  TAG_BODY_OPEN,  TAG_BODY_CLOSE },
        { @"SYNC",  TAG_SYNC,       TAG_NONE },
        { @"P",     TAG_P,          TAG_NONE },
        { @"BR",    TAG_BR,         TAG_NONE },
        { @"FONT",  TAG_FONT_OPEN,  TAG_FONT_CLOSE },
        { @"I",     TAG_I_OPEN,     TAG_I_CLOSE },
        { @"B",     TAG_B_OPEN,     TAG_B_CLOSE },
    };
    for (i = 0; i < sizeof(nameType) / sizeof(nameType[0]); i++) {
        if (![self compare:nameType[i].name options:NSCaseInsensitiveSearch range:nr]) {
            return MMakeSMITag(nameType[i].type[c],
                               or.location, NSMaxRange(cr) - or.location,
                               (0 < ar.length) ? [self substringWithRange:ar] : nil);
        }
    }
    return MMakeSMITag(TAG_UNKNOWN, NSNotFound, 0, nil);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSColor (MSubtitleParser_SMI)

+ (NSColor*)colorFromSMIString:(NSString*)string
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);
    unsigned int red = 0xFF, green = 0xFF, blue = 0xFF;

    if ([string length] == 0) {
        // empty string => make white using default red, green and blue.
    }
    else if ([string characterAtIndex:0] == '#') {   // ex: #ABCDEF
        sscanf([string UTF8String] + 1, "%2x%2x%2x", &red, &green, &blue);
    }
    else {
        struct SMIColor {
            NSString* name;
            unsigned int r, g, b;
        };
        static struct SMIColor smiColors[] = {
            { @"AliceBlue",         0xF0, 0xF8, 0xFF },
            { @"AntiqueWhite",      0xFA, 0xEB, 0xD7 },
            { @"Aqua",              0x00, 0xFF, 0xFF },
            { @"Aquamarine",        0x7F, 0xFF, 0xD4 },
            { @"Azure",             0xF0, 0xFF, 0xFF },
            { @"Beige",             0xF5, 0xF5, 0xDC },
            { @"Bisque",            0xFF, 0xE4, 0xC4 },
            { @"Black",             0x00, 0x00, 0x00 },
            { @"BlanchedAlmond",    0xFF, 0xEB, 0xCD },
            { @"Blue",              0x00, 0x00, 0xFF },
            { @"BlueViolet",        0x8A, 0x2B, 0xE2 },
            { @"Brown",             0xA5, 0x2A, 0x2A },
            { @"BurlyWood",         0xDE, 0xB8, 0x87 },
            { @"CadetBlue",         0x5F, 0x9E, 0xA0 },
            { @"Chartreuse",        0x7F, 0xFF, 0x00 },
            { @"Chocolate",         0xD2, 0x69, 0x1E },
            { @"Coral",             0xFF, 0x7F, 0x50 },
            { @"CornflowerBlue",    0x64, 0x95, 0xED },
            { @"Cornsilk",          0xFF, 0xF8, 0xDC },
            { @"Crimson",           0xDC, 0x14, 0x3C },
            { @"Cyan",              0x00, 0xFF, 0xFF },
            { @"DarkBlue",          0x00, 0x00, 0x8B },
            { @"DarkCyan",          0x00, 0x8B, 0x8B },
            { @"DarkGoldenRod",     0xB8, 0x86, 0x0B },
            { @"DarkGray",          0xA9, 0xA9, 0xA9 },
            { @"DarkGrey",          0xA9, 0xA9, 0xA9 },
            { @"DarkGreen",         0x00, 0x64, 0x00 },
            { @"DarkKhaki",         0xBD, 0xB7, 0x6B },
            { @"DarkMagenta",       0x8B, 0x00, 0x8B },
            { @"DarkOliveGreen",    0x55, 0x6B, 0x2F },
            { @"Darkorange",        0xFF, 0x8C, 0x00 },
            { @"DarkOrchid",        0x99, 0x32, 0xCC },
            { @"DarkRed",           0x8B, 0x00, 0x00 },
            { @"DarkSalmon",        0xE9, 0x96, 0x7A },
            { @"DarkSeaGreen",      0x8F, 0xBC, 0x8F },
            { @"DarkSlateBlue",     0x48, 0x3D, 0x8B },
            { @"DarkSlateGray",     0x2F, 0x4F, 0x4F },
            { @"DarkSlateGrey",     0x2F, 0x4F, 0x4F },
            { @"DarkTurquoise",     0x00, 0xCE, 0xD1 },
            { @"DarkViolet",        0x94, 0x00, 0xD3 },
            { @"DeepPink",          0xFF, 0x14, 0x93 },
            { @"DeepSkyBlue",       0x00, 0xBF, 0xFF },
            { @"DimGray",           0x69, 0x69, 0x69 },
            { @"DimGrey",           0x69, 0x69, 0x69 },
            { @"DodgerBlue",        0x1E, 0x90, 0xFF },
            { @"FireBrick",         0xB2, 0x22, 0x22 },
            { @"FloralWhite",       0xFF, 0xFA, 0xF0 },
            { @"ForestGreen",       0x22, 0x8B, 0x22 },
            { @"Fuchsia",           0xFF, 0x00, 0xFF },
            { @"Gainsboro",         0xDC, 0xDC, 0xDC },
            { @"GhostWhite",        0xF8, 0xF8, 0xFF },
            { @"Gold",              0xFF, 0xD7, 0x00 },
            { @"GoldenRod",         0xDA, 0xA5, 0x20 },
            { @"Gray",              0x80, 0x80, 0x80 },
            { @"Grey",              0x80, 0x80, 0x80 },
            { @"Green",             0x00, 0x80, 0x00 },
            { @"GreenYellow",       0xAD, 0xFF, 0x2F },
            { @"HoneyDew",          0xF0, 0xFF, 0xF0 },
            { @"HotPink",           0xFF, 0x69, 0xB4 },
            { @"IndianRed",         0xCD, 0x5C, 0x5C },
            { @"Indigo",            0x4B, 0x00, 0x82 },
            { @"Ivory",             0xFF, 0xFF, 0xF0 },
            { @"Khaki",             0xF0, 0xE6, 0x8C },
            { @"Lavender",          0xE6, 0xE6, 0xFA },
            { @"LavenderBlush",     0xFF, 0xF0, 0xF5 },
            { @"LawnGreen",         0x7C, 0xFC, 0x00 },
            { @"LemonChiffon",      0xFF, 0xFA, 0xCD },
            { @"LightBlue",         0xAD, 0xD8, 0xE6 },
            { @"LightCoral",        0xF0, 0x80, 0x80 },
            { @"LightCyan",         0xE0, 0xFF, 0xFF },
            { @"LightGoldenRodYellow",0xFA,0xFA,0xD2 },
            { @"LightGray",         0xD3, 0xD3, 0xD3 },
            { @"LightGrey",         0xD3, 0xD3, 0xD3 },
            { @"LightGreen",        0x90, 0xEE, 0x90 },
            { @"LightPink",         0xFF, 0xB6, 0xC1 },
            { @"LightSalmon",       0xFF, 0xA0, 0x7A },
            { @"LightSeaGreen",     0x20, 0xB2, 0xAA },
            { @"LightSkyBlue",      0x87, 0xCE, 0xFA },
            { @"LightSlateGray",    0x77, 0x88, 0x99 },
            { @"LightSlateGrey",    0x77, 0x88, 0x99 },
            { @"LightSteelBlue",    0xB0, 0xC4, 0xDE },
            { @"LightYellow",       0xFF, 0xFF, 0xE0 },
            { @"Lime",              0x00, 0xFF, 0x00 },
            { @"LimeGreen",         0x32, 0xCD, 0x32 },
            { @"Linen",             0xFA, 0xF0, 0xE6 },
            { @"Magenta",           0xFF, 0x00, 0xFF },
            { @"Maroon",            0x80, 0x00, 0x00 },
            { @"MediumAquaMarine",  0x66, 0xCD, 0xAA },
            { @"MediumBlue",        0x00, 0x00, 0xCD },
            { @"MediumOrchid",      0xBA, 0x55, 0xD3 },
            { @"MediumPurple",      0x93, 0x70, 0xD8 },
            { @"MediumSeaGreen",    0x3C, 0xB3, 0x71 },
            { @"MediumSlateBlue",   0x7B, 0x68, 0xEE },
            { @"MediumSpringGreen", 0x00, 0xFA, 0x9A },
            { @"MediumTurquoise",   0x48, 0xD1, 0xCC },
            { @"MediumVioletRed",   0xC7, 0x15, 0x85 },
            { @"MidnightBlue",      0x19, 0x19, 0x70 },
            { @"MintCream",         0xF5, 0xFF, 0xFA },
            { @"MistyRose",         0xFF, 0xE4, 0xE1 },
            { @"Moccasin",          0xFF, 0xE4, 0xB5 },
            { @"NavajoWhite",       0xFF, 0xDE, 0xAD },
            { @"Navy",              0x00, 0x00, 0x80 },
            { @"OldLace",           0xFD, 0xF5, 0xE6 },
            { @"Olive",             0x80, 0x80, 0x00 },
            { @"OliveDrab",         0x6B, 0x8E, 0x23 },
            { @"Orange",            0xFF, 0xA5, 0x00 },
            { @"OrangeRed",         0xFF, 0x45, 0x00 },
            { @"Orchid",            0xDA, 0x70, 0xD6 },
            { @"PaleGoldenRod",     0xEE, 0xE8, 0xAA },
            { @"PaleGreen",         0x98, 0xFB, 0x98 },
            { @"PaleTurquoise",     0xAF, 0xEE, 0xEE },
            { @"PaleVioletRed",     0xD8, 0x70, 0x93 },
            { @"PapayaWhip",        0xFF, 0xEF, 0xD5 },
            { @"PeachPuff",         0xFF, 0xDA, 0xB9 },
            { @"Peru",              0xCD, 0x85, 0x3F },
            { @"Pink",              0xFF, 0xC0, 0xCB },
            { @"Plum",              0xDD, 0xA0, 0xDD },
            { @"PowderBlue",        0xB0, 0xE0, 0xE6 },
            { @"Purple",            0x80, 0x00, 0x80 },
            { @"Red",               0xFF, 0x00, 0x00 },
            { @"RosyBrown",         0xBC, 0x8F, 0x8F },
            { @"RoyalBlue",         0x41, 0x69, 0xE1 },
            { @"SaddleBrown",       0x8B, 0x45, 0x13 },
            { @"Salmon",            0xFA, 0x80, 0x72 },
            { @"SandyBrown",        0xF4, 0xA4, 0x60 },
            { @"SeaGreen",          0x2E, 0x8B, 0x57 },
            { @"SeaShell",          0xFF, 0xF5, 0xEE },
            { @"Sienna",            0xA0, 0x52, 0x2D },
            { @"Silver",            0xC0, 0xC0, 0xC0 },
            { @"SkyBlue",           0x87, 0xCE, 0xEB },
            { @"SlateBlue",         0x6A, 0x5A, 0xCD },
            { @"SlateGray",         0x70, 0x80, 0x90 },
            { @"SlateGrey",         0x70, 0x80, 0x90 },
            { @"Snow",              0xFF, 0xFA, 0xFA },
            { @"SpringGreen",       0x00, 0xFF, 0x7F },
            { @"SteelBlue",         0x46, 0x82, 0xB4 },
            { @"Tan",               0xD2, 0xB4, 0x8C },
            { @"Teal",              0x00, 0x80, 0x80 },
            { @"Thistle",           0xD8, 0xBF, 0xD8 },
            { @"Tomato",            0xFF, 0x63, 0x47 },
            { @"Turquoise",         0x40, 0xE0, 0xD0 },
            { @"Violet",            0xEE, 0x82, 0xEE },
            { @"Wheat",             0xF5, 0xDE, 0xB3 },
            { @"White",             0xFF, 0xFF, 0xFF },
            { @"WhiteSmoke",        0xF5, 0xF5, 0xF5 },
            { @"Yellow",            0xFF, 0xFF, 0x00 },
            { @"YellowGreen",       0x9A, 0xCD, 0x32 },
        };
        NSRange range = NSMakeRange(0, [string length]);
        int i, count = sizeof(smiColors) / sizeof(smiColors[0]);
        for (i = 0; i < count; i++) {
            if (NSNotFound != [string rangeOfString:smiColors[i].name
                                              range:range].location) {
                red   = smiColors[i].r;
                green = smiColors[i].g;
                blue  = smiColors[i].b;
                break;
            }
        }
        if (i == count) {
            // assume string is hex-value without leading '#'
            sscanf([string UTF8String], "%2x%2x%2x", &red, &green, &blue);
        }
    }
    return [NSColor colorWithCalibratedRed:red  / 255.0 green:green / 255.0
                                      blue:blue / 255.0 alpha:1.0];
}

@end

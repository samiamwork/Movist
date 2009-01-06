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

@implementation MSubtitleParser_SSA

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

- (NSMutableAttributedString*)parseSubtitleString_MKV:(NSString*)string
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, string);

    // this method is called independently for parsing embedded subtitle in MKV.
    // string is formatted with following predefined order:
    //   ReadOrder, Layer, Style, Name, MarginL, MarginR, MarginV, Effect, Text.

    // apply text-attributes : italic, bold, ...
    NSMutableAttributedString* mas = [[[NSMutableAttributedString alloc]
                                initWithString:@"" attributes:nil] autorelease];

    NSString* s;
    NSRange range = NSMakeRange(0, [string length]);
    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"ReadOrder = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"Layer = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"Style = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"Name = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"MarginL = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"MarginR = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"MarginV = %@", s);

    s = [self eventStringWithString:string rangePtr:&range];
    //TRACE(@"Effect = %@", s);

    s = [string substringWithRange:range];
    //TRACE(@"Text = %@", s);
    [mas appendAttributedString:[[[NSAttributedString alloc]
                                  initWithString:s attributes:nil] autorelease]];

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

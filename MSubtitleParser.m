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

#import "MSubtitleParser.h"

@implementation MSubtitleParser

+ (Class)parserClassForSubtitleType:(NSString*)type
{
    return NSClassFromString([subtitleTypesAndParsers()
                              objectForKey:[type lowercaseString]]);
}

- (id)initWithURL:(NSURL*)subtitleURL
{
    if (self = [super init]) {
        _subtitleURL = [subtitleURL retain];
    }
    return self;
}

- (void)dealloc
{
    [_subtitleURL release];
    [super dealloc];
}

NSString* MSubtitleParserOptionKey_stringEncoding = @"stringEncoding";

- (NSArray*)parseWithOptions:(NSDictionary*)options error:(NSError**)error
{
    // assume _subtitleURL is a text-based subtitle.
    // some parsers for other types can override this message.
    CFStringEncoding encoding = kCFStringEncodingInvalidId;
    NSNumber* n = [options objectForKey:MSubtitleParserOptionKey_stringEncoding];
    if (n) {
        encoding = [n intValue];
    }

    NSString* s = [self stringWithEncoding:encoding error:error];
    return (s) ? [self parseString:s options:options error:error] : nil;
}

- (NSString*)stringWithEncoding:(CFStringEncoding)encoding error:(NSError**)error
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [subtitleURL absoluteString]);
    assert(encoding != kCFStringEncodingInvalidId);

    NSString* path = [_subtitleURL path];
    NSData* data = [NSData dataWithContentsOfFile:path options:0 error:error];
    if (!data) {
        return nil;
    }
    
    // try with user-specified encoding
    NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
    //TRACE(@"CFStringEncoding:%u => NSStringEncoding:%u", cfEncoding, nsEncoding);
    NSString* s = [[NSString alloc] initWithData:data encoding:nsEncoding];
    if (s) {
        return [s autorelease];
    }
    
    // remove unconvertable characters
    const char* p = (const char*)[data bytes];
    char* bytes = (char*)malloc([data length]);
    int i = 0;
    while (*p != '\0') {
        bytes[i] = *p++;
        if (bytes[i] & 0x80) {
            bytes[i + 1] = *p++;
            bytes[i + 2] = '\0';
            if ([[[NSString alloc] initWithBytesNoCopy:&bytes[i] length:i + 2
                        encoding:nsEncoding freeWhenDone:FALSE] autorelease]) {
                i += 2;
            }
        }
        else {
            i++;
        }
    }
    bytes[i] = '\0';
    s = [[NSString alloc] initWithBytesNoCopy:bytes length:i + 1
                                     encoding:nsEncoding freeWhenDone:TRUE];
    if (s) {
        return [s autorelease];
    }
    else {
        free(bytes);
        return @"";  // not nil for reopen
    }
}

- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error
{
    return nil;
}

@end

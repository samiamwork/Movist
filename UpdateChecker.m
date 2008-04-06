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

#import "UpdateChecker.h"
#import "MSubtitle.h"   // for NSString (MSubtitleParser) extension

@implementation UpdateChecker

- (id)init
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        CURRENT_VERSION = [[infoDict objectForKey:@"CFBundleVersion"] retain];
    }
    return self;
}

- (void)dealloc
{
    [CURRENT_VERSION release];
    [_downloadURL release];
    [_homepageURL release];
    [_newVersion release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSString*)newVersion { return _newVersion; }
- (NSURL*)homepageURL { return _homepageURL; }
- (NSURL*)downloadURL { return _downloadURL; }

- (NSString*)tdStringInString:(NSString*)string rangePtr:(NSRange*)range
                      tdRange:(NSRange*)tdRange
{
    // find <td ...> ~ </td> in html table
    NSRange r1 = [string rangeOfString:@"<td" rangePtr:range];
    if (r1.location == NSNotFound) {
        return nil;
    }
    NSRange r2 = [string rangeOfString:@"</td>" rangePtr:range];
    if (r1.location == NSNotFound) {
        return nil;
    }
    tdRange->location = r1.location + 3;
    tdRange->length = r2.location - r1.location;
    return [string substringWithRange:*tdRange];
}

- (int)checkUpdate:(NSError**)error
{
    NSString* address = @"http://code.google.com/p/movist/downloads/list";
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:address]
                                         options:NSMappedRead | NSUncachedRead
                                           error:error];
    if (!data || [data length] == 0) {
        return UPDATE_CHECK_FAILED;
    }

    [_newVersion release], _newVersion = nil;
    [_homepageURL release], _homepageURL = nil;

    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSRange range = NSMakeRange(0, [string length]);

    NSRange r, r1, r2, tdr;
    NSString* tds, *version;
    NSString* newVersion = CURRENT_VERSION;
    NSString* homepageURLString = nil;
    NSString* downloadURLString = nil;
    while (TRUE) {
        tds = [self tdStringInString:string rangePtr:&range tdRange:&tdr];
        if (!tds) {
            break;  // no more data
        }
        //TRACE(@"substring=\"%@\"", tds);

        // find filename string
        tdr.location = 0;
        r1 = [tds rangeOfString:@"Movist_v" range:tdr];
        if (r1.location == NSNotFound) {
            continue;
        }
        r2 = [tds rangeOfString:@".zip" range:tdr];
        if (r2.location == NSNotFound) {
            r2 = [tds rangeOfString:@".dmg" range:tdr];
            if (r2.location == NSNotFound) {
                continue;
            }
        }

        // find version string
        r.location = NSMaxRange(r1);
        r.length = r2.location - r.location;
        version = [tds substringWithRange:r];
        if ([version caseInsensitiveCompare:newVersion] <= 0) {
            continue;
        }

        // find homepage URL
        r1 = [tds rangeOfString:@"http://" range:tdr];
        if (r1.location == NSNotFound) {
            continue;
        }
        r2 = [tds rangeOfString:@"</a>" range:tdr];
        if (r2.location == NSNotFound) {
            continue;
        }
        r.location = r1.location;
        r.length = r2.location - r1.location;
        homepageURLString = [tds substringWithRange:r];
        newVersion = version;

        // find download URL
        tds = [self tdStringInString:string rangePtr:&range tdRange:&tdr];
        if (!tds) {
            break;  // no more data
        }
        //TRACE(@"substring=\"%@\"", tds);

        tdr = NSMakeRange(0, [tds length]);
        r1 = [tds rangeOfString:@"http://" range:tdr];
        if (r1.location == NSNotFound) {
            continue;
        }
        r2 = [tds rangeOfString:@"\" " range:tdr];
        if (r2.location == NSNotFound) {
            continue;
        }
        r.location = r1.location;
        r.length = r2.location - r1.location;
        downloadURLString = [tds substringWithRange:r];
    }

    [string release];

    if (homepageURLString) {
        //TRACE(@"new version=\"%@\", homepage=\"%@\", download=\"%@\"",
        //      newVersion, homepageURLString, downloadURLString);
        _newVersion = [newVersion retain];
        _homepageURL = [[NSURL URLWithString:homepageURLString] retain];
        _downloadURL = [[NSURL URLWithString:downloadURLString] retain];
        return NEW_VERSION_AVAILABLE;
    }
    return NO_UPDATE_AVAILABLE;
}

@end

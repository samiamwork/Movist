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

#import "MSubtitleOSD.h"

@implementation MSubtitleOSD : MTextOSD

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        [_paragraphStyle setAlignment:NSCenterTextAlignment];
        _strings = [[NSMutableDictionary alloc] initWithCapacity:2];
        _shadowStrongness = 10;
        _hAlign = OSD_HALIGN_CENTER;
        _vAlign = OSD_VALIGN_UPPER_FROM_MOVIE_BOTTOM;
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_strings release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)hasContent { return ([_strings count] != 0); }

- (void)clearContent
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_strings removeAllObjects];
    _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
}

- (NSMutableAttributedString*)stringForName:(NSString*)name
{
    return [_strings objectForKey:name];
}

- (BOOL)setString:(NSMutableAttributedString*)string forName:(NSString*)name
{
    //TRACE(@"%s \"%@\" for \"%@\"", __PRETTY_FUNCTION__, [string string], name);
    assert(string != nil && name != nil);
    NSAttributedString* prevString = [self stringForName:name];
    if (!prevString || ![prevString isEqualToAttributedString:string]) {
        if ([string length] == 0) {
            [_strings removeObjectForKey:name];
        }
        else {
            [_strings setObject:string forKey:name];
        }
        _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
        return TRUE;
    }
    return FALSE;
}

- (void)updateContent
{
    [_newString release];
    _newString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSAttributedString* newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString* s;
    NSEnumerator* enumerator = [[_strings allValues] objectEnumerator];
    while (s = [enumerator nextObject]) {
        if ([_newString length] != 0) {
            [_newString appendAttributedString:newline];
        }
        [_newString appendAttributedString:s];
    }
    [newline release];
    [_newString fixAttributesInRange:NSMakeRange(0, [_newString length])];

    [super updateContent];
}

- (void)drawInViewBounds:(NSRect)viewBounds
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    if (0 < [_strings count]) {
        [super drawInViewBounds:viewBounds];
    }
}

@end

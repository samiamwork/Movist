//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MSubtitleOSD.h"

@implementation MSubtitleOSD : MTextOSD

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        [_paragraphStyle setAlignment:NSCenterTextAlignment];
        _strings = [[NSMutableDictionary alloc] initWithCapacity:2];
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
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_strings removeAllObjects];
    _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
}

- (void)setString:(NSMutableAttributedString*)string forName:(NSString*)name
{
    //TRACE(@"%s \"%@\" for \"%@\"", __PRETTY_FUNCTION__, [string string], name);
    assert(string != nil && name != nil);
    if ([string length] == 0) {
        [_strings removeObjectForKey:name];
    }
    else {
        [_strings setObject:string forKey:name];
    }
    _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
}

- (void)updateContent
{
    [_string release];
    _string = [[NSMutableAttributedString alloc] initWithString:@""];
    NSAttributedString* newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString* s;
    NSEnumerator* enumerator = [[_strings allValues] objectEnumerator];
    while (s = [enumerator nextObject]) {
        if ([_string length] != 0) {
            [_string appendAttributedString:newline];
        }
        [_string appendAttributedString:s];
    }
    [newline release];
    [_string fixAttributesInRange:NSMakeRange(0, [_string length])];
}

- (void)drawInViewBounds:(NSRect)viewBounds
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    if (0 < [_strings count]) {
        [super drawInViewBounds:viewBounds];
    }
}

@end

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

#if defined(_SUPPORT_FRONT_ROW)

#import "FullNavItems.h"

@implementation NavItem

- (id)initWithType:(int)type name:(NSString*)name
{
    TRACE(@"%s type=%d, name=\"%@\"", __PRETTY_FUNCTION__, type, name);
    if (self = [super init]) {
        _type = type;
        _name = [name retain];
        _isContainer = (_type == NAV_ITEM_FOLDER);
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_name release];
    [super dealloc];
}

- (void)drawInRect:(NSRect)rect attributes:(NSDictionary*)attrs
{
    TRACE(@"%s name=\"%@\"", __PRETTY_FUNCTION__, _name);

    float CONTAINER_MARK_WIDTH = 60;
    NSSize size = [_name sizeWithAttributes:attrs];
    NSRect rc;
    rc.origin.x    = rect.origin.x;
    rc.origin.y    = rect.origin.y + (rect.size.height - size.height) / 2;
    rc.size.width  = rect.size.width - CONTAINER_MARK_WIDTH;
    rc.size.height = size.height;
    [_name drawInRect:rc withAttributes:attrs];

    if (_isContainer) {
        rc.size.width = CONTAINER_MARK_WIDTH;
        rc.origin.x = NSMaxX(rect) - rc.size.width;
        [@">" drawInRect:rc withAttributes:attrs];
    }
}

- (int)type { return _type; }
- (NSString*)name { return _name; }
- (BOOL)isContainer { return _isContainer; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation NavPathItem

- (id)initWithPath:(NSString*)path
{
    TRACE(@"%s path=\"%@\"", __PRETTY_FUNCTION__, path);
    BOOL isDirectory;
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm fileExistsAtPath:path isDirectory:&isDirectory];
    int type = (isDirectory) ? NAV_ITEM_FOLDER : NAV_ITEM_MOVIE;    // FIXME
    NSString* name = [[fm displayNameAtPath:path] lastPathComponent];
    if (self = [super initWithType:type name:name]) {
        _path = [path retain];
    }
    return self;
}

- (NSString*)path { return _path; }

@end

#endif  // _SUPPORT_FRONT_ROW

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

#import "FullNavItems.h"
#import "MMovie.h"

@implementation FullNavList

- (id)initWithParentItem:(FullNavItem*)parentItem items:(NSArray*)items
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _parentItem = [parentItem retain];
        _items = [items retain];
        _selectedIndex = (0 < [_items count]) ? 0 : -1;
        _topIndex = 0;
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_items release];
    [super dealloc];
}

- (FullNavItem*)parentItem  { return _parentItem; }
- (int)count                { return [_items count]; }
- (int)topIndex             { return _topIndex; }
- (int)selectedIndex        { return _selectedIndex; }

- (FullNavItem*)itemAtIndex:(int)index { return [_items objectAtIndex:index]; }

- (FullNavItem*)selectedItem
{
    return (0 <= _selectedIndex) ? (FullNavItem*)[_items objectAtIndex:_selectedIndex] : nil;
}

- (void)selectAtIndex:(int)index { _selectedIndex = index; }

- (void)selectUpper
{
    if (0 < _selectedIndex) {
        _selectedIndex--;
    }
}

- (void)selectLower
{
    if (_selectedIndex < [_items count] - 1) {
        _selectedIndex++;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavItem

+ (id)fullNavItemWithName:(NSString*)name
{
    FullNavItem* item = [[FullNavItem alloc] initWithName:name];
    return [item autorelease];
}

- (id)initWithName:(NSString*)name
{
    //TRACE(@"%s name=\"%@\"", __PRETTY_FUNCTION__, name);
    if (self = [super init]) {
        _name = [name retain];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_name release];
    [super dealloc];
}

- (NSString*)name { return _name; }
- (BOOL)hasSubContents { return FALSE; }
- (NSArray*)subContents { return nil; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavFileItem

+ (id)fullNavFileItemWithPath:(NSString*)path name:(NSString*)name
{
    FullNavFileItem* item = [[FullNavFileItem alloc] initWithPath:path name:name];
    return [item autorelease];
}

- (id)initWithPath:(NSString*)path name:(NSString*)name
{
    //TRACE(@"%s path=\"%@\"", __PRETTY_FUNCTION__, path);
    if (!name) {
        NSFileManager* fm = [NSFileManager defaultManager];
        name = [[fm displayNameAtPath:path] lastPathComponent];
    }
    if (self = [super initWithName:name]) {
        _path = [path retain];
    }
    return self;
}

- (NSString*)path { return _path; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavDirectoryItem

+ (id)fullNavDirectoryItemWithPath:(NSString*)path name:(NSString*)name
{
    FullNavDirectoryItem* item = [[FullNavDirectoryItem alloc] initWithPath:path name:name];
    return [item autorelease];
}

- (BOOL)hasSubContents { return TRUE; }

- (NSArray*)subContents
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* contents = [fm directoryContentsAtPath:_path];

    NSMutableArray* items = [[NSMutableArray alloc] initWithCapacity:[contents count]];

    BOOL isDirectory;
    NSString* file, *path;
    NSArray* movieTypes = [MMovie movieTypes];
    NSEnumerator* enumerator = [contents objectEnumerator];
    while (file = [enumerator nextObject]) {
        path = [_path stringByAppendingPathComponent:file];
        if ([fm isVisibleFile:path isDirectory:&isDirectory]) {
            if (isDirectory) {
                [items addObject:[FullNavDirectoryItem fullNavDirectoryItemWithPath:path name:nil]];
            }
            else if ([path hasAnyExtension:movieTypes]) {
                [items addObject:[FullNavFileItem fullNavFileItemWithPath:path name:nil]];
            }
        }
    }
    return [items autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavURLItem

+ (id)fullNavURLItemWithURL:(NSURL*)url
{
    FullNavURLItem* item = [[FullNavURLItem alloc] initWithURL:url];
    return [item autorelease];
}

- (id)initWithURL:(NSURL*)url
{
    //TRACE(@"%s url=\"%@\"", __PRETTY_FUNCTION__, [url absoluteString]);
    NSString* name = [[url absoluteString] lastPathComponent];
    if (self = [super initWithName:name]) {
        _url = [url retain];
    }
    return self;
}

- (NSURL*)URL { return _url; }

@end


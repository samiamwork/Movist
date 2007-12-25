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

#import "Movist.h"

@class FullNavItem;

@interface FullNavList : NSObject
{
    FullNavItem* _parentItem;
    NSArray* _items;
    int _selectedIndex;
    int _topIndex;
}

- (id)initWithParentItem:(FullNavItem*)parentItem items:(NSArray*)items;

- (FullNavItem*)parentItem;
- (int)count;
- (int)topIndex;
- (int)selectedIndex;

- (FullNavItem*)itemAtIndex:(int)index;
- (FullNavItem*)selectedItem;
- (void)selectAtIndex:(int)index;
- (void)selectUpper;
- (void)selectLower;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavItem : NSObject
{
    NSString* _name;
}

- (id)initWithName:(NSString*)name;

- (NSString*)name;
- (BOOL)hasSubContents;
- (NSArray*)subContents;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavFileItem : FullNavItem
{
    NSString* _path;
}

- (id)initWithPath:(NSString*)path name:(NSString*)name;

- (NSString*)path;

@end

extern NSString* PATH_LINK_SYMBOL;

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavDirectoryItem : FullNavFileItem
{
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavURLItem : FullNavItem
{
    NSURL* _url;
}

- (id)initWithURL:(NSURL*)url name:(NSString*)name;

- (NSURL*)URL;

@end

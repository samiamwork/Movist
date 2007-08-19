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

#import "Movist.h"

#import <QuartzCore/QuartzCore.h>

enum {
    COLUMN_ROOT,
    COLUMN_PATH,
    //COLUMN_TRAILER,
};

@class NavItem;

@interface NavColumn : NSObject
{
    int _type;          // COLUMN_*
    NSImage* _image;

    NSString* _title;
    NSMutableArray* _items; // NavItem
    int _topIndex;
    int _selectedIndex;

    CGShadingRef _shading;  // background
    CIFilter* _bgFilter;
}

- (id)initWithType:(int)type title:(NSString*)title;
- (void)addItem:(NavItem*)item;
- (void)addPathItem:(NSString*)path;

- (void)updateImage;
- (void)drawInRect:(NSRect)rect;

- (NavItem*)selectedItem;
- (void)selectUpper;
- (void)selectLower;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface NavRootColumn : NavColumn
{
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface NavPathColumn : NavColumn
{
    NSString* _path;
}

- (id)initWithPath:(NSString*)path;

@end

#endif  // _SUPPORT_FRONT_ROW

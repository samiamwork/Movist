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

enum {
    NAV_ITEM_FOLDER,
    NAV_ITEM_MOVIE,
    NAV_ITEM_MUSCI,
    //NAV_ITEM_TRAILER,
};

@interface NavItem : NSObject
{
    int _type;          // NAV_ITEM_*
    NSString* _name;
    BOOL _isContainer;
}

- (id)initWithType:(int)type name:(NSString*)name;
- (void)drawInRect:(NSRect)rect attributes:(NSDictionary*)attrs;

- (int)type;
- (NSString*)name;
- (BOOL)isContainer;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface NavPathItem : NavItem
{
    NSString* _path;
}

- (id)initWithPath:(NSString*)path;

- (NSString*)path;

@end

#endif  // _SUPPORT_FRONT_ROW

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
#import <QuartzCore/QuartzCore.h>

@class FullNavItem;
@class FullNavList;

@interface FullNavListView : NSView
{
    FullNavList* _list;
    float _itemHeight;
    NSView* _selBox;
    NSViewAnimation* _animation;

    // list fade-out gradation
    CIFilter* _tFilter;
    CIFilter* _bFilter;

    // item name fade-out gradation
    CIFilter* _lFilter;
    CIFilter* _rFilter;
    FullNavItem* _nameScrollItem;
    float _itemNameScrollSize;
    NSRect _itemNameScrollRect;
    NSTimer* _itemNameScrollTimer;
}

- (id)initWithFrame:(NSRect)frame window:(NSWindow*)window;

- (void)setNavList:(FullNavList*)list;
- (void)startItemNameScroll;
- (void)resetItemNameScroll;

- (NSView*)createSelBox;
- (void)slideSelBox;

@end

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

@class MMovieView;
@class FullNavTitleView;
@class FullNavListView;
@class FullNavItem;

@interface FullNavView : NSView
{
    NSMutableArray* _listArray;

    MMovieView* _movieView;
    NSTimer* _previewTimer;

    FullNavTitleView* _titleView;
    FullNavListView* _listView;
}

- (id)initWithFrame:(NSRect)rect movieView:(MMovieView*)movieView;

- (void)initListRoot;
- (void)addNavListWithParentItem:(FullNavItem*)parentItem items:(NSArray*)items;
- (void)removeLastNavList;

- (void)selectUpper;
- (void)selectLower;
- (void)selectMovie:(NSURL*)movieURL;

- (void)openCurrent;
- (BOOL)closeCurrent;
- (BOOL)canCloseCurrent;

- (void)showPreview;
- (void)hidePreview;
- (NSRect)previewRect;

@end

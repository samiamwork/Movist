//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#if defined(_SUPPORT_FRONT_ROW)

#import "Movist.h"
#import "FullNavItems.h"
#import "FullNavColumns.h"

@class MMovieView;

@interface FullNavView : NSView
{
    MMovieView* _movieView;
    NSMutableArray* _columns;   // NavColumn
    float _slideOffset;

    CGShadingRef _shading;  // background
}

- (id)initWithFrame:(NSRect)frameRect movieView:(MMovieView*)movieView;

- (NavItem*)selectedItem;
- (void)openSelectedItem;
- (void)closeCurrent;
- (void)selectUpper;
- (void)selectLower;

@end

#endif  // _SUPPORT_FRONT_ROW

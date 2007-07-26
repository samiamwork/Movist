//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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

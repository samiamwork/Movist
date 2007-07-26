//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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

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

#import "FullNavListView.h"

#import "FullNavView.h"
#import "FullNavItems.h"
#import "AppController.h"

@interface FullNavItem (Drawing)

- (void)drawInRect:(NSRect)rect withAttributes:(NSDictionary*)attrs
          selected:(BOOL)selected scrollSize:(float)scrollSize
          nameSize:(NSSize*)nameSize nameRect:(NSRect*)nameRect;

@end

@implementation FullNavItem (Drawing)

- (void)drawInRect:(NSRect)rect withAttributes:(NSDictionary*)attrs
          selected:(BOOL)selected scrollSize:(float)scrollSize
          nameSize:(NSSize*)nameSize nameRect:(NSRect*)nameRect
{
    float LEFT_MARGIN = 0;
    float CONTAINER_MARK_MARGIN = 10;
    float CONTAINER_MARK_WIDTH = rect.size.height / 2;
    NSSize size = [_name sizeWithAttributes:attrs];
    NSRect rc = NSMakeRect(rect.origin.x + LEFT_MARGIN,
                           rect.origin.y + (rect.size.height - size.height) / 2,
                           rect.size.width - LEFT_MARGIN,
                           size.height);
    if ([self hasSubContents]) {
        rc.size.width -= CONTAINER_MARK_MARGIN + CONTAINER_MARK_WIDTH;
    }
    if (nameSize) {
        *nameSize = size;
    }
    if (nameRect) {
        *nameRect = rc;
        //[[NSColor cyanColor] set];
        //NSFrameRect(*nameRect);
    }

    NSMutableAttributedString* name = [[NSMutableAttributedString alloc]
                                        initWithString:_name attributes:attrs];
    NSRange r = [_name rangeOfString:PATH_LINK_SYMBOL];
    if (r.location != NSNotFound) {
        r.length = [_name length] - r.location;
        [name addAttribute:NSForegroundColorAttributeName
                     value:[NSColor grayColor] range:r];
    }

    float unitSize = size.width + 100;  // gap between name & name
    scrollSize = (int)scrollSize % (int)unitSize;
    if (0 == scrollSize) {
        [name drawInRect:rc];
    }
    else {
        rc.origin.x -= scrollSize;
        rc.size.width += scrollSize;
        [name drawInRect:rc];

        if (unitSize < rc.size.width) {
            rc.origin.x += unitSize;
            rc.size.width -= unitSize;
            [name drawInRect:rc];
        }
    }
    // container mark
    if ([self hasSubContents]) {
        rc.size.height = rect.size.height / 3;
        rc.origin.y = rect.origin.y + (rect.size.height - rc.size.height) / 2;
        rc.size.width = CONTAINER_MARK_WIDTH;
        rc.origin.x = NSMaxX(rect) - rc.size.width - 8;
        float cx = rc.origin.x + rc.size.width  / 2 + 5;
        float cy = rc.origin.y + rc.size.height / 2;
        [NSGraphicsContext saveGraphicsState];
        if (selected) {
            [[NSColor whiteColor] set];
            NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
            [shadow setShadowColor:[NSColor whiteColor]];
            [shadow setShadowBlurRadius:5];
            [shadow set];
        }
        else {
            [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
        }
        [NSBezierPath setDefaultLineWidth:8];
        [NSBezierPath setDefaultLineJoinStyle:NSRoundLineJoinStyle];
        [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(cx, NSMaxY(rc))
                                  toPoint:NSMakePoint(NSMaxX(rc), cy)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(rc), cy)
                                  toPoint:NSMakePoint(cx, NSMinY(rc))];
        [NSGraphicsContext restoreGraphicsState];
    }
    //[[NSColor greenColor] set];
    //NSFrameRect(rect);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavSelBox : NSView
{
    NSImage* _bgImage;
}

- (id)initWithFrame:(NSRect)frame;

@end

@implementation FullNavSelBox

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame]) {
        NSSize size = frame.size;
        _bgImage = [[NSImage alloc] initWithSize:size];
        [_bgImage lockFocus];
            NSImage* lImage = [NSImage imageNamed:@"FSNavSelBoxLeft"];
            NSImage* cImage = [NSImage imageNamed:@"FSNavSelBoxCenter"];
            NSImage* rImage = [NSImage imageNamed:@"FSNavSelBoxRight"];
            NSRect rc;
            rc.origin.x = 0, rc.size.width = [lImage size].width;
            rc.origin.y = 0, rc.size.height = size.height;
            [lImage drawInRect:rc fromRect:NSZeroRect
                     operation:NSCompositeSourceOver fraction:1.0];
            rc.origin.x = size.width - [rImage size].width;
            rc.size.width = [rImage size].width;
            [rImage drawInRect:rc fromRect:NSZeroRect
                     operation:NSCompositeSourceOver fraction:1.0];
            rc.origin.x = [lImage size].width;
            rc.size.width = size.width - [lImage size].width - [rImage size].width;
            [cImage drawInRect:rc fromRect:NSZeroRect
                     operation:NSCompositeSourceOver fraction:1.0];
            //[[NSColor redColor] set];
            //NSFrameRect([self bounds]);
        [_bgImage unlockFocus];
    }
    return self;
}

- (void)dealloc
{
    [_bgImage release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    [_bgImage drawInRect:[self bounds] fromRect:NSZeroRect
               operation:NSCompositePlusLighter fraction:1.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavListView

#define ITEM_HSCROLL_FADE_SIZE    _itemHeight

- (id)initWithFrame:(NSRect)frame window:(NSWindow*)window
{
    if (self = [super initWithFrame:frame]) {
        _itemHeight = (float)(int)(frame.size.height / 10);

        CIColor* c0 = [CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        CIColor* c1 = [CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        CIVector* p0 = [CIVector vectorWithX:0 Y:_itemHeight];
        CIVector* p1 = [CIVector vectorWithX:0 Y:0];
        if (isSystemTiger()) { CIVector* p; p = p0, p0 = p1, p1 = p; }
        _tFilter = [[CIFilter filterWithName:@"CILinearGradient"] retain];
        [_tFilter setValue:p0 forKey:@"inputPoint0"];
        [_tFilter setValue:p1 forKey:@"inputPoint1"];
        [_tFilter setValue:c0 forKey:@"inputColor0"];
        [_tFilter setValue:c1 forKey:@"inputColor1"];

        p0 = [CIVector vectorWithX:0 Y:0];
        p1 = [CIVector vectorWithX:0 Y:_itemHeight];
        if (isSystemTiger()) { CIVector* p; p = p0, p0 = p1, p1 = p; }
        _bFilter = [[CIFilter filterWithName:@"CILinearGradient"] retain];
        [_bFilter setValue:p0 forKey:@"inputPoint0"];
        [_bFilter setValue:p1 forKey:@"inputPoint1"];
        [_bFilter setValue:c0 forKey:@"inputColor0"];
        [_bFilter setValue:c1 forKey:@"inputColor1"];

        p0 = [CIVector vectorWithX:0 Y:0];
        p1 = [CIVector vectorWithX:ITEM_HSCROLL_FADE_SIZE Y:0];
        if (isSystemTiger()) { CIVector* p; p = p0, p0 = p1, p1 = p; }
        _lFilter = [[CIFilter filterWithName:@"CILinearGradient"] retain];
        [_lFilter setValue:p0 forKey:@"inputPoint0"];
        [_lFilter setValue:p1 forKey:@"inputPoint1"];
        [_lFilter setValue:c0 forKey:@"inputColor0"];
        [_lFilter setValue:c1 forKey:@"inputColor1"];

        p0 = [CIVector vectorWithX:ITEM_HSCROLL_FADE_SIZE Y:0];
        p1 = [CIVector vectorWithX:0 Y:0];
        if (isSystemTiger()) { CIVector* p; p = p0, p0 = p1, p1 = p; }
        _rFilter = [[CIFilter filterWithName:@"CILinearGradient"] retain];
        [_rFilter setValue:p0 forKey:@"inputPoint0"];
        [_rFilter setValue:p1 forKey:@"inputPoint1"];
        [_rFilter setValue:c0 forKey:@"inputColor0"];
        [_rFilter setValue:c1 forKey:@"inputColor1"];

        _nameScrollItem = nil;
        _itemNameScrollSize = 0;
    }
    return self;
}

- (void)dealloc
{
    [_rFilter release];
    [_lFilter release];
    [_bFilter release];
    [_tFilter release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark

- (void)drawRect:(NSRect)rect
{
    //TRACE(@"%s rect=%@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    NSRect br = [self bounds];

    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];

    NSMutableDictionary* attrs;
    attrs = [[[NSMutableDictionary alloc] init] autorelease];
    [attrs setObject:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]
              forKey:NSForegroundColorAttributeName];
    [attrs setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [attrs setObject:[NSFont boldSystemFontOfSize:38 * br.size.width / 640.0]
              forKey:NSFontAttributeName];

    if ([_list count] == 0) {
        NSString* s = NSLocalizedString(@"No movie file", nil);
        NSSize size = [s sizeWithAttributes:attrs];
        NSRect r = NSMakeRect((rect.size.width  - size.width)  / 2,
                              rect.size.height * 2 / 3 - size.height,
                              size.width, size.height);
        [s drawInRect:r withAttributes:attrs];
        return;
    }

    CIContext* ciContext = [[NSGraphicsContext currentContext] CIContext];

    NSSize ns;
    NSRect r, nr;
    r.size.width = br.size.width;
    r.size.height = _itemHeight;
    r.origin.x = br.origin.x;
    r.origin.y = NSMaxY(br) - _itemHeight;
    FullNavItem* item;
    CGPoint fadePoint;
    CGRect fadeRect = CGRectMake(0, 0, ITEM_HSCROLL_FADE_SIZE, r.size.height);
    int i, count = [_list count];
    for (i = 0; i < count; i++) {
        if (NSIntersectsRect(rect, r)) {
            item = [_list itemAtIndex:i];
            if (i != [_list selectedIndex]) {
                [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
                [item drawInRect:r withAttributes:attrs selected:FALSE
                      scrollSize:0 nameSize:nil nameRect:nil];
            }
            else {
                [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
                [item drawInRect:r withAttributes:attrs selected:TRUE
                      scrollSize:_itemNameScrollSize nameSize:&ns nameRect:&nr];

                if (ns.width <= nr.size.width) {
                    _nameScrollItem = nil;
                }
                else {
                    fadePoint.y = NSMinY(r);
                    fadePoint.x = NSMinX(nr);
                    if (0 < _itemNameScrollSize) {
                        [ciContext drawImage:[_lFilter valueForKey:@"outputImage"]
                                     atPoint:fadePoint fromRect:fadeRect];
                    }
                    fadePoint.x = NSMaxX(nr) - ITEM_HSCROLL_FADE_SIZE;
                    [ciContext drawImage:[_rFilter valueForKey:@"outputImage"]
                                 atPoint:fadePoint fromRect:fadeRect];
                    if (_nameScrollItem != item) {
                        _nameScrollItem = item;
                        _itemNameScrollRect = nr;
                    }
                }
            }
        }
        r.origin.y -= r.size.height;
    }

    rect = [self visibleRect];
    if (rect.size.height < _itemHeight * count) {  // vertical scrollable
        NSRect fr = [self frame];
        if (rect.size.height < NSMaxY(fr)) {
            [ciContext drawImage:[_tFilter valueForKey:@"outputImage"]
                         atPoint:CGPointMake(NSMinX(rect), NSMaxY(rect) - _itemHeight)
                        fromRect:CGRectMake(0, 0, rect.size.width, _itemHeight)];
        }
        if (fr.origin.y < 0) {
            [ciContext drawImage:[_bFilter valueForKey:@"outputImage"]
                         atPoint:CGPointMake(NSMinX(rect), NSMinY(rect))
                        fromRect:CGRectMake(0, 0, rect.size.width, _itemHeight)];
        }
    }

    //[[NSColor yellowColor] set];
    //NSFrameRect(br);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark

- (void)startItemNameScroll
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_list selectedItem] == _nameScrollItem) {
        [NSTimer scheduledTimerWithTimeInterval:1.0
                        target:self selector:@selector(startItemNameScrollTimer:)
                        userInfo:_nameScrollItem repeats:FALSE];
    }
}

- (void)startItemNameScrollTimer:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([timer userInfo] == _nameScrollItem) {
        _itemNameScrollSize = 0;
        _itemNameScrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                    target:self selector:@selector(scrollItemName:)
                                    userInfo:_nameScrollItem repeats:TRUE];
    }
}

- (void)scrollItemName:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([timer userInfo] == _nameScrollItem) {
        _itemNameScrollSize += 1.0;
        [self setNeedsDisplayInRect:_itemNameScrollRect];
    }
}

- (void)resetItemNameScroll
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_itemNameScrollTimer invalidate];
    _itemNameScrollTimer = nil;
    _itemNameScrollSize = 0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark

- (int)topIndex
{
    NSRect rc = [[self superview] bounds];
    int visibleCount = rc.size.height / _itemHeight;
    int halfCount = visibleCount / 2 - ((visibleCount % 2) ? 0 : 1);
    int sel = [_list selectedIndex];
    if ([_list count] <= visibleCount || sel <= halfCount) {
        return 0;
    }
    else if (sel < [_list count] - visibleCount / 2) {
        return sel - halfCount;
    }
    else {
        return [_list count] - visibleCount;
    }
}

- (NSRect)calcViewRect
{
    NSRect rc = [[self superview] bounds];
    if (0 < [_list count]) {
        float height = [_list count] * _itemHeight;
        rc.origin.y = NSMaxY(rc) - height;
        rc.size.height = height;
        rc.origin.y += [self topIndex] * _itemHeight;
    }
    //TRACE(@"listViewRect=%@", NSStringFromRect(rc));
    return rc;
}

#define SEL_BOX_HMARGIN     60
#define SEL_BOX_VMARGIN     37

- (NSView*)createSelBox
{
    // cannot use -selBoxRect here because it refers _selBox.
    NSRect frame = [self bounds];
    frame.size.width += SEL_BOX_HMARGIN * 2;
    frame.size.height = _itemHeight + SEL_BOX_VMARGIN * 2;
    _selBox = [[FullNavSelBox alloc] initWithFrame:frame];
    return _selBox;
}

- (NSRect)selBoxRect
{
    if ([_list count] == 0) {
        return NSZeroRect;
    }
    else {
        NSRect rc = [[self superview] bounds];
        rc.origin.y = NSMaxY(rc) - _itemHeight -
                        ([_list selectedIndex] - [self topIndex]) * _itemHeight;
        rc.size.height = _itemHeight;
        rc = NSInsetRect(rc, -SEL_BOX_HMARGIN, -SEL_BOX_VMARGIN);
        return [[self superview] convertRect:rc toView:[_selBox superview]];
    }
}

- (void)slideSelBox
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self resetItemNameScroll];

    if (_animation && [_animation isAnimating]) {
        [_animation stopAnimation];
        [_animation release];
        _animation = nil;
    }

    NSRect frame = [self calcViewRect];
    NSRect selBoxRect = [self selBoxRect];

    NSArray* array = [NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       self, NSViewAnimationTargetKey,
                       [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       _selBox, NSViewAnimationTargetKey,
                       [NSValue valueWithRect:selBoxRect], NSViewAnimationEndFrameKey,
                       nil],
                      nil];
    NSViewAnimation* animation;
    animation = [[NSViewAnimation alloc] initWithViewAnimations:array];
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setAnimationCurve:NSAnimationLinear];
    [animation setDuration:0.2];
    [animation setDelegate:self];
    [animation startAnimation];

    _animation = animation;
}

- (void)animationDidEnd:(NSAnimation*)animation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_animation == animation) {
        [_animation release];
        _animation = nil;
    }

    [self resetItemNameScroll];
    [self startItemNameScroll];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark

- (void)setNavList:(FullNavList*)list
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self resetItemNameScroll];

    _list = list;   // no retain

    [self setFrame:[self calcViewRect]];
    [[self superview] display];
    [_selBox setFrame:[self selBoxRect]];
    [[_selBox superview] display];

    [self startItemNameScroll];  // for scrolling name of top-item
}

@end

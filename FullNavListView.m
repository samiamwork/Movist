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

@interface FullNavSelBox : NSWindow
{
}

@end

@implementation FullNavSelBox

- (id)initWithFrameRect:(NSRect)frameRect window:(NSWindow*)window
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    unsigned int styleMask = NSBorderlessWindowMask;
#if defined(AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER)
    styleMask |= NSUnscaledWindowMask;
#endif
    if (self = [super initWithContentRect:frameRect
                                styleMask:styleMask
                                  backing:NSBackingStoreBuffered
                                    defer:FALSE
                                   screen:[window screen]]) {
        [self setLevel:[window level] + 1];
        //[self setHasShadow:TRUE];
        [self setOpaque:FALSE];
        [self setAlphaValue:1.0];

        NSRect rect = [[self contentView] bounds];
        NSSize bgSize = rect.size;
        NSImage* bg = [[[NSImage alloc] initWithSize:bgSize] autorelease];
        [bg lockFocus];

        NSBezierPath* path = [NSBezierPath bezierPathWithRect:rect];
        [path setLineWidth:5.0];
        [[NSColor yellowColor] set];
        [path stroke];

        [bg unlockFocus];

        [self setBackgroundColor:[NSColor colorWithPatternImage:bg]];
    }
    return self;
}
/*
- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [super dealloc];
}
*/
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavItem (ListView)

- (void)drawInListRect:(NSRect)rect withAttributes:(NSDictionary*)attrs;

@end

@implementation FullNavItem (ListView)

- (void)drawInListRect:(NSRect)rect withAttributes:(NSDictionary*)attrs
{
    //TRACE(@"%s name=\"%@\"", __PRETTY_FUNCTION__, _name);
    float LEFT_MARGIN = 0;
    float CONTAINER_MARK_WIDTH = (float)(int)(rect.size.width * 0.085);
    NSSize size = [_name sizeWithAttributes:attrs];
    NSRect rc;
    rc.origin.x    = rect.origin.x + LEFT_MARGIN;
    rc.origin.y    = rect.origin.y + (rect.size.height - size.height) / 2;
    rc.size.width  = rect.size.width - LEFT_MARGIN - CONTAINER_MARK_WIDTH;
    rc.size.height = size.height;
    [_name drawInRect:rc withAttributes:attrs];

    if ([self hasSubContents]) {
        rc.size.width = CONTAINER_MARK_WIDTH;
        rc.origin.x = NSMaxX(rect) - rc.size.width;
        [@">" drawInRect:rc withAttributes:attrs];
    }
    //[[NSColor greenColor] set];
    //NSFrameRect(rect);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavListView (Private)

- (int)topIndex;
- (NSRect)listViewRect;
- (NSRect)selBoxRect;

@end

@implementation FullNavListView (Private)

- (int)topIndex
{
    NSRect rc = [[self superview] bounds];
    int visibleCount = rc.size.height / _listItemHeight;
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

- (NSRect)listViewRect
{
    float height = [_list count] * _listItemHeight;

    NSRect rc = [[self superview] bounds];
    rc.origin.y = NSMaxY(rc) - height;
    rc.size.height = height;
    
    rc.origin.y += [self topIndex] * _listItemHeight;
    TRACE(@"listViewRect=%@", NSStringFromRect(rc));
    return rc;
}

#define SEL_BOX_MARGIN(rc)  (float)(int)(rc.size.width * 0.05)

- (NSRect)selBoxRect
{
    if ([_list count] == 0) {
        return NSZeroRect;
    }
    else {
        NSRect rc = [[self superview] bounds];
        float margin = SEL_BOX_MARGIN(rc);
        rc.origin.x   -= margin;
        rc.size.width += margin * 2;
        rc.origin.y = NSMaxY(rc) - _listItemHeight -
                        ([_list selectedIndex] - [self topIndex]) * _listItemHeight;
        rc.size.height = _listItemHeight;
        return [[self superview] convertRect:rc toView:nil];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavListView

- (id)initWithFrame:(NSRect)frame window:(NSWindow*)window
{
    if (self = [super initWithFrame:frame]) {
        _listItemHeight = frame.size.height / 10;

        NSRect rc = [self bounds];
        rc.size.width += SEL_BOX_MARGIN(rc) * 2;
        rc.size.height = _listItemHeight;
        _selBox = [[FullNavSelBox alloc] initWithFrameRect:rc window:window];
    }
    return self;
}

- (void)dealloc
{
    [self hideSelBox];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    //TRACE(@"%s rect=%@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    NSRect br = [self bounds];

    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

    NSMutableDictionary* attrs;
    attrs = [[[NSMutableDictionary alloc] init] autorelease];
    [attrs setObject:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]
              forKey:NSForegroundColorAttributeName];
    [attrs setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [attrs setObject:[NSFont boldSystemFontOfSize:38 * br.size.width / 640.0]
              forKey:NSFontAttributeName];

    NSRect r;
    r.size.width = br.size.width;
    r.size.height = _listItemHeight;
    r.origin.x = br.origin.x;
    r.origin.y = NSMaxY(br) - _listItemHeight;
    int i, count = [_list count];
    for (i = 0; i < count; i++) {
        if (NSIntersectsRect(rect, r)) {
            if (i == [_list selectedIndex]) {
                [attrs setObject:[NSColor yellowColor]
                          forKey:NSForegroundColorAttributeName];
                [[_list itemAtIndex:i] drawInListRect:r withAttributes:attrs];
            }
            else {
                [attrs setObject:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]
                          forKey:NSForegroundColorAttributeName];
                [[_list itemAtIndex:i] drawInListRect:r withAttributes:attrs];
            }
        }
        r.origin.y -= r.size.height;
    }

    //[[NSColor yellowColor] set];
    //NSFrameRect(br);
}

- (void)setNavList:(FullNavList*)list
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _list = list;   // no retain

    [self setFrame:[self listViewRect]];
    [_selBox setFrame:[self selBoxRect] display:TRUE];
    [_selBox orderFront:self];
    [[self superview] display];
    [self display];
}

- (void)showSelBox
{
    [_selBox orderFront:self];
    [[self window] addChildWindow:_selBox ordered:NSWindowAbove];
}

- (void)hideSelBox
{
    [[self window] removeChildWindow:_selBox];
    [_selBox orderOut:self];
}

- (void)slideSelBox
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_animation && [_animation isAnimating]) {
        [_animation stopAnimation];/*
        NSArray* array = [_animation viewAnimations];
        NSDictionary* dict = [array objectAtIndex:0];
        NSValue* value = [dict objectForKey:NSViewAnimationEndFrameKey];
        [self setFrame:[value rectValue]];
        [self display];
        dict = [array objectAtIndex:1];
        value = [dict objectForKey:NSViewAnimationEndFrameKey];
        [_selBox setFrame:[value rectValue] display:TRUE];*/
        [_animation release];
    }

    NSRect frame = [self listViewRect];
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

- (void)animatioinDidEnd:(NSAnimation*)animation
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_animation == animation) {
        [_animation release];
        _animation = nil;
    }
}

@end

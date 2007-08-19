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

#import "FullNavView.h"

#import "MMovieView.h"
#import "MMovie.h"
/*
@interface SlideAnimation : NSAnimation
{
    float _initialOffset;
    float* _currentOffset;
}

- (id)initWithView:(NSView*)view offset:(float*)offset;

@end

@implementation SlideAnimation

- (id)initWithView:(NSView*)view offset:(float*)offset
{
    if (self = [super initWithDuration:0.5
                        animationCurve:NSAnimationLinear]) {
        [self setAnimationBlockingMode:NSAnimationNonblocking];
        [self setDelegate:view];

        _initialOffset = *offset;
        _currentOffset = offset;
    }
    return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    [super setCurrentProgress:progress];

    *_currentOffset = _initialOffset * progress;
    [(NSView*)[self delegate] setNeedsDisplay:TRUE];
    //[(NSView*)[self delegate] drawRect:NSZeroRect];
}

@end
*/
////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define L_MARGIN            20
#define MOVIE_VIEW_WIDTH    640

#define _FILL_BACKGROUND

#if defined(_FILL_BACKGROUND)
static void backgroundShadingFunc(void* info, const float *in, float *out)
{
    static const float c[] = { 0.3, 0.3, 0.3, 0 };
    
    size_t k, components = (size_t)info;
    
    float v = *in;
    for (k = 0; k < components - 1; k++) {
        *out++ = c[k] * v;
    }
    *out++ = 1;
}
#endif

@implementation FullNavView

- (id)initWithFrame:(NSRect)frameRect movieView:(MMovieView*)movieView
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super initWithFrame:frameRect]) {
        _movieView = [movieView retain];
        /*
        float h = 360;
        NSRect rect = [self bounds];
        rect.origin.x = L_MARGIN;
        rect.origin.y = (rect.size.height - h) / 2;
        rect.size.width = MOVIE_VIEW_WIDTH;
        rect.size.height = h;
        [self addSubview:_movieView];
        [_movieView setFrame:rect];
        */

        _columns = [[NSMutableArray alloc] initWithCapacity:4];
        [_columns addObject:[[[NavRootColumn alloc] init] autorelease]];

#if defined(_FILL_BACKGROUND)
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        const float domain[2] = { 0, 1 };
        const float range[10] = { 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 };
        const CGFunctionCallbacks callbacks = { 0, &backgroundShadingFunc, 0 };
        size_t components = 1 + CGColorSpaceGetNumberOfComponents(colorSpace);
        CGFunctionRef function = CGFunctionCreate((void*)components, 1, domain,
                                                  components, range, &callbacks);
        _shading = CGShadingCreateAxial(colorSpace,
                                        CGPointMake(0, frameRect.size.height / 2),
                                        CGPointMake(0, 0),
                                        function, FALSE, FALSE);
        CGColorSpaceRelease(colorSpace);
#endif
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
#if defined(_FILL_BACKGROUND)
    CGShadingRelease(_shading);
#endif
    [_movieView release];
    [_columns release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    TRACE(@"%s rect=%@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
#if defined(_FILL_BACKGROUND)
    NSRect br = [self bounds];
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(cgContext);
    CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1);
    CGContextFillRect(cgContext, CGRectMake(0, br.size.height / 2, br.size.width, br.size.height / 2));
    CGContextDrawShading(cgContext, _shading);
    CGContextRestoreGState(cgContext);
#endif

    float columnWidth = [[self window] frame].size.width;
    int i = [_columns count] - 1;
    NSRect columnRect = [self bounds];
    columnRect.origin.x = columnWidth * i;
    columnRect.size.width = columnWidth;
    [(NavColumn*)[_columns objectAtIndex:i] drawInRect:columnRect];
    if (0 <= --i) {
        columnRect.origin.x -= columnWidth;
        [(NavColumn*)[_columns objectAtIndex:i] drawInRect:columnRect];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NavItem*)selectedItem
{
    return [(NavColumn*)[_columns lastObject] selectedItem];
}

- (void)selectUpper
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [(NavColumn*)[_columns lastObject] selectUpper];
    [self setNeedsDisplay:TRUE];
}

- (void)selectLower
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [(NavColumn*)[_columns lastObject] selectLower];
    [self setNeedsDisplay:TRUE];
}

- (void)slideAnimation:(NSRect)frame
{
    NSArray* array = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            self, NSViewAnimationTargetKey,
            [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
            nil],
        nil];
    NSViewAnimation* animation;
    animation = [[NSViewAnimation alloc] initWithViewAnimations:array];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setAnimationCurve:NSAnimationLinear];
    [animation setDuration:0.5];
    [animation startAnimation];
    [animation release];
}

- (void)openSelectedItem
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NavItem* item = [self selectedItem];
    if ([item type] == NAV_ITEM_FOLDER) {
        NSString* path = [(NavPathItem*)item path];
        NavPathItem* item = [[NavPathColumn alloc] initWithPath:path];
        [_columns addObject:[item autorelease]];

        float dw = [[self window] frame].size.width;
        NSRect frame = [self frame];

        frame.size.width += dw;
        [self setFrame:frame];

        frame.origin.x -= dw;
        [self slideAnimation:frame];
    }
}

- (void)closeCurrent
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (1 < [_columns count]) {
        float dw = [[self window] frame].size.width;
        NSRect frame = [self frame];
        
        frame.origin.x += dw;
        [self slideAnimation:frame];

        [_columns removeLastObject];
        frame.size.width -= dw;
        [self setFrame:frame];
    }
}

@end

#endif  // _SUPPORT_FRONT_ROW

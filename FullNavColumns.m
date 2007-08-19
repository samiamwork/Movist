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

#import "MMovie.h"

//#define _USE_CORE_IMAGE
//#define _USE_QUARTZ_2D

#if defined(_USE_QUARTZ_2D)
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

#define MAX_ROW_COUNT   7

@implementation NavColumn

- (id)initWithType:(int)type title:(NSString*)title
{
    TRACE(@"%s type=%d, title=\"%@\"", __PRETTY_FUNCTION__, type, title);
    if (self = [super init]) {
        _type = type;
        _image = [[NSImage alloc] initWithSize:[[NSScreen mainScreen] frame].size];
        _title = [title retain];
        _items = [[NSMutableArray alloc] initWithCapacity:MAX_ROW_COUNT];
        _selectedIndex = -1;

#if defined(_USE_CORE_IMAGE)
        CIVector* p0 = [CIVector vectorWithX:0 Y:0];
        CIVector* p1 = [CIVector vectorWithX:0 Y:[_image size].height / 2];
        CIColor* c0 = [CIColor colorWithRed:0.3 green:0.3 blue:0.3];
        CIColor* c1 = [CIColor colorWithRed:0.0 green:0.0 blue:0.0];
        _bgFilter = [[CIFilter filterWithName:@"CILinearGradient"] retain];
        [_bgFilter setValue:p0 forKey:@"inputPoint0"];
        [_bgFilter setValue:p1 forKey:@"inputPoint1"];
        [_bgFilter setValue:c0 forKey:@"inputColor0"];
        [_bgFilter setValue:c1 forKey:@"inputColor1"];
#elif defined(_USE_QUARTZ_2D)
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        const float domain[2] = { 0, 1 };
        const float range[10] = { 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 };
        const CGFunctionCallbacks callbacks = { 0, &backgroundShadingFunc, 0 };
        size_t components = 1 + CGColorSpaceGetNumberOfComponents(colorSpace);
        CGFunctionRef function = CGFunctionCreate((void*)components, 1, domain,
                                                  components, range, &callbacks);
        _shading = CGShadingCreateAxial(colorSpace,
                                        CGPointMake(0, [_image size].height / 2),
                                        CGPointMake(0, 0),
                                        function, FALSE, FALSE);
        CGColorSpaceRelease(colorSpace);
#endif
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
#if defined(_USE_CORE_IMAGE)
    [_bgFilter release];
#elif defined(_USE_QUARTZ_2D)
    CGShadingRelease(_shading);
#endif
    [_title release];
    [_items release];
    [_image release];
    [super dealloc];
}

- (void)addItem:(NavItem*)item
{
    TRACE(@"%s name=\"%@\"", __PRETTY_FUNCTION__, [item name]);
    [_items addObject:item];

    if ([_items count] == 1) {
        _selectedIndex = 0;
    }
}

- (void)addPathItem:(NSString*)path
{
    [self addItem:[[[NavPathItem alloc] initWithPath:path] autorelease]];
}

#define L_MARGIN  20
#define M_MARGIN  25
#define MOVIE_VIEW_WIDTH    640
#define R_MARGIN  80
#define B_MARGIN  20

- (void)updateBackground:(NSRect)rect
{
#if defined(_USE_CORE_IMAGE)
    NSGraphicsContext* prevGC = [NSGraphicsContext currentContext];
    [NSGraphicsContext saveGraphicsState];
    
    NSData* tiffData = [_image TIFFRepresentation];
    NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:tiffData];
    //CFStringRef colorSpaceName = (CFStringRef)[rep colorSpaceName];
    //TRACE(@"colorSpaceName=%@", [rep colorSpaceName]);
    //CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(colorSpaceName);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    assert(colorSpace != 0);
    
    NSGraphicsContext* gc = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    assert(gc != 0);
    [NSGraphicsContext setCurrentContext:gc];
    CIContext* ciContext = [gc CIContext];
    assert(ciContext != 0);
    [ciContext drawImage:[_bgFilter valueForKey:@"outputImage"]
                 atPoint:CGPointMake(0, 0)
                fromRect:CGRectMake(0, 0, 0, rect.size.height / 2)];
    
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext setCurrentContext:prevGC];
#elif defined(_USE_QUARTZ_2D)
    NSGraphicsContext* prevGC = [NSGraphicsContext currentContext];
    [NSGraphicsContext saveGraphicsState];
    
    NSData* tiffData = [_image TIFFRepresentation];
    NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:tiffData];
    NSGraphicsContext* gc = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    [NSGraphicsContext setCurrentContext:gc];
    CGContextRef cgContext = (CGContextRef)[gc graphicsPort];
    /*
    //CFStringRef colorSpaceName = (CFStringRef)[rep colorSpaceName];
    //TRACE(@"colorSpaceName=%@", [rep colorSpaceName]);
    //CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(colorSpaceName);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    assert(colorSpace != 0);
    CGContextRef cgContext = CGBitmapContextCreate([rep bitmapData],
                                                   rect.size.width, rect.size.height,
                                                   8,//[rep bitsPerPixel] / 4,
                                                   [rep bytesPerRow],
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
     */
    assert(cgContext != 0);
    
    CGContextSaveGState(cgContext);
    CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1);
    CGContextFillRect(cgContext, CGRectMake(0, rect.size.height / 2,
                                            rect.size.width, rect.size.height / 2));
    CGContextDrawShading(cgContext, _shading);
    CGContextRestoreGState(cgContext);
    
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext setCurrentContext:prevGC];
#else
    [[NSColor clearColor] set];
    NSRectFill(rect);

    NSImage* i = [NSImage imageNamed:@"FrontRow"];
    [i drawAtPoint:NSMakePoint(rect.origin.x, rect.origin.y)
          fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

#endif
}

- (void)updateTitleInRect:(NSRect)rect attributes:(NSDictionary*)attributes
{
    //[[NSColor magentaColor] set];
    //NSFrameRect(rect);

    NSImage* icon = [NSImage imageNamed:@"Movist"];
    NSSize size = [_title sizeWithAttributes:attributes];
    float dx = [icon size].width + 16;
    size.width += dx;
    if (rect.size.width - 60 * 2 < size.width) {
        size.width = rect.size.width - 60 * 2;
    }
    NSRect rc;
    rc.origin.x = rect.origin.x + (rect.size.width - size.width ) / 2;
    rc.origin.y = rect.origin.y + (rect.size.height- size.height) / 2;
    [icon drawAtPoint:NSMakePoint(rc.origin.x, rc.origin.y)
             fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    rc.origin.x += dx;
    rc.size.width = size.width - dx;
    rc.size.height = size.height;
    [_title drawInRect:rc withAttributes:attributes];

    // title separator
    rc.size.width = rect.size.width;
    rc.size.height = 8;
    rc.origin.x = rect.origin.x;
    rc.origin.y = rect.origin.y - rc.size.height;
    [[NSColor whiteColor] set];
    NSRectFill(rc);
    //[[NSColor magentaColor] set];
    //NSFrameRect(rc);
}

- (void)updateSelectionBar:(NSRect)rect
{
    [[NSColor magentaColor] set];
    NSFrameRect(rect);

    NSImage* li = [NSImage imageNamed:@"FSSelectionLeft"];
    NSImage* mi = [NSImage imageNamed:@"FSSelectionMiddle"];
    NSImage* ri = [NSImage imageNamed:@"FSSelectionRight"];
    float x = rect.origin.x - 50;
    float w = 50 + rect.size.width + 50;
    float h = rect.size.height + 8;
    float y = rect.origin.y + (rect.size.height - h) / 2 - 5;
    [li drawInRect:NSMakeRect(x, y, [li size].width, h)
          fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [mi drawInRect:NSMakeRect(x + [li size].width, y,
                              w - [li size].width - [ri size].width, h)
          fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [ri drawInRect:NSMakeRect(x + w - [ri size].width, y, [ri size].width, h)
           fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)updateImage
{
    [_image lockFocus];

    NSRect br = NSMakeRect(0, 0, [_image size].width, [_image size].height);

    // background
    [self updateBackground:br];

    // all drawing has shadow
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:10.0];
    [shadow set];

    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSMutableDictionary* attrs;
    attrs = [[[NSMutableDictionary alloc] init] autorelease];
    [attrs setObject:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]
              forKey:NSForegroundColorAttributeName];
    [attrs setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];

    // title
    [attrs setObject:[NSFont boldSystemFontOfSize:35 * br.size.width / 640.0]
              forKey:NSFontAttributeName];
    NSRect tr = br;
    tr.size.height = 170;
    tr.origin.y = NSMaxY(br) - tr.size.height;
    [self updateTitleInRect:tr attributes:attrs];

    // items
    [attrs setObject:[NSFont boldSystemFontOfSize:27 * br.size.width / 640.0]
              forKey:NSFontAttributeName];
    NSRect ir;
    ir.origin.x = br.origin.x + L_MARGIN + MOVIE_VIEW_WIDTH + M_MARGIN;
    ir.size.width = NSMaxX(br) - NSMinX(ir) - R_MARGIN;
    ir.size.height = 132 - ir.size.height * _topIndex;
    ir.origin.y = tr.origin.y - 205;
    NavItem* item;
    unsigned int i, count = [_items count];
    for (i = _topIndex; i < count; i++) {
        item = [_items objectAtIndex:i];
        if (i == _selectedIndex) {
            [[[[NSShadow alloc] init] autorelease] set];   // no shadow
            [self updateSelectionBar:ir];
            [shadow set];       // set shadow again
        }
        [item drawInRect:ir attributes:attrs];
        ir.origin.y -= ir.size.height;
        if (ir.origin.y < B_MARGIN) {
            break;
        }
    }

    [_image unlockFocus];
}

- (void)drawInRect:(NSRect)rect
{
    NSRect srcRect = NSMakeRect(0, 0, [_image size].width, [_image size].height);
    [_image drawInRect:rect fromRect:srcRect
             operation:NSCompositeSourceOver fraction:1.0];
}

- (NavItem*)selectedItem { return [_items objectAtIndex:_selectedIndex]; }

- (void)selectUpper
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (0 < _selectedIndex) {
        _selectedIndex--;
        [self updateImage];
    }
}

- (void)selectLower
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_selectedIndex < [_items count] - 1) {
        _selectedIndex++;
        [self updateImage];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation NavRootColumn

- (id)init
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super initWithType:COLUMN_ROOT
                             title:NSLocalizedString(@"Movist", nil)]) {
        [self addPathItem:[@"~/Movies" stringByExpandingTildeInPath]];
        [self updateImage];
    }
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation NavPathColumn

- (id)initWithPath:(NSString*)path
{
    TRACE(@"%s path=\"%@\"", __PRETTY_FUNCTION__, path);
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* title = [[fm displayNameAtPath:path] lastPathComponent];
    if (self = [super initWithType:COLUMN_PATH title:title]) {
        _path = [path retain];

        NSFileManager* fm = [NSFileManager defaultManager];
        NSString* file, *itemPath;
        BOOL isDirectory;
        NSArray* contents = [fm directoryContentsAtPath:_path];
        NSEnumerator* enumerator = [contents objectEnumerator];
        while (file = [enumerator nextObject]) {
            itemPath = [_path stringByAppendingPathComponent:file];
            if ([fm isVisibleFileAtPath:itemPath isDirectory:&isDirectory] &&
                (isDirectory || [itemPath hasAnyExtension:[MMovie movieTypes]])) {
                [self addPathItem:itemPath];
            }
        }
        [self updateImage];
    }
    return self;
}

- (void)dealloc
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_path release];
    [super dealloc];
}

@end

#endif  // _SUPPORT_FRONT_ROW

//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MBarOSD.h"

@implementation MBarOSD : MMovieOSD

- (BOOL)hasContent { return (_minValue <= _value); }

- (void)clearContent
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _value = _minValue - 1.0;
    
    _updateMask |= UPDATE_TEXTURE;
}

- (void)setType:(int)type value:(float)value
       minValue:(float)minValue maxValue:(float)maxValue
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _type = type;
    _value = value;
    _minValue = minValue;
    _maxValue = maxValue;

    _updateMask |= UPDATE_SHADOW | UPDATE_TEXTURE;
}

#define BAR_HMARGIN         40
#define BAR_VMARGIN         40
#define BAR_HEIGHT          100
#define BAR_ICON_SIZE       100
#define BAR_TIME_SIZE       200
#define BAR_TRACK_MARGIN     20
#define BAR_TRACK_HEIGHT    80

- (NSRect)drawTrack:(NSSize)texSize infoSize:(float)infoSize
{
    NSRect rect = NSMakeRect(0, 0, texSize.width, texSize.height);
    rect.origin.x   +=  infoSize + BAR_TRACK_MARGIN;
    rect.size.width -= (infoSize + BAR_TRACK_MARGIN) * 2;
    rect.origin.y   += (BAR_HEIGHT - BAR_TRACK_HEIGHT) / 2;
    rect.size.height = BAR_TRACK_HEIGHT;
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:rect];

    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
    [path fill];

    [[NSColor whiteColor] set];
    [path setLineWidth:5.0];
    [path stroke];

    return rect;
}

- (void)drawVolumeBar:(NSSize)texSize
{
    // volume-down icon
    NSPoint p = NSMakePoint(0, 0);
    [[NSImage imageNamed:@"FSBVolumeDown"] drawAtPoint:p fromRect:NSZeroRect
                                operation:NSCompositeSourceOver fraction:1.0];

    // volume-up icon
    p.x = texSize.width - BAR_ICON_SIZE;
    [[NSImage imageNamed:@"FSBVolumeUp"] drawAtPoint:p fromRect:NSZeroRect
                                operation:NSCompositeSourceOver fraction:1.0];

    // volume track
    NSRect rc = [self drawTrack:texSize infoSize:BAR_ICON_SIZE];

    // volume value
    rc.origin.x += 7, rc.size.width  -= 14;
    rc.origin.y += 7, rc.size.height -= 14;
    float x = rc.origin.x + rc.size.width * _value / (_maxValue - _minValue);
    rc.size.width = x - rc.origin.x;
    [[[[NSShadow alloc] init] autorelease] set];    // clear shadow
    [[NSBezierPath bezierPathWithRect:rc] fill];
}

- (void)drawSeekBar:(NSSize)texSize
{
    // left time
    NSPoint p = NSMakePoint(0, 0);
    NSString* s = NSStringFromMovieTime(_value);
    [s drawAtPoint:p withAttributes:nil];

    // right time
    p.x = texSize.width - BAR_TIME_SIZE;
    s = NSStringFromMovieTime(_value - _maxValue);
    [s drawAtPoint:p withAttributes:nil];

    // time track
    NSRect rc = [self drawTrack:texSize infoSize:BAR_TIME_SIZE];

    // time value
    rc.origin.x += 7, rc.size.width  -= 14;
    rc.origin.y += 7, rc.size.height -= 14;
    float cx = rc.origin.x + rc.size.width * _value / (_maxValue - _minValue);
    float cy = rc.origin.y + rc.size.height / 2;
    rc.size.width  = rc.size.height;
    rc.origin.x = cx - rc.size.width / 2;
    [[[[NSShadow alloc] init] autorelease] set];    // clear shadow
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path setLineWidth:5.0];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    [path moveToPoint:NSMakePoint(cx, NSMinY(rc))];
    [path lineToPoint:NSMakePoint(NSMaxX(rc), cy)];
    [path lineToPoint:NSMakePoint(cx, NSMaxY(rc))];
    [path lineToPoint:NSMakePoint(NSMinX(rc), cy)];
    [path closePath];
    [path stroke];
    [path fill];
}

- (NSSize)updateTextureSizes
{
    if (![self hasContent]) {
        return NSMakeSize(0, 0);
    }

    _drawingSize.width  = _movieRect.size.width - BAR_HMARGIN * 2;
    _drawingSize.height = BAR_HEIGHT;
    return _drawingSize;
}

- (void)updateShadow
{
    [_shadow setShadowOffset:NSMakeSize(0, 0)];
    [_shadow setShadowBlurRadius:[self autoSize:2.0]];
    [_shadow setShadowColor:[NSColor blackColor]];
}

- (void)drawContent:(NSSize)texSize
{
    [_shadow set];
    if (_type == VOLUME_BAR) {
        [self drawVolumeBar:texSize];
    }
    else {
        [self drawSeekBar:texSize];
    }
}

- (NSRect)drawingRectForViewBounds:(NSRect)viewBounds
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    NSRect rect;
    rect.origin.x = _movieRect.origin.x + BAR_HMARGIN;
    rect.origin.y = NSMaxY(viewBounds) - BAR_VMARGIN - BAR_HEIGHT;
    rect.size.width = _movieRect.size.width - BAR_HMARGIN * 2;
    rect.size.height= BAR_HEIGHT;
    return rect;
}

@end


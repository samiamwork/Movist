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
    rc = NSInsetRect(rc, 7, 7);
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
    rc = NSInsetRect(rc, 7, 7);
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
        if (_strongShadow) {  // draw again for strong shadow
            [self drawVolumeBar:texSize];
        }
    }
    else {
        [self drawSeekBar:texSize];
        if (_strongShadow) {  // draw again for strong shadow
            [self drawVolumeBar:texSize];
        }
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


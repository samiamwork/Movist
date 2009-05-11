//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
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

#import "SeekSlider.h"

@interface SeekSliderCell : NSSliderCell
{
    NSImage* _bgImage;
    NSImage*  _lImage, * _cImage, * _rImage;
    NSImage            *_ucImage, *_urImage;
    NSColor* _rangeRepeatColor;
    NSColor* _knobColor;
    float _knobSize;
    BOOL _rounded;

    float _indexedDuration;
    float _repeatBeginning;
    float _repeatEnd;
}

- (void)setImageName:(NSString*)imageName rounded:(BOOL)rounded;
- (void)setRangeRepeatColor:(NSColor*)rangeRepeatColor;
- (void)setKnobColor:(NSColor*)knobColor;
- (void)setKnobSize:(float)knobSize;
- (void)setBgImage:(NSImage*)image;
- (float)positionOfTime:(float)time;
- (float)timeAtPosition:(float)position;

- (float)indexedDuration;
- (void)setIndexedDuration:(float)duration;

- (BOOL)repeatEnabled;
- (NSRange)repeatRange;
- (float)repeatBeginning;
- (float)repeatEnd;
- (void)setRepeatRange:(NSRange)range;
- (void)setRepeatBeginning:(float)beginning;
- (void)setRepeatEnd:(float)end;
- (void)clearRepeat;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation SeekSliderCell

- (id)init
{
    if (self = [super init]) {
        [self clearRepeat];
    }
    return self;
}

- (void)dealloc
{
    [_rangeRepeatColor release];
    [_knobColor release];
    [_ucImage release];
    [_urImage release];
    [_lImage release];
    [_cImage release];
    [_rImage release];
    [_bgImage release];

    [super dealloc];
}

- (void)setImageName:(NSString*)imageName rounded:(BOOL)rounded
{
    _lImage  = imageNamedWithPostfix(imageName, @"SeekSliderLeft");
    _cImage  = imageNamedWithPostfix(imageName, @"SeekSliderCenter");
    _rImage  = imageNamedWithPostfix(imageName, @"SeekSliderRight");
    _ucImage = imageNamedWithPostfix(imageName, @"SeekSliderUnindexedCenter");
    _urImage = imageNamedWithPostfix(imageName, @"SeekSliderUnindexedRight");
    _rounded = rounded;
}

- (void)setRangeRepeatColor:(NSColor*)color { _rangeRepeatColor = [color retain]; }
- (void)setKnobColor:(NSColor*)knobColor { _knobColor = [knobColor retain]; }
- (void)setKnobSize:(float)knobSize { _knobSize = knobSize; }
- (void)setBgImage:(NSImage*)image { _bgImage = [image retain]; }

- (float)positionOfTime:(float)time
{
    float width = [[self controlView] bounds].size.width - _knobSize;
    return width * time / ([self maxValue] - [self minValue]) + _knobSize / 2 + 1;
}

- (float)timeAtPosition:(float)position
{
    if (position < _knobSize / 2) {
        return [self minValue];
    }
    float width = [[self controlView] bounds].size.width - _knobSize;
    if (_knobSize / 2 + width <= position) {
        return [self maxValue];
    }
    return (float)(int)
        (([self maxValue] - [self minValue]) * (position - _knobSize / 2) / width);
}

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
    // hide original drawing...
    if (_bgImage) {
        [_bgImage setFlipped:flipped];
        [_bgImage drawInRect:rect fromRect:NSZeroRect
                   operation:NSCompositeSourceOver fraction:1.0];
    }
    else {
        [HUDBackgroundColor set];
        NSRectFill(rect);
    }

    // adjust track rect
    rect.origin.y += (rect.size.height - [_lImage size].height) / 2;
    rect.size.height = [_lImage size].height;
    if (!_rounded) {
        rect.origin.x += _knobSize / 2;
        rect.size.width -= _knobSize;
    }

    NSRect rc = rect;
    [_lImage setFlipped:flipped];
    [_lImage drawAtPoint:rc.origin fromRect:NSZeroRect
               operation:NSCompositeSourceOver fraction:1.0];

    rc.origin.x += [_lImage size].width;
    if (_indexedDuration == 0 || _indexedDuration == [self maxValue]) {
        rc.size.width = NSMaxX(rect) - rc.origin.x - [_rImage size].width;
        [_cImage setFlipped:flipped];
        [_cImage drawInRect:rc fromRect:NSZeroRect
                  operation:NSCompositeSourceOver fraction:1.0];
        rc.origin.x += rc.size.width;
        [_rImage setFlipped:flipped];
        [_rImage drawAtPoint:rc.origin fromRect:NSZeroRect
                   operation:NSCompositeSourceOver fraction:1.0];
    }
    else {
        float ux = [self positionOfTime:_indexedDuration];
        rc.size.width = ux - rc.origin.x;
        [_cImage setFlipped:flipped];
        [_cImage drawInRect:rc fromRect:NSZeroRect
                   operation:NSCompositeSourceOver fraction:1.0];

        [_ucImage setFlipped:flipped];
        rc.size.width = [_ucImage size].width;
        rc.origin.x = (int)ux - (int)ux % (int)rc.size.width;
        float ex = NSMaxX(rect) - [_urImage size].width;
        for (; rc.origin.x < ex; rc.origin.x += rc.size.width) {
            [_ucImage drawInRect:rc fromRect:NSZeroRect
                        operation:NSCompositeSourceOver fraction:1.0];
        }
        rc.origin.x = NSMaxX(rect) - [_urImage size].width;
        [_urImage setFlipped:flipped];
        [_urImage drawAtPoint:rc.origin fromRect:NSZeroRect
                    operation:NSCompositeSourceOver fraction:1.0];
    }

    // repeat range
    if (0 <= _repeatBeginning) {
        NSRect rc;
        rc.origin.x   = [self positionOfTime:_repeatBeginning] + 1;
        rc.origin.y   = rect.origin.y + (rect.size.height - (_knobSize - 2)) / 2;
        rc.size.width = [self positionOfTime:_repeatEnd] - 1 - rc.origin.x;
        rc.size.height= _knobSize - 2;
        [_rangeRepeatColor set];
        NSRectFill(rc);
    }
}

- (NSRect)knobRectFlipped:(BOOL)flipped
{
    float x = [self positionOfTime:[self floatValue]];
    NSRect rect = [[self controlView] bounds];
    rect.origin.x = x - _knobSize / 2 - 1;
    rect.origin.y += (rect.size.height - _knobSize) / 2;
    rect.size.width = _knobSize;
    rect.size.height= _knobSize;
    return rect;
}

- (void)drawKnob:(NSRect)knobRect
{
    if ([(NSControl*)[self controlView] isEnabled]) {
        float cx = knobRect.origin.x + knobRect.size.width  / 2;
        float cy = knobRect.origin.y + knobRect.size.height / 2;
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(cx, NSMinY(knobRect))];
        [path lineToPoint:NSMakePoint(NSMaxX(knobRect), cy)];
        [path lineToPoint:NSMakePoint(cx, NSMaxY(knobRect))];
        [path lineToPoint:NSMakePoint(NSMinX(knobRect), cy)];
        [path closePath];

        [_knobColor set];
        [path fill];
    }
}

- (float)indexedDuration { return _indexedDuration; }
- (void)setIndexedDuration:(float)duration { _indexedDuration = duration; }

- (BOOL)repeatEnabled { return (0 <= _repeatBeginning && _repeatBeginning <= _repeatEnd); }
- (NSRange)repeatRange { return NSMakeRange(_repeatBeginning, _repeatEnd - _repeatBeginning); }
- (float)repeatBeginning { return _repeatBeginning; }
- (float)repeatEnd { return _repeatEnd; }

- (void)setRepeatRange:(NSRange)range
{
    float beginning = range.location;
    if ([self minValue] <= beginning && beginning <= [self maxValue] &&
        0.0 < range.length) {
        float end = NSMaxRange(range);
        [self setRepeatBeginning:beginning];
        [self setRepeatEnd:MIN(end, [self maxValue])];
    }
    else {
        [self clearRepeat];
    }
}

- (void)setRepeatBeginning:(float)beginning
{
    _repeatBeginning = beginning;
    if (![self repeatEnabled]) {
        _repeatEnd = [self maxValue];
    }
}
- (void)setRepeatEnd:(float)end
{
    _repeatEnd = end;
    if (![self repeatEnabled]) {
        _repeatBeginning = [self minValue];
    }
}

- (void)clearRepeat { _repeatBeginning = _repeatEnd = -1; }

@end

////////////////////////////////////////////////////////////////////////////////

#import <Carbon/Carbon.h>   // for kHIWindowVisibleInAllSpaces

@implementation SeekSlider

- (void)initToolTipWithTextColor:(NSColor*)textColor backColor:(NSColor*)backColor
{
    NSPanel* window = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 58, 14)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:TRUE];
    [window setOpaque:FALSE];
    [window setAlphaValue:0.9];
    [window setBackgroundColor:backColor];
    [window setHasShadow:FALSE];
    [window setHidesOnDeactivate:TRUE];
    [window setFloatingPanel:TRUE];
    [window setLevel:[[self window] level] + 1];

    _toolTipTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [_toolTipTextField setAlignment:NSCenterTextAlignment];
    [_toolTipTextField setEditable:FALSE];
    [_toolTipTextField setSelectable:FALSE];
    [_toolTipTextField setBezeled:FALSE];
    [_toolTipTextField setBordered:FALSE];
    [_toolTipTextField setDrawsBackground:FALSE];
    [_toolTipTextField setFont:[NSFont toolTipsFontOfSize:[NSFont smallSystemFontSize]]];
    [_toolTipTextField setTextColor:textColor];
    [window setContentView:_toolTipTextField];

    _mouseTime = -1;
}

- (void)dealloc
{
    [[_toolTipTextField window] release];
    [_toolTipTextField release];
    [super dealloc];
}

- (void)mouseDown:(NSEvent*)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    float x = [(SeekSliderCell*)[self cell] positionOfTime:[self indexedDuration]];
    if (p.x <= x) {
        [super mouseDown:event];
    }
}

- (void)showMouseTimeToolTip:(NSPoint)locationInWindow
{
    [_toolTipTextField setStringValue:NSStringFromMovieTime(_mouseTime)];

    NSWindow* toolTipWindow = [_toolTipTextField window];
    NSRect r = [self convertRect:[self bounds] toView:nil];
    r.origin.x = locationInWindow.x;
    r.origin.y += r.size.height;
    r.origin = [[self window] convertBaseToScreen:r.origin];
    r.origin.x -= [toolTipWindow frame].size.width / 2;
    [toolTipWindow setFrameOrigin:r.origin];
    [toolTipWindow orderFront:self];
}

- (void)hideMouseTimeToolTip
{
    [[_toolTipTextField window] orderOut:self];

    [_toolTipTextField setStringValue:@""];
}

- (void)mouseMoved:(NSPoint)locationInWindow
{
    float t = -1;
    NSPoint p = [self convertPoint:locationInWindow fromView:nil];
    if (NSPointInRect(p, [self bounds])) {
        t = [(SeekSliderCell*)[self cell] timeAtPosition:p.x];
    }

    if (t != _mouseTime) {
        _mouseTime = t;
        if (0 <= _mouseTime && 0 < [self maxValue]) {
            [self showMouseTimeToolTip:locationInWindow];
        }
        else {
            [self hideMouseTimeToolTip];
        }
    }
}

- (float)duration { return [[self cell] maxValue]; }
- (void)setDuration:(float)duration
{
    [[self cell] setMaxValue:duration];
    if (duration == 0) {
        [self hideMouseTimeToolTip];
    }
}

- (float)indexedDuration { return [(SeekSliderCell*)[self cell] indexedDuration]; }

- (void)setIndexedDuration:(float)duration
{
    //TRACE(@"%s %.1f", __PRETTY_FUNCTION__, duration);
    [(SeekSliderCell*)[self cell] setIndexedDuration:duration];
    [self setNeedsDisplay];
}

- (BOOL)repeatEnabled    { return [(SeekSliderCell*)[self cell] repeatEnabled]; }
- (NSRange)repeatRange   { return [(SeekSliderCell*)[self cell] repeatRange]; }
- (float)repeatBeginning { return [(SeekSliderCell*)[self cell] repeatBeginning]; }
- (float)repeatEnd       { return [(SeekSliderCell*)[self cell] repeatEnd]; }

- (void)setRepeatRange:(NSRange)range
{
    //TRACE(@"%s %.1f ~ %.1f", __PRETTY_FUNCTION__, range.location, NSMaxRange(range));
    [(SeekSliderCell*)[self cell] setRepeatRange:range];
    [self setNeedsDisplay];
}

- (void)setRepeatBeginning:(float)beginning
{
    //TRACE(@"%s %.1f", __PRETTY_FUNCTION__, beginning);
    [(SeekSliderCell*)[self cell] setRepeatBeginning:beginning];
    [self setNeedsDisplay];
}

- (void)setRepeatEnd:(float)end
{
    //TRACE(@"%s %.1f", __PRETTY_FUNCTION__, end);
    [(SeekSliderCell*)[self cell] setRepeatEnd:end];
    [self setNeedsDisplay];
}

- (void)clearRepeat
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [(SeekSliderCell*)[self cell] clearRepeat];
    [self setNeedsDisplay];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MainSeekSlider

- (void)awakeFromNib
{
    [self replaceCell:[SeekSliderCell class]];
    SeekSliderCell* cell = [self cell];
    [cell setBgImage:[NSImage imageNamed:@"MainLCD"]];
    [cell setImageName:@"Main" rounded:FALSE];
    [cell setRangeRepeatColor:[NSColor colorWithCalibratedWhite:0.5 alpha:0.9]];
    [cell setKnobColor:[NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.25 alpha:1.0]];
    [cell setKnobSize:8.0];

    [self initToolTipWithTextColor:[NSColor whiteColor] backColor:HUDTitleBackColor];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowWillMiniaturize:)
               name:NSWindowWillMiniaturizeNotification object:[self window]];
}

- (void)dealloc
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];

    [super dealloc];
}

- (void)windowWillMiniaturize:(NSNotification*)notification
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (0 <= _mouseTime) {
        [self hideMouseTimeToolTip];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FSSeekSlider

- (void)awakeFromNib
{
    [self replaceCell:[SeekSliderCell class]];
    SeekSliderCell* cell = [self cell];
    [cell setImageName:@"FS" rounded:TRUE];
    [cell setRangeRepeatColor:[NSColor colorWithCalibratedWhite:0.4 alpha:0.9]];
    [cell setKnobColor:[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.0]];
    [cell setKnobSize:10.0];

    [self initToolTipWithTextColor:HUDTextColor backColor:HUDTitleBackColor];
}

@end

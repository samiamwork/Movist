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

#import "SeekSlider.h"

@interface SeekSliderCell : NSSliderCell
{
    NSImage* _bgImage;
    NSImage* _lImage, *_cImage, *_rImage;
    NSColor* _knobColor;
    float _knobSize;

    float _indexedDuration;
    float _repeatBeginning;
    float _repeatEnd;
}

- (void)draw:(NSRect)cellFrame inView:(NSView*)controlView;
- (void)setBgImage:(NSImage*)bgImage
            lImage:(NSImage*)lImage cImage:(NSImage*)cImage rImage:(NSImage*)rImage;
- (void)setKnobColor:(NSColor*)knobColor;
- (float)locationOfValue:(float)value;

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
    [_bgImage release];
    [_lImage release];
    [_cImage release];
    [_rImage release];
    [_knobColor release];
    
    [super dealloc];
}

- (void)setBgImage:(NSImage*)bgImage
            lImage:(NSImage*)lImage cImage:(NSImage*)cImage rImage:(NSImage*)rImage
{
    _bgImage = [bgImage retain];
    _lImage = [lImage retain];
    _cImage = [cImage retain];
    _rImage = [rImage retain];
}

- (void)setKnobColor:(NSColor*)knobColor
{
    _knobColor = [knobColor retain];
}

- (void)setKnobThickness:(float)thickness
{
    _knobSize = thickness;
    [super setKnobThickness:thickness];
}

- (float)locationOfValue:(float)value
{
    float width = [[self controlView] bounds].size.width - _knobSize;
    return width * value / ([self maxValue] - [self minValue]) + _knobSize / 2 + 1;
}

- (void)draw:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSRect knobRect = [self knobRectFlipped:[controlView isFlipped]];

    if (_bgImage) {
        [_bgImage setFlipped:TRUE];
        [_bgImage drawInRect:cellFrame fromRect:NSZeroRect
                  operation:NSCompositeSourceOver fraction:1.0];
    }

    NSRect trackRect;
    trackRect.size.width = cellFrame.size.width - _knobSize;
    trackRect.size.height= [_lImage size].height;
    trackRect.origin.x = cellFrame.origin.x + _knobSize / 2;
    trackRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - trackRect.size.height) / 2;

    // track
    NSRect rc;
    rc.origin.x = trackRect.origin.x, rc.size.width = [_lImage size].width;
    rc.origin.y = trackRect.origin.y, rc.size.height = trackRect.size.height;
    [_lImage setFlipped:TRUE];
    [_lImage drawInRect:rc fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];
    rc.origin.x = NSMaxX(trackRect) - [_rImage size].width;
    rc.size.width = [_rImage size].width;
    [_rImage setFlipped:TRUE];
    [_rImage drawInRect:rc fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];
    rc.origin.x = trackRect.origin.x + [_lImage size].width;
    rc.size.width = trackRect.size.width - [_lImage size].width - [_rImage size].width;
    [_cImage setFlipped:TRUE];
    [_cImage drawInRect:rc fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];

    float minY = NSMinY(trackRect) + 1;
    float maxY = NSMaxY(trackRect) - 1;
    // indexed duration
    if (_indexedDuration < [self maxValue]) {
        // FIXME
        [[NSColor colorWithCalibratedWhite:0.8 alpha:0.7] set];     // FIXME
        NSBezierPath* path = [NSBezierPath bezierPath];
        float bx = [self locationOfValue:_indexedDuration];
        float ex = [self locationOfValue:[self maxValue]];
        [path moveToPoint:NSMakePoint(bx, minY)];
        [path lineToPoint:NSMakePoint(ex, minY)];
        [path lineToPoint:NSMakePoint(ex, maxY)];
        [path lineToPoint:NSMakePoint(bx, maxY)];
        [path closePath];
        [path fill];
    }

    // repeat range
    if (0 <= _repeatBeginning) {
        [[NSColor colorWithCalibratedWhite:0.5 alpha:0.7] set];
        NSBezierPath* path = [NSBezierPath bezierPath];
        float bx = [self locationOfValue:_repeatBeginning];
        float ex = [self locationOfValue:_repeatEnd];
        [path moveToPoint:NSMakePoint(bx, minY)];
        [path lineToPoint:NSMakePoint(ex, minY)];
        [path lineToPoint:NSMakePoint(ex, maxY)];
        [path lineToPoint:NSMakePoint(bx, maxY)];
        [path closePath];
        [path fill];
    }

    // knob
    if ([(NSControl*)controlView isEnabled]) {
        /*
         NSPoint p = NSMakePoint(knobRect.origin.x + (knobRect.size.width  - 8) / 2,
                                 knobRect.origin.y + (knobRect.size.height - 8) / 2);
         NSImage* kImage = [NSImage imageNamed:@"MainSeekSliderKnob"];
         [kImage setFlipped:TRUE];
         [kImage drawAtPoint:p fromRect:NSZeroRect
                   operation:NSCompositeSourceOver fraction:1.0];
         */
        rc.size.width  = _knobSize;
        rc.size.height = _knobSize;
        rc.origin.x = knobRect.origin.x + (knobRect.size.width  - rc.size.width)  / 2;
        rc.origin.y = knobRect.origin.y + (knobRect.size.height - rc.size.height) / 2;
        NSBezierPath* path = [NSBezierPath bezierPath];
        float cx = rc.origin.x + rc.size.width  / 2;
        float cy = rc.origin.y + rc.size.height / 2;
        [_knobColor set];
        [path moveToPoint:NSMakePoint(cx, NSMinY(rc))];
        [path lineToPoint:NSMakePoint(NSMaxX(rc), cy)];
        [path lineToPoint:NSMakePoint(cx, NSMaxY(rc))];
        [path lineToPoint:NSMakePoint(NSMinX(rc), cy)];
        [path closePath];
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

@implementation SeekSlider

- (void)mouseDown:(NSEvent*)theEvent
{
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    float x = [(SeekSliderCell*)[self cell] locationOfValue:[self indexedDuration]];
    if (p.x <= x) {
        [super mouseDown:theEvent];
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

@interface MainSeekSliderCell : SeekSliderCell {} @end

@implementation MainSeekSliderCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // to calc knob rect... I don't know how to draw without super's.
    [super drawWithFrame:cellFrame inView:controlView];

    [self draw:cellFrame inView:controlView];
}

@end

@implementation MainSeekSlider

+ (void)initialize
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setCellClass:[MainSeekSliderCell class]];
}

- (void)awakeFromNib
{
    replaceSliderCell(self, [MainSeekSliderCell class]);
    SeekSliderCell* cell = [self cell];
    [cell setBgImage:[NSImage imageNamed:@"MainLCD"]
              lImage:[NSImage imageNamed:@"MainSeekSliderLeft"]
              cImage:[NSImage imageNamed:@"MainSeekSliderCenter"]
              rImage:[NSImage imageNamed:@"MainSeekSliderRight"]];
    [cell setKnobColor:[NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.25 alpha:1.0]];
    [self setKnobThickness:8.0];
}
/*
- (void)mouseMoved:(NSEvent*)theEvent
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
}
*/
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface FSSeekSliderCell : SeekSliderCell {} @end

@implementation FSSeekSliderCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // to calc knob rect... I don't know how to draw without super's.
    [super drawWithFrame:cellFrame inView:controlView];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:0.75] set];
    NSRectFill(cellFrame);

    [self draw:cellFrame inView:controlView];
}

@end

@implementation FSSeekSlider

+ (void)initialize
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setCellClass:[FSSeekSliderCell class]];
}

- (void)awakeFromNib
{
    replaceSliderCell(self, [FSSeekSliderCell class]);
    SeekSliderCell* cell = [self cell];
    [cell setBgImage:nil
              lImage:[NSImage imageNamed:@"FSSeekSliderLeft"]
              cImage:[NSImage imageNamed:@"FSSeekSliderCenter"]
              rImage:[NSImage imageNamed:@"FSSeekSliderRight"]];
    [cell setKnobColor:[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.0]];
    [self setKnobThickness:12.0];
}

@end

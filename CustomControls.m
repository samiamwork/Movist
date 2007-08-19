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

#import "CustomControls.h"

@implementation TimeTextField

- (void)drawRect:(NSRect)rect
{
    NSImage* bgImage = [NSImage imageNamed:@"MainLCD"];
    [bgImage drawInRect:[self bounds] fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];

    [super drawRect:rect];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

void replaceSliderCell(NSSlider* slider, Class sliderCellClass)
{
    if ([[slider cell] class] != sliderCellClass) {
        // replace cell
        NSSliderCell* oldCell = [slider cell];
        NSSliderCell* newCell = [[[sliderCellClass alloc] init] autorelease];
        [newCell setTarget:[oldCell target]];
        [newCell setAction:[oldCell action]];
        [newCell setType:[oldCell type]];
        [newCell setSliderType:[oldCell sliderType]];
        [newCell setTag:[oldCell tag]];
        [newCell setMaxValue:[oldCell maxValue]];
        [newCell setMinValue:[oldCell minValue]];
        [newCell setDoubleValue:[oldCell doubleValue]];
        [newCell setEnabled:[oldCell isEnabled]];
        [newCell setState:[oldCell state]];
        [newCell setControlSize:[oldCell controlSize]];
        [newCell setAllowsTickMarkValuesOnly:[oldCell allowsTickMarkValuesOnly]];
        [newCell setAltIncrementValue:[oldCell altIncrementValue]];
        [newCell setControlTint:[oldCell controlTint]];
        [newCell setKnobThickness:[oldCell knobThickness]];
        [newCell setNumberOfTickMarks:[oldCell numberOfTickMarks]];
        [newCell setEditable:[oldCell isEditable]];
        [newCell setEntryType:[oldCell entryType]];
        [newCell setFocusRingType:[oldCell focusRingType]];
        [newCell setHighlighted:[oldCell isHighlighted]];
        [newCell setTickMarkPosition:[oldCell tickMarkPosition]];
        [slider setCell:newCell];
    }
}

void drawSeekSlider(NSSliderCell* cell, NSRect cellFrame, NSView* controlView,
                    NSImage* bgImage, NSImage* lImage, NSImage* cImage, NSImage* rImage,
                    float knobSize, NSColor* knobColor,
                    float repeatBeginning, float repeatEnd,
                    float minValue, float maxValue)
{
    NSRect knobRect = [cell knobRectFlipped:[controlView isFlipped]];

    if (bgImage) {
        [bgImage setFlipped:TRUE];
        [bgImage drawInRect:cellFrame fromRect:NSZeroRect
                  operation:NSCompositeSourceOver fraction:1.0];
    }

    NSRect trackRect;
    trackRect.size.width = cellFrame.size.width - knobSize;
    trackRect.size.height= [lImage size].height;
    trackRect.origin.x = cellFrame.origin.x + knobSize / 2;
    trackRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - trackRect.size.height) / 2;

    // track
    NSRect rc;
    rc.origin.x = trackRect.origin.x, rc.size.width = [lImage size].width;
    rc.origin.y = trackRect.origin.y, rc.size.height = trackRect.size.height;
    [lImage setFlipped:TRUE];
    [lImage drawInRect:rc fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
    rc.origin.x = NSMaxX(trackRect) - [rImage size].width;
    rc.size.width = [rImage size].width;
    [rImage setFlipped:TRUE];
    [rImage drawInRect:rc fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
    rc.origin.x = trackRect.origin.x + [lImage size].width;
    rc.size.width = trackRect.size.width - [lImage size].width - [rImage size].width;
    [cImage setFlipped:TRUE];
    [cImage drawInRect:rc fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];

    // repeat range
    if (0 <= repeatBeginning && 0 <= repeatBeginning) {
        [[NSColor colorWithCalibratedWhite:0.5 alpha:0.7] set];
        NSBezierPath* path = [NSBezierPath bezierPath];
        float bx = trackRect.size.width * repeatBeginning / (maxValue - minValue) + knobSize / 2;
        float ex = trackRect.size.width * repeatEnd       / (maxValue - minValue) + knobSize / 2;
        [path moveToPoint:NSMakePoint(bx, NSMinY(trackRect))];
        [path lineToPoint:NSMakePoint(ex, NSMinY(trackRect))];
        [path lineToPoint:NSMakePoint(ex, NSMaxY(trackRect))];
        [path lineToPoint:NSMakePoint(bx, NSMaxY(trackRect))];
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
        rc.size.width  = knobSize;
        rc.size.height = knobSize;
        rc.origin.x = knobRect.origin.x + (knobRect.size.width  - rc.size.width)  / 2;
        rc.origin.y = knobRect.origin.y + (knobRect.size.height - rc.size.height) / 2;
        NSBezierPath* path = [NSBezierPath bezierPath];
        float cx = rc.origin.x + rc.size.width  / 2;
        float cy = rc.origin.y + rc.size.height / 2;
        [knobColor set];
        [path moveToPoint:NSMakePoint(cx, NSMinY(rc))];
        [path lineToPoint:NSMakePoint(NSMaxX(rc), cy)];
        [path lineToPoint:NSMakePoint(cx, NSMaxY(rc))];
        [path lineToPoint:NSMakePoint(NSMinX(rc), cy)];
        [path closePath];
        [path fill];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface SeekSliderCell : NSSliderCell
{
    float _repeatBeginning;
    float _repeatEnd;
}

- (BOOL)repeatEnabled;
- (float)repeatBeginning;
- (float)repeatEnd;
- (void)setRepeatBeginning:(float)beginning;
- (void)setRepeatEnd:(float)end;
- (void)clearRepeat;

@end

@implementation SeekSliderCell

- (id)init
{
    if (self = [super init]) {
        [self clearRepeat];
    }
    return self;
}

- (BOOL)repeatEnabled { return (0 <= _repeatBeginning && _repeatBeginning <= _repeatEnd); }
- (float)repeatBeginning { return _repeatBeginning; }
- (float)repeatEnd { return _repeatEnd; }

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

@implementation SeekSlider

- (BOOL)repeatEnabled    { return [(SeekSliderCell*)[self cell] repeatEnabled]; }
- (float)repeatBeginning { return [(SeekSliderCell*)[self cell] repeatBeginning]; }
- (float)repeatEnd       { return [(SeekSliderCell*)[self cell] repeatEnd]; }

- (void)setRepeatBeginning:(float)beginning
{
    TRACE(@"%s %.1f", __PRETTY_FUNCTION__, beginning);
    [(SeekSliderCell*)[self cell] setRepeatBeginning:beginning];
    [self setNeedsDisplay];
}

- (void)setRepeatEnd:(float)end
{
    TRACE(@"%s %.1f", __PRETTY_FUNCTION__, end);
    [(SeekSliderCell*)[self cell] setRepeatEnd:end];
    [self setNeedsDisplay];
}

- (void)clearRepeat
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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

    drawSeekSlider(self, cellFrame, controlView,
                   [NSImage imageNamed:@"MainLCD"],
                   [NSImage imageNamed:@"MainSeekSliderLeft"],
                   [NSImage imageNamed:@"MainSeekSliderCenter"],
                   [NSImage imageNamed:@"MainSeekSliderRight"],
                   8.0,
                   [NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.25 alpha:1.0],
                   _repeatBeginning, _repeatEnd, [self minValue], [self maxValue]);
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

    drawSeekSlider(self, cellFrame, controlView,
                   nil,
                   [NSImage imageNamed:@"FSSeekSliderLeft"],
                   [NSImage imageNamed:@"FSSeekSliderCenter"],
                   [NSImage imageNamed:@"FSSeekSliderRight"],
                   12.0,
                   [NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.0],
                   _repeatBeginning, _repeatEnd, [self minValue], [self maxValue]);
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
    [self setKnobThickness:12.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MainVolumeSliderCell : NSSliderCell {} @end

@implementation MainVolumeSliderCell

- (void)drawKnob:(NSRect)knobRect
{
    NSImage* image = [NSImage imageNamed:
        (![self isEnabled])     ? @"MainVolumeSliderKnobDisabled" :
        ([self mouseDownFlags]) ? @"MainVolumeSliderKnobPressed" :
        @"MainVolumeSliderKnob"];
    [image setFlipped:TRUE];
    NSPoint p = NSMakePoint(knobRect.origin.x, knobRect.origin.y + 2);
    [image drawAtPoint:p fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
}

@end

@implementation MainVolumeSlider

+ (void)initialize
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setCellClass:[MainVolumeSliderCell class]];
}

- (void)awakeFromNib
{
    replaceSliderCell(self, [MainVolumeSliderCell class]);
    [self setKnobThickness:14.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FSVolumeSlider

@end


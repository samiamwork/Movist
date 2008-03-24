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

@interface NSCell (CopyAttributes)

- (void)copyAttributesFromCell:(NSCell*)cell;

@end

@implementation NSCell (CopyAttributes)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [self setTarget:[cell target]];
    [self setAction:[cell action]];
    [self setType:[cell type]];
    [self setEnabled:[cell isEnabled]];
    [self setBezeled:[cell isBezeled]];
    [self setBordered:[cell isBordered]];
    [self setTag:[cell tag]];
    [self setState:[cell state]];
    [self setControlSize:[cell controlSize]];
    [self setControlTint:[cell controlTint]];
    [self setEditable:[cell isEditable]];
    [self setFocusRingType:[cell focusRingType]];
    [self setHighlighted:[cell isHighlighted]];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface HoverButtonCell : NSButtonCell
{
    NSImage* _hoverImage;
    NSImage* _orgImage;
}

- (void)setHoverImage:(NSImage*)image;

@end

@implementation HoverButtonCell

- (void)setHoverImage:(NSImage*)image
{
    [image retain], [_hoverImage release], _hoverImage = image;
}

- (void)mouseEntered:(NSEvent*)event
{
    if (!_orgImage && _hoverImage && [self isEnabled] &&
        [[[self controlView] window] isKeyWindow]) {
        _orgImage = [[self image] retain];
        [self setImage:_hoverImage];
    }
}

- (void)mouseExited:(NSEvent*)event
{
    if (_orgImage) {
        [self setImage:_orgImage];
        [_orgImage release];
        _orgImage = nil;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HoverButton

+ (void)initialize
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setCellClass:[HoverButtonCell class]];
}

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([[self cell] class] != [HoverButtonCell class]) {
        // replace cell
        NSButtonCell* oldCell = [self cell];
        NSButtonCell* newCell = [[[HoverButtonCell alloc] init] autorelease];
        [newCell copyAttributesFromCell:oldCell];

        // copy button attributes
        [newCell setImage:[oldCell image]];
        [newCell setAlternateImage:[oldCell alternateImage]];
        [newCell setImagePosition:[oldCell imagePosition]];
        [newCell setBackgroundColor:[oldCell backgroundColor]];
        [newCell setBezelStyle:[oldCell bezelStyle]];
        [newCell setGradientType:[oldCell gradientType]];
        [newCell setImageDimsWhenDisabled:[oldCell imageDimsWhenDisabled]];
        [newCell setTransparent:[oldCell isTransparent]];
        [self setCell:newCell];
    }
    [[self cell] setShowsBorderOnlyWhileMouseInside:TRUE];
}

- (void)setHoverImage:(NSImage*)image
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [(HoverButtonCell*)[self cell] setHoverImage:image];
}

- (void)updateHoverImage
{
    //NSPoint p = [NSEvent mouseLocation];
    NSPoint p = [[self window] mouseLocationOutsideOfEventStream];
    p = [self convertPoint:p fromView:nil];
    if (NSPointInRect(p, [self bounds])) {
        [[self cell] mouseEntered:nil];
    }
    else {
        [[self cell] mouseExited:nil];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation TimeTextField

- (void)drawRect:(NSRect)rect
{
    NSImage* bgImage = [NSImage imageNamed:@"MainLCD"];
    [bgImage drawInRect:[self bounds] fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];

    [super drawRect:rect];
}

- (void)mouseDown:(NSEvent*)event
{
    if (_clickable) {
        [[self target] performSelector:[self action] withObject:self];
    }
}

- (BOOL)isClickable { return _clickable; }
- (void)setClickable:(BOOL)clickable { _clickable = clickable; }

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

void replaceSliderCell(NSSlider* slider, Class sliderCellClass)
{
    if ([[slider cell] class] != sliderCellClass) {
        // replace cell
        NSSliderCell* oldCell = [slider cell];
        NSSliderCell* newCell = [[[sliderCellClass alloc] init] autorelease];
        [newCell copyAttributesFromCell:oldCell];
        
        // copy slider attributes
        [newCell setSliderType:[oldCell sliderType]];
        [newCell setMaxValue:[oldCell maxValue]];
        [newCell setMinValue:[oldCell minValue]];
        [newCell setDoubleValue:[oldCell doubleValue]];
        [newCell setKnobThickness:[oldCell knobThickness]];
        [newCell setTickMarkPosition:[oldCell tickMarkPosition]];
        [newCell setNumberOfTickMarks:[oldCell numberOfTickMarks]];
        [newCell setAltIncrementValue:[oldCell altIncrementValue]];
        [newCell setAllowsTickMarkValuesOnly:[oldCell allowsTickMarkValuesOnly]];
        [slider setCell:newCell];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MainVolumeSliderCell : NSSliderCell
{
    NSImage* _knobImage;
    NSImage* _knobImagePressed;
    NSImage* _knobImageDisabled;
}

- (void)setKnobImage:(NSImage*)image
        imagePressed:(NSImage*)imagePressed
       imageDisabled:(NSImage*)imageDisabled;

@end

@implementation MainVolumeSliderCell

- (void)dealloc
{
    [_knobImage release];
    [_knobImagePressed release];
    [_knobImageDisabled release];

    [super dealloc];
}

- (void)setKnobImage:(NSImage*)image
        imagePressed:(NSImage*)imagePressed
       imageDisabled:(NSImage*)imageDisabled
{
    _knobImage         = [image retain];
    _knobImagePressed  = [imagePressed retain];
    _knobImageDisabled = [imageDisabled retain];
}

- (void)drawKnob:(NSRect)knobRect
{
    NSImage* image = (![self isEnabled])     ? _knobImageDisabled :
                     ([self mouseDownFlags]) ? _knobImagePressed :
                                               _knobImage;
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
    MainVolumeSliderCell* cell = [self cell];
    [cell setKnobImage:[NSImage imageNamed:@"MainVolumeSliderKnob"]
          imagePressed:[NSImage imageNamed:@"MainVolumeSliderKnobPressed"]
         imageDisabled:[NSImage imageNamed:@"MainVolumeSliderKnobDisabled"]];
    [self setKnobThickness:14.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation FSVolumeSlider

@end


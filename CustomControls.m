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

#import "CustomControls.h"

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

- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self replaceCell:[HoverButtonCell class]];
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

@implementation MainLCDView

- (void)drawRect:(NSRect)rect
{
    NSImage* bgImage = [NSImage imageNamed:@"MainLCD"];
    [bgImage drawInRect:[self bounds] fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation TimeTextField

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

@implementation CustomSliderCell

- (void)dealloc
{
    [_backColor release];
    [_knobImage release];
    [_knobImagePressed release];
    [_knobImageDisabled release];
    [_trackImage release];
    [_trackImageDisabled release];

    [super dealloc];
}

- (void)setImageName:(NSString*)imageName backColor:(NSColor*)backColor
         trackOffset:(float)trackOffset knobOffset:(float)knobOffset
{
#define sliderImageNamed(postfix)   \
    [[NSImage imageNamed:[imageName stringByAppendingString:postfix]] retain]
    _trackImage         = sliderImageNamed(@"SliderTrack");
    _trackImageDisabled = sliderImageNamed(@"SliderTrackDisabled");
    if (!_trackImageDisabled) {
        _trackImageDisabled = [_trackImage retain];
    }
    _knobImage          = sliderImageNamed(@"SliderKnob");
    _knobImagePressed   = sliderImageNamed(@"SliderKnobPressed");
    if (!_knobImagePressed) {
        _knobImagePressed = [_knobImage retain];
    }
    _knobImageDisabled  = sliderImageNamed(@"SliderKnobDisabled");
    if (!_knobImageDisabled) {
        _knobImageDisabled = [_knobImage retain];
    }
    _backColor = [backColor retain];
    _trackOffset = trackOffset;
    _knobOffset = knobOffset;
}

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
    NSImage* track = ([self isEnabled]) ? _trackImage : _trackImageDisabled;

    rect.origin.x -= ([_trackImage size].width - rect.size.width) / 2;
    rect.origin.y += _trackOffset;
    if (_backColor) {   // hide original drawing...
        [_backColor set];
        TRACE(@"tick-count=%d", [self numberOfTickMarks]);
        if (0 < [self numberOfTickMarks]) {
            NSRect rc = rect;
            rc.size.height = 5;     // except tick marks
            NSRectFill(rc);
        }
        else {
            NSRectFill(rect);
        }
    }
    [track setFlipped:flipped];
    [track drawAtPoint:rect.origin fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)knobRectFlipped:(BOOL)flipped
{
    NSRect rect = [super knobRectFlipped:flipped];
    rect.origin.x -= ([_knobImage size].width - rect.size.width) / 2;
    rect.origin.y += _knobOffset;
    return rect;
}

- (void)drawKnob:(NSRect)knobRect
{
    NSImage* knob = (![self isEnabled]) ? _knobImageDisabled :
                    ([self mouseDownFlags]) ? _knobImagePressed : _knobImage;
    [knob setFlipped:TRUE];
    [knob drawAtPoint:knobRect.origin fromRect:NSZeroRect
            operation:NSCompositeSourceOver fraction:1.0];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDTabView

- (BOOL)mouseDownCanMoveWindow { return TRUE; }

@end

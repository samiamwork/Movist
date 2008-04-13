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

@implementation CustomButtonCell

- (void)dealloc
{
    [_rImagePressed release];
    [_rImage release];
    [_mImagePressed release];
    [_mImage release];
    [_lImagePressed release];
    [_lImage release];
    
    [super dealloc];
}

- (void)setImageName:(NSString*)imageName titleColor:(NSColor*)titleColor
         titleOffset:(float)titleOffset
{
    if ([self tag] < 0) {
        _lImage        = imageNamedWithPostfix(imageName, @"ButtonRoundLeft");
        _lImagePressed = imageNamedWithPostfix(imageName, @"ButtonRoundLeftPressed");
        _rImage        = imageNamedWithPostfix(imageName, @"ButtonFlatRight");
        _rImagePressed = imageNamedWithPostfix(imageName, @"ButtonFlatRightPressed");
    }
    else if ([self tag] == 0) {
        _lImage        = imageNamedWithPostfix(imageName, @"ButtonRoundLeft");
        _lImagePressed = imageNamedWithPostfix(imageName, @"ButtonRoundLeftPressed");
        _rImage        = imageNamedWithPostfix(imageName, @"ButtonRoundRight");
        _rImagePressed = imageNamedWithPostfix(imageName, @"ButtonRoundRightPressed");
    }
    else {  // [self tag] > 0
        _lImage        = imageNamedWithPostfix(imageName, @"ButtonFlatLeft");
        _lImagePressed = imageNamedWithPostfix(imageName, @"ButtonFlatLeftPressed");
        _rImage        = imageNamedWithPostfix(imageName, @"ButtonRoundRight");
        _rImagePressed = imageNamedWithPostfix(imageName, @"ButtonRoundRightPressed");
    }
    _mImage        = imageNamedWithPostfix(imageName, @"ButtonMid");
    _mImagePressed = imageNamedWithPostfix(imageName, @"ButtonMidPressed");

    if (0 < [[self attributedTitle] length]) {
        NSMutableAttributedString* title = [NSMutableAttributedString alloc];
        [[title initWithAttributedString:[self attributedTitle]] autorelease];
        NSRange range = NSMakeRange(0, [title length]);
        [title addAttribute:NSForegroundColorAttributeName value:titleColor range:range];
        [title removeAttribute:NSShadowAttributeName range:range];
        [self setAttributedTitle:title];
        _titleOffset = titleOffset;
    }
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView
{
    NSRect rect = frame;
    rect.origin.y += ((int)frame.size.height - (int)[_lImage size].height) / 2;
    if (_cFlags.highlighted) {
        [self drawInRect:rect leftImage:_lImagePressed
                midImage:_mImagePressed rightImage:_rImagePressed];
    }
    else {
        [self drawInRect:rect leftImage:_lImage
                midImage:_mImage rightImage:_rImage];
    }
}

- (NSRect)titleRectForBounds:(NSRect)rect
{
    rect.origin.y -= _titleOffset;
    return rect;
}
/*
- (NSRect)imageRectForBounds:(NSRect)rect
{
    rect.origin.y -= _titleOffset;
    return rect;
}
*/
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation CustomPopUpButtonCell

- (void)dealloc
{
    [_titleColor release];
    [_rImagePressed release];
    [_rImage release];
    [_mImagePressed release];
    [_mImage release];
    [_lImagePressed release];
    [_lImage release];
    
    [super dealloc];
}

- (void)setImageName:(NSString*)imageName titleColor:(NSColor*)titleColor
{
    _lImage        = imageNamedWithPostfix(imageName, @"PopUpLeft");
    _lImagePressed = imageNamedWithPostfix(imageName, @"PopUpLeftPressed");
    _mImage        = imageNamedWithPostfix(imageName, @"PopUpMid");
    _mImagePressed = imageNamedWithPostfix(imageName, @"PopUpMidPressed");
    _rImage        = imageNamedWithPostfix(imageName, @"PopUpRight");
    _rImagePressed = imageNamedWithPostfix(imageName, @"PopUpRightPressed");
    _titleColor = [titleColor retain];
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)frame inView:(NSView*)controlView
{
    if (_cFlags.highlighted) {
        [self drawInRect:frame leftImage:_lImagePressed
                midImage:_mImagePressed rightImage:_rImagePressed];
    }
    else {
        [self drawInRect:frame leftImage:_lImage
                midImage:_mImage rightImage:_rImage];
    }
}

- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect rect = [self titleRectForBounds:cellFrame];
    rect.size.width = cellFrame.size.width - rect.origin.x - 14;//[_rImage size].width;
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
        [self font], NSFontAttributeName,
        _titleColor, NSForegroundColorAttributeName,
        nil];
    [[[self selectedItem] title] drawInRect:rect withAttributes:dict];
}

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
    _trackImage         = imageNamedWithPostfix(imageName, @"SliderTrack");
    _trackImageDisabled = imageNamedWithPostfix(imageName, @"SliderTrackDisabled");
    if (!_trackImageDisabled) {
        _trackImageDisabled = [_trackImage retain];
    }
    _knobImage          = imageNamedWithPostfix(imageName, @"SliderKnob");
    _knobImagePressed   = imageNamedWithPostfix(imageName, @"SliderKnobPressed");
    if (!_knobImagePressed) {
        _knobImagePressed = [_knobImage retain];
    }
    _knobImageDisabled  = imageNamedWithPostfix(imageName, @"SliderKnobDisabled");
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
                    (_scFlags.isPressed) ? _knobImagePressed : _knobImage;
    [knob setFlipped:TRUE];
    [knob drawAtPoint:knobRect.origin fromRect:NSZeroRect
            operation:NSCompositeSourceOver fraction:1.0];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDTabView

- (BOOL)mouseDownCanMoveWindow { return TRUE; }

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDTableView

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
    [HUDTitleBackColor set];
    NSRectFill(clipRect);
}
/*
- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
}
*/
- (void)mouseDown:(NSEvent*)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    if (0 <= [self rowAtPoint:p]) {
        [super mouseDown:event];
    }
    else {
        [[self window] mouseDown:event];
    }
}

- (void)mouseUp:(NSEvent*)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    if (0 <= [self rowAtPoint:p]) {
        [super mouseUp:event];
    }
    else {
        [[self window] mouseUp:event];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDTableColumn

- (id)dataCell
{
    NSTextFieldCell* cell = [super dataCell];
    [cell setTextColor:HUDTextColor];
    return cell;
}

@end

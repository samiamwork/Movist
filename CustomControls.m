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

- (id)copyWithZone:(NSZone*)zone
{
    CustomButtonCell* cell = [super copyWithZone:zone];
    cell->_lImage        = [_lImage retain];
    cell->_lImagePressed = [_lImagePressed retain];
    cell->_mImage        = [_mImage retain];
    cell->_mImagePressed = [_mImagePressed retain];
    cell->_rImage        = [_rImage retain];
    cell->_rImagePressed = [_rImagePressed retain];
    return cell;
}

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
    if ([self isHighlighted]) {
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

@implementation CustomCheckBoxCell

- (id)copyWithZone:(NSZone*)zone
{
    CustomCheckBoxCell* cell = [super copyWithZone:zone];
    cell->_onImage          = [_onImage retain];
    cell->_onImagePressed   = [_onImagePressed retain];
    cell->_onImageDisabled  = [_onImageDisabled retain];
    cell->_offImage         = [_offImage retain];
    cell->_offImagePressed  = [_offImagePressed retain];
    cell->_offImageDisabled = [_offImageDisabled retain];
    return cell;
}

- (void)dealloc
{
    TRACE(@"%s self=0x%x onImage=0x%x", __PRETTY_FUNCTION__, self, _onImage);
    [_offImageDisabled release];
    [_offImagePressed release];
    [_offImage release];
    [_onImageDisabled release];
    [_onImagePressed release];
    [_onImage release];
    [super dealloc];
}

- (void)setImageName:(NSString*)imageName
{
    _onImage          = imageNamedWithPostfix(imageName, @"CheckBoxOn");
    _onImagePressed   = imageNamedWithPostfix(imageName, @"CheckBoxOnPressed");
    _onImageDisabled  = imageNamedWithPostfix(imageName, @"CheckBoxOnDisabled");
    if (!_onImageDisabled) {
        _onImageDisabled = [_onImage retain];
    }
    _offImage         = imageNamedWithPostfix(imageName, @"CheckBoxOff");
    _offImagePressed  = imageNamedWithPostfix(imageName, @"CheckBoxOffPressed");
    _offImageDisabled = imageNamedWithPostfix(imageName, @"CheckBoxOffDisabled");
    if (!_offImageDisabled) {
        _offImageDisabled = [_offImage retain];
    }
}

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView
{
    if ([self state]) {
        image = (![self isEnabled]) ? _onImageDisabled :
                ([self isHighlighted]) ? _onImagePressed : _onImage;
    }
    else {
        image = (![self isEnabled]) ? _offImageDisabled :
                ([self isHighlighted]) ? _offImagePressed : _offImage;
    }
    frame.origin.y++;
    [image setFlipped:TRUE];
    [image drawAtPoint:frame.origin fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation CustomPopUpButtonCell

- (id)copyWithZone:(NSZone*)zone
{
    CustomPopUpButtonCell* cell = [super copyWithZone:zone];
    cell->_lImage        = [_lImage retain];
    cell->_lImagePressed = [_lImagePressed retain];
    cell->_mImage        = [_mImage retain];
    cell->_mImagePressed = [_mImagePressed retain];
    cell->_rImage        = [_rImage retain];
    cell->_rImagePressed = [_rImagePressed retain];
    cell->_titleColor    = [_titleColor retain];
    return cell;
}

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
    if ([self isHighlighted]) {
        [self drawInRect:frame leftImage:_lImagePressed
                midImage:_mImagePressed rightImage:_rImagePressed];
    }
    else {
        [self drawInRect:frame leftImage:_lImage
                midImage:_mImage rightImage:_rImage];
    }
}

- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSRect rect = [self titleRectForBounds:cellFrame];
    rect.size.width = cellFrame.size.width - rect.origin.x - 14;//[_rImage size].width;
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [self font], NSFontAttributeName,
                           _titleColor, NSForegroundColorAttributeName,
                           nil];
    [[[self selectedItem] title] drawInRect:rect withAttributes:attrs];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation CustomSegmentedCell

- (id)copyWithZone:(NSZone*)zone
{
    CustomSegmentedCell* cell = [super copyWithZone:zone];
    cell->_lImage             = [_lImage retain];
    cell->_lImageSelected     = [_lImageSelected retain];
    cell->_mImage             = [_mImage retain];
    cell->_mImageSelected     = [_mImageSelected retain];
    cell->_rImage             = [_rImage retain];
    cell->_rImageSelected     = [_rImageSelected retain];
    cell->_sepImage           = [_sepImage retain];
    cell->_titleColor         = [_titleColor retain];
    cell->_selectedTitleColor = [_selectedTitleColor retain];
    return cell;
}

- (void)dealloc
{
    [_selectedTitleColor release];
    [_titleColor release];
    [_sepImage release];
    [_rImageSelected release];
    [_rImage release];
    [_mImageSelected release];
    [_mImage release];
    [_lImageSelected release];
    [_lImage release];
    [super dealloc];
}

- (void)setImageName:(NSString*)imageName titleColor:(NSColor*)titleColor
                                  selectedTitleColor:(NSColor*)selectedTitleColor
{
    _lImage         = imageNamedWithPostfix(imageName, @"SegmentedLeft");
    _lImageSelected = imageNamedWithPostfix(imageName, @"SegmentedLeftSelected");
    _mImage         = imageNamedWithPostfix(imageName, @"SegmentedMid");
    _mImageSelected = imageNamedWithPostfix(imageName, @"SegmentedMidSelected");
    _rImage         = imageNamedWithPostfix(imageName, @"SegmentedRight");
    _rImageSelected = imageNamedWithPostfix(imageName, @"SegmentedRightSelected");
    _sepImage       = imageNamedWithPostfix(imageName, @"SegmentedSep");
    _titleColor = [titleColor retain];
    _selectedTitleColor = [selectedTitleColor retain];
}

- (void)drawSegment:(int)segment inFrame:(NSRect)frame withView:(NSView*)controlView
{
    NSImage* lImage, *mImage, *rImage;
    NSColor* titleColor;
    if ([self selectedSegment] == segment) {
        if (segment == 0) {
            frame.origin.x -= 2, frame.size.width += 2;
            lImage = _lImageSelected, mImage = rImage = _mImageSelected;
        }
        else if (segment < [(NSSegmentedControl*)controlView segmentCount] - 1) {
            lImage = _sepImage, mImage = rImage = _mImageSelected;
        }
        else {
            frame.size.width += 2;
            lImage = _sepImage, mImage = _mImageSelected, rImage = _rImageSelected;
        }
        titleColor = _selectedTitleColor;
    }
    else {
        if (segment == 0) {
            frame.origin.x -= 2, frame.size.width += 2;
            lImage = _lImage, mImage = rImage = _mImage;
        }
        else if (segment < [(NSSegmentedControl*)controlView segmentCount] - 1) {
            lImage = _sepImage, mImage = rImage = _mImage;
        }
        else {
            frame.size.width += 2;
            lImage = _sepImage, mImage = _mImage, rImage = _rImage;
        }
        titleColor = _titleColor;
    }
    [self drawInRect:frame leftImage:lImage midImage:mImage rightImage:rImage];

    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           titleColor, NSForegroundColorAttributeName,
                           paragraphStyle, NSParagraphStyleAttributeName,
                           nil];
    frame.origin.y += 2, frame.size.height -= 2;
    [[self labelForSegment:segment] drawInRect:frame withAttributes:attrs];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation CustomSliderCell

- (id)copyWithZone:(NSZone*)zone
{
    CustomSliderCell* cell = [super copyWithZone:zone];
    cell->_backColor          = [_backColor retain];
    cell->_knobImage          = [_knobImage retain];
    cell->_knobImagePressed   = [_knobImagePressed retain];
    cell->_knobImageDisabled  = [_knobImageDisabled retain];
    cell->_trackImage         = [_trackImage retain];
    cell->_trackImageDisabled = [_trackImageDisabled retain];
    return cell;
}

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

- (id)_highlightColorForCell:(NSCell*)cell
{
    NSColor* color = [super _highlightColorForCell:cell];
	return [color colorWithAlphaComponent:[HUDBackgroundColor alphaComponent]];
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
    [HUDTitleBackColor set];
    NSRectFill(clipRect);
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    int rowIndex = [self selectedRow];
    if (0 <= rowIndex) {
        NSCell* cell = nil;
        [[self _highlightColorForCell:cell] set];
        NSRectFill([self rectOfRow:rowIndex]);
    }
}

- (void)mouseDown:(NSEvent*)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    if (0 <= [self rowAtPoint:p]) {
        [super mouseDown:event];
    }
    else {
        [self deselectAll:self];
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

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        HUDTableHeaderCell* cell = [[[HUDTableHeaderCell alloc] init] autorelease];
        [cell copyAttributesFromCell:[self headerCell]];
        [self setHeaderCell:cell];
    }
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDTableHeaderCell

- (void)setImageName:(NSString*)name
{
    _lImage = imageNamedWithPostfix(name, @"TableHeaderLeft");
    _mImage = imageNamedWithPostfix(name, @"TableHeaderMid");
    _rImage = imageNamedWithPostfix(name, @"TableHeaderRight");
}

- (id)init
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        [self setImageName:@"HUD"];
    }
    return self;
}
/*
- (id)initWithCoder:(NSCoder*)decoder
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super initWithCoder:decoder]) {
        [self setImageName:@"HUD"];
    }
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    HUDTableHeaderCell* cell = [super copyWithZone:zone];
    cell->_lImage = [_lImage retain];
    cell->_mImage = [_mImage retain];
    cell->_rImage = [_rImage retain];
    return cell;
}
*/
- (void)dealloc
{
    [_lImage release];
    [_mImage release];
    [_rImage release];
    [super dealloc];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    if (cellFrame.origin.x == 0) {
        [self drawInRect:cellFrame leftImage:_lImage midImage:_mImage rightImage:_rImage];
    }
    else {
        [self drawInRect:cellFrame leftImage:_mImage midImage:_mImage rightImage:_rImage];
    }

    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment:[self alignment]];
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           HUDTextColor, NSForegroundColorAttributeName,
                           paragraphStyle, NSParagraphStyleAttributeName,
                           nil];
    cellFrame.origin.x += 3, cellFrame.size.width -= 6;
    [[self stringValue] drawInRect:cellFrame withAttributes:attrs];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDTextFieldCell

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        [self setTextColor:HUDTextColor];
    }
    return self;
}

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    [self setTextColor:HUDTextColor];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSColor* textColor = (![self isHighlighted]) ? HUDTextColor :
                         ([NSApp isActive])      ? [NSColor controlHighlightColor] :
                                                   [NSColor controlTextColor];
    [self setTextColor:textColor];
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDButtonCell

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        [self setImageName:@"HUD" titleColor:HUDButtonTextColor titleOffset:2];
    }
    return self;
}

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    [self setImageName:@"HUD" titleColor:HUDButtonTextColor titleOffset:2];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDCheckBoxCell

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        [self setImageName:@"HUD"];
    }
    return self;
}

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];
    
    [self setImageName:@"HUD"];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDPopUpButtonCell

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        [self setImageName:@"HUD" titleColor:HUDButtonTextColor];
    }
    return self;
}

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    [self setImageName:@"HUD" titleColor:HUDButtonTextColor];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDSegmentedCell

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        [self setImageName:@"HUD" titleColor:HUDTextColor
                          selectedTitleColor:HUDButtonTextColor];
    }
    return self;
}

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    [self setImageName:@"HUD" titleColor:HUDTextColor
                      selectedTitleColor:HUDButtonTextColor];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HUDSliderCell

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        [self setImageName:@"HUD" backColor:HUDBackgroundColor
               trackOffset:2 knobOffset:0];
    }
    return self;
}

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    [self setImageName:@"HUD" backColor:HUDBackgroundColor
           trackOffset:2 knobOffset:0];
}

@end

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

#import "Movist.h"

@interface HoverButton : NSButton
{
}

- (void)setHoverImage:(NSImage*)image;
- (void)updateHoverImage;

@end

////////////////////////////////////////////////////////////////////////////////

@interface MainLCDView : NSView
{
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface TimeTextField : NSTextField
{
    BOOL _clickable;
}

- (BOOL)isClickable;
- (void)setClickable:(BOOL)clickable;

@end

////////////////////////////////////////////////////////////////////////////////

@interface CustomButtonCell : NSButtonCell
{
    NSImage* _lImage;
    NSImage* _lImagePressed;
    NSImage* _mImage;
    NSImage* _mImagePressed;
    NSImage* _rImage;
    NSImage* _rImagePressed;
    float _titleOffset;
}

- (void)setImageName:(NSString*)imageName titleColor:(NSColor*)titleColor
         titleOffset:(float)titleOffset;

@end

////////////////////////////////////////////////////////////////////////////////

@interface CustomCheckBoxCell : NSButtonCell
{
    NSImage* _onImage;
    NSImage* _onImagePressed;
    NSImage* _onImageDisabled;
    NSImage* _offImage;
    NSImage* _offImagePressed;
    NSImage* _offImageDisabled;
}

- (void)setImageName:(NSString*)imageName;

@end

////////////////////////////////////////////////////////////////////////////////

@interface CustomPopUpButtonCell : NSPopUpButtonCell
{
    NSImage* _lImage;
    NSImage* _lImagePressed;
    NSImage* _mImage;
    NSImage* _mImagePressed;
    NSImage* _rImage;
    NSImage* _rImagePressed;
    NSColor* _titleColor;
}

- (void)setImageName:(NSString*)imageName titleColor:(NSColor*)titleColor;

@end

////////////////////////////////////////////////////////////////////////////////

@interface CustomSegmentedCell : NSSegmentedCell
{
    NSImage* _lImage;
    NSImage* _lImageSelected;
    NSImage* _mImage;
    NSImage* _mImageSelected;
    NSImage* _rImage;
    NSImage* _rImageSelected;
    NSImage* _sepImage;
    NSColor* _titleColor;
    NSColor* _selectedTitleColor;
}

- (void)setImageName:(NSString*)imageName titleColor:(NSColor*)titleColor
                                  selectedTitleColor:(NSColor*)selectedTitleColor;

@end

////////////////////////////////////////////////////////////////////////////////

@interface CustomSliderCell : NSSliderCell
{
    NSImage* _trackImage;
    NSImage* _trackImageDisabled;
    NSImage* _knobImage;
    NSImage* _knobImagePressed;
    NSImage* _knobImageDisabled;
    NSColor* _backColor;
    float _trackOffset;
    float _knobOffset;
}

- (void)setImageName:(NSString*)imageName backColor:(NSColor*)backColor
         trackOffset:(float)trackOffset knobOffset:(float)knobOffset;

@end

////////////////////////////////////////////////////////////////////////////////

@interface HUDTabView : NSTabView {} @end
@interface HUDTableView : NSTableView {} @end
@interface HUDTableColumn : NSTableColumn {} @end

@interface HUDTableHeaderCell : NSTextFieldCell
{
    NSImage* _lImage;
    NSImage* _mImage;
    NSImage* _rImage;
}

@end

@interface HUDTextFieldCell : NSTextFieldCell {} @end
@interface HUDButtonCell : CustomButtonCell {} @end
@interface HUDCheckBoxCell : CustomCheckBoxCell {} @end
@interface HUDPopUpButtonCell : CustomPopUpButtonCell {} @end
@interface HUDSegmentedCell : CustomSegmentedCell {} @end
@interface HUDSliderCell : CustomSliderCell {} @end

////////////////////////////////////////////////////////////////////////////////

#define imageNamedWithPostfix(imageName, postfix)   \
    [[NSImage imageNamed:[imageName stringByAppendingString:postfix]] retain]

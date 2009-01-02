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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"
#import "MMovieView.h"

@implementation PreferenceController (Subtitle)

- (void)initSubtitlePane
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[_subtitleTabView tabViewItemAtIndex:0] setView:_subtitleDataView];
    [[_subtitleTabView tabViewItemAtIndex:1] setView:_subtitleDataView];
    [[_subtitleTabView tabViewItemAtIndex:2] setView:_subtitleDataView];
    [_subtitleEncodingPopUpButton removeAllItems];
    initSubtitleEncodingMenu([_subtitleEncodingPopUpButton menu], nil);

    [_subtitleEnableButton setState:[_defaults boolForKey:MSubtitleEnableKey]];

    _subtitleIndex = [[_defaults objectForKey:MPrefsSubtitleTabKey] intValue];
    _subtitleIndex = adjustToRange(_subtitleIndex, 0, 2);
    [_subtitleTabView selectTabViewItemAtIndex:_subtitleIndex];

    int textEncoding = [_defaults integerForKey:MSubtitleEncodingKey];
    [_subtitleEncodingPopUpButton selectItemWithTag:textEncoding];

    [self updateSubtitleDataView];

    int height = [_defaults integerForKey:MLetterBoxHeightKey];
    [_letterBoxHeightPopUpButton selectItemWithTag:height];

    float screenMargin = [_defaults floatForKey:MSubtitleScreenMarginKey];
    [_subtitleScreenMarginSlider setFloatValue:screenMargin];
    [_subtitleScreenMarginTextField setFloatValue:screenMargin];
}

- (IBAction)subtitleEnableAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL subtitleEnable = [_subtitleEnableButton state];
    [_defaults setBool:subtitleEnable forKey:MSubtitleEnableKey];
    
    [_appController setSubtitleEnable:subtitleEnable];
}

- (void)updateSubtitleDataView
{
    [self updateSubtitleFontAndSizeUI];

    NSColor* textColor = [_defaults colorForKey:MSubtitleTextColorKey[_subtitleIndex]];
    [_subtitleTextColorWell setColor:textColor];
    [_subtitleTextOpacitySlider setFloatValue:[textColor alphaComponent]];
    [_subtitleTextOpacityTextField setFloatValue:[textColor alphaComponent]];

    NSColor* strokeColor = [_defaults colorForKey:MSubtitleStrokeColorKey[_subtitleIndex]];
    float strokeWidth = [_defaults floatForKey:MSubtitleStrokeWidthKey[_subtitleIndex]];
    [_subtitleStrokeColorWell setColor:strokeColor];
    [_subtitleStrokeOpacitySlider setFloatValue:[strokeColor alphaComponent]];
    [_subtitleStrokeOpacityTextField setFloatValue:[strokeColor alphaComponent]];
    [_subtitleStrokeWidthSlider setFloatValue:strokeWidth];
    [_subtitleStrokeWidthTextField setFloatValue:strokeWidth];

    NSColor* shadowColor = [_defaults colorForKey:MSubtitleShadowColorKey[_subtitleIndex]];
    float shadowBlur = [_defaults floatForKey:MSubtitleShadowBlurKey[_subtitleIndex]];
    float shadowOffset = [_defaults floatForKey:MSubtitleShadowOffsetKey[_subtitleIndex]];
    int shadowDarkness = [_defaults integerForKey:MSubtitleShadowDarknessKey[_subtitleIndex]];
    [_subtitleShadowColorWell setColor:shadowColor];
    [_subtitleShadowOpacitySlider setFloatValue:[shadowColor alphaComponent]];
    [_subtitleShadowOpacityTextField setFloatValue:[shadowColor alphaComponent]];
    [_subtitleShadowBlurSlider setFloatValue:shadowBlur];
    [_subtitleShadowBlurTextField setFloatValue:shadowBlur];
    [_subtitleShadowOffsetSlider setFloatValue:shadowOffset];
    [_subtitleShadowOffsetTextField setFloatValue:shadowOffset];
    [_subtitleShadowDarknessSlider setIntValue:shadowDarkness];
    [_subtitleShadowDarknessTextField setIntValue:shadowDarkness];

    int position = [_defaults integerForKey:MSubtitleVPositionKey[_subtitleIndex]];
    [_subtitlePositionPopUpButton selectItemWithTag:position];

    float hMargin = [_defaults floatForKey:MSubtitleHMarginKey[_subtitleIndex]];
    [_subtitleHMarginSlider setFloatValue:hMargin];
    [_subtitleHMarginTextField setFloatValue:hMargin];

    float vMargin = [_defaults floatForKey:MSubtitleVMarginKey[_subtitleIndex]];
    [_subtitleVMarginSlider setFloatValue:vMargin];
    [_subtitleVMarginTextField setFloatValue:vMargin];

    float lineSpacing = [_defaults floatForKey:MSubtitleLineSpacingKey[_subtitleIndex]];
    [_subtitleLineSpacingSlider setFloatValue:lineSpacing];
    [_subtitleLineSpacingTextField setFloatValue:lineSpacing];
}

- (void)updateSubtitleFontAndSizeUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithCapacity:3];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    [attrs setObject:[paragraphStyle autorelease] forKey:NSParagraphStyleAttributeName];
    
    NSString* name = [_defaults stringForKey:MSubtitleFontNameKey[_subtitleIndex]];
    float size = [_defaults floatForKey:MSubtitleFontSizeKey[_subtitleIndex]];
    NSFont* font = [NSFont fontWithName:name size:MIN(size, 20.0)];
    if (font) {
        [attrs setObject:font forKey:NSFontAttributeName];
    }
    NSString* title = [NSString localizedStringWithFormat:@"%@ %g", [font displayName], size];
    NSMutableAttributedString* mas = [[NSMutableAttributedString alloc]
                                      initWithString:title attributes:attrs];
    BOOL autoFontSize = [_defaults boolForKey:MSubtitleAutoFontSizeKey[_subtitleIndex]];
    if (autoFontSize) {
        NSRange range;
        range.location = [[font displayName] length] + 1;
        range.length = [title length] - range.location;
        [mas addAttribute:NSForegroundColorAttributeName
                    value:[NSColor disabledControlTextColor]
                    range:range];
    }
    [_subtitleFontButton setAttributedTitle:[mas autorelease]];
    
    int chars = [_defaults integerForKey:MSubtitleAutoFontSizeCharsKey[_subtitleIndex]];
    [_subtitleAutoFontSizeButton setState:autoFontSize];
    [_subtitleAutoFontSizeLabelTextField setEnabled:autoFontSize];
    [_subtitleAutoFontSizeTextField setEnabled:autoFontSize];
    [_subtitleAutoFontSizeTextField setEditable:autoFontSize];
    [_subtitleAutoFontSizeTextField setIntValue:chars];
    [_subtitleAutoFontSizeStepper setEnabled:autoFontSize];
    [_subtitleAutoFontSizeStepper setIntValue:chars];
}

- (IBAction)subtitleEncodingAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    CFStringEncoding encoding = [[sender selectedItem] tag];
    [_defaults setInteger:encoding forKey:MSubtitleEncodingKey];
    [_appController reopenSubtitles];
}

- (IBAction)subtitleFontAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[self window] makeFirstResponder:nil];

    NSString* name = [_defaults stringForKey:MSubtitleFontNameKey[_subtitleIndex]];
    float size = [_defaults floatForKey:MSubtitleFontSizeKey[_subtitleIndex]];
    NSFont* font = [NSFont fontWithName:name size:size];

    NSFontManager* fontManager = [NSFontManager sharedFontManager];
    [fontManager setDelegate:self];
    [fontManager orderFrontFontPanel:self];
    [fontManager setSelectedFont:font isMultiple:FALSE];
}

- (float)fontSizeForAutoFontSizeChars:(int)chars
{
    NSString* testChar = NSLocalizedString(@"SubtitleTestChar", nil);
    NSMutableString* s = [NSMutableString stringWithCapacity:100];
    int i;
    for (i = 0; i < chars; i++) {
        [s appendString:testChar];
    }
    NSMutableAttributedString* mas = [[NSMutableAttributedString alloc] initWithString:s];
    NSRange range = NSMakeRange(0, [s length]);

    NSFont* font;
    NSSize maxSize = NSMakeSize(10000, 10000);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin |
                                     NSStringDrawingUsesFontLeading |
                                     NSStringDrawingUsesDeviceMetrics;
    NSString* fontName = [_defaults stringForKey:MSubtitleFontNameKey[_subtitleIndex]];
    float hMargin = [_defaults floatForKey:MSubtitleHMarginKey[_subtitleIndex]] / 100.0;    // percentage
    float width, maxWidth = 640.0 - (640.0 * hMargin) * 2;
    float fontSize = 10;
    while (TRUE) {
        font = [NSFont fontWithName:fontName size:fontSize];
        [mas addAttribute:NSFontAttributeName value:font range:range];
        width = [mas boundingRectWithSize:maxSize options:options].size.width;
        if (maxWidth < width) {
            fontSize--;
            break;
        }
        fontSize++;
    };
    [mas release];

    return fontSize;
}

- (void)updateFontSizeForAutoFontSizeChars
{
    int chars = [_defaults integerForKey:MSubtitleAutoFontSizeCharsKey[_subtitleIndex]];
    float fontSize = [self fontSizeForAutoFontSizeChars:chars];
    [_defaults setFloat:fontSize forKey:MSubtitleFontSizeKey[_subtitleIndex]];

    [self updateSubtitleFontAndSizeUI];

    SubtitleAttributes attrs;
    attrs.fontName = [_defaults stringForKey:MSubtitleFontNameKey[_subtitleIndex]];
    attrs.fontSize = fontSize;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT;
    [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
}

- (IBAction)subtitleAutoFontSizeAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL autoFontSize = [_subtitleAutoFontSizeButton state];
    [_defaults setBool:autoFontSize
                forKey:MSubtitleAutoFontSizeKey[_subtitleIndex]];

    if (autoFontSize) {
        [self updateFontSizeForAutoFontSizeChars];
    }
    else {
        [self updateSubtitleFontAndSizeUI];
    }
}

- (IBAction)subtitleAutoFontSizeCharsAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setInteger:[sender intValue]
                   forKey:MSubtitleAutoFontSizeCharsKey[_subtitleIndex]];

    [self updateFontSizeForAutoFontSizeChars];
}

- (void)changeFont:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* name = [_defaults stringForKey:MSubtitleFontNameKey[_subtitleIndex]];
    float size = [_defaults floatForKey:MSubtitleFontSizeKey[_subtitleIndex]];
    NSFont* font = [sender convertFont:[NSFont fontWithName:name size:size]];

    float fontSize = [font pointSize];
    if ([_defaults boolForKey:MSubtitleAutoFontSizeKey[_subtitleIndex]]) {
        fontSize = [_defaults floatForKey:MSubtitleFontSizeKey[_subtitleIndex]];
    }
    [_defaults setObject:[font fontName] forKey:MSubtitleFontNameKey[_subtitleIndex]];
    [_defaults setFloat:fontSize forKey:MSubtitleFontSizeKey[_subtitleIndex]];
    [self updateSubtitleFontAndSizeUI];

    SubtitleAttributes attrs;
    attrs.fontName = [font fontName];
    attrs.fontSize = fontSize;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT;
    [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
}

- (IBAction)subtitleAttributesAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    enum {
        SUBTITLE_TEXT_COLOR,
        SUBTITLE_TEXT_OPACITY,
        SUBTITLE_STROKE_COLOR,
        SUBTITLE_STROKE_OPACITY,
        SUBTITLE_STROKE_WIDTH,
        SUBTITLE_SHADOW_COLOR,
        SUBTITLE_SHADOW_OPACITY,
        SUBTITLE_SHADOW_OFFSET,
        SUBTITLE_SHADOW_DARKNESS,
        SUBTITLE_SHADOW_BLUR,
    };

    switch ([sender tag]) {
        case SUBTITLE_TEXT_COLOR :
        case SUBTITLE_TEXT_OPACITY : {
            NSColor* c = [_subtitleTextColorWell color];
            NSColor* textColor = [NSColor colorWithCalibratedRed:[c redComponent]
                                    green:[c greenComponent] blue:[c blueComponent]
                                    alpha:[_subtitleTextOpacitySlider floatValue]];
            [_subtitleTextColorWell setColor:textColor];
            [_subtitleTextOpacityTextField setFloatValue:[textColor alphaComponent]];
            [_defaults setColor:textColor forKey:MSubtitleTextColorKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.textColor = textColor;
            attrs.mask = SUBTITLE_ATTRIBUTE_TEXT_COLOR;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_STROKE_COLOR :
        case SUBTITLE_STROKE_OPACITY : {
            NSColor* c = [_subtitleStrokeColorWell color];
            NSColor* strokeColor = [NSColor colorWithCalibratedRed:[c redComponent]
                                    green:[c greenComponent] blue:[c blueComponent]
                                    alpha:[_subtitleStrokeOpacitySlider floatValue]];
            [_subtitleStrokeColorWell setColor:strokeColor];
            [_subtitleStrokeOpacityTextField setFloatValue:[strokeColor alphaComponent]];
            [_defaults setColor:strokeColor forKey:MSubtitleStrokeColorKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.strokeColor = strokeColor;
            attrs.mask = SUBTITLE_ATTRIBUTE_STROKE_COLOR;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_STROKE_WIDTH : {
            float strokeWidth = normalizedFloat1([_subtitleStrokeWidthSlider floatValue]);
            [_subtitleStrokeWidthTextField setFloatValue:strokeWidth];
            [_defaults setFloat:strokeWidth forKey:MSubtitleStrokeWidthKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.strokeWidth = strokeWidth;
            attrs.mask = SUBTITLE_ATTRIBUTE_STROKE_WIDTH;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_SHADOW_COLOR :
        case SUBTITLE_SHADOW_OPACITY : {
            NSColor* c = [_subtitleShadowColorWell color];
            NSColor* shadowColor = [NSColor colorWithCalibratedRed:[c redComponent]
                                    green:[c greenComponent] blue:[c blueComponent]
                                    alpha:[_subtitleShadowOpacitySlider floatValue]];
            [_subtitleShadowColorWell setColor:shadowColor];
            [_subtitleShadowOpacityTextField setFloatValue:[shadowColor alphaComponent]];
            [_defaults setColor:shadowColor forKey:MSubtitleShadowColorKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.shadowColor = shadowColor;
            attrs.mask = SUBTITLE_ATTRIBUTE_SHADOW_COLOR;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_SHADOW_OFFSET : {
            float shadowOffset = normalizedFloat1([_subtitleShadowOffsetSlider floatValue]);
            [_subtitleShadowOffsetTextField setFloatValue:shadowOffset];
            [_defaults setFloat:shadowOffset forKey:MSubtitleShadowOffsetKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.shadowOffset = shadowOffset;
            attrs.mask = SUBTITLE_ATTRIBUTE_SHADOW_OFFSET;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_SHADOW_DARKNESS : {
            float shadowDarkness = (float)[_subtitleShadowDarknessSlider intValue];
            [_subtitleShadowDarknessTextField setIntValue:shadowDarkness];
            [_defaults setInteger:shadowDarkness forKey:MSubtitleShadowDarknessKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.shadowDarkness = shadowDarkness;
            attrs.mask = SUBTITLE_ATTRIBUTE_SHADOW_DARKNESS;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_SHADOW_BLUR : {
            float shadowBlur = normalizedFloat1([_subtitleShadowBlurSlider floatValue]);
            [_subtitleShadowBlurTextField setFloatValue:shadowBlur];
            [_defaults setFloat:shadowBlur forKey:MSubtitleShadowBlurKey[_subtitleIndex]];
            SubtitleAttributes attrs;
            attrs.shadowBlur = shadowBlur;
            attrs.mask = SUBTITLE_ATTRIBUTE_SHADOW_BLUR;
            [_movieView setSubtitleAttributes:&attrs atIndex:_subtitleIndex];
            break;
        }
    }
}

- (IBAction)subtitlePositionAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    enum {
        SUBTITLE_V_POSITION,
        SUBTITLE_H_MARGIN,
        SUBTITLE_V_MARGIN,
        SUBTITLE_LINE_SPACING,
    };

    switch ([sender tag]) {
        case SUBTITLE_V_POSITION : {
            int position = [[_subtitlePositionPopUpButton selectedItem] tag];
            [_defaults setInteger:position forKey:MSubtitleVPositionKey[_subtitleIndex]];
            [_appController setSubtitlePosition:position atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_H_MARGIN : {
            float hMargin = [_subtitleHMarginSlider floatValue];
            [_subtitleHMarginTextField setFloatValue:hMargin];
            [_defaults setFloat:hMargin forKey:MSubtitleHMarginKey[_subtitleIndex]];
            [_appController setSubtitleHMargin:hMargin atIndex:_subtitleIndex];
            if ([_defaults boolForKey:MSubtitleAutoFontSizeKey[_subtitleIndex]]) {
                [self updateFontSizeForAutoFontSizeChars];
            }
            break;
        }
        case SUBTITLE_V_MARGIN : {
            float vMargin = [_subtitleVMarginSlider floatValue];
            [_subtitleVMarginTextField setFloatValue:vMargin];
            [_defaults setFloat:vMargin forKey:MSubtitleVMarginKey[_subtitleIndex]];
            [_appController setSubtitleVMargin:vMargin atIndex:_subtitleIndex];
            break;
        }
        case SUBTITLE_LINE_SPACING : {
            float spacing = [_subtitleLineSpacingSlider floatValue];
            [_subtitleLineSpacingTextField setFloatValue:spacing];
            [_defaults setFloat:spacing forKey:MSubtitleLineSpacingKey[_subtitleIndex]];
            [_appController setSubtitleLineSpacing:spacing atIndex:_subtitleIndex];
            break;
        }
    }
}

- (IBAction)letterBoxHeightAction:(id)sender
{
    int height = [[_letterBoxHeightPopUpButton selectedItem] tag];
    [_defaults setInteger:height forKey:MLetterBoxHeightKey];
    [_appController setLetterBoxHeight:height];
}

- (IBAction)subtitleScreenMarginAction:(id)sender
{
    float screenMargin = [_subtitleScreenMarginSlider floatValue];
    [_subtitleScreenMarginTextField setFloatValue:screenMargin];
    [_defaults setFloat:screenMargin forKey:MSubtitleScreenMarginKey];
    [_appController setSubtitleScreenMargin:screenMargin];
}

@end

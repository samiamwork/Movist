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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"
#import "MMovieView.h"

@implementation PreferenceController (Subtitle)

- (void)initSubtitlePane
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleEnableButton setState:[_defaults boolForKey:MSubtitleEnableKey]];
    [self initSubtitleEncodingPopUpButton];

    [self updateSubtitleFontAndSizeUI];

    NSColor* textColor = [_defaults colorForKey:MSubtitleTextColorKey];
    [_subtitleTextColorWell setColor:textColor];
    [_subtitleTextOpacitySlider setFloatValue:[textColor alphaComponent]];
    [_subtitleTextOpacityTextField setFloatValue:[textColor alphaComponent]];

    NSColor* strokeColor = [_defaults colorForKey:MSubtitleStrokeColorKey];
    float strokeWidth = [_defaults floatForKey:MSubtitleStrokeWidthKey];
    [_subtitleStrokeColorWell setColor:strokeColor];
    [_subtitleStrokeOpacitySlider setFloatValue:[strokeColor alphaComponent]];
    [_subtitleStrokeOpacityTextField setFloatValue:[strokeColor alphaComponent]];
    [_subtitleStrokeWidthSlider setFloatValue:strokeWidth];
    [_subtitleStrokeWidthTextField setFloatValue:strokeWidth];

    NSColor* shadowColor = [_defaults colorForKey:MSubtitleShadowColorKey];
    float shadowBlur = [_defaults floatForKey:MSubtitleShadowBlurKey];
    float shadowOffset = [_defaults floatForKey:MSubtitleShadowOffsetKey];
    int shadowDarkness = [_defaults integerForKey:MSubtitleShadowDarknessKey];
    [_subtitleShadowColorWell setColor:shadowColor];
    [_subtitleShadowOpacitySlider setFloatValue:[shadowColor alphaComponent]];
    [_subtitleShadowOpacityTextField setFloatValue:[shadowColor alphaComponent]];
    [_subtitleShadowBlurSlider setFloatValue:shadowBlur];
    [_subtitleShadowBlurTextField setFloatValue:shadowBlur];
    [_subtitleShadowOffsetSlider setFloatValue:shadowOffset];
    [_subtitleShadowOffsetTextField setFloatValue:shadowOffset];
    [_subtitleShadowDarknessSlider setFloatValue:shadowDarkness];
    [_subtitleShadowDarknessTextField setFloatValue:shadowDarkness];

    [_subtitleDisplayOnLetterBoxButton setState:[_defaults boolForKey:MSubtitleDisplayOnLetterBoxKey]];

    float minLetterBoxHeight = [_defaults floatForKey:MSubtitleMinLetterBoxHeightKey];
    [_subtitleMinLetterBoxHeightSlider setFloatValue:minLetterBoxHeight];
    [_subtitleMinLetterBoxHeightTextField setIntValue:(int)minLetterBoxHeight];

    float hMargin = [_defaults floatForKey:MSubtitleHMarginKey];
    [_subtitleHMarginSlider setFloatValue:hMargin];
    [_subtitleHMarginTextField setFloatValue:hMargin];

    float vMargin = [_defaults floatForKey:MSubtitleVMarginKey];
    [_subtitleVMarginSlider setFloatValue:vMargin];
    [_subtitleVMarginTextField setFloatValue:vMargin];

    [_subtitleReplaceNLWithBRButton setState:[_defaults boolForKey:MSubtitleReplaceNLWithBRKey]];
}

- (IBAction)subtitleEnbleAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL subtitleEnable = [_subtitleEnableButton state];
    [_defaults setBool:subtitleEnable forKey:MSubtitleEnableKey];

    [_appController setSubtitleEnable:subtitleEnable];
}

- (IBAction)subtitleEncodingAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setInteger:[[sender selectedItem] tag] forKey:MSubtitleEncodingKey];
    [_appController reopenSubtitle];
}

- (IBAction)subtitleFontAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [[self window] makeFirstResponder:nil];

    NSFont* font = [NSFont fontWithName:[_defaults stringForKey:MSubtitleFontNameKey]
                                   size:[_defaults floatForKey:MSubtitleFontSizeKey]];

    NSFontManager* fontManager = [NSFontManager sharedFontManager];
    [fontManager setDelegate:self];
    [fontManager orderFrontFontPanel:self];
    [fontManager setSelectedFont:font isMultiple:FALSE];
}

- (float)fontSizeForAutoFontSizeChars:(int)chars
{
    /*
    NSFont* font;
    NSString* fontName = [_defaults stringForKey:MSubtitleFontNameKey];
    float fontSize = 10;
    float hMargin = [_defaults floatForKey:MSubtitleHMarginKey] / 100.0;    // percentage
    float width, maxWidth = 640.0 - (640.0 * hMargin) * 2;
    while (TRUE) {
        font = [NSFont fontWithName:fontName size:fontSize];
        width = [font boundingRectForFont].size.width * chars;
        if (maxWidth < width) {
            fontSize--;
            break;
        }
        fontSize++;
    };

    return fontSize;
     */

    NSString* testChar = NSLocalizedString(@"SubtitleAutoSizeTestChar", nil);
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
    NSString* fontName = [_defaults stringForKey:MSubtitleFontNameKey];
    float fontSize = 10;
    float hMargin = [_defaults floatForKey:MSubtitleHMarginKey] / 100.0;    // percentage
    float width, maxWidth = 640.0 - (640.0 * hMargin) * 2;
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
    int chars = [_defaults integerForKey:MSubtitleAutoFontSizeCharsKey];
    float fontSize = [self fontSizeForAutoFontSizeChars:chars];
    [_defaults setFloat:fontSize forKey:MSubtitleFontSizeKey];

    [self updateSubtitleFontAndSizeUI];

    [_movieView setSubtitleFontName:[_defaults stringForKey:MSubtitleFontNameKey]
                               size:[_defaults floatForKey:MSubtitleFontSizeKey]];
}

- (IBAction)subtitleAutoFontSizeAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL autoFontSize = [_subtitleAutoFontSizeButton state];
    [_defaults setBool:autoFontSize forKey:MSubtitleAutoFontSizeKey];

    if (autoFontSize) {
        [self updateFontSizeForAutoFontSizeChars];
    }
    else {
        [self updateSubtitleFontAndSizeUI];
    }
}

- (IBAction)subtitleAutoFontSizeCharsAction:(id)sender
{
    [_defaults setInteger:[sender intValue] forKey:MSubtitleAutoFontSizeCharsKey];

    [self updateFontSizeForAutoFontSizeChars];
}

- (void)changeFont:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSFont* font = [NSFont fontWithName:[_defaults stringForKey:MSubtitleFontNameKey]
                                   size:[_defaults floatForKey:MSubtitleFontSizeKey]];
    font = [sender convertFont:font];

    float fontSize = [font pointSize];
    if ([_defaults boolForKey:MSubtitleAutoFontSizeKey]) {
        fontSize = [_defaults floatForKey:MSubtitleFontSizeKey];
    }
    [_defaults setObject:[font fontName] forKey:MSubtitleFontNameKey];
    [_defaults setFloat:fontSize forKey:MSubtitleFontSizeKey];
    [self updateSubtitleFontAndSizeUI];

    [_movieView setSubtitleFontName:[_defaults stringForKey:MSubtitleFontNameKey]
                               size:[_defaults floatForKey:MSubtitleFontSizeKey]];
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
        SUBTITLE_SHADOW_BLUR,
        SUBTITLE_SHADOW_OFFSET,
        SUBTITLE_SHADOW_DARKNESS,
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
            [_defaults setColor:textColor forKey:MSubtitleTextColorKey];
            [_movieView setSubtitleTextColor:textColor];
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
            [_defaults setColor:strokeColor forKey:MSubtitleStrokeColorKey];
            [_movieView setSubtitleStrokeColor:strokeColor];
            break;
        }
        case SUBTITLE_STROKE_WIDTH : {
            float strokeWidth = [_subtitleStrokeWidthSlider floatValue];
            [_subtitleStrokeWidthTextField setFloatValue:strokeWidth];
            [_defaults setFloat:strokeWidth forKey:MSubtitleStrokeWidthKey];
            [_movieView setSubtitleStrokeWidth:strokeWidth];
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
            [_defaults setColor:shadowColor forKey:MSubtitleShadowColorKey];
            [_movieView setSubtitleShadowColor:shadowColor];
            break;
        }
        case SUBTITLE_SHADOW_BLUR : {
            float shadowBlur = [_subtitleShadowBlurSlider floatValue];
            [_subtitleShadowBlurTextField setFloatValue:shadowBlur];
            [_defaults setFloat:shadowBlur   forKey:MSubtitleShadowBlurKey];
            [_movieView setSubtitleShadowBlur:shadowBlur];
            break;
        }
        case SUBTITLE_SHADOW_OFFSET : {
            float shadowOffset = [_subtitleShadowOffsetSlider floatValue];
            [_subtitleShadowOffsetTextField setFloatValue:shadowOffset];
            [_defaults setFloat:shadowOffset forKey:MSubtitleShadowOffsetKey];
            [_movieView setSubtitleShadowOffset:shadowOffset];
            break;
        }
        case SUBTITLE_SHADOW_DARKNESS : {
            float shadowDarkness = [_subtitleShadowDarknessSlider intValue];
            [_subtitleShadowDarknessTextField setIntValue:shadowDarkness];
            [_defaults setInteger:shadowDarkness forKey:MSubtitleShadowDarknessKey];
            [_movieView setSubtitleShadowDarkness:shadowDarkness];
            break;
        }
    }
}

- (IBAction)subtitlePositionAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    enum {
        SUBTITLE_DISPLAY_ON_LETTER_BOX,
        SUBTITLE_MIN_LETTER_BOX_HEIGHT,
        SUBTITLE_H_MARGIN,
        SUBTITLE_V_MARGIN,
    };

    switch ([sender tag]) {
        case SUBTITLE_DISPLAY_ON_LETTER_BOX : {
            BOOL displayOnLetterBox = [_subtitleDisplayOnLetterBoxButton state];
            [_defaults setBool:displayOnLetterBox forKey:MSubtitleDisplayOnLetterBoxKey];
            [_appController subtitleDisplayOnLetterBoxAction:self];
            break;
        }
        case SUBTITLE_MIN_LETTER_BOX_HEIGHT : {
            float minLetterBoxHeight = [_subtitleMinLetterBoxHeightSlider floatValue];
            [_subtitleMinLetterBoxHeightTextField setIntValue:(int)minLetterBoxHeight];
            [_defaults setFloat:minLetterBoxHeight forKey:MSubtitleMinLetterBoxHeightKey];
            [_appController setMinLetterBoxHeight:minLetterBoxHeight];
            break;
        }
        case SUBTITLE_H_MARGIN : {
            float hMargin = [_subtitleHMarginSlider floatValue];
            [_subtitleHMarginTextField setFloatValue:hMargin];
            [_defaults setFloat:hMargin forKey:MSubtitleHMarginKey];
            [_appController setSubtitleHMargin:hMargin];
            if ([_defaults boolForKey:MSubtitleAutoFontSizeKey]) {
                [self updateFontSizeForAutoFontSizeChars];
            }
            break;
        }
        case SUBTITLE_V_MARGIN : {
            float vMargin = [_subtitleVMarginSlider floatValue];
            [_subtitleVMarginTextField setFloatValue:vMargin];
            [_defaults setFloat:vMargin forKey:MSubtitleVMarginKey];
            [_appController setSubtitleVMargin:vMargin];
            break;
        }
    }
}

- (IBAction)subtitleReplaceNLWithBRAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_defaults setBool:[_subtitleReplaceNLWithBRButton state] forKey:MSubtitleReplaceNLWithBRKey];
    [_appController reopenSubtitle];
}

- (void)initSubtitleEncodingPopUpButton
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_subtitleEncodingPopUpButton removeAllItems];
    initSubtitleEncodingMenu([_subtitleEncodingPopUpButton menu], nil);
    [_subtitleEncodingPopUpButton selectItemWithTag:[_defaults integerForKey:MSubtitleEncodingKey]];
}

- (void)updateSubtitleFontAndSizeUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithCapacity:3];

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    [attrs setObject:[paragraphStyle autorelease] forKey:NSParagraphStyleAttributeName];

    float fontSize = [_defaults floatForKey:MSubtitleFontSizeKey];
    NSFont* font = [NSFont fontWithName:[_defaults stringForKey:MSubtitleFontNameKey]
                                   size:MIN(fontSize, 20.0)];
    [attrs setObject:font forKey:NSFontAttributeName];

    NSString* title = [NSString localizedStringWithFormat:
                                        @"%@ %g", [font displayName], fontSize];
    NSMutableAttributedString* mas = [[NSMutableAttributedString alloc]
                                            initWithString:title attributes:attrs];
    BOOL autoFontSize = [_defaults boolForKey:MSubtitleAutoFontSizeKey];
    if (autoFontSize) {
        NSRange range;
        range.location = [[font displayName] length] + 1;
        range.length = [title length] - range.location;
        [mas addAttribute:NSForegroundColorAttributeName
                    value:[NSColor disabledControlTextColor]
                    range:range];
    }
    [_subtitleFontButton setAttributedTitle:[mas autorelease]];

    int chars = [_defaults integerForKey:MSubtitleAutoFontSizeCharsKey];
    [_subtitleAutoFontSizeButton setState:autoFontSize];
    [_subtitleAutoFontSizeLabelTextField setTextColor:
        autoFontSize ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
    [_subtitleAutoFontSizeTextField setEnabled:autoFontSize];
    [_subtitleAutoFontSizeTextField setIntValue:chars];
    [_subtitleAutoFontSizeStepper setEnabled:autoFontSize];
    [_subtitleAutoFontSizeStepper setIntValue:chars];
}

@end

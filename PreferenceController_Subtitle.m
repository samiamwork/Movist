//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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
    [self updateSubtitleFontButtonUI];

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
    [_subtitleShadowColorWell setColor:shadowColor];
    [_subtitleShadowOpacitySlider setFloatValue:[shadowColor alphaComponent]];
    [_subtitleShadowOpacityTextField setFloatValue:[shadowColor alphaComponent]];
    [_subtitleShadowBlurSlider setFloatValue:shadowBlur];
    [_subtitleShadowBlurTextField setFloatValue:shadowBlur];
    [_subtitleShadowOffsetSlider setFloatValue:shadowOffset];
    [_subtitleShadowOffsetTextField setFloatValue:shadowOffset];

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
    NSFont* font = [NSFont fontWithName:[_defaults stringForKey:MSubtitleFontNameKey]
                                   size:[_defaults floatForKey:MSubtitleFontSizeKey]];

    NSFontManager* fontManager = [NSFontManager sharedFontManager];
    [fontManager setDelegate:self];
    [fontManager orderFrontFontPanel:self];
    [fontManager setSelectedFont:font isMultiple:FALSE];
}

- (void)changeFont:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSFont* font = [NSFont fontWithName:[_defaults stringForKey:MSubtitleFontNameKey]
                                   size:[_defaults floatForKey:MSubtitleFontSizeKey]];
    font = [sender convertFont:font];
    [_defaults setObject:[font fontName] forKey:MSubtitleFontNameKey];
    [_defaults setFloat:[font pointSize] forKey:MSubtitleFontSizeKey];
    [self updateSubtitleFontButtonUI];

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

- (void)updateSubtitleFontButtonUI
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    float fontSize = [_defaults floatForKey:MSubtitleFontSizeKey];
    NSFont* font = [NSFont fontWithName:[_defaults stringForKey:MSubtitleFontNameKey]
                                   size:MIN(fontSize, 20.0)];
    [_subtitleFontButton setFont:font];
    [_subtitleFontButton setTitle:
        [NSString localizedStringWithFormat:@"%@ %g", [font displayName], fontSize]];
}

@end

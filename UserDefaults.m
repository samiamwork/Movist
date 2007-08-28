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

#import "UserDefaults.h"

#pragma mark app
NSString* MPreferencePaneKey                = @"PreferencePane";
NSString* MControlTabKey                    = @"ControlTab";

#pragma mark -
#pragma mark prefs: general
NSString* MAutoFullScreenKey                = @"AutoFullScreen";
NSString* MAlwaysOnTopKey                   = @"AlwaysOnTop";
NSString* MActivateOnDraggingKey            = @"ActivateOnDragging";
NSString* MQuitWhenWindowCloseKey           = @"QuitWhenWindowClose";
NSString* MSeekInterval0Key                 = @"SeekInterval0";
NSString* MSeekInterval1Key                 = @"SeekInterval1";
NSString* MSeekInterval2Key                 = @"SeekInterval2";

#pragma mark -
#pragma mark prefs: video
NSString* MFullScreenEffectKey              = @"FullScreenEffect";
NSString* MFullScreenFillForWideMovieKey    = @"FullScreenFillForWideMovie";
NSString* MFullScreenFillForStdMovieKey     = @"FullScreenFillForStdMovie";
NSString* MFullScreenUnderScanKey           = @"FullScreenUnderScan";

#pragma mark -
#pragma mark prefs: audio
NSString* MVolumeKey                        = @"Volume";

#pragma mark -
#pragma mark prefs: subtitle
NSString* MSubtitleEnableKey                = @"SubtitleEnable";
NSString* MSubtitleEncodingKey              = @"SubtitleEncoding";
NSString* MSubtitleFontNameKey              = @"SubtitleFontName";
NSString* MSubtitleFontSizeKey              = @"SubtitleFontSize";
NSString* MSubtitleAutoFontSizeKey          = @"SubtitleAutoFontSize";
NSString* MSubtitleAutoFontSizeCharsKey     = @"SubtitleAutoFontSizeChars";
NSString* MSubtitleTextColorKey             = @"SubtitleTextColor";
NSString* MSubtitleStrokeColorKey           = @"SubtitleStrokeColor";
NSString* MSubtitleStrokeWidthKey           = @"SubtitleStrokeWidth";
NSString* MSubtitleShadowColorKey           = @"SubtitleShadowColor";
NSString* MSubtitleShadowBlurKey            = @"SubtitleShadowBlur";
NSString* MSubtitleShadowOffsetKey          = @"SubtitleShadowOffset";
NSString* MSubtitleHMarginKey               = @"SubtitleHMargin";
NSString* MSubtitleVMarginKey               = @"SubtitleVMargin";
NSString* MSubtitleDisplayOnLetterBoxKey    = @"SubtitleDisplayOnLetterBox";
NSString* MSubtitleMinLetterBoxHeightKey    = @"SubtitleMinLetterBoxHeight";
NSString* MSubtitleReplaceNLWithBRKey       = @"SubtitleReplaceNLWithBR";

#pragma mark -
#pragma mark prefs: advanced
NSString* MDefaultDecoderKey                = @"DefaultDecoder";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSUserDefaults (Movist)

+ (void)initialize
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [super initialize];

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    // app
    [dict setObject:@"" forKey:MPreferencePaneKey]; // for first pane
    [dict setObject:@"" forKey:MControlTabKey];     // for first tab

    // prefs: general
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MAutoFullScreenKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MAlwaysOnTopKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MActivateOnDraggingKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MQuitWhenWindowCloseKey];
    [dict setObject:[NSNumber numberWithFloat: 10.0] forKey:MSeekInterval0Key];
    [dict setObject:[NSNumber numberWithFloat: 60.0] forKey:MSeekInterval1Key];
    [dict setObject:[NSNumber numberWithFloat:300.0] forKey:MSeekInterval2Key];

    // prefs: video
    [dict setObject:[NSNumber numberWithInt:FS_EFFECT_NONE] forKey:MFullScreenEffectKey];
    [dict setObject:[NSNumber numberWithInt:FS_FILL_NEVER] forKey:MFullScreenFillForWideMovieKey];
    [dict setObject:[NSNumber numberWithInt:FS_FILL_NEVER] forKey:MFullScreenFillForStdMovieKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MFullScreenUnderScanKey];

    // prefs: audio
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MVolumeKey];

    // prefs: subtitle
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MSubtitleEnableKey];
    [dict setObject:[NSNumber numberWithInt:kCFStringEncodingDOSKorean] forKey:MSubtitleEncodingKey];
    [dict setObject:[[NSFont boldSystemFontOfSize:1.0] fontName] forKey:MSubtitleFontNameKey];
    [dict setObject:[NSNumber numberWithFloat:24.0] forKey:MSubtitleFontSizeKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MSubtitleAutoFontSizeKey];
    [dict setObject:[NSNumber numberWithInt:26] forKey:MSubtitleAutoFontSizeCharsKey];
    NSColor* color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [dict setObject:[NSArchiver archivedDataWithRootObject:color] forKey:MSubtitleTextColorKey];
    color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    [dict setObject:[NSArchiver archivedDataWithRootObject:color] forKey:MSubtitleStrokeColorKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleStrokeWidthKey];
    color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    [dict setObject:[NSArchiver archivedDataWithRootObject:color] forKey:MSubtitleShadowColorKey];
    [dict setObject:[NSNumber numberWithFloat:2.0] forKey:MSubtitleShadowBlurKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MSubtitleShadowOffsetKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleHMarginKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleVMarginKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MSubtitleDisplayOnLetterBoxKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MSubtitleMinLetterBoxHeightKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MSubtitleReplaceNLWithBRKey];

    // prefs: advanced
    [dict setObject:[NSNumber numberWithInt:DECODER_QUICKTIME] forKey:MDefaultDecoderKey];

    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
    //TRACE(@"registering defaults: %@", dict);
}

- (void)setColor:(NSColor*)color forKey:(NSString*)key
{
    //TRACE(@"%s %@ for \"%@\"", __PRETTY_FUNCTION__, color, key);
    NSData* data = [NSArchiver archivedDataWithRootObject:color];
    [self setObject:data forKey:key];
}

- (NSColor*)colorForKey:(NSString*)key
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, key);
    NSData* data = [self dataForKey:key];
    return (!data) ? nil : (NSColor*)[NSUnarchiver unarchiveObjectWithData:data];
}

@end

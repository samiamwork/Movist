//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@interface NSUserDefaults (Movist)

- (void)setColor:(NSColor*)color forKey:(NSString*)key;
- (NSColor*)colorForKey:(NSString*)key;

@end

#pragma mark -
#pragma mark app
extern NSString* MPreferencePaneKey;
extern NSString* MControlTabKey;

#pragma mark -
#pragma mark prefs: general
extern NSString* MAutoFullScreenKey;
extern NSString* MAlwaysOnTopKey;
extern NSString* MActivateOnDraggingKey;
extern NSString* MQuitWhenWindowCloseKey;
extern NSString* MSeekInterval0Key;
extern NSString* MSeekInterval1Key;
extern NSString* MSeekInterval2Key;

#pragma mark -
#pragma mark prefs: video
extern NSString* MFullScreenEffectKey;
extern NSString* MFullScreenFillForWideMovieKey;
extern NSString* MFullScreenFillForStdMovieKey;
extern NSString* MFullScreenUnderScanKey;

#pragma mark -
#pragma mark prefs: audio
extern NSString* MVolumeKey;

#pragma mark -
#pragma mark prefs: subtitle
extern NSString* MSubtitleEnableKey;
extern NSString* MSubtitleEncodingKey;
extern NSString* MSubtitleFontNameKey;
extern NSString* MSubtitleFontSizeKey;
extern NSString* MSubtitleAutoFontSizeKey;
extern NSString* MSubtitleAutoFontSizeCharsKey;
extern NSString* MSubtitleTextColorKey;
extern NSString* MSubtitleStrokeColorKey;
extern NSString* MSubtitleStrokeWidthKey;
extern NSString* MSubtitleShadowColorKey;
extern NSString* MSubtitleShadowBlurKey;
extern NSString* MSubtitleShadowOffsetKey;
extern NSString* MSubtitleHMarginKey;
extern NSString* MSubtitleVMarginKey;
extern NSString* MSubtitleDisplayOnLetterBoxKey;
extern NSString* MSubtitleMinLetterBoxHeightKey;
extern NSString* MSubtitleReplaceNLWithBRKey;

#pragma mark -
#pragma mark prefs: advanced
extern NSString* MDefaultDecoderKey;
extern NSString* MRemoveGreenBoxKey;

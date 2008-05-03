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

#pragma mark app
extern NSString* MPreferencePaneKey;
extern NSString* MControlTabKey;
extern NSString* MViewDurationKey;
extern NSString* MPlaylistKey;
extern NSString* MLastPlayedMovieTimeKey;
extern NSString* MLastPlayedMovieRepeatRangeKey;

#pragma mark -
#pragma mark prefs: general
extern NSString* MAutodetectMovieSeriesKey;
extern NSString* MAutoFullScreenKey;
extern NSString* MAutoPlayOnFullScreenKey;
extern NSString* MAlwaysOnTopKey;
extern NSString* MDeactivateScreenSaverKey;
extern NSString* MQuitWhenWindowCloseKey;
extern NSString* MRememberLastPlayKey;
extern NSString* MSupportAppleRemoteKey;
extern NSString* MFullNavUseKey;
extern NSString* MFullNavShowiTunesMoviesKey;
extern NSString* MFullNavShowiTunesPodcastsKey;
extern NSString* MFullNavShowiTunesTVShowsKey;
extern NSString* MFullNavOnStartupKey;
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
extern NSString* MAutodetectDigitalAudioOutKey;

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
extern NSString* MSubtitleShadowDarknessKey;
extern NSString* MSubtitlePositionKey;
extern NSString* MSubtitleHMarginKey;
extern NSString* MSubtitleVMarginKey;
extern NSString* MSubtitleLineSpacingKey;

#pragma mark -
#pragma mark prefs: advanced
extern NSString* MDefaultCodecBindingKey;
extern NSString* MUpdateCheckIntervalKey;
extern NSString* MLastUpdateCheckTimeKey;

#pragma mark -
#pragma mark prefs: advanced - details
// General
extern NSString* MActivateOnDraggingKey;
extern NSString* MOpeningResizeKey;
extern NSString* MDraggingActionKey;
// Video
extern NSString* MCaptureFormatKey;
extern NSString* MIncludeLetterBoxOnCaptureKey;
extern NSString* MRemoveGreenBoxKey;
// Audio
// Subtitle
extern NSString* MDisablePerianSubtitleKey;
extern NSString* MSubtitleReplaceNLWithBRKey;
extern NSString* MDefaultLanguageIdentifiersKey;
extern NSString* MAutoSubtitlePositionMaxLinesKey;
// Full Navigation
extern NSString* MFullNavPathKey;
extern NSString* MShowActualPathForLinkKey;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSUserDefaults (MovistUtils)

- (void)registerMovistDefaults;

////////////////////////////////////////////////////////////////////////////////

- (NSDictionary*)defaultCodecBinding;

- (int)defaultDecoderForCodecId:(int)codecId;
- (void)setDefaultDecoder:(int)decoder forCodecId:(int)codecId;
- (void)setDefaultDecoder:(int)decoder forCodecIdSet:(NSIndexSet*)codecIdSet;

- (BOOL)a52CodecAttemptPassthrough;
- (void)setA52CodecAttemptPassthrough:(BOOL)enabled;

- (BOOL)isPerianSubtitleEnabled;
- (void)setPerianSubtitleEnabled:(BOOL)enabled;

@end

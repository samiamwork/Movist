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
extern NSString* MOpeningViewKey;
extern NSString* MAutodetectMovieSeriesKey;
extern NSString* MAutoPlayOnFullScreenKey;
extern NSString* MAlwaysOnTopKey;
extern NSString* MAlwaysOnTopOnPlayingKey;
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
extern NSString* MFullScreenBlackScreensKey;

#pragma mark -
#pragma mark prefs: audio
extern NSString* MVolumeKey;
extern NSString* MAutodetectDigitalAudioOutKey;
extern NSString* MUpdateSystemVolumeKey;

#pragma mark -
#pragma mark prefs: subtitle
extern NSString* MSubtitleEnableKey;
extern NSString* MPrefsSubtitleTabKey;
extern NSString* MSubtitleEncodingKey;
extern NSString* MSubtitleFontNameKey[3];
extern NSString* MSubtitleFontSizeKey[3];
extern NSString* MSubtitleAutoFontSizeKey[3];
extern NSString* MSubtitleAutoFontSizeCharsKey[3];
extern NSString* MSubtitleTextColorKey[3];
extern NSString* MSubtitleStrokeColorKey[3];
extern NSString* MSubtitleStrokeWidthKey[3];
extern NSString* MSubtitleShadowColorKey[3];
extern NSString* MSubtitleShadowBlurKey[3];
extern NSString* MSubtitleShadowOffsetKey[3];
extern NSString* MSubtitleShadowDarknessKey[3];
//extern NSString* MSubtitleHPositionKey[3];
extern NSString* MSubtitleVPositionKey[3];
extern NSString* MSubtitleHMarginKey[3];
extern NSString* MSubtitleVMarginKey[3];
extern NSString* MSubtitleLineSpacingKey[3];
extern NSString* MLetterBoxHeightKey;
extern NSString* MSubtitleScreenMarginKey;

#pragma mark -
#pragma mark prefs: advanced
extern NSString* MPrefsAdvancedTabKey;

#pragma mark -
#pragma mark prefs: advanced - general
extern NSString* MUpdateCheckIntervalKey;
extern NSString* MLastUpdateCheckTimeKey;

#pragma mark -
#pragma mark prefs: advanced - codec-binding
extern NSString* MDefaultCodecBindingKey;

#pragma mark -
#pragma mark prefs: advanced - details: general
extern NSString* MActivateOnDraggingKey;
extern NSString* MAutoShowDockKey;
extern NSString* MUsePlayPanelKey;
extern NSString* MFloatingPlaylistKey;
extern NSString* MGotoBegginingWhenReopenMovieKey;
extern NSString* MGotoBegginingWhenOpenSubtitleKey;
extern NSString* MMovieResizeCenterKey;
extern NSString* MWindowResizeModeKey;
extern NSString* MViewDragActionKey;
#pragma mark prefs: advanced - details: video
extern NSString* MCaptureFormatKey;
extern NSString* MIncludeLetterBoxOnCaptureKey;
extern NSString* MRemoveGreenBoxKey;
#pragma mark prefs: advanced - details: audio
#pragma mark prefs: advanced - details: subtitle
extern NSString* MUseQuickTimeSubtitlesKey;
extern NSString* MAutoLoadMKVEmbeddedSubtitlesKey;
extern NSString* MSubtitleReplaceNLWithBRKey;
extern NSString* MDefaultLanguageIdentifiersKey;
extern NSString* MAutoLetterBoxHeightMaxLinesKey;
#pragma mark prefs: advanced - details: full-nav
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

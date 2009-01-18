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

#import "UserDefaults.h"

#pragma mark app
NSString* MPreferencePaneKey                = @"PreferencePane";
NSString* MControlTabKey                    = @"ControlTab";
NSString* MViewDurationKey                  = @"ViewDuration";
NSString* MPlaylistKey                      = @"Playlist";
NSString* MLastPlayedMovieTimeKey           = @"LastPlayedMovieTime";
NSString* MLastPlayedMovieRepeatRangeKey    = @"LastPlayedMovieRepeatRange";

#pragma mark -
#pragma mark prefs: general
NSString* MOpeningViewKey                   = @"OpeningView";
NSString* MAutodetectMovieSeriesKey         = @"AutodetectMovieSeries";
NSString* MAutoPlayOnFullScreenKey          = @"AutoPlayOnFullScreen";
NSString* MAlwaysOnTopKey                   = @"AlwaysOnTop";
NSString* MDeactivateScreenSaverKey         = @"DeactivateScreenSaver";
NSString* MQuitWhenWindowCloseKey           = @"QuitWhenWindowClose";
NSString* MRememberLastPlayKey              = @"RememberLastPlay";
NSString* MSupportAppleRemoteKey            = @"SupportAppleRemote";
NSString* MFullNavUseKey                    = @"FullNavUse";
NSString* MFullNavOnStartupKey              = @"FullNavOnStartup";
NSString* MFullNavShowiTunesMoviesKey       = @"FullNavShowiTunesMovies";
NSString* MFullNavShowiTunesPodcastsKey     = @"FullNavShowiTunesPodcasts";
NSString* MFullNavShowiTunesTVShowsKey      = @"FullNavShowiTunesTVShows";
NSString* MSeekInterval0Key                 = @"SeekInterval0";
NSString* MSeekInterval1Key                 = @"SeekInterval1";
NSString* MSeekInterval2Key                 = @"SeekInterval2";

#pragma mark -
#pragma mark prefs: video
NSString* MFullScreenEffectKey              = @"FullScreenEffect";
NSString* MFullScreenFillForWideMovieKey    = @"FullScreenFillForWideMovie";
NSString* MFullScreenFillForStdMovieKey     = @"FullScreenFillForStdMovie";
NSString* MFullScreenUnderScanKey           = @"FullScreenUnderScan";
NSString* MFullScreenBlackScreensKey	    = @"FullScreenBlackScreens";

#pragma mark -
#pragma mark prefs: audio
NSString* MVolumeKey                        = @"Volume";
NSString* MAutodetectDigitalAudioOutKey     = @"AutodetectDigitalAudioOut";
NSString* MUpdateSystemVolumeKey            = @"UpdateSystemVolume";

#pragma mark -
#pragma mark prefs: subtitle
NSString* MSubtitleEnableKey                = @"SubtitleEnable";
NSString* MPrefsSubtitleTabKey              = @"PrefsSubtitleTab";
NSString* MSubtitleEncodingKey              = @"SubtitleEncoding";
NSString* MSubtitleFontNameKey[3]           = { @"SubtitleFontName", @"SubtitleFontName1", @"SubtitleFontName2" };
NSString* MSubtitleFontSizeKey[3]           = { @"SubtitleFontSize", @"SubtitleFontSize1", @"SubtitleFontSize2" };
NSString* MSubtitleAutoFontSizeKey[3]       = { @"SubtitleAutoFontSize", @"SubtitleAutoFontSize1", @"SubtitleAutoFontSize2" };
NSString* MSubtitleAutoFontSizeCharsKey[3]  = { @"SubtitleAutoFontSizeChars", @"SubtitleAutoFontSizeChars1", @"SubtitleAutoFontSizeChars2" };
NSString* MSubtitleTextColorKey[3]          = { @"SubtitleTextColor", @"SubtitleTextColor1", @"SubtitleTextColor2" };
NSString* MSubtitleStrokeColorKey[3]        = { @"SubtitleStrokeColor", @"SubtitleStrokeColor1", @"SubtitleStrokeColor2" };
NSString* MSubtitleStrokeWidthKey[3]        = { @"SubtitleStrokeWidth", @"SubtitleStrokeWidth1", @"SubtitleStrokeWidth2" };
NSString* MSubtitleShadowColorKey[3]        = { @"SubtitleShadowColor", @"SubtitleShadowColor1", @"SubtitleShadowColor2" };
NSString* MSubtitleShadowBlurKey[3]         = { @"SubtitleShadowBlur", @"SubtitleShadowBlur1", @"SubtitleShadowBlur2" };
NSString* MSubtitleShadowOffsetKey[3]       = { @"SubtitleShadowOffset", @"SubtitleShadowOffset1", @"SubtitleShadowOffset2" };
NSString* MSubtitleShadowDarknessKey[3]     = { @"SubtitleShadowDarkness", @"SubtitleShadowDarkness1", @"SubtitleShadowDarkness2" };
//NSString* MSubtitleHPositionKey[3]          = { @"SubtitleHPosition", @"SubtitleHPosition1", @"SubtitleHPosition2" };
NSString* MSubtitleVPositionKey[3]          = { @"SubtitleVPosition", @"SubtitleVPosition1", @"SubtitleVPosition2" };
NSString* MSubtitleHMarginKey[3]            = { @"SubtitleHMargin", @"SubtitleHMargin1", @"SubtitleHMargin2" };
NSString* MSubtitleVMarginKey[3]            = { @"SubtitleVMargin", @"SubtitleVMargin1", @"SubtitleVMargin2" };
NSString* MSubtitleLineSpacingKey[3]        = { @"SubtitleLineSpacing", @"SubtitleLineSpacing1", @"SubtitleLineSpacing2" };
NSString* MLetterBoxHeightKey               = @"LetterBoxHeight";
NSString* MSubtitleScreenMarginKey          = @"SubtitleScreenMargin";

#pragma mark -
#pragma mark prefs: advanced
NSString* MPrefsAdvancedTabKey              = @"PrefsAdvancedTab";

#pragma mark prefs: advanced - general
NSString* MUpdateCheckIntervalKey           = @"UpdateCheckInterval";
NSString* MLastUpdateCheckTimeKey           = @"LastUpdateCheckTime";

#pragma mark prefs: advanced - codec-binding
NSString* MDefaultCodecBindingKey           = @"DefaultCodecBinding";

#pragma mark prefs: advanced - details: general
NSString* MActivateOnDraggingKey            = @"ActivateOnDragging";
NSString* MAutoShowDockKey                  = @"AutoShowDock";
NSString* MFloatingPlaylistKey              = @"FloatingPlaylist";
NSString* MGotoBegginingWhenReopenMovieKey  = @"GotoBegginingWhenReopenMovie";
NSString* MGotoBegginingWhenOpenSubtitleKey = @"GotoBegginingWhenOpenSubtitle";
NSString* MMovieResizeCenterKey             = @"MovieResizeCenter";
NSString* MWindowResizeModeKey              = @"WindowResizeMode";
NSString* MViewDragActionKey                = @"ViewDragAction";
#pragma mark prefs: advanced - details: video
NSString* MCaptureFormatKey                 = @"CaptureFormat";
NSString* MIncludeLetterBoxOnCaptureKey     = @"IncludeLetterBoxOnCapture";
NSString* MRemoveGreenBoxKey                = @"RemoveGreenBox";
#pragma mark prefs: advanced - details: audio
#pragma mark prefs: advanced - details: subtitle
NSString* MUsePerianExternalSubtitlesKey    = @"UsePerianExternalSubtitles";
NSString* MUseQuickTimeEmbeddedSubtitlesKey = @"UseQuickTimeEmbeddedSubtitles";
NSString* MAutoLoadMKVEmbeddedSubtitlesKey  = @"AutoLoadMKVEmbeddedSubtitles";
NSString* MSubtitleReplaceNLWithBRKey       = @"SubtitleReplaceNLWithBR";
NSString* MDefaultLanguageIdentifiersKey    = @"DefaultLanguageIdentifiers";
NSString* MAutoLetterBoxHeightMaxLinesKey   = @"AutoLetterBoxHeightMaxLines";
#pragma mark prefs: advanced - details: full-nav
NSString* MFullNavPathKey                   = @"FullNavPath";
NSString* MShowActualPathForLinkKey         = @"ShowActualPathForLink";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSUserDefaults (MovistUtils)

- (void)registerMovistDefaults
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    // app
    [dict setObject:@"" forKey:MPreferencePaneKey]; // for first pane
    [dict setObject:@"" forKey:MControlTabKey];     // for first tab
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MViewDurationKey];

    // prefs: general
    [dict setObject:[NSNumber numberWithInt:OPENING_VIEW_NORMAL_SIZE] forKey:MOpeningViewKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutodetectMovieSeriesKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutoPlayOnFullScreenKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MAlwaysOnTopKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MDeactivateScreenSaverKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MQuitWhenWindowCloseKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MRememberLastPlayKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MSupportAppleRemoteKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavUseKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesMoviesKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesPodcastsKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesTVShowsKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MFullNavOnStartupKey];
    [dict setObject:[NSNumber numberWithFloat: 10.0] forKey:MSeekInterval0Key];
    [dict setObject:[NSNumber numberWithFloat: 60.0] forKey:MSeekInterval1Key];
    [dict setObject:[NSNumber numberWithFloat:300.0] forKey:MSeekInterval2Key];
    
    // prefs: video
    [dict setObject:[NSNumber numberWithInt:FS_EFFECT_ANIMATION] forKey:MFullScreenEffectKey];
    [dict setObject:[NSNumber numberWithInt:FS_FILL_NEVER] forKey:MFullScreenFillForWideMovieKey];
    [dict setObject:[NSNumber numberWithInt:FS_FILL_NEVER] forKey:MFullScreenFillForStdMovieKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MFullScreenUnderScanKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MFullScreenBlackScreensKey];

    // prefs: audio
    [dict setObject:[NSNumber numberWithFloat:DEFAULT_VOLUME] forKey:MVolumeKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutodetectDigitalAudioOutKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MUpdateSystemVolumeKey];

    // prefs: subtitle
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MSubtitleEnableKey];
    [dict setObject:@"" forKey:MPrefsSubtitleTabKey];     // for first tab
    CFStringEncoding defaultStringEncoding = CFStringGetSystemEncoding();
    if (defaultStringEncoding == kCFStringEncodingMacKorean) {  // if Mac/Korean,
        defaultStringEncoding = kCFStringEncodingDOSKorean;     // then convert to Windows/Korean.
    }
    [dict setObject:[NSNumber numberWithInt:defaultStringEncoding] forKey:MSubtitleEncodingKey];
    int vPosition[3] = { OSD_VPOSITION_LBOX, OSD_VPOSITION_TOP, OSD_VPOSITION_CENTER };
    NSColor* textColor   = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    NSColor* strokeColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    NSColor* shadowColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    int i;
    for (i = 0; i < 3; i++) {
        [dict setObject:[[NSFont boldSystemFontOfSize:1.0] fontName] forKey:MSubtitleFontNameKey[i]];
        [dict setObject:[NSNumber numberWithFloat:24.0] forKey:MSubtitleFontSizeKey[i]];
        [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MSubtitleAutoFontSizeKey[i]];
        [dict setObject:[NSNumber numberWithInt:26] forKey:MSubtitleAutoFontSizeCharsKey[i]];
        [dict setObject:[NSArchiver archivedDataWithRootObject:textColor] forKey:MSubtitleTextColorKey[i]];
        [dict setObject:[NSArchiver archivedDataWithRootObject:strokeColor] forKey:MSubtitleStrokeColorKey[i]];
        [dict setObject:[NSNumber numberWithFloat:4.0] forKey:MSubtitleStrokeWidthKey[i]];
        [dict setObject:[NSArchiver archivedDataWithRootObject:shadowColor] forKey:MSubtitleShadowColorKey[i]];
        [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleShadowOffsetKey[i]];
        [dict setObject:[NSNumber numberWithFloat:2.0] forKey:MSubtitleShadowBlurKey[i]];
        [dict setObject:[NSNumber numberWithInt:5] forKey:MSubtitleShadowDarknessKey[i]];
        //[dict setObject:[NSNumber numberWithInt:OSD_HPOSITION_CENTER] forKey:MSubtitleHPositionKey[i]];
        [dict setObject:[NSNumber numberWithInt:vPosition[i]] forKey:MSubtitleVPositionKey[i]];
        [dict setObject:[NSNumber numberWithFloat:DEFAULT_SUBTITLE_H_MARGIN] forKey:MSubtitleHMarginKey[i]];
        [dict setObject:[NSNumber numberWithFloat:DEFAULT_SUBTITLE_V_MARGIN] forKey:MSubtitleVMarginKey[i]];
        [dict setObject:[NSNumber numberWithFloat:DEFAULT_SUBTITLE_LINE_SPACING] forKey:MSubtitleLineSpacingKey[i]];
    }
    [dict setObject:[NSNumber numberWithInt:LETTER_BOX_HEIGHT_AUTO] forKey:MLetterBoxHeightKey];
    [dict setObject:[NSNumber numberWithFloat:DEFAULT_SUBTITLE_SCREEN_MARGIN] forKey:MSubtitleScreenMarginKey];

    // prefs: advanced
    [dict setObject:@"" forKey:MPrefsAdvancedTabKey];     // for first tab
    // prefs: advanced - general
    [dict setObject:[NSNumber numberWithInt:CHECK_UPDATE_WEEKLY] forKey:MUpdateCheckIntervalKey];
    [dict setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:MLastUpdateCheckTimeKey];
    // prefs: advanced - codec binding
    [dict setObject:[self defaultCodecBinding] forKey:MDefaultCodecBindingKey];
    // prefs: advanced - details: general
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MActivateOnDraggingKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutoShowDockKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MFloatingPlaylistKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MGotoBegginingWhenReopenMovieKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MGotoBegginingWhenOpenSubtitleKey];
    [dict setObject:[NSNumber numberWithInt:MOVIE_RESIZE_CENTER_TM] forKey:MMovieResizeCenterKey];
    [dict setObject:[NSNumber numberWithInt:WINDOW_RESIZE_ADJUST_TO_SIZE] forKey:MWindowResizeModeKey];
    [dict setObject:[NSNumber numberWithInt:VIEW_DRAG_ACTION_NONE] forKey:MViewDragActionKey];
    // prefs: advanced - details: video
    [dict setObject:[NSNumber numberWithInt:CAPTURE_FORMAT_PNG] forKey:MCaptureFormatKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MIncludeLetterBoxOnCaptureKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MRemoveGreenBoxKey];
    // prefs: advanced - details: audio
    // prefs: advanced - details: subtitle
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MUsePerianExternalSubtitlesKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MUseQuickTimeEmbeddedSubtitlesKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutoLoadMKVEmbeddedSubtitlesKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MSubtitleReplaceNLWithBRKey];
    [dict setObject:NSLocalizedString(@"DefaultSubtitleLanguageIdentifiers", nil)
             forKey:MDefaultLanguageIdentifiersKey];
    [dict setObject:[NSNumber numberWithInt:2] forKey:MAutoLetterBoxHeightMaxLinesKey];
    // prefs: advanced - details: full-nav
    [dict setObject:@"~/Movies" forKey:MFullNavPathKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MShowActualPathForLinkKey];

    //TRACE(@"registering defaults: %@", dict);
    [self registerDefaults:dict];
}

////////////////////////////////////////////////////////////////////////////////

- (NSDictionary*)defaultCodecBinding
{
    #define DECODER_VALUE(object)           [object intValue]
    #define CODEC_VALUE(ojbect)             [object intValue]

    #define DECODER_OBJECT(decoder)         [NSNumber numberWithInt:decoder]
    #define CODEC_KEY(codecId)              [NSString stringWithFormat:@"%d", codecId]
    //#define CODEC_KEY(codecId)              [NSNumber numberWithInt:codecId]
    // I don't know why [NSUserDefaults registerDefaults:] crashes for key of NSNumber.

    #define CODEC_BINDING(decoder, codecId) DECODER_OBJECT(decoder), CODEC_KEY(codecId)

    return [NSDictionary dictionaryWithObjectsAndKeys:
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_ETC_),
            CODEC_BINDING(DECODER_QUICKTIME,MCODEC_MPEG1),
            CODEC_BINDING(DECODER_QUICKTIME,MCODEC_MPEG2),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_MPEG4),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIV1),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIV2),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIV3),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIV4),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIV5),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIV6),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DIVX),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DX50),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_XVID),
            CODEC_BINDING(DECODER_QUICKTIME,MCODEC_MP4V),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_MPG4),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_MP42),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_MP43),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_MP4S),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_M4S2),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_AP41),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_RMP4),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_SEDG),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_FMP4),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_BLZ0),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_H263),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_H264),
            CODEC_BINDING(DECODER_QUICKTIME,MCODEC_AVC1),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_X264),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_VC1),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_WMV1),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_WMV2),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_WMV3),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_WVC1),
            CODEC_BINDING(DECODER_QUICKTIME,MCODEC_SVQ1),
            CODEC_BINDING(DECODER_QUICKTIME,MCODEC_SVQ3),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_VP3),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_VP5),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_VP6),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_VP6F),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_RV10),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_RV20),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_RV30),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_RV40),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_FLV),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_THEORA),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_HUFFYUV),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_CINEPAK),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_INDEO2),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_INDEO3),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_MJPEG),
            CODEC_BINDING(DECODER_FFMPEG,   MCODEC_DV),
            nil];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark utils.

- (int)defaultDecoderForCodecId:(int)codecId
{
    NSDictionary* dict = [self dictionaryForKey:MDefaultCodecBindingKey];
    id object = [dict objectForKey:CODEC_KEY(codecId)];
    if (!object) { // if not exist, use decoder for "etc."
        object = [dict objectForKey:CODEC_KEY(MCODEC_ETC_)];
    }
    return DECODER_VALUE(object);
}

- (void)setDefaultDecoder:(int)decoder forCodecId:(int)codecId
{
    NSMutableDictionary* dict =
    [[self dictionaryForKey:MDefaultCodecBindingKey] mutableCopy];

    id object = DECODER_OBJECT(decoder);
    if (codecId < 0) {  // for all codecs
        TRACE(@"codecId=%d ==> default-decoder=%d", codecId, decoder);
        id key;
        NSEnumerator* enumerator = [[dict allKeys] objectEnumerator];
        while (key = [enumerator nextObject]) {
            [dict setObject:object forKey:key];
        }
    }
    else {
        TRACE(@"codecId=%d ==> default-decoder=%d", codecId, decoder);
        [dict setObject:object forKey:CODEC_KEY(codecId)];
    }

    [self setObject:dict forKey:MDefaultCodecBindingKey];
}

- (void)setDefaultDecoder:(int)decoder forCodecIdSet:(NSIndexSet*)codecIdSet
{
    NSMutableDictionary* dict =
    [[self dictionaryForKey:MDefaultCodecBindingKey] mutableCopy];
    
    id object = DECODER_OBJECT(decoder);
    int i, count = [codecIdSet count];
    unsigned int* ids = (unsigned int*)malloc(sizeof(int) * count);
    [codecIdSet getIndexes:ids maxCount:count inIndexRange:nil];
    for (i = 0; i < count; i++) {
        TRACE(@"codecId=%d ==> default-decoder=%d", ids[i], decoder);
        [dict setObject:object forKey:CODEC_KEY(ids[i])];
    }
    free(ids);

    [self setObject:dict forKey:MDefaultCodecBindingKey];
}

////////////////////////////////////////////////////////////////////////////////

NSString* A52CODEC_DEFAULTS                 = @"com.cod3r.a52codec";
NSString* A52CODEC_ATTEMPT_PASSTHROUGH_KEY  = @"attemptPassthrough";

- (BOOL)a52CodecAttemptPassthrough
{
    NSNumber* number = nil;
    NSDictionary* a52Codec = [self persistentDomainForName:A52CODEC_DEFAULTS];
    if (a52Codec) {
        number = [a52Codec objectForKey:A52CODEC_ATTEMPT_PASSTHROUGH_KEY];
    }
    return (number) ? [number boolValue] : FALSE;   // disabled by default
}

- (void)setA52CodecAttemptPassthrough:(BOOL)enabled
{
    NSMutableDictionary* a52Codec =
    [[[self persistentDomainForName:A52CODEC_DEFAULTS] mutableCopy] autorelease];
    
    [a52Codec setObject:[NSNumber numberWithInt:enabled ? 1 : 0]
                 forKey:A52CODEC_ATTEMPT_PASSTHROUGH_KEY];
    
    [self removePersistentDomainForName:A52CODEC_DEFAULTS];
    [self setPersistentDomain:a52Codec forName:A52CODEC_DEFAULTS];
    [self synchronize];
}

////////////////////////////////////////////////////////////////////////////////

NSString* PERIAN_DEFAULTS       = @"org.perian.Perian";
NSString* PERIAN_SUBTITLE_KEY   = @"LoadExternalSubtitles";

- (BOOL)isPerianSubtitleEnabled
{
    NSNumber* number = nil;
    NSDictionary* perian = [self persistentDomainForName:PERIAN_DEFAULTS];
    if (perian) {
        number = [perian objectForKey:PERIAN_SUBTITLE_KEY];
    }
    return (number) ? [number boolValue] : TRUE;    // enabled by default of capri-perian
}

- (void)setPerianSubtitleEnabled:(BOOL)enabled
{
    NSMutableDictionary* perian =
    [[[self persistentDomainForName:PERIAN_DEFAULTS] mutableCopy] autorelease];
    
    [perian setObject:[NSNumber numberWithBool:enabled] forKey:PERIAN_SUBTITLE_KEY];
    
    [self removePersistentDomainForName:PERIAN_DEFAULTS];
    [self setPersistentDomain:perian forName:PERIAN_DEFAULTS];
    [self synchronize];
}

@end

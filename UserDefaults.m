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
NSString* MViewDurationKey                  = @"ViewDuration";
NSString* MPlaylistKey                      = @"Playlist";
NSString* MLastPlayedMovieTimeKey           = @"LastPlayedMovieTime";
NSString* MLastPlayedMovieRepeatRangeKey    = @"LastPlayedMovieRepeatRange";

#pragma mark -
#pragma mark prefs: general
NSString* MAutoFullScreenKey                = @"AutoFullScreen";
NSString* MAlwaysOnTopKey                   = @"AlwaysOnTop";
NSString* MQuitWhenWindowCloseKey           = @"QuitWhenWindowClose";
NSString* MRememberLastPlayKey              = @"RememberLastPlay";
NSString* MDeactivateScreenSaverKey         = @"DeactivateScreenSaver";
NSString* MSeekInterval0Key                 = @"SeekInterval0";
NSString* MSeekInterval1Key                 = @"SeekInterval1";
NSString* MSeekInterval2Key                 = @"SeekInterval2";
NSString* MSupportAppleRemoteKey            = @"SupportAppleRemote";
NSString* MFullNavUseKey                    = @"FullNavUse";

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
NSString* MSubtitleShadowDarknessKey        = @"SubtitleShadowDarkness";
NSString* MSubtitlePositionKey              = @"SubtitlePosition";
NSString* MSubtitleHMarginKey               = @"SubtitleHMargin";
NSString* MSubtitleVMarginKey               = @"SubtitleVMargin";
NSString* MSubtitleLineSpacingKey           = @"SubtitleLineSpacing";

#pragma mark -
#pragma mark prefs: advanced
NSString* MDefaultCodecBindingKey           = @"DefaultCodecBinding";
NSString* MUpdateCheckIntervalKey           = @"UpdateCheckInterval";
NSString* MLastUpdateCheckTimeKey           = @"LastUpdateCheckTime";

#pragma mark -
#pragma mark prefs: advanced - details
// General
NSString* MActivateOnDraggingKey            = @"ActivateOnDragging";
NSString* MAutodetectMovieSeriesKey         = @"AutodetectMovieSeries";
NSString* MAutodetectDigitalAudioOutKey     = @"AutodetectDigitalAudioOut";
NSString* MAutoPlayOnFullScreenKey          = @"AutoPlayOnFullScreen";
NSString* MCaptureIncludingLetterBoxKey     = @"CaptureIncludingLetterBox";
// Subtitle
NSString* MDisablePerianSubtitleKey         = @"DisablePerianSubtitle";
NSString* MSubtitleReplaceNLWithBRKey       = @"SubtitleReplaceNLWithBR";
NSString* MDefaultLanguageIdentifiersKey    = @"DefaultLanguageIdentifiers";
NSString* MAutoSubtitlePositionMaxLinesKey  = @"AutoSubtitlePositionMaxLines";
// Full Navigation
NSString* MFullNavPathKey                   = @"FullNavPath";
NSString* MFullNavShowiTunesMoviesKey       = @"FullNavShowiTunesMovies";
NSString* MFullNavShowiTunesTVShowsKey      = @"FullNavShowiTunesTVShows";
NSString* MFullNavShowiTunesPodcastKey      = @"FullNavShowiTunesPodcast";
NSString* MShowActualPathForLinkKey         = @"ShowActualPathForLink";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSUserDefaults (MovistUtils)

#define DECODER_VALUE(object)           [object intValue]
#define CODEC_VALUE(ojbect)             [object intValue]

#define DECODER_OBJECT(decoder)         [NSNumber numberWithInt:decoder]
#define CODEC_KEY(codecId)              [NSString stringWithFormat:@"%d", codecId]
//#define CODEC_KEY(codecId)              [NSNumber numberWithInt:codecId]
// I don't know why [NSUserDefaults registerDefaults:] crashes for key of NSNumber.

#define CODEC_BINDING(decoder, codecId) DECODER_OBJECT(decoder), CODEC_KEY(codecId)

- (NSDictionary*)defaultCodecBinding
{
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
            nil];
}

- (void)registerMovistDefaults
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    // app
    [dict setObject:@"" forKey:MPreferencePaneKey]; // for first pane
    [dict setObject:@"" forKey:MControlTabKey];     // for first tab
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MViewDurationKey];

    // prefs: general
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MAutoFullScreenKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MAlwaysOnTopKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MQuitWhenWindowCloseKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MRememberLastPlayKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MDeactivateScreenSaverKey];
    [dict setObject:[NSNumber numberWithFloat: 10.0] forKey:MSeekInterval0Key];
    [dict setObject:[NSNumber numberWithFloat: 60.0] forKey:MSeekInterval1Key];
    [dict setObject:[NSNumber numberWithFloat:300.0] forKey:MSeekInterval2Key];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MSupportAppleRemoteKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavUseKey];

    // prefs: video
    [dict setObject:[NSNumber numberWithInt:FS_EFFECT_ANIMATION] forKey:MFullScreenEffectKey];
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
    [dict setObject:[NSNumber numberWithFloat:2.0] forKey:MSubtitleStrokeWidthKey];
    color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    [dict setObject:[NSArchiver archivedDataWithRootObject:color] forKey:MSubtitleShadowColorKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MSubtitleShadowOffsetKey];
    [dict setObject:[NSNumber numberWithFloat:2.5] forKey:MSubtitleShadowBlurKey];
    [dict setObject:[NSNumber numberWithInt:5] forKey:MSubtitleShadowDarknessKey];
    [dict setObject:[NSNumber numberWithInt:SUBTITLE_POSITION_AUTO] forKey:MSubtitlePositionKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleHMarginKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleVMarginKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MSubtitleLineSpacingKey];

    // prefs: advanced - general
    [dict setObject:[NSNumber numberWithInt:CHECK_UPDATE_WEEKLY] forKey:MUpdateCheckIntervalKey];
    [dict setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:MLastUpdateCheckTimeKey];
    // prefs: advanced - codec binding
    [dict setObject:[self defaultCodecBinding] forKey:MDefaultCodecBindingKey];
    // prefs: advanced - details
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MActivateOnDraggingKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutodetectMovieSeriesKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutodetectDigitalAudioOutKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MAutoPlayOnFullScreenKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MCaptureIncludingLetterBoxKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MDisablePerianSubtitleKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MSubtitleReplaceNLWithBRKey];
    [dict setObject:@"ko kr" forKey:MDefaultLanguageIdentifiersKey];
    [dict setObject:[NSNumber numberWithInt:3] forKey:MAutoSubtitlePositionMaxLinesKey];
    [dict setObject:@"~/Movies" forKey:MFullNavPathKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesMoviesKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesTVShowsKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesPodcastKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MShowActualPathForLinkKey];

    //TRACE(@"registering defaults: %@", dict);
    [self registerDefaults:dict];
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
    NSDictionary* perian = [self persistentDomainForName:PERIAN_DEFAULTS];
    if (!perian) {
        return TRUE;    // enabled by default of capri-perian
    }
    
    //TRACE(@"perian=%@", perian);
    NSNumber* number = [perian objectForKey:PERIAN_SUBTITLE_KEY];
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

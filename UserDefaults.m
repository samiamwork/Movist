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
NSString* MFullNavPathKey                   = @"FullNavPath";
NSString* MFullNavShowiTunesMoviesKey       = @"FullNavShowiTunesMovies";
NSString* MFullNavShowVideoPodcastKey       = @"FullNavShowVideoPodcast";

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
NSString* MSubtitleDisplayOnLetterBoxKey    = @"SubtitleDisplayOnLetterBox";
NSString* MSubtitleLetterBoxHeightKey       = @"SubtitleLetterBoxHeight";
NSString* MSubtitleHMarginKey               = @"SubtitleHMargin";
NSString* MSubtitleVMarginKey               = @"SubtitleVMargin";
NSString* MSubtitleLineSpacingKey           = @"SubtitleLineSpacing";
NSString* MSubtitleReplaceNLWithBRKey       = @"SubtitleReplaceNLWithBR";

#pragma mark -
#pragma mark prefs: advanced
NSString* MDefaultDecoderKey                = @"DefaultDecoder";
NSString* MUpdateCheckIntervalKey           = @"UpdateCheckInterval";
NSString* MLastUpdateCheckTimeKey           = @"LastUpdateCheckTime";

#pragma mark -
#pragma mark prefs: advanced - details
NSString* MActivateOnDraggingKey            = @"ActivateOnDragging";
NSString* MDisablePerianSubtitleKey         = @"DisablePerianSubtitle";
NSString* MShowActualPathForLinkKey         = @"ShowActualPathForLink";
NSString* MCaptureIncludingLetterBoxKey     = @"CaptureIncludingLetterBox";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSUserDefaults (Movist)

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
    [dict setObject:[@"~/Movies" stringByExpandingTildeInPath] forKey:MFullNavPathKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowiTunesMoviesKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MFullNavShowVideoPodcastKey];

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
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MSubtitleDisplayOnLetterBoxKey];
    [dict setObject:[NSNumber numberWithInt:LETTER_BOX_HEIGHT_DEFAULT] forKey:MSubtitleLetterBoxHeightKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleHMarginKey];
    [dict setObject:[NSNumber numberWithFloat:1.0] forKey:MSubtitleVMarginKey];
    [dict setObject:[NSNumber numberWithFloat:0.0] forKey:MSubtitleLineSpacingKey];
    [dict setObject:[NSNumber numberWithBool:FALSE] forKey:MSubtitleReplaceNLWithBRKey];

    // prefs: advanced
    [dict setObject:[NSNumber numberWithInt:DECODER_QUICKTIME] forKey:MDefaultDecoderKey];
    [dict setObject:[NSNumber numberWithInt:CHECK_UPDATE_WEEKLY] forKey:MUpdateCheckIntervalKey];
    [dict setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:MLastUpdateCheckTimeKey];

    // prefs: advanced - details
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MActivateOnDraggingKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MDisablePerianSubtitleKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MShowActualPathForLinkKey];
    [dict setObject:[NSNumber numberWithBool:TRUE] forKey:MCaptureIncludingLetterBoxKey];

    //TRACE(@"registering defaults: %@", dict);
    [self registerDefaults:dict];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark color extension
#pragma mark -

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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark A52Codec

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
#pragma mark -
#pragma mark Perian

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

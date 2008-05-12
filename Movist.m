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
#import "MSubtitle.h"

#pragma mark notifications: movie
NSString* MMovieIndexedDurationNotification = @"MMovieIndexedDurationNotification";
NSString* MMovieRateChangeNotification      = @"MMovieRateChangeNotification";
NSString* MMovieCurrentTimeNotification     = @"MMovieCurrentTimeNotification";
NSString* MMovieEndNotification             = @"MMovieEndNotification";

#pragma mark notifications: etc
NSString* MPlaylistUpdatedNotification      = @"MPlaylistUpdatedNotification";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark drag & drop

NSString* MPlaylistItemDataType = @"MPlaylistItemDataType";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark utilities

enum {
    OS_NOT_SUPPORTED,
    OS_TIGER,
    OS_LEOPARD,
};

static int _operatingSystem = OS_LEOPARD;

void detectOperatingSystem()
{
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:
                          @"/System/Library/CoreServices/SystemVersion.plist"];
    NSString* version = [dict objectForKey:@"ProductVersion"];
    _operatingSystem = ([version compare:@"10.4"] < 0) ? OS_NOT_SUPPORTED :
                       ([version compare:@"10.5"] < 0) ? OS_TIGER : OS_LEOPARD;
}

BOOL isSystemTiger() { return (_operatingSystem == OS_TIGER); }
BOOL isSystemLeopard() { return (_operatingSystem == OS_LEOPARD); }

NSArray* movistDragTypes()
{
    return [NSArray arrayWithObjects:
            NSFilenamesPboardType, NSURLPboardType, MPlaylistItemDataType, nil];
}

float valueInRange(float value, float minValue, float maxValue)
{
    return (minValue <= value && value <= maxValue);
}

float adjustToRange(float value, float minValue, float maxValue)
{
    return MIN(MAX(minValue, value), maxValue);
}

float normalizedFloat1(float value)
{
    float f = (0 <= value) ? 0.05f : -0.05f;
    return (float)(int)((value + f) * 10) / 10;     // make "x.x"
}

float normalizedFloat2(float value)
{
    float f = (0 <= value) ? 0.005f : -0.005f;
    return (float)(int)((value + f) * 100) / 100;   // make "x.xx"
}

NSString* NSStringFromMovieTime(float time)
{
    BOOL positive = (0.0 <= time) ? TRUE : (time = -time, FALSE);
    int totalSeconds = (int)time;
    int totalMinutes = totalSeconds / 60;
    return [NSString stringWithFormat:
            positive ? @"%02d:%02d:%02d" : @"-%02d:%02d:%02d",
            totalMinutes / 60, totalMinutes % 60, totalSeconds % 60];
}

NSString* codecName(int codecId)
{
    if (codecId == MCODEC_ETC_) {
        return NSLocalizedString(@"etc.", nil);
    }

#define CASE_CODEC_STRING(codec)    \
        case MCODEC_##codec : return @""#codec

    switch (codecId) {
        CASE_CODEC_STRING(MPEG1);
        CASE_CODEC_STRING(MPEG2);
        CASE_CODEC_STRING(MPEG4);
        CASE_CODEC_STRING(DIV1);
        CASE_CODEC_STRING(DIV2);
        CASE_CODEC_STRING(DIV3);
        CASE_CODEC_STRING(DIV4);
        CASE_CODEC_STRING(DIV5);
        CASE_CODEC_STRING(DIV6);
        CASE_CODEC_STRING(DIVX);
        CASE_CODEC_STRING(DX50);
        CASE_CODEC_STRING(XVID);
        CASE_CODEC_STRING(MP4V);
        CASE_CODEC_STRING(MPG4);
        CASE_CODEC_STRING(MP42);
        CASE_CODEC_STRING(MP43);
        CASE_CODEC_STRING(MP4S);
        CASE_CODEC_STRING(M4S2);
        CASE_CODEC_STRING(AP41);
        CASE_CODEC_STRING(RMP4);
        CASE_CODEC_STRING(SEDG);
        CASE_CODEC_STRING(FMP4);
        CASE_CODEC_STRING(BLZ0);
        CASE_CODEC_STRING(H263);
        CASE_CODEC_STRING(H264);
        CASE_CODEC_STRING(AVC1);
        CASE_CODEC_STRING(X264);
        CASE_CODEC_STRING(VC1);
        CASE_CODEC_STRING(WMV1);
        CASE_CODEC_STRING(WMV2);
        CASE_CODEC_STRING(WMV3);
        CASE_CODEC_STRING(WVC1);
        CASE_CODEC_STRING(SVQ1);
        CASE_CODEC_STRING(SVQ3);
        CASE_CODEC_STRING(VP3);
        CASE_CODEC_STRING(VP5);
        CASE_CODEC_STRING(VP6);
        CASE_CODEC_STRING(VP6F);
        CASE_CODEC_STRING(RV10);
        CASE_CODEC_STRING(RV20);
        CASE_CODEC_STRING(RV30);
        CASE_CODEC_STRING(RV40);
        CASE_CODEC_STRING(FLV);
        CASE_CODEC_STRING(THEORA);
        CASE_CODEC_STRING(HUFFYUV);
        CASE_CODEC_STRING(CINEPAK);
        CASE_CODEC_STRING(INDEO2);
        CASE_CODEC_STRING(INDEO3);
        CASE_CODEC_STRING(MJPEG);
        CASE_CODEC_STRING(DV);

        CASE_CODEC_STRING(PCM);
        CASE_CODEC_STRING(DPCM);
        CASE_CODEC_STRING(ADPCM);
        CASE_CODEC_STRING(MP2);
        CASE_CODEC_STRING(MP3);
        CASE_CODEC_STRING(AAC);
        CASE_CODEC_STRING(AC3);
        CASE_CODEC_STRING(DTS);
        CASE_CODEC_STRING(VORBIS);
        CASE_CODEC_STRING(DVAUDIO);
        CASE_CODEC_STRING(WMAV1);
        CASE_CODEC_STRING(WMAV2);
        CASE_CODEC_STRING(RA);
        CASE_CODEC_STRING(AMR);
        CASE_CODEC_STRING(ALAC);
        CASE_CODEC_STRING(FLAC);
        CASE_CODEC_STRING(QDM2);
        CASE_CODEC_STRING(MACE);
        CASE_CODEC_STRING(SPEEX);
        CASE_CODEC_STRING(TTA);
        CASE_CODEC_STRING(WAVPACK);
    }
    return @"";
}

NSString* codecDescription(int codecId)
{
    if (codecId == MCODEC_ETC_) {
        // -[codecName:] returns localized name for "etc.". (the others are not)
        return NSLocalizedString(@"etc. DESC.", nil);
    }
    NSString* s = codecName(codecId);
    if (0 < [s length]) {
        s = [NSString stringWithFormat:@"%@ DESC.", s];
        return NSLocalizedString(s, nil);
    }
    return @"";
}

NSString* NSStringFromSubtitlePosition(int position)
{
    if (position == SUBTITLE_POSITION_AUTO) {
        return NSLocalizedString(@"Auto Subtitle Position", nil);
    }
    else if (position == SUBTITLE_POSITION_ON_MOVIE) {
        return NSLocalizedString(@"Subtitle on Movie", nil);
    }
    else if (position == SUBTITLE_POSITION_ON_LETTER_BOX) {
        return NSLocalizedString(@"Subtitle on Letter Box", nil);
    }
    else if (position == SUBTITLE_POSITION_ON_LETTER_BOX_1_LINE) {
        return [NSString stringWithFormat:
                NSLocalizedString(@"Subtitle on Letter Box (1 Line)", nil),
                position - SUBTITLE_POSITION_ON_LETTER_BOX];
    }
    else {
        return [NSString stringWithFormat:
                NSLocalizedString(@"Subtitle on Letter Box (%d Lines)", nil),
                position - SUBTITLE_POSITION_ON_LETTER_BOX];
    }
}

NSString* NSStringFromSubtitleEncoding(CFStringEncoding encoding)
{
    return [NSString localizedNameOfStringEncoding:
            CFStringConvertEncodingToNSStringEncoding(encoding)];
}

void runAlertPanelForOpenError(NSError* error, NSURL* url)
{
    NSString* s = [NSString stringWithFormat:@"%@\n\n%@",
                   error, [url isFileURL] ? [url path] : [url absoluteString]];
    NSRunAlertPanel([NSApp localizedAppName], s,
                    NSLocalizedString(@"OK", nil), nil, nil);
}

unsigned int dragActionFromPasteboard(NSPasteboard* pboard, BOOL defaultPlay)
{
    NSString* type = [pboard availableTypeFromArray:MOVIST_DRAG_TYPES];
    if (!type) {
        return DRAG_ACTION_NONE;
    }
    else if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
        if ([filenames count] == 1 &&
            [[filenames objectAtIndex:0] hasAnyExtension:[MSubtitle fileExtensions]]) {
            return DRAG_ACTION_REPLACE_SUBTITLE_FILE;
        }
        else {
            return (defaultPlay) ? DRAG_ACTION_PLAY_FILES : DRAG_ACTION_ADD_FILES;
        }
    }
    else if ([type isEqualToString:NSURLPboardType]) {
        NSString* s = [[NSURL URLFromPasteboard:pboard] absoluteString];
        if ([s hasAnyExtension:[MSubtitle fileExtensions]]) {
            return DRAG_ACTION_REPLACE_SUBTITLE_URL;
        }
        else {
            return (defaultPlay) ? DRAG_ACTION_PLAY_URL : DRAG_ACTION_ADD_URL;
        }
    }
    else if ([type isEqualToString:MPlaylistItemDataType]) {
        return DRAG_ACTION_REORDER_PLAYLIST;
    }
    return DRAG_ACTION_NONE;
}

void initSubtitleEncodingMenu(NSMenu* menu, SEL action)
{
    int cfEncoding[] = {
        // Korean
        kCFStringEncodingISO_2022_KR,
        kCFStringEncodingMacKorean,
        kCFStringEncodingDOSKorean,
        //kCFStringEncodingWindowsKoreanJohab,
        //kCFStringEncodingKSC_5601_87,
        //kCFStringEncodingKSC_5601_92_Johab,
        //kCFStringEncodingEUC_KR,
        
        kCFStringEncodingInvalidId, // for separator
        
        // UNICODE
        kCFStringEncodingUTF8,
        kCFStringEncodingUTF16,
        //kCFStringEncodingUTF16BE,
        //kCFStringEncodingUTF16LE,
        //kCFStringEncodingUTF32,
        //kCFStringEncodingUTF32BE,
        //kCFStringEncodingUTF32LE,
        //kCFStringEncodingUnicode,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Western
        kCFStringEncodingISOLatin1,
        kCFStringEncodingMacRoman,
        //kCFStringEncodingISOLatin3,
        //kCFStringEncodingISOLatin9,
        //kCFStringEncodingMacRomanLatin1,
        //kCFStringEncodingDOSLatin1,
        //kCFStringEncodingWindowsLatin1,
        //kCFStringEncodingNextStepLatin,
        //kCFStringEncodingMacVT100,
        //kCFStringEncodingASCII,
        //kCFStringEncodingANSEL,
        //kCFStringEncodingEBCDIC_US,
        //kCFStringEncodingEBCDIC_CP037,
        //kCFStringEncodingNextStepLatin,
        //kCFStringEncodingASCII,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Japanese
        kCFStringEncodingShiftJIS,
        kCFStringEncodingISO_2022_JP,
        kCFStringEncodingEUC_JP,
        kCFStringEncodingShiftJIS_X0213_00,
        //kCFStringEncodingMacJapanese,
        //kCFStringEncodingDOSJapanese,
        //kCFStringEncodingShiftJIS_X0213_MenKuTen,
        //kCFStringEncodingJIS_X0201_76,
        //kCFStringEncodingJIS_X0208_83,
        //kCFStringEncodingJIS_X0208_90,
        //kCFStringEncodingJIS_X0212_90,
        //kCFStringEncodingJIS_C6226_78,
        //kCFStringEncodingISO_2022_JP_2,
        //kCFStringEncodingISO_2022_JP_1,
        //kCFStringEncodingISO_2022_JP_3,
        //kCFStringEncodingNextStepJapanese,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Chinese Traditional
        kCFStringEncodingBig5,
        kCFStringEncodingBig5_HKSCS_1999,
        kCFStringEncodingDOSChineseTrad,
        //kCFStringEncodingMacChineseTrad,
        //kCFStringEncodingBig5_E,
        //kCFStringEncodingEUC_TW,
        //kCFStringEncodingCNS_11643_92_P1,
        //kCFStringEncodingCNS_11643_92_P2,
        //kCFStringEncodingCNS_11643_92_P3,
        //kCFStringEncodingISO_2022_CN,
        //kCFStringEncodingISO_2022_CN_EXT,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Arabic
        kCFStringEncodingISOLatinArabic,
        kCFStringEncodingWindowsArabic,
        //kCFStringEncodingMacArabic,
        //kCFStringEncodingMacExtArabic,
        //kCFStringEncodingDOSArabic,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Hebrew
        kCFStringEncodingISOLatinHebrew,
        kCFStringEncodingWindowsHebrew,
        //kCFStringEncodingMacHebrew,
        //kCFStringEncodingDOSHebrew,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Greek
        kCFStringEncodingISOLatinGreek,
        kCFStringEncodingWindowsGreek,
        //kCFStringEncodingMacGreek,
        //kCFStringEncodingDOSGreek,
        //kCFStringEncodingDOSGreek1,
        //kCFStringEncodingDOSGreek2,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Cyrillic
        kCFStringEncodingISOLatinCyrillic,
        kCFStringEncodingMacCyrillic,
        kCFStringEncodingKOI8_R,
        kCFStringEncodingWindowsCyrillic,
        kCFStringEncodingKOI8_U,
        //kCFStringEncodingMacUkrainian,
        //kCFStringEncodingDOSCyrillic,
        //kCFStringEncodingDOSRussian,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Thai
        kCFStringEncodingDOSThai,
        //kCFStringEncodingMacThai,
        //kCFStringEncodingISOLatinThai,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Chinese Simplified
        kCFStringEncodingGB_2312_80,
        kCFStringEncodingHZ_GB_2312,
        kCFStringEncodingGB_18030_2000,
        //kCFStringEncodingMacChineseSimp,
        //kCFStringEncodingDOSChineseSimplif,
        //kCFStringEncodingEUC_CN,
        //kCFStringEncodingGBK_95,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Central European
        kCFStringEncodingISOLatin2,
        kCFStringEncodingMacCentralEurRoman,
        kCFStringEncodingWindowsLatin2,
        //kCFStringEncodingDOSLatin2,
        //kCFStringEncodingDOSLatinUS,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Vietnamese
        kCFStringEncodingMacVietnamese,
        kCFStringEncodingWindowsVietnamese,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Turkish
        kCFStringEncodingISOLatin5,
        kCFStringEncodingWindowsLatin5,
        //kCFStringEncodingMacTurkish,
        //kCFStringEncodingDOSTurkish,
        
        kCFStringEncodingInvalidId, // for separator
        
        // Baltic
        kCFStringEncodingISOLatin4,
        kCFStringEncodingWindowsBalticRim,
        //kCFStringEncodingDOSBalticRim,
        //kCFStringEncodingISOLatin7,
        
        //kCFStringEncodingInvalidId, // for separator
        
        // Icelandic
        //kCFStringEncodingMacIcelandic,
        //kCFStringEncodingDOSIcelandic,
        
        //kCFStringEncodingInvalidId, // for separator
        
        // Nordic
        //kCFStringEncodingDOSNordic,
        //kCFStringEncodingISOLatin6,
        
        //kCFStringEncodingInvalidId, // for separator
        
        // Celtic
        //kCFStringEncodingMacCeltic,
        //kCFStringEncodingISOLatin8,
        
        //kCFStringEncodingInvalidId, // for separator
        
        // Romanian
        //kCFStringEncodingMacRomanian,
        //kCFStringEncodingISOLatin10,
        
        //kCFStringEncodingInvalidId, // for separator
        
        //kCFStringEncodingNonLossyASCII,
        
        //kCFStringEncodingInvalidId, // for separator
        
        // Etc.
        //kCFStringEncodingMacDevanagari,
        //kCFStringEncodingMacGurmukhi,
        //kCFStringEncodingMacGujarati,
        //kCFStringEncodingMacOriya,
        //kCFStringEncodingMacBengali,
        //kCFStringEncodingMacTamil,
        //kCFStringEncodingMacTelugu,
        //kCFStringEncodingMacKannada,
        //kCFStringEncodingDOSCanadianFrench,
        //kCFStringEncodingMacMalayalam,
        //kCFStringEncodingMacSinhalese,
        //kCFStringEncodingMacBurmese,
        //kCFStringEncodingMacKhmer,
        //kCFStringEncodingMacLaotian,
        //kCFStringEncodingMacGeorgian,
        //kCFStringEncodingMacArmenian,
        //kCFStringEncodingMacTibetan,
        //kCFStringEncodingMacMongolian,
        //kCFStringEncodingMacEthiopic,
        //kCFStringEncodingMacCroatian,
        //kCFStringEncodingMacGaelic,
        //kCFStringEncodingMacFarsi,
        //kCFStringEncodingDOSPortuguese,
        //kCFStringEncodingMacSymbol,
        //kCFStringEncodingMacDingbats,
        //kCFStringEncodingMacInuit,
        //kCFStringEncodingVISCII,
    };
    
    // remove all items
    while (0 < [menu numberOfItems]) {
        [menu removeItemAtIndex:0];
    }
    
    NSMenuItem* item;
    // FIXME: add system default...
    //item = [menu addItemWithTitle:NSLocalizedString(@"System Default", nil)
    //                       action:action keyEquivalent:@""];
    //[item setTag:systemDefaultCFEncoding];
    //[menu addItem:[NSMenuItem separatorItem]];
    
    NSString* encodingString;
    int i, count = sizeof(cfEncoding) / sizeof(cfEncoding[0]);
    for (i = 0; i < count; i++) {
        if (cfEncoding[i] == kCFStringEncodingInvalidId) {  // separator
            [menu addItem:[NSMenuItem separatorItem]];
            //TRACE(@"separator ===============================");
        }
        else {
            encodingString = NSStringFromSubtitleEncoding(cfEncoding[i]);
            if (0 < [encodingString length]) {
                item = [menu addItemWithTitle:encodingString action:action keyEquivalent:@""];
                [item setTag:cfEncoding[i]];
            }
            //TRACE(@"encoding:[0x%08x] => [0x%08x]:\"%@\"",
            //      cfEncoding[i], nsEncoding, encodingString);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#if defined(DEBUG)
void TRACE(NSString* format, ...)
{
    va_list arg;
    va_start(arg, format);
    NSLogv(format, arg);
    va_end(arg);
}
#endif

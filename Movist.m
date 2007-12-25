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

#import "Movist.h"
#import "MSubtitle.h"

#pragma mark notifications: movie

NSString* MMovieIndexDurationNotification       = @"MMovieIndexDurationNotification";
NSString* MMovieRateChangeNotification          = @"MMovieRateChangeNotification";
NSString* MMovieCurrentTimeNotification         = @"MMovieCurrentTimeNotification";
NSString* MMovieEndNotification                 = @"MMovieEndNotification";

#pragma mark notifications: etc

NSString* MMovieRectUpdateNotification          = @"MMovieRectUpdateNotification";

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSWindow (Movist)

- (void)setMovieURL:(NSURL*)movieURL
{
    if (!movieURL) {
        [self setTitleWithRepresentedFilename:@""];
        [self setTitle:[NSApp localizedAppName]];
    }
    else if ([movieURL isFileURL]) {
        [self setTitleWithRepresentedFilename:[movieURL path]];
    }
    else {
        [self setTitleWithRepresentedFilename:@""];
        [self setTitle:[[movieURL absoluteString] lastPathComponent]];
    }
}

- (void)fadeWithEffect:(NSString*)effect
          blockingMode:(NSAnimationBlockingMode)blockingMode
              duration:(float)duration
{
    NSArray* array = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            self, NSViewAnimationTargetKey,
            effect, NSViewAnimationEffectKey,
            nil],
        nil];
    NSViewAnimation* animation = [[NSViewAnimation alloc] initWithViewAnimations:array];
    [animation setAnimationBlockingMode:blockingMode];
    [animation setDuration:duration];
    [animation startAnimation];
    [animation release];
}

- (NSColor*)makeHUDBackgroundColor
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSView* cv = [self contentView];
    NSSize bgSize = [cv convertSize:[self frame].size fromView:nil];
    NSImage* bg = [[NSImage alloc] initWithSize:bgSize];
    [bg lockFocus];

    float radius = 6.0;
    float titlebarHeight = 19.0;

    // make background
    NSBezierPath* bgPath = [NSBezierPath bezierPath];
    NSRect bgRect = NSMakeRect(0, 0, bgSize.width, bgSize.height - titlebarHeight);
    bgRect = [cv convertRect:bgRect fromView:nil];
    int minX = NSMinX(bgRect), midX = NSMidX(bgRect), maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect), midY = NSMidY(bgRect), maxY = NSMaxY(bgRect);
    
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    [bgPath lineToPoint:NSMakePoint(maxX, maxY)];
    [bgPath lineToPoint:NSMakePoint(minX, maxY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];

    [[NSColor colorWithCalibratedWhite:0.1 alpha:0.75] set];
    [bgPath fill];

    // make titlebar
    NSBezierPath* titlePath = [NSBezierPath bezierPath];
    NSRect titlebarRect = NSMakeRect(0, bgSize.height - titlebarHeight, bgSize.width, titlebarHeight);
    titlebarRect = [cv convertRect:titlebarRect fromView:nil];
    minX = NSMinX(titlebarRect), midX = NSMidX(titlebarRect), maxX = NSMaxX(titlebarRect);
    minY = NSMinY(titlebarRect), midY = NSMidY(titlebarRect), maxY = NSMaxY(titlebarRect);

    [titlePath moveToPoint:NSMakePoint(minX, minY)];
    [titlePath lineToPoint:NSMakePoint(maxX, minY)];
    [titlePath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                        toPoint:NSMakePoint(midX, maxY) 
                                         radius:radius];
    [titlePath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                        toPoint:NSMakePoint(minX, minY) 
                                         radius:radius];
    [titlePath closePath];

    [[NSColor colorWithCalibratedWhite:0.25 alpha:0.75] set];
    [titlePath fill];

    [bg unlockFocus];

    return [NSColor colorWithPatternImage:[bg autorelease]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSTextField (Movist)

- (void)setEnabled:(BOOL)enabled
{
    [self setTextColor:enabled ? [NSColor controlTextColor] :
                                 [NSColor disabledControlTextColor]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSScreen (Movist)

static NSWindow* _fadeWindow = 0;

- (void)fadeOut:(float)duration
{
    _fadeWindow = [[NSWindow alloc] initWithContentRect:[self frame]
                                              styleMask:NSBorderlessWindowMask
                                                backing:NSBackingStoreBuffered
                                                  defer:FALSE
                                                 screen:self];
    [_fadeWindow setBackgroundColor:[NSColor blackColor]];
    [_fadeWindow setLevel:NSScreenSaverWindowLevel];
    [_fadeWindow useOptimizedDrawing:TRUE];
    [_fadeWindow setHasShadow:FALSE];
    [_fadeWindow setOpaque:FALSE];
    [_fadeWindow setAlphaValue:0.0];

    [_fadeWindow orderFront:self];
    [_fadeWindow fadeWithEffect:NSViewAnimationFadeInEffect
                   blockingMode:NSAnimationBlocking
                       duration:duration];
}

- (void)fadeIn:(float)duration
{
    if (0 < duration) {
        [_fadeWindow fadeWithEffect:NSViewAnimationFadeOutEffect
                       blockingMode:NSAnimationBlocking
                           duration:duration];
    }
    [_fadeWindow orderOut:self];
    [_fadeWindow release];
    _fadeWindow = 0;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSString (Movist)

- (BOOL)hasAnyExtension:(NSArray*)extensions
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, self);
    NSString* ext = [self pathExtension];
    if (![ext isEqualToString:@""]) {
        NSString* type;
        NSEnumerator* enumerator = [extensions objectEnumerator];
        while (type = [enumerator nextObject]) {
            if ([type caseInsensitiveCompare:ext] == NSOrderedSame) {
                return TRUE;
            }
        }
    }
    return FALSE;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSFileManager (Movist)

- (NSString*)pathContentOfLinkAtPath:(NSString*)path
{
    NSString* linkPath = [self pathContentOfSymbolicLinkAtPath:path];
    if (!linkPath) {
        linkPath = [self pathContentOfAliasAtPath:path];
    }
    return (linkPath) ? linkPath : nil;
}

- (NSString*)pathContentOfAliasAtPath:(NSString*)path
{
    FSRef ref;
    if (noErr == FSPathMakeRef((const UInt8*)[path UTF8String], &ref, 0)) {
        Boolean targetIsFolder, wasAliased;
        if (noErr == FSResolveAliasFile(&ref, TRUE, &targetIsFolder, &wasAliased) &&
            wasAliased) {
            UInt8 s[PATH_MAX + 1];
            if (noErr == FSRefMakePath(&ref, s, PATH_MAX)) {
                return [NSString stringWithUTF8String:(const char*)s];
            }
        }
    }    
    return nil;
}

- (BOOL)isVisibleFile:(NSString*)path isDirectory:(BOOL*)isDirectory
{
    if (![self fileExistsAtPath:path isDirectory:isDirectory]) {
        return FALSE;
    }
    if ([[path lastPathComponent] hasPrefix:@"."] || [path hasSuffix:@".app"]) {
        return FALSE;
    }
    FSRef possibleInvisibleFile;
    FSCatalogInfo catalogInfo;
    if (noErr != FSPathMakeRef((const UInt8*)[path fileSystemRepresentation],
                               &possibleInvisibleFile, nil)) {
        return FALSE;
    }
    FSGetCatalogInfo(&possibleInvisibleFile, kFSCatInfoFinderInfo, 
                     &catalogInfo, nil, nil, nil);
    if (((FileInfo*)catalogInfo.finderInfo)->finderFlags & kIsInvisible) {
        return FALSE;
    }
    NSString* hiddenFile = [NSString stringWithContentsOfFile:@"/.hidden"];
    NSArray* dotHiddens = [hiddenFile componentsSeparatedByString:@"\n"];
    if ([dotHiddens containsObject:[path lastPathComponent]] ||
        [path isEqualToString:@"/Network"] ||
        [path isEqualToString:@"/automount"] ||
        [path isEqualToString:@"/etc"] ||
        [path isEqualToString:@"/tmp"] ||
        [path isEqualToString:@"/var"]) {
        return FALSE;
    }
    return TRUE;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSApplication (Movist)

- (NSString*)localizedAppName
{
    return [[NSBundle mainBundle] localizedStringForKey:@"CFBundleName"
                                                  value:@"Movist"
                                                  table:@"InfoPlist"];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

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

float normalizedVolume(float volume)
{
    return (float)(int)((volume + 0.05f) * 10) / 10;  // make "x.x"
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

NSString* NSStringFromLetterBoxHeight(int height)
{
    return (height == LETTER_BOX_HEIGHT_DEFAULT) ?
                NSLocalizedString(@"Align Image to Center", nil) :
                [NSString stringWithFormat:
                    NSLocalizedString(@"%d Line(s) Height", nil), height];
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
            [[filenames objectAtIndex:0] hasAnyExtension:[MSubtitle subtitleTypes]]) {
            return DRAG_ACTION_REPLACE_SUBTITLE_FILE;
        }
        else {
            return (defaultPlay) ? DRAG_ACTION_PLAY_FILES : DRAG_ACTION_ADD_FILES;
        }
    }
    else if ([type isEqualToString:NSURLPboardType]) {
        NSString* s = [[NSURL URLFromPasteboard:pboard] absoluteString];
        if ([s hasAnyExtension:[MSubtitle subtitleTypes]]) {
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
        //kCFStringEncodingUTF16,
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
    NSStringEncoding nsEncoding;
    int i, count = sizeof(cfEncoding) / sizeof(cfEncoding[0]);
    for (i = 0; i < count; i++) {
        if (cfEncoding[i] == kCFStringEncodingInvalidId) {  // separator
            [menu addItem:[NSMenuItem separatorItem]];
            //TRACE(@"separator ===============================");
        }
        else {
            nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding[i]);
            encodingString = [NSString localizedNameOfStringEncoding:nsEncoding];
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

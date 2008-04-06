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

#import "MovistExtensions.h"

@implementation NSTextField (Movist)

- (void)setEnabled:(BOOL)enabled
{
    [self setTextColor:enabled ? [NSColor controlTextColor] :
     [NSColor disabledControlTextColor]];
}

@end

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

- (NSComparisonResult)caseInsensitiveNumericCompare:(NSString*)aString
{
    return [self compare:aString options:NSCaseInsensitiveSearch | NSNumericSearch];
}

#define rangeOfStringOption (NSCaseInsensitiveSearch | NSLiteralSearch)

- (NSRange)rangeOfString:(NSString*)s range:(NSRange)range
{
    //TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, NSStringFromRange(range));
    return [self rangeOfString:s options:rangeOfStringOption range:range];
}

- (NSRange)rangeOfString:(NSString*)s rangePtr:(NSRange*)range
{
    //TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, s, NSStringFromRange(*range));
    NSRange r = [self rangeOfString:s range:*range];
    if (r.location != NSNotFound) {
        int n = NSMaxRange(r) - range->location;
        range->location += n;
        range->length   -= n;
    }
    return r;
}

- (NSRange)tokenRangeForDelimiterSet:(NSCharacterSet*)delimiterSet rangePtr:(NSRange*)range
{
    //TRACE(@"%s %@ (%@)", __PRETTY_FUNCTION__, delimiterSet, NSStringFromRange(*range));
    NSRange result;
    int i = range->location, end = NSMaxRange(*range);
    while (i < end && [delimiterSet characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    result.location = i;
    while (i < end && ![delimiterSet characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    result.length = i - result.location;
    
    int n = NSMaxRange(result) - range->location;
    range->location += n;
    range->length   -= n;
    
    return result;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSMutableString (Movist)

- (void)removeLeftWhitespaces
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSCharacterSet* set = [NSCharacterSet whitespaceCharacterSet];
    
    int i, length = [self length];
    for (i = 0; i < length; i++) {
        if (![set characterIsMember:[self characterAtIndex:i]]) {
            if (0 < i) {
                [self deleteCharactersInRange:NSMakeRange(0, i)];
            }
            break;
        }
    }
}

- (void)removeRightWhitespaces
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSCharacterSet* set = [NSCharacterSet whitespaceCharacterSet];
    
    int i, length = [self length];
    for (i = length - 1; 0 <= i; i--) {
        if (![set characterIsMember:[self characterAtIndex:i]]) {
            if (i < length - 1) {
                [self deleteCharactersInRange:NSMakeRange(i + 1, length - (i + 1))];
            }
            break;
        }
    }
}

- (void)removeNewLineCharacters
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self replaceOccurrencesOfString:@"\r" withString:@""
                             options:0 range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"\n" withString:@""
                             options:0 range:NSMakeRange(0, [self length])];
}

- (unsigned int)replaceOccurrencesOfString:(NSString*)target
                                withString:(NSString*)replacement
{
    //TRACE(@"%s \"%@\" with \"%@\"", __PRETTY_FUNCTION__, target, replacement);
    return [self replaceOccurrencesOfString:target
                                 withString:replacement
                                    options:rangeOfStringOption
                                      range:NSMakeRange(0, [self length])];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSIndexSet (Movist)

+ (id)indexSetWithIndexes:(int)index, ...
{
    NSMutableIndexSet* set = [NSMutableIndexSet indexSet];

    va_list vargs;
    va_start(vargs, index);
    while (0 <= index) {
        [set addIndex:(unsigned int)index];
        index = va_arg(vargs, int);
    }
    va_end(vargs);

    return set;
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
    return linkPath;
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

- (NSArray*)sortedDirectoryContentsAtPath:(NSString*)path
{
    NSMutableArray* contents = [[self directoryContentsAtPath:path] mutableCopy];
    [contents sortUsingSelector:@selector(caseInsensitiveNumericCompare:)];
    return [contents autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSUserDefaults (Movist)

- (NSColor*)colorForKey:(NSString*)key
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, key);
    NSData* data = [self dataForKey:key];
    return (!data) ? nil : (NSColor*)[NSUnarchiver unarchiveObjectWithData:data];
}

- (void)setColor:(NSColor*)color forKey:(NSString*)key
{
    //TRACE(@"%s %@ for \"%@\"", __PRETTY_FUNCTION__, color, key);
    NSData* data = [NSArchiver archivedDataWithRootObject:color];
    [self setObject:data forKey:key];
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

@implementation ScreenFader

+ (id)screenFaderWithScreen:(NSScreen*)screen
{
    return [[[ScreenFader alloc] initWithScreen:screen] autorelease];
}

- (id)initWithScreen:(NSScreen*)screen
{
    if (self = [super init]) {
        _screen = [screen retain];
    }
    return self;
}

- (void)dealloc
{
    [_fadeWindow release];
    [_screen release];
    [super dealloc];
}

- (void)fadeOut:(float)duration
{
    if (_fadeWindow) {
        return;
    }
    
    _fadeWindow = [[NSWindow alloc] initWithContentRect:[_screen frame]
                                              styleMask:NSBorderlessWindowMask
                                                backing:NSBackingStoreBuffered
                                                  defer:FALSE screen:_screen];
    [_fadeWindow setBackgroundColor:[NSColor blackColor]];
    [_fadeWindow setLevel:NSScreenSaverWindowLevel];
    [_fadeWindow useOptimizedDrawing:TRUE];
    [_fadeWindow setHasShadow:FALSE];
    [_fadeWindow setOpaque:FALSE];
    [_fadeWindow setAlphaValue:0.0];
    
    [_fadeWindow orderFront:self];
    if (0 < duration) {
        [_fadeWindow fadeWithEffect:NSViewAnimationFadeInEffect
                       blockingMode:NSAnimationBlocking
                           duration:duration];
    }
    else {
        [_fadeWindow setAlphaValue:1.0];
    }
}

- (void)fadeIn:(float)duration
{
    if (!_fadeWindow) {
        return;
    }
    
    if (0 < duration) {
        [_fadeWindow fadeWithEffect:NSViewAnimationFadeOutEffect
                       blockingMode:NSAnimationBlocking
                           duration:duration];
    }
    [_fadeWindow orderOut:self];
    [_fadeWindow release];
    _fadeWindow = nil;
}

@end

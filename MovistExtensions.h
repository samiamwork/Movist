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

#import <Cocoa/Cocoa.h>

@interface NSCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell;
- (void)drawInRect:(NSRect)rect leftImage:(NSImage*)lImage
          midImage:(NSImage*)mImage rightImage:(NSImage*)rImage;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSControl (Movist)

- (void)replaceCell:(Class)cellClass;

@end

// override hidden message
@interface NSObject (NSTableViewPrivateMethods)

- (id)_highlightColorForCell:(NSCell*)cell;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSTextField (Movist)

- (void)setEnabled:(BOOL)enabled;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSWindow (Movist)

- (void)initHUDWindow;
- (void)initHUDSubviews;
- (void)cleanupHUDWindow;
- (void)updateHUDBackground;

- (void)setMovieURL:(NSURL*)movieURL;
- (void)fadeWithEffect:(NSString*)effect
          blockingMode:(NSAnimationBlockingMode)blockingMode
              duration:(float)duration;

@end

#define HUDTitleBackColor   [NSColor colorWithCalibratedWhite:0.1 alpha:0.85]
#define HUDBackgroundColor  [NSColor colorWithCalibratedWhite:0.1 alpha:0.80]
#define HUDBorderColor      [NSColor colorWithCalibratedWhite:0.2 alpha:0.75]
#define HUDTextColor        [NSColor colorWithCalibratedWhite:0.8 alpha:0.75]
#define HUDButtonTextColor  [NSColor colorWithCalibratedWhite:1.0 alpha:0.75]

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSString (Movist)

- (BOOL)hasAnyExtension:(NSArray*)extensions;
- (NSComparisonResult)caseInsensitiveNumericCompare:(NSString*)aString;

- (NSRange)rangeOfString:(NSString*)s range:(NSRange)range;
- (NSRange)rangeOfString:(NSString*)s rangePtr:(NSRange*)range;
- (NSRange)tokenRangeForDelimiterSet:(NSCharacterSet*)delimiterSet rangePtr:(NSRange*)range;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSMutableString (Movist)

- (void)removeLeftWhitespaces;
- (void)removeRightWhitespaces;
- (void)removeNewLineCharacters;
- (unsigned int)replaceOccurrencesOfString:(NSString*)target
                                withString:(NSString*)replacement;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSIndexSet (Movist)

+ (id)indexSetWithIndexes:(int)firstIndex, ...;     // -1 must be append for ending

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSFileManager (Movist)

- (NSString*)pathContentOfLinkAtPath:(NSString*)path;
- (NSString*)pathContentOfAliasAtPath:(NSString*)path;
- (BOOL)isVisibleFile:(NSString*)path isDirectory:(BOOL*)isDirectory;
- (NSArray*)sortedDirectoryContentsAtPath:(NSString*)path;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSUserDefaults (Movist)

- (NSColor*)colorForKey:(NSString*)key;
- (void)setColor:(NSColor*)color forKey:(NSString*)key;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSApplication (Movist)

- (NSString*)localizedAppName;
- (NSArray*)supportedFileExtensionsWithPrefix:(NSString*)prefix;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface ScreenFader : NSObject
{
    NSScreen* _screen;
    NSWindow* _fadeWindow;
}

+ (id)screenFaderWithScreen:(NSScreen*)screen;
- (id)initWithScreen:(NSScreen*)screen;

- (void)fadeOut:(float)duration;
- (void)fadeIn:(float)duration;

@end

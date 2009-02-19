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
#import "CustomControls.h"

#import <Carbon/Carbon.h>   // for kHIWindowVisibleInAllSpaces

@implementation NSCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    // cell attributes
    [self setType:[cell type]];
    [self setEnabled:[cell isEnabled]];
    [self setBezeled:[cell isBezeled]];
    [self setBordered:[cell isBordered]];

    // state
    [self setState:[cell state]];

    // textural attributes
    [self setEditable:[cell isEditable]];
    [self setSelectable:[cell isSelectable]];
    [self setScrollable:[cell isScrollable]];
    [self setAlignment:[cell alignment]];
    [self setFont:[cell font]];
    [self setLineBreakMode:[cell lineBreakMode]];
    [self setWraps:[cell wraps]];
    [self setBaseWritingDirection:[cell baseWritingDirection]];
    [self setAttributedStringValue:[cell attributedStringValue]];
    [self setAllowsEditingTextAttributes:[cell allowsEditingTextAttributes]];
    [self setImportsGraphics:[cell importsGraphics]];
    [self setTitle:[cell title]];

    // target/action
    [self setTarget:[cell target]];
    [self setAction:[cell action]];
    [self setContinuous:[cell isContinuous]];

    // image/tag
    [self setImage:[cell image]];
    [self setTag:[cell tag]];

    // drawing/highlighting
    [self setControlSize:[cell controlSize]];
    [self setControlTint:[cell controlTint]];
    [self setFocusRingType:[cell focusRingType]];
    [self setHighlighted:[cell isHighlighted]];
}

- (void)drawInRect:(NSRect)rect leftImage:(NSImage*)lImage
          midImage:(NSImage*)mImage rightImage:(NSImage*)rImage
{
    NSPoint p = rect.origin;
    [lImage setFlipped:TRUE];
    [lImage drawAtPoint:p fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];

    NSRect rc = rect;
    rc.origin.x    = rect.origin.x + [lImage size].width;
    rc.origin.y    = rect.origin.y;
    rc.size.width  = rect.size.width - [lImage size].width - [rImage size].width;
    rc.size.height = [mImage size].height;
    [mImage setFlipped:TRUE];
    [mImage drawInRect:rc fromRect:NSZeroRect
             operation:NSCompositeSourceOver fraction:1.0];
    
    p.x = NSMaxX(rect) - [rImage size].width;
    [rImage setFlipped:TRUE];
    [rImage drawAtPoint:p fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSControl (Movist)

- (void)replaceCell:(Class)cellClass
{
    if ([[self cell] class] != cellClass) {
        NSCell* newCell = [[[cellClass alloc] init] autorelease];
        [newCell copyAttributesFromCell:[self cell]];
        [self setCell:newCell];
    }
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

@implementation NSButtonCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    NSButtonCell* buttonCell = (NSButtonCell*)cell;
    [self setAlternateImage:[buttonCell alternateImage]];
    [self setImagePosition:[buttonCell imagePosition]];
    [self setBackgroundColor:[buttonCell backgroundColor]];
    [self setBezelStyle:[buttonCell bezelStyle]];
    [self setGradientType:[buttonCell gradientType]];
    [self setImageDimsWhenDisabled:[buttonCell imageDimsWhenDisabled]];
    [self setTransparent:[buttonCell isTransparent]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSMenuItemCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    NSMenuItemCell* menuItemCell = (NSMenuItemCell*)cell;
    [self setHighlighted:[menuItemCell isHighlighted]];
    [self setMenuItem:[menuItemCell menuItem]];
    [self setMenuView:[menuItemCell menuView]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSPopUpButtonCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    NSPopUpButtonCell* popUpCell = (NSPopUpButtonCell*)cell;
    [self setMenu:[popUpCell menu]];
    [self setPullsDown:[popUpCell pullsDown]];
    [self setAutoenablesItems:[popUpCell autoenablesItems]];
    [self setPreferredEdge:[popUpCell preferredEdge]];
    [self setUsesItemFromMenu:[popUpCell usesItemFromMenu]];
    [self setAltersStateOfSelectedItem:[popUpCell altersStateOfSelectedItem]];
    [self setArrowPosition:[popUpCell arrowPosition]];
    [self selectItem:[popUpCell selectedItem]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSSegmentedCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    NSSegmentedCell* segmentedCell = (NSSegmentedCell*)cell;
    [self setSegmentCount:[segmentedCell segmentCount]];
    [self setTrackingMode:[segmentedCell trackingMode]];
    if (0 <= [segmentedCell selectedSegment]) {
        [self setSelectedSegment:[segmentedCell selectedSegment]];
    }
    int i, count = [self segmentCount];
    for (i = 0; i < count; i++) {
        [self setImage:[segmentedCell imageForSegment:i] forSegment:i];
        [self setLabel:[segmentedCell labelForSegment:i] forSegment:i];
        //[self setWidth:[segmentedCell widthForSegment:i] forSegment:i];
        [self setWidth:0 forSegment:i];     // always auto size
        [self setEnabled:[segmentedCell isEnabledForSegment:i] forSegment:i];
        [self setToolTip:[segmentedCell toolTipForSegment:i] forSegment:i];
        [self setMenu:[segmentedCell menuForSegment:i] forSegment:i];
        [self setTag:[segmentedCell tagForSegment:i] forSegment:i];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSSliderCell (Movist)

- (void)copyAttributesFromCell:(NSCell*)cell
{
    [super copyAttributesFromCell:cell];

    NSSliderCell* sliderCell = (NSSliderCell*)cell;
    [self setSliderType:[sliderCell sliderType]];
    [self setMaxValue:[sliderCell maxValue]];
    [self setMinValue:[sliderCell minValue]];
    [self setDoubleValue:[sliderCell doubleValue]];
    [self setTickMarkPosition:[sliderCell tickMarkPosition]];
    [self setNumberOfTickMarks:[sliderCell numberOfTickMarks]];
    [self setAltIncrementValue:[sliderCell altIncrementValue]];
    [self setAllowsTickMarkValuesOnly:[sliderCell allowsTickMarkValuesOnly]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation NSWindow (Movist)

- (void)initHUDWindow
{
    [self setOpaque:FALSE];
    [self setAlphaValue:1.0];
    [self setHasShadow:FALSE];
    [self useOptimizedDrawing:TRUE];
    [self setMovableByWindowBackground:TRUE];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hudWindowDidResize:)
               name:NSWindowDidResizeNotification object:self];
}

- (void)cleanupHUDWindow
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSWindowDidResizeNotification object:self];
    [super dealloc];
}

- (void)initHUDSubview:(NSView*)subview
{
    if ([subview isKindOfClass:[NSTextField class]]) {
        [(NSTextField*)subview setTextColor:HUDTextColor];
    }
    else if ([subview isMemberOfClass:[NSBox class]]) {
        [[(NSBox*)subview titleCell] setTextColor:HUDTextColor];
    }
    else if ([subview isMemberOfClass:[NSButton class]] &&
             [(NSButton*)subview isBordered]) {
        [(NSButton*)subview replaceCell:[HUDButtonCell class]];
    }
    else if ([subview isMemberOfClass:[NSPopUpButton class]]) {
        [(NSPopUpButton*)subview replaceCell:[HUDPopUpButtonCell class]];
    }
    else if ([subview isMemberOfClass:[NSSlider class]] &&
             [[(NSSlider*)subview cell] isMemberOfClass:[NSSliderCell class]]) {
        [(NSSlider*)subview replaceCell:[HUDSliderCell class]];
    }
    else if ([subview isMemberOfClass:[NSSegmentedControl class]]) {
        [(NSSegmentedControl*)subview replaceCell:[HUDSegmentedCell class]];
    }
    else if ([subview isMemberOfClass:[NSTableView class]]) {
        [(NSTableView*)subview setBackgroundColor:
            [NSColor colorWithCalibratedWhite:0.05 alpha:0.75]];
    }

    // do it all subviews recursively
    if ([subview isKindOfClass:[NSTabView class]]) {
        NSTabViewItem* tabItem;
        NSEnumerator* enumerator = [[(NSTabView*)subview tabViewItems] objectEnumerator];
        while (tabItem = [enumerator nextObject]) {
            [self initHUDSubview:[tabItem view]];
        }
    }
    else {
        NSEnumerator* enumerator = [[subview subviews] objectEnumerator];
        while (subview = [enumerator nextObject]) {
            [self initHUDSubview:subview];
        }
    }
}

- (void)initHUDSubviews { [self initHUDSubview:[self contentView]]; }

- (void)updateHUDBackground
{
    NSView* cv = [self contentView];
    NSSize bgSize = [cv convertSize:[self frame].size fromView:nil];
    NSImage* bgImage = [[[NSImage alloc] initWithSize:bgSize] autorelease];
    [bgImage lockFocus];

    float radius = 6.0;
    float titlebarHeight = 19.0;
    if ([self isSheet] || [self standardWindowButton:NSWindowCloseButton]) {
        titlebarHeight = 0.0;
    }

    // make background
    NSBezierPath* bgPath = [NSBezierPath bezierPath];
    NSRect bgRect = NSMakeRect(0, 0, bgSize.width, bgSize.height - titlebarHeight);
    bgRect = [cv convertRect:bgRect fromView:nil];
    int minX = NSMinX(bgRect), midX = NSMidX(bgRect), maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect), midY = NSMidY(bgRect), maxY = NSMaxY(bgRect);

    [bgPath setFlatness:0.01];
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

    [HUDBackgroundColor set];   [bgPath fill];
    [HUDBorderColor set];       [bgPath stroke];

    if (0 < titlebarHeight) {   // make titlebar
        NSBezierPath* titlePath = [NSBezierPath bezierPath];
        NSRect titlebarRect = NSMakeRect(0, bgSize.height - titlebarHeight, bgSize.width, titlebarHeight);
        titlebarRect = [cv convertRect:titlebarRect fromView:nil];
        minX = NSMinX(titlebarRect), midX = NSMidX(titlebarRect), maxX = NSMaxX(titlebarRect);
        minY = NSMinY(titlebarRect), midY = NSMidY(titlebarRect), maxY = NSMaxY(titlebarRect);

        [titlePath setFlatness:0.01];
        [titlePath moveToPoint:NSMakePoint(minX, minY)];
        [titlePath lineToPoint:NSMakePoint(maxX, minY)];
        [titlePath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                            toPoint:NSMakePoint(midX, maxY) 
                                             radius:radius];
        [titlePath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                            toPoint:NSMakePoint(minX, minY) 
                                             radius:radius];
        [titlePath closePath];

        [HUDTitleBackColor set];    [titlePath fill];
        [HUDBorderColor set];       [titlePath stroke];
    }
    [bgImage unlockFocus];

    [self setBackgroundColor:[NSColor colorWithPatternImage:bgImage]];
}

- (void)hudWindowDidResize:(NSNotification*)aNotification
{
    [self updateHUDBackground];
}

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

- (void)fadeWithEffect:(NSString*)effect duration:(float)duration
{
    NSArray* array = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            self, NSViewAnimationTargetKey,
            effect, NSViewAnimationEffectKey,
            nil],
        nil];
    NSViewAnimation* animation = [[NSViewAnimation alloc] initWithViewAnimations:array];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setDuration:duration];
    [animation setDelegate:self];
    [animation startAnimation];
    [animation release];
}

- (void)fadeIn:(float)duration  { [self fadeWithEffect:NSViewAnimationFadeInEffect duration:duration]; }
- (void)fadeOut:(float)duration { [self fadeWithEffect:NSViewAnimationFadeOutEffect duration:duration]; }

- (void)setAlwaysOnTop:(BOOL)alwaysOnTop
{
    // enhancement for Expose & Spaces
    // based on patch of Chan-gu Lee <maidaro@gmail.com>.
    if (alwaysOnTop) {
        [self setLevel:TopMostWindowLevel];
    }
    else {
        [self setLevel:NSNormalWindowLevel];
    }

    HIWindowRef windowRef = (HIWindowRef)[self windowRef];
    HIWindowAvailability windowAvailability = 0;
    HIWindowGetAvailability(windowRef, &windowAvailability);
    if (!(windowAvailability & kHIWindowExposeHidden)) {
        HIWindowChangeAvailability(windowRef, kHIWindowExposeHidden, 0);
    }
    HIWindowChangeAvailability(windowRef, 0, kHIWindowExposeHidden);
    /*
    if (isSystemLeopard()) {
        if (alwaysOnTop) {
            HIWindowChangeAvailability(windowRef, kHIWindowVisibleInAllSpaces, 0);
        }
        else {
            HIWindowChangeAvailability(windowRef, 0, kHIWindowVisibleInAllSpaces);
        }
        [self orderFront:self];
    }
     */
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

@implementation NSMutableAttributedString (Movist)

NSString* const MFontBoldAttributeName   = @"MFontBoldAttributeName";
NSString* const MFontItalicAttributeName = @"MFontItalicAttributeName";

- (void)applyFont:(NSFont*)font
        fontTrait:(NSFontTraitMask)fontTrait
    attributeName:(NSString*)attributeName
{
    //TRACE(@"%s \"%@\" %d", __PRETTY_FUNCTION__, attributeName, fontTrait);
    NSString* attrName = NSFontAttributeName;
    id attrValue = [[NSFontManager sharedFontManager] convertFont:font
                                                      toHaveTrait:fontTrait];
    if (attrValue == font) {    // no available font for fontTrait
        if (fontTrait != NSItalicFontMask || [font italicAngle] != 0.0) {
            return;
        }
        // use alternative attribute NSObliqnessAttributeName for italic
        attrName = NSObliquenessAttributeName;
        attrValue = [NSNumber numberWithFloat:0.3];
    }

    NSNumber* n;
    NSRange attrRange;
    NSRange range = NSMakeRange(0, [self length]);
    while (0 < range.length) {
        n = [self attribute:attributeName atIndex:range.location
      longestEffectiveRange:&attrRange inRange:range];
        if (n) {
            [self addAttribute:attrName value:attrValue range:attrRange];
            range = NSMakeRange(NSMaxRange(attrRange),
                                NSMaxRange(range) - NSMaxRange(attrRange));
        }
        else {
            range.location++;
            range.length--;
        }
    }
}

- (void)applyFont:(NSFont*)font textColor:(NSColor*)textColor
      strokeColor:(NSColor*)strokeColor strokeWidth:(NSNumber*)strokeWidth
   paragraphStyle:(NSParagraphStyle*)paragraphStyle
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSRange range = NSMakeRange(0, [self length]);
    [self addAttribute:NSFontAttributeName value:font range:range];

    NSColor* c;
    NSRange r;  r.length = 1;
    for (r.location = 0; r.location < range.length; r.location++) {
        c = [self attribute:NSForegroundColorAttributeName atIndex:r.location effectiveRange:nil];
        c = (!c) ? textColor : [NSColor colorWithCalibratedRed:[c redComponent]
                                                         green:[c greenComponent]
                                                          blue:[c blueComponent]
                                                         alpha:[textColor alphaComponent]];
        [self addAttribute:NSForegroundColorAttributeName value:c range:r];
    }
    [self applyFont:font fontTrait:NSItalicFontMask attributeName:MFontItalicAttributeName];
    [self applyFont:font fontTrait:NSBoldFontMask attributeName:MFontBoldAttributeName];

    [self addAttribute:NSStrokeColorAttributeName value:strokeColor range:range];
    if ([strokeWidth floatValue] != 0.0) {
        [self addAttribute:NSStrokeWidthAttributeName value:strokeWidth range:range];
    }

    [self addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    //[self addAttribute:NSKernAttributeName value:kern range:range];

    [self fixAttributesInRange:range];
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
    return (data) ? (NSColor*)[NSUnarchiver unarchiveObjectWithData:data] : nil;
}

- (void)setColor:(NSColor*)color forKey:(NSString*)key
{
    //TRACE(@"%s %@ for \"%@\"", __PRETTY_FUNCTION__, color, key);
    [self setObject:[NSArchiver archivedDataWithRootObject:color] forKey:key];
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

- (NSArray*)supportedFileExtensionsWithPrefix:(NSString*)prefix;
{
    NSMutableArray* exts = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];

    NSDictionary* dict = [[NSBundle mainBundle] infoDictionary];
    NSDictionary* type;
    NSString* bundleTypeName;
    NSArray* types = [dict objectForKey:@"CFBundleDocumentTypes"];
    NSEnumerator* typeEnumerator = [types objectEnumerator];
    while (type = [typeEnumerator nextObject]) {
        bundleTypeName = [type objectForKey:@"CFBundleTypeName"];
        if ([bundleTypeName hasPrefix:prefix]) {
            [exts addObjectsFromArray:[type objectForKey:@"CFBundleTypeExtensions"]];
        }
    }
    return exts;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation ScreenFader

+ (id)screenFaderWithScreens:(NSArray*)screens
{
    return [[[ScreenFader alloc] initWithScreens:screens] autorelease];
}

+ (id)screenFaderWithScreen:(NSScreen*)screen
{
    return [[[ScreenFader alloc] initWithScreen:screen] autorelease];
}

- (id)initWithScreens:(NSArray*)screens
{
    if (self = [super init]) {
        _screens = [screens retain];
    }
    return self;
}

- (id)initWithScreen:(NSScreen*)screen
{
    return [self initWithScreens:[NSArray arrayWithObject:screen]];
}

- (void)dealloc
{
    [_fadeWindows release];
    [_screens release];
    [super dealloc];
}

- (void)fadeOut:(float)duration
{
    if (_fadeWindows) {
        return;
    }

    _fadeWindows = [[NSMutableArray alloc] initWithCapacity:[_screens count]];
    NSMutableArray* animations = nil;
    if (0 < duration) {
        animations = [NSMutableArray arrayWithCapacity:[_fadeWindows count]];
    }

    NSScreen* screen;
    NSWindow* window;
    NSEnumerator* enumerator = [_screens objectEnumerator];
    while (screen = [enumerator nextObject]) {
        window = [[NSWindow alloc] initWithContentRect:[screen frame]
                                             styleMask:NSBorderlessWindowMask
                                               backing:NSBackingStoreBuffered
                                                 defer:FALSE screen:screen];
        [window setBackgroundColor:[NSColor blackColor]];
        [window setLevel:NSScreenSaverWindowLevel];
        [window useOptimizedDrawing:TRUE];
        [window setHasShadow:FALSE];
        [window setOpaque:FALSE];
        [window setAlphaValue:0.0];
        [window orderFront:self];

        if (animations) {
            [animations addObject:
             [NSDictionary dictionaryWithObjectsAndKeys:
                            window, NSViewAnimationTargetKey,
                            NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
                            nil]];
        }
        [_fadeWindows addObject:window];
        [window release];
    }

    if (animations) {
        NSViewAnimation* animation = [NSViewAnimation alloc];
        [animation initWithViewAnimations:animations];
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation setDuration:duration];
        [animation startAnimation];
        [animation release];
    }
    else {
        NSWindow* window;
        NSEnumerator* enumerator = [_fadeWindows objectEnumerator];
        while (window = [enumerator nextObject]) {
            [window setAlphaValue:1.0];
        }
    }
}

- (void)fadeIn:(float)duration
{
    if (!_fadeWindows) {
        return;
    }

    if (0 < duration) {
        NSMutableArray* animations;
        animations = [NSMutableArray arrayWithCapacity:[_fadeWindows count]];

        NSWindow* window;
        NSEnumerator* enumerator = [_fadeWindows objectEnumerator];
        while (window = [enumerator nextObject]) {
            [animations addObject:
             [NSDictionary dictionaryWithObjectsAndKeys:
                            window, NSViewAnimationTargetKey,
                            NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
                            nil]];
        }

        NSViewAnimation* animation = [NSViewAnimation alloc];
        [animation initWithViewAnimations:animations];
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation setDuration:duration];
        [animation startAnimation];
        [animation release];
    }

    NSWindow* window;
    NSEnumerator* enumerator = [_fadeWindows objectEnumerator];
    while (window = [enumerator nextObject]) {
        [window orderOut:self];
    }
}

@end

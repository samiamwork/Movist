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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"
#import "MainWindow.h"
#import "MMovieView.h"
#import "MMovie_QuickTime.h"

@interface DetailsNode : NSObject
{
    NSString* _name;
}

- (id)initWithName:(NSString*)name;
- (NSString*)name;

@end

@implementation DetailsNode

- (id)initWithName:(NSString*)name
{
    if (self = [super init]) {
        _name = [name retain];
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (NSString*)name { return _name; }

@end

////////////////////////////////////////////////////////////////////////////////

@interface CategoryNode : DetailsNode
{
    NSArray* _children;
}

+ (id)categoryNodeWithName:(NSString*)name children:(NSArray*)children;
- (id)initWithName:(NSString*)name children:(NSArray*)children;
- (NSArray*)children;
- (NSString*)value;

@end

@interface CategoryCell : NSTextFieldCell {} @end

@implementation CategoryCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSImage* image = [NSImage imageNamed:@"OutlineCategoryMid"];
    NSRect bgRect = cellFrame;
    bgRect.origin.x -= 17, bgRect.size.width  += 17 + 3;
    bgRect.origin.y -= 1,  bgRect.size.height += 2;
    [image setFlipped:TRUE];
    [image drawInRect:bgRect fromRect:NSZeroRect
            operation:NSCompositeSourceOver fraction:1.0];

    float fontSize = [NSFont smallSystemFontSize];
    cellFrame.origin.x += 2, cellFrame.size.width  -= 2;
    cellFrame.origin.y += 1, cellFrame.size.height -= 2;
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSFont boldSystemFontOfSize:fontSize], NSFontAttributeName,
                           [NSColor grayColor], NSForegroundColorAttributeName,
                           nil];
    [[self stringValue] drawInRect:cellFrame withAttributes:attrs];
}

@end

@implementation CategoryNode

+ (id)categoryNodeWithName:(NSString*)name children:(NSArray*)children
{
    return [[[CategoryNode alloc] initWithName:name children:children] autorelease];
}

- (id)initWithName:(NSString*)name children:(NSArray*)children
{
    if (self = [super initWithName:name]) {
        _children = [children retain];
    }
    return self;
}

- (void)dealloc
{
    [_children release];
    [super dealloc];
}

- (NSArray*)children { return _children; }
- (NSString*)value { return @""; }

- (NSCell*)settingCell
{
    CategoryCell* cell = [[CategoryCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:FALSE];
    return [cell autorelease];
}

- (NSCell*)valueCell
{
    return [self settingCell];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface ValueNode : DetailsNode
{
    NSString* _key;
}

- (id)initWithName:(NSString*)name key:(NSString*)key;
- (NSString*)key;

@end

@implementation ValueNode

- (id)initWithName:(NSString*)name key:(NSString*)key
{
    if (self = [super initWithName:name]) {
        _key = [key retain];
    }
    return self;
}

- (void)dealloc
{
    [_key release];
    [super dealloc];
}

- (NSString*)key { return _key; }

- (NSCell*)settingCell
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:FALSE];
    return [cell autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface BoolNode : ValueNode
{
}

+ (id)boolNodeWithName:(NSString*)name key:(NSString*)key;

- (NSNumber*)value;
- (void)setValue:(NSNumber*)boolNumber;

@end

@implementation BoolNode

+ (id)boolNodeWithName:(NSString*)name key:(NSString*)key
{
    return [[[BoolNode alloc] initWithName:name key:key] autorelease];
}

- (NSNumber*)value
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [NSNumber numberWithBool:[defaults boolForKey:_key]];
}

- (void)setValue:(NSNumber*)boolNumber
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[boolNumber boolValue] forKey:_key];
}

- (NSCell*)valueCell
{
    NSButtonCell* cell = [[NSButtonCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setButtonType:NSSwitchButton];
    return [cell autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface IntNode : ValueNode
{
    int _minValue;
    int _maxValue;
}

+ (id)intNodeWithName:(NSString*)name key:(NSString*)key
             minValue:(int)minValue maxValue:(int)maxValue;
- (id)initWithName:(NSString*)name key:(NSString*)key
          minValue:(int)minValue maxValue:(int)maxValue;
- (NSNumber*)value;
- (void)setValue:(NSNumber*)intNumber;

@end

@implementation IntNode

+ (id)intNodeWithName:(NSString*)name key:(NSString*)key
             minValue:(int)minValue maxValue:(int)maxValue
{
    return [[[IntNode alloc] initWithName:name key:key
                                 minValue:minValue maxValue:maxValue] autorelease];
}

- (id)initWithName:(NSString*)name key:(NSString*)key
          minValue:(int)minValue maxValue:(int)maxValue
{
    if (self = [super initWithName:name key:key]) {
        _minValue = minValue;
        _maxValue = maxValue;
    }
    return self;
}

- (NSNumber*)value
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [NSNumber numberWithInt:[defaults integerForKey:_key]];
}

- (void)setValue:(NSNumber*)intNumber
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[intNumber intValue] forKey:_key];
}

- (NSCell*)valueCell
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormat:@"0"];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    if (_minValue <= _maxValue) {
        [formatter setMinimum:[NSNumber numberWithInt:_minValue]];
        [formatter setMaximum:[NSNumber numberWithInt:_maxValue]];
    }
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setFormatter:[formatter autorelease]];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:TRUE];
    return [cell autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface StringNode : ValueNode
{
}

+ (id)stringNodeWithName:(NSString*)name key:(NSString*)key;

- (NSString*)value;
- (void)setValue:(NSString*)string;

@end

@implementation StringNode

+ (id)stringNodeWithName:(NSString*)name key:(NSString*)key
{
    return [[[StringNode alloc] initWithName:name key:key] autorelease];
}

- (NSString*)value
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:_key];
}

- (void)setValue:(NSString*)string
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:string forKey:_key];
}

- (NSCell*)valueCell
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [cell setEditable:TRUE];
    return [cell autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface SelectNode : ValueNode
{
    NSArray* _titles;
}

+ (id)selectNodeWithName:(NSString*)name key:(NSString*)key titles:(NSArray*)titles;
- (id)initWithName:(NSString*)name key:(NSString*)key titles:(NSArray*)titles;
- (NSNumber*)value;
- (void)setValue:(NSNumber*)index;

@end

@implementation SelectNode

+ (id)selectNodeWithName:(NSString*)name key:(NSString*)key titles:(NSArray*)titles
{
    return [[[SelectNode alloc] initWithName:name key:key titles:titles] autorelease];
}

- (id)initWithName:(NSString*)name key:(NSString*)key titles:(NSArray*)titles
{
    if (self = [super initWithName:name key:key]) {
        _titles = [titles retain];
    }
    return self;
}

- (void)dealloc
{
    [_titles release];
    [super dealloc];
}

- (NSNumber*)value
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [NSNumber numberWithInt:[defaults integerForKey:_key]];
}

- (void)setValue:(NSNumber*)intNumber
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[intNumber intValue] forKey:_key];
}

- (NSCell*)valueCell
{
    NSPopUpButtonCell* cell = [[NSPopUpButtonCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell addItemsWithTitles:_titles];
    [cell setBordered:FALSE];
    return [cell autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define LABEL(s)    NSLocalizedString(s, nil)
#define LABEL_R(s)  [NSLocalizedString(s, nil) stringByAppendingString:@" *"]

@implementation PreferenceController (Advanced_Details)

- (void)initDetails
{
    NSMutableArray* categories = [[NSMutableArray alloc] initWithCapacity:3];

    // "General" category
    [categories addObject:
     [CategoryNode categoryNodeWithName:LABEL(@"General") children:
      [NSArray arrayWithObjects:
       [BoolNode boolNodeWithName:LABEL(@"Activate on Dragging over Main Window")
                              key:MActivateOnDraggingKey],
       [BoolNode boolNodeWithName:LABEL(@"Auto Show Dock in Full Screen")
                              key:MAutoShowDockKey],
       [BoolNode boolNodeWithName:LABEL(@"Use Play-Panel in Full Screen")
                              key:MUsePlayPanelKey],
       [BoolNode boolNodeWithName:LABEL(@"Floating Playlist")
                              key:MFloatingPlaylistKey],
       [BoolNode boolNodeWithName:LABEL(@"Goto Begginning When Reopen Movie")
                              key:MGotoBegginingWhenReopenMovieKey],
       [BoolNode boolNodeWithName:LABEL(@"Goto Begginning When Open Subtitle")
                              key:MGotoBegginingWhenOpenSubtitleKey],
       [SelectNode selectNodeWithName:LABEL(@"Movie Resize Center")
                                  key:MMovieResizeCenterKey
                               titles:[NSArray arrayWithObjects:
                                       NSLocalizedString(@"Title Center", nil),
                                       NSLocalizedString(@"Title Left", nil),
                                       NSLocalizedString(@"Title Right", nil),
                                       NSLocalizedString(@"Bottom Center", nil),
                                       NSLocalizedString(@"Bottom Left", nil),
                                       NSLocalizedString(@"Bottom Right", nil),
                                       nil]],
       [SelectNode selectNodeWithName:LABEL(@"Window Resize Type")
                                  key:MWindowResizeModeKey
                               titles:[NSArray arrayWithObjects:
                                       NSLocalizedString(@"Free", nil),
                                       NSLocalizedString(@"Adjust to Size", nil),
                                       NSLocalizedString(@"Adjust to Width", nil),
                                       nil]],
       [SelectNode selectNodeWithName:LABEL(@"Dragging Action on Movie Area")
                                  key:MViewDragActionKey
                               titles:[NSArray arrayWithObjects:
                                       NSLocalizedString(@"None", nil),
                                       NSLocalizedString(@"Move Window", nil),
                                       NSLocalizedString(@"Capture Movie", nil),
                                       nil]],
       nil]]];

    // "Video" category
    [categories addObject:
     [CategoryNode categoryNodeWithName:LABEL(@"Video") children:
      [NSArray arrayWithObjects:
       [SelectNode selectNodeWithName:LABEL(@"Capture Format")
                                  key:MCaptureFormatKey
                               titles:[NSArray arrayWithObjects:
                                       NSLocalizedString(@"TIFF", nil),
                                       NSLocalizedString(@"JPEG", nil),
                                       NSLocalizedString(@"PNG", nil),
                                       NSLocalizedString(@"BMP", nil),
                                       NSLocalizedString(@"GIF", nil),
                                       nil]],
       [BoolNode boolNodeWithName:LABEL(@"Include Letter Box on Capture")
                              key:MIncludeLetterBoxOnCaptureKey],
       [BoolNode boolNodeWithName:LABEL(@"Remove Green Box")
                              key:MRemoveGreenBoxKey],
       [IntNode intNodeWithName:LABEL_R(@"Video Queue Capacity (8~99)")
                            key:MVideoQueueCapacityKey minValue:8 maxValue:99],
       nil]]];

    // "Subtitle" category
    [categories addObject:
     [CategoryNode categoryNodeWithName:LABEL(@"Subtitle") children:
      [NSArray arrayWithObjects:
       [BoolNode boolNodeWithName:LABEL_R(@"Use QuickTime/Perian Subtitles")
                              key:MUseQuickTimeSubtitlesKey],
       [BoolNode boolNodeWithName:LABEL_R(@"Auto-Load Embedded Subtitles in MKV")
                              key:MAutoLoadMKVEmbeddedSubtitlesKey],
       [BoolNode boolNodeWithName:LABEL_R(@"Replace New-Line with <BR> for SAMI")
                              key:MSubtitleReplaceNLWithBRKey],
       [StringNode stringNodeWithName:LABEL_R(@"Default Subtitle Language Identifiers")
                                  key:MDefaultLanguageIdentifiersKey],
       [IntNode intNodeWithName:LABEL_R(@"Auto Letter Box Height Max Lines (1~3)")
                            key:MAutoLetterBoxHeightMaxLinesKey minValue:1 maxValue:3],
       nil]]];
    
    // "Full Screen Navigation" category
    [categories addObject:
     [CategoryNode categoryNodeWithName:LABEL(@"Full Screen Navigation") children:
      [NSArray arrayWithObjects:
       [StringNode stringNodeWithName:LABEL(@"Default Navigation Path")
                                  key:MFullNavPathKey],
       [BoolNode boolNodeWithName:LABEL(@"Show Actual Path for Alias or Symbolic-Link")
                              key:MShowActualPathForLinkKey],
       nil]]];

    _detailsCategories = categories;
    [_detailsOutlineView reloadData];
    [_detailsOutlineView setAction:@selector(detailsOutlineViewAction:)];

    if (isSystemTiger()) {
        CategoryNode* node;
        NSEnumerator* enumerator = [_detailsCategories objectEnumerator];
        while (node = [enumerator nextObject]) {
            [_detailsOutlineView expandItem:node];
        }
    }
    else {
        [_detailsOutlineView expandItem:nil expandChildren:TRUE];
    }
}

- (int)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item
{
    //TRACE(@"%s item=%@", __PRETTY_FUNCTION__, item);
    return (item == nil) ? [_detailsCategories count] :
           ([item class] == [CategoryNode class]) ? [[item children] count] : -1;
}

- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item
{
    //TRACE(@"%s item=%@", __PRETTY_FUNCTION__, item);
    return (item == nil) ? TRUE : [item class] == [CategoryNode class];
}

- (id)outlineView:(NSOutlineView*)outlineView child:(int)index ofItem:(id)item
{
    //TRACE(@"%s item=%@ child=%d", __PRETTY_FUNCTION__, item, index);
    return (item == nil) ? [_detailsCategories objectAtIndex:index] :
                           [[item children] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView*)outlineView
objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
    //TRACE(@"%s column=%@ item=%@", __PRETTY_FUNCTION__, [tableColumn identifier], item);
    return ([[tableColumn identifier] isEqualToString:@"setting"]) ? [item name] : [item value];
}

- (void)outlineView:(NSOutlineView*)outlineView
     setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
    //TRACE(@"%s column=%@ item=%@ value=%@", __PRETTY_FUNCTION__, [tableColumn identifier], item, object);
    [item setValue:object];

    NSString* key = [item key];
    // general
    if ([key isEqualToString:MActivateOnDraggingKey]) {
        [_movieView setActivateOnDragging:[object boolValue]];
    }
    else if ([key isEqualToString:MViewDragActionKey]) {
        [_movieView setViewDragAction:[object intValue]];
    }
    // video
    else if ([key isEqualToString:MCaptureFormatKey]) {
        [_movieView setCaptureFormat:[object intValue]];
    }
    else if ([key isEqualToString:MIncludeLetterBoxOnCaptureKey]) {
        [[NSApp delegate] setIncludeLetterBoxOnCapture:[object boolValue]];
    }
    else if ([key isEqualToString:MRemoveGreenBoxKey]) {
        [_movieView setRemoveGreenBox:[object boolValue]];
    }
    // subtitles
    else if ([key isEqualToString:MUseQuickTimeSubtitlesKey]) {
        [MMovie_QuickTime setUseQuickTimeSubtitles:[object boolValue]];
    }
    else if ([key isEqualToString:MSubtitleReplaceNLWithBRKey]) {
        [_appController reopenSubtitles];
    }
    else if ([key isEqualToString:MAutoLetterBoxHeightMaxLinesKey]) {
        [_movieView setAutoLetterBoxHeightMaxLines:[object intValue]];
    }
    // full-nav
}

- (void)detailsOutlineViewAction:(id)sender
{
    //TRACE(@"%s column=%d, row=%d", __PRETTY_FUNCTION__,
    //      [_detailsOutlineView clickedColumn], [_detailsOutlineView clickedRow]);
    if ([_detailsOutlineView clickedColumn] == 1) {   // "value" column
        [_detailsOutlineView editColumn:[_detailsOutlineView clickedColumn]
                                    row:[_detailsOutlineView clickedRow]
                              withEvent:nil select:TRUE];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark advanced-details table-column

@implementation AdvancedDetailsTableColumn

- (id)dataCellForRow:(int)rowIndex
{
    NSOutlineView* outlineView = (NSOutlineView*)[self tableView];
    if ([[self identifier] isEqualToString:@"setting"]) {
        id cell = [[outlineView itemAtRow:rowIndex] settingCell];
        return (cell) ? cell : [super dataCellForRow:rowIndex];
    }
    else {
        id cell = [[outlineView itemAtRow:rowIndex] valueCell];
        return (cell) ? cell : [super dataCellForRow:rowIndex];
    }
}

@end

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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "AppController.h"
#import "MMovieView.h"

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

- (NSCell*)dataCell
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:FALSE];
    return [cell autorelease];
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

@end

////////////////////////////////////////////////////////////////////////////////

@interface BoolNode : ValueNode
{
}

+ (id)boolNodeWithName:(NSString*)name key:(NSString*)key;

- (NSNumber*)value;
- (void)setValue:(NSNumber*)boolNumber;
- (NSCell*)dataCell;

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

- (NSCell*)dataCell
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
- (NSCell*)dataCell;

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

- (NSCell*)dataCell
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormat:@"#"];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    if (_minValue != 0 || _maxValue != 0) {
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
- (NSCell*)dataCell;

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

- (NSCell*)dataCell
{
    NSTextFieldCell* cell = [[NSTextFieldCell alloc] initTextCell:@""];
    [cell setControlSize:NSSmallControlSize];
    [cell setEditable:TRUE];
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
       [BoolNode boolNodeWithName:LABEL(@"Add Similar Files to Playlist for Opening File")
                              key:MAutodetectMovieSeriesKey],
       [BoolNode boolNodeWithName:LABEL_R(@"Auto-detect Digital Audio-Out")
                              key:MAutodetectDigitalAudioOutKey],
       [BoolNode boolNodeWithName:LABEL(@"Auto-Play On Full Screen")
                              key:MAutoPlayOnFullScreenKey],
       [BoolNode boolNodeWithName:LABEL(@"Capture Screenshot Including Letter Box")
                              key:MCaptureIncludingLetterBoxKey],
       nil]]];

    // "Subtitle" category
    [categories addObject:
     [CategoryNode categoryNodeWithName:LABEL(@"Subtitle") children:
      [NSArray arrayWithObjects:
       [BoolNode boolNodeWithName:LABEL_R(@"Disable Perian Subtitle for using QuickTime")
                              key:MDisablePerianSubtitleKey],
       [BoolNode boolNodeWithName:LABEL(@"Replace New-Line with <BR> for SAMI")
                              key:MSubtitleReplaceNLWithBRKey],
       [StringNode stringNodeWithName:LABEL(@"Default Subtitle Language Identifiers for SAMI")
                                  key:MDefaultLanguageIdentifiersKey],
       [IntNode intNodeWithName:LABEL(@"Auto Subtitle Position Max Lines (1~3)")
                            key:MAutoSubtitlePositionMaxLinesKey minValue:1 maxValue:3],
       nil]]];
    
    // "Full Screen Navigation" category
    [categories addObject:
     [CategoryNode categoryNodeWithName:LABEL(@"Full Screen Navigation") children:
      [NSArray arrayWithObjects:
       [StringNode stringNodeWithName:LABEL(@"Default Navigation Path")
                                  key:MFullNavPathKey],
       [BoolNode boolNodeWithName:LABEL(@"Show iTunes Movies")
                              key:MFullNavShowiTunesMoviesKey],
       [BoolNode boolNodeWithName:LABEL(@"Show iTunes TV Shows")
                              key:MFullNavShowiTunesTVShowsKey],
       [BoolNode boolNodeWithName:LABEL(@"Show iTunes Video Podcast")
                              key:MFullNavShowiTunesPodcastKey],
       [BoolNode boolNodeWithName:LABEL(@"Show Actual Path for Alias or Symbolic-Link")
                              key:MShowActualPathForLinkKey],
       nil]]];

    _detailsCategories = categories;
    [_detailsOutlineView reloadData];
    [_detailsOutlineView setAction:@selector(detailsOutlineViewAction:)];
    
    if (!isSystemLeopard()) {
        [_detailsOutlineView expandItem:nil expandChildren:TRUE];
    }
    else {
        CategoryNode* node;
        NSEnumerator* enumerator = [_detailsCategories objectEnumerator];
        while (node = [enumerator nextObject]) {
            [_detailsOutlineView expandItem:node];
        }
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
    if ([key isEqualToString:MActivateOnDraggingKey]) {
        [_movieView setActivateOnDragging:[_defaults boolForKey:MActivateOnDraggingKey]];
    }
    else if ([key isEqualToString:MAutodetectDigitalAudioOutKey]) {
        [[NSApp delegate] updateDigitalAudio];
    }
    else if ([key isEqualToString:MCaptureIncludingLetterBoxKey]) {
        [[NSApp delegate] setCaptureIncludingLetterBox:
         [_defaults boolForKey:MCaptureIncludingLetterBoxKey]];
    }
    else if ([key isEqualToString:MSubtitleReplaceNLWithBRKey]) {
        [_appController reopenSubtitle];
    }
    else if ([key isEqualToString:MAutoSubtitlePositionMaxLinesKey]) {
        [_movieView setAutoSubtitlePositionMaxLines:
         [_defaults integerForKey:MAutoSubtitlePositionMaxLinesKey]];
    }
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
    id cell = [[outlineView itemAtRow:rowIndex] dataCell];
    return (cell) ? cell : [super dataCellForRow:rowIndex];
}

@end

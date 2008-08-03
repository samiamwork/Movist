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

#import "AppController.h"
#import "UserDefaults.h"

#import "MMovieView.h"
#import "MMovie.h"

@implementation AppController (Subtitle)

- (void)setSubtitleEnable:(BOOL)enable
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (enable) {
        [self reopenSubtitle];

        if (![_movieView subtitleVisible]) {
            [_movieView setSubtitleVisible:TRUE];
            [_subtitleVisibleMenuItem setTitle:NSLocalizedString(@"Hide Subtitle", nil)];
        }
    }
    else if (_subtitles) {
        [_movieView setSubtitle:nil atIndex:0];
        [_movieView setSubtitle:nil atIndex:1];
        [_movieView setSubtitle:nil atIndex:2];
        [_subtitles release], _subtitles = nil;
        [self updateSubtitleLanguageMenuItems];
    }
}

- (void)changeSubtitleVisible
{
    if ([_movieView subtitleVisible]) {
        [_movieView setSubtitleVisible:FALSE];
        [_movieView setMessage:NSLocalizedString(@"Hide Subtitle", nil)];
        [_subtitleVisibleMenuItem setTitle:NSLocalizedString(@"Show Subtitle", nil)];
    }
    else {
        [_movieView setSubtitleVisible:TRUE];
        [_movieView setMessage:NSLocalizedString(@"Show Subtitle", nil)];
        [_subtitleVisibleMenuItem setTitle:NSLocalizedString(@"Hide Subtitle", nil)];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setLetterBoxHeight:(int)height
{
    NSString* msg;
    switch (height) {
        case LETTER_BOX_HEIGHT_SAME    : msg = [_letterBoxHeightSameMenuItem title];    break;
        case LETTER_BOX_HEIGHT_1_LINE  : msg = [_letterBoxHeight1LineMenuItem title];   break;
        case LETTER_BOX_HEIGHT_2_LINES : msg = [_letterBoxHeight2LinesMenuItem title];  break;
        case LETTER_BOX_HEIGHT_3_LINES : msg = [_letterBoxHeight3LinesMenuItem title];  break;
        default :   // including LETTER_BOX_HEIGHT_AUTO
            height = LETTER_BOX_HEIGHT_AUTO;
            msg = NSLocalizedString(@"Letter Box Height : Auto", nil);
            break;
    }
    [_movieView setLetterBoxHeight:height];
    [_movieView setMessage:msg];
    [self updateLetterBoxHeightMenuItems];
}

- (void)changeLetterBoxHeight
{
    int height = [_movieView letterBoxHeight];
    switch (height) {   // change to next height
        case LETTER_BOX_HEIGHT_SAME    : height = LETTER_BOX_HEIGHT_1_LINE;     break;
        case LETTER_BOX_HEIGHT_1_LINE  : height = LETTER_BOX_HEIGHT_2_LINES;    break;
        case LETTER_BOX_HEIGHT_2_LINES : height = LETTER_BOX_HEIGHT_3_LINES;    break;
        case LETTER_BOX_HEIGHT_3_LINES : height = LETTER_BOX_HEIGHT_AUTO;       break;
        case LETTER_BOX_HEIGHT_AUTO    : height = LETTER_BOX_HEIGHT_SAME;       break;
        default                        : height = LETTER_BOX_HEIGHT_AUTO;       break;
    }
    [self setLetterBoxHeight:height];
}

- (void)setSubtitleScreenMargin:(float)screenMargin
{
    screenMargin = adjustToRange(screenMargin, MIN_SUBTITLE_SCREEN_MARGIN, MAX_SUBTITLE_SCREEN_MARGIN);
    [_movieView setSubtitleScreenMargin:screenMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle Screen Margin %.1f", nil),
                            screenMargin]];
}

- (void)setSubtitleFontSize:(float)size atIndex:(int)index
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    size = adjustToRange(size, 1.0, 50.0);

    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT;
    [_movieView getSubtitleAttributes:&attrs atIndex:index]; // fill fontName

    attrs.fontSize = size;
    [_movieView setSubtitleAttributes:&attrs atIndex:index];
    
    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle %@ : Size %.1f", nil),
                            [[_movieView subtitleAtIndex:index] name], size]];
}

- (void)changeSubtitleFontSize:(int)tag atIndex:(int)index
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT;
    [_movieView getSubtitleAttributes:&attrs atIndex:index];

    attrs.fontSize = (tag < 0) ? (attrs.fontSize - 1.0) :
                     (0 < tag) ? (attrs.fontSize + 1.0) :
                                 [_defaults floatForKey:MSubtitleFontSizeKey[index]];
    [self setSubtitleFontSize:attrs.fontSize atIndex:index];
}

- (void)setSubtitlePosition:(int)position atIndex:(int)index
{
    NSString* ps;
    switch (position) {
        case OSD_VPOSITION_UBOX   : ps = [_subtitlePositionUBoxMenuItem title];    break;
        case OSD_VPOSITION_TOP    : ps = [_subtitlePositionTopMenuItem title];     break;
        case OSD_VPOSITION_CENTER : ps = [_subtitlePositionCenterMenuItem title];  break;
        case OSD_VPOSITION_BOTTOM : ps = [_subtitlePositionBottomMenuItem title];  break;
        default : // including OSD_VPOSITION_LBOX
            position = OSD_VPOSITION_LBOX;
            ps = [_subtitlePositionLBoxMenuItem title];
            break;
    }
    SubtitleAttributes attrs;
    attrs.vPosition = position;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
    [_movieView setSubtitleAttributes:&attrs atIndex:index];
    [_movieView setMessage:[NSString stringWithFormat:
                    @"%@ : %@", [[_movieView subtitleAtIndex:index] name], ps]];
    if (index == 0) {
        [self updateSubtitlePositionMenuItems];
    }
}

- (void)changeSubtitlePositionAtIndex:(int)index
{
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
    [_movieView getSubtitleAttributes:&attrs atIndex:index];

    // change to next position
    switch (attrs.vPosition) {
        case OSD_VPOSITION_UBOX   : attrs.vPosition = OSD_VPOSITION_TOP;     break;
        case OSD_VPOSITION_TOP    : attrs.vPosition = OSD_VPOSITION_CENTER;  break;
        case OSD_VPOSITION_CENTER : attrs.vPosition = OSD_VPOSITION_BOTTOM;  break;
        case OSD_VPOSITION_BOTTOM : attrs.vPosition = OSD_VPOSITION_LBOX;    break;
        case OSD_VPOSITION_LBOX   : attrs.vPosition = OSD_VPOSITION_UBOX;    break;
        default                   : attrs.vPosition = OSD_VPOSITION_LBOX;    break;
    }
    [self setSubtitlePosition:attrs.vPosition atIndex:index];
}

- (void)setSubtitleHMargin:(float)hMargin atIndex:(int)index
{
    hMargin = adjustToRange(hMargin, MIN_SUBTITLE_H_MARGIN, MAX_SUBTITLE_H_MARGIN);

    SubtitleAttributes attrs;
    attrs.hMargin = hMargin;
    attrs.mask = SUBTITLE_ATTRIBUTE_H_MARGIN;
    [_movieView setSubtitleAttributes:&attrs atIndex:index];

    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle %@ : HMargin %.1f %%", nil),
                            [[_movieView subtitleAtIndex:index] name], hMargin]];
}

- (void)setSubtitleVMargin:(float)vMargin atIndex:(int)index
{
    vMargin = adjustToRange(vMargin, MIN_SUBTITLE_V_MARGIN, MAX_SUBTITLE_V_MARGIN);

    SubtitleAttributes attrs;
    attrs.vMargin = vMargin;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_MARGIN;
    [_movieView setSubtitleAttributes:&attrs atIndex:index];

    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle %@ : VMargin %.1f %%", nil),
                            [[_movieView subtitleAtIndex:index] name], vMargin]];
}

- (void)changeSubtitleVMargin:(int)tag atIndex:(int)index
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_MARGIN;
    [_movieView getSubtitleAttributes:&attrs atIndex:index];

    attrs.vMargin = (tag < 0) ? (attrs.vMargin - 1.0) :
                    (0 < tag) ? (attrs.vMargin + 1.0) :
                                [_defaults floatForKey:MSubtitleVMarginKey[index]];
    [self setSubtitleVMargin:attrs.vMargin atIndex:index];
}

- (void)setSubtitleLineSpacing:(float)spacing atIndex:(int)index
{
    spacing = adjustToRange(spacing, MIN_SUBTITLE_LINE_SPACING, MAX_SUBTITLE_LINE_SPACING);

    SubtitleAttributes attrs;
    attrs.lineSpacing = spacing;
    attrs.mask = SUBTITLE_ATTRIBUTE_LINE_SPACING;
    [_movieView setSubtitleAttributes:&attrs atIndex:index];

    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle %@ : Line Spacing %.1f", nil),
                            [[_movieView subtitleAtIndex:index] name], spacing]];
}

- (void)setSubtitleSync:(float)sync atIndex:(int)index
{
    SubtitleAttributes attrs;
    attrs.sync = sync;
    attrs.mask = SUBTITLE_ATTRIBUTE_SYNC;
    [_movieView setSubtitleAttributes:&attrs atIndex:index];

    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle %@ : Sync %.1f sec.", nil),
                            [[_movieView subtitleAtIndex:index] name], sync]];
}

- (void)changeSubtitleSync:(int)tag atIndex:(int)index
{
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_SYNC;
    [_movieView getSubtitleAttributes:&attrs atIndex:index];

    switch (tag) {
        case -1 : attrs.sync -= 0.1;    break;
        case +1 : attrs.sync += 0.1;    break;
        default : attrs.sync  = 0.0;    break;
    }
    [self setSubtitleSync:attrs.sync atIndex:index];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setSubtitle:(MSubtitle*)subtitle enabled:(BOOL)enabled
{
    [subtitle setEnabled:enabled];
    if (enabled) {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Subtitle %@ enabled", nil),
            [subtitle name]]];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Subtitle %@ disabled", nil),
            [subtitle name]]];
    }

    [self updateSubtitleLanguageMenuItems];
}

- (void)autoenableSubtitles
{
    if (_subtitles == nil) {
        return;
    }

    MSubtitle* subtitle;
    int i, enabledCount = 0;
    if (0 < [_subtitleNameSet count]) {
        // select previous selected language
        for (i = 0; i < [_subtitles count]; i++) {
            subtitle = [_subtitles objectAtIndex:i];
            if ([_subtitleNameSet containsObject:[subtitle name]]) {
                [subtitle setEnabled:TRUE];
                enabledCount++;
            }
            else {
                [subtitle setEnabled:FALSE];
            }
        }
    }
    if (enabledCount == 0) {
        // select first language by default
        for (i = 0; i < [_subtitles count]; i++) {
            subtitle = [_subtitles objectAtIndex:i];
            [subtitle setEnabled:(i == 0)];
        }
    }
}

- (void)changeSubtitleLanguage:(int)tag
{
    int index = tag;
    if (0 <= index) {
        int i, subtitleCount = [_subtitles count];
        for (i = 0; i < subtitleCount; i++) {
            [[_subtitles objectAtIndex:i] setEnabled:(i == index)];
        }
    }
    else {  // rotation
        if ([_subtitles count] <= 1) {
            return;
        }
        // make index set combination (max 2 subtitles)
        NSMutableIndexSet* indexSet;
        int i, j, subtitleCount = [_subtitles count];
        NSMutableArray* combiSets = [NSMutableArray arrayWithCapacity:10];
        for (i = 0; i < subtitleCount; i++) {
            indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
            [indexSet addIndex:i];
            [combiSets addObject:indexSet];
        }
        for (i = 0; i < subtitleCount; i++) {
            for (j = i + 1; j < subtitleCount; j++) {
                indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
                [indexSet addIndex:i];
                [indexSet addIndex:j];
                [combiSets addObject:indexSet];
            }
        }
        //TRACE(@"combiSets=%@", combiSets);

        // current index set
        indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
        for (i = 0; i < subtitleCount; i++) {
            if ([[_subtitles objectAtIndex:i] isEnabled]) {
                [indexSet addIndex:i];
            }
        }

        // find next index set
        for (i = 0; i < [combiSets count]; i++) {
            if ([indexSet isEqualToIndexSet:[combiSets objectAtIndex:i]]) {
                indexSet = [combiSets objectAtIndex:(i + 1) % [combiSets count]];
                break;
            }
        }
        for (i = 0; i < subtitleCount; i++) {
            [[_subtitles objectAtIndex:i] setEnabled:[indexSet containsIndex:i]];
        }
    }

    MSubtitle* subtitle;
    int i, subtitleCount = [_subtitles count];
    NSMutableString* names = [NSMutableString stringWithCapacity:64];
    for (i = 0; i < subtitleCount; i++) {
        subtitle = [_subtitles objectAtIndex:i];
        if ([subtitle isEnabled]) {
            if ([names length] == 0) {
                [names appendString:[subtitle name]];
            }
            else {
                [names appendFormat:@", %@", [subtitle name]];
            }
        }
    }
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Subtitle %@ selected", nil), names]];
    [self updateSubtitleLanguageMenuItems];
    [_propertiesView reloadData];
}

- (void)updateMovieViewSubtitles
{
    int i, count = MIN(3, [_subtitles count]);
    for (i = 0; i < count; i++) {
        [_movieView setSubtitle:[_subtitles objectAtIndex:i] atIndex:i];
    }
    for (; i < 3; i++) {
        [_movieView setSubtitle:nil atIndex:i];
    }
}

- (void)updateSubtitleLanguageMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // remove all subtitle language items except rotation item
    int i, index;
    NSMenuItem* item;
    for (i = 0; i < [[_subtitleMenu itemArray] count]; i++) {
        item = (NSMenuItem*)[[_subtitleMenu itemArray] objectAtIndex:i];
        if ([item action] == @selector(subtitleLanguageAction:)) {
            [_subtitleMenu removeItem:item];
            index = i--;  // remember index of last subtitle item
        }
    }

    if (!_subtitles || [_subtitles count] == 0) {
        item = [_subtitleMenu
                    insertItemWithTitle:NSLocalizedString(@"No Subtitle", nil)
                                 action:@selector(subtitleLanguageAction:)
                          keyEquivalent:@"" atIndex:index];
    }
    else {
        // insert before rotation item
        MSubtitle* subtitle;
        NSString* title;
        unsigned int mask = NSCommandKeyMask | NSControlKeyMask;
        unsigned int i, count = [_subtitles count];
        for (i = 0; i < count; i++) {
            subtitle = [_subtitles objectAtIndex:i];
            title = [NSString stringWithFormat:@"%@ (%@)", [subtitle name], [subtitle type]];
            item = [_subtitleMenu
                        insertItemWithTitle:title
                                     action:@selector(subtitleLanguageAction:)
                              keyEquivalent:@"" atIndex:index++];
            [item setTag:i];
            [item setState:[subtitle isEnabled]];
            [item setKeyEquivalent:[NSString stringWithFormat:@"%d", i + 1]];
            [item setKeyEquivalentModifierMask:mask];
        }
        if (1 < [_subtitles count]) {   // add rotate item
            item = [_subtitleMenu
                        insertItemWithTitle:NSLocalizedString(@"Subtitle Rotation", nil)
                                     action:@selector(subtitleLanguageAction:)
                              keyEquivalent:@"s" atIndex:index++];
            [item setKeyEquivalentModifierMask:mask];
            [item setTag:-1];
        }
    }
    [_subtitleMenu update];

    MSubtitle* subtitle = [_movieView subtitleAtIndex:0];   // always [0]
    if (subtitle) {
        [_subtitleControlMenuItem setTitle:[NSString stringWithFormat:
         NSLocalizedString(@"Controlling Subtitle %@ (%@)", nil),
                            [subtitle name], [subtitle type]]];
    }

    // update subtitle-name in control-panel.
    [self subtitleLanguageAction:_subtitleLanguageSegmentedControl];
}

- (void)updateSubtitlePositionMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
#define SUBTITLE_POSITION_MENUITEM_SET_STATE(item)    \
    [item setState:([item tag] == position) ? NSOnState : NSOffState]

    int position = -10; // for no check
    if ([_movieView subtitleAtIndex:0]) {   // for [0] only
        SubtitleAttributes attrs;
        attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
        [_movieView getSubtitleAttributes:&attrs atIndex:0];
        position = attrs.vPosition;
    }
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionUBoxMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionTopMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionCenterMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionBottomMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionLBoxMenuItem);
}

- (void)updateLetterBoxHeightMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
#define LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(item)    \
    [item setState:([item tag] == height) ? NSOnState : NSOffState]

    int height = (_movie) ? [_movieView letterBoxHeight] : -10; // -10 for no check
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(_letterBoxHeightSameMenuItem);
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(_letterBoxHeight1LineMenuItem);
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(_letterBoxHeight2LinesMenuItem);
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(_letterBoxHeight3LinesMenuItem);
    [_letterBoxHeightPopUpButton selectItemWithTag:height];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)subtitleVisibleAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitleVisible];
}

- (IBAction)subtitleLanguageAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (sender == _subtitleLanguageSegmentedControl) {
        // this is just for updating subtitle name text-field in control-panel.
        // don't change subtitle language.
        int index = [_subtitleLanguageSegmentedControl selectedSegment];
        MSubtitle* subtitle = [_movieView subtitleAtIndex:index];
        if (subtitle) {
            [_subtitleNameTextField setStringValue:
             [NSString stringWithFormat:@"%@ (%@)", [subtitle name], [subtitle type]]];
            SubtitleAttributes attrs;
            attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
            [_movieView getSubtitleAttributes:&attrs atIndex:index];
            [_subtitlePositionPopUpButton selectItemWithTag:attrs.vPosition];
        }
        else {
            [_subtitleNameTextField setStringValue:NSLocalizedString(@"No Subtitle", nil)];
            [_subtitlePositionPopUpButton selectItemWithTag:-1];
        }
    }
    else {
        [self changeSubtitleLanguage:[sender tag]];
    }
}

- (IBAction)subtitleFontSizeAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    int index = 0;
    if (![sender isMemberOfClass:[NSMenuItem class]]) { // may be control-panel
        index = [_subtitleLanguageSegmentedControl selectedSegment];
    }
    [self changeSubtitleFontSize:[sender tag] atIndex:index];
}

- (IBAction)subtitleVMarginAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int index = 0;
    if (![sender isMemberOfClass:[NSMenuItem class]]) { // may be control-panel
        index = [_subtitleLanguageSegmentedControl selectedSegment];
    }
    [self changeSubtitleVMargin:[sender tag] atIndex:index];
}

- (IBAction)letterBoxHeightAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int height;
    if (sender == _preferenceController) {
        height = [_defaults integerForKey:MLetterBoxHeightKey];
    }
    else if (sender == _letterBoxHeightPopUpButton) {
        height = [[_letterBoxHeightPopUpButton selectedItem] tag];
    }
    else if (sender == _letterBoxHeightDefaultButton) {
        height = [_defaults integerForKey:MLetterBoxHeightKey];
    }
    else {  // for menu-items
        height = [sender tag];
        if (height != LETTER_BOX_HEIGHT_SAME &&
            height != LETTER_BOX_HEIGHT_1_LINE &&
            height != LETTER_BOX_HEIGHT_2_LINES &&
            height != LETTER_BOX_HEIGHT_3_LINES &&
            height != LETTER_BOX_HEIGHT_AUTO) {
            height = [_defaults integerForKey:MLetterBoxHeightKey];
        }
    }
    [self setLetterBoxHeight:height];
}

- (IBAction)subtitlePositionAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int index, position;
    if (sender == _subtitlePositionPopUpButton) {
        index = [_subtitleLanguageSegmentedControl selectedSegment];
        position = [[_subtitlePositionPopUpButton selectedItem] tag];
    }
    else if (sender == _subtitlePositionDefaultButton) {
        index = [_subtitleLanguageSegmentedControl selectedSegment];
        position = [_defaults integerForKey:MSubtitleVPositionKey[index]];
    }
    else {  // for menu-items
        index = 0;  // always
        position = [sender tag];
        if (position != OSD_VPOSITION_UBOX &&
            position != OSD_VPOSITION_TOP &&
            position != OSD_VPOSITION_CENTER &&
            position != OSD_VPOSITION_BOTTOM &&
            position != OSD_VPOSITION_LBOX) {
            position = [_defaults integerForKey:MSubtitleVPositionKey[index]];
        }
    }
    [self setSubtitlePosition:position atIndex:index];
}

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int index = 0;
    if (![sender isMemberOfClass:[NSMenuItem class]]) { // may be control-panel
        index = [_subtitleLanguageSegmentedControl selectedSegment];
    }
    [self changeSubtitleSync:[sender tag] atIndex:index];
}

@end

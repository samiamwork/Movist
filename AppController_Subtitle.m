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
        [_movieView setSubtitles:nil];
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

- (void)setSubtitleFontSize:(float)size
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    size = (size < 1.0) ? 1.0 : (50.0 < size) ? 50.0 : size;
    [_movieView setSubtitleFontName:[_movieView subtitleFontName] size:size];
    
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Size %.1f", nil), [_movieView subtitleFontSize]]];
}

- (void)changeSubtitleFontSize:(int)tag
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    float size = [_defaults floatForKey:MSubtitleFontSizeKey];
    switch (tag) {
        case -1 : size = [_movieView subtitleFontSize] - 1.0;   break;
        case  0 : /* use as it is */                            break;
        case +1 : size = [_movieView subtitleFontSize] + 1.0;   break;
    }
    [self setSubtitleFontSize:size];
}

- (void)setSubtitlePosition:(int)position
{
    if (position != SUBTITLE_POSITION_AUTO) {
        if (SUBTITLE_POSITION_ON_LETTER_BOX_3_LINES < position) {
            position = SUBTITLE_POSITION_ON_LETTER_BOX_3_LINES;
        }
        else if (position < SUBTITLE_POSITION_ON_MOVIE) {
            position = SUBTITLE_POSITION_ON_MOVIE;
        }
    }
    [_movieView setSubtitlePosition:position];
    [_movieView setMessage:NSStringFromSubtitlePosition(position)];
    [self updateSubtitlePositionMenuItems];
}

- (void)changeSubtitlePosition:(int)tag
{
    [self setSubtitlePosition:
        (tag < 0) ? [_movieView subtitlePosition] - 1 :
        (0 < tag) ? [_movieView subtitlePosition] + 1 :
                    [_defaults integerForKey:MSubtitlePositionKey]];
}

- (void)setSubtitleHMargin:(float)hMargin
{
    hMargin = valueInRange(hMargin, MIN_SUBTITLE_H_MARGIN, MAX_SUBTITLE_H_MARGIN);
    [_movieView setSubtitleHMargin:hMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle HMargin %.1f %%", nil), hMargin]];
}

- (void)setSubtitleVMargin:(float)vMargin
{
    vMargin = valueInRange(vMargin, MIN_SUBTITLE_V_MARGIN, MAX_SUBTITLE_V_MARGIN);
    [_movieView setSubtitleVMargin:vMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle VMargin %.1f %%", nil), vMargin]];
}

- (void)changeSubtitleVMargin:(int)tag
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    float vmargin;
    switch (tag) {
        case -1 : vmargin = [_movieView subtitleVMargin] - 1.0;         break;
        case +1 : vmargin = [_movieView subtitleVMargin] + 1.0;         break;
        default : vmargin = [_defaults floatForKey:MSubtitleVMarginKey];break;
    }
    [self setSubtitleVMargin:vmargin];
}

- (void)setSubtitleScreenMargin:(float)screenMargin
{
    screenMargin = valueInRange(screenMargin, MIN_SUBTITLE_SCREEN_MARGIN, MAX_SUBTITLE_SCREEN_MARGIN);
    [_movieView setSubtitleScreenMargin:screenMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
                            NSLocalizedString(@"Subtitle Screen Margin %.1f", nil),
                            screenMargin]];
}

- (void)setSubtitleLineSpacing:(float)spacing
{
    spacing = valueInRange(spacing, MIN_SUBTITLE_LINE_SPACING, MAX_SUBTITLE_LINE_SPACING);
    [_movieView setSubtitleLineSpacing:spacing];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Line Spacing %.1f", nil), spacing]];
}

- (void)setSubtitleSync:(float)sync
{
    [_movieView setSubtitleSync:sync];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Sync %.1f sec.", nil), [_movieView subtitleSync]]];
}

- (void)changeSubtitleSync:(int)tag
{
    float sync;
    switch (tag) {
        case -1 : sync = [_movieView subtitleSync] - 0.1;   break;
        case +1 : sync = [_movieView subtitleSync] + 0.1;   break;
        default : sync = 0.0;                               break;
    }
    [self setSubtitleSync:sync];
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
    [_movieView setSubtitles:_subtitles];   // for update
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
    [_movieView setSubtitles:_subtitles];   // for update
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Subtitle %@ selected", nil), names]];
    [self updateSubtitleLanguageMenuItems];
    [_propertiesView reloadData];
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
            title = [NSString stringWithFormat:
                        NSLocalizedString(@"Subtitle %@", nil), [subtitle name]];
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
}

- (void)updateSubtitlePositionMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
#define SUBTITLE_POSITION_MENUITEM_SET_STATE(item)    \
    [item setState:([item tag] == position) ? NSOnState : NSOffState]

    int position = (_movie) ? [_movieView subtitlePosition] : -10;
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionOnMovieMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionOnLetterBoxMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionOnLetterBox1LineMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionOnLetterBox2LinesMenuItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(_subtitlePositionOnLetterBox3LinesMenuItem);
    [_subtitlePositionPopUpButton selectItemWithTag:position];
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
    [self changeSubtitleLanguage:[sender tag]];
}

- (IBAction)subtitleFontSizeAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    [self changeSubtitleFontSize:[sender tag]];
}

- (IBAction)subtitleVMarginAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitleVMargin:[sender tag]];
}

- (IBAction)subtitlePositionAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int position;
    if (sender == _preferenceController) {
        position = [_defaults integerForKey:MSubtitlePositionKey];
    }
    else if (sender == _subtitlePositionPopUpButton) {
        position = [[_subtitlePositionPopUpButton selectedItem] tag];
    }
    else if (sender == _subtitlePositionDefaultButton) {
        position = [_defaults integerForKey:MSubtitlePositionKey];
    }
    else {  // for menu-items
        if ([sender tag] == 10) {
            position = [_defaults integerForKey:MSubtitlePositionKey];
        }
        else {
            position = [sender tag];
        }
    }
    [self setSubtitlePosition:position];
}

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitleSync:[sender tag]];
}

@end

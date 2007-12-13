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

#import "AppController.h"
#import "UserDefaults.h"

#import "MMovieView.h"

@implementation AppController (Subtitle)

- (void)setSubtitleEnable:(BOOL)enable
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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

- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    [_movieView setSubtitleDisplayOnLetterBox:displayOnLetterBox];
    [_movieView setMessage:displayOnLetterBox ?
        NSLocalizedString(@"Display Subtitle on Letter Box", nil) :
        NSLocalizedString(@"Display Subtitle on Movie", nil)];

    [_subtitleDisplayOnLetterBoxMenuItem setState:displayOnLetterBox];
    [_subtitleDisplayOnLetterBoxButton setState:displayOnLetterBox];
    [_subtitleLinesInLetterBoxMoreButton setEnabled:displayOnLetterBox];
    [_subtitleLinesInLetterBoxLessButton setEnabled:displayOnLetterBox];
    [_subtitleLinesInLetterBoxDefaultButton setEnabled:displayOnLetterBox];
}

- (void)setSubtitleLinesInLetterBox:(int)lines
{
    if (lines < MIN_SUBTITLE_LINES_IN_LETTER_BOX) {
        lines = MIN_SUBTITLE_LINES_IN_LETTER_BOX;
    }
    else if (MAX_SUBTITLE_LINES_IN_LETTER_BOX < lines) {
        lines = MAX_SUBTITLE_LINES_IN_LETTER_BOX;
    }
    [_movieView setSubtitleLinesInLetterBox:lines];
    if (lines == 0) {
        [_movieView setMessage:NSLocalizedString(@"Letter Box Default Size", nil)];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"%d Lines in Letter Box", nil),
            [_movieView subtitleLinesInLetterBox]]];
    }
}

- (void)changeSubtitleLinesInLetterBox:(int)tag
{
    int lines = [_defaults integerForKey:MSubtitleLinesInLetterBoxKey];
    switch (tag) {
        case -1 : lines = [_movieView subtitleLinesInLetterBox] - 1;    break;
        case  0 : /* use as it is */                                    break;
        case +1 : lines = [_movieView subtitleLinesInLetterBox] + 1;    break;
    }
    [self setSubtitleLinesInLetterBox:lines];
}

- (void)setSubtitleHMargin:(float)hMargin
{
    hMargin = (hMargin < 0.0) ? 0.0 : (10.0 < hMargin) ? 10.0 : hMargin;
    [_movieView setSubtitleHMargin:hMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle HMargin %.1f %%", nil), hMargin]];
}

- (void)setSubtitleVMargin:(float)vMargin
{
    vMargin = (vMargin < 0.0) ? 0.0 : (10.0 < vMargin) ? 10.0 : vMargin;
    [_movieView setSubtitleVMargin:vMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle VMargin %.1f %%", nil), vMargin]];
}

- (void)changeSubtitleVMargin:(int)tag
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float vmargin = [_defaults floatForKey:MSubtitleVMarginKey];
    switch (tag) {
        case -1 : vmargin = [_movieView subtitleVMargin] - 1.0; break;
        case  0 : /* use as it is */                            break;
        case +1 : vmargin = [_movieView subtitleVMargin] + 1.0; break;
    }
    [self setSubtitleVMargin:vmargin];
}

- (void)setSubtitleSync:(float)sync
{
    [_movieView setSubtitleSync:sync];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Sync %.1f sec.", nil), [_movieView subtitleSync]]];
}

- (void)changeSubtitleSync:(int)tag
{
    float sync = 0.0;
    switch (tag) {
        case -1 : sync = [_movieView subtitleSync] - 0.1;   break;
        case  0 : /* use as it is */                        break;
        case +1 : sync = [_movieView subtitleSync] + 0.1;   break;
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

- (void)changeSubtitle:(int)tag
{
    int index = tag;
    if (index < 0) { // rotation
        int i, count = [_subtitles count];
        for (i = 0; i < count; i++) {
            if ([[_subtitles objectAtIndex:i] isEnabled]) {
                break;
            }
        }
        index = (i + 1) % count;
    }
    int i, count = [_subtitles count];
    for (i = 0; i < count; i++) {
        [[_subtitles objectAtIndex:i] setEnabled:(i == index)];
    }
    [_movieView setSubtitles:_subtitles];   // for update
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Subtitle %@ selected", nil),
        [[_subtitles objectAtIndex:index] name]]];
    [self updateSubtitleLanguageMenuItems];
    [_propertiesView reloadData];
}

- (void)updateSubtitleLanguageMenuItems
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
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

    if ([_subtitles count] == 0) {
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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)subtitleVisibleAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitleVisible];
}

- (IBAction)subtitleLanguageAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitle:[sender tag]];
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

- (IBAction)subtitleDisplayOnLetterBoxAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    BOOL display;
    if (sender == _preferenceController) {
        display = [_defaults boolForKey:MSubtitleDisplayOnLetterBoxKey];
    }
    else {
        display = ![_movieView subtitleDisplayOnLetterBox];
    }
    [self setSubtitleDisplayOnLetterBox:display];
}

- (IBAction)subtitleLinesInLetterBoxAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (sender == _preferenceController) {
        int lines = [_defaults integerForKey:MSubtitleLinesInLetterBoxKey];
        [self setSubtitleLinesInLetterBox:lines];
    }
    else {
        [self changeSubtitleLinesInLetterBox:[sender tag]];
    }
}

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitleSync:[sender tag]];
}

@end

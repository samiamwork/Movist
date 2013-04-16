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
#import "ControlPanel.h"

#import "MMovieView.h"
#import "MMovie.h"
#import "MSubtitle.h"

@implementation AppController (Subtitle)

- (void)changeSubtitleVisible
{
    NSMenuItem* visibleItem = nil;
	for (visibleItem in [_subtitleMenu itemArray]) {
        if ([visibleItem action] == @selector(subtitleVisibleAction:)) {
            break;
        }
    }
    
    if ([_movieView subtitleVisible]) {
        [_movieView setSubtitleVisible:FALSE];
        [_movieView setMessage:NSLocalizedString(@"Hide Subtitle", nil)];
        [visibleItem setTitle:NSLocalizedString(@"Show Subtitle", nil)];
    }
    else {
        [_movieView setSubtitleVisible:TRUE];
        [_movieView setMessage:NSLocalizedString(@"Show Subtitle", nil)];
        [visibleItem setTitle:NSLocalizedString(@"Hide Subtitle", nil)];
    }
}

- (int)enabledSubtitleCount
{
    int count = 0;
	for (MSubtitle* subtitle in _subtitles) {
        if ([subtitle isEnabled]) {
            count++;
        }
    }
    return count;
}

- (void)setSubtitleEnable:(BOOL)enable
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (enable) {
        [self reopenSubtitles];
        if (![_movieView subtitleVisible]) {
            [_movieView setSubtitleVisible:TRUE];

			for (NSMenuItem* visibleItem in [_subtitleMenu itemArray]) {
                if ([visibleItem action] == @selector(subtitleVisibleAction:)) {
					[visibleItem setTitle:NSLocalizedString(@"Hide Subtitle", nil)];
                    break;
                }
            }
        }
    }
    else if (_subtitles) {
        [_movieView removeAllSubtitles];
        [_subtitles release], _subtitles = nil;
        [self updateSubtitleLanguageMenuItems];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#define INIT_LETTER_BOX_HEIGHT_MENUITEMS    \
    NSMenuItem* sameItem, *line1Item, *line2Item, *line3Item;   \
    {   \
		for (NSMenuItem* item in [_subtitleMenu itemArray]) { \
        if ([item action] == @selector(letterBoxHeightAction:)) {   \
            switch ([item tag]) {   \
                case LETTER_BOX_HEIGHT_SAME    : sameItem  = item;  break;  \
                case LETTER_BOX_HEIGHT_1_LINE  : line1Item = item;  break;  \
                case LETTER_BOX_HEIGHT_2_LINES : line2Item = item;  break;  \
                case LETTER_BOX_HEIGHT_3_LINES : line3Item = item;  break;  \
                }   \
            }   \
        }   \
    }

- (void)setLetterBoxHeight:(int)height
{
    INIT_LETTER_BOX_HEIGHT_MENUITEMS

    NSString* msg;
    switch (height) {
        case LETTER_BOX_HEIGHT_SAME    : msg = [sameItem title];    break;
        case LETTER_BOX_HEIGHT_1_LINE  : msg = [line1Item title];   break;
        case LETTER_BOX_HEIGHT_2_LINES : msg = [line2Item title];   break;
        case LETTER_BOX_HEIGHT_3_LINES : msg = [line3Item title];   break;
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
    [_movieView setMessage:[NSString localizedStringWithFormat:@"%@ %.1f",
                            NSLocalizedString(@"Subtitle Screen Margin", nil),
                            screenMargin]];
}

- (void)setSubtitleFontSize:(float)size
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    size = adjustToRange(size, 1.0, 50.0);

    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT;
    [_movieView getSubtitleAttributes:&attrs]; // fill fontName

    attrs.fontSize = size;
    [_movieView setSubtitleAttributes:&attrs];

    [_movieView setMessage:[NSString localizedStringWithFormat:@"%@ %.1f",
                            NSLocalizedString(@"Font Size", nil), size]];
}

- (float)_changeSubtitleFontSize:(int)tag
{
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_FONT;
    [_movieView getSubtitleAttributes:&attrs];
    attrs.fontSize = (tag < 0) ? (attrs.fontSize - 1.0) :
                     (0 < tag) ? (attrs.fontSize + 1.0) :
                                 [_defaults floatForKey:MSubtitleFontSizeKey];
    attrs.fontSize = adjustToRange(attrs.fontSize, 1.0, 50.0);
    [_movieView setSubtitleAttributes:&attrs];
    return attrs.fontSize;
}

- (void)changeSubtitleFontSize:(int)tag
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    NSString* action = (tag < 0) ? [_subtitleFontSizeSmallerMenuItem title] :
                       (0 < tag) ? [_subtitleFontSizeBiggerMenuItem title] :
                                   [_subtitleFontSizeDefaultMenuItem title];
    NSMutableString* msg = [NSMutableString stringWithString:action];
	float size = [self _changeSubtitleFontSize:tag];
	[msg appendFormat:@"\n%.1f", size];

    [_movieView setMessage:msg];
}

- (void)setSubtitleHMargin:(float)hMargin
{
    hMargin = adjustToRange(hMargin, MIN_SUBTITLE_H_MARGIN, MAX_SUBTITLE_H_MARGIN);

    SubtitleAttributes attrs;
    attrs.hMargin = hMargin;
    attrs.mask = SUBTITLE_ATTRIBUTE_H_MARGIN;
    [_movieView setSubtitleAttributes:&attrs];

    [_movieView setMessage:[NSString localizedStringWithFormat:@"%@ %.1f %%",
                            NSLocalizedString(@"HMargin", nil), hMargin]];
}

- (void)setSubtitleVMargin:(float)vMargin
{
    vMargin = adjustToRange(vMargin, MIN_SUBTITLE_V_MARGIN, MAX_SUBTITLE_V_MARGIN);

    SubtitleAttributes attrs;
    attrs.vMargin = vMargin;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_MARGIN;
    [_movieView setSubtitleAttributes:&attrs];
    
    [_movieView setMessage:[NSString localizedStringWithFormat:@"%@ %.1f %%",
                            NSLocalizedString(@"VMargin", nil), vMargin]];
}

- (float)_changeSubtitleVMargin:(int)tag
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_MARGIN;
    [_movieView getSubtitleAttributes:&attrs];
    
    attrs.vMargin = (tag < 0) ? (attrs.vMargin - 1.0) :
                    (0 < tag) ? (attrs.vMargin + 1.0) :
                                [_defaults floatForKey:MSubtitleVMarginKey];
    attrs.vMargin = adjustToRange(attrs.vMargin, MIN_SUBTITLE_V_MARGIN, MAX_SUBTITLE_V_MARGIN);
    [_movieView setSubtitleAttributes:&attrs];
    return attrs.vMargin;
}

- (void)changeSubtitleVMargin:(int)tag
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* action = (tag < 0) ? [_subtitleVMarginSmallerMenuItem title] :
                       (0 < tag) ? [_subtitleVMarginBiggerMenuItem title] :
                                   [_subtitleVMarginDefaultMenuItem title];
    NSMutableString* msg = [NSMutableString stringWithString:action];
	float vMargin = [self _changeSubtitleVMargin:tag];
	[msg appendFormat:@"\n%.1f", vMargin];

    [_movieView setMessage:msg];
}

- (void)setSubtitleLineSpacing:(float)spacing
{
    assert(0 <= index);
    spacing = adjustToRange(spacing, MIN_SUBTITLE_LINE_SPACING, MAX_SUBTITLE_LINE_SPACING);

    SubtitleAttributes attrs;
    attrs.lineSpacing = spacing;
    attrs.mask = SUBTITLE_ATTRIBUTE_LINE_SPACING;
    [_movieView setSubtitleAttributes:&attrs];
    
    [_movieView setMessage:[NSString localizedStringWithFormat:@"%@ %.1f",
                            NSLocalizedString(@"Line Spacing", nil), spacing]];
}

- (float)_changeSubtitleSync:(int)tag
{
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_SYNC;
    [_movieView getSubtitleAttributes:&attrs];
    attrs.sync = (tag < 0) ? attrs.sync - 0.5 :
                 (0 < tag) ? attrs.sync + 0.5 :
                 0.0;
    [_movieView setSubtitleAttributes:&attrs];
    return attrs.sync;
}

- (void)changeSubtitleSync:(int)tag
{
    NSString* action = (tag < 0) ? [_subtitleSyncLaterMenuItem title] :
                       (0 < tag) ? [_subtitleSyncEarlierMenuItem title] :
                                   [_subtitleSyncDefaultMenuItem title];
    NSMutableString* msg = [NSMutableString stringWithString:action];
	float sync = [self _changeSubtitleSync:tag];
	[msg appendFormat:@"\n%.1f %@",
	 sync, NSLocalizedString(@"sec.", nil)];

    [_movieView setMessage:msg];
}

#define INIT_SUBTITLE_POSITION_MENUITEMS \
    NSMenuItem* uboxItem, *topItem, *centerItem, *bottomItem, *lboxItem;    \
    {   \
        for (NSMenuItem* item in [[_subtitle0MenuItem submenu] itemArray]) { \
            if ([item action] == @selector(subtitlePositionAction:)) {  \
                switch ([item tag]) {   \
                    case OSD_VPOSITION_UBOX   : uboxItem = item;   break;   \
                    case OSD_VPOSITION_TOP    : topItem = item;    break;   \
                    case OSD_VPOSITION_CENTER : centerItem = item; break;   \
                    case OSD_VPOSITION_BOTTOM : bottomItem = item; break;   \
                    case OSD_VPOSITION_LBOX   : lboxItem = item;   break;   \
                }   \
            }   \
        }   \
    }

- (void)setSubtitlePosition:(int)position
{
    INIT_SUBTITLE_POSITION_MENUITEMS

    NSString* ps;
    switch (position) {
        case OSD_VPOSITION_UBOX   : ps = [uboxItem title];    break;
        case OSD_VPOSITION_TOP    : ps = [topItem title];     break;
        case OSD_VPOSITION_CENTER : ps = [centerItem title];  break;
        case OSD_VPOSITION_BOTTOM : ps = [bottomItem title];  break;
        default : // including OSD_VPOSITION_LBOX
            position = OSD_VPOSITION_LBOX;
            ps = [lboxItem title];
            break;
    }
    SubtitleAttributes attrs;
    attrs.vPosition = position;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
    [_movieView setSubtitleAttributes:&attrs];
    [_movieView setMessage:[NSString stringWithFormat:@"%@", ps]];
    [self updateSubtitlePositionMenuItem];
    [self updateControlPanelSubtitleUI];
}

- (void)changeSubtitlePosition
{
    SubtitleAttributes attrs;
    attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
    [_movieView getSubtitleAttributes:&attrs];

    // change to next position
    switch (attrs.vPosition) {
        case OSD_VPOSITION_UBOX   : attrs.vPosition = OSD_VPOSITION_TOP;     break;
        case OSD_VPOSITION_TOP    : attrs.vPosition = OSD_VPOSITION_CENTER;  break;
        case OSD_VPOSITION_CENTER : attrs.vPosition = OSD_VPOSITION_BOTTOM;  break;
        case OSD_VPOSITION_BOTTOM : attrs.vPosition = OSD_VPOSITION_LBOX;    break;
        case OSD_VPOSITION_LBOX   : attrs.vPosition = OSD_VPOSITION_UBOX;    break;
        default                   : attrs.vPosition = OSD_VPOSITION_LBOX;    break;
    }
    [self setSubtitlePosition:attrs.vPosition];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setSubtitle:(MSubtitle*)subtitle enabled:(BOOL)enabled
{
    [subtitle setEnabled:enabled];
	[_movieView addSubtitle:subtitle];
	[_movieView setMessage:[subtitle UIName]];

    [self updateSubtitleLanguageMenuItems];
}

- (void)updateExternalSubtitleTrackNames
{
    // count external subtitles
    int externalCount = 0;
    NSString* defaultName = NSLocalizedString(@"External Subtitle", nil);
	for (MSubtitle* subtitle in _subtitles) {
        if (![subtitle isEmbedded] && 1 < externalCount++) {
            break;
        }
    }
    
    if (1 < externalCount) {
        // add to track number.
        int trackNumber = 1;
		for (MSubtitle* subtitle in _subtitles) {
            if ([subtitle isEmbedded]) {
                continue;
            }
            if ([[subtitle trackName] isEqualToString:defaultName]) {
                [subtitle setTrackName:
                 [NSString stringWithFormat:@"%@ %d", defaultName, trackNumber]];
            }
            trackNumber++;
        }
    }
}

- (void)autoenableSubtitles
{
    if (_subtitles == nil) {
        return;
    }

    int enabledCount = 0;
    if (0 < [_subtitleNameSet count]) {
        // select previous selected language
		for (MSubtitle* subtitle in _subtitles) {
            if ([_subtitleNameSet containsObject:[subtitle UIName]]) {
                [subtitle setEnabled:TRUE];
                enabledCount++;
            }
            else {
                [subtitle setEnabled:FALSE];
            }
        }
    }
    else {
        // select by user-defined default language identifiers
        NSArray* defaultLangIDs = [[_defaults objectForKey:MDefaultLanguageIdentifiersKey]
                                   componentsSeparatedByString:@" "];
		for (NSString* langID in defaultLangIDs) {
			for (MSubtitle* subtitle in _subtitles) {
				if (!enabledCount && [subtitle checkDefaultLanguage:[NSArray arrayWithObject:langID]]) {
					[subtitle setEnabled:YES];
					enabledCount = 1;
				}
				else {
					[subtitle setEnabled:NO];
				}
			}
			if (enabledCount)
				break;
		}
    }

    if (enabledCount == 0) {
        // select first language by default
        MSubtitle* firstExternal = nil;
        MSubtitle* firstEmbedded = nil;
		for (MSubtitle* subtitle in _subtitles) {
            [subtitle setEnabled:FALSE];
            if ([subtitle isEmbedded]) {
                if (!firstEmbedded) {
                    firstEmbedded = subtitle;
                }
            }
            else if (!firstExternal) {
                firstExternal = subtitle;
            }
        }
        if (firstExternal) {
            [firstExternal setEnabled:TRUE];
        }
        else if (firstEmbedded) {
            [firstEmbedded setEnabled:TRUE];
        }
    }
}

- (void)changeSubtitleLanguage:(int)tag
{
	int index;
	if (tag < 0)
	{
		// Pick the next subtitle
		index = 0;
		for (MSubtitle* sub in _subtitles)
		{
			index++;
			if([sub isEnabled])
			{
				[sub setEnabled:NO];
				break;
			}
		}
		if (index == [_subtitles count])
			index = 0;
		[(MSubtitle*)[_subtitles objectAtIndex:index] setEnabled:YES];
	}
	else
	{
		// select or enable/disable a specific subtitle
		index = tag;
		if (0 <= index) {
			// TODO: be smarter about this since we know only one subtitle
			//       is enabled at a time.
			// enable only one at index.
			int i, subtitleCount = [_subtitles count];
			for (i = 0; i < subtitleCount; i++) {
				[[_subtitles objectAtIndex:i] setEnabled:(i == index)];
			}
		}
	}

	MSubtitle* subtitle = [_subtitles objectAtIndex:index];
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"%@ selected", nil), [subtitle UIName]]];
    [self updateMovieViewSubtitles];
    [self updateSubtitleLanguageMenuItems];
    [_propertiesView reloadData];
}

- (void)updateMovieViewSubtitles
{
    [_movieView removeAllSubtitles];

    MSubtitle* subtitle;
    NSEnumerator* e = [_subtitles objectEnumerator];
    while (subtitle = [e nextObject]) {
        if ([subtitle isEnabled]) {
            [_movieView addSubtitle:subtitle];
        }
    }
}

- (void)updateSubtitleLanguageMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // remove all subtitle language items
    NSMenuItem* item;
    while (TRUE) {
        item = [_subtitleMenu itemAtIndex:0];
        if ([item action] == @selector(subtitleLanguageAction:)) {
            [_subtitleMenu removeItem:item];
        }
        else {
            break;
        }
    }

    if (!_subtitles || [_subtitles count] == 0) {
        item = [_subtitleMenu
                    insertItemWithTitle:[NSString stringWithFormat:@"<%@>",
                                         NSLocalizedString(@"No Subtitle", nil)]
                                 action:@selector(subtitleLanguageAction:)
                          keyEquivalent:@"" atIndex:0];
    }
    else {
        MSubtitle* subtitle;
        NSString* keyEquivalent;
        unsigned int mask = NSCommandKeyMask | NSControlKeyMask;
        unsigned int i, mi, count = [_subtitles count];
        for (i = mi = 0; i < count; i++) {
            subtitle = [_subtitles objectAtIndex:i];
            keyEquivalent = [NSString stringWithFormat:@"%d", i + 1];
            // select ... item
            item = [_subtitleMenu
                    insertItemWithTitle:[subtitle UIName]
                                 action:@selector(subtitleLanguageAction:)
                          keyEquivalent:keyEquivalent atIndex:mi++];
            [item setTag:i];
            [item setState:[subtitle isEnabled]];
            [item setKeyEquivalentModifierMask:mask];
        }
        if (1 < [_subtitles count]) {   // add rotate item
            item = [_subtitleMenu
                    insertItemWithTitle:NSLocalizedString(@"Subtitle Rotation", nil)
                    action:@selector(subtitleLanguageAction:)
                    keyEquivalent:@"s" atIndex:mi];
            [item setKeyEquivalentModifierMask:mask];
            [item setTag:-1];
        }
    }

	MSubtitle*  subtitle = [_movieView subtitle];
	if (subtitle) {
		[_subtitle0MenuItem setTitle:[subtitle UIName]];
		[_subtitle0MenuItem setEnabled:TRUE];
	}
	else {
		[_subtitle0MenuItem setTitle:[NSString stringWithFormat:@"<%@>",
							NSLocalizedString(@"None", nil)]];
		[_subtitle0MenuItem setEnabled:FALSE];
	}

    [_subtitleMenu update];
    
    // update subtitle-name in control-panel.
	[self updateControlPanelSubtitleUI];
}

- (void)updateSubtitlePositionMenuItem
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int position = -10; // for no check
    if ([_movieView subtitle]) {
        SubtitleAttributes attrs;
        attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
        [_movieView getSubtitleAttributes:&attrs];
        position = attrs.vPosition;
    }

    INIT_SUBTITLE_POSITION_MENUITEMS

    #define SUBTITLE_POSITION_MENUITEM_SET_STATE(item)    \
        [item setState:([item tag] == position) ? NSOnState : NSOffState]

    SUBTITLE_POSITION_MENUITEM_SET_STATE(uboxItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(topItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(centerItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(bottomItem);
    SUBTITLE_POSITION_MENUITEM_SET_STATE(lboxItem);
}

- (void)updateLetterBoxHeightMenuItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    INIT_LETTER_BOX_HEIGHT_MENUITEMS

    #define LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(item)    \
        [item setState:([item tag] == height) ? NSOnState : NSOffState]

    int height = (_movie) ? [_movieView letterBoxHeight] : -10; // -10 for no check
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(sameItem);
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(line1Item);
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(line2Item);
    LETTER_BOX_HEIGHT_MENUITEM_SET_STATE(line3Item);
    [_letterBoxHeightPopUpButton selectItemWithTag:height];
}

- (void)updateControlPanelSubtitleUI
{
	MSubtitle* subtitle = [_movieView subtitle];
	if (subtitle) {
		[_subtitleNameTextField setStringValue:
		 [NSString stringWithFormat:@"%@ (%@)", [subtitle name], [subtitle type]]];
		SubtitleAttributes attrs;
		attrs.mask = SUBTITLE_ATTRIBUTE_V_POSITION;
		[_movieView getSubtitleAttributes:&attrs];
		[_subtitlePositionPopUpButton selectItemWithTag:attrs.vPosition];
	}
	[_subtitlePositionPopUpButton setEnabled:TRUE];
	[_subtitlePositionDefaultButton setEnabled:TRUE];
}

////////////////////////////////////////////////////////////////////////////////

- (void)subtitleTrackWillLoad:(NSNotification*)notification
{
    [_controlPanel setSubtitleTrackLoadingTime:0.1];
    [_propertiesView reloadData];
}

- (void)subtitleTrackIsLoading:(NSNotification*)notification
{
    float t = [[[notification userInfo] objectForKey:@"progress"] floatValue];
    [_controlPanel setSubtitleTrackLoadingTime:t];
    [_propertiesView reloadData];
}

- (void)subtitleTrackDidLoad:(NSNotification*)notification
{
    [_controlPanel setSubtitleTrackLoadingTime:0.0];
    [_propertiesView reloadData];
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

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self changeSubtitleSync:[sender tag]];
}

- (IBAction)subtitlePositionAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int position;
    if (sender == _subtitlePositionPopUpButton) {
        position = [[_subtitlePositionPopUpButton selectedItem] tag];
    }
    else if (sender == _subtitlePositionDefaultButton) {
        position = [_defaults integerForKey:MSubtitleVPositionKey];
    }
    else {  // for menu-items
        position = [sender tag];
        if (position < 0) { // rotation for the 1st subtitle only
            [self changeSubtitlePosition];
            return;
        }
        else if (OSD_VPOSITION_LBOX < position) {
            position = [_defaults integerForKey:MSubtitleVPositionKey];
        }
    }
    [self setSubtitlePosition:position];
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
    else if ([[sender class] isEqualTo:[NSButton class]]) { // default-button in control-panel
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

@end

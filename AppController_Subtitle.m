//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
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
        [self updateSubtitleLanguageMenu];
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

- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    [_movieView setSubtitleDisplayOnLetterBox:displayOnLetterBox];
    [_movieView setMessage:displayOnLetterBox ?
        NSLocalizedString(@"Display Subtitle on Letter Box", nil) :
        NSLocalizedString(@"Display Subtitle on Movie", nil)];

    [_subtitleDisplayOnLetterBoxMenuItem setState:displayOnLetterBox];
    [_subtitleDisplayOnLetterBoxButton setState:displayOnLetterBox];
}

- (void)setMinLetterBoxHeight:(float)minLetterBoxHeight
{
    [_movieView setMinLetterBoxHeight:minLetterBoxHeight];
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Min. Letter Box Height %d", nil),
        (int)[_movieView minLetterBoxHeight]]];
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

- (void)setSubtitleSync:(float)sync
{
    [_movieView setSubtitleSync:sync];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Sync %.1f sec.", nil), [_movieView subtitleSync]]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setSubtitle:(MSubtitle*)subtitle enabled:(BOOL)enabled
{
    [subtitle setEnabled:enabled];
    if (enabled) {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Subtitle Language %@ enabled", nil),
            [subtitle name]]];
    }
    else {
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Subtitle Language %@ disabled", nil),
            [subtitle name]]];
    }
    [_movieView setSubtitles:_subtitles];   // for update
    [self updateSubtitleLanguageMenu];
}

- (void)updateSubtitleLanguageMenu
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // remove all items
    while (0 < [_subtitleLanguageMenu numberOfItems]) {
        [_subtitleLanguageMenu removeItemAtIndex:0];
    }

    NSMenuItem* item;
    if ([_subtitles count] == 0) {
        item = [_subtitleLanguageMenu
                    addItemWithTitle:NSLocalizedString(@"no subtitle", nil)
                              action:@selector(subtitleLanguageAction:)
                       keyEquivalent:@""];
        [item setTag:-1];
    }
    else {
        MSubtitle* subtitle;
        unsigned int i, count = [_subtitles count];
        for (i = 0; i < count; i++) {
            subtitle = [_subtitles objectAtIndex:i];
            item = [_subtitleLanguageMenu
                    addItemWithTitle:[subtitle name]
                              action:@selector(subtitleLanguageAction:)
                       keyEquivalent:@""];
            [item setTag:i];
            [item setState:[subtitle isEnabled]];
            [item setKeyEquivalent:[NSString stringWithFormat:@"%d", i + 1]];
            [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
        }
    }
    [_subtitleLanguageMenu update];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)subtitleVisibleAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_movieView subtitleVisible]) {
        [_movieView setSubtitleVisible:FALSE];
        [_movieView setMessage:[sender title]];
        [_subtitleVisibleMenuItem setTitle:NSLocalizedString(@"Show Subtitle", nil)];
    }
    else {
        [_movieView setSubtitleVisible:TRUE];
        [_movieView setMessage:[sender title]];
        [_subtitleVisibleMenuItem setTitle:NSLocalizedString(@"Hide Subtitle", nil)];
    }
}

- (IBAction)subtitleLanguageAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // enable selected subtitle only
    int i, index = [sender tag];
    for (i = 0; i < [_subtitles count]; i++) {
        [[_subtitles objectAtIndex:i] setEnabled:(i == index)];
    }
    [_movieView setSubtitles:_subtitles];   // for update
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Subtitle Language %@ selected", nil),
        [[_subtitles objectAtIndex:index] name]]];
    [self updateSubtitleLanguageMenu];
    [_propertiesView reloadData];
}

- (IBAction)subtitleFontSizeAction:(id)sender
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__);
    switch ([sender tag]) {
        case -1 : [self setSubtitleFontSize:[_movieView subtitleFontSize] - 1.0];           break;
        case  0 : [self setSubtitleFontSize:[_defaults floatForKey:MSubtitleFontSizeKey]];  break;
        case +1 : [self setSubtitleFontSize:[_movieView subtitleFontSize] + 1.0];           break;
    }
}

- (IBAction)subtitleVMarginAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    switch ([sender tag]) {
        case -1 : [self setSubtitleVMargin:[_movieView subtitleVMargin] - 1.0];          break;
        case  0 : [self setSubtitleVMargin:[_defaults floatForKey:MSubtitleVMarginKey]]; break;
        case +1 : [self setSubtitleVMargin:[_movieView subtitleVMargin] + 1.0];          break;
    }
}

- (IBAction)subtitleLetterBoxHeightAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (sender == _preferenceController) {
        float height = [_defaults floatForKey:MSubtitleMinLetterBoxHeightKey];
        [self setMinLetterBoxHeight:height];
    }
    else {
        switch ([sender tag]) {
            case -1 : [_movieView decreaseLetterBoxHeight]; break;
            case  0 : [_movieView revertLetterBoxHeight];   break;
            case +1 : [_movieView increaseLetterBoxHeight]; break;
        }
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Min. Letter Box Height %d", nil),
            (int)[_movieView minLetterBoxHeight]]];
    }
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

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    switch ([sender tag]) {
        case -1 : [self setSubtitleSync:[_movieView subtitleSync] - 0.1];    break;
        case  0 : [self setSubtitleSync:0.0];           break;
        case +1 : [self setSubtitleSync:[_movieView subtitleSync] + 0.1];    break;
    }
    
}

@end

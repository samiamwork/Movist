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

- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    [_movieView setSubtitleDisplayOnLetterBox:displayOnLetterBox];
    [_movieView setMessage:displayOnLetterBox ?
        NSLocalizedString(@"Display Subtitle on Letter Box", nil) :
        NSLocalizedString(@"Display Subtitle on Movie", nil)];

    [_subtitleDisplayOnLetterBoxMenuItem setState:displayOnLetterBox];
    [_subtitleDisplayOnLetterBoxButton setState:displayOnLetterBox];
}

- (void)performLetterBoxHeightSelector:(SEL)selector
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_movieView performSelector:selector];
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Min. Letter Box Height %d", nil),
        (int)[_movieView minLetterBoxHeight]]];
}

- (void)revertLetterBoxHeight   { [self performLetterBoxHeightSelector:@selector(revertLetterBoxHeight)]; }
- (void)increaseLetterBoxHeight { [self performLetterBoxHeightSelector:@selector(increaseLetterBoxHeight)]; }
- (void)decreaseLetterBoxHeight { [self performLetterBoxHeightSelector:@selector(decreaseLetterBoxHeight)]; }

- (void)setMinLetterBoxHeight:(float)minLetterBoxHeight
{
    [_movieView setMinLetterBoxHeight:minLetterBoxHeight];
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Min. Letter Box Height %d", nil),
        (int)[_movieView minLetterBoxHeight]]];
}

- (void)setSubtitleHMargin:(float)hMargin
{
    [_movieView setSubtitleHMargin:hMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle HMargin %.1f %%", nil), hMargin]];
}

- (void)setSubtitleVMargin:(float)vMargin
{
    [_movieView setSubtitleVMargin:vMargin];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle VMargin %.1f %%", nil), vMargin]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)performSubtitleSyncSelector:(SEL)selector
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_movieView performSelector:selector];
    [_movieView setMessage:[NSString localizedStringWithFormat:
        NSLocalizedString(@"Subtitle Sync %.1f sec.", nil), [_movieView subtitleSync]]];
}

- (void)revertSubtitleSync   { [self performSubtitleSyncSelector:@selector(revertSubtitleSync)]; }
- (void)increaseSubtitleSync { [self performSubtitleSyncSelector:@selector(increaseSubtitleSync)]; }
- (void)decreaseSubtitleSync { [self performSubtitleSyncSelector:@selector(decreaseSubtitleSync)]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setSubtitle:(MSubtitle*)subtitle enabled:(BOOL)enabled
{
    NSMutableArray* subtitles = [NSMutableArray arrayWithArray:[_movieView subtitles]];
    if (enabled) {
        [subtitles addObject:subtitle];
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Subtitle Language %@ enabled", nil),
            [subtitle name]]];
    }
    else {
        [subtitles removeObject:subtitle];
        [_movieView setMessage:[NSString stringWithFormat:
            NSLocalizedString(@"Subtitle Language %@ disabled", nil),
            [subtitle name]]];
    }
    [_movieView setSubtitles:subtitles];
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
            [item setState:[[_movieView subtitles] containsObject:subtitle]];
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
    MSubtitle* subtitle = [_subtitles objectAtIndex:[sender tag]];
    [_movieView setSubtitles:[NSArray arrayWithObject:subtitle]];
    [_movieView setMessage:[NSString stringWithFormat:
        NSLocalizedString(@"Subtitle Language %@ selected", nil), [subtitle name]]];
    [self updateSubtitleLanguageMenu];
    [_propertiesView reloadData];
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

- (IBAction)subtitleLetterBoxHeightAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (sender == _preferenceController) {
        float height = [_defaults floatForKey:MSubtitleMinLetterBoxHeightKey];
        [self setMinLetterBoxHeight:height];
    }
    else {
        switch ([sender tag]) {
            case -1 : [self decreaseLetterBoxHeight];   break;
            case  0 : [self revertLetterBoxHeight];     break;
            case +1 : [self increaseLetterBoxHeight];   break;
        }
    }
}

- (IBAction)subtitleSyncAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    switch ([sender tag]) {
        case -1 : [self decreaseSubtitleSync];     break;
        case  0 : [self revertSubtitleSync];       break;
        case +1 : [self increaseSubtitleSync];     break;
    }
}

@end

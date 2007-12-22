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

#import "MMovieView.h"
#import "MainWindow.h"

NSString* PANE_ID[] = {
    @"PreferenceGeneral",
    @"PreferenceVideo",
    @"PreferenceAudio",
    @"PreferenceSubtitle",
    @"PreferenceAdvanced",
};

#define PANE_COUNT  (sizeof(PANE_ID) / sizeof(PANE_ID[0]))

@implementation PreferenceController

- (id)initWithAppController:(AppController*)appController
                 mainWindow:(MainWindow*)mainWindow;
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super initWithWindowNibName:@"Preferences"]) {
        [self setWindowFrameAutosaveName:@"PreferencesWindow"];
        _defaults = [[NSUserDefaults standardUserDefaults] retain];
        _appController = [appController retain];
        _mainWindow = [mainWindow retain];
        _movieView = [_mainWindow movieView];
    }
    return self;
}

- (void)windowDidLoad
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:@"MPrefsToolbar"];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setAllowsUserCustomization:FALSE];
    [toolbar setAutosavesConfiguration:FALSE];
    [toolbar setDelegate: self];
    [[self window] setToolbar:[toolbar autorelease]];
    [[self window] setShowsToolbarButton:FALSE];

    [self initGeneralPane];
    [self initVideoPane];
    [self initAudioPane];
    [self initSubtitlePane];
    [self initAdvancedPane];

    NSString* identifier = [_defaults stringForKey:MPreferencePaneKey];
    if ([identifier isEqualToString:@""]) {
        identifier = PANE_ID[0];
    }
    [toolbar setSelectedItemIdentifier:identifier];
    [self selectPaneWithIdentifier:nil];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_appController release];
    [_mainWindow release];
    [_defaults synchronize];
    [_defaults release];
    [super dealloc];
}

- (void)selectPaneWithIdentifier:(NSString*)identifier
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, identifier);
    BOOL initial = FALSE;
    if (!identifier) {
        initial = TRUE;
        identifier = [[[self window] toolbar] selectedItemIdentifier];
    }

    NSView* panes[PANE_COUNT] = {
        _generalPane,
        _videoPane,
        _audioPane,
        _subtitlePane,
        _advancedPane,
    };
    int i;
    for (i = 0; i < PANE_COUNT; i++) {
        if ([identifier isEqualToString:PANE_ID[i]]) {
            break;
        }
    }

    NSWindow* window = [self window];
    NSRect frame = [window frame];

    NSView* cv = [window contentView];
    NSSize contentSize = [cv convertSize:[cv bounds].size toView:nil];
    NSSize frameSize = [cv convertSize:[panes[i] frame].size toView:nil];
    frameSize.height += frame.size.height - contentSize.height;

    if (!initial) {
        frame.origin.x -= (frameSize.width - frame.size.width) / 2;
        frame.origin.y -= frameSize.height - frame.size.height;
    }
    frame.size = frameSize;

    if (!initial) {
        [[[[window contentView] subviews] objectAtIndex:0] removeFromSuperview];
    }
    [window setFrame:frame display:TRUE animate:!initial];
    [[window contentView] addSubview:panes[i]];
    [window setTitle:[[[[window toolbar] items] objectAtIndex:i] label]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark toolbar

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar
    itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag
{
    //TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, identifier,
    //      flag ? @"will be inserted" : @"will not be inserted");
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];

    NSString* label[PANE_COUNT] = {
        NSLocalizedString(@"General", nil),
        NSLocalizedString(@"Video", nil),
        NSLocalizedString(@"Audio", nil),
        NSLocalizedString(@"Subtitle", nil),
        NSLocalizedString(@"Advanced", nil),
    };
    
    int i;
    for (i = 0; i < PANE_COUNT; i++) {
        if ([identifier isEqualToString:PANE_ID[i]]) {
            [item setImage:[NSImage imageNamed:PANE_ID[i]]];
            [item setLabel:label[i]];
            [item setTarget:self];
            [item setAction:@selector(toolbarItemSelected:)];
            break;
        }
    }
    return item;
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [NSArray arrayWithObjects:PANE_ID count:PANE_COUNT];
}

- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)toolbar
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (BOOL)validateToolbarItem:(NSToolbarItem*)toolbarItem { return TRUE; }

- (void)toolbarItemSelected:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* identifier = [[[self window] toolbar] selectedItemIdentifier];
    [self selectPaneWithIdentifier:identifier];
    [_defaults setObject:identifier forKey:MPreferencePaneKey];
}

@end

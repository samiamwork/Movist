//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class AppController;
@class Playlist;

@interface PlaylistController : NSWindowController
{
    IBOutlet NSTableView* _tableView;
    IBOutlet NSButton* _removeButton;
    IBOutlet NSButton* _modeButton;
    IBOutlet NSTextField* _statusTextField;

    AppController* _appController;
    Playlist* _playlist;
}

- (id)initWithAppController:(AppController*)appController
                   playlist:(Playlist*)playlist;
- (void)runSheetForWindow:(NSWindow*)window;

#pragma mark -
- (IBAction)addAction:(id)sender;
- (IBAction)removeAction:(id)sender;
- (IBAction)modeAction:(id)sender;
- (IBAction)closeAction:(id)sender;

#pragma mark -
- (void)updateRemoveButton;
- (void)updateRepeatUI;
- (void)updateUI;

@end

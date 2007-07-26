//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class PlayPanel;
@class MMovieView;

@interface MainWindow : NSWindow
{
    IBOutlet MMovieView* _movieView;
    NSPoint _movieViewMarginPoint;
    NSSize _movieViewMarginSize;

    NSRect _zoomRestoreRect;

    BOOL _alwaysOnTop;
}

- (MMovieView*)movieView;

- (BOOL)alwaysOnTop;
- (void)setAlwaysOnTop:(BOOL)alwaysOnTop;

- (NSRect)frameRectForMovieSize:(NSSize)movieSize align:(int)align;
- (NSRect)frameRectForMovieRect:(NSRect)movieRect;
- (NSRect)frameRectForScreen;

@end

enum {  // for frameRectFromMovieSize:align:
    ALIGN_WINDOW_TITLE,
    ALIGN_SCREEN_CENTER,
};

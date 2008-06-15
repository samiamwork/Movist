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

#import "Movist.h"

@class PlayPanel;
@class MMovieView;
@class MainSeekSlider;

@interface MainWindow : NSWindow
{
    IBOutlet MMovieView* _movieView;
    IBOutlet MainSeekSlider* _seekSlider;
    NSPoint _movieViewMarginPoint;
    NSSize _movieViewMarginSize;

    NSRect _zoomRestoreRect;
    NSPoint _initialDragPoint;

    BOOL _alwaysOnTop;
}

- (NSButton*)createDecoderButton;
- (MMovieView*)movieView;

- (BOOL)alwaysOnTop;
- (IBAction)setAlwaysOnTop:(BOOL)alwaysOnTop;

- (NSRect)frameRectForMovieSize:(NSSize)movieSize align:(int)align;
- (NSRect)frameRectForMovieRect:(NSRect)movieRect;
- (NSRect)frameRectForScreen;

@end

enum {  // for frameRectFromMovieSize:align:
    ALIGN_SCREEN_CENTER,
    ALIGN_WINDOW_TITLE_CENTER,
    ALIGN_WINDOW_TITLE_LEFT,
    ALIGN_WINDOW_TITLE_RIGHT,
    ALIGN_WINDOW_BOTTOM_CENTER,
    ALIGN_WINDOW_BOTTOM_LEFT,
    ALIGN_WINDOW_BOTTOM_RIGHT,
};

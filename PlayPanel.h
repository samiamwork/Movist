//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class MMovieView;

@interface PlayPanel : NSWindow     // not NSPanel
{
    IBOutlet MMovieView* _movieView;
    IBOutlet NSTextField* _titleTextField;

    NSTimer* _hideTimer;
}

- (void)showPanel;
- (void)hidePanel;
- (void)updateByMouseInScreen:(NSPoint)point;

@end

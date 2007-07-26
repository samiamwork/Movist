//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class FullScreener;
#if defined(_SUPPORT_FRONT_ROW)
@class FullNavView;
#endif
@class MMovieView;
@class PlayPanel;

@interface FullWindow : NSWindow
{
    FullScreener* _fullScreener;
#if defined(_SUPPORT_FRONT_ROW)
    FullNavView* _navView;
#endif
    MMovieView* _movieView;
    PlayPanel* _playPanel;
}

- (id)initWithFullScreener:(FullScreener*)fullScreener
                    screen:(NSScreen*)screen playPanel:(PlayPanel*)playPanel;

- (void)setMovieView:(MMovieView*)movieView;

#if defined(_SUPPORT_FRONT_ROW)
- (void)selectUpper;
- (void)selectLower;
- (void)openSelectedItem;
- (void)closeCurrent;
#endif

@end

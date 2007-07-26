//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@class PlaylistItem;

@interface PlaylistMovieCell : NSActionCell <NSCopying>
{
    PlaylistItem* _playlistItem;
}

- (void)setPlaylistItem:(PlaylistItem*)item;

@end

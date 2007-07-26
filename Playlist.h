//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@interface PlaylistItem : NSObject <NSCopying>
{
    NSURL* _movieURL;
    NSURL* _subtitleURL;
}

- (id)initWithMovieURL:(NSURL*)movieURL;

#pragma mark -
- (NSURL*)movieURL;
- (NSURL*)subtitleURL;
- (void)setMovieURL:(NSURL*)movieURL;
- (void)setSubtitleURL:(NSURL*)subtitleURL;

#pragma mark -
- (BOOL)isEqualToMovieURL:(NSURL*)movieURL;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

enum {
    REPEAT_OFF,
    REPEAT_ALL,
    REPEAT_ONE,
    MAX_REPEAT_MODE,
};

@interface Playlist : NSObject
{
    NSMutableArray* _array;     // array of PlaylistItem
    PlaylistItem* _currentItem;

    unsigned int _repeatMode;     // REPEAT_*
}

#pragma mark -
#pragma mark add/remove
- (int)count;
- (PlaylistItem*)itemAtIndex:(int)index;
- (void)addFile:(NSString*)filename addSeries:(BOOL)addSeries;
- (void)addFiles:(NSArray*)filenames;
- (void)addURL:(NSURL*)movieURL;
- (int)insertFile:(NSString*)filename atIndex:(unsigned int)index
        addSeries:(BOOL)addSeries;
- (void)insertFiles:(NSArray*)filenames atIndex:(unsigned int)index;
- (void)insertURL:(NSURL*)movieURL atIndex:(unsigned int)index;
- (unsigned int)moveItemsAtIndexes:(NSIndexSet*)indexes
                           toIndex:(unsigned int)index;
- (void)removeItemAtIndex:(unsigned int)index;
- (void)removeItemsAtIndexes:(NSIndexSet*)indexes;
- (void)removeAllItems;

#pragma mark -
#pragma mark play
- (PlaylistItem*)currentItem;
- (NSEnumerator*)itemEnumerator;
- (int)indexOfItem:(PlaylistItem*)item;
- (void)setCurrentItemAtIndex:(unsigned int)index;
- (void)setPrevItem;
- (void)setNextItem;

#pragma mark -
#pragma mark repeat-mode
- (unsigned int)repeatMode;
- (void)setRepeatMode:(unsigned int)mode;

@end

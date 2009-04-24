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

#import "Playlist.h"

#import "MMovie.h"
#import "MSubtitle.h"  // for auto-find-subtitle

@implementation PlaylistItem

- (id)initWithMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    if (self = [super init]) {
        _movieURL = [movieURL retain];
        _subtitleURLs = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        [self setMovieURL:[coder decodeObjectForKey:@"MovieURL"]];
        _subtitleURLs = [[NSMutableArray alloc] initWithCapacity:1];
        // for legacy
        NSURL* subtitleURL = [coder decodeObjectForKey:@"SubtitleURL"];
        if (subtitleURL) {
            [self addSubtitleURL:subtitleURL];
        }
        [self addSubtitleURLs:[coder decodeObjectForKey:@"SubtitleURLs"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [coder encodeObject:_movieURL forKey:@"MovieURL"];
    [coder encodeObject:_subtitleURLs forKey:@"SubtitleURLs"];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_movieURL release];
    [_subtitleURLs release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    PlaylistItem* item = [[PlaylistItem alloc] initWithMovieURL:_movieURL];
    [item setSubtitleURLs:_subtitleURLs];
    return item;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSURL*)movieURL       { return _movieURL; }
- (NSArray*)subtitleURLs { return _subtitleURLs; }

- (void)setMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    [movieURL retain], [_movieURL release], _movieURL = movieURL;
}

- (void)setSubtitleURLs:(NSArray*)subtitleURLs { [_subtitleURLs setArray:subtitleURLs]; }
- (void)addSubtitleURL:(NSURL*)subtitleURL
{
    if (![_subtitleURLs containsObject:subtitleURL]) {
        [_subtitleURLs addObject:subtitleURL];
    }
}

- (void)removeSubtitleURL:(NSURL*)subtitleURL
{
    if ([_subtitleURLs containsObject:subtitleURL]) {
        [_subtitleURLs removeObject:subtitleURL];
    }
}

- (void)addSubtitleURLs:(NSArray*)subtitleURLs
{
    NSURL* subtitleURL;
    NSEnumerator* e = [subtitleURLs objectEnumerator];
    while (subtitleURL = [e nextObject]) {
        [self addSubtitleURL:subtitleURL];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (BOOL)isEqualToMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    return [[_movieURL absoluteString] isEqualToString:[movieURL absoluteString]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation Playlist

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _array = [[NSMutableArray alloc] initWithCapacity:10];
        _repeatMode = REPEAT_OFF;
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _array = [[coder decodeObjectForKey:@"Array"] retain];
        int index = [coder decodeInt32ForKey:@"CurrentIndex"];
        _currentItem = (0 <= index && index < [_array count]) ?
                                [_array objectAtIndex:index] : nil;
        _repeatMode = [coder decodeInt32ForKey:@"RepeatMode"];

        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MPlaylistUpdatedNotification object:self];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [coder encodeObject:_array forKey:@"Array"];
    [coder encodeInt32:[_array indexOfObject:_currentItem] forKey:@"CurrentIndex"];
    [coder encodeInt32:_repeatMode forKey:@"RepeatMode"];
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_array release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark add/remove

- (BOOL)containsMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    PlaylistItem* item;
    NSEnumerator* enumerator = [_array objectEnumerator];
    while (item = [enumerator nextObject]) {
        if ([item isEqualToMovieURL:movieURL]) {
            return TRUE;
        }
    }
    return FALSE;
}

int compareSubtitleURLs(id url1, id url2, void* context)
{
    NSString* path1 = [url1 absoluteString], *ext1 = [path1 pathExtension];
    NSString* path2 = [url2 absoluteString], *ext2 = [path2 pathExtension];
    if (NSOrderedSame == [ext1 caseInsensitiveCompare:ext2]) {
        unsigned int len1 = [path1 length];
        unsigned int len2 = [path2 length];
        return (len1 < len2) ? NSOrderedAscending :
        (len1 > len2) ? NSOrderedDescending : NSOrderedSame;
    }
    return [path1 caseInsensitiveCompare:path2];
}

- (NSArray*)findSubtitleURLsForMoviePath:(NSString*)moviePath
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, moviePath);
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* directory = [moviePath stringByDeletingLastPathComponent];
    NSString* movieFilename = [moviePath lastPathComponent];
    NSString* movieFilenameWithoutExt = [movieFilename stringByDeletingPathExtension];
    NSArray* fileExtensions = [MSubtitle fileExtensions];
    
    NSMutableArray* subtitleURLs = [NSMutableArray arrayWithCapacity:1];
    NSString* filename, *path;
    NSRange range = NSMakeRange(0, [movieFilenameWithoutExt length]);
    NSArray* contents = [fileManager sortedDirectoryContentsAtPath:directory];
    NSEnumerator* enumerator = [contents objectEnumerator];
    while (filename = [enumerator nextObject]) {
        if ([filename hasAnyExtension:fileExtensions] &&
            range.length <= [filename length] &&
            [filename compare:movieFilenameWithoutExt
                      options:NSCaseInsensitiveSearch
                        range:range] == NSOrderedSame) {
            path = [directory stringByAppendingPathComponent:filename];
            [subtitleURLs addObject:[NSURL fileURLWithPath:path]];
        }
    }
    [subtitleURLs sortUsingFunction:compareSubtitleURLs context:nil];
    return subtitleURLs;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (int)count                            { return [_array count]; }
- (PlaylistItem*)itemAtIndex:(int)index { return [_array objectAtIndex:index]; }

- (void)addFile:(NSString*)filename option:(int)option
{
    //TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, filename,
    //      (option == OPTION_ONLY) ? @"only" :
    //      (option == OPTION_SERIES)  ? @"series" : @"all");
    [self insertFile:filename atIndex:[_array count] option:option];
}

- (void)addFiles:(NSArray*)filenames
{
    //TRACE(@"%s {%@}", __PRETTY_FUNCTION__, filenames);
    [self insertFiles:filenames atIndex:[_array count]];
}

- (void)addURL:(NSURL*)movieURL
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    [self insertURL:movieURL atIndex:[_array count]];
}

- (int)insertFile:(NSString*)filename atIndex:(unsigned int)index option:(int)option
{
    //TRACE(@"%s \"%@\" at %d %@", __PRETTY_FUNCTION__, filename, index,
    //      (option == OPTION_ONLY) ? @"only" :
    //      (option == OPTION_SERIES)  ? @"series" : @"all");
    BOOL isDirectory;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filename isDirectory:&isDirectory]) {
        return 0;
    }

    int count = 0;
    NSArray* fileExtensions = [MMovie fileExtensions];
    if (isDirectory) {
        NSString* directory = filename;
        NSArray* contents = [fileManager sortedDirectoryContentsAtPath:directory];
        NSEnumerator* enumerator = [contents objectEnumerator];
        while (filename = [enumerator nextObject]) {
            filename = [directory stringByAppendingPathComponent:filename];
            if ([filename hasAnyExtension:fileExtensions]) {
                [self insertURL:[NSURL fileURLWithPath:filename] atIndex:index++];
            }
        }
        count = [contents count];
    }
    else if (option != OPTION_ONLY) {
        NSString* directory = [filename stringByDeletingLastPathComponent];
        NSString* movieFilename = [filename lastPathComponent];

        NSArray* contents = [fileManager sortedDirectoryContentsAtPath:directory];
        NSEnumerator* enumerator = [contents objectEnumerator];
        while (filename = [enumerator nextObject]) {
            if ([filename hasAnyExtension:fileExtensions] &&
                (option == OPTION_ALL ||
                 (option == OPTION_SERIES && checkMovieSeries(movieFilename, filename)))) {
                [self insertURL:[NSURL fileURLWithPath:
                            [directory stringByAppendingPathComponent:filename]]
                        atIndex:index++];

                if ([filename isEqualToString:movieFilename]) {
                    _currentItem = [_array lastObject];
                }
            }
        }
        count = [contents count];
    }
    else if ([filename hasAnyExtension:fileExtensions]) {
        [self insertURL:[NSURL fileURLWithPath:filename] atIndex:index];
        count = 1;
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MPlaylistUpdatedNotification object:self];

    return count;
}

- (void)insertFiles:(NSArray*)filenames atIndex:(unsigned int)index
{
    //TRACE(@"%s {%@} at %d", __PRETTY_FUNCTION__, filenames, index);
    NSString* filename;
    NSEnumerator* enumerator = [filenames objectEnumerator];
    while (filename = [enumerator nextObject]) {
        index += [self insertFile:filename atIndex:index option:OPTION_ONLY];
    }
}

- (void)insertURL:(NSURL*)movieURL atIndex:(unsigned int)index
{
    //TRACE(@"%s \"%@\" at %d", __PRETTY_FUNCTION__, [movieURL absoluteString], index);
    if ([self containsMovieURL:movieURL]) {
        return;     // already contained
    }
    
    NSArray* subtitleURLs = nil;
    if ([movieURL isFileURL]) {
        subtitleURLs = [self findSubtitleURLsForMoviePath:[movieURL path]];
    }

    PlaylistItem* item = [[PlaylistItem alloc] initWithMovieURL:movieURL];
    [item setSubtitleURLs:subtitleURLs];
    [_array insertObject:item atIndex:MIN(index, [_array count])];

    if (_currentItem == nil) {
        _currentItem = item;    // auto-select
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MPlaylistUpdatedNotification object:self];
}

- (unsigned int)moveItemsAtIndexes:(NSIndexSet*)indexes toIndex:(unsigned int)index
{
    //TRACE(@"%s %@ to %d", __PRETTY_FUNCTION__, indexes, index);
    if ([indexes firstIndex] <= index && index <= [indexes lastIndex]) {
        int i, lastIndex = index;
        for (i = [indexes firstIndex]; i <= lastIndex; i++) {
            if ([indexes containsIndex:i]) {
                index--;
            }
        }
    }
    else if ([indexes lastIndex] < index) {
        index -= [indexes count];
    }

    NSArray* items = [_array objectsAtIndexes:indexes];
    [_array removeObjectsAtIndexes:indexes];

    PlaylistItem* item;
    NSEnumerator* enumerator = [items objectEnumerator];
    while (item = [enumerator nextObject]) {
        [_array insertObject:item atIndex:index++];
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MPlaylistUpdatedNotification object:self];

    return index - [items count];   // new first index
}

- (void)removeItemAtIndex:(unsigned int)index
{
    //TRACE(@"%s at %d", __PRETTY_FUNCTION__, index);
    if ([_array count] <= index) {
        return;
    }

    if (_currentItem == [_array objectAtIndex:index]) {
        if (index == [_array count] - 1) {
            index = [_array count] - 2;
        }
        _currentItem = (0 <= index) ? [_array objectAtIndex:index] : nil;
    }
    [_array removeObjectAtIndex:index];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MPlaylistUpdatedNotification object:self];
}

- (void)removeItemsAtIndexes:(NSIndexSet*)indexes
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, indexes);
    [_array removeObjectsAtIndexes:indexes];

    if (![_array containsObject:_currentItem]) {
        _currentItem = nil;
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MPlaylistUpdatedNotification object:self];
}

- (void)removeAllItems
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _currentItem = nil;
    [_array removeAllObjects];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MPlaylistUpdatedNotification object:self];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark play

- (PlaylistItem*)currentItem { return _currentItem; }
- (NSEnumerator*)itemEnumerator { return [_array objectEnumerator]; }
- (int)indexOfItem:(PlaylistItem*)item { return [_array indexOfObject:item]; }

- (void)setCurrentItemAtIndex:(unsigned int)index
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, index);
    _currentItem = (0 <= index && index < [_array count]) ?
                                        [_array objectAtIndex:index] : nil;
}

- (void)setNextItem_RepeatOff:(BOOL)forward
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, forward ? @"forward" : @"backward");
    assert(0 < [_array count]);
    if (!_currentItem) {
        _currentItem = (forward) ? [_array objectAtIndex:0] :
                                   [_array objectAtIndex:[_array count] - 1];
    }
    else {
        int index = [_array indexOfObject:_currentItem];
        if (forward) {
            _currentItem = (index == [_array count] - 1) ? nil :
                                                [_array objectAtIndex:index + 1];
        }
        else {
            _currentItem = (index == 0) ? nil : [_array objectAtIndex:index - 1];
        }
    }
}

- (void)setNextItem_RepeatAll:(BOOL)forward
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, forward ? @"forward" : @"backward");
    assert(0 < [_array count]);
    if (!_currentItem) {
        _currentItem = (forward) ? [_array objectAtIndex:0] :
                                   [_array objectAtIndex:[_array count] - 1];
    }
    else {
        int index = [_array indexOfObject:_currentItem];
        if (forward) {
            index = (index < [_array count] - 1) ? (index + 1) : 0;
        }
        else {
            index = (0 < index) ? (index - 1) : [_array count] - 1;
        }
        _currentItem = [_array objectAtIndex:index];
    }
}

- (void)setNextItem_RepeatOne
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    assert(0 < [_array count]);
    if (!_currentItem) {
        _currentItem = [_array objectAtIndex:0];
    }
}

- (void)setPrevItem
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (0 < [_array count]) {
        switch (_repeatMode) {
            case REPEAT_OFF : [self setNextItem_RepeatOff:FALSE];   break;
            case REPEAT_ALL : [self setNextItem_RepeatAll:FALSE];   break;
            case REPEAT_ONE : [self setNextItem_RepeatOne];         break;
        }
    }
}

- (void)setNextItem
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (0 < [_array count]) {
        switch (_repeatMode) {
            case REPEAT_OFF : [self setNextItem_RepeatOff:TRUE];    break;
            case REPEAT_ALL : [self setNextItem_RepeatAll:TRUE];    break;
            case REPEAT_ONE : [self setNextItem_RepeatOne];         break;
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark repeat-mode

- (unsigned int)repeatMode { return _repeatMode; }

- (void)setRepeatMode:(unsigned int)mode
{
    //TRACE(@"%s %d", __PRETTY_FUNCTION__, mode);
    _repeatMode = mode;
}

@end

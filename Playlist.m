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

#import "Playlist.h"

#import "MMovie.h"
#import "MSubtitle.h"  // for auto-find-subtitle

@implementation PlaylistItem

- (id)initWithMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    if (self = [super init]) {
        _movieURL = [movieURL retain];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        [self setMovieURL:[coder decodeObjectForKey:@"MovieURL"]];
        [self setSubtitleURL:[coder decodeObjectForKey:@"SubtitleURL"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [coder encodeObject:_movieURL forKey:@"MovieURL"];
    if (_subtitleURL) {
        [coder encodeObject:_subtitleURL forKey:@"SubtitleURL"];
    }
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_movieURL release];
    [_subtitleURL release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    PlaylistItem* item = [[PlaylistItem alloc] initWithMovieURL:_movieURL];
    [item setSubtitleURL:_subtitleURL];
    return item;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSURL*)movieURL    { return _movieURL; }
- (NSURL*)subtitleURL { return _subtitleURL; }

- (void)setMovieURL:(NSURL*)movieURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    [movieURL retain], [_movieURL release], _movieURL = movieURL;
}

- (void)setSubtitleURL:(NSURL*)subtitleURL
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [subtitleURL absoluteString]);
    [subtitleURL retain], [_subtitleURL release], _subtitleURL = subtitleURL;
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

- (NSString*)findSubtitlePathForMoviePath:(NSString*)moviePath
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, moviePath);
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* path, *ext;
    NSString* pathWithoutExt = [moviePath stringByDeletingPathExtension];
    NSArray* extensions = [MSubtitle subtitleTypes];
    NSEnumerator* enumerator = [extensions objectEnumerator];
    while (ext = [enumerator nextObject]) {
        path = [pathWithoutExt stringByAppendingPathExtension:ext];
        if ([fileManager fileExistsAtPath:path] &&
            [fileManager isReadableFileAtPath:path]) {
            return path;
        }
    }
    return nil;
}

- (BOOL)checkMovieSeriesFile:(NSString*)path forMovieFile:(NSString*)moviePath
{
    //TRACE(@"%s \"%@\" for \"%@\"", __PRETTY_FUNCTION__, path, moviePath);
    if ([path isEqualToString:moviePath]) {
        return TRUE;
    }

    // don't check if same extension for more flexibility
    //if (![[path pathExtension] isEqualToString:[moviePath pathExtension]]) {
    //    return FALSE;
    //}

    unsigned int length1 = [moviePath length];
    unsigned int length2 = [path length];
    unsigned int i, minSameLength = 5;
    unichar c1, c2;
    for (i = 0; i < length1 && i < length2; i++) {
        c1 = [moviePath characterAtIndex:i];
        c2 = [path characterAtIndex:i];
        if (toupper(c1) != toupper(c2)) {
            return (minSameLength <= i || (isdigit(c1) && isdigit(c2)));
        }
    }
    return TRUE;
}        

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (int)count                            { return [_array count]; }
- (PlaylistItem*)itemAtIndex:(int)index { return [_array objectAtIndex:index]; }

- (void)addFile:(NSString*)filename option:(int)option
{
    TRACE(@"%s \"%@\" %@", __PRETTY_FUNCTION__, filename,
          (option == OPTION_ONLY) ? @"only" :
          (option == OPTION_SERIES)  ? @"series" : @"all");
    [self insertFile:filename atIndex:[_array count] option:option];
}

- (void)addFiles:(NSArray*)filenames
{
    TRACE(@"%s {%@}", __PRETTY_FUNCTION__, filenames);
    [self insertFiles:filenames atIndex:[_array count]];
}

- (void)addURL:(NSURL*)movieURL
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, [movieURL absoluteString]);
    [self insertURL:movieURL atIndex:[_array count]];
}

- (int)insertFile:(NSString*)filename atIndex:(unsigned int)index option:(int)option
{
    TRACE(@"%s \"%@\" at %d %@", __PRETTY_FUNCTION__, filename, index,
          (option == OPTION_ONLY) ? @"only" :
          (option == OPTION_SERIES)  ? @"series" : @"all");
    BOOL isDirectory;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filename isDirectory:&isDirectory]) {
        return 0;
    }

    NSArray* movieFileExtensions = [MMovie movieFileExtensions];
    if (isDirectory) {
        NSString* directory = filename;
        NSArray* contents = [fileManager sortedDirectoryContentsAtPath:directory];
        NSEnumerator* enumerator = [contents objectEnumerator];
        while (filename = [enumerator nextObject]) {
            filename = [directory stringByAppendingPathComponent:filename];
            if ([filename hasAnyExtension:movieFileExtensions]) {
                [self insertURL:[NSURL fileURLWithPath:filename] atIndex:index++];
            }
        }
        return [contents count];
    }
    else if (option != OPTION_ONLY) {
        NSString* directory = [filename stringByDeletingLastPathComponent];
        NSString* movieFilename = [filename lastPathComponent];

        NSArray* contents = [fileManager sortedDirectoryContentsAtPath:directory];
        NSEnumerator* enumerator = [contents objectEnumerator];
        while (filename = [enumerator nextObject]) {
            if ([filename hasAnyExtension:movieFileExtensions] &&
                (option == OPTION_ALL || (option == OPTION_SERIES &&
                  [self checkMovieSeriesFile:filename forMovieFile:movieFilename]))) {
                [self insertURL:[NSURL fileURLWithPath:
                            [directory stringByAppendingPathComponent:filename]]
                        atIndex:index++];

                if ([filename isEqualToString:movieFilename]) {
                    _currentItem = [_array lastObject];
                }
            }
        }
        return [contents count];
    }
    else if ([filename hasAnyExtension:movieFileExtensions]) {
        [self insertURL:[NSURL fileURLWithPath:filename] atIndex:index];
        return 1;
    }
    return 0;
}

- (void)insertFiles:(NSArray*)filenames atIndex:(unsigned int)index
{
    TRACE(@"%s {%@} at %d", __PRETTY_FUNCTION__, filenames, index);
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
    
    NSURL* subtitleURL = nil;
    if ([movieURL isFileURL]) {
        NSString* subtitlePath = [self findSubtitlePathForMoviePath:[movieURL path]];
        if (subtitlePath) {
            subtitleURL = [NSURL fileURLWithPath:subtitlePath];
        }
    }
    
    PlaylistItem* item = [[PlaylistItem alloc] initWithMovieURL:movieURL];
    [item setSubtitleURL:subtitleURL];
    [_array insertObject:item atIndex:MIN(index, [_array count])];
    
    if (_currentItem == nil) {
        _currentItem = item;    // auto-select
    }
}

- (unsigned int)moveItemsAtIndexes:(NSIndexSet*)indexes toIndex:(unsigned int)index
{
    TRACE(@"%s %@ to %d", __PRETTY_FUNCTION__, indexes, index);
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
    return index - [items count];   // new first index
}

- (void)removeItemAtIndex:(unsigned int)index
{
    TRACE(@"%s at %d", __PRETTY_FUNCTION__, index);
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
}

- (void)removeItemsAtIndexes:(NSIndexSet*)indexes
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, indexes);
    [_array removeObjectsAtIndexes:indexes];

    if (![_array containsObject:_currentItem]) {
        _currentItem = nil;
    }
}

- (void)removeAllItems
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _currentItem = nil;
    [_array removeAllObjects];
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

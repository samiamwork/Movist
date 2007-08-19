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

#import "AppController.h"
#import "UserDefaults.h"

#import "MMovie_FFMPEG.h"
#import "MMovie_QuickTime.h"
#import "MSubtitle.h"
#import "Playlist.h"

#import "MMovieView.h"
#import "CustomControls.h"  // for SeekSlider

@implementation AppController (Open)

- (void)setMessageWithURL:(NSURL*)url info:(NSString*)info
{
    NSString* name = ([url isFileURL]) ? [[url path] lastPathComponent] :
                                         [[url absoluteString] lastPathComponent];
    NSStringEncoding encoding = [NSString defaultCStringEncoding];
    const char* cString = [name cStringUsingEncoding:encoding];
    if (cString) {
        name = [NSString stringWithCString:cString encoding:encoding];
    }
    [_movieView setMessage:name info:info];
}

- (MMovie*)movieFromURL:(NSURL*)movieURL withMovieClass:(Class)movieClass
                   error:(NSError**)error
{
#if defined(_SUPPORT_FFMPEG)
    TRACE(@"%s \"%@\" with \"%@\"", __PRETTY_FUNCTION__,
          [movieURL absoluteString], movieClass);
    NSArray* classes;
    if (movieClass) {
        // if movieClass is specified, then try it only
        classes = [NSArray arrayWithObject:movieClass];
    }
    else {
        // try all movie-classes with starting default-movie-class
        int decoder = [_defaults integerForKey:MDefaultDecoderKey];
        if (decoder == DECODER_QUICKTIME) {
            classes = [NSArray arrayWithObjects:
                [MMovie_QuickTime class], [MMovie_FFMPEG class], nil];
        }
        else {
            classes = [NSArray arrayWithObjects:
                [MMovie_FFMPEG class], [MMovie_QuickTime class], nil];
        }
    }
    
    MMovie* movie;
    NSEnumerator* enumerator = [classes objectEnumerator];
    while (movieClass = [enumerator nextObject]) {
        movie = [[movieClass alloc] initWithURL:movieURL error:error];
        if (movie) {
            return [movie autorelease];
        }
    }
#else
    // always QuickTime!
    MMovie* movie = [[MMovie_QuickTime alloc] initWithURL:movieURL error:error];
    if (movie) {
        return [movie autorelease];
    }
#endif
    return nil;
}

- (NSArray*)subtitleFromURL:(NSURL*)subtitleURL
               withEncoding:(CFStringEncoding)cfEncoding
                      error:(NSError**)error
{
    TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [subtitleURL absoluteString]);
    if (!subtitleURL) {
        return nil;
    }
    if (![subtitleURL isFileURL]) {
        TRACE(@"remote subtitle is not supported yet");
        *error = [NSError errorWithDomain:NSLocalizedString(@"Movist", nil)
                                     code:0 userInfo:0];
        return nil;
    }
    
    // find parser for subtitle's path extension
    NSString* path = [subtitleURL path];
    Class parserClass = [MSubtitle subtitleParserClassForType:[path pathExtension]];
    if (!parserClass) {
        *error = [NSError errorWithDomain:NSLocalizedString(@"Movist", nil)
                                     code:1 userInfo:0];
        return nil;
    }

    // open subtitle with subtitle-encoding
    NSData* data = [NSData dataWithContentsOfFile:path options:0 error:error];
    if (!data) {
        return nil;
    }
    if (cfEncoding == kCFStringEncodingInvalidId) {
        cfEncoding = [_defaults integerForKey:MSubtitleEncodingKey];
    }
    NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    //TRACE(@"CFStringEncoding:%u => NSStringEncoding:%u", cfEncoding, nsEncoding);
    NSString* s = [[[NSString alloc] initWithData:data encoding:nsEncoding] autorelease];
    if (!s) {
        // remove unconvertable characters
        const char* p = (const char*)[data bytes];
        int i = 0, length = [data length];
        char* contents = (char*)malloc(length);
        while (i < length) {
            contents[i] = *p++;
            if (contents[i] & 0x80) {
                contents[i + 1] = *p++;
                contents[i + 2] = '\0';
                if ([NSString stringWithCString:&contents[i] encoding:nsEncoding]) {
                    i += 2;
                }
            }
            else {
                i++;
            }
        }
        s = [NSString stringWithCString:contents encoding:nsEncoding];
        if (!s) {
            *error = [NSError errorWithDomain:NSLocalizedString(@"Movist", nil)
                                         code:2 userInfo:0];
            return nil;
        }
    }

    // parse subtitles
    id<MSubtitleParser> parser = [[[parserClass alloc] init] autorelease];
    return [parser parseString:s options:[parserClass defaultOptions] error:error];
}

- (BOOL)openMovie:(NSURL*)movieURL movieClass:(Class)movieClass
         subtitle:(NSURL*)subtitleURL subtitleEncoding:(CFStringEncoding)subtitleEncoding
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [self closeMovie];
    }
    assert(_movie == nil);
    if (!movieURL) {
        return FALSE;
    }

    // open movie
    NSError* error;
    MMovie* movie = [self movieFromURL:movieURL withMovieClass:movieClass error:&error];
    if (!movie || ![movie setOpenGLContext:[_movieView openGLContext]
                               pixelFormat:[_movieView pixelFormat] error:&error]) {
        runAlertPanelForOpenError(error, movieURL);
        return FALSE;
    }
    _movie = [movie retain];

    // open subtitle
    if (subtitleURL && [_defaults boolForKey:MSubtitleEnableKey]) {
        NSArray* subtitles = [self subtitleFromURL:subtitleURL
                                      withEncoding:subtitleEncoding error:&error];
        if (!subtitles) {
            runAlertPanelForOpenError(error, subtitleURL);
            // continue... subtitle is not necessary for movie.
        }
        else {
            _subtitles = [subtitles retain];

            int i;
            MSubtitle* subtitle;
            if ([_subtitleNameSet count] == 0) {
                // select first language by default
                for (i = 0; i < [_subtitles count]; i++) {
                    subtitle = [_subtitles objectAtIndex:i];
                    [subtitle setEnabled:(i == 0)];
                }
            }
            else {
                // select previous selected language
                for (i = 0; i < [_subtitles count]; i++) {
                    subtitle = [_subtitles objectAtIndex:i];
                    [subtitle setEnabled:[_subtitleNameSet containsObject:[subtitle name]]];
                }
            }
        }
    }

    // update movie & UI
    [self autoenableAudioTracks];
    //[_movie setVolume:[movie preferredVolume]];
    [_movie setVolume:[_defaults floatForKey:MVolumeKey]];
    [_movie setMuted:([_muteButton state] == NSOnState)];
    [_movieView setMovie:_movie];
    [_movieView setSubtitles:_subtitles];
    [self setFullScreenFill:[_defaults integerForKey:MFullScreenFillForWideMovieKey] forWideMovie:TRUE];
    [self setFullScreenFill:[_defaults integerForKey:MFullScreenFillForStdMovieKey] forWideMovie:FALSE];
    [_seekSlider setMinValue:0];
    [_seekSlider setMaxValue:[_movie duration]];
    [_seekSlider clearRepeat];
    [_panelSeekSlider setMinValue:0];
    [_panelSeekSlider setMaxValue:[_movie duration]];
    [_panelSeekSlider clearRepeat];
    _prevMovieTime = 0.0;
    [self updateUI];

    // observe movie's notifications
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(movieRateChanged:)
               name:MMovieRateChangeNotification object:_movie];
    [nc addObserver:self selector:@selector(movieCurrentTimeChanged:)
               name:MMovieCurrentTimeNotification object:_movie];
    [nc addObserver:self selector:@selector(movieEnded:)
               name:MMovieEndNotification object:_movie];

    // show message
    [self setMessageWithURL:movieURL info:[[_movie class] name]];

    // add to recent-menu
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[self movieURL]];

    if (![self isFullScreen]) {
        [self resizeWithMagnification:1.0];
        if ([_defaults boolForKey:MAutoFullScreenKey]) {
            [self beginFullScreen];
        }
    }
    [_movie setRate:_playRate];  // auto play
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark public interface

- (BOOL)openFile:(NSString*)filename updatePlaylist:(BOOL)updatePlaylist
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    return [self openFiles:[NSArray arrayWithObject:filename]
            updatePlaylist:updatePlaylist];
}

- (BOOL)openFiles:(NSArray*)filenames updatePlaylist:(BOOL)updatePlaylist
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_mainWindow isVisible]) {
        [_mainWindow makeKeyAndOrderFront:self];
    }

    if ([filenames count] == 1 &&
        [[filenames objectAtIndex:0] hasAnyExtension:[MSubtitle subtitleTypes]]) {
        if (_movie) {   // reopen subtitle
            NSURL* subtitleURL = [NSURL fileURLWithPath:[filenames objectAtIndex:0]];
            [[_playlist currentItem] setSubtitleURL:subtitleURL];
            [_playlistController updateUI];
            [self reopenSubtitle];
        }
        return TRUE;
    }
    else if (updatePlaylist) {
        [_playlist removeAllItems];
        if ([filenames count] == 1) {
            [_playlist addFile:[filenames objectAtIndex:0] addSeries:TRUE];
        }
        else {
            [_playlist addFiles:filenames];
        }
        [_playlistController updateUI];
        return (0 < [_playlist count]) ? [self openCurrentPlaylistItem] : FALSE;
    }
    else {
        // use temp. playlist for auto-detecting subtitle.
        Playlist* tempPlaylist = [[[Playlist alloc] init] autorelease];
        [tempPlaylist addFile:[filenames objectAtIndex:0] addSeries:FALSE];
        if (1 == [tempPlaylist count]) {
            PlaylistItem* item = [tempPlaylist currentItem];
            return [self openMovie:[item movieURL] movieClass:nil
                          subtitle:[item subtitleURL] subtitleEncoding:kCFStringEncodingInvalidId];
        }
        // don't open multiple files without updating playlist
        return FALSE;
    }
}

- (BOOL)openURL:(NSURL*)url updatePlaylist:(BOOL)updatePlaylist
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* s = @"\"Open URL...\" is not implemented yet.";
    NSRunAlertPanel(NSLocalizedString(@"Movist", nil), s,
                    NSLocalizedString(@"OK", nil), nil, nil);
    return FALSE;
    /*
    if ([[url absoluteString] hasAnyExtension:[MSubtitle subtitleTypes]]) {
        if (_movie) {   // reopen subtitle
            [[_playlist currentItem] setSubtitleURL:url];
            [_playlistController updateUI];
            [self reopenSubtitle];
        }
        return TRUE;
    }
    else if (updatePlaylist) {
        [_playlist removeAllItems];
        [_playlist addURL:url];
        [_playlistController updateUI];
        return (0 < [_playlist count]) ? [self openCurrentPlaylistItem] : FALSE;
    }
    else {
        Playlist* tempPlaylist = [[[Playlist alloc] init] autorelease];
        [tempPlaylist addURL:url];
        PlaylistItem* item = [tempPlaylist currentItem];
        return [self openMovie:[item movieURL] movieClass:nil
                      subtitle:[item subtitleURL] subtitleEncoding:kCFStringEncodingInvalidId];
    }
     */
}

- (BOOL)openSubtitle:(NSURL*)subtitleURL encoding:(CFStringEncoding)encoding
{
    NSError* error;
    NSArray* subtitles = [self subtitleFromURL:subtitleURL withEncoding:encoding error:&error];
    if (!subtitles) {
        runAlertPanelForOpenError(error, subtitleURL);
        return FALSE;
    }

    [_subtitles release];
    _subtitles = [subtitles retain];

    [[_playlist currentItem] setSubtitleURL:subtitleURL];
    [_movieView setSubtitles:   // select first language by default
        [NSArray arrayWithObject:[_subtitles objectAtIndex:0]]];

    [self updateSubtitleLanguageMenu];

    [_movie gotoBeginning];

    if (encoding == kCFStringEncodingInvalidId) {
        encoding = [_defaults integerForKey:MSubtitleEncodingKey];
    }
    NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
    NSString* encodingString = [NSString localizedNameOfStringEncoding:nsEncoding];
    [self setMessageWithURL:subtitleURL info:encodingString];

    return TRUE;
}

- (BOOL)reopenMovieWithMovieClass:(Class)movieClass
{
    TRACE(@"%s:%@", __PRETTY_FUNCTION__, movieClass);
    [self closeMovie];

    PlaylistItem* item = [_playlist currentItem];
    return [self openMovie:[item movieURL] movieClass:movieClass
                  subtitle:[item subtitleURL] subtitleEncoding:kCFStringEncodingInvalidId];
}

- (void)reopenSubtitle
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [self openSubtitle:[[_playlist currentItem] subtitleURL]
                  encoding:kCFStringEncodingInvalidId];
    }
}

- (void)closeMovie
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        // don't clear _audioTrackIndexSet.
        // _audioTrackIndexSet will be used in next open.

        // init _subtitleNameSet for next open.
        [_subtitleNameSet removeAllObjects];
        MSubtitle* subtitle;
        NSEnumerator* enumerator = [_subtitles objectEnumerator];
        while (subtitle = [enumerator nextObject]) {
            if ([subtitle isEnabled]) {
                [_subtitleNameSet addObject:[subtitle name]];
            }
        }

        [_playlistController updateUI];

        [[NSNotificationCenter defaultCenter]
            removeObserver:self name:nil object:_movie];
        
        [_movieView setMovie:nil];
        [_movieView setSubtitles:nil];
        [_movie cleanup], _movie = nil;

        [_subtitles release], _subtitles = nil;
        [self updateUI];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)openFileAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self clearPureArrowKeyEquivalents];

    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:TRUE];
    if (NSOKButton == [panel runModalForTypes:[MMovie movieTypes]]) {
        [self openFile:[panel filename] updatePlaylist:TRUE];
    }

    [self setPureArrowKeyEquivalents];
}

- (IBAction)openURLAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    // FIXME : not implemented yet
    [self openURL:nil updatePlaylist:TRUE];
}

- (IBAction)openSubtitleFileAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:TRUE];
    if (NSOKButton == [panel runModalForTypes:[MSubtitle subtitleTypes]]) {
        [self openSubtitle:[NSURL fileURLWithPath:[panel filename]]
                  encoding:kCFStringEncodingInvalidId];
    }
}

- (IBAction)reopenMovieAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([sender tag] == DECODER_QUICKTIME) {
        [self reopenMovieWithMovieClass:[MMovie_QuickTime class]];
    }
    else {
        #if defined(_SUPPORT_FFMPEG)
        [self reopenMovieWithMovieClass:[MMovie_FFMPEG class]];
        #endif
    }
}

- (IBAction)reopenSubtitleAction:(id)sender
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self openSubtitle:[[_playlist currentItem] subtitleURL]
              encoding:[sender tag]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark properties view

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int count = 0;
    if (_movie) {
        count += [[_movie videoTracks] count];
        count += [[_movie audioTracks] count];
        if (_subtitles) {
            count += [_subtitles count];
        }
    }
    return count;
}

- (id)tableView:(NSTableView*)tableView
    objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    //TRACE(@"%s %@:%d", __PRETTY_FUNCTION__, [tableColumn identifier], rowIndex);
    int videoCount = [[_movie videoTracks] count];
    int audioCount = [[_movie audioTracks] count];
    int videoIndex = rowIndex;
    int audioIndex = videoIndex - videoCount;
    int subtitleIndex = audioIndex - audioCount;

    NSString* identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"enable"]) {
        // the first video track is always enable.
        [[tableColumn dataCellForRow:rowIndex] setEnabled:(rowIndex != 0)];

        if (videoIndex < videoCount) {
            return [NSNumber numberWithBool:TRUE];
        }
        else if (audioIndex < audioCount) {
            BOOL state = [_audioTrackIndexSet containsIndex:audioIndex];
            return [NSNumber numberWithBool:state];
        }
        else {
            BOOL state = [[_subtitles objectAtIndex:subtitleIndex] isEnabled];
            return [NSNumber numberWithBool:state];
        }
    }
    else if ([identifier isEqualToString:@"name"]) {
        if (videoIndex < videoCount) {
            return [[[_movie videoTracks] objectAtIndex:videoIndex] name];
        }
        else if (audioIndex < audioCount) {
            return [[[_movie audioTracks] objectAtIndex:audioIndex] name];
        }
        else {
            return [NSString stringWithFormat:
                        NSLocalizedString(@"External Subtitle %d", nil),
                        subtitleIndex + 1];
        }
    }
    else if ([identifier isEqualToString:@"format"]) {
        if (videoIndex < videoCount) {
            return [[[_movie videoTracks] objectAtIndex:videoIndex] format];
        }
        else if (audioIndex < audioCount) {
            return [[[_movie audioTracks] objectAtIndex:audioIndex] format];
        }
        else {
            MSubtitle* subtitle = [_subtitles objectAtIndex:subtitleIndex];
            return [NSString stringWithFormat:@"%@, %@", [subtitle type], [subtitle name]];
        }
    }
    return nil;
}
/*
- (void)tableView:(NSTableView*)tableView willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    TRACE(@"%s %@:%d", __PRETTY_FUNCTION__, [tableColumn identifier], rowIndex);
    // the first video track is always enable. (cannot disable)
    if ([[tableColumn identifier] isEqualToString:@"enable"]) {
        [[tableColumn dataCellForRow:rowIndex] setEnabled:(rowIndex != 0)];
    }
}
*/

- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object
   forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    //TRACE(@"%s %@ %@ %d", __PRETTY_FUNCTION__, object, [tableColumn identifier], rowIndex);
    NSString* identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"enable"]) {
        int videoCount = [[_movie videoTracks] count];
        int audioCount = [[_movie audioTracks] count];
        int videoIndex = rowIndex;
        int audioIndex = videoIndex - videoCount;
        int subtitleIndex = audioIndex - audioCount;
        
        if (videoIndex < videoCount) {
            //BOOL enabled = [(NSNumber*)object boolValue];
            //[self setVideoTrackAtIndex:videoIndex enabled:enabled];
        }
        else if (audioIndex < audioCount) {
            BOOL enabled = [(NSNumber*)object boolValue];
            [self setAudioTrackAtIndex:audioIndex enabled:enabled];
        }
        else {
            MSubtitle* subtitle = [_subtitles objectAtIndex:subtitleIndex];
            BOOL enabled = [(NSNumber*)object boolValue];
            [self setSubtitle:subtitle enabled:enabled];
        }
    }
}

- (IBAction)moviePropertyAction:(id)sender
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, sender);
}

@end

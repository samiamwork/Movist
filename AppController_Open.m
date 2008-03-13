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

#import "Playlist.h"
#import "UserDefaults.h"

#import "MMovie_FFmpeg.h"
#import "MMovie_QuickTime.h"
#import "MSubtitleParser_SMI.h"
#import "MSubtitleParser_SRT.h"

#import "MMovieView.h"
#import "FullScreener.h"
#import "CustomControls.h"  // for SeekSlider

@implementation AppController (Open)

- (MMovie*)movieFromURL:(NSURL*)movieURL withMovieClass:(Class)movieClass
                   error:(NSError**)error
{
    //TRACE(@"%s \"%@\" with \"%@\"", __PRETTY_FUNCTION__,
    //      [movieURL absoluteString], movieClass);
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
                [MMovie_QuickTime class], [MMovie_FFmpeg class], nil];
        }
        else {
            classes = [NSArray arrayWithObjects:
                [MMovie_FFmpeg class], [MMovie_QuickTime class], nil];
        }
    }
    
    MMovie* movie;
    NSString* info;
    NSEnumerator* enumerator = [classes objectEnumerator];
    while (movieClass = [enumerator nextObject]) {
        info = [NSString stringWithFormat:
                NSLocalizedString(@"Opening with %@...", nil), [movieClass name]];
        [_movieView setMessageWithMovieURL:movieURL movieInfo:info
                               subtitleURL:nil subtitleInfo:nil];
        [_movieView display];   // force display

        if (_disablePerianSubtitle) {
            // disable perian-subtitle before using quick-time.
            if ([MMovie_QuickTime class] == movieClass && _perianSubtitleEnabled) {
                [_defaults setPerianSubtitleEnabled:FALSE];
            }
        }        
        movie = [[movieClass alloc] initWithURL:movieURL error:error];
        if (movie) {
            return [movie autorelease];
        }
    }
    return nil;
}

- (NSArray*)subtitleFromURL:(NSURL*)subtitleURL
               withEncoding:(CFStringEncoding)cfEncoding
                      error:(NSError**)error
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [subtitleURL absoluteString]);
    if (!subtitleURL) {
        return nil;
    }
    if (![subtitleURL isFileURL]) {
        //TRACE(@"remote subtitle is not supported yet");
        *error = [NSError errorWithDomain:[NSApp localizedAppName] code:0 userInfo:0];
        return nil;
    }

    // find parser for subtitle's path extension
    NSString* path = [subtitleURL path];
    Class parserClass = [MSubtitleParser parserClassForSubtitleType:[path pathExtension]];
    if (!parserClass) {
        *error = [NSError errorWithDomain:[NSApp localizedAppName] code:1 userInfo:0];
        return nil;
    }

    if (cfEncoding == kCFStringEncodingInvalidId) {
        cfEncoding = [_defaults integerForKey:MSubtitleEncodingKey];
    }

    // parse subtitles
    NSDictionary* options = nil;
    if (parserClass == [MSubtitleParser_SMI class]) {
        NSNumber* stringEncoding = [NSNumber numberWithInt:cfEncoding];
        NSNumber* replaceNLWithBR = [_defaults objectForKey:MSubtitleReplaceNLWithBRKey];
        NSArray* defaultLangIDs = [[_defaults objectForKey:MDefaultLanguageIdentifiersKey]
                                                        componentsSeparatedByString:@" "];
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   stringEncoding, MSubtitleParserOptionKey_stringEncoding,
                   replaceNLWithBR, MSubtitleParserOptionKey_SMI_replaceNewLineWithBR,
                   defaultLangIDs, MSubtitleParserOptionKey_SMI_defaultLanguageIdentifiers,
                   nil];
    }
    else if (parserClass == [MSubtitleParser_SRT class]) {
        NSNumber* stringEncoding = [NSNumber numberWithInt:cfEncoding];
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   stringEncoding, MSubtitleParserOptionKey_stringEncoding,
                   nil];
    }
    //else if (parserClass == [MSubtitleParser_SUB class]) {
    //}

    MSubtitleParser* parser = [[[parserClass alloc] initWithURL:subtitleURL] autorelease];
    NSArray* subtitles = [parser parseWithOptions:options error:error];
    if (!subtitles) {
        *error = [NSError errorWithDomain:[NSApp localizedAppName] code:2 userInfo:0];
        return nil;
    }
    return subtitles;
}

- (void)updateUIForOpenedMovieAndSubtitleEncoding:(CFStringEncoding)subtitleEncoding
{
    NSSize ss = [[_mainWindow screen] frame].size;
    NSSize ms = [_movie adjustedSizeByAspectRatio];
    [_movieView setFullScreenFill:(ss.width / ss.height < ms.width / ms.height) ?
                        [_defaults integerForKey:MFullScreenFillForWideMovieKey] :
                        [_defaults integerForKey:MFullScreenFillForStdMovieKey]];
    [_movieView setSubtitlePosition:[_defaults integerForKey:MSubtitlePositionKey]];
    [_movieView updateMovieRect:TRUE];
    [_movieView hideLogo];
    [_movieView setMovie:_movie];

    if (subtitleEncoding == kCFStringEncodingInvalidId) {
        subtitleEncoding = [_defaults integerForKey:MSubtitleEncodingKey];
    }
    NSString* subtitleInfo = NSStringFromSubtitleEncoding(subtitleEncoding);
    if (_subtitles && [_subtitles count] == 0) {
        subtitleInfo = NSLocalizedString(@"No Subtitle: Reopen with other encodings", nil);
    }
    [_movieView setMessageWithMovieURL:[self movieURL] movieInfo:[[_movie class] name]
                           subtitleURL:[self subtitleURL] subtitleInfo:subtitleInfo];

    if (![self isFullScreen]) {
        [self resizeWithMagnification:1.0];
        if ([_defaults boolForKey:MAutoFullScreenKey]) {
            [self beginFullScreen];
        }
    }
    // subtitles should be set after resizing window.
    [_movieView setSubtitles:_subtitles];

    // update etc. UI
    [_seekSlider setMinValue:0];
    [_seekSlider setMaxValue:[_movie duration]];
    [_seekSlider setIndexedDuration:0];
    [_panelSeekSlider setMinValue:0];
    [_panelSeekSlider setMaxValue:[_movie duration]];
    [_panelSeekSlider setIndexedDuration:0];
    [self setRangeRepeatRange:_lastPlayedMovieRepeatRange];
    
    [_reopenWithMenuItem setTitle:
        [NSString stringWithFormat:NSLocalizedString(@"Reopen With %@", nil),
        ([_movie class] == [MMovie_QuickTime class]) ? [MMovie_FFmpeg name] :
                                                       [MMovie_QuickTime name]]];
    _prevMovieTime = 0.0;
    [self updateUI];

    // update system activity periodically not to activate screen saver
    _updateSystemActivityTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
        target:self selector:@selector(updateSystemActivity:) userInfo:nil repeats:TRUE];

    // add to recent-menu
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[self movieURL]];
}

- (BOOL)openMovie:(NSURL*)movieURL movieClass:(Class)movieClass
         subtitle:(NSURL*)subtitleURL subtitleEncoding:(CFStringEncoding)subtitleEncoding
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // -[closeMovie] should be called after opening new-movie not to display black screen.
    if (!movieURL) {
        if (_movie) {
            [self closeMovie];
        }
        return FALSE;
    }

    // open movie
    NSError* error;
    MMovie* movie = [self movieFromURL:movieURL withMovieClass:movieClass error:&error];
    if (!movie || ![movie setOpenGLContext:[_movieView openGLContext]
                               pixelFormat:[_movieView pixelFormat] error:&error]) {
        if (_movie) {
            [self closeMovie];
        }
        if ([self isFullScreen]) {
            NSString* s = [movieURL isFileURL] ? [movieURL path] : [movieURL absoluteString];
            [_movieView setError:error info:[s lastPathComponent]];
        }
        else {
            runAlertPanelForOpenError(error, movieURL);
        }
        return FALSE;
    }
    if (_movie) {
        [self closeMovie];
    }
    assert(_movie == nil);
    _movie = [movie retain];

    // observe movie's notifications
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(movieIndexDurationChanged:)
               name:MMovieIndexedDurationNotification object:_movie];
    [nc addObserver:self selector:@selector(movieRateChanged:)
               name:MMovieRateChangeNotification object:_movie];
    [nc addObserver:self selector:@selector(movieCurrentTimeChanged:)
               name:MMovieCurrentTimeNotification object:_movie];
    [nc addObserver:self selector:@selector(movieEnded:)
               name:MMovieEndNotification object:_movie];

    // update movie
    [self autoenableAudioTracks];
    [_movie setVolume:[self preferredVolume:[_defaults floatForKey:MVolumeKey]]];
    [_movie setMuted:([_muteButton state] == NSOnState)];
    if (!_lastPlayedMovieURL || ![_lastPlayedMovieURL isEqualTo:movieURL]) {
        [_lastPlayedMovieURL release];
        _lastPlayedMovieURL = [movieURL retain];
    }
    else if (0 < _lastPlayedMovieTime) {
        [_movie gotoTime:_lastPlayedMovieTime];
    }
    
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
            [self autoenableSubtitles];
        }
    }

    [self updateUIForOpenedMovieAndSubtitleEncoding:subtitleEncoding];

    [_movie setRate:_playRate];  // auto play

    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark public interface

- (BOOL)openFile:(NSString*)filename
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [self openFiles:[NSArray arrayWithObject:filename]];
}

- (BOOL)openFiles:(NSArray*)filenames
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    int option = [_defaults boolForKey:MAutodetectMovieSeriesKey] ?
                                                    OPTION_SERIES : OPTION_ONLY;
    return [self openFiles:filenames option:option];
}

- (BOOL)openURL:(NSURL*)url
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSString* s = @"\"Open URL...\" is not implemented yet.";
    NSRunAlertPanel([NSApp localizedAppName], s,
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
    else {
        [_playlist removeAllItems];
        [_playlist addURL:url];
        [_playlistController updateUI];
        return (0 < [_playlist count]) ? [self openCurrentPlaylistItem] : FALSE;
    }
     */
}

- (BOOL)openFile:(NSString*)filename option:(int)option
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return [self openFiles:[NSArray arrayWithObject:filename] option:option];
}

- (BOOL)openFiles:(NSArray*)filenames option:(int)option
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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
    else {
        [_playlist removeAllItems];
        if ([filenames count] == 1) {
            [_playlist addFile:[filenames objectAtIndex:0] option:option];
        }
        else {
            [_playlist addFiles:filenames];
        }
        [_playlistController updateUI];
        return (0 < [_playlist count]) ? [self openCurrentPlaylistItem] : FALSE;
    }
}

- (BOOL)openSubtitle:(NSURL*)subtitleURL encoding:(CFStringEncoding)encoding
{
    NSError* error;
    NSArray* subtitles = [self subtitleFromURL:subtitleURL withEncoding:encoding error:&error];
    if (!subtitles) {
        runAlertPanelForOpenError(error, subtitleURL);
        [self setSubtitlePosition:[_defaults integerForKey:MSubtitlePositionKey]];
        return FALSE;
    }

    [_subtitles release];
    _subtitles = [subtitles retain];

    [[_playlist currentItem] setSubtitleURL:subtitleURL];
    if (0 < [_subtitles count]) {   // select first language by default
        [_movieView setSubtitles:[NSArray arrayWithObject:[_subtitles objectAtIndex:0]]];
    }
    else {
        [_movieView setSubtitles:nil];
    }

    [self autoenableSubtitles];
    [self updateSubtitleLanguageMenuItems];
    [self setSubtitlePosition:[_defaults integerForKey:MSubtitlePositionKey]];

    [_movie gotoBeginning];

    if (encoding == kCFStringEncodingInvalidId) {
        encoding = [_defaults integerForKey:MSubtitleEncodingKey];
    }
    NSString* subtitleInfo = NSStringFromSubtitleEncoding(encoding);
    if (_subtitles && [_subtitles count] == 0) {
        subtitleInfo = NSLocalizedString(@"No Subtitle: Reopen with other encodings", nil);
    }
    [_movieView setMessageWithMovieURL:nil movieInfo:nil
                           subtitleURL:subtitleURL subtitleInfo:subtitleInfo];

    return TRUE;
}

- (BOOL)reopenMovieWithMovieClass:(Class)movieClass
{
    //TRACE(@"%s:%@", __PRETTY_FUNCTION__, movieClass);
    [self closeMovie];

    // to play at the beginning
    [_lastPlayedMovieURL release];
    _lastPlayedMovieURL = nil;

    PlaylistItem* item = [_playlist currentItem];
    return [self openMovie:[item movieURL] movieClass:movieClass
                  subtitle:[item subtitleURL] subtitleEncoding:kCFStringEncodingInvalidId];
}

- (void)reopenSubtitle
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [self openSubtitle:[[_playlist currentItem] subtitleURL]
                  encoding:kCFStringEncodingInvalidId];
    }
}

- (void)closeMovie
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        [_updateSystemActivityTimer invalidate];

        if (_disablePerianSubtitle) {
            // re-enable perian-subtitle after using quick-time if needed.
            if ([MMovie_QuickTime class] == [_movie class] && _perianSubtitleEnabled) {
                [_defaults setPerianSubtitleEnabled:TRUE];
            }
        }
        _lastPlayedMovieTime = ([_movie currentTime] < [_movie duration]) ?
                                [_movie currentTime] : 0.0;
        _lastPlayedMovieRepeatRange = [_seekSlider repeatRange];

        // init _audioTrackIndexSet for next open.
        [_audioTrackIndexSet removeAllIndexes];
        NSArray* audioTracks = [_movie audioTracks];
        int i, count = [audioTracks count];
        for (i = 0; i < count; i++) {
            if ([[audioTracks objectAtIndex:i] isEnabled]) {
                [_audioTrackIndexSet addIndex:i];
            }
        }

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
        [_movieView setMessage:@""];
        [_movie cleanup], _movie = nil;

        [_subtitles release], _subtitles = nil;
        [_reopenWithMenuItem setTitle:[NSString stringWithFormat:
            NSLocalizedString(@"Reopen With %@", nil), @"..."]];
        [self updateUI];
    }
}

- (void)updateDecoderUI
{
    NSString* decoder;
    BOOL enable;
    if ([_movieView movie]) {
        decoder = [[[_movieView movie] class] name];
        enable = TRUE;
    }
    else {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        decoder = ([defaults integerForKey:MDefaultDecoderKey] == DECODER_QUICKTIME) ?
                                        [MMovie_QuickTime name] : [MMovie_FFmpeg name];
        enable = FALSE;
    }

    if ([decoder isEqualToString:[MMovie_QuickTime name]]) {
        [_decoderButton setImage:[NSImage imageNamed:@"MainQuickTime"]];
        [_panelDecoderButton setImage:[NSImage imageNamed:@"FSQuickTime"]];
        [_controlPanelDecoderButton setImage:(enable) ? [NSImage imageNamed:@"QuickTime16"] : nil];
    }
    else {  // [decoder isEqualToString:[MMovie_FFmpeg name]]
        [_decoderButton setImage:[NSImage imageNamed:@"MainFFMPEG"]];
        [_panelDecoderButton setImage:[NSImage imageNamed:@"FSFFMPEG"]];
        [_controlPanelDecoderButton setImage:(enable) ? [NSImage imageNamed:@"FFMPEG16"] : nil];
    }
    [_decoderButton setEnabled:enable];
    [_panelDecoderButton setEnabled:enable];
    [_controlPanelDecoderButton setEnabled:enable];
}

- (void)updateSystemActivity:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isFullScreen] ||  // always deactivate in full-screen
        [_defaults boolForKey:MDeactivateScreenSaverKey]) {
        UpdateSystemActivity(UsrActivity);
    }
    if ([self isFullScreen]) {
        [_fullScreener autoHidePlayPanel];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IB actions

- (IBAction)openFileAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:TRUE];
    [panel setCanChooseDirectories:TRUE];
    [panel setAllowsMultipleSelection:FALSE];
    if (NSOKButton == [panel runModalForTypes:[MMovie movieTypes]]) {
        [self openFile:[panel filename]];
    }
}

- (IBAction)openURLAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // FIXME : not implemented yet
    [self openURL:nil];
}

- (IBAction)openSubtitleFileAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:TRUE];
    [panel setCanChooseDirectories:FALSE];
    [panel setAllowsMultipleSelection:FALSE];
    if (NSOKButton == [panel runModalForTypes:[MSubtitle subtitleTypes]]) {
        [self openSubtitle:[NSURL fileURLWithPath:[panel filename]]
                  encoding:kCFStringEncodingInvalidId];
    }
}

- (IBAction)reopenMovieAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        if ([_movie isMemberOfClass:[MMovie_FFmpeg class]]) {
            [self reopenMovieWithMovieClass:[MMovie_QuickTime class]];
        }
        else {
            [self reopenMovieWithMovieClass:[MMovie_FFmpeg class]];
        }
    }
}

- (IBAction)reopenSubtitleAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
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
        if (videoIndex < videoCount) {
            // at least, one video track should be enabled.
            int i;
            NSArray* tracks = [_movie videoTracks];
            for (i = 0; i < videoCount; i++) {
                if (i != videoIndex && [[tracks objectAtIndex:i] isEnabled]) {
                    break;
                }
            }
            [[tableColumn dataCellForRow:rowIndex] setEnabled:i < videoCount];
            BOOL state = [[tracks objectAtIndex:videoIndex] isEnabled];
            return [NSNumber numberWithBool:state];
        }
        else {
            [[tableColumn dataCellForRow:rowIndex] setEnabled:TRUE];
            if (audioIndex < audioCount) {
                BOOL state = [[[_movie audioTracks] objectAtIndex:audioIndex] isEnabled];
                return [NSNumber numberWithBool:state];
            }
            else {
                BOOL state = [[_subtitles objectAtIndex:subtitleIndex] isEnabled];
                return [NSNumber numberWithBool:state];
            }
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
            BOOL enabled = [(NSNumber*)object boolValue];
            [self setVideoTrackAtIndex:videoIndex enabled:enabled];
            [tableView reloadData];  // to update other video tracks availablity
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

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
    MMovieInfo movieInfo;
    if (![MMovie getMovieInfo:&movieInfo forMovieURL:movieURL error:error]) {
        if (movieClass && movieClass == [MMovie_FFmpeg class]) {
            return nil;
        }
        // continue by using QuickTime
        movieClass = [MMovie_QuickTime class];
    }

    NSArray* classes;
    if (movieClass) {
        // if movieClass is specified, then try it only
        classes = [NSArray arrayWithObject:movieClass];
    }
    else {
        // try all movie-classes with starting default-movie-class
        int codecId = [[movieInfo.videoTracks objectAtIndex:0] codecId];
        int decoder = [_defaults defaultDecoderForCodecId:codecId];
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

        BOOL digitalAudioOut = [self digitalAudioOut] && movieInfo.hasDigitalAudio;
        if (movieClass == [MMovie_QuickTime class]) {
            // remember original settings & update new settings
            if (_a52CodecInstalled) {
                _a52CodecAttemptPassthrough = [_defaults a52CodecAttemptPassthrough];
                [_defaults setA52CodecAttemptPassthrough:digitalAudioOut];
            }
            if (_perianInstalled) {
                _perianSubtitleEnabled = [_defaults isPerianSubtitleEnabled];
                if ([_defaults boolForKey:MDisablePerianSubtitleKey]) {
                    [_defaults setPerianSubtitleEnabled:FALSE];
                }
            }
        }

        movie = [[movieClass alloc] initWithURL:movieURL movieInfo:&movieInfo
                                digitalAudioOut:digitalAudioOut error:error];
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
    NSString* ext = [path pathExtension];
    Class parserClass = ([ext isEqualToString:@"smi"]) ? [MSubtitleParser_SMI class] :
                        ([ext isEqualToString:@"srt"]) ? [MSubtitleParser_SRT class] :
                        //([ext isEqualToString:@"idx"] ||
                        // [ext isEqualToString:@"sub"]) ? [MSubtitleParser_SUB class] :
                                                         Nil;
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

- (NSString*)subtitleInfoMessageString
{
    NSString* s = nil;
    if (_subtitles) {
        MSubtitle* subtitle;
        NSEnumerator* enumerator = [_subtitles objectEnumerator];
        while (subtitle = [enumerator nextObject]) {
            if ([subtitle isEnabled]) {
                s = (!s) ? [NSString stringWithString:[subtitle name]] :
                           [s stringByAppendingFormat:@", %@", [subtitle name]];
            }
        }
        if (!s) {
            s = NSLocalizedString(@"No Subtitle: Reopen with other encodings", nil);
        }
    }
    return s;
}

- (void)updateUIForOpenedMovieAndSubtitle
{
    NSSize ss = [[_mainWindow screen] frame].size;
    NSSize ms = [_movie adjustedSizeByAspectRatio];
    [_movieView setFullScreenFill:(ss.width / ss.height < ms.width / ms.height) ?
                        [_defaults integerForKey:MFullScreenFillForWideMovieKey] :
                        [_defaults integerForKey:MFullScreenFillForStdMovieKey]];
    [_movieView hideLogo];
    [_movieView setMovie:_movie];
    [_movieView setSubtitlePosition:[_defaults integerForKey:MSubtitlePositionKey]];
    [_movieView updateMovieRect:TRUE];

    int mode = [_defaults integerForKey:MSubtitleInfoDisplayOnOpeningKey];
    if (mode == SUBTITLE_INFO_DISPLAY_NONE || ![self subtitleURL]) {
        [_movieView setMessageWithMovieURL:[self movieURL] movieInfo:[[_movie class] name]
                               subtitleURL:nil subtitleInfo:nil];
    }
    else if (mode == SUBTITLE_INFO_DISPLAY_SIMPLE) {
        NSString* info = [NSString stringWithFormat:@"%@, %@",
                          [[_movie class] name], [self subtitleInfoMessageString]];
        [_movieView setMessageWithMovieURL:[self movieURL] movieInfo:info
                               subtitleURL:nil subtitleInfo:nil];
    }
    else if (mode == SUBTITLE_INFO_DISPLAY_FULL) {
        [_movieView setMessageWithMovieURL:[self movieURL] movieInfo:[[_movie class] name]
                               subtitleURL:[self subtitleURL]
                              subtitleInfo:[self subtitleInfoMessageString]];
    }

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
    [_controlPanelButton updateHoverImage];
    [_prevMovieButton updateHoverImage];
    [_nextMovieButton updateHoverImage];
    [_playlistButton updateHoverImage];
    [self updateDataSizeBpsUI];
    [self setRangeRepeatRange:_lastPlayedMovieRepeatRange];
    
    [_reopenWithMenuItem setTitle:[NSString stringWithFormat:
            NSLocalizedString(@"Reopen With %@", nil), [[_movie class] name]]];
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
    [nc addObserver:self selector:@selector(playlistUpdated:)
               name:MPlaylistUpdatedNotification object:_playlist];

    // update movie
    [self updateDigitalAudioOut:self];
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

    [self updateUIForOpenedMovieAndSubtitle];

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
        [[filenames objectAtIndex:0] hasAnyExtension:[MSubtitle fileExtensions]]) {
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

    [_movieView setMessageWithMovieURL:nil movieInfo:nil
                           subtitleURL:subtitleURL
                          subtitleInfo:[self subtitleInfoMessageString]];

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

        if ([_movie isMemberOfClass:[MMovie_QuickTime class]]) {
            // restore original settings
            if (_a52CodecInstalled) {
                [_defaults setA52CodecAttemptPassthrough:_a52CodecAttemptPassthrough];
            }
            if (_perianInstalled) {
                [_defaults setPerianSubtitleEnabled:_perianSubtitleEnabled];
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

        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:nil object:_movie];
        [nc removeObserver:self name:nil object:_playlist];

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
    NSImage* mainImage = nil;
    NSImage* panelImage = nil;
    if ([_movieView movie]) {
        NSString* decoder = [[[_movieView movie] class] name];
        if ([decoder isEqualToString:[MMovie_QuickTime name]]) {
            mainImage  = [NSImage imageNamed:@"MainQuickTime"];
            panelImage = [NSImage imageNamed:@"FSQuickTime"];
        }
        else {  // [decoder isEqualToString:[MMovie_FFmpeg name]]
            mainImage  = [NSImage imageNamed:@"MainFFMPEG"];
            panelImage = [NSImage imageNamed:@"FSFFMPEG"];
        }
    }

    [_decoderButton setImage:mainImage];
    [_panelDecoderButton setImage:panelImage];
    [_controlPanelDecoderButton setImage:panelImage];

    [_decoderButton setEnabled:(mainImage != nil)];
    [_panelDecoderButton setEnabled:(panelImage != nil)];
    [_controlPanelDecoderButton setEnabled:(panelImage != nil)];
}

- (void)updateDataSizeBpsUI
{
    NSString* s = @"";
    if (_movie) {
        float megaBytes = [_movie fileSize] / 1024. / 1024.;
        if (megaBytes < 1024) {
            s = [NSString stringWithFormat:@"%.2f MB", megaBytes];
        }
        else {
            s = [NSString stringWithFormat:@"%.2f GB", megaBytes / 1024.];
        }
        if (0 < [_movie bitRate]) {
            s = [s stringByAppendingFormat:@",  %d kbps", [_movie bitRate] / 1000];
        }
    }
    [_dataSizeBpsTextField setStringValue:s];
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
    if (NSOKButton == [panel runModalForTypes:[MMovie fileExtensions]]) {
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
    if (NSOKButton == [panel runModalForTypes:[MSubtitle fileExtensions]]) {
        [self openSubtitle:[NSURL fileURLWithPath:[panel filename]]
                  encoding:kCFStringEncodingInvalidId];
    }
}

- (IBAction)reopenMovieAction:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_movie) {
        Class newClass = ([_movie isMemberOfClass:[MMovie_QuickTime class]]) ?
                                [MMovie_FFmpeg class] : [MMovie_QuickTime class];
        [self reopenMovieWithMovieClass:newClass];
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
    int vCount = [[_movie videoTracks] count];
    int aCount = [[_movie audioTracks] count];
    int vIndex = rowIndex;
    int aIndex = vIndex - vCount;
    int sIndex = aIndex - aCount;

    NSString* identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"enable"]) {
        if (vIndex < vCount) {
            // at least, one video track should be enabled.
            int i, count = 0;
            NSArray* tracks = [_movie videoTracks];
            for (i = 0; i < vCount; i++) {
                if (i != vIndex && [[tracks objectAtIndex:i] isEnabled]) {
                    count++;
                }
            }
            [[tableColumn dataCellForRow:rowIndex] setEnabled:0 < count];
            BOOL state = [[tracks objectAtIndex:vIndex] isEnabled];
            return [NSNumber numberWithBool:state];
        }
        else {
            [[tableColumn dataCellForRow:rowIndex] setEnabled:TRUE];
            if (aIndex < aCount) {
                BOOL state = [[[_movie audioTracks] objectAtIndex:aIndex] isEnabled];
                return [NSNumber numberWithBool:state];
            }
            else {
                BOOL state = [[_subtitles objectAtIndex:sIndex] isEnabled];
                return [NSNumber numberWithBool:state];
            }
        }
    }
    else if ([identifier isEqualToString:@"name"]) {
        if (vIndex < vCount) {
            return [[[_movie videoTracks] objectAtIndex:vIndex] name];
        }
        else if (aIndex < aCount) {
            return [[[_movie audioTracks] objectAtIndex:aIndex] name];
        }
        else {
            return [NSString stringWithFormat:
                    NSLocalizedString(@"External Subtitle %d", nil), sIndex + 1];
        }
    }
    else if ([identifier isEqualToString:@"codec"]) {
        if (vIndex < vCount) {
            return codecName([[[_movie videoTracks] objectAtIndex:vIndex] codecId]);
        }
        else if (aIndex < aCount) {
            return codecName([[[_movie audioTracks] objectAtIndex:aIndex] codecId]);
        }
        else {
            return [[_subtitles objectAtIndex:sIndex] type];
        }
    }
    else if ([identifier isEqualToString:@"format"]) {
        if (vIndex < vCount) {
            return [[[_movie videoTracks] objectAtIndex:vIndex] summary];
        }
        else if (aIndex < aCount) {
            return [[[_movie audioTracks] objectAtIndex:aIndex] summary];
        }
        else {
            return [[_subtitles objectAtIndex:sIndex] name];
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
        int vCount = [[_movie videoTracks] count];
        int aCount = [[_movie audioTracks] count];
        int vIndex = rowIndex;
        int aIndex = vIndex - vCount;
        int sIndex = aIndex - aCount;
        
        if (vIndex < vCount) {
            BOOL enabled = [(NSNumber*)object boolValue];
            [self setVideoTrackAtIndex:vIndex enabled:enabled];
            [tableView reloadData];  // to update other video tracks availablity
        }
        else if (aIndex < aCount) {
            BOOL enabled = [(NSNumber*)object boolValue];
            [self setAudioTrackAtIndex:aIndex enabled:enabled];
        }
        else {
            MSubtitle* subtitle = [_subtitles objectAtIndex:sIndex];
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

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

#import "FullNavView.h"

#import "AppController.h"
#import "UserDefaults.h"
#import "Playlist.h"
#import "MMovie.h"
#import "MMovieView.h"
#import "FullNavItems.h"
#import "FullNavListView.h"

@interface FullNavTitleView : NSView
{
    NSImage* _icon;
    NSString* _title;
}

- (void)setIcon:(NSImage*)icon title:(NSString*)title;

@end

@implementation FullNavTitleView

- (void)drawRect:(NSRect)rect
{
    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

    NSRect br = [self bounds];
    NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithCapacity:3];
    [attrs setObject:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]
              forKey:NSForegroundColorAttributeName];
    [attrs setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [attrs setObject:[NSFont boldSystemFontOfSize:60 * br.size.width / 640.0]
              forKey:NSFontAttributeName];

    NSRect tr;
    tr.size = [_title sizeWithAttributes:attrs];
    if (_icon) {
        const int ICON_SIZE = [self bounds].size.height;
        const int ICON_MARGIN = ICON_SIZE * 0.15;
        NSRect rc;
        rc.size.width = ICON_SIZE;
        rc.size.height= ICON_SIZE;
        float width = rc.size.width + ICON_MARGIN + tr.size.width;
        if (br.size.width < width) {
            tr.size.width -= width - br.size.width;
            width -= width - br.size.width;
        }
        rc.origin.x = br.origin.x + (br.size.width - width) / 2;
        rc.origin.y = br.origin.y + (br.size.height - rc.size.height) / 2;
        [_icon drawInRect:rc fromRect:NSZeroRect
                operation:NSCompositeSourceOver fraction:1.0];

        tr.origin.x = rc.origin.x + rc.size.width + ICON_MARGIN;
    }
    else {
        if (br.size.width < tr.size.width) {
            tr.size.width -= tr.size.width - br.size.width;
        }
        tr.origin.x = br.origin.x + (br.size.width - tr.size.width) / 2;
    }
    tr.origin.y = br.origin.y + (br.size.height - tr.size.height)/ 2;
    [_title drawInRect:tr withAttributes:attrs];

    //[[NSColor grayColor] set];
    //NSFrameRect([self bounds]);
}

- (void)setIcon:(NSImage*)icon title:(NSString*)title
{
    if (isSystemTiger()) {
        [icon setScalesWhenResized:TRUE];
        [icon setSize:NSMakeSize(128, 128)];
    }
    [icon retain], [_icon release], _icon = icon;
    [title retain], [_title release], _title = title;
    [self display];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@interface FullNavListContainerView : NSView
{
}

@end

@implementation FullNavListContainerView
/*
- (void)drawRect:(NSRect)rect
{
    [[NSColor greenColor] set];
    NSFrameRect([self bounds]);
}
*/
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark

@implementation FullNavView

#define SEL_BOX_HMARGIN     60
#define SEL_BOX_VMARGIN     16

- (id)initWithFrame:(NSRect)rect movieView:(MMovieView*)movieView
{
    if (self = [super initWithFrame:rect]) {
        _movieView = [movieView retain];

        float titleHeight   = (float)(int)(rect.size.height * 0.095);
        float gap           = (float)(int)(rect.size.height * 0.025);
        float listHeight    = (float)(int)(rect.size.height * 0.66);
        float BOTTOM_MARGIN = (float)(int)(rect.size.height * 0.115);
        float LEFT_MARGIN   = (float)(int)(rect.size.width  * 0.075);
        float RIGHT_MARGIN  = (float)(int)(rect.size.width  * 0.195);

        // list view & sel-box
        rect = [self bounds];
        rect.origin.x += LEFT_MARGIN;
        rect.size.width -= LEFT_MARGIN + RIGHT_MARGIN;
        rect.origin.y = BOTTOM_MARGIN;
        rect.size.height = listHeight;
        NSView* lcv = [[FullNavListContainerView alloc] initWithFrame:rect];
        _listView = [[FullNavListView alloc] initWithFrame:[lcv bounds]
                                                    window:[movieView window]];
        [lcv addSubview:_listView];
        [self addSubview:[lcv autorelease]];
        [self addSubview:[_listView createSelBox]];

        // title view
        rect.origin.y += listHeight + gap;
        rect.size.height = titleHeight;
        _titleView = [[FullNavTitleView alloc] initWithFrame:rect];
        [self addSubview:_titleView];

        // list array
        _listArray = [[NSMutableArray alloc] initWithCapacity:4];
        [self initListRoot];
    }
    return self;
}

- (void)dealloc
{
    [_movieView release];
    [_listArray release];
    [super dealloc];
}
/*
- (void)drawRect:(NSRect)rect
{
    [[NSColor grayColor] set];
    NSFrameRect([self bounds]);
}
*/
- (void)keyDown:(NSEvent*)event
{
    //TRACE(@"%s \"%@\" (modifierFlags=%u)", __PRETTY_FUNCTION__,
    //      [event characters], [event modifierFlags]);
    unichar key = [[event characters] characterAtIndex:0];
    //unsigned int modifierFlags = [event modifierFlags] &
    //    (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask | NSShiftKeyMask);
    NSDate* now = [NSDate date];
    switch (key) {
        case NSUpArrowFunctionKey :         // up arrow
        case NSDownArrowFunctionKey :       // down arrow
            if (!_lastUpDownKeyTime ||
                0.02 <= [now timeIntervalSinceDate:_lastUpDownKeyTime]) {
                if (key == NSUpArrowFunctionKey) {
                    [self selectUpper];
                }
                else {
                    [self selectLower];
                }
                _lastUpDownKeyTime = [now retain];
            }
            break;

        case ' ' :                          // space: toggle play/pause
        case NSCarriageReturnCharacter :    // return : toggle full-screen
        case NSEnterCharacter :             // enter (in keypad)
            [self openCurrent];
            break;

        case 27 :                           // ESC
        //case NSBackspaceCharacter :         // backsapce
            if (![self closeCurrent]) {
                [[NSApp delegate] endFullNavigation];
            }
            break;
    }
}

- (void)keyUp:(NSEvent*)event
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [event characters]);
    unichar key = [[event characters] characterAtIndex:0];
    switch (key) {
        case NSUpArrowFunctionKey :         // up arrow
        case NSDownArrowFunctionKey :       // down arrow
            [_lastUpDownKeyTime release];
            _lastUpDownKeyTime = nil;
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark list

- (void)initListRoot
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSFileManager* fileManager = [NSFileManager defaultManager];

    // default navigation path
    NSString* path = [[defaults stringForKey:MFullNavPathKey] stringByExpandingTildeInPath];
    if (!path || ![fileManager fileExistsAtPath:path]) {
        path = [@"~/Movies" stringByExpandingTildeInPath];
    }
    if ([defaults boolForKey:MFullNavShowiTunesMoviesKey] ||
        [defaults boolForKey:MFullNavShowiTunesTVShowsKey] ||
        [defaults boolForKey:MFullNavShowiTunesPodcastsKey]) {
        NSMutableArray* items = [NSMutableArray arrayWithCapacity:6];
        [items addObject:[[[FullNavDirectoryItem alloc]
                                            initWithPath:path name:nil] autorelease]];

        // iTunes Movies folder
        if ([defaults boolForKey:MFullNavShowiTunesMoviesKey]) {
            path = [@"~/Music/iTunes/iTunes Music/Movies" stringByExpandingTildeInPath];
            if ([fileManager fileExistsAtPath:path]) {
                NSString* name = NSLocalizedString(@"iTunes Movies", nil);
                [items addObject:[[[FullNavDirectoryItem alloc]
                                            initWithPath:path name:name] autorelease]];
            }
        }

        // iTunes TV shows folder
        if ([defaults boolForKey:MFullNavShowiTunesTVShowsKey]) {
            path = [@"~/Music/iTunes/iTunes Music/TV shows" stringByExpandingTildeInPath];
            if ([fileManager fileExistsAtPath:path]) {
                NSString* name = NSLocalizedString(@"iTunes TV Shows", nil);
                [items addObject:[[[FullNavDirectoryItem alloc]
                                   initWithPath:path name:name] autorelease]];
            }
        }

        // iTunes Podcast folder
        if ([defaults boolForKey:MFullNavShowiTunesPodcastsKey]) {
            path = [@"~/Music/iTunes/iTunes Music/Podcast" stringByExpandingTildeInPath];
            if ([fileManager fileExistsAtPath:path]) {
                NSString* name = NSLocalizedString(@"iTunes Video Podcast", nil);
                [items addObject:[[[FullNavDirectoryItem alloc]
                                            initWithPath:path name:name] autorelease]];
            }
        }
        [self addNavListWithParentItem:nil items:items];
    }
    else {
        FullNavDirectoryItem* dirItem =
            [[[FullNavDirectoryItem alloc] initWithPath:path name:nil] autorelease];
        [self addNavListWithParentItem:nil items:[dirItem subContents]];
    }
}

- (void)updateListUI
{
    FullNavList* list = [_listArray lastObject];
    FullNavItem* item = [list parentItem];
    NSImage* icon = nil;
    NSString* title = nil;
    if (!item) {
        icon = [NSImage imageNamed:@"Movist"];
        title = [NSApp localizedAppName];
    }
    else {
        if ([item isMemberOfClass:[FullNavDirectoryItem class]]) {
            NSString* path = [(FullNavDirectoryItem*)item path];
            icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        }
        title = [item name];
        NSRange r = [title rangeOfString:PATH_LINK_SYMBOL];
        if (r.location != NSNotFound) {
            title = [title substringToIndex:r.location];
        }
    }
    [_titleView setIcon:icon title:title];
    [_listView setNavList:list];
    [self showPreview];
}

- (void)addNavListWithParentItem:(FullNavItem*)parentItem items:(NSArray*)items
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_listArray addObject:[[FullNavList alloc] initWithParentItem:parentItem items:items]];
    [self updateListUI];
}

- (void)removeLastNavList
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self canCloseCurrent]) {    // cannot remove root list
        [_listArray removeLastObject];
        [self updateListUI];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark selection

- (void)selectUpper
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    FullNavList* list = (FullNavList*)[_listArray lastObject];
    if (0 < [list selectedIndex]) {
        [_listView resetItemNameScroll];
        [list selectUpper];
        [self showPreview];
        [_listView slideSelBox];
    }
}

- (void)selectLower
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    FullNavList* list = (FullNavList*)[_listArray lastObject];
    if ([list selectedIndex] < [list count] - 1) {
        [_listView resetItemNameScroll];
        [list selectLower];
        [self showPreview];
        [_listView slideSelBox];
    }
}

- (void)selectMovie:(NSURL*)movieURL
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    FullNavList* list = (FullNavList*)[_listArray lastObject];

    // assume movieURL is file URL.
    NSString* path = [movieURL path];
    FullNavFileItem* item;
    int i, count = [list count];
    for (i = 0; i < count; i++) {
        item = (FullNavFileItem*)[list itemAtIndex:i];
        if ([path isEqualToString:[item path]]) {
            break;
        }
    }
    if (i < count && i != [list selectedIndex]) {
        [_listView resetItemNameScroll];
        [list selectAtIndex:i];
        [self showPreview];
        [_listView slideSelBox];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark open & close

#define FADE_DURATION   0.25

- (void)openSubContents:(FullNavItem*)item
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSWindow* window = [self window];
    ScreenFader* fader = [ScreenFader screenFaderWithScreen:[window screen]];
    [fader fadeOut:FADE_DURATION];

    [self addNavListWithParentItem:item items:[item subContents]];

    [window flushWindow];
    [fader fadeIn:FADE_DURATION];
}

- (void)closeSubContents
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // exit from sub-contents
    NSWindow* window = [self window];
    ScreenFader* fader = [ScreenFader screenFaderWithScreen:[window screen]];
    [fader fadeOut:FADE_DURATION];

    [self hidePreview];
    [self removeLastNavList];

    [window flushWindow];
    [fader fadeIn:FADE_DURATION];
}

- (void)openCurrentMovie:(FullNavItem*)item
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSWindow* window = [self window];
    ScreenFader* fader = [ScreenFader screenFaderWithScreen:[window screen]];
    [fader fadeOut:FADE_DURATION];

    [_listView resetItemNameScroll];
    MMovie* movie = [_movieView movie];
    if (movie) {
        [_movieView setHidden:TRUE];
        [movie gotoBeginning];
    }
    else {
        [self hidePreview];
    }
    [self setHidden:TRUE];
    [_movieView hideLogo];

    [_movieView setFrame:[[window contentView] bounds]];
    [_movieView updateSubtitle];
    [_movieView setHidden:FALSE];

    [window makeFirstResponder:_movieView];
    [_movieView display];
    [window flushWindow];
    [fader fadeIn:FADE_DURATION];

    if (movie) {
        [movie setMuted:FALSE];
        [movie setRate:DEFAULT_PLAY_RATE];
    }
    else if ([item isMemberOfClass:[FullNavFileItem class]]) {
        [[NSApp delegate] openFile:[(FullNavFileItem*)item path]];
    }
    else if ([item isMemberOfClass:[FullNavURLItem class]]) {
        [[NSApp delegate] openURL:[(FullNavURLItem*)item URL]];
    }
}

- (void)closeCurrentMovie
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // exit from full-screen movie
    [[_movieView movie] setMuted:TRUE];
    [[_movieView movie] setRate:0.0];

    NSWindow* window = [self window];
    ScreenFader* fader = [ScreenFader screenFaderWithScreen:[window screen]];
    [fader fadeOut:FADE_DURATION];

    [self setHidden:FALSE];
    [_movieView setFrame:[self previewRect]];
    [[_movieView superview] display];   // for Tiger
    [_movieView updateSubtitle];
    [window makeFirstResponder:self];

    [window flushWindow];
    [fader fadeIn:FADE_DURATION];
    [_listView startItemNameScroll];
    [[_movieView movie] setRate:DEFAULT_PLAY_RATE];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL)canCloseCurrent { return (1 < [_listArray count]); }

- (void)openCurrent
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    FullNavItem* item = [(FullNavList*)[_listArray lastObject] selectedItem];
    if (item == nil) {
        // do nothing
    }
    else if ([item hasSubContents]) {
        [self openSubContents:item];
    }
    else {
        [self openCurrentMovie:item];
    }
}

- (BOOL)closeCurrent
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([self isHidden]) {
        [self closeCurrentMovie];
        return TRUE;
    }
    else if ([self canCloseCurrent]) {
        [self closeSubContents];
        return TRUE;
    }
    return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark preview

- (void)endPreviewTimer
{
    if (_previewTimer) {
        if ([_previewTimer isValid]) {
            [_previewTimer invalidate];
        }
        _previewTimer = nil;
    }
}

- (void)showPreview:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self endPreviewTimer];

    if ([self isHidden] || [_movieView window] != [self window]) {
        return; // if timer is expired after exiting navigation, then ignore it.
    }

    [_movieView setError:nil info:nil]; // clear previous error

    FullNavItem* item = [(FullNavList*)[_listArray lastObject] selectedItem];
    if (item == nil) {
        // do nothing
    }
    else if ([item hasSubContents]) {
        [self hidePreview];
    }
    else {
        if ([item isMemberOfClass:[FullNavFileItem class]]) {
            [[NSApp delegate] openFile:[(FullNavFileItem*)item path] option:OPTION_ALL];
        }
        else if ([item isMemberOfClass:[FullNavURLItem class]]) {
            [[NSApp delegate] openURL:[(FullNavURLItem*)item URL]];
        }
        [[_movieView window] disableScreenUpdatesUntilFlush];   // for Tiger
        [_movieView setFrame:[self previewRect]];
        [[_movieView superview] display];   // for Tiger
        [_movieView updateSubtitle];
        [_movieView setHidden:FALSE];
    }
}

- (void)showPreview
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self endPreviewTimer];    // release previous timer

    if (![self isHidden]) {
        _previewTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                    target:self selector:@selector(showPreview:)
                                    userInfo:nil repeats:FALSE];
    }
}

- (void)hidePreview
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![self isHidden] && ![_movieView isHidden]) {
        [[NSApp delegate] closeMovie];
        [_movieView setError:nil info:nil];
        [_movieView display];
        [_movieView setHidden:TRUE];
    }
}

- (NSRect)previewRect
{
    NSSize movieSize;
    MMovie* movie = [(AppController*)[NSApp delegate] movie];
    if (movie) {
        [movie setMuted:TRUE]; // always muted in preview
        movieSize = [movie displaySize];
    }
    else {
        movieSize = NSMakeSize(640, 360);
    }
    NSRect rc = [[_movieView superview] bounds];
    rc.size.width /= 2;

    float IN_MARGIN  = (float)(int)(rc.size.width * 0.075);
    float OUT_MARGIN = (float)(int)(rc.size.width * 0.195);
    rc.origin.x += OUT_MARGIN, rc.size.width -= OUT_MARGIN + IN_MARGIN;
    float height = rc.size.width * movieSize.height / movieSize.width;
    rc.origin.y += (rc.size.height - height) / 2, rc.size.height = height;
    return rc;
}

@end

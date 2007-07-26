//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "PlaylistCell.h"

#import "Playlist.h"

@implementation PlaylistMovieCell

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_playlistItem release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    PlaylistMovieCell* cell = [[PlaylistMovieCell alloc] init];
    [cell setPlaylistItem:_playlistItem];
    return cell;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setPlaylistItem:(PlaylistItem*)item
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, item);
    [item retain], [_playlistItem release], _playlistItem = item;
}

- (id)objectValue { return _playlistItem; }

- (void)setObjectValue:(id<NSCopying>)object
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, object);
    [_playlistItem release];
    _playlistItem = [(PlaylistItem*)object copy];
    [(NSControl*)[self controlView] updateCell:self];
}

- (void)drawIcon:(NSImage*)icon inRect:(NSRect)rect
{
    //TRACE(@"%s %@ in %@", __PRETTY_FUNCTION__, icon, NSStringFromRect(rect));
    rect.origin.x += (rect.size.width - 16) / 2;
    rect.origin.y += (rect.size.height- 16) / 2;
    rect.size.width = 16;
    rect.size.height= 16;
    [icon setFlipped:TRUE];
    [icon drawInRect:rect fromRect:NSZeroRect
           operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawString:(NSString*)s subtitle:(BOOL)subtitle inRect:(NSRect)rect
{
    //TRACE(@"%s %@ in %@", __PRETTY_FUNCTION__, s, NSStringFromRect(rect));
    NSColor* textColor;
    if (subtitle) {
        if ([NSApp isActive] && [self isHighlighted]) {
            textColor = [NSColor controlHighlightColor];
        }
        else {
            textColor = [NSColor disabledControlTextColor];
        }
    }
    else if ([NSApp isActive] && [self isHighlighted]) {
        textColor = [NSColor controlHighlightColor];
    }
    else {
        textColor = [NSColor controlTextColor];
    }

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [paragraphStyle autorelease];

    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                textColor, NSForegroundColorAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName,
                                nil];
    [s drawInRect:rect withAttributes:attrs];
}

- (void)drawURL:(NSURL*)url subtitle:(BOOL)subtitle inRect:(NSRect)rect
{
    //TRACE(@"%s %@ in %@", __PRETTY_FUNCTION__, [url absoluteString], NSStringFromRect(rect));
    if (!url && subtitle) {
        // no icon
        rect.origin.x   += 20;
        rect.size.width -= 20;
        NSString* s = NSLocalizedString(@"no subtitle", nil);
        [self drawString:s subtitle:TRUE inRect:rect];
    }
    else {
        NSImage* icon;
        NSString* s;
        if ([url isFileURL]) {
            icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
            s = [[url path] lastPathComponent];
        }
        else {
            icon = nil;
            s = [url absoluteString];
        }
        rect.origin.x   += 20;
        rect.size.width -= 20;
        [self drawString:s subtitle:subtitle inRect:rect];

        rect.origin.x   -= 20;
        rect.size.width  = 20;
        [self drawIcon:icon inRect:rect];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(cellFrame));
    NSRect rect = cellFrame;
    rect.size.height /= 2;
    [self drawURL:[_playlistItem movieURL] subtitle:FALSE inRect:rect];

    rect.origin.y += rect.size.height;
    [self drawURL:[_playlistItem subtitleURL] subtitle:TRUE inRect:rect];
}

@end

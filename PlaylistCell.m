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
    PlaylistMovieCell* cell = [super copyWithZone:zone];
    cell->_playlistItem = [_playlistItem retain];
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

- (void)drawString:(NSString*)s inRect:(NSRect)rect isSubtitle:(BOOL)isSubtitle
{
    //TRACE(@"%s %@ in %@", __PRETTY_FUNCTION__, s, NSStringFromRect(rect));
    NSColor* textColor;
    if (isSubtitle) {
        if ([NSApp isActive] && [self isHighlighted]) {
            textColor = [NSColor controlHighlightColor];
        }
        else {
            textColor = [NSColor disabledControlTextColor];
        }
    }
    else if ([NSApp isActive]) {
        if ([self isHighlighted]) {
            textColor = [NSColor controlHighlightColor];
        }
        else {
            textColor = HUDButtonTextColor;
        }
    }
    else {
        if ([self isHighlighted]) {
            textColor = [NSColor controlTextColor];
        }
        else {
            textColor = HUDButtonTextColor;
        }
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

- (void)drawMovieURL:(NSURL*)url inRect:(NSRect)rect
{
    //TRACE(@"%s %@ in %@", __PRETTY_FUNCTION__, [url absoluteString], NSStringFromRect(rect));
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
    [self drawString:s inRect:rect isSubtitle:FALSE];

    rect.origin.x   -= 20;
    rect.size.width  = 20;
    [self drawIcon:icon inRect:rect];
}

- (void)drawSubtitleURLs:(NSArray*)urls inRect:(NSRect)rect
{
    //TRACE(@"%s %@ in %@", __PRETTY_FUNCTION__, [url absoluteString], NSStringFromRect(rect));
    rect.origin.x   += 20;
    rect.size.width -= 20;

    if ([urls count] == 0) {
        NSString* s = NSLocalizedString(@"No Subtitle", nil);
        [self drawString:s inRect:rect isSubtitle:TRUE];
    }
    else {
        rect.size.height /= [urls count];
        NSRect iconRect = rect;
        iconRect.origin.x -= 20;
        iconRect.size.width = 20;

        NSURL* url;
        NSImage* icon;
        NSString* s;
        NSEnumerator* enumerator = [urls objectEnumerator];
        while (url = [enumerator nextObject]) {
            if ([url isFileURL]) {
                icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
                s = [[url path] lastPathComponent];
            }
            else {
                icon = nil;
                s = [url absoluteString];
            }
            [self drawString:s inRect:rect isSubtitle:TRUE];
            [self drawIcon:icon inRect:iconRect];
            
            rect.origin.y += rect.size.height;
            iconRect.origin.y += iconRect.size.height;
        }
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(cellFrame));
    if ([self isHighlighted]) {
        [[controlView _highlightColorForCell:self] set];
        NSRectFill(cellFrame);
    }

    NSArray* subtitleURLs = [_playlistItem subtitleURLs];
    int lines = 1 + (([subtitleURLs count] <= 1) ? 1 : [subtitleURLs count]);
    float lineHeight = cellFrame.size.height / lines;

    NSRect rect = cellFrame;
    rect.size.height = lineHeight;
    [self drawMovieURL:[_playlistItem movieURL] inRect:rect];

    rect.origin.y += lineHeight;
    rect.size.height = cellFrame.size.height - lineHeight;
    [self drawSubtitleURLs:subtitleURLs inRect:rect];
}

@end

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
        NSString* s = NSLocalizedString(@"No Subtitle", nil);
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

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

#import "PlaylistPanel.h"

@implementation PlaylistPanel
/*
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(unsigned int)styleMask
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super initWithContentRect:contentRect
                                styleMask:NSTitledWindowMask//NSBorderlessWindowMask
                                  backing:bufferingType
                                    defer:deferCreation]) {
        [self initHUDWindow];
        [self setFloatingPanel:TRUE];
    }
    return self;
}
*/
- (void)awakeFromNib
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self initHUDWindow];
    [self updateHUDBackground];
    [self initHUDSubviews];
    //[self setFloatingPanel:TRUE];

    _initialDragPoint.x = -1;
    _initialDragPoint.y = -1;
}

- (void)dealloc
{
    [self cleanupHUDWindow];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark window-moving by dragging

- (void)mouseDown:(NSEvent*)event
{
    if (![self isSheet]) {
        NSRect frame = [self frame];
        _initialDragPoint = [self convertBaseToScreen:[event locationInWindow]];
        _initialDragPoint.x -= frame.origin.x;
        _initialDragPoint.y -= frame.origin.y;
    }
}

- (void)mouseUp:(NSEvent*)event
{
    if (![self isSheet]) {
        _initialDragPoint.x = -1;
        _initialDragPoint.y = -1;
    }
}

- (void)mouseDragged:(NSEvent*)event
{
    if (![self isSheet] &&
        0 <= _initialDragPoint.x && 0 <= _initialDragPoint.y) {
        NSPoint p = [self convertBaseToScreen:[event locationInWindow]];
        NSRect sr = [[self screen] frame];
        NSRect wr = [self frame];
        
        NSPoint origin;
        origin.x = p.x - _initialDragPoint.x;
        origin.y = p.y - _initialDragPoint.y;
        if (NSMaxY(sr) < origin.y + wr.size.height) {
            origin.y = sr.origin.y + (sr.size.height - wr.size.height);
        }
        [self setFrameOrigin:origin];
    }
}

@end

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

#import "MMovieView.h"

#import "MTextOSD.h"
#import "MImageOSD.h"
#import "SubtitleRenderer.h"
#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView (OSD)

- (BOOL)initOSD
{
    _subtitleRenderer = [[SubtitleRenderer alloc] initWithMovieView:self];

    NSRect rect = [self bounds];
    _subtitleImageOSD = [[MTextImageOSD alloc] init];
    [_subtitleImageOSD setMovieRect:rect];
    [_subtitleImageOSD setHAlign:OSD_HALIGN_CENTER];
    [_subtitleImageOSD setVAlign:OSD_VALIGN_LOWER_FROM_MOVIE_BOTTOM];
    _subtitleVisible = TRUE;
    _autoSubtitlePositionMaxLines = 3;
    _subtitlePosition = SUBTITLE_POSITION_AUTO; // for initial update

    _messageOSD = [[MTextOSD alloc] init];
    [_messageOSD setMovieRect:rect];
    [_messageOSD setHAlign:OSD_HALIGN_LEFT];
    [_messageOSD setVAlign:OSD_VALIGN_UPPER_FROM_MOVIE_TOP];
    _messageHideInterval = 2.0;

    _errorOSD = [[MTextOSD alloc] init];
    [_errorOSD setMovieRect:rect];
    [_errorOSD setTextAlignment:NSCenterTextAlignment];
    [_errorOSD setHAlign:OSD_HALIGN_CENTER];
    [_errorOSD setVAlign:OSD_VALIGN_CENTER];

    _iconOSD = [[MImageOSD alloc] init];
    [_iconOSD setMovieRect:rect];
    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];
    [_iconOSD setHAlign:OSD_HALIGN_CENTER];
    [_iconOSD setVAlign:OSD_VALIGN_CENTER];
    return TRUE;
}

- (void)cleanupOSD
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_iconOSD release];
    [_errorOSD release];
    [_messageOSD release];
    [_subtitleImageOSD release];
    [_subtitleRenderer release];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)drawOSD
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    // set OpenGL states
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    NSRect frame = [self frame];
    glScalef(2.0f / frame.size.width, -2.0f / frame.size.height, 1.0f);
    glTranslatef(-frame.size.width / 2.0f, -frame.size.height / 2.0f, 0.0f);

    NSRect bounds = [self bounds];
    if ([[NSApp delegate] isFullScreen] && 0 < _fullScreenUnderScan) {
        bounds = [self underScannedRect:bounds];
    }

    if ([_iconOSD hasContent]) {
        [_iconOSD drawInViewBounds:bounds];
    }
    if (_subtitleVisible && [_subtitleImageOSD hasContent]) {
        [_subtitleImageOSD drawInViewBounds:bounds];
    }
    if ([_messageOSD hasContent]) {
        [_messageOSD drawInViewBounds:bounds];
    }
    if ([_errorOSD hasContent]) {
        [_errorOSD drawInViewBounds:bounds];
    }

    // restore OpenGL status
    glPopMatrix(); // GL_MODELVIEW
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);

    glDisable(GL_TEXTURE_RECTANGLE_EXT);
    glDisable(GL_BLEND);
}

- (void)drawDragHighlight
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    NSRect rect = [self bounds];
    float x1 = NSMinX(rect), y1 = NSMinY(rect);
    float x2 = NSMaxX(rect), y2 = NSMaxY(rect);
    float w = 8.0;
    glColor4f(0.0, 0.0, 1.0, 0.25);
    glBegin(GL_QUADS);
        // bottom
        glVertex2f(x1, y1);         glVertex2f(x2,     y1);
        glVertex2f(x2, y1 + w);     glVertex2f(x1,     y1 + w);
        // right
        glVertex2f(x2 - w, y1 + w); glVertex2f(x2,     y1 + w);
        glVertex2f(x2,     y2 - w); glVertex2f(x2 - w, y2 - w);
        // top
        glVertex2f(x1, y2 - w);     glVertex2f(x2,     y2 - w);
        glVertex2f(x2, y2);         glVertex2f(x1,     y2);
        // left
        glVertex2f(x1,     y1 + w); glVertex2f(x1 + w, y1 + w);
        glVertex2f(x1 + w, y2 - w); glVertex2f(x1,     y2 - w);
    glEnd();
    glColor3f(1.0, 1.0, 1.0);

    glDisable(GL_BLEND);
}

- (void)clearOSD
{
    [_subtitleRenderer clearSubtitleContent];
    [_subtitleImageOSD clearContent];
    [_messageOSD clearContent];
    [_errorOSD clearContent];
}

- (void)showLogo
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self lockDraw];

    [_iconOSD setImage:[NSImage imageNamed:@"Movist"]];

    [self unlockDraw];
}

- (void)hideLogo
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self lockDraw];

    [_iconOSD clearContent];

    [self unlockDraw];
}

@end

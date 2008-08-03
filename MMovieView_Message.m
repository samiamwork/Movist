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

#import "MMovie.h"
#import "MMovieOSD.h"

@implementation MMovieView (Message)

- (void)setAttributedMessage:(NSAttributedString*)s
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [s string]);
    [_messageOSD setString:s];
    [self redisplay];

    [self invalidateMessageHideTimer];
    _messageHideTimer = [NSTimer scheduledTimerWithTimeInterval:_messageHideInterval
                         target:self selector:@selector(hideMessage:)
                         userInfo:nil repeats:FALSE];
}

- (void)setMessageWithURL:(NSURL*)url info:(NSString*)info
{
    //TRACE(@"%s \"%@\", \"%@\"", __PRETTY_FUNCTION__, [url path], info);
    NSString* s = ([url isFileURL]) ? [[url path] lastPathComponent] :
    [[url absoluteString] lastPathComponent];
    NSStringEncoding encoding = [NSString defaultCStringEncoding];
    const char* cString = [s cStringUsingEncoding:encoding];
    if (cString) {
        s = [NSString stringWithCString:cString encoding:encoding];
    }

    NSAttributedString* as;
    if (info) {
        NSString* msg = [NSString stringWithFormat:@"%@ (%@)", s, info];
        NSDictionary* attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:1.0],
            NSForegroundColorAttributeName, nil];
        NSMutableAttributedString* mas;
        as = mas = [[[NSMutableAttributedString alloc] initWithString:msg] autorelease];
        [mas setAttributes:attrs range:NSMakeRange([s length] + 1, 1 + [info length] + 1)];
        //[mas fixAttributesInRange:NSMakeRange(0, [mas length])];
    }
    else {
        as = [[[NSAttributedString alloc] initWithString:s] autorelease];
    }

    [self setAttributedMessage:as];
}

- (void)setMessage:(NSString*)s
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, s);
    [self setAttributedMessage:[[[NSAttributedString alloc] initWithString:s] autorelease]];
}

- (void)hideMessage:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _messageHideTimer = nil;

    [_messageOSD setString:[[NSAttributedString alloc] initWithString:@""]];
    [self redisplay];
}

- (void)invalidateMessageHideTimer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_messageHideTimer && [_messageHideTimer isValid]) {
        [_messageHideTimer invalidate];
        _messageHideTimer = nil;
    }
}

- (float)messageHideInterval { return _messageHideInterval; }

- (void)setMessageHideInterval:(float)interval
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, interval);
    _messageHideInterval = interval;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setError:(NSError*)error info:(NSString*)info
{
    //TRACE(@"%s \"%@\", \"%@\"", __PRETTY_FUNCTION__, s, info);
    if (error) {
        NSString* s = [NSString stringWithFormat:@"%@\n\n%@", error, info];
        [_errorOSD setString:[[[NSAttributedString alloc] initWithString:s] autorelease]];
    }
    else {
        [_errorOSD clearContent];
    }
    [self redisplay];
}

@end

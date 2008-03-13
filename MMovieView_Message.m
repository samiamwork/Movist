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

#import "MMovieView.h"

#import "MMovie.h"
#import "MTextOSD.h"

@implementation MMovieView (Message)

- (NSMutableAttributedString*)messageStringWithURL:(NSURL*)url info:(NSString*)info
{
    NSString* s = ([url isFileURL]) ? [[url path] lastPathComponent] :
                                      [[url absoluteString] lastPathComponent];
    NSStringEncoding encoding = [NSString defaultCStringEncoding];
    const char* cString = [s cStringUsingEncoding:encoding];
    if (cString) {
        s = [NSString stringWithCString:cString encoding:encoding];
    }

    NSMutableAttributedString* mas;
    if (info) {
        NSString* msg = [NSString stringWithFormat:@"%@ (%@)", s, info];
        NSDictionary* attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               [NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:1.0],
                               NSForegroundColorAttributeName, nil];
        mas = [[NSMutableAttributedString alloc] initWithString:msg];
        [mas setAttributes:attrs range:NSMakeRange([s length] + 1, 1 + [info length] + 1)];
        //[mas fixAttributesInRange:NSMakeRange(0, [mas length])];
    }
    else {
        mas = [[NSMutableAttributedString alloc] initWithString:s];
    }
    return [mas autorelease];
}

- (void)setMessageWithMovieURL:(NSURL*)movieURL movieInfo:(NSString*)movieInfo
                   subtitleURL:(NSURL*)subtitleURL subtitleInfo:(NSString*)subtitleInfo
{
    //TRACE(@"%s \"%@\", \"%@\"", __PRETTY_FUNCTION__, s, info);
    NSMutableAttributedString* mas = nil;
    if (movieURL) {
        mas = [self messageStringWithURL:movieURL info:movieInfo];
    }
    if (subtitleURL) {
        NSMutableAttributedString* s =
                [self messageStringWithURL:subtitleURL info:subtitleInfo];
        if (mas) {
            [mas appendAttributedString:[[[NSAttributedString alloc]
                                            initWithString:@"\n"] autorelease]];
            [mas appendAttributedString:s];
        }
        else {
            mas = s;
        }
    }

    [self setAttributedMessage:mas];
}

- (void)setMessage:(NSString*)s
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, s);
    [self setAttributedMessage:
     [[[NSMutableAttributedString alloc] initWithString:s] autorelease]];
}

- (void)setAttributedMessage:(NSMutableAttributedString*)s
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [s string]);
    [_messageOSD setString:s];
    [self redisplay];

    [self invalidateMessageHideTimer];
    _messageHideTimer = [NSTimer scheduledTimerWithTimeInterval:_messageHideInterval
                                        target:self selector:@selector(hideMessage:)
                                        userInfo:nil repeats:FALSE];
}

- (void)hideMessage:(NSTimer*)timer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    _messageHideTimer = nil;

    [_messageOSD setString:[[NSMutableAttributedString alloc] initWithString:@""]];
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
        NSMutableAttributedString* mas = [[NSMutableAttributedString alloc] initWithString:s];
        [_errorOSD setString:[mas autorelease]];
    }
    else {
        [_errorOSD clearContent];
    }
    [self redisplay];
}

@end

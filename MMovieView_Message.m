//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovieView.h"

#import "MMovie.h"
#import "MTextOSD.h"
#import "MBarOSD.h"

@implementation MMovieView (Message)

- (void)setMessage:(NSString*)s
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, s);
    [self setMessage:s info:nil];
}

- (void)setMessage:(NSString*)s info:(NSString*)info
{
    //TRACE(@"%s \"%@\", \"%@\"", __PRETTY_FUNCTION__, s, info);
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
    [self setAttributedMessage:[mas autorelease]];
}

- (void)setAttributedMessage:(NSMutableAttributedString*)s
{
    TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [s string]);
    [_messageOSD setString:s];
    [self setNeedsDisplay:TRUE];

    [self invalidateMessageHideTimer];
    _messageHideTimer = [NSTimer scheduledTimerWithTimeInterval:_messageHideInterval
                                        target:self selector:@selector(hideMessage:)
                                        userInfo:nil repeats:FALSE];
}

- (void)hideMessage:(NSTimer*)timer
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _messageHideTimer = nil;

    [_messageOSD setString:[[NSMutableAttributedString alloc] initWithString:@""]];
    [self setNeedsDisplay:TRUE];
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
    TRACE(@"%s %g", __PRETTY_FUNCTION__, interval);
    _messageHideInterval = interval;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)showBar:(int)type value:(float)value
       minValue:(float)minValue maxValue:(float)maxValue
{
    [_barOSD setType:type value:value minValue:minValue maxValue:maxValue];
    [self setNeedsDisplay:TRUE];

    [self invalidateBarHideTimer];
    _barHideTimer = [NSTimer scheduledTimerWithTimeInterval:_barHideInterval
                                        target:self selector:@selector(hideBar:)
                                        userInfo:nil repeats:FALSE];
}

- (void)showVolumeBar
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self showBar:VOLUME_BAR value:[_movie volume] minValue:0.0 maxValue:MAX_VOLUME];
}

- (void)showSeekBar
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self showBar:SEEK_BAR value:[_movie currentTime] minValue:0.0 maxValue:[_movie duration]];
}

- (void)hideBar
{
    [self invalidateBarHideTimer];
    [_barOSD clearContent];
    [self setNeedsDisplay:TRUE];
}

- (void)hideBar:(NSTimer*)timer
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _barHideTimer = nil;
    
    [_barOSD clearContent];
    [self setNeedsDisplay:TRUE];
}

- (void)invalidateBarHideTimer
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_barHideTimer && [_barHideTimer isValid]) {
        [_barHideTimer invalidate];
        _barHideTimer = nil;
    }
}

@end

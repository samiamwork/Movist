//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovieView.h"

#import "MMovie.h"
#import "MSubtitle.h"
#import "MSubtitleOSD.h"

@implementation MMovieView (Subtitle)

- (NSArray*)subtitles { return _subtitles; }

- (void)setSubtitles:(NSArray*)subtitles
{
    TRACE(@"%s %@", __PRETTY_FUNCTION__, subtitles);
    [_drawLock lock];
    [subtitles retain], [_subtitles release], _subtitles = subtitles;
    [_subtitleOSD clearContent];
    
    MSubtitle* subtitle;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        [subtitle clearCache];
    }
    [self updateSubtitleString];
    [_drawLock unlock];
    [self setNeedsDisplay:TRUE];
}

- (void)updateSubtitleString
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    MSubtitle* subtitle;
    NSMutableAttributedString* s;
    float currentTime = [_movie currentTime] + _subtitleSync;
    NSEnumerator* enumerator = [_subtitles objectEnumerator];
    while (subtitle = [enumerator nextObject]) {
        s = [subtitle nextString:currentTime];
        if (s) {
            [_subtitleOSD setString:s forName:[subtitle name]];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark visibility

- (BOOL)subtitleVisible { return _subtitleVisible; }

- (void)setSubtitleVisible:(BOOL)visible
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleVisible = visible;
    [self setNeedsDisplay:TRUE];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle font & attributes

- (NSString*)subtitleFontName { return [_subtitleOSD fontName]; }
- (float)subtitleFontSize { return [_subtitleOSD fontSize]; }

- (void)setSubtitleFontName:(NSString*)fontName size:(float)size
{
    TRACE(@"%s \"%@\" %g", __PRETTY_FUNCTION__, fontName, size);
    [_messageOSD setFontName:fontName size:15.0];
    [_subtitleOSD setFontName:fontName size:size];
    [self setNeedsDisplay:TRUE];
}

- (void)setSubtitleTextColor:(NSColor*)textColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setTextColor:textColor];
    [_subtitleOSD setTextColor:textColor];
    [self setNeedsDisplay:TRUE];
}

- (void)setSubtitleStrokeColor:(NSColor*)strokeColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setStrokeColor:strokeColor];
    [_subtitleOSD setStrokeColor:strokeColor];
    [self setNeedsDisplay:TRUE];
}

- (void)setSubtitleStrokeWidth:(float)strokeWidth
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setStrokeWidth:strokeWidth];
    [_subtitleOSD setStrokeWidth:strokeWidth];
    [self setNeedsDisplay:TRUE];
}

- (void)setSubtitleShadowColor:(NSColor*)shadowColor
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setShadowColor:shadowColor];
    [_subtitleOSD setShadowColor:shadowColor];
    [self setNeedsDisplay:TRUE];
}

- (void)setSubtitleShadowBlur:(float)shadowBlur
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setShadowBlur:shadowBlur];
    [_subtitleOSD setShadowBlur:shadowBlur];
    [self setNeedsDisplay:TRUE];
}

- (void)setSubtitleShadowOffset:(float)shadowOffset
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [_messageOSD setShadowOffset:shadowOffset];
    [_subtitleOSD setShadowOffset:shadowOffset];
    [self setNeedsDisplay:TRUE];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark subtitle attributes

- (BOOL)subtitleDisplayOnLetterBox { return [_subtitleOSD displayOnLetterBox]; }
- (float)minLetterBoxHeight { return _minLetterBoxHeight; }
- (float)subtitleHMargin { return [_subtitleOSD hMargin]; }
- (float)subtitleVMargin { return [_subtitleOSD vMargin]; }

- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (displayOnLetterBox != [self subtitleDisplayOnLetterBox]) {
        [_messageOSD setDisplayOnLetterBox:displayOnLetterBox];
        [_subtitleOSD setDisplayOnLetterBox:displayOnLetterBox];
        [self setNeedsDisplay:TRUE];
    }
}

- (void)setMinLetterBoxHeight:(float)height
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (_minLetterBoxHeight != height) {
        _minLetterBoxHeight = height;
        [self updateMovieRect:TRUE];
    }
}

- (void)revertLetterBoxHeight
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setMinLetterBoxHeight:0.0];
}

- (void)increaseLetterBoxHeight
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float letterBoxHeight = _movieRect.origin.y + 1.0;
    if (_movieRect.size.height + letterBoxHeight < [self frame].size.height) {
        [self setMinLetterBoxHeight:letterBoxHeight];
    }
}

- (void)decreaseLetterBoxHeight
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    float letterBoxHeight = _movieRect.origin.y - 1.0;
    if (([self frame].size.height - _movieRect.size.height) / 2 < letterBoxHeight) {
        [self setMinLetterBoxHeight:letterBoxHeight];
    }
}

- (void)setSubtitleHMargin:(float)hMargin
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (hMargin != [self subtitleHMargin]) {
        [_subtitleOSD setHMargin:hMargin];
        [_messageOSD setHMargin:hMargin];
        [self setNeedsDisplay:TRUE];
    }
}

- (void)setSubtitleVMargin:(float)vMargin
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    if (vMargin != [self subtitleVMargin]) {
        [_subtitleOSD setVMargin:vMargin];
        [_messageOSD setVMargin:vMargin];
        [self setNeedsDisplay:TRUE];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark sync

- (float)subtitleSync { return _subtitleSync; }

- (void)setSubtitleSync:(float)sync
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    _subtitleSync = sync;
    [self updateSubtitleString];
    [self setNeedsDisplay:TRUE];
}

- (void)revertSubtitleSync
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setSubtitleSync:0.0];
}

- (void)increaseSubtitleSync
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setSubtitleSync:_subtitleSync + 0.1];
}

- (void)decreaseSubtitleSync
{
    TRACE(@"%s", __PRETTY_FUNCTION__);
    [self setSubtitleSync:_subtitleSync - 0.1];
}

@end

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

#import "MTextOSD.h"

@implementation MTextOSD

- (id)init
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [_paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        //[_paragraphStyle setLineSpacing:0.5];
        //[_paragraphStyle setParagraphSpacing:0.1];
        //[_paragraphStyle setParagraphSpacingBefore:0];
        //[self setKern:-0.3];

        _textColor = [[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1] retain];
        _strokeColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1] retain];
        _strokeWidth = [[NSNumber alloc] initWithFloat:1.0];
        _strokeWidth2= [[NSNumber alloc] initWithFloat:-0.01];

        // for stroke & shadow
        _contentLeftMargin  = 10;
        _contentRightMargin = 30;
        _contentTopMargin   = 10;
        _contentBottomMargin= 30;
        
        _hAlign = OSD_HALIGN_LEFT;
        _vAlign = OSD_VALIGN_LOWER_FROM_MOVIE_TOP;
        _hMargin = _vMargin = 0.0;
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_font release];
    [_fontName release];
    [_paragraphStyle release];
    //[_kern release];
    [_textColor release];
    [_strokeWidth release];
    [_strokeWidth2 release];
    [_strokeColor release];
    [_shadowColor release];
    [_shadow release];
    [_string release];
    _string = nil;
    [self makeTexture:CGLGetCurrentContext()];  // delete texture
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setMovieRect:(NSRect)rect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(rect));
    [super setMovieRect:rect];
    _updateMask |= UPDATE_FONT;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSMutableAttributedString*)string { return _string; }
- (NSString*)fontName { return _fontName; }
- (float)fontSize { return _fontSize; }

- (BOOL)hasContent { return _newString && ([_newString length] != 0); }

- (void)clearContent
{
    [self setString:[[NSMutableAttributedString alloc] initWithString:@""]];
}

- (void)setTextAlignment:(NSTextAlignment)alignment
{
    [_paragraphStyle setAlignment:alignment];
}

- (BOOL)setString:(NSMutableAttributedString*)string
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [string string]);
    assert(string != nil);
    if (!_newString || ![_newString isEqualToAttributedString:string]) {
        [_newString release];
        _newString = [string retain];
        _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
        return TRUE;
    }
    return FALSE;
}

- (void)setFontName:(NSString*)name size:(float)size
{
    TRACE(@"%s \"%@\" %g", __PRETTY_FUNCTION__, name, size);
    if (![_fontName isEqualToString:name]) {
        [_fontName release];
        _fontName = [name retain];
    }
    _fontSize = size;

    _updateMask |= UPDATE_FONT | UPDATE_TEXTURE;
}

- (void)setTextColor:(NSColor*)textColor
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_textColor isEqualTo:textColor]) {
        [_textColor release];
        _textColor = [textColor retain];
        _updateMask |= UPDATE_CONTENT | UPDATE_TEXTURE;
    }
}

- (void)setStrokeColor:(NSColor*)strokeColor
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if (![_strokeColor isEqualTo:strokeColor]) {
        [_strokeColor release];
        _strokeColor = [strokeColor retain];
        _updateMask |= UPDATE_TEXTURE;
    }
}

- (void)setStrokeWidth:(float)strokeWidth
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    if ([_strokeWidth floatValue] != -strokeWidth) {
        [_strokeWidth release];
        _strokeWidth = [[NSNumber alloc] initWithFloat:-strokeWidth];
        _updateMask |= UPDATE_TEXTURE;
    }
}

/*
- (void)setKern:(float)kern
{
    //TRACE(@"%s %g", __PRETTY_FUNCTION__, kern);
    if ([_kern floatValue] != kern) {
        [_kern release];
        _kern = [[NSNumber alloc] initWithFloat:kern];
    }
     
    _updateMask |= UPDATE_TEXTURE;
}/
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)updateFont
{
    [_font release];
    float size = MAX(15.0, [self autoSize:_fontSize]);
    _font = [[NSFont fontWithName:_fontName size:size] retain];
    //TRACE(@"font recreated: name=\"%@\" size=%g", _fontName, [_font pointSize]);
}

- (NSImage*)makeTexImage
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromRect(viewBounds));
    if (_updateMask & UPDATE_FONT) {
        _updateMask &= ~UPDATE_FONT;
        [self updateFont];
    }
    return [super makeTexImage];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

NSString* MFontBoldAttributeName   = @"MFontBoldAttributeName";
NSString* MFontItalicAttributeName = @"MFontItalicAttributeName";

- (void)applyUserFontAttributes:(NSString*)attributeName fontTrait:(NSFontTraitMask)fontTrait
{
    //TRACE(@"%s \"%@\" %d", __PRETTY_FUNCTION__, attributeName, fontTrait);
    NSString* attrName = NSFontAttributeName;
    id attrValue = [[NSFontManager sharedFontManager] convertFont:_font
                                                      toHaveTrait:fontTrait];
    if (attrValue == _font) {   // no available font for fontTrait
        if (fontTrait != NSItalicFontMask || [_font italicAngle] != 0.0) {
            return;
        }
        // use alternative attribute NSObliqnessAttributeName for italic
        attrName = NSObliquenessAttributeName;
        attrValue = [NSNumber numberWithFloat:0.3];
    }

    NSNumber* n;
    NSRange attrRange;
    NSRange range = NSMakeRange(0, [_string length]);
    while (0 < range.length) {
        n = [_string attribute:attributeName atIndex:range.location
                        longestEffectiveRange:&attrRange inRange:range];
        if (n) {
            [_string addAttribute:attrName value:attrValue range:attrRange];
            range = NSMakeRange(NSMaxRange(attrRange),
                                NSMaxRange(range) - NSMaxRange(attrRange));
        }
        else {
            range.location++;
            range.length--;
        }
    }
}

- (void)applyAttributes
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSRange range = NSMakeRange(0, [_string length]);
    [_string addAttribute:NSFontAttributeName value:_font range:range];

    NSColor* c;
    NSRange r;  r.length = 1;
    for (r.location = 0; r.location < range.length; r.location++) {
        c = [_string attribute:NSForegroundColorAttributeName atIndex:r.location effectiveRange:nil];
        c = (!c) ? _textColor :
            [NSColor colorWithCalibratedRed:[c redComponent] green:[c greenComponent]
                                       blue:[c blueComponent] alpha:[_textColor alphaComponent]];
        [_string addAttribute:NSForegroundColorAttributeName value:c range:r];
    }
    [self applyUserFontAttributes:MFontItalicAttributeName fontTrait:NSItalicFontMask];
    [self applyUserFontAttributes:MFontBoldAttributeName fontTrait:NSBoldFontMask];

    [_string addAttribute:NSStrokeColorAttributeName value:_strokeColor range:range];
    if ([_strokeWidth floatValue] != 0.0) {
        [_string addAttribute:NSStrokeWidthAttributeName value:_strokeWidth range:range];
    }

    [_string addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle range:range];
    //[_string addAttribute:NSKernAttributeName value:_kern range:range];

    [_string fixAttributesInRange:range];
}

- (void)updateContent
{
    [_newString retain];
    [_string release];
    _string = _newString;
    
    if (!_string) {
        _contentSize.width  = 0;
        _contentSize.height = 0;
    }
    else {
        // set attributes : font & shadow should be applied before calculating size
        [self applyAttributes];
        
        NSSize maxSize = _movieRect.size;
        float vmargin = _movieRect.size.height * _vMargin;
        maxSize.width -= (_movieRect.size.width * _hMargin) * 2;
        NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin |
            NSStringDrawingUsesFontLeading |
            NSStringDrawingUsesDeviceMetrics;
        _contentSize = [_string boundingRectWithSize:maxSize options:options].size;
        // add margins for outline & shadow
        _contentSize.width  += _contentLeftMargin + _contentRightMargin;
        _contentSize.height += _contentTopMargin + MAX(vmargin, _contentBottomMargin);
    }
}

- (void)drawContent:(NSRect)rect
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    rect.origin.x += _contentLeftMargin;
    rect.origin.y += _contentBottomMargin;
    rect.size.width  -= _contentLeftMargin + _contentRightMargin;
    rect.size.height -= _contentTopMargin + _contentBottomMargin;

    // at first, draw with outline & shadow
    [_shadow set];
    int i;  assert(0 < _shadowDarkness);
    for (i = 0; i < _shadowDarkness; i++) {
        [_string drawInRect:rect];
    }

    // redraw with new-outline & no-shadow for sharpness
    NSRange range = NSMakeRange(0, [_string length]);
    [_shadowNone set];
    [_string addAttribute:NSStrokeWidthAttributeName
                    value:_strokeWidth2 range:range];
    [_string fixAttributesInRange:range];
    [_string drawInRect:rect];

    //[[NSColor blueColor] set];
    //NSFrameRect(rect);
}

@end

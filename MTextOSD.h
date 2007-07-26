//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovieOSD.h"

enum {  // for _updateMask
    UPDATE_FONT     = 1 << 3,
};

@interface MTextOSD : MMovieOSD
{
    NSMutableAttributedString* _newString;
    NSMutableAttributedString* _string;

    NSFont* _font;
    NSString* _fontName;
    float _fontSize;            // for 640-width-of-movie

    NSColor* _textColor;
    NSColor* _strokeColor;
    NSNumber* _strokeWidth;    // for 640-width-of-movie
    NSNumber* _strokeWidth2;   // for redraw

    NSMutableParagraphStyle* _paragraphStyle;
    //NSNumber* _kern;
}

#pragma mark -
- (NSString*)fontName;
- (float)fontSize;
- (void)setString:(NSMutableAttributedString*)string;
- (void)setFontName:(NSString*)name size:(float)size;
- (void)setTextColor:(NSColor*)textColor;
- (void)setStrokeColor:(NSColor*)strokeColor;
- (void)setStrokeWidth:(float)strokeWidth;
//- (void)setKern:(float)kern;

@end

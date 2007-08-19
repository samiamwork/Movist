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

#import "Movist.h"

#import <QuartzCore/QuartzCore.h>

@class MMovie;

@class MImageOSD;
@class MTextOSD;
@class MSubtitleOSD;
@class MBarOSD;

@interface MMovieView : NSOpenGLView
{
    CVDisplayLinkRef _displayLink;
    CGDirectDisplayID _displayID;
    NSRecursiveLock* _drawLock;

    CIContext* _ciContext;
    CIFilter* _colorFilter;
    CIFilter* _hueFilter;
    CIFilter* _cropFilter;  // for removing green box
	CVOpenGLTextureRef _image;
    CGRect _movieRect;
    CGRect _imageRect;
    int _fullScreenFill;
    float _fullScreenUnderScan;
    BOOL _removeGreenBox;

    MMovie* _movie;
    NSArray* _subtitles;

    // icon
    MImageOSD* _iconOSD;
    
    // message
    MTextOSD* _messageOSD;
    float _messageHideInterval;
    NSTimer* _messageHideTimer;
    
    // subtitle
    MSubtitleOSD* _subtitleOSD;
    BOOL _subtitleVisible;
    float _minLetterBoxHeight;
    float _subtitleSync;
    
    // bar
    MBarOSD* _barOSD;
    float _barHideInterval;
    NSTimer* _barHideTimer;

    // drag & drop
    unsigned int _dragAction;
    BOOL _activateOnDragging;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (MMovie*)movie;
- (NSRect)movieRect;
- (void)setMovie:(MMovie*)movie;
- (void)updateMovieRect:(BOOL)display;
- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect;

- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Video)

- (int)fullScreenFill;
- (float)fullScreenUnderScan;
- (void)setFullScreenFill:(int)fill;
- (void)setFullScreenUnderScan:(float)underScan;

- (float)brightness;
- (float)saturation;
- (float)contrast;
- (float)hue;
- (void)setBrightness:(float)brightness;
- (void)setSaturation:(float)saturation;
- (void)setContrast:(float)contrast;
- (void)setHue:(float)hue;

- (BOOL)removesGreenBox;
- (void)setRemoveGreenBox:(BOOL)remove;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Message)

- (void)setMessage:(NSString*)s;
- (void)setMessage:(NSString*)s info:(NSString*)info;
- (void)setAttributedMessage:(NSMutableAttributedString*)s;
- (void)invalidateMessageHideTimer;
- (float)messageHideInterval;
- (void)setMessageHideInterval:(float)interval;

- (void)showVolumeBar;
- (void)showSeekBar;
- (void)hideBar;
- (void)invalidateBarHideTimer;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Subtitle)

- (NSArray*)subtitles;
- (void)setSubtitles:(NSArray*)subtitles;
- (void)updateSubtitleString;

- (BOOL)subtitleVisible;
- (void)setSubtitleVisible:(BOOL)visible;

- (NSString*)subtitleFontName;
- (float)subtitleFontSize;
- (void)setSubtitleFontName:(NSString*)fontName size:(float)size;
- (void)setSubtitleTextColor:(NSColor*)textColor;
- (void)setSubtitleStrokeColor:(NSColor*)strokeColor;
- (void)setSubtitleStrokeWidth:(float)strokeWidth;
- (void)setSubtitleShadowColor:(NSColor*)shadowColor;
- (void)setSubtitleShadowBlur:(float)shadowBlur;
- (void)setSubtitleShadowOffset:(float)shadowOffset;

- (BOOL)subtitleDisplayOnLetterBox;
- (float)minLetterBoxHeight;
- (float)subtitleHMargin;
- (float)subtitleVMargin;
- (void)setSubtitleDisplayOnLetterBox:(BOOL)displayOnLetterBox;
- (void)setMinLetterBoxHeight:(float)height;
- (void)revertLetterBoxHeight;
- (void)increaseLetterBoxHeight;
- (void)decreaseLetterBoxHeight;
- (void)setSubtitleHMargin:(float)hMargin;
- (void)setSubtitleVMargin:(float)vMargin;

- (float)subtitleSync;
- (void)setSubtitleSync:(float)sync;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (DragDrop)

- (void)setActivateOnDragging:(BOOL)activate;

@end

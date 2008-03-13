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

@class MTextOSD;
@class MImageOSD;
@class MTextImageOSD;
@class SubtitleRenderer;

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
    BOOL _captureIncludingLetterBox;

    MMovie* _movie;
    NSArray* _subtitles;

    // subtitle
    SubtitleRenderer* _subtitleRenderer;
    MTextImageOSD* _subtitleImageOSD;
    BOOL _subtitleVisible;
    int _subtitlePositionByUser;
    int _subtitlePosition;
    float _subtitleSync;

    // icon, error, message
    MImageOSD* _iconOSD;
    MTextOSD* _errorOSD;
    MTextOSD* _messageOSD;
    float _messageHideInterval;
    NSTimer* _messageHideTimer;
    
    // drag & drop
    unsigned int _dragAction;
    BOOL _activateOnDragging;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (CGDirectDisplayID)displayID;

- (MMovie*)movie;
- (NSRect)movieRect;
- (void)setMovie:(MMovie*)movie;
- (void)showLogo;
- (void)hideLogo;
- (void)updateMovieRect:(BOOL)display;
- (float)subtitleLineHeightForMovieWidth:(float)movieWidth;
- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect;

- (void)lockDraw;
- (void)unlockDraw;
- (void)redisplay;

- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp;

- (void)setCaptureIncludingLetterBox:(BOOL)includingLetterBox;
- (void)saveCurrentImage:(BOOL)alternative;
- (IBAction)copy:(id)sender;

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

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Message)

- (void)setMessageWithMovieURL:(NSURL*)movieURL movieInfo:(NSString*)movieInfo
                   subtitleURL:(NSURL*)subtitleURL subtitleInfo:(NSString*)subtitleInfo;
- (void)setMessage:(NSString*)s;
- (void)setAttributedMessage:(NSMutableAttributedString*)s;
- (void)invalidateMessageHideTimer;
- (float)messageHideInterval;
- (void)setMessageHideInterval:(float)interval;

- (void)setError:(NSError*)error info:(NSString*)info;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Subtitle)

- (NSArray*)subtitles;
- (void)setSubtitles:(NSArray*)subtitles;
- (void)updateSubtitleString;
- (void)updateSubtitle;

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
- (void)setSubtitleShadowDarkness:(int)shadowDarkness;

- (int)subtitlePosition;
- (float)subtitleHMargin;
- (float)subtitleVMargin;
- (void)updateSubtitlePosition;
- (void)setSubtitlePosition:(int)position;
- (void)setSubtitleHMargin:(float)hMargin;
- (void)setSubtitleVMargin:(float)vMargin;
- (void)setSubtitleLineSpacing:(float)lineSpacing;

- (float)subtitleSync;
- (void)setSubtitleSync:(float)sync;

- (float)currentSubtitleTime;
- (float)prevSubtitleTime;
- (float)nextSubtitleTime;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (DragDrop)

- (void)setActivateOnDragging:(BOOL)activate;

@end

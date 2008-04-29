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
    float _brightnessValue; // for performance
    float _saturationValue;
    float _contrastValue;
    float _hueValue;

    MMovie* _movie;
    NSArray* _subtitles;

    // subtitle
    SubtitleRenderer* _subtitleRenderer;
    MTextImageOSD* _subtitleImageOSD;
    BOOL _subtitleVisible;
    int _autoSubtitlePositionMaxLines;
    int _subtitlePositionByUser;
    int _subtitlePosition;
    float _subtitleSync;

    // icon, error, message
    MImageOSD* _iconOSD;
    MTextOSD* _errorOSD;
    MTextOSD* _messageOSD;
    float _messageHideInterval;
    NSTimer* _messageHideTimer;
    
    // etc. options
    int _fullScreenFill;
    float _fullScreenUnderScan;
    int _draggingAction;
    int _captureFormat;
    BOOL _includeLetterBoxOnCapture;
    BOOL _removeGreenBox;

    // capture
    NSImage* _captureImage;
    NSString* _capturePath;
    NSPoint _draggingPoint;

    // fps calc.
    float _currentFps;
    double _lastFpsCheckTime;
    double _fpsElapsedTime;
    int _fpsFrameCount;

    // drag & drop
    unsigned int _dragAction;
    BOOL _activateOnDragging;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)lockDraw;
- (void)unlockDraw;
- (void)redisplay;

- (MMovie*)movie;
- (float)currentFps;
- (void)setMovie:(MMovie*)movie;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Image)

- (CGDirectDisplayID)displayID;

- (BOOL)initCoreVideo;
- (void)cleanupCoreVideo;
- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp;

- (BOOL)initCoreImage;
- (void)cleanupCoreImage;

- (NSRect)movieRect;
- (void)updateMovieRect:(BOOL)display;
- (float)subtitleLineHeightForMovieWidth:(float)movieWidth;
- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect;

- (int)fullScreenFill;
- (float)fullScreenUnderScan;
- (void)setFullScreenFill:(int)fill;
- (void)setFullScreenUnderScan:(float)underScan;
- (NSRect)underScannedRect:(NSRect)rect;

- (float)brightness;
- (float)saturation;
- (float)contrast;
- (float)hue;
- (void)setBrightness:(float)brightness;
- (void)setSaturation:(float)saturation;
- (void)setContrast:(float)contrast;
- (void)setHue:(float)hue;
- (void)setRemoveGreenBox:(BOOL)remove;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (OSD)

- (BOOL)initOSD;
- (void)cleanupOSD;

- (void)drawOSD;
- (void)drawDragHighlight;
- (void)clearOSD;

- (void)showLogo;
- (void)hideLogo;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Message)

- (void)setMessageWithURL:(NSURL*)url info:(NSString*)info;
- (void)setMessage:(NSString*)s;
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
- (void)setAutoSubtitlePositionMaxLines:(int)lines;
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

@interface MMovieView (Capture)

- (int)draggingActionWithModifierFlags:(unsigned int)flags;
- (void)setDraggingAction:(int)action;
- (void)setCaptureFormat:(int)format;
- (void)setIncludeLetterBoxOnCapture:(BOOL)include;

- (void)copyCurrentImage:(BOOL)alternative;
- (void)saveCurrentImage:(BOOL)alternative;
- (IBAction)copy:(id)sender;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (DragDrop)

- (void)setActivateOnDragging:(BOOL)activate;

@end

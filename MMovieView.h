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
@class MSubtitle;
@class MMovieOSD;

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
    NSSize _movieSize;
    CGRect _movieRect;
    CGRect _imageRect;
    float _brightnessValue; // for performance
    float _saturationValue;
    float _contrastValue;
    float _hueValue;
    BOOL _needsCoreImage;

    MMovie* _movie;

    // subtitle
    MSubtitle* _subtitle[3];
    MMovieOSD* _subtitleOSD[3];
    MMovieOSD* _auxSubtitleOSD[3];
    unsigned int _needsSubtitleDrawing; // bit-mask of subtitle-numbers
    BOOL _subtitleVisible;
    int _indexOfSubtitleInLBOX;
    int _autoLetterBoxHeightMaxLines;
    int _letterBoxHeightPrefs;
    int _letterBoxHeight;
    float _subtitleScreenMargin;        // pixels

    // icon, error, message
    MMovieOSD* _iconOSD;
    MMovieOSD* _errorOSD;
    MMovieOSD* _messageOSD;
    float _messageHideInterval;
    NSTimer* _messageHideTimer;
    
    // etc. options
    int _fullScreenFill;
    float _fullScreenUnderScan;
    int _viewDragAction;
    int _captureFormat;
    BOOL _includeLetterBoxOnCapture;
    BOOL _removeGreenBoxSetting;
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
- (void)drawImage;

- (BOOL)initCoreImage;
- (void)cleanupCoreImage;

- (NSRect)movieRect;
- (void)updateMovieRect:(BOOL)display;
- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect;

- (int)fullScreenFill;
- (float)fullScreenUnderScan;
- (void)setFullScreenFill:(int)fill;
- (void)setFullScreenUnderScan:(float)underScan;
- (void)setFullScreenMovieSize:(NSSize)size;
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
- (void)updateRemoveGreenBox;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (OSD)

- (BOOL)initOSD;
- (void)cleanupOSD;

- (void)drawOSD;
- (void)drawDragHighlight;
- (void)clearOSD;
- (void)updateOSDImageBaseWidth;

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

- (int)subtitleCount;
- (MSubtitle*)subtitleAtIndex:(int)index;
- (void)addSubtitle:(MSubtitle*)subtitle;
- (void)removeSubtitle:(MSubtitle*)subtitle;
- (void)removeAllSubtitles;
- (BOOL)updateSubtitleOSDAtIndex:(int)index;

- (BOOL)subtitleVisible;
- (void)setSubtitleVisible:(BOOL)visible;

- (void)getSubtitleAttributes:(SubtitleAttributes*)attrs atIndex:(int)index;
- (void)setSubtitleAttributes:(const SubtitleAttributes*)attrs atIndex:(int)index;
- (void)updateIndexOfSubtitleInLBOX;

- (int)letterBoxHeight;
- (float)subtitleScreenMargin;
- (void)setAutoLetterBoxHeightMaxLines:(int)lines;
- (void)setLetterBoxHeight:(int)height;
- (void)updateLetterBoxHeight;
- (void)setSubtitleScreenMargin:(float)screenMargin;

- (float)prevSubtitleTime;
- (float)nextSubtitleTime;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovieView (Capture)

- (int)viewDragActionWithModifierFlags:(unsigned int)flags;
- (void)setViewDragAction:(int)action;
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

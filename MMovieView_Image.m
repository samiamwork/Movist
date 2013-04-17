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
#import "MMovie_QuickTime.h"
#import "MMovieOSD.h"
#import "MMovieViewLayer.h"
#import "MSubtitle.h"
#import "AppController.h"   // for NSApp's delegate

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovieView (Image)

- (CGDirectDisplayID)displayID { return _displayID; }

- (CVReturn)updateImage:(const CVTimeStamp*)timeStamp
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    {
//        if (_movie) {
//            CVOpenGLTextureRef image = [_movie nextImage:timeStamp];
//            if (image) {
//                if (_image) {
//                    CVOpenGLTextureRelease(_image);
//                }
//                _image = image;
//                if (_subtitleVisible) {
//                    [self updateSubtitleOSDAtIndex:0];
//                    [self updateSubtitleOSDAtIndex:1];
//                    [self updateSubtitleOSDAtIndex:2];
//                }
//                if ([self canDraw]) {
//                    [self drawImage];
//                }
//                _fpsFrameCount++;
//            }
//            else if (_image && _subtitleVisible && _needsSubtitleDrawing) {
//                if (_needsSubtitleDrawing & 0x01) {
//                    [self updateSubtitleOSDAtIndex:0];
//                }
//                if (_needsSubtitleDrawing & 0x02) {
//                    [self updateSubtitleOSDAtIndex:1];
//                }
//                if (_needsSubtitleDrawing & 0x04) {
//                    [self updateSubtitleOSDAtIndex:2];
//                }
//                if ([self canDraw]) {
//                    [self drawImage];
//                }
//            }
//            // calc. fps
//            double ct = (double)timeStamp->videoTime / timeStamp->videoTimeScale;
//            _fpsElapsedTime += ABS(ct - _lastFpsCheckTime);
//            _lastFpsCheckTime = ct;
//            if (1.0 <= _fpsElapsedTime) {
//                _currentFps = (float)(_fpsFrameCount / _fpsElapsedTime);
//                _fpsElapsedTime = 0.0;
//                _fpsFrameCount = 0;
//            }
//        }
    }

    [pool release];
    
	return kCVReturnSuccess;
}

- (void)updateImageRect
{
//    assert(_image != 0);
//    _imageRect = CVImageBufferGetCleanRect(_image);
//    if (_removeGreenBox) {
//        _imageRect.origin.x++, _imageRect.size.width  -= 2;
//        _imageRect.origin.y++, _imageRect.size.height -= 2;
//    }
//    
//    if ([[NSApp delegate] isFullScreen] && _fullScreenFill == FS_FILL_CROP) {
//        NSSize bs = [self bounds].size;
//        NSSize ms = [self.movie adjustedSizeByAspectRatio];
//        if (bs.width / bs.height < ms.width / ms.height) {
//            float mw = ms.width * bs.height / ms.height;
//            float dw = (mw - bs.width) * ms.width / mw;
//            _imageRect.origin.x += dw / 2;
//            _imageRect.size.width -= dw;
//        }
//        else {
//            float mh = ms.height * bs.width / ms.width;
//            float dh = (mh - bs.height) * ms.height / mh;
//            _imageRect.origin.y += dh / 2;
//            _imageRect.size.height -= dh;
//        }
//    }
    //TRACE(@"_imageRect=%@", NSStringFromRect(*(NSRect*)&_imageRect));
}

- (void)drawImage
{
	return;

    {
        if (_imageRect.size.width == 0) {
            [self updateImageRect];
        }
        // draw image
//        CIImage* img = [CIImage imageWithCVImageBuffer:_image];
//        if (_removeGreenBox) {
//            [_cropFilter setValue:img forKey:@"inputImage"];
//            img = [_cropFilter valueForKey:@"outputImage"];
//        }
//        if (_brightnessValue != DEFAULT_BRIGHTNESS ||
//            _saturationValue != DEFAULT_SATURATION ||
//            _contrastValue   != DEFAULT_CONTRAST) {
//            [_colorFilter setValue:img forKey:@"inputImage"];
//            img = [_colorFilter valueForKey:@"outputImage"];
//        }
//        if (_hueValue != DEFAULT_HUE) {
//            [_hueFilter setValue:img forKey:@"inputImage"];
//            img = [_hueFilter valueForKey:@"outputImage"];
//        }
//        [_ciContext drawImage:img inRect:_movieRect fromRect:_imageRect];

        // clear extra area
//        NSRect bounds = [self bounds];
//        if (NSMinX(bounds) != CGRectGetMinX(_movieRect) ||
//            NSMinY(bounds) != CGRectGetMinY(_movieRect) ||
//            NSMaxX(bounds) != CGRectGetMaxX(_movieRect) ||
//            NSMaxY(bounds) != CGRectGetMaxY(_movieRect)) {
//            glColor3f(0.0f, 0.0f, 0.0f);
//            glBegin(GL_QUADS);
//                float vl = NSMinX(bounds), vr = NSMaxX(bounds);
//                float vb = NSMinY(bounds), vt = NSMaxY(bounds);
//                float rl = CGRectGetMinX(_movieRect);
//                float rr = CGRectGetMaxX(_movieRect);
//                float rb = CGRectGetMinY(_movieRect);
//                float rt = CGRectGetMaxY(_movieRect);
//                if (bounds.size.height != _movieRect.size.height) {
//                    // lower letter-box
//                    glVertex2f(vl, vb), glVertex2f(vl, rb);
//                    glVertex2f(vr, rb), glVertex2f(vr, vb);
//                    // upper letter-box
//                    glVertex2f(vl, rt), glVertex2f(vl, vt);
//                    glVertex2f(vr, vt), glVertex2f(vr, rt);
//                }
//                if (bounds.size.width != _movieRect.size.width) {
//                    // left area
//                    glVertex2f(vl, rb), glVertex2f(vl, rt);
//                    glVertex2f(rl, rt), glVertex2f(rl, rb);
//                    // right area
//                    glVertex2f(rr, rb), glVertex2f(rr, rt);
//                    glVertex2f(vr, rt), glVertex2f(vr, rb);
//                }
//            glEnd();
//            glColor3f(1.0f, 1.0f, 1.0f);
//        }
    }

    [self drawOSD];

    [self.movie idleTask];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark core-image

- (BOOL)initCoreImage
{
	CIFilter* colorFilter = [CIFilter filterWithName:@"CIColorControls"];
	CIFilter* hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
	[colorFilter setDefaults];
	[hueFilter setDefaults];
	[colorFilter setName:@"color"];
	[hueFilter setName:@"hue"];

	_rootLayer.filters = [NSArray arrayWithObjects:colorFilter, hueFilter, nil];

	return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark movie-rect

- (NSRect)movieRect { return *(NSRect*)&_movieRect; }

- (void)updateMovieRect:(BOOL)display
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, display ? @"display" : @"no-display");

    NSRect bounds = [self bounds];
    if (_subtitleScreenMargin) {
        //bounds.origin.x += _subtitleScreenMargin;
        bounds.origin.y += _subtitleScreenMargin;
        //bounds.size.width -= _subtitleScreenMargin * 2;
        bounds.size.height-= _subtitleScreenMargin * 2;
    }

    if (!self.movie) {
        [_iconOSD setViewBounds:bounds movieRect:bounds autoSizeWidth:0];
        [_messageOSD setViewBounds:bounds movieRect:bounds autoSizeWidth:0];
    }
    else {
        // make invalid to update later
        _imageRect.size.width = 0;

        // update _movieRect
        NSRect mr = [self calcMovieRectForBoundingRect:[self bounds]];
        _movieRect = *(CGRect*)&mr;

        float asw = 0;
        if ([[NSApp delegate] isFullScreen] &&
            NSEqualSizes(_movieSize, NSZeroSize)) {
            asw = NSWidth(bounds);
        }
        [_iconOSD setViewBounds:bounds movieRect:mr autoSizeWidth:asw];
        [_messageOSD setViewBounds:bounds movieRect:mr autoSizeWidth:asw];
		if ([_subtitleOSD setViewBounds:bounds movieRect:mr autoSizeWidth:asw]) {
			if (_subtitle && [_subtitle isEnabled]) {
				[_subtitle setNeedsRemakeTexImages];
				[self updateSubtitleOSD];
			}
		}
    }
    [_errorOSD setViewBounds:bounds movieRect:NSInsetRect(bounds, 50, 0) autoSizeWidth:0];

    if (display) {
        [self redisplay];
    }

}

- (float)calcLetterBoxHeightForMovieSize:(NSSize)movieSize
                            boundingSize:(NSSize)boundingSize
{
    if (_letterBoxHeight == LETTER_BOX_HEIGHT_SAME || !_subtitleInLBOX) {
        return (boundingSize.height - movieSize.height) / 2;
    }

    MMovieOSD* subtitleOSD = _subtitleOSD;
    float lineHeight = [subtitleOSD adjustedLineHeight:movieSize.width];
    float lineSpacing = [subtitleOSD adjustedLineSpacing:movieSize.width];
    // FIXME: how to apply line-spacing for line-height?  it's estimated roughly...
    #define LINE_HEIGHT (lineHeight + lineSpacing / 2)

    int lines = _letterBoxHeight - LETTER_BOX_HEIGHT_1_LINE + 1;
    float height = lines * LINE_HEIGHT + _subtitleScreenMargin;
    while (boundingSize.height < movieSize.height + height) {
        height -= LINE_HEIGHT;
    }
    float midHeight = (boundingSize.height - movieSize.height) / 2;
    return MAX(height, midHeight);
}

- (NSRect)_calcMovieRectForBoundingRect:(NSRect)boundingRect
{
    NSRect rect;
    rect.origin = boundingRect.origin;

    NSSize bs = boundingRect.size;
    NSSize ms = [self.movie adjustedSizeByAspectRatio];
    if (bs.width / bs.height < ms.width / ms.height) {
        rect.size.width = bs.width;
        rect.size.height = rect.size.width * ms.height / ms.width;
        rect.origin.y += [self calcLetterBoxHeightForMovieSize:rect.size
                                                  boundingSize:bs];
    }
    else {
        rect.size.height = bs.height;
        rect.size.width = rect.size.height * ms.width / ms.height;
        rect.origin.x += (bs.width - rect.size.width) / 2;
    }
    return rect;
}

- (NSRect)calcMovieRectForBoundingRect:(NSRect)boundingRect
{
    //TRACE(@"%s %@", __PRETTY_FUNCTION__, NSStringFromSize(boundingSize));
    if ([[NSApp delegate] isFullScreen] && 0 < _fullScreenUnderScan) {
        boundingRect = [self underScannedRect:boundingRect];
    }

    if ([[NSApp delegate] isFullScreen] || [[NSApp delegate] isDesktopBackground]) {
        if (!NSEqualSizes(_movieSize, NSZeroSize)) {
            if (NSWidth(boundingRect)  < _movieSize.width ||
                NSHeight(boundingRect) < _movieSize.height) {
                return [self _calcMovieRectForBoundingRect:boundingRect];
            }
            else {
                NSRect rect = boundingRect;
                rect.size = _movieSize;
                rect.origin.x += (NSWidth(boundingRect)  - _movieSize.width)  / 2;
                rect.origin.y += [self calcLetterBoxHeightForMovieSize:rect.size
                                                          boundingSize:boundingRect.size];
                return rect;
            }
        }
        else if (_fullScreenFill != FS_FILL_NEVER) {
            return boundingRect;
        }
    }
    return [self _calcMovieRectForBoundingRect:boundingRect];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark full-screen fill

- (int)fullScreenFill { return _fullScreenFill; }
- (float)fullScreenUnderScan { return _fullScreenUnderScan; }
- (void)setFullScreenFill:(int)fill { _fullScreenFill = fill; }
- (void)setFullScreenUnderScan:(float)underScan { _fullScreenUnderScan = underScan; }

- (void)setFullScreenMovieSize:(NSSize)size
{
    _movieSize = size;
    [self updateMovieRect:TRUE];
}

- (NSRect)underScannedRect:(NSRect)rect
{
    assert(0 < _fullScreenUnderScan);
    float underScan = _fullScreenUnderScan / 100.0;
    float dw = rect.size.width  * underScan;
    float dh = rect.size.height * underScan;
    rect.origin.x += dw / 2, rect.size.width  -= dw;
    rect.origin.y += dh / 2, rect.size.height -= dh;
    return rect;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark color-controls

- (float)brightness { return [[_rootLayer valueForKeyPath:@"filters.color.inputBrightness"] floatValue]; }
- (float)saturation { return [[_rootLayer valueForKeyPath:@"filters.color.inputSaturation"] floatValue]; }
- (float)contrast   { return [[_rootLayer valueForKeyPath:@"filters.color.inputContrast"] floatValue]; }
- (float)hue        { return [[_rootLayer valueForKeyPath:@"filters.hue.inputAngle"] floatValue]; }

- (void)setFilterInput:(NSString*)filterPath value:(CGFloat)value min:(CGFloat)min max:(CGFloat)max
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	{
		CGFloat normalizedValue = normalizedFloat2(adjustToRange(value, min, max));
		[_rootLayer setValue:[NSNumber numberWithFloat:normalizedValue] forKeyPath:filterPath];
	}
	[CATransaction commit];
}

- (void)setBrightness:(float)brightness
{
	[self setFilterInput:@"filters.color.inputBrightness" value:brightness min:MIN_BRIGHTNESS max:MAX_BRIGHTNESS];
}

- (void)setSaturation:(float)saturation
{
	[self setFilterInput:@"filters.color.inputSaturation" value:saturation min:MIN_SATURATION max:MAX_SATURATION];
}

- (void)setContrast:(float)contrast
{
	[self setFilterInput:@"filters.color.inputContrast" value:contrast min:MIN_CONTRAST max:MAX_CONTRAST];
}

- (void)setHue:(float)hue
{
	[self setFilterInput:@"filters.hue.inputAngle" value:hue min:MIN_HUE max:MAX_HUE];
}

@end

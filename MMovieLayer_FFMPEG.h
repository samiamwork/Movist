//
//  Movist
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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "MMovieLayer.h"

@class MMovie_FFmpeg;

@interface MMovieLayer_FFMPEG : NSOpenGLLayer <MMovieLayer>
{
	BOOL                _configured;
	BOOL                _movieNeedsGLContext;
	MMovie_FFmpeg*      _movie;
	CVOpenGLTextureRef  _image;
	CIContext*          _ciContext;
	CGDirectDisplayID   _displayID;
//	NSRecursiveLock*    _drawLock;
}

- (void)setMovie:(MMovie_FFmpeg*)newMovie;
- (MMovie*)movie;
@end

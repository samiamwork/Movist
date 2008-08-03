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
#import "AppController.h"   // for NSApp's delegate

@implementation MMovieView (Capture)

- (void)setCaptureFormat:(int)format { _captureFormat = format; }
- (void)setIncludeLetterBoxOnCapture:(BOOL)include { _includeLetterBoxOnCapture = include; }

- (NSRect)rectForCapture:(BOOL)alternative
{
    if (_includeLetterBoxOnCapture) {
        return (alternative) ? *(NSRect*)&_movieRect : [self bounds];
    }
    else {
        return (alternative) ? [self bounds] : *(NSRect*)&_movieRect;
    }
}

- (NSImage*)captureRect:(NSRect)rect
{
    float width = MAX(rect.size.width, _movieRect.size.width);
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:0
        pixelsWide:rect.size.width pixelsHigh:rect.size.height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:TRUE isPlanar:FALSE
        colorSpaceName:NSCalibratedRGBColorSpace
        bytesPerRow:width * 4 bitsPerPixel:0] autorelease];

    [_drawLock lock];
    [[self openGLContext] makeCurrentContext];
    glReadPixels((int)rect.origin.x, (int)rect.origin.y,
                 (int)rect.size.width, (int)rect.size.height,
                 GL_RGBA, GL_UNSIGNED_BYTE, [imageRep bitmapData]);
    [NSOpenGLContext clearCurrentContext];
    [_drawLock unlock];

    NSImage* image = [[NSImage alloc] initWithSize:rect.size];
    [image addRepresentation:imageRep];

    // image is flipped. so, flip again. teach me better idea...
    NSImage* imageFlipped = [[NSImage alloc] initWithSize:rect.size];
    [imageFlipped lockFocus];
        [image setFlipped:TRUE];
        [image drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect
                 operation:NSCompositeSourceOver fraction:1.0];
        [image release];
    [imageFlipped unlockFocus];
    return [imageFlipped autorelease];
}

- (NSData*)dataWithImage:(NSImage*)image
{
    NSBitmapImageFileType fileType = NSTIFFFileType;
    NSMutableDictionary* properties = [NSMutableDictionary dictionary];
    if (_captureFormat == CAPTURE_FORMAT_TIFF) {
        fileType = NSTIFFFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:??? forKey:NSImageCompressionMethod];
    }
    else if (_captureFormat == CAPTURE_FORMAT_JPEG) {
        fileType = NSJPEGFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
        //[properties setObject:??? forKey:NSImageProgressive];
    }
    else if (_captureFormat == CAPTURE_FORMAT_PNG) {
        fileType = NSPNGFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:??? forKey:NSImageGamma];
        //[properties setObject:??? forKey:NSImageInterlaced];
    }
    else if (_captureFormat == CAPTURE_FORMAT_BMP) {
        fileType = NSBMPFileType;
    }
    else if (_captureFormat == CAPTURE_FORMAT_GIF) {
        fileType = NSGIFFileType;
        //[properties setObject:??? forKey:NSImageColorSyncProfileData];
        //[properties setObject:??? forKey:NSImageDitherTransparency];
        //[properties setObject:??? forKey:NSImageRGBColorTable];
    }

    return [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]]
            representationUsingType:fileType properties:properties];
}

- (NSString*)fileExtensionForCaptureFormat:(int)format
{
    /*
    NSString * NSFileTypeForHFSTypeCode(OSType hfsFileTypeCode);
     */
    return (format == CAPTURE_FORMAT_JPEG) ? @"jpeg" :
           (format == CAPTURE_FORMAT_PNG)  ? @"png" :
           (format == CAPTURE_FORMAT_BMP)  ? @"bmp" :
           (format == CAPTURE_FORMAT_GIF)  ? @"gif" :
                   /* CAPTURE_FORMAT_TIFF */ @"tiff";
}

- (NSString*)capturePathAtDirectory:(NSString*)directory
{
    NSString* name = [[[[NSApp delegate] movieURL] path] lastPathComponent];
    NSString* ext = [self fileExtensionForCaptureFormat:_captureFormat];
    directory = [[directory stringByExpandingTildeInPath]
                 stringByAppendingPathComponent:[name stringByDeletingPathExtension]];
    int i = 1;
    NSString* path;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    while (TRUE) {
        path = [directory stringByAppendingFormat:@" %d.%@", i++, ext];
        if (![fileManager fileExistsAtPath:path]) {
            break;
        }
    }
    return path;
}

- (void)copyCurrentImage:(BOOL)alternative
{
    NSImage* image = [self captureRect:[self rectForCapture:alternative]];
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    [pboard setData:[self dataWithImage:image] forType:NSTIFFPboardType];
}

- (void)saveCurrentImage:(BOOL)alternative
{
    NSImage* image = [self captureRect:[self rectForCapture:alternative]];
    NSString* path = [self capturePathAtDirectory:@"~/Desktop"];
    [[self dataWithImage:image] writeToFile:path atomically:TRUE];
}

- (IBAction)copy:(id)sender
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [self copyCurrentImage:[sender tag] != 0];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma view drag action

- (void)setViewDragAction:(int)action { _viewDragAction = action; }

- (int)viewDragActionWithModifierFlags:(unsigned int)flags
{
    return (flags & NSControlKeyMask)   ? VIEW_DRAG_ACTION_MOVE_WINDOW :
           (flags & NSAlternateKeyMask) ? VIEW_DRAG_ACTION_CAPTURE_MOVIE :
                                          _viewDragAction;
}

- (NSSize)thumbnailSizeForImageSize:(NSSize)imageSize
{
    const float MAX_SIZE = 192;
    return (imageSize.width < imageSize.height) ?
        NSMakeSize(MAX_SIZE * imageSize.width / imageSize.height, MAX_SIZE) :
        NSMakeSize(MAX_SIZE, MAX_SIZE * imageSize.height / imageSize.width);
}

- (void)mouseDragged:(NSEvent*)event
{
    int action = [self viewDragActionWithModifierFlags:[event modifierFlags]];
    if (action == VIEW_DRAG_ACTION_MOVE_WINDOW) {
        if (![[NSApp delegate] isFullScreen]) {
            [[self window] mouseDragged:event];
        }
    }
    else if (action == VIEW_DRAG_ACTION_CAPTURE_MOVIE) {
        BOOL alt = ([event modifierFlags] & NSShiftKeyMask) ? TRUE : FALSE;
        _captureImage = [[self captureRect:[self rectForCapture:alt]] retain];

//#define _REAL_SIZE_DRAGGING
#if defined(_REAL_SIZE_DRAGGING)
        _draggingPoint = [event locationInWindow];
        _draggingPoint.x -= [self frame].origin.x;
        _draggingPoint.y -= [self frame].origin.y;
        NSRect rect;
        rect.size = [_captureImage size];
        rect.origin = NSMakePoint(0, 0);
#else
        NSRect rect;
        rect.size = [self thumbnailSizeForImageSize:[_captureImage size]];
        rect.origin = [self convertPoint:[event locationInWindow] fromView:nil];
        rect.origin.x -= rect.size.width / 2;
        rect.origin.y -= rect.size.height / 2;
#endif
        NSString* ext = [self fileExtensionForCaptureFormat:_captureFormat];
        [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:ext]
                              fromRect:rect source:self slideBack:TRUE event:event];
    }
}

- (void)dragImage:(NSImage*)image at:(NSPoint)imageLoc offset:(NSSize)mouseOffset
            event:(NSEvent*)event pasteboard:(NSPasteboard*)pboard
           source:(id)sourceObject slideBack:(BOOL)slideBack
{
#if defined(_REAL_SIZE_DRAGGING)
    NSSize size = [_captureImage size];
#else
    NSSize size = [self thumbnailSizeForImageSize:[_captureImage size]];
#endif
    NSImage* dragImage = [[[NSImage alloc] initWithSize:size] autorelease];
    [dragImage lockFocus];
        [dragImage setBackgroundColor:[NSColor clearColor]];
        [_captureImage drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSZeroRect
                    operation:NSCompositeSourceOver fraction:0.5];
    [dragImage unlockFocus];

    [super dragImage:dragImage at:imageLoc offset:mouseOffset
               event:event pasteboard:pboard source:sourceObject slideBack:slideBack];
}

- (NSArray*)namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination
{
    _capturePath = [[self capturePathAtDirectory:[dropDestination path]] retain];
    return [NSArray arrayWithObject:_capturePath];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)forLocal
{
    return (forLocal) ? NSDragOperationNone : NSDragOperationCopy;
}
/*
#if defined(_REAL_SIZE_DRAGGING)
- (void)draggedImage:(NSImage*)image movedTo:(NSPoint)screenPoint
{
    screenPoint.x += _draggingPoint.x;
    screenPoint.y += _draggingPoint.y;
    NSSize size;
    if (NSPointInRect(screenPoint, [[self window] frame])) {
        size = [_captureImage size];
    }
    else {
        size = [self thumbnailSizeForImageSize:[_captureImage size]];
    }
    if (!NSEqualSizes([image size], size)) {
        // FIXME: I don't know how to change image size???
        TRACE(@"change to %@",NSEqualSizes([_captureImage size], size) ?
                                        @"real size" : @"thumbnail size");
        [image lockFocus];
        [image setSize:size];
        [image setBackgroundColor:[NSColor clearColor]];
        [_captureImage drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSZeroRect
                        operation:NSCompositeSourceOver fraction:0.5];
        [image unlockFocus];
    }
}
#endif
*/
- (void)draggedImage:(NSImage*)image
             endedAt:(NSPoint)point operation:(NSDragOperation)operation
{
    [[self dataWithImage:_captureImage] writeToFile:_capturePath atomically:TRUE];

    [_capturePath release], _capturePath = nil;
    [_captureImage release], _captureImage = nil;
}

@end

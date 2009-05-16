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

#import "MSubtitleParser_SUB.h"

#import "vobsub.h"
#import "spudec.h"

@implementation MSubtitleParser_SUB

- (id)initWithURL:(NSURL*)subtitleURL
{
    if (self = [super initWithURL:subtitleURL]) {
        _subtitles = [[NSMutableArray alloc] initWithCapacity:2];
    }
    return self;
}

- (void)dealloc
{
    if (_spudec) {
        spudec_free(_spudec);
        _spudec = 0;
    }
    if (_vobsub) {
        vobsub_close(_vobsub);
        _vobsub = 0;
    }
    [_subtitles release];

    [super dealloc];
}

static void dummy_draw_alpha(int x, int y, int w, int h,
                             unsigned char* src, unsigned char* srca,
                             int stride) { /* do nothing */ }

- (NSBitmapImageRep*)imageRepWithSpudec:(spudec_handle_t*)spudec
{
    int x, y, width;
    int sx = spudec->width - 1, ex = 0;
    unsigned char* pa = spudec->aimage;
    for (y = 0; y < spudec->height; y++) {
        for (x = 0; x < spudec->width; x++) {
            if (pa[x] && x < sx) {
                sx = x;
            }
        }
        for (x = spudec->width - 1; 0 <= x; x--) {
            if (pa[x] && ex < x) {
                ex = x;
            }
        }
        pa += spudec->stride;
    }
    width = ex - sx + 1;

    NSBitmapImageRep* bmp;
    bmp = [[NSBitmapImageRep alloc]
           initWithBitmapDataPlanes:0
           pixelsWide:width pixelsHigh:spudec->height
           bitsPerSample:8 samplesPerPixel:4 hasAlpha:TRUE
           isPlanar:FALSE colorSpaceName:NSCalibratedRGBColorSpace
           bitmapFormat:0 bytesPerRow:width * 4 bitsPerPixel:32];
    pa = spudec->aimage;
    unsigned char* pi = spudec->image;
    unsigned char* pb = [bmp bitmapData];
    for (y = 0; y < spudec->height; y++) {
        for (x = sx; x <= ex; x++) {
            *pb++ = pi[x];              // red
            *pb++ = pi[x];              // green
            *pb++ = pi[x];              // blue
            *pb++ = (pa[x]) ? 255 : 0;  // alpha: 255 is opaque
        }
        pi += spudec->stride;
        pa += spudec->stride;
    }
    return [bmp autorelease];
}

- (void)parseSubtitle:(MSubtitle*)subtitle atIndex:(int)index
{
    spudec_packet_t* packet;
    int size, pts100;
    NSBitmapImageRep* bmp;
    NSImage* image;

    NSAutoreleasePool* pool;
    spudec_handle_t* spudec = (spudec_handle_t*)_spudec;
    while (0 <= (size = vobsub_get_next_packet(_vobsub, index, (void*)&packet, &pts100))) {
        spudec_assemble(spudec, (unsigned char*)packet, size, pts100);
        if (spudec->queue_head) {
            spudec_heartbeat(spudec, spudec->queue_head->start_pts);
            if (spudec_changed(spudec)) {
                if (0 < spudec->width && 0 < spudec->height) {
                    pool = [[NSAutoreleasePool alloc] init];
                    bmp = [self imageRepWithSpudec:spudec];
                    image = [[NSImage alloc] initWithSize:[bmp size]];
                    [image addRepresentation:bmp];
                    [image setCacheMode:NSImageCacheNever];
                    [image setCachedSeparately:TRUE]; // for thread safety
                    [subtitle addImage:image baseWidth:spudec->width
                             beginTime:spudec->start_pts / 90 / 1000.f
                               endTime:spudec->end_pts   / 90 / 1000.f];
                    [image release];
                    [pool release];
                }
                spudec_draw(spudec, dummy_draw_alpha);
            }
        }
    }
    spudec_reset(_spudec);
}

- (void)parseThread:(id)object
{
    NSAutoreleasePool* pool = nil;

    MSubtitle* subtitle;
    int i, count = [_subtitles count];
    for (i = 0; i < count; i++) {
        pool = [[NSAutoreleasePool alloc] init];

        subtitle = [_subtitles objectAtIndex:i];
        [self parseSubtitle:subtitle atIndex:i];

        [pool release], pool = nil;
    }

    [self release];
}

- (NSArray*)parseWithOptions:(NSDictionary*)options error:(NSError**)error
{
    NSString* path = [[_subtitleURL path] stringByDeletingPathExtension];
    _vobsub = vobsub_open([path UTF8String], 0, 0, &_spudec);
    if (!_vobsub) {
        return nil;
    }

    MSubtitle* subtitle;
    int i, count = vobsub_get_indexes_count(_vobsub);
    for (i = 0; i < count; i++) {
        subtitle = [[[MSubtitle alloc] initWithURL:_subtitleURL] autorelease];
        [subtitle setType:@"SUB"];
        [subtitle setName:[NSString stringWithCString:vobsub_get_id(_vobsub, i)
                                             encoding:NSASCIIStringEncoding]];
        [subtitle setTrackName:NSLocalizedString(@"External Subtitle", nil)];
        [subtitle setEmbedded:FALSE];
        [_subtitles addObject:subtitle];
    }

    // self should be retained for threading.
    // self will be released after threading.
    [self retain];

    [NSThread detachNewThreadSelector:@selector(parseThread:)
                             toTarget:self withObject:self];

    // _spudec, _vobsub will be released in -dealloc.

    return _subtitles;
}

// this is called by MSubtitleParser_MKV for each subtitle-image-item.
- (NSImage*)parseSubtitleImage:(unsigned char*)data size:(int)dataSize
                baseImageWidth:(int*)imageBaseWidth
{
    *imageBaseWidth = 0;
    return nil; // FIXME
}

@end

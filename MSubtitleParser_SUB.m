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
        _tracks = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return self;
}

- (void)dealloc
{
    int i, count = [_subtitles count];
    for (i = 0; i < count; i++) {
        if (_spudec[i]) {
            spudec_free(_spudec[i]);
        }
    }
    if (_vobsub) {
        vobsub_close(_vobsub);
        _vobsub = 0;
    }
    [_tracks release];
    [_subtitles release];

    [super dealloc];
}

- (NSImage*)imageWithSpudec:(spudec_handle_t*)spudec
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

    NSImage* image = [[NSImage alloc] initWithSize:[bmp size]];
    [image addRepresentation:bmp];
    [image setCacheMode:NSImageCacheNever];
    [image setCachedSeparately:TRUE]; // for thread safety
    [bmp release];

    return [image autorelease];
}

- (void)parseSubtitle:(MSubtitle*)subtitle atIndex:(int)index
{
    TRACE(@"subtitle[%d] parse... (0x%x)", index, _spudec[index]);
    vobsub_init_spudec(_vobsub, index);

    NSAutoreleasePool* pool;
    int size, pts100;
    spudec_packet_t* packet;
    spudec_handle_t* spudec = (spudec_handle_t*)_spudec[index];
    while (0 <= (size = vobsub_get_next_packet(_vobsub, index, (void*)&packet, &pts100))) {
        spudec_assemble(spudec, (unsigned char*)packet, size, pts100);
        if (spudec->queue_head) {
            spudec_heartbeat(spudec, spudec->queue_head->start_pts);
            if (spudec_changed(spudec)) {
                if (0 < spudec->width && 0 < spudec->height) {
                    pool = [[NSAutoreleasePool alloc] init];
                    [subtitle addImage:[self imageWithSpudec:spudec]
                             beginTime:spudec->start_pts / 90 / 1000.f
                               endTime:spudec->end_pts   / 90 / 1000.f];
                    [pool release];
                }

                if (spudec->start_pts <= spudec->now_pts &&
                    spudec->now_pts < spudec->end_pts && spudec->image) {
                    spudec->spu_changed = 0;
                }
            }
        }
    }
    spudec_reset(_spudec[index]);
    TRACE(@"subtitle[%d] parse...done", index);
}

- (void)parseThread:(id)object
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    int index = [(NSNumber*)object intValue];
    MSubtitle* subtitle = [_subtitles objectAtIndex:index];
    [self parseSubtitle:subtitle atIndex:index];

    [pool release];
}

- (NSArray*)parseWithOptions:(NSDictionary*)options error:(NSError**)error
{
    NSString* path = [[_subtitleURL path] stringByDeletingPathExtension];
    _vobsub = vobsub_open([path UTF8String], 0, 0, &_spudec[0]);
    if (!_vobsub) {
        return nil;
    }

    MSubtitle* subtitle;
    int i, count = vobsub_get_indexes_count(_vobsub);
    for (i = 0; i < count; i++) {
        if (0 < i) {    // _spudec[0] is already init in vobsub_open().
            _spudec[i] = calloc(1, sizeof(spudec_handle_t));
            memcpy(_spudec[i], _spudec[0], sizeof(spudec_handle_t));
        }
        subtitle = [[[MSubtitle alloc] initWithURL:_subtitleURL] autorelease];
        [subtitle setType:@"VOBSUB"];
        [subtitle setName:[NSString stringWithCString:vobsub_get_id(_vobsub, i)
                                             encoding:NSASCIIStringEncoding]];
        [subtitle setTrackName:NSLocalizedString(@"External Subtitle", nil)];
        [subtitle setEmbedded:FALSE];
        [_subtitles addObject:subtitle];

        [NSThread detachNewThreadSelector:@selector(parseThread:) toTarget:self
                               withObject:[NSNumber numberWithInt:i]];
    }

    // _spudec, _vobsub will be released in -dealloc.

    return _subtitles;
}
/*
// this is called by MSubtitleParser_MKV for each subtitle-idx.
- (void)mkvTrackNumber:(int)trackNumber parseIdx:(const char*)s
{
    int index = [_tracks count];
    if (!_vobsub) {
        _vobsub = vobsub_make(s, &_spudec[0]);
    }
    if (0 < index) {
        _spudec[index] = calloc(1, sizeof(spudec_handle_t));
        memcpy(_spudec[index], _spudec[0], sizeof(spudec_handle_t));
    }
    [_tracks setObject:[NSNumber numberWithInt:index]
                forKey:[NSNumber numberWithInt:trackNumber]];
    //TRACE(@"idx: %d => %d", trackNumber, index);
}

// this is called by MSubtitleParser_MKV for each subtitle-image-item.
- (void)mkvTrackNumber:(int)trackNumber
    parseSubtitleImage:(unsigned char*)data size:(int)dataSize time:(float)time
{
    int index = [[_tracks objectForKey:[NSNumber numberWithInt:trackNumber]] intValue];

    vobsub_add_sub(_vobsub, index, data, dataSize, (int)(time * 90 * 1000));
}
*/
@end

//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim, Cheol Ju. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//      Cheol Ju      <moosoy@gmail.com>
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

#import "FFIndexer.h"
#import "MMovie_FFmpeg.h"

#import <ffmpeg/avio.h>
//#import <libavformat/avio.h>
#import <fcntl.h>

///////////// copied from ffmpeg/libavformat/avformat.h ///////////////////////

//typedef struct {
//    int64_t  riff_end;
//    int64_t  movi_end;
//    int64_t  fsize;
//    int64_t movi_list;
//    int64_t last_pkt_pos;
//    int index_loaded;
//    int is_odml;
//    int non_interleaved;
//    int stream_index;
//    struct DVDemuxContext* dv_demux;
//} AVIContext;

typedef struct {
    int64_t  riff_end;
    int64_t  movi_end;
    int64_t  fsize;
    offset_t movi_list;
    int index_loaded;
    int is_odml;
    int non_interleaved;
    int stream_index;
    struct DVDemuxContext* dv_demux;
} AVIContext;

///////////////////////////////////////////////////////////////////////////////

@implementation FFIndexer

- (id)initWithMovie:(MMovie_FFmpeg*)movie
      formatContext:(AVFormatContext*)formatContext
        streamIndex:(int)streamIndex
     frameReadMutex:(NSLock*)frameReadMutex
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    const char* path = [[[movie url] path] UTF8String];
    if (av_open_input_file(&_indexContext, path, NULL, 0, NULL) != 0) {
        return 0;
    }
    if (av_find_stream_info(_indexContext) < 0) {
        return 0;
    }

    if (self = [super initWithAVStream:_indexContext->streams[streamIndex]
                                 index:streamIndex]) {
        _movie = [movie retain];
        _formatContext = formatContext;
        _frameReadMutex = [frameReadMutex retain];
        _maxFrameSize = 0;
        _indexingTime = 0;
        _indexingPosition = 0;
        _finished = FALSE;

        _running = TRUE;
        [NSThread detachNewThreadSelector:@selector(indexingThreadFunc:)
                                 toTarget:self withObject:nil];
    }
    return self;
}

- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_frameReadMutex release];
    [_movie release];
    [super dealloc];

    av_close_input_file(_indexContext);
}

- (void)waitForFinish
{
    while (_running) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)makeIndex
{
    AVPacket packet;
    int i;
    for (i = 0; i < 30;) {
        if ([_movie quitRequested]) {
            break;
        }
        if (_indexContext->file_size < _indexingPosition + _maxFrameSize * 4) {
            _finished = TRUE;
            return;
        }
        if (av_read_frame(_indexContext, &packet) < 0) {
            _finished = TRUE;
            TRACE(@"%s read-error or end-of-file", __PRETTY_FUNCTION__);
            return;
        }
        [_frameReadMutex lock];
        av_add_index_entry(_formatContext->streams[packet.stream_index], 
                           packet.pos - 8, packet.dts, packet.size, 0,
                           (packet.flags & PKT_FLAG_KEY) ? AVINDEX_KEYFRAME : 0);
        [_frameReadMutex unlock];
        if (packet.stream_index == [self streamIndex]) {
            if (packet.flags & PKT_FLAG_KEY) {
                AVStream* stream = _formatContext->streams[packet.stream_index];
                _indexingTime = packet.dts * av_q2d(stream->time_base);
                TRACE(@"current %f", packet.dts * av_q2d(stream->time_base));
            }
            i++;
        }
        if (_maxFrameSize < packet.size) {
            _maxFrameSize = packet.size;
        }
        _indexingPosition = packet.pos;
        av_free_packet(&packet);
    }
}

- (void)updateFileSize:(int)fd
{
    int64_t fileSize = lseek(fd, (off_t)0, SEEK_END);
    if (fileSize < 0) {
        TRACE(@"seek failed (%d:%s)", errno, strerror(errno));
        return;
    }

    /* AHHHHHH, DIRTY HACK.... */
    AVIContext* aviContext = (AVIContext*)(_formatContext->priv_data);
    if (fileSize <= aviContext->fsize) {
        return;
    }
    _finished = FALSE;
    TRACE(@"file size = %lld", fileSize);

    //TRACE(@"mov_end   = %lld", aviContext->movi_end);
    //TRACE(@"riff_end  = %lld", aviContext->riff_end);
    aviContext->fsize = fileSize;
    _formatContext->file_size = fileSize;

    aviContext = (AVIContext*)(_indexContext->priv_data);
    aviContext->fsize = fileSize;
    _indexContext->file_size = fileSize;
    _indexContext->pb->eof_reached = 0;
}

- (void)indexingThreadFunc:(id)anObject
{
    TRACE(@"%s", __PRETTY_FUNCTION__);    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    const char* path = [[[_movie url] path] UTF8String];
    int fd = open(path, O_RDONLY);
    if (0 <= fd) {
        const NSTimeInterval INDEXING_INTERVAL = 0.1;
        const NSTimeInterval CHECK_FILE_SIZE_INTERVAL = 5;
        const NSTimeInterval SKIP_INTERVAL = 0.01;
        int skipCount = 0;
        int tmpCount = 0; // FIXME
        while (![_movie quitRequested]) {
            if (skipCount * SKIP_INTERVAL < INDEXING_INTERVAL) {
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:SKIP_INTERVAL]];
                skipCount++;
                continue;
            }
            skipCount = 0;
            [self makeIndex];
            [_movie indexedDurationUpdated:_indexingTime];

            if (tmpCount < CHECK_FILE_SIZE_INTERVAL / INDEXING_INTERVAL) {
                tmpCount++;
                continue;
            }
            tmpCount = 0;
            [self updateFileSize:fd];
        }
        close(fd);
    }
    [_movie performSelector:@selector(indexingFinished:)
                 withObject:self afterDelay:0.1];

    [pool release];
    _running = FALSE;

    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

@end

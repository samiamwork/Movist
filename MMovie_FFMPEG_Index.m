//
//  Movist
//
//  Copyright 2006, 2007 Cheol Ju. All rights reserved.
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

#import "MMovie_FFmpeg.h"
#import <avio.h>
#include <fcntl.h>

///////////// copied from ffmpeg/libavformat/avformat.h ///////////////////////

typedef struct DVDemuxContext DVDemuxContext;

typedef struct {
    int64_t  riff_end;
    int64_t  movi_end;
    int64_t  fsize;
    offset_t movi_list;
    int index_loaded;
    int is_odml;
    int non_interleaved;
    int stream_index;
    DVDemuxContext* dv_demux;
} AVIContext;

///////////////////////////////////////////////////////////////////////////////


@implementation MMovie_FFmpeg (Index)

- (BOOL)isCompleteFile
{
    return _indexContext->streams[_indexStreamId]->nb_index_entries > 1;
}

- (BOOL)initIndexContext
{
    const char* path = [[_url path] UTF8String];
    if (av_open_input_file(&_indexContext, path, NULL, 0, NULL) != 0) {
        return FALSE;
    }
    if (av_find_stream_info(_indexContext) < 0) {
        return FALSE;
    }
    int i;
    _indexStreamId = -1;
    for (i = 0; i < _indexContext->nb_streams; i++) {
        if (_indexContext->streams[i]->codec->codec_type == CODEC_TYPE_VIDEO) {
            _indexStreamId = i;
            break;
        }
    }
    if (_indexStreamId < 0) {
        return FALSE;
    }
    _indexCodec = _indexContext->streams[_indexStreamId]->codec;
    AVCodec* codec = avcodec_find_decoder(_indexCodec->codec_id);
    if (!codec) {
        return FALSE;
    }
    if (![self initDecoder:_indexCodec codec:codec forVideo:TRUE]) {
        return FALSE;
    }
    _needIndexing = FALSE;
    if (strstr(_indexContext->iformat->name, "avi")) {
        _needIndexing = ![self isCompleteFile];
    }
    _indexedDuration = (_needIndexing) ? 0 : _info.duration;
    _maxFrameSize = 0;
    _currentIndexingPosition = 0;
    return TRUE;
}

- (void)cleanupIndexContext
{
    avcodec_close(_indexCodec);
    av_close_input_file(_indexContext);
    _indexStreamId = -1;
    _indexContext = 0;
}

- (void)makeIndex
{
    if (_indexingCompleted) {
        return;
    }
    AVPacket packet;
    int i;
    for (i = 0; i < 10; i++) {
        if (_quitRequested) {
            break;
        }
        if (_indexContext->file_size < _currentIndexingPosition + _maxFrameSize * 4) {
            _indexingCompleted = TRUE;
            return;
        }
        if (av_read_frame(_indexContext, &packet) < 0) {
            _indexingCompleted = TRUE;
            TRACE(@"%s read-error or end-of-file", __PRETTY_FUNCTION__);
            return;
        }
        [_frameReadMutex lock];
        av_add_index_entry(_formatContext->streams[packet.stream_index], 
                           packet.pos - 8,
                           packet.dts,
                           packet.size,
                           0,
                           packet.flags & PKT_FLAG_KEY ? AVINDEX_KEYFRAME : 0);
        [_frameReadMutex unlock];
        if (packet.stream_index == _videoStreamIndex &&
            packet.flags & PKT_FLAG_KEY) {
            TRACE(@"current %f", 1. * packet.dts * av_q2d(_videoStream->time_base)); 
            _indexedDuration = packet.dts * av_q2d(_formatContext->streams[packet.stream_index]->time_base);
        }
        if (_maxFrameSize < packet.size) {
            _maxFrameSize = packet.size;
        }
        _currentIndexingPosition = packet.pos;
        av_free_packet(&packet);
    }
}

- (void)updateFileSize:(int)fd
{
    if (!strstr(_indexContext->iformat->name, "avi")) {
        return;
    }
    int64_t fileSize = lseek(fd, (off_t)0, SEEK_END);
    if (fileSize < 0) {
        NSLog(@"seek failed (%d:%s)", errno, strerror(errno));
        return;
    }

    /* AHHHHHH, DIRTY HACK.... */
    AVIContext* aviContext = (AVIContext*)(_formatContext->priv_data);
    if (fileSize <= aviContext->fsize) {
        return;
    }
    _indexingCompleted = FALSE;
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

- (void)backgroundThreadFunc:(id)anObject
{
    _playThreading++;
    TRACE(@"%s", __PRETTY_FUNCTION__);    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if (![self initIndexContext]) {
        [pool release];
        _playThreading--;
        return;
    }
    if (!_needIndexing) {
        [self cleanupIndexContext];
        [pool release];
        _playThreading--;
        TRACE(@"%s need not indexing", __PRETTY_FUNCTION__);
        return;
    }
    const char* path = [[_url path] UTF8String];
    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        [self cleanupIndexContext];
        [pool release];
        _playThreading--;
        return;
    }
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    const NSTimeInterval INDEXING_INTERVAL = 0.1;
    const NSTimeInterval CHECK_FILE_SIZE_INTERVAL = 5;
    const NSTimeInterval SKIP_INTERVAL = 0.01;
    int skipCount = 0;
    int tmpCount = 0; // FIXME
    while (!_quitRequested) {
        if (skipCount * SKIP_INTERVAL < INDEXING_INTERVAL) {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:SKIP_INTERVAL]];
            skipCount++;
            continue;
        }
        skipCount = 0;
        [self makeIndex];
        if (!_indexingCompleted) {
            [nc postNotificationName:MMovieIndexedDurationNotification object:self];
        }
        if (tmpCount < CHECK_FILE_SIZE_INTERVAL / INDEXING_INTERVAL) {
            tmpCount++;
            continue;
        }
        tmpCount = 0;
        [self updateFileSize:fd];
    }
    [self cleanupIndexContext];
    close(fd);
    [pool release];
    _playThreading--;
    TRACE(@"%s finished", __PRETTY_FUNCTION__);
}

/*
- (double) keyFrameTime:(double)time mode:(int)mode
{
    int left = 0;
    int right = _rebuildedKeyCount - 1;
    int middle = (left + right) / 2;
    while (left < right) {
        middle = (left + right) / 2;
        if (right - left == 1) {
            break;
        }        
        if (_avIndex[middle].timestamp == time) {
            break;
        }
        if (_avIndex[middle].timestamp < time) {
            left = middle;
        }
        else {
            right = middle;
        }
    }
    return _avIndex[middle].pos;
}
*/
@end

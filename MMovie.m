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

#import "MMovie.h"

#import <avcodec.h>
#import <avformat.h>

@implementation MTrack

- (id)initWithMovie:(MMovie*)movie
{
    if (self = [super init]) {
        _movie = [movie retain];
        _enabled = TRUE;
    }
    return self;
}

- (void)dealloc
{
    [_summary release];
    [_name release];
    [_movie release];
    [super dealloc];
}

- (MMovie*)movie { return _movie; }
- (NSString*)name { return _name; }
- (NSString*)summary { return _summary; }
- (BOOL)isEnabled { return _enabled; }
- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;

    if (_enabled) {
        [_movie trackEnabled:self];
    }
    else {
        [_movie trackDisabled:self];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation MMovie

+ (NSArray*)movieFileExtensions
{
    return [NSArray arrayWithObjects:
            @"avi", @"svi", @"divx",                        // general movie
            @"wm",  @"wmp", @"wmv", @"wmx", @"wvx",         // Windows Media
            @"asf", @"asx",                                 // Windows Media
            @"mpe", @"mpg", @"mpeg",@"m1v", @"m2v",         // MPEG
            @"dat", @"ifo", @"vob", @"ts",  @"tp",  @"trp", // MPEG
            @"mp4", @"m4v",                                 // MPEG4
            @"rm",  @"rmvb",                                // Real Media
            @"mkv",                                         // Matroska
            @"ogm",                                         // OGM
            //@"swf",                                         // Flash
            @"flv",                                         // Flash Video
            @"mov", @"mqv", @"qt",                          // QuickTime
            //@"dmb",                                       // DMB-TS
            //@"3gp", @"dmskm",@"k3g", @"skm", @"lmp4",       // Mobile Phone
            nil];
}

+ (BOOL)checkMovieURL:(NSURL*)url error:(NSError**)error
{
    if ([url isFileURL]) {
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString* path = [url path];
        if (![fileManager fileExistsAtPath:path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Movist"
                                             code:ERROR_FILE_NOT_EXIST userInfo:nil];
            }
            return FALSE;
        }
        if (![fileManager isReadableFileAtPath:path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Movist"
                                             code:ERROR_FILE_NOT_READABLE userInfo:nil];
            }
            return FALSE;
        }
    }
    return TRUE;
}

+ (AVFormatContext*)formatContextForMovieURL:(NSURL*)url error:(NSError**)error
{
    AVFormatContext* formatContext = 0;
    const char* path = [[url path] UTF8String];
    if (av_open_input_file(&formatContext, path, NULL, 0, NULL) != 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"Movist"
                                         code:ERROR_FFMPEG_FILE_OPEN_FAILED
                                     userInfo:nil];
        }
        return 0;
    }
    if (av_find_stream_info(formatContext) < 0) {
        av_close_input_file(formatContext);
        if (error) {
            *error = [NSError errorWithDomain:@"Movist"
                                         code:ERROR_FFMPEG_STREAM_INFO_NOT_FOUND
                                     userInfo:nil];
        }
        return 0;
    }
    return formatContext;
}

+ (int)videoCodecIdFromFFmpegCodecId:(int)ffmpegCodecId fourCC:(NSString*)fourCC
{
    #define CASE_FFCODEC_MCODEC(fc, mc) \
            case CODEC_ID_##fc : \
                codecId = MCODEC_##mc; \
                fs = @""#fc; ms = @""#mc; \
                break
    #define CASE_FFCODEC_______(fc) \
            case CODEC_ID_##fc : \
                fs = @""#fc; \
                break
    #define IF_FFCODEC_MCODEC(fcs, mc) \
            if ([fourCC isEqualToString:fcs]) \
                codecId = MCODEC_##mc, \
                ms = @""#mc
    
    // at first, init with ffmpegCodeId for codecs without fourCC
    int codecId = MCODEC_ETC_;
    NSString* fs = @"???", *ms = @"???";
    switch (ffmpegCodecId) {
        CASE_FFCODEC_MCODEC(NONE,            ETC_);
        CASE_FFCODEC_MCODEC(MPEG1VIDEO,      MPEG1);
        CASE_FFCODEC_MCODEC(MPEG2VIDEO,      MPEG2);
        CASE_FFCODEC_MCODEC(MPEG2VIDEO_XVMC, MPEG2);
        CASE_FFCODEC_______(H261);
        CASE_FFCODEC_MCODEC(H263,            H263);
        CASE_FFCODEC_MCODEC(RV10,            RV10);
        CASE_FFCODEC_MCODEC(RV20,            RV20);
        CASE_FFCODEC_MCODEC(MJPEG,           MJPEG);
        CASE_FFCODEC_MCODEC(MJPEGB,          MJPEG);
        CASE_FFCODEC_______(LJPEG);
        CASE_FFCODEC_______(SP5X);
        CASE_FFCODEC_______(JPEGLS);
        CASE_FFCODEC_MCODEC(MPEG4,           MPEG4);
        CASE_FFCODEC_______(RAWVIDEO);
        CASE_FFCODEC_MCODEC(MSMPEG4V1,       MPG4);
        CASE_FFCODEC_MCODEC(MSMPEG4V2,       MP42);
        CASE_FFCODEC_MCODEC(MSMPEG4V3,       MP43);
        CASE_FFCODEC_MCODEC(WMV1,            WMV1);
        CASE_FFCODEC_MCODEC(WMV2,            WMV2);
        CASE_FFCODEC_MCODEC(H263P,           H263);
        CASE_FFCODEC_MCODEC(H263I,           H263);
        CASE_FFCODEC_MCODEC(FLV1,            FLV);
        CASE_FFCODEC_MCODEC(SVQ1,            SVQ1);
        CASE_FFCODEC_MCODEC(SVQ3,            SVQ3);
        CASE_FFCODEC_______(DVVIDEO);
        CASE_FFCODEC_MCODEC(HUFFYUV,         HUFFYUV);
        CASE_FFCODEC_______(CYUV);
        CASE_FFCODEC_MCODEC(H264,            H264);
        CASE_FFCODEC_MCODEC(INDEO3,          INDEO3);
        CASE_FFCODEC_MCODEC(VP3,             VP3);
        CASE_FFCODEC_MCODEC(THEORA,          THEORA);
        CASE_FFCODEC_______(ASV1);
        CASE_FFCODEC_______(ASV2);
        CASE_FFCODEC_______(FFV1);
        CASE_FFCODEC_______(4XM);
        CASE_FFCODEC_______(VCR1);
        CASE_FFCODEC_______(CLJR);
        CASE_FFCODEC_______(MDEC);
        CASE_FFCODEC_______(ROQ);
        CASE_FFCODEC_______(INTERPLAY_VIDEO);
        CASE_FFCODEC_______(XAN_WC3);
        CASE_FFCODEC_______(XAN_WC4);
        CASE_FFCODEC_______(RPZA);
        CASE_FFCODEC_MCODEC(CINEPAK,         CINEPAK);
        CASE_FFCODEC_______(WS_VQA);
        CASE_FFCODEC_______(MSRLE);
        CASE_FFCODEC_______(MSVIDEO1);
        CASE_FFCODEC_______(IDCIN);
        CASE_FFCODEC_______(8BPS);
        CASE_FFCODEC_______(SMC);
        CASE_FFCODEC_______(FLIC);
        CASE_FFCODEC_______(TRUEMOTION1);
        CASE_FFCODEC_______(VMDVIDEO);
        CASE_FFCODEC_______(MSZH);
        CASE_FFCODEC_______(ZLIB);
        CASE_FFCODEC_______(QTRLE);
        CASE_FFCODEC_______(SNOW);
        CASE_FFCODEC_______(TSCC);
        CASE_FFCODEC_______(ULTI);
        CASE_FFCODEC_______(QDRAW);
        CASE_FFCODEC_______(VIXL);
        CASE_FFCODEC_______(QPEG);
        CASE_FFCODEC_MCODEC(XVID,            XVID);
        CASE_FFCODEC_______(PNG);
        CASE_FFCODEC_______(PPM);
        CASE_FFCODEC_______(PBM);
        CASE_FFCODEC_______(PGM);
        CASE_FFCODEC_______(PGMYUV);
        CASE_FFCODEC_______(PAM);
        CASE_FFCODEC_______(FFVHUFF);
        CASE_FFCODEC_MCODEC(RV30,            RV30);
        CASE_FFCODEC_MCODEC(RV40,            RV40);
        CASE_FFCODEC_MCODEC(VC1,             VC1);
        CASE_FFCODEC_MCODEC(WMV3,            WMV3);
        CASE_FFCODEC_______(LOCO);
        CASE_FFCODEC_______(WNV1);
        CASE_FFCODEC_______(AASC);
        CASE_FFCODEC_MCODEC(INDEO2,          INDEO2);
        CASE_FFCODEC_______(FRAPS);
        CASE_FFCODEC_______(TRUEMOTION2);
        CASE_FFCODEC_______(BMP);
        CASE_FFCODEC_______(CSCD);
        CASE_FFCODEC_______(MMVIDEO);
        CASE_FFCODEC_______(ZMBV);
        CASE_FFCODEC_______(AVS);
        CASE_FFCODEC_______(SMACKVIDEO);
        CASE_FFCODEC_______(NUV);
        CASE_FFCODEC_______(KMVC);
        CASE_FFCODEC_______(FLASHSV);
        CASE_FFCODEC_______(CAVS);
        CASE_FFCODEC_______(JPEG2000);
        CASE_FFCODEC_______(VMNC);
        CASE_FFCODEC_MCODEC(VP5,             VP5);
        CASE_FFCODEC_MCODEC(VP6,             VP6);
        CASE_FFCODEC_MCODEC(VP6F,            VP6F);
        CASE_FFCODEC_______(TARGA);
        CASE_FFCODEC_______(DSICINVIDEO);
        CASE_FFCODEC_______(TIERTEXSEQVIDEO);
        CASE_FFCODEC_______(TIFF);
        CASE_FFCODEC_______(GIF);
        CASE_FFCODEC_______(FFH264);
        CASE_FFCODEC_______(DXA);
        CASE_FFCODEC_______(DNXHD);
        CASE_FFCODEC_______(THP);
        CASE_FFCODEC_______(SGI);
        CASE_FFCODEC_______(C93);
        CASE_FFCODEC_______(BETHSOFTVID);
        CASE_FFCODEC_______(PTX);
        CASE_FFCODEC_______(TXD);
        CASE_FFCODEC_______(VP6A);
        CASE_FFCODEC_______(AMV);
        CASE_FFCODEC_______(VB);
        CASE_FFCODEC_______(PCX);
        CASE_FFCODEC_______(SUNRAST);
        CASE_FFCODEC_MCODEC(MPEG2TS,         MPEG2);
    }
    
    // update detailed-codec-info by fourCC
    if (fourCC) {
             IF_FFCODEC_MCODEC(@"DIV1", DIV1);
        else IF_FFCODEC_MCODEC(@"DIV2", DIV2);
        else IF_FFCODEC_MCODEC(@"DIV3", DIV3);
        else IF_FFCODEC_MCODEC(@"DIV4", DIV4);
        else IF_FFCODEC_MCODEC(@"DIV5", DIV5);
        else IF_FFCODEC_MCODEC(@"DIV6", DIV6);
        else IF_FFCODEC_MCODEC(@"DIVX", DIVX);
        else IF_FFCODEC_MCODEC(@"DX50", DX50);
        else IF_FFCODEC_MCODEC(@"XVID", XVID);
        else IF_FFCODEC_MCODEC(@"mp4v", MP4V);
        else IF_FFCODEC_MCODEC(@"MPG4", MPG4);
        else IF_FFCODEC_MCODEC(@"MP42", MP42);
        else IF_FFCODEC_MCODEC(@"MP43", MP43);
        else IF_FFCODEC_MCODEC(@"MP4S", MP4S);
        else IF_FFCODEC_MCODEC(@"M4S2", M4S2);
        else IF_FFCODEC_MCODEC(@"AP41", AP41);
        else IF_FFCODEC_MCODEC(@"RMP4", RMP4);
        else IF_FFCODEC_MCODEC(@"SEDG", SEDG);
        else IF_FFCODEC_MCODEC(@"FMP4", FMP4);
        else IF_FFCODEC_MCODEC(@"BLZ0", BLZ0);
        else IF_FFCODEC_MCODEC(@"avc1", AVC1);
        else IF_FFCODEC_MCODEC(@"X264", X264);
        else IF_FFCODEC_MCODEC(@"x264", X264);
        else IF_FFCODEC_MCODEC(@"vc-1", VC1);
        else IF_FFCODEC_MCODEC(@"WVC1", WVC1);
        // [3IV2],[IV31],[IV32]
    }
    TRACE(@"detected codec: [%d]:\"%@\" ==> [%d]:\"%@\"", ffmpegCodecId, fs, codecId, ms);
    return codecId;
}

+ (BOOL)getMovieInfo:(MMovieInfo*)info forMovieURL:(NSURL*)url error:(NSError**)error
{
    if (![self checkMovieURL:url error:error]) {
        return FALSE;
    }

    AVFormatContext* formatContext;
    formatContext = [self formatContextForMovieURL:url error:error];
    if (!formatContext) {
        return FALSE;
    }

    info->videoCodecId = -1;
    info->encodedSize.width = 0;
    info->encodedSize.height= 0;
    info->displaySize.width = 0;
    info->displaySize.height= 0;
    info->startTime = 0;
    info->duration = 0;
    info->audioCodecId = -1;
    info->audioChannels = 0;
    info->audioSampleRate = 0;
    info->preferredVolume = DEFAULT_VOLUME;

    if (formatContext->duration != AV_NOPTS_VALUE) {
        info->duration = formatContext->duration / AV_TIME_BASE;
    }
    if (formatContext->start_time != AV_NOPTS_VALUE) {
        info->startTime = formatContext->start_time / AV_TIME_BASE;
    }

    AVCodecContext* enc;
    NSString* fourCC = nil;
    int i;
    for (i = 0; i < formatContext->nb_streams; i++) {
        enc = formatContext->streams[i]->codec;

        if (enc->codec_tag != 0) {
            unsigned int tag = enc->codec_tag;
            if (isprint((tag      ) & 0xFF) && isprint((tag >>  8) & 0xFF) &&
                isprint((tag >> 16) & 0xFF) && isprint((tag >> 24) & 0xFF)) {
                fourCC = [NSString stringWithFormat:@"%c%c%c%c",
                          (tag      ) & 0xFF, (tag >>  8) & 0xFF,
                          (tag >> 16) & 0xFF, (tag >> 24) & 0xFF];
            }
        }

        if (enc->codec_type == CODEC_TYPE_VIDEO) {
            if (info->videoCodecId < 0) {
                info->videoCodecId =
                    [self videoCodecIdFromFFmpegCodecId:enc->codec_id fourCC:fourCC];
                TRACE(@"coded={%3d,%3d}, size={%3d,%3d}",
                      enc->coded_width, enc->coded_height, enc->width, enc->height);
                info->encodedSize.width = enc->coded_width;
                info->encodedSize.height= enc->coded_height;
                info->displaySize.width = enc->width;
                info->displaySize.height= enc->height;
                if (0 < enc->sample_aspect_ratio.num && 0 < enc->sample_aspect_ratio.den) {
                    info->displaySize.width *= (float)enc->sample_aspect_ratio.num /
                                                      enc->sample_aspect_ratio.den;
                    // FIXME: ignore strange pixel-aspect-ratio (vertically long).
                    if (info->displaySize.width < info->displaySize.height) {
                        info->displaySize.width = info->encodedSize.width;
                    }
                }
            }
        }
        else if (enc->codec_type == CODEC_TYPE_AUDIO) {
            info->audioChannels = enc->channels;
            info->audioSampleRate = enc->sample_rate;
        }
    }
    av_close_input_file(formatContext);

    return TRUE;
}

+ (NSString*)name { return @""; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (id)initWithURL:(NSURL*)url movieInfo:(MMovieInfo*)movieInfo error:(NSError**)error
{
    //TRACE(@"%s \"%@\"", __PRETTY_FUNCTION__, [url absoluteString]);
    if (![MMovie checkMovieURL:url error:error]) {
        return nil;
    }
    if (self = [super init]) {
        _url = [url retain];
        memcpy(&_info, movieInfo, sizeof(MMovieInfo));
        _videoTracks = [[NSMutableArray alloc] initWithCapacity:1];
        _audioTracks = [[NSMutableArray alloc] initWithCapacity:5];

        _volume = DEFAULT_VOLUME;
        _muted = FALSE;

        _aspectRatio = ASPECT_RATIO_DEFAULT;
    }
    return self;
}

- (BOOL)setOpenGLContext:(NSOpenGLContext*)openGLContext
             pixelFormat:(NSOpenGLPixelFormat*)openGLPixelFormat
                   error:(NSError**)error
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    return TRUE;
}

- (void)cleanup
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [_audioTracks release];
    [_videoTracks release];
    [_url release];
    [self release];
}
/*
- (void)dealloc
{
    //TRACE(@"%s", __PRETTY_FUNCTION__);
    [super dealloc];
}
*/
////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSURL*)url { return _url; }
- (NSArray*)videoTracks { return _videoTracks; }
- (NSArray*)audioTracks { return _audioTracks; }
- (NSSize)displaySize { return _info.displaySize; }
- (NSSize)encodedSize { return _info.encodedSize; }
- (float)startTime { return _info.startTime; }
- (float)duration { return _info.duration; }
- (float)preferredVolume { return _info.preferredVolume; }

- (float)indexedDuration { return _indexedDuration; }
- (float)volume { return _volume; }
- (BOOL)muted { return _muted; }
- (void)setVolume:(float)volume { _volume = volume; }
- (void)setMuted:(BOOL)muted { _muted = muted; }

- (int)aspectRatio { return _aspectRatio; }
- (NSSize)adjustedSizeByAspectRatio { return _adjustedSize; }
- (void)setAspectRatio:(int)aspectRatio
{
    _aspectRatio = aspectRatio;

    if (_aspectRatio == ASPECT_RATIO_DEFAULT) {
        _adjustedSize = _info.displaySize;
    }
    else {
        float ratio[] = {
            4.0  / 3.0,     // ASPECT_RATIO_4_3
            16.0 / 9.0,     // ASPECT_RATIO_16_9
            1.85 / 1.0,     // ASPECT_RATIO_1_85
            2.35 / 1.0,     // ASPECT_RATIO_2_35
        };
        _adjustedSize.width  = _info.displaySize.width;
        _adjustedSize.height = _info.displaySize.width / ratio[_aspectRatio - 1];
    }
}

- (void)trackEnabled:(MTrack*)track {}
- (void)trackDisabled:(MTrack*)track {}

// FIXME
- (int)videoCodecId { return _info.videoCodecId; }
- (int)audioCodecId { return _info.audioCodecId; }
- (int)audioChannels { return _info.audioChannels; }
- (float)audioSampleRate { return _info.audioSampleRate; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark playback

- (float)currentTime { return 0.0; }
- (float)rate { return 0.0; }
- (void)setRate:(float)rate {}
- (void)stepBackward {}
- (void)stepForward {}
- (void)gotoBeginning {}
- (void)gotoEnd {}
- (void)gotoTime:(float)time {}
- (void)seekByTime:(float)dt {}
- (CVOpenGLTextureRef)nextImage:(const CVTimeStamp*)timeStamp { return 0; }
- (void)idleTask {}

@end

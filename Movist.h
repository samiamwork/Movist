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

#import <Cocoa/Cocoa.h>

#import "MovistExtensions.h"

#pragma mark check-for-updates
enum {
    CHECK_UPDATE_NEVER,
    CHECK_UPDATE_DAILY,
    CHECK_UPDATE_WEEKLY,
    CHECK_UPDATE_MONTHLY,
};

#pragma mark decoder
enum {
    DECODER_QUICKTIME,
    DECODER_FFMPEG,
};

#pragma mark full-scren transition
enum {
    FS_EFFECT_NONE,
    FS_EFFECT_FADE,
    FS_EFFECT_ANIMATION,
};

#pragma mark full-screen fill
enum {
    FS_FILL_NEVER,
    FS_FILL_STRETCH,
    FS_FILL_CROP
};

#pragma mark aspect-ratio
enum {
    ASPECT_RATIO_DAR,   // DAR (Display Aspect Ratio)
    ASPECT_RATIO_SAR,   // SAR (Source Aspect Ratio)
    ASPECT_RATIO_4_3,   //    4 : 3 (TV)
    ASPECT_RATIO_16_9,  //   16 : 9 (HDTV)
    ASPECT_RATIO_1_85,  // 1.85 : 1 (Screen)
    ASPECT_RATIO_2_35,  // 2.35 : 1 (Screen)
};

#pragma mark dragging-action on movie-area
enum {
    DRAGGING_ACTION_NONE,
    DRAGGING_ACTION_MOVE_WINDOW,
    DRAGGING_ACTION_CAPTURE_MOVIE,
};

#pragma mark movie-capture format
enum {
    CAPTURE_FORMAT_TIFF,
    CAPTURE_FORMAT_JPEG,
    CAPTURE_FORMAT_PNG,
    CAPTURE_FORMAT_BMP,
    CAPTURE_FORMAT_GIF,
};

#pragma mark error-codes
enum {
    ERROR_FILE_NOT_EXIST = 1,
    ERROR_FILE_NOT_READABLE,

    ERROR_SUBTITLE_NOT_FOUND,
    ERROR_UNSUPPORTED_SUBTITLE_TYPE,

    ERROR_INVALID_VIDEO_DIMENSION,
    ERROR_VISUAL_CONTEXT_CREATE_FAILED,

    ERROR_FFMPEG_FILE_OPEN_FAILED,
    ERROR_FFMPEG_STREAM_INFO_NOT_FOUND,
    ERROR_FFMPEG_VIDEO_STREAM_NOT_FOUND,
    ERROR_FFMPEG_DECODER_NOT_FOUND,
    ERROR_FFMPEG_CODEC_OPEN_FAILED,
    ERROR_FFMPEG_FRAME_ALLOCATE_FAILED,
    ERROR_FFMPEG_SW_SCALER_INIT_FAILED,
    ERROR_FFMPEG_AUDIO_UNIT_CREATE_FAILED,
};

#pragma mark -
#pragma mark codec-id
enum {
    MCODEC_ETC_         = 0,    // for all other codecs

    // video codec //////////////////////////////////////

    MCODEC_MPEG1        = 1,    // MPEG-1
    MCODEC_MPEG2        = 10,   // MPEG-2
    MCODEC_MPEG4        = 100,  // MPEG-4
        MCODEC_DIV1,            // DivX MPEG-4 V3.x
        MCODEC_DIV2,            // DivX MPEG-4 V3.x
        MCODEC_DIV3,            // DivX MPEG-4 V3.x (Low Motion)
        MCODEC_DIV4,            // DivX MPEG-4 V3.x (Fast Motion)
        MCODEC_DIV5,            // DivX MPEG-4 V3.x
        MCODEC_DIV6,            // DivX MPEG-4 V3.x
        MCODEC_DIVX,            // DivX MPEG-4 V4.x
        MCODEC_DX50,            // DivX MPEG-4 V5.x
        MCODEC_XVID     = 120,  // Xvid MPEG-4
        MCODEC_MP4V     = 130,  // Apple MPEG-4
        MCODEC_MPG4     = 140,  // Microsoft MPEG-4 V1
        MCODEC_MP42,            // Microsoft MPEG-4 V2
        MCODEC_MP43,            // Microsoft MPEG-4 V3
        MCODEC_MP4S,            // Microsoft ISO MPEG-4 V1
        MCODEC_M4S2,            // Microsoft ISO MPEG-4 V1.1
        MCODEC_AP41     = 150,  // AngelPotion Definitive
        MCODEC_RMP4     = 160,  // REALmagic MPEG-4
        MCODEC_SEDG     = 170,  // Samsung MPEG-4
        MCODEC_FMP4     = 180,  // FFmpeg MPEG-4
        MCODEC_BLZ0,            // DivX for Blizzard

    MCODEC_H263         = 200,  // H.263, H.263+
    MCODEC_H264         = 300,  // H.264/MPEG4 AVC
        MCODEC_AVC1,            // Apple H.264
        MCODEC_X264,            // Open Source H.264
    MCODEC_VC1          = 400,  // VC-1 (SMPTE 421M)

    MCODEC_WMV1         = 500,  // Windows Media Video 7
    MCODEC_WMV2         = 510,  // Windows Media Video 8
    MCODEC_WMV3         = 520,  // Windows Media Video 9
    MCODEC_WVC1         = 530,  // Windows Media Video 9 Advanced Profile

    MCODEC_SVQ1         = 600,  // Sorenson Video 1
    MCODEC_SVQ3         = 610,  // Sorenson Video 3

    MCODEC_VP3          = 700,  // On2 VP3
    MCODEC_VP5          = 710,  // On2 VP5
    MCODEC_VP6          = 720,  // TrueMotion VP6
    MCODEC_VP6F         = 730,  // TrueMotion VP6 Flash

    MCODEC_RV10         = 800,  // RealVideo
    MCODEC_RV20         = 810,  // RealVideo G2
    MCODEC_RV30         = 820,  // RealVideo 8
    MCODEC_RV40         = 830,  // RealVideo 9, 10

    MCODEC_FLV          = 9000, // Flash Video
    MCODEC_THEORA       = 9010, // Theora
    MCODEC_HUFFYUV      = 9020, // Huffyuv
    MCODEC_CINEPAK      = 9030, // Cinepak
    MCODEC_INDEO2       = 9040, // Indeo Video 2
    MCODEC_INDEO3       = 9050, // Indeo Video 3
    MCODEC_MJPEG        = 9060, // Motion-JPEG

    // audio codec //////////////////////////////////////

    MCODEC_PCM          = 50000,// PCM
    MCODEC_DPCM         = 50100,// DPCM
    MCODEC_ADPCM        = 50200,// ADPCM

    MCODEC_MP2          = 50300,// MP2 (MPEG-1 Audio Layer II)
    MCODEC_MP3          = 50400,// MP3 (MPEG-1 Audio Layer 3)
    MCODEC_AAC          = 50500,// AAC (Advanced Audio Coding)

    MCODEC_AC3          = 50600,// AC3 (Dolby Digital)
    MCODEC_DTS          = 50700,// DTS (Digital Theater Systems)
    MCODEC_VORBIS       = 50800,// Vorbis
    MCODEC_DVAUDIO      = 50900,// DV Audio
    MCODEC_WMAV1        = 51000,// Windows Media Audio V1
    MCODEC_WMAV2,               // Windows Media Audio V2
    MCODEC_RA           = 51100,// RealAudio
    MCODEC_AMR          = 51200,// AMR (Adaptive Multi-Rate)
    MCODEC_ALAC         = 51300,// ALAC
    MCODEC_FLAC         = 51400,// FLAC
    MCODEC_QDM2         = 51500,// QDM2 (QDesign Music Codec)
    MCODEC_MACE         = 51600,// MACE (Macintosh Audio Compression and Expansion)
    MCODEC_SPEEX        = 51700,// Speex
    MCODEC_TTA          = 51800,// TTA (True Audio)
    MCODEC_WAVPACK      = 51900,// WavPack
};

#pragma mark -
#define DEFAULT_VOLUME  1.0
#define MAX_VOLUME      4.0

#define MIN_PLAY_RATE   0.5
#define MAX_PLAY_RATE   3.0

#define SUBTITLE_POSITION_AUTO                      100
#define SUBTITLE_POSITION_ON_MOVIE                  -1
#define SUBTITLE_POSITION_ON_LETTER_BOX             0
#define SUBTITLE_POSITION_ON_LETTER_BOX_1_LINE      1
#define SUBTITLE_POSITION_ON_LETTER_BOX_2_LINES     2
#define SUBTITLE_POSITION_ON_LETTER_BOX_3_LINES     3

#pragma mark -
#pragma mark notifications: movie
extern NSString* MMovieIndexedDurationNotification;
extern NSString* MMovieRateChangeNotification;
extern NSString* MMovieCurrentTimeNotification;
extern NSString* MMovieEndNotification;

#pragma mark -
#pragma mark notifications: etc
extern NSString* MPlaylistUpdatedNotification;

#pragma mark -
#pragma mark drag & drop
enum {
    DRAG_ACTION_NONE,
    DRAG_ACTION_PLAY_FILES,
    DRAG_ACTION_PLAY_URL,
    DRAG_ACTION_ADD_FILES,
    DRAG_ACTION_ADD_URL,
    DRAG_ACTION_REPLACE_SUBTITLE_FILE,
    DRAG_ACTION_REPLACE_SUBTITLE_URL,
    DRAG_ACTION_REORDER_PLAYLIST,
};

extern NSString* MPlaylistItemDataType;

#define MOVIST_DRAG_TYPES   movistDragTypes()

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark utilities

BOOL isSystemTiger();
BOOL isSystemLeopard();

NSArray* movistDragTypes();

float normalizedVolume(float volume);

NSString* NSStringFromMovieTime(float time);
NSString* NSStringFromSubtitlePosition(int position);
NSString* NSStringFromSubtitleEncoding(CFStringEncoding encoding);

NSString* codecName(int codecId);
NSString* codecDescription(int codecId);

void runAlertPanelForOpenError(NSError* error, NSURL* url);

unsigned int dragActionFromPasteboard(NSPasteboard* pboard, BOOL defaultPlay);

void initSubtitleEncodingMenu(NSMenu* menu, SEL action);

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#if defined(DEBUG)
    void TRACE(NSString* format, ...);
#else
    #define TRACE(...)
#endif

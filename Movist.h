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
    ASPECT_RATIO_DEFAULT,
    ASPECT_RATIO_4_3,           //    4 : 3 (TV)
    ASPECT_RATIO_16_9,          //   16 : 9 (HDTV)
    ASPECT_RATIO_1_85,          // 1.85 : 1 (Screen)
    ASPECT_RATIO_2_35,          // 2.35 : 1 (Screen)
};

#pragma mark error-codes
enum {
    ERROR_FILE_NOT_EXIST = 1,
    ERROR_FILE_NOT_READABLE,

    ERROR_SUBTITLE_NOT_FOUND,
    ERROR_UNSUPPORTED_SUBTITLE_TYPE,

    ERROR_VISUAL_CONTEXT_CREATE_FAILED,

    ERROR_FFMPEG_FILE_OPEN_FAILED,
    ERROR_FFMPEG_STREAM_INFO_NOT_FOUND,
    ERROR_FFMPEG_VIDEO_STREAM_NOT_FOUND,
    ERROR_FFMPEG_INVALID_VIDEO_DIMENSION,
    ERROR_FFMPEG_DECODER_NOT_FOUND,
    ERROR_FFMPEG_CODEC_OPEN_FAILED,
    ERROR_FFMPEG_FRAME_ALLOCATE_FAILED,
    ERROR_FFMPEG_SW_SCALER_INIT_FAILED,
    ERROR_FFMPEG_AUDIO_UNIT_CREATE_FAILED,
};

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
extern NSString* MMovieRectUpdateNotification;

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

void runAlertPanelForOpenError(NSError* error, NSURL* url);

unsigned int dragActionFromPasteboard(NSPasteboard* pboard, BOOL defaultPlay);

NSDictionary* subtitleTypesAndParsers();
void initSubtitleEncodingMenu(NSMenu* menu, SEL action);

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

#if defined(DEBUG)
    void TRACE(NSString* format, ...);
#else
    #define TRACE(...)
#endif

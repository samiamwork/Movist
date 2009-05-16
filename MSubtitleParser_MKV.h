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

#import "Movist.h"

#import "MSubtitleParser.h"

#if defined(__cplusplus)
namespace libebml {
    class StdIOCallback;
    class EbmlStream;
    class EbmlElement;
}
namespace libmatroska {
    class KaxCluster;
}
class StdIOCallback64;
#endif

@class MSubtitleParser_SUB;
@class MSubtitleParser_SRT;
@class MSubtitleParser_SSA;

@interface MSubtitleParser_MKV : MSubtitleParser
{
    NSMutableDictionary* _subtitles;

#if defined(__cplusplus)
    //libebml::StdIOCallback* _file;    // libebml::StdIOCallback has 32-bit-fseek() problem.
    StdIOCallback64* _file;             // so, we use custom IO class for file operations.
    libebml::EbmlStream* _stream;
    libebml::EbmlElement* _level0;
    libebml::EbmlElement* _level1;
    libebml::EbmlElement* _level2;
    libebml::EbmlElement* _level3;
    libmatroska::KaxCluster* _cluster;
    uint64_t _timecodeScale;
    int _upperLevel;
#endif

    MSubtitleParser_SUB* _parser_SUB;
    MSubtitleParser_SRT* _parser_SRT;
    MSubtitleParser_SSA* _parser_SSA;

    // current parsing info
    NSMutableAttributedString* _string;
    NSImage* _image;
    int _imageBaseWidth;
    float _beginTime;
    BOOL _quitRequested;
}

+ (void)quitThreadForSubtitleURL:(NSURL*)subtitleURL;

- (id)initWithURL:(NSURL*)subtitleURL;
- (NSArray*)parseWithOptions:(NSDictionary*)options error:(NSError**)error;

@end


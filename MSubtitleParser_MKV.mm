//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//
//  This _file is part of Movist.
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

#import "MSubtitleParser_MKV.h"

#import "MSubtitleParser_SRT.h"
#import "MSubtitleParser_SSA.h"

#import "ebml/StdIOCallback.h"
#import "ebml/EbmlHead.h"
#import "ebml/EbmlStream.h"
#import "ebml/EbmlMaster.h"
#import "ebml/EbmlVoid.h"
#import "ebml/EbmlCrc32.h"
#import "matroska/KaxBlock.h"
#import "matroska/KaxCluster.h"
#import "matroska/KaxInfo.h"
#import "matroska/KaxInfoData.h"
#import "matroska/KaxSegment.h"
#import "matroska/KaxTracks.h"

#import <string>
#import <vector>

using namespace libmatroska;
using namespace libebml;

namespace { // unnamed
    std::string format_timecode(int64_t timecode, unsigned int precision = 9)
    {
        char s[256];
        sprintf(s, "%02d:%02d:%02d",
                (int)( timecode / 60 / 60 / 1000000000),
                (int)((timecode      / 60 / 1000000000) % 60),
                (int)((timecode           / 1000000000) % 60));

        std::string result(s);

        if (9 < precision) {
            precision = 9;
        }
        if (precision) {
            sprintf(s, ".%09d", (int)(timecode % 1000000000));
            result += s;
        }
        return result;
    }

    #define is_id(e, ref) (e->Generic().GlobalId == ref::ClassInfos.GlobalId)
}   // unnamed namespace

////////////////////////////////////////////////////////////////////////////////

@implementation MSubtitleParser_MKV

- (id)initWithURL:(NSURL*)subtitleURL
{
    if (self = [super initWithURL:subtitleURL]) {
        _parser_SRT = [[MSubtitleParser_SRT alloc] initWithURL:nil];
        _parser_SSA = [[MSubtitleParser_SSA alloc] initWithURL:nil];
    }
    return self;
}

- (void)dealloc
{
    [_parser_SSA release];
    [_parser_SRT release];
    [super dealloc];
}

- (MSubtitle*)addSubtitleWithNumber:(int)number
{
    MSubtitle* subtitle = [[MSubtitle alloc] initWithURL:_subtitleURL];
    [_subtitles setObject:subtitle forKey:[NSNumber numberWithInt:number]];
    return [subtitle autorelease];
}

- (MSubtitle*)subtitleWithNumber:(int)number
{
    return [_subtitles objectForKey:[NSNumber numberWithInt:number]];
}

- (NSArray*)allSubtitles
{
    NSMutableArray* numbers = [NSMutableArray arrayWithArray:[_subtitles allKeys]];
    [numbers sortUsingSelector:@selector(compare:)];

    NSMutableArray* subtitles = [NSMutableArray arrayWithCapacity:[numbers count]];

    int track = 1;
    NSNumber* num;
    MSubtitle* sub;
    NSEnumerator* e = [numbers objectEnumerator];
    while (num = [e nextObject]) {
        sub = [_subtitles objectForKey:num];
        [sub setTrackName:(1 == [numbers count]) ?
                           NSLocalizedString(@"Subtitle Track", nil) :
                           [NSString stringWithFormat:@"%@ %d",
                            NSLocalizedString(@"Subtitle Track", nil), track]];
        [sub setEmbedded:TRUE];
        [subtitles addObject:sub];
        track++;
    }
    return subtitles;
}

////////////////////////////////////////////////////////////////////////////////

//#define TRACE_PARSING
#if defined(TRACE_PARSING)
    static void TRACE_ELEMENT(EbmlElement* element, int level,
                              NSString* format, ...)
    {
        va_list arg;
        va_start(arg, format);

        char s[256] = { '|', };
        memset(&s[1], ' ', level * 2);
        //int64_t position = (element) ? (int64_t)element->GetElementPosition() : -1;
        NSLogv([NSString stringWithFormat:@"%s+ %@", s, format], arg);

        va_end(arg);
    }
#else
    #define TRACE_ELEMENT(...)
#endif

struct master_sorter_t {
    int _index;
    int64_t _pos;

    master_sorter_t(int index, int64_t pos) : _index(index), _pos(pos) {}
    bool operator<(const master_sorter_t& cmp) const { return _pos < cmp._pos; }
};

- (void)readMaster:(EbmlMaster*)master
{
    master->Read(*_stream, _level1->Generic().Context, _upperLevel, _level3, true);
    if (0 < master->ListSize()) {
        // sort master
        EbmlMaster& m = *master;
        std::vector<master_sorter_t> sort_me;
        for (int i = 0; i < m.ListSize(); i++) {
            sort_me.push_back(master_sorter_t(i, m[i]->GetElementPosition()));
        }
        std::sort(sort_me.begin(), sort_me.end());

        std::vector<EbmlElement*> tmp;
        for (int i = 0; i < sort_me.size(); i++) {
            tmp.push_back(m[sort_me[i]._index]);
        }
        m.RemoveAll();

        for (int i = 0; i < tmp.size(); i++) {
            m.PushElement(*tmp[i]);
        }
    }
}

- (void)parseInfo
{
    // General info about this Matroska _file
    TRACE_ELEMENT(_level1, 1, @"Segment Information");

    _upperLevel = 0;
    EbmlMaster* master = static_cast<EbmlMaster*>(_level1);
    [self readMaster:master];

    for (int i1 = 0; i1 < master->ListSize(); i1++) {
        _level2 = (*master)[i1];
        if (is_id(_level2, KaxTimecodeScale)) {
            KaxTimecodeScale& tcs = *static_cast<KaxTimecodeScale*>(_level2);
            _timecodeScale = uint64(tcs);
            //TRACE_ELEMENT(_level2, 2, @"Timecode scale: %llu", _timecodeScale]);
        }
    }
}

- (void)parseTracks
{
    TRACE_ELEMENT(_level1, 1, @"Segment Tracks");

    _upperLevel = 0;
    EbmlMaster* master1 = static_cast<EbmlMaster*>(_level1);
    [self readMaster:master1];

    for (int i1 = 0; i1 < master1->ListSize(); i1++) {
        _level2 = (*master1)[i1];
        if (is_id(_level2, KaxTrackEntry)) {
            int trackNumber;
            MSubtitle* subtitle = nil;

            EbmlMaster* master2 = static_cast<EbmlMaster*>(_level2);
            for (int i2 = 0; i2 < master2->ListSize(); i2++) {
                _level3 = (*master2)[i2];

                if (is_id(_level3, KaxTrackNumber)) {
                    KaxTrackNumber& num = *static_cast<KaxTrackNumber*>(_level3);
                    trackNumber = int(uint64(num));
                }
                else if (is_id(_level3, KaxTrackType)) {
                    KaxTrackType& type = *static_cast<KaxTrackType*>(_level3);
                    if (uint8(type) != track_subtitle) {
                        subtitle = nil;
                    }
                    else {
                        TRACE_ELEMENT(_level2, 2, @"Track");
                        TRACE_ELEMENT(_level3, 3, @"Track Type: subtitles");
                        subtitle = [self addSubtitleWithNumber:trackNumber];
                    }
                }
                else if (subtitle && is_id(_level3, KaxTrackName)) {
                    KaxTrackName& name = *static_cast<KaxTrackName*>(_level3);
                    char s[256];
                    sprintf(s, "%s", ((const UTFstring&)name).c_str());
                    [subtitle setName:[NSString stringWithUTF8String:s]];
                    TRACE_ELEMENT(_level3, 3, @"Name: %@", [subtitle name]);
                }
                else if (subtitle && is_id(_level3, KaxCodecID)) {
                    KaxCodecID& codecID = *static_cast<KaxCodecID*>(_level3);
                    NSString* codec = [NSString stringWithUTF8String:std::string(codecID).c_str()];
                    int index = ([codec hasPrefix:@"S_TEXT/"]) ?  (2 + 4 + 1) : // remove "S_TEXT/"
                                ([codec hasPrefix:@"S_IMAGE/"]) ? (2 + 5 + 1) : // remove "S_IMAGE/"
                                /* "S_VOBSUB", "S_KATE", ... */   (2);          // remove "S_"
                    [subtitle setType:[codec substringFromIndex:index]];
                    TRACE_ELEMENT(_level3, 3, @"CodecID: %@", codec);
                }
                else if (subtitle && is_id(_level3, KaxCodecPrivate)) {
                    KaxCodecPrivate& codecPrivate = *static_cast<KaxCodecPrivate*>(_level3);
                    if (0 < codecPrivate.GetSize()) {
                        const char* cps = (const char*)(codecPrivate.GetBuffer());
                        NSString* s = [NSString stringWithUTF8String:std::string(cps).c_str()];
                        if (s) {
                            [_parser_SSA setStyles:s forSubtitleNumber:trackNumber];
                        }
                    }
                    TRACE_ELEMENT(_level3, 3, @"CodecPrivate: ...");
                }
                else if (subtitle && is_id(_level3, KaxTrackLanguage)) {
                    KaxTrackLanguage& language = *static_cast<KaxTrackLanguage*>(_level3);
                    [subtitle setLanguage:[NSString stringWithUTF8String:std::string(language).c_str()]];
                    TRACE_ELEMENT(_level3, 3, @"Language: %@", [subtitle language]);
                }
            }
        }
    }
}

- (void)parseBlockGroup
{
    BOOL blockGroupPrinted = FALSE;
    MSubtitle* subtitle = nil;
    char text[1024];

    EbmlMaster* master2 = static_cast<EbmlMaster*>(_level2);
    for (int i2 = 0; i2 < master2->ListSize(); i2++) {
        _level3 = (*master2)[i2];
        if (is_id(_level3, KaxBlock)) {
            KaxBlock& block = *static_cast<KaxBlock*>(_level3);
            block.SetParent(*_cluster);

            subtitle = [self subtitleWithNumber:(int)block.TrackNum()];
            if (subtitle) {
                if (!blockGroupPrinted) {
                    blockGroupPrinted = TRUE;
                    TRACE_ELEMENT(_level2, 2, @"Block Group");
                }
                TRACE_ELEMENT(_level3, 3,
                              @"Block: track#=%u, %u frame(s), timecode=%f (%s)",
                              block.TrackNum(), block.NumberFrames(),
                              ((float)block.GlobalTimecode() / 1000000000.0),
                              format_timecode(block.GlobalTimecode()).c_str());

                NSString* type = [subtitle type];
                if ([type isEqualToString:@"VOBSUB"]) {
                }
                else if ([type isEqualToString:@"BMP"]) {
                }
                else if ([type isEqualToString:@"KATE"]) {
                }
                else {
                    DataBuffer& data = block.GetBuffer(0);  // only one!
                    memcpy(text, data.Buffer(), data.Size());
                    text[data.Size()] = '\0';

                    NSString* s = [NSString stringWithUTF8String:text];
                    if ([type isEqualToString:@"UTF8"]) {
                        _string = [_parser_SRT parseSubtitleString:s];
                    }
                    else if ([type isEqualToString:@"SSA"] ||
                             [type isEqualToString:@"ASS"]) {
                        _string = [_parser_SSA parseSubtitleString_MKV:s
                                                     forSubtitleNumber:(int)block.TrackNum()];
                    }
                    else if ([type isEqualToString:@"USF"]) {
                        _string = [_parser_SRT parseSubtitleString:s];
                    }
                    TRACE_ELEMENT(0, 4, @"Subtitle: \"%@\"", [_string string]);
                }
                _beginTime = (float)block.GlobalTimecode() / 1000000000.0;
            }
        }
        else if (subtitle && is_id(_level3, KaxBlockDuration)) {
            KaxBlockDuration& duration = *static_cast<KaxBlockDuration*>(_level3);
            if (_string) {
                float d = (((float)uint64(duration)) * _timecodeScale / 1000000.0) / 1000.0;
                [subtitle addString:_string beginTime:_beginTime endTime:_beginTime + d];
                _string = nil;
            }
            TRACE_ELEMENT(_level3, 3, @"Block Duration: %llu.%llu ms",
                                       (uint64(duration) * _timecodeScale / 1000000),
                                       (uint64(duration) * _timecodeScale % 1000000));
        }
    }
}

- (void)parseCluster
{
    _cluster = (KaxCluster*)_level1;

    _upperLevel = 0;
    EbmlMaster* master1 = static_cast<EbmlMaster*>(_level1);
    [self readMaster:master1];

    for (int i1 = 0; i1 < master1->ListSize(); i1++) {
        _level2 = (*master1)[i1];
        if (is_id(_level2, KaxClusterTimecode)) {
            KaxClusterTimecode& ctc = *static_cast<KaxClusterTimecode*>(_level2);
            int64_t clusterTimeCode = uint64(ctc);
            _cluster->InitTimecode(clusterTimeCode, _timecodeScale);
            //TRACE_ELEMENT(_level2, 2, @"cluster timecode: %f sec",
            //              ((float)clusterTimeCode * (float)_timecodeScale / 1000000000.0));
        }
        else if (is_id(_level2, KaxBlockGroup)) {
            [self parseBlockGroup];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// custom IO class

class StdIOCallback64 : public IOCallback {
public:
    StdIOCallback64(NSString* path, BOOL readOnly = TRUE)
    { _file = ::open([path UTF8String], (readOnly) ? O_RDONLY : O_RDWR); }
	virtual ~StdIOCallback64() { close(); }

private:
    int _file;  // file descriptor
public:
    virtual uint64 getFilePointer() { return ::lseek(_file, 0, SEEK_CUR); }
    virtual void setFilePointer(int64_t offset, seek_mode mode = seek_beginning);
    virtual uint32 read(void* p, size_t size) { return ::read(_file, p, size); }
    virtual size_t write(const void* p, size_t size) { return ::write(_file, p, size); }
    virtual void close() { ::close(_file); }
};

void StdIOCallback64::setFilePointer(int64_t offset, seek_mode mode)
{
    switch (mode) {
        case seek_beginning : ::lseek(_file, offset, SEEK_SET);     break;
        case seek_end       : ::lseek(_file, offset, SEEK_END);     break;
        default :
            ::lseek(_file, lseek(_file, 0, SEEK_END) + offset, SEEK_SET);
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL)initEbmlStream
{
    NSString* path = [_subtitleURL path];
    //_file = new StdIOCallback([path UTF8String], MODE_READ);
    _file = new StdIOCallback64(path);
    _stream = new EbmlStream(*_file);
    _level0 = _level1 = _level2 = _level3 = 0;
    _timecodeScale = 1000000;   // default scale

    // Find the EbmlHead element. Must be the first one.
    _level0 = _stream->FindNextID(EbmlHead::ClassInfos, 0xFFFFFFFFL);
    if (!_level0) {
        TRACE(@"No EBML Head found.");
        delete _stream, _stream = 0;
        delete _file, _file = 0;
        return FALSE;
    }

    // skip header
    TRACE_ELEMENT(_level0, 0, @"EBML Head");
    _level0->SkipData(*_stream, _level0->Generic().Context);
    delete _level0, _level0 = 0;

    // find first segment
    _level0 = _stream->FindNextID(KaxSegment::ClassInfos, 0xFFFFFFFFFFFFFFFFLL);
    if (!_level0) {
        delete _stream, _stream = 0;
        delete _file, _file = 0;
        return FALSE;
    }
    return TRUE;
}

- (void)cleanupEbmlStream
{
    delete _level1, _level1 = 0;
    delete _level0, _level0 = 0;
    delete _stream, _stream = 0;
    delete _file, _file = 0;
}

- (NSArray*)parseWithOptions:(NSDictionary*)options error:(NSError**)error
{
    _subtitles = [NSMutableDictionary dictionaryWithCapacity:1];

    try {
        if (![self initEbmlStream]) {
            return [self allSubtitles];
        }

        // find tracks and get subtitles
        _upperLevel = 0;
        int64_t endOfLevel0 = _level0->GetElementPosition() + _level0->HeadSize() + _level0->GetSize();
        _level1 = _stream->FindNextElement(_level0->Generic().Context, _upperLevel, 0xFFFFFFFFL, true);
        while (_level1 && _upperLevel <= 0) {
            if (is_id(_level1, KaxInfo)) {
                [self parseInfo];       // update timecode-scale
            }
            else if (is_id(_level1, KaxTracks)) {
                [self parseTracks];     // find subtitle tracks
                if ([_subtitles count] == 0) {      // if no subtitle track found,
                    delete _level1, _level1 = 0;    // then, need not read more.
                    break;
                }
            }
            else if (is_id(_level1, KaxCluster)) {
                [self parseCluster];    // get subtitles
            }

            if (_level0->IsFiniteSize() && endOfLevel0 <= _file->getFilePointer()) {
                delete _level1, _level1 = 0;
                break;
            }

            if (0 < _upperLevel) {
                if (0 < --_upperLevel) {
                    break;
                }
                delete _level1, _level1 = 0;
                _level1 = _level2;
                continue;
            }
            else if (_upperLevel < 0) {
                if (++_upperLevel < 0) {
                    break;
                }
            }

            _level1->SkipData(*_stream, _level1->Generic().Context);
            delete _level1, _level1 = 0;
            _level1 = _stream->FindNextElement(_level0->Generic().Context, _upperLevel, 0xFFFFFFFFL, true);
        }
        [self cleanupEbmlStream];
    }
    catch (...) {
        TRACE(@"Caught exception");
        [self cleanupEbmlStream];
    }
    
    return [self allSubtitles];
}

@end

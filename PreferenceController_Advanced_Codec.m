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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "MMovie_QuickTime.h"
#import "MMovie_FFmpeg.h"

@implementation PreferenceController (Advanced_CodecBinding)

- (void)initCodecBinding
{
    // used for listing in GUI
    #define MCODEC_ID(codec) [NSNumber numberWithInt:MCODEC_##codec]
    _codecIds = [[NSArray alloc] initWithObjects:
        MCODEC_ID(MPEG1),MCODEC_ID(MPEG2),MCODEC_ID(MPEG4),
        MCODEC_ID(DIV1), MCODEC_ID(DIV2), MCODEC_ID(DIV3), MCODEC_ID(DIV4),
        MCODEC_ID(DIV5), MCODEC_ID(DIV6), MCODEC_ID(DIVX), MCODEC_ID(DX50),
        MCODEC_ID(XVID), MCODEC_ID(MP4V), MCODEC_ID(MPG4), MCODEC_ID(MP42),
        MCODEC_ID(MP43), MCODEC_ID(MP4S), MCODEC_ID(M4S2), MCODEC_ID(AP41),
        MCODEC_ID(RMP4), MCODEC_ID(SEDG), MCODEC_ID(FMP4), MCODEC_ID(BLZ0),
        MCODEC_ID(H263), MCODEC_ID(H264), MCODEC_ID(AVC1), MCODEC_ID(X264),
        MCODEC_ID(VC1),
        MCODEC_ID(WMV1), MCODEC_ID(WMV2), MCODEC_ID(WMV3), MCODEC_ID(WVC1),
        MCODEC_ID(SVQ1), MCODEC_ID(SVQ3),
        MCODEC_ID(VP3),  MCODEC_ID(VP5),  MCODEC_ID(VP6),  MCODEC_ID(VP6F),
        MCODEC_ID(RV10), MCODEC_ID(RV20), MCODEC_ID(RV30), MCODEC_ID(RV40),
        MCODEC_ID(FLV),  MCODEC_ID(THEORA), MCODEC_ID(HUFFYUV),
        MCODEC_ID(CINEPAK), MCODEC_ID(INDEO2), MCODEC_ID(INDEO3),
        MCODEC_ID(MJPEG),
        MCODEC_ID(ETC_),
        nil];

    NSTableColumn* column = [_codecBindingTableView tableColumnWithIdentifier:@"decoder"];
    NSPopUpButtonCell* cell = [column dataCell];
    [cell addItemWithTitle:[MMovie_QuickTime name]];
    [cell addItemWithTitle:[MMovie_FFmpeg name]];
    NSMenu* menu = [cell menu];
    [[menu itemAtIndex:0] setImage:[NSImage imageNamed:@"QuickTime16"]];
    [[menu itemAtIndex:1] setImage:[NSImage imageNamed:@"FFMPEG16"]];
}

- (int)numberOfRowsInCodecBindingTableView { return [_codecIds count]; }

- (id)objectValueForCodecBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    if ([[tableColumn identifier] isEqualToString:@"codec"]) {
        return videoCodecName([[_codecIds objectAtIndex:rowIndex] intValue]);
    }
    else if ([[tableColumn identifier] isEqualToString:@"desc"]) {
        return videoCodecDescription([[_codecIds objectAtIndex:rowIndex] intValue]);
    }
    else {  // @"decoder"
        int codecId = [[_codecIds objectAtIndex:rowIndex] intValue];
        int decoder = [_defaults defaultDecoderForCodecId:codecId];
        return [NSNumber numberWithInt:decoder];
    }
}

- (void)setObjectValue:(id)object
forCodecBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    [_defaults setDefaultDecoder:[(NSNumber*)object intValue]
                      forCodecId:[[_codecIds objectAtIndex:rowIndex] intValue]];
}

enum {
    CODEC_BINDING_ACTION_ALL_TO_QUICKTIME,
    CODEC_BINDING_ACTION_ALL_TO_FFMPEG,
    CODEC_BINDING_ACTION_ALL_MPEG4_TO_QUICKTIME,
    CODEC_BINDING_ACTION_ALL_MPEG4_TO_FFMPEG,
    CODEC_BINDING_ACTION_MOVIST_DEFAULT,
};

- (IBAction)codecBindingAction:(id)sender
{
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Codec Binding"];
    SEL action = @selector(codecBindingActions:);

    NSMenuItem* item;
    item = [menu addItemWithTitle:NSLocalizedString(@"Set all to QuickTime", nil)
                           action:action keyEquivalent:@""]; [item setTarget:self];
                     [item setTag:CODEC_BINDING_ACTION_ALL_TO_QUICKTIME];
    item = [menu addItemWithTitle:NSLocalizedString(@"Set all to FFmpeg", nil)
                           action:action keyEquivalent:@""]; [item setTarget:self];
                     [item setTag:CODEC_BINDING_ACTION_ALL_TO_FFMPEG];
    [menu addItem:[NSMenuItem separatorItem]];
    item = [menu addItemWithTitle:NSLocalizedString(@"Set all MPEG-4 to QuickTime", nil)
                           action:action keyEquivalent:@""]; [item setTarget:self];
                     [item setTag:CODEC_BINDING_ACTION_ALL_MPEG4_TO_QUICKTIME];
    item = [menu addItemWithTitle:NSLocalizedString(@"Set all MPEG-4 to FFmpeg", nil)
                           action:action keyEquivalent:@""]; [item setTarget:self];
                     [item setTag:CODEC_BINDING_ACTION_ALL_MPEG4_TO_FFMPEG];
    [menu addItem:[NSMenuItem separatorItem]];
    item = [menu addItemWithTitle:NSLocalizedString(@"Set to Movist default", nil)
                           action:action keyEquivalent:@""]; [item setTarget:self];
                     [item setTag:CODEC_BINDING_ACTION_MOVIST_DEFAULT];

    NSRect rect = [sender frame];
    rect.origin.x += 10;
    rect.origin.y -= rect.size.height + 1;
    NSPopUpButtonCell* cell = [[[NSPopUpButtonCell alloc] initTextCell:@""] autorelease];
    [cell setMenu:menu];
    [cell selectItemAtIndex:-1];    // deselct all
    [cell performClickWithFrame:rect inView:[sender superview]];
}

- (IBAction)codecBindingActions:(id)sender
{
    int tag = [sender tag];
    if (tag == CODEC_BINDING_ACTION_ALL_TO_QUICKTIME) {
        [_defaults setDefaultDecoder:DECODER_QUICKTIME forCodecId:-1];
    }
    else if (tag == CODEC_BINDING_ACTION_ALL_TO_FFMPEG) {
        [_defaults setDefaultDecoder:DECODER_FFMPEG forCodecId:-1];
    }
    else if (tag == CODEC_BINDING_ACTION_ALL_MPEG4_TO_QUICKTIME ||
             tag == CODEC_BINDING_ACTION_ALL_MPEG4_TO_FFMPEG) {
        NSMutableIndexSet* set = [NSMutableIndexSet indexSet];

        NSNumber* num;
        NSDictionary* dict = [_defaults dictionaryForKey:MDefaultCodecBindingKey];
        NSEnumerator* enumerator = [[dict allKeys] objectEnumerator];
        while (num = [enumerator nextObject]) {
            if ([num intValue] / MCODEC_MPEG4 == 1) {  // all MPEG4s are in 100 ~ 199.
                [set addIndex:[num intValue]];
            }
        }
        int decoder = (tag == CODEC_BINDING_ACTION_ALL_MPEG4_TO_QUICKTIME) ?
                                            DECODER_QUICKTIME : DECODER_FFMPEG;
        [_defaults setDefaultDecoder:decoder forCodecIdSet:set];
    }
    else if (tag == CODEC_BINDING_ACTION_MOVIST_DEFAULT) {
        [_defaults removeObjectForKey:MDefaultCodecBindingKey];
    }

    [_codecBindingTableView reloadData];
}
@end

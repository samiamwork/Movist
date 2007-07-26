//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@interface TimeTextField : NSTextField {} @end

@interface SeekSlider : NSSlider
{
}

- (BOOL)repeatEnabled;
- (float)repeatBeginning;
- (float)repeatEnd;
- (void)setRepeatBeginning:(float)beginning;
- (void)setRepeatEnd:(float)end;
- (void)clearRepeat;

@end

@interface MainSeekSlider : SeekSlider {} @end
@interface FSSeekSlider : SeekSlider {} @end

@interface MainVolumeSlider : NSSlider {} @end
@interface FSVolumeSlider : NSSlider {} @end

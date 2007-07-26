//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovieOSD.h"

enum { VOLUME_BAR, SEEK_BAR };

@interface MBarOSD : MMovieOSD
{
    int _type;
    float _value;
    float _minValue;
    float _maxValue;
}

- (void)setType:(int)type value:(float)value
       minValue:(float)minValue maxValue:(float)maxValue;

@end

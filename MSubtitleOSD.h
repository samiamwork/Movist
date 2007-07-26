//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MTextOSD.h"

@interface MSubtitleOSD : MTextOSD
{
    NSMutableDictionary* _strings;
}

- (void)setString:(NSMutableAttributedString*)string forName:(NSString*)name;

@end

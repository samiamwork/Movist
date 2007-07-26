//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "MMovie.h"

#import <QTKit/QTKit.h>

@interface MTrack_QuickTime : MTrack
{
    QTTrack* _qtTrack;
}

- (id)initWithQTTrack:(QTTrack*)qtTrack;

- (NSString*)name;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface MMovie_QuickTime : MMovie
{
    QTVisualContextRef _visualContext;
    QTMovie* _qtMovie;
}

@end

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

// author: macnow@hoax.pl

#import "Movist.h"

#import "MSubtitleParser.h"

@interface MSubtitleParser_TXT : MSubtitleParser
{
    NSString* _source;
    NSRange _sourceRange;
	
    NSCharacterSet* _fontDelimSet;
	
    NSMutableArray* _subtitles;
}

- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error;

- (NSMutableAttributedString*)parseSubtitleString:(NSString*)string;

@end
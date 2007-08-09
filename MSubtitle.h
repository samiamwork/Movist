//
//  Movist
//
//  Created by dckim <cocoable@gmail.com>
//  Copyright 2006 cocoable. All rights reserved.
//

#import "Movist.h"

@interface MSubtitle : NSObject
{
    NSString* _type;
    NSString* _name;
    BOOL _enabled;
    NSMutableArray* _strings;   // for MSubtitleString

    // for performance of -nextString:
    int _lastLoadedIndex;
    NSAttributedString* _lastLoadedString;
    NSMutableAttributedString* _emptyString;
}

+ (NSArray*)subtitleTypes;
+ (Class)subtitleParserClassForType:(NSString*)type;

#pragma mark -
- (id)initWithType:(NSString*)type;
- (NSString*)type;
- (NSString*)name;
- (BOOL)isEmpty;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (void)setName:(NSString*)name;
- (void)addString:(NSMutableAttributedString*)string time:(float)time;
- (NSMutableAttributedString*)nextString:(float)time;
- (void)clearCache;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@protocol MSubtitleParser

+ (NSDictionary*)defaultOptions;
- (NSArray*)parseString:(NSString*)string options:(NSDictionary*)options
                  error:(NSError**)error;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSString (MSubtitleParser)

- (NSRange)rangeOfString:(NSString*)s range:(NSRange)range;
- (NSRange)rangeOfString:(NSString*)s rangePtr:(NSRange*)range;
- (NSRange)tokenRangeForDelimiterSet:(NSCharacterSet*)delimiterSet rangePtr:(NSRange*)range;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface NSMutableString (MSubtitleParser)

- (void)removeLeftWhitespaces;
- (void)removeRightWhitespaces;
- (void)removeNewLineCharacters;
- (unsigned int)replaceOccurrencesOfString:(NSString*)target
                                withString:(NSString*)replacement;

@end

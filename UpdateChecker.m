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

#import "UpdateChecker.h"
#import "MSubtitle.h"   // for NSString (MSubtitleParser) extension

NSString* kMovistHomepageURLString = @"http://github.com/samiamwork/Movist/downloads";
NSString* const kMovistUpdateErrorDomain = @"MovistUpdateErrorDomain";

@implementation UpdateChecker

- (id)init
{
    if (self = [super init]) {
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        CURRENT_VERSION = [[infoDict objectForKey:@"CFBundleVersion"] retain];
		_homepageURL = [[NSURL alloc] initWithString:kMovistHomepageURLString];
    }
    return self;
}

- (void)dealloc
{
    [CURRENT_VERSION release];
    [_downloadURL release];
	[_homepageURL release];
    [_newVersion release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (NSString*)newVersion { return _newVersion; }
- (NSURL*)homepageURL { return _homepageURL; }
- (NSURL*)downloadURL { return _downloadURL; }

- (int)checkUpdate:(NSError**)error
{
	NSString* address = @"http://theidiotprojectdownloads.s3.amazonaws.com/latest";
	NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:address]
                                         options:NSMappedRead | NSUncachedRead
                                           error:error];
    if (!data || [data length] == 0) {
		if(error != NULL)
			*error = [NSError errorWithDomain:kMovistUpdateErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"No response received from update server", @"No response received from update server"), NSLocalizedDescriptionKey, nil]];
        return UPDATE_CHECK_FAILED;
    }

    [_newVersion release];
	_newVersion = nil;

    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* parts = [string componentsSeparatedByString:@" "];
	[string release];
	if(parts == nil || [parts count] != 2)
	{
		if(error != NULL)
			*error = [NSError errorWithDomain:kMovistUpdateErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Could not understand update server response", @"Could not understand update server response"), NSLocalizedDescriptionKey, nil]];
		return UPDATE_CHECK_FAILED;
	}
	NSString* versionString = [parts objectAtIndex:0];
	NSString* downloadString = [[parts objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if([versionString isEqualToString:CURRENT_VERSION])
	{
		return NO_UPDATE_AVAILABLE;
	}
	NSArray* thisVersionValues = [CURRENT_VERSION componentsSeparatedByString:@"."];
	NSArray* newVersionValues = [versionString componentsSeparatedByString:@"."];
	int i;
	int dotCount = [thisVersionValues count] < [newVersionValues count] ? [thisVersionValues count] : [newVersionValues count];
	for(i = 0; i < dotCount; i++)
	{
		int thisValue = [(NSString*)[thisVersionValues objectAtIndex:i] intValue];
		int newValue = [(NSString*)[newVersionValues objectAtIndex:i] intValue];
		if(thisValue > newValue)
		{
			return NO_UPDATE_AVAILABLE;
		}
		else if(thisValue < newValue)
		{
			_downloadURL = [[NSURL URLWithString:downloadString] retain];
			_newVersion = [versionString retain];
			return NEW_VERSION_AVAILABLE;
		}
	}
	// If the number of dots in the version differs between the two versions
	// assume the one with more dots is more recent (since they've been determined equal so far).
	if([thisVersionValues count] < [newVersionValues count])
	{
		_downloadURL = [[NSURL URLWithString:downloadString] retain];
		return NEW_VERSION_AVAILABLE;
	}
	else if([thisVersionValues count] > [newVersionValues count])
	{
		return NO_UPDATE_AVAILABLE;
	}

    return NO_UPDATE_AVAILABLE;
}

@end

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

#import "PreferenceController.h"
#import "UserDefaults.h"

#import "MMovie.h"

@implementation PreferenceController (Advanced_FileBinding)

- (void)initFileBinding
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    LSRegisterURL((CFURLRef)[NSURL URLWithString:appPath], true);

    // file extensions
    _fileExtensions = [[NSArray alloc] initWithArray:[MMovie fileExtensions]];

    // file extension description
    NSMutableArray* descs = [NSMutableArray arrayWithCapacity:[_fileExtensions count]];
    NSDictionary* ext, *type;
    NSDictionary* dict = [[NSBundle mainBundle] infoDictionary];
    NSArray* types = [dict objectForKey:@"CFBundleDocumentTypes"];
    NSEnumerator* extEnumerator = [_fileExtensions objectEnumerator];
    while (ext = [extEnumerator nextObject]) {
        NSEnumerator* typeEnumerator = [types objectEnumerator];
        while (type = [typeEnumerator nextObject]) {
            if ([[type objectForKey:@"CFBundleTypeExtensions"] containsObject:ext]) {
                [descs addObject:[type objectForKey:@"CFBundleTypeName"]];
                break;
            }
        }
    }
    _fileExtensionDescriptions = [descs retain];

    // available applications
    NSMutableArray* apps = [NSMutableArray arrayWithCapacity:2];
    NSArray* allApps;
    _LSCopyAllApplicationURLs(&allApps);
    NSURL* appURL;
    NSEnumerator* appEnumerator = [allApps objectEnumerator];
    while (appURL = [appEnumerator nextObject]) {
        NSString* ext;
        NSEnumerator* extEnumerator = [_fileExtensions objectEnumerator];
        while (ext = [extEnumerator nextObject]) {
            NSBundle* bundle = [NSBundle bundleWithPath:[appURL path]];
            NSDictionary* dict = [bundle infoDictionary];
            NSDictionary* type;
            NSArray* types = [dict objectForKey:@"CFBundleDocumentTypes"];
            NSEnumerator* typeEnumerator = [types objectEnumerator];
            while (type = [typeEnumerator nextObject]) {
                NSArray* exts = [type objectForKey:@"CFBundleTypeExtensions"];
                NSString* ex;
                NSEnumerator* exEnumerator = [exts objectEnumerator];
                while (ex = [exEnumerator nextObject]) {
                    if (NSOrderedSame == [ext caseInsensitiveCompare:ex]) {
                        break;
                    }
                }
                if (ex) {
                    break;
                }
            }
            if (type) {
                break;
            }
        }
        if (ext) {
            [apps addObject:[appURL path]];
        }
    }
/*
    // available applications
    NSArray* contentTypes = [NSArray arrayWithObjects:
         @"public.video",   // kUTTypeVideo:
         @"public.avi",     // .avi, .vfw, 'Vfw ', video/avi, video/msvideo, video/x-msvideo
         @"public.mpeg",    // kUTTypeMPEG: 'MPG ', 'MPEG', .mpg, .mpeg, .m75, .m15,
                            // video/mpg, video/mpeg, video/x-mpg, video/x-mpeg
         @"public.mpeg-4",  // kUTTypeMPEG4: 'mpg4', .mp4, video/mp4, video/mp4v
         @"com.apple.quicktime-movie",              // kUTTypeQuickTimeMovie: 'MooV', .mov, .qt, video/quicktime
         @"com.microsoft.advanced-systems-format",  // .asf, 'ASF_', video/x-ms-asf
         @"com.microsoft.windows-media-wm",         // .wm, video/x-ms-wm
         @"com.microsoft.windows-media-wmv",        // .wmv, video/x-ms-wmv
         @"com.microsoft.windows-media-wmp",        // .wmp, video/x-ms-wmp
         @"com.microsoft.windows-media-wmx",        // .wmx, video-x-ms-wmx
         @"com.microsoft.windows-media-wvx",        // .wvx, video-x-ms-wvx
         @"com.microsoft.advanced-stream-redirector",//.asx, 'ASX_', video/x-ms-asx
         @"com.real.realmedia", // .rm, 'PNRM', application/vnd.rn-realmedia
         @"public.3gpp",        // .3gp, .3gpp, '3gpp', video/3gpp, audio/3gpp
         @"public.3gpp2",       // .3g2 , .3gp2 , '3gp2', video/3gpp2, audio/3gpp2
         nil];

    NSMutableArray* apps = [NSMutableArray arrayWithCapacity:2];
    NSString* contentType;
    NSEnumerator* contentTypeEnumerator = [contentTypes objectEnumerator];
    while (contentType = [contentTypeEnumerator nextObject]) {
        NSArray* bundleIDs =
        (NSArray*)LSCopyAllRoleHandlersForContentType((CFStringRef)contentType,
                                                      kLSRolesViewer);
        TRACE(@"contentType=\"%@\" => bundleIDs=\"%@\"", contentType, bundleIDs);
        NSURL* appURL;
        NSString* bundleID;
        NSEnumerator* bundleIDEnumerator = [bundleIDs objectEnumerator];
        while (bundleID = [bundleIDEnumerator nextObject]) {
            if (noErr == LSFindApplicationForInfo(kLSUnknownCreator,
                                                  (CFStringRef)bundleID,
                                                  NULL, NULL, (CFURLRef*)&appURL)) {
                if (![apps containsObject:[appURL path]]) {
                    [apps addObject:[appURL path]];
                    TRACE(@"    bundleID=\"%@\" : app=\"%@\"", bundleID, [appURL path]);
                }
                else {
                    TRACE(@"    bundleID=\"%@\" : app=\"%@\" (already added)", bundleID, [appURL path]);
                }
            }
            else {
                TRACE(@"    bundleID=\"%@\" : no app", bundleID);
            }
        }
    }
*/
    /*
    NSMutableArray* apps = [NSMutableArray arrayWithCapacity:3];
    [apps addObject:@"/Users/dckim/Projects/Movist/Movist_0.5.0/build/Debug/Movist.app"];
    [apps addObject:@"/Applications/VLC.app"];
    [apps addObject:@"/Applications/MPlayer OSX.app"];
    [apps addObject:@"/Applications/QuickTime Player.app"];
    _bindingApps = [apps retain];
     */
    [apps sortUsingSelector:@selector(caseInsensitiveCompare:)];
    _bindingApps = [apps retain];
    TRACE(@"bindingApps=%@", apps);

    // application menu
    NSTableColumn* column = [_fileBindingTableView tableColumnWithIdentifier:@"application"];
    NSPopUpButtonCell* cell = [column dataCell];
    NSMenu* menu = [cell menu];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    int i = 0;
    NSString* app;
    NSImage* icon;
    NSEnumerator* enumerator = [_bindingApps objectEnumerator];
    while (app = [enumerator nextObject]) {
        [cell addItemWithTitle:[fileManager displayNameAtPath:app]];
        icon = [workspace iconForFile:app];
        [icon setSize:NSMakeSize(16, 16)];
        [[menu itemAtIndex:i++] setImage:icon];
    }
    [menu setAutoenablesItems:FALSE];
}

- (int)numberOfRowsInFileBindingTableView { return [_fileExtensions count]; }

- (id)objectValueForFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    if ([[tableColumn identifier] isEqualToString:@"extension"]) {
        return [@"." stringByAppendingString:[_fileExtensions objectAtIndex:rowIndex]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"desc"]) {
        NSString* desc = [_fileExtensionDescriptions objectAtIndex:rowIndex];
        return NSLocalizedStringFromTable(desc, @"InfoPlist", nil);

        /* use to show preferred-app's description
        NSString* desc;
        NSString* ext = [_fileExtensions objectAtIndex:rowIndex];
        if (noErr == LSCopyKindStringForTypeInfo(kLSUnknownType, kLSUnknownCreator,
                                                 (CFStringRef)ext, (CFStringRef*)&desc)) {
            return desc;
        }
        return @"";
         */
    }
    else {  // @"application"
        NSURL* url;
        int index = -1;
        NSString* ext = [_fileExtensions objectAtIndex:rowIndex];
        if (noErr == LSGetApplicationForInfo(kLSUnknownType, kLSUnknownCreator,
                                             (CFStringRef)ext, kLSRolesViewer,
                                             NULL, (CFURLRef*)&url)) {
            TRACE(@"ext=\"%@\" ==> app=\"%@\"", ext, [url path]);
            index = [_bindingApps indexOfObject:[url path]];
        }
        return [NSNumber numberWithInt:index];
    }
}

- (void)setObjectValue:(id)object
forFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    int index = [(NSNumber*)object intValue];
    if (0 <= index) {
        NSString* ext = [_fileExtensions objectAtIndex:rowIndex];
        NSString* app = [_bindingApps objectAtIndex:index];
        NSString* contentType = @"";
        NSString* bundleID = [[NSBundle bundleWithPath:app] bundleIdentifier];
        TRACE(@"\"%@\"(\"%@\") => \"%@\"(\"%@\")", ext, contentType, app, bundleID);
        //LSSetDefaultRoleHandlerForContentType(contentType, kLSRolesViewer, bundleID);
    }
}

- (void)willDisplayCell:(id)cell
forFileBindingTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
    /*
    if ([[tableColumn identifier] isEqualToString:@"application"]) {
        NSMenu* menu = [(NSPopUpButtonCell*)cell menu];
        [[menu itemAtIndex:1] setEnabled:FALSE];
    }
     */
}

- (IBAction)fileBindingAction:(id)sender
{
}

@end

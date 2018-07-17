//
//  WLGeneralPreferences.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 WireLoad, Inc. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLGeneralPreferences.h"


static NSString *_WLLoginItemJobLabel = @"net.wireload.blotter.mac.LoginItem";


@implementation WLGeneralPreferences

#pragma mark Properties
@dynamic shouldStartAtLogin;

- (BOOL)shouldStartAtLogin
{
    // While deperecated, there is no replacement as of macOS 10.13
    CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    NSArray* jobDicts = CFBridgingRelease(cfJobDicts);

    if (jobDicts && jobDicts.count > 0)
    {
        for (NSDictionary* job in jobDicts)
        {
            if ([job[@"Label"] isEqualToString:_WLLoginItemJobLabel])
            {
                return [job[@"OnDemand"] boolValue];
            }
        }
    }

    return NO;
}

- (void)setShouldStartAtLogin:(BOOL)newShouldStartAtLogin
{
    SMLoginItemSetEnabled((__bridge CFStringRef)_WLLoginItemJobLabel, (Boolean)newShouldStartAtLogin);
}

#pragma mark Methods

- (IBAction)quitBlotter:(id)aSender
{
    [[NSApplication sharedApplication] terminate:aSender];
}

- (IBAction)showMacOSXCalendarSettings:(id)aSender
{

    if (![[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:@"/System/Library/PreferencePanes/Localization.prefPane"]])
    {
        NSAlert *a = [NSAlert new];
        a.messageText = NSLocalizedString(@"Failed to open System Preferences.",  @"Cannot open System Preferences alert message");
        a.informativeText = NSLocalizedString(@"You can open it manually by following:\n→System Preferences…→Language & Region", @"Cannot open System Preferences alert informative text for 10.10 and higher");
        a.alertStyle = NSCriticalAlertStyle;
        a.showsHelp = YES;
        a.delegate = self;
        [a beginSheetModalForWindow:self.view.window completionHandler:nil];
    }
}


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:NSImageNamePreferencesGeneral];
    anItem.label = NSLocalizedString(@"General", @"General pref pane title");
    anItem.toolTip = NSLocalizedString(@"General Preferences", @"General pref pane tooltip");
}


#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_getSupportURL]];
    return YES;
}

@end

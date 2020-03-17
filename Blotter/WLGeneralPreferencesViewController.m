//
//  WLGeneralPreferencesViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 11/7/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLGeneralPreferencesViewController.h"


static NSString *_WLLoginItemJobLabel = @"net.wireload.blotter.mac.LoginItem";


@implementation WLGeneralPreferencesViewController

- (BOOL)shouldStartAtLogin
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // While deperecated, there is no replacement as of macOS 10.15
    CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
#pragma clang diagnostic pop

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

    if (![NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:@"/System/Library/PreferencePanes/Localization.prefPane"]])
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

- (IBAction)showPrivacyPolicy:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_privacyPolicyURL]];
}

#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_getSupportURL]];
    return YES;
}

#pragma mark WLPreferencesViewController

- (NSTabViewItem *)makeTabViewItem
{
    NSTabViewItem *t = [super makeTabViewItem];
    t.image = [NSImage imageNamed:NSImageNamePreferencesGeneral];
    t.label = NSLocalizedString(@"General", @"General pref pane title");
    t.toolTip = NSLocalizedString(@"General Preferences", @"General pref pane tooltip");
    return t;
}

@end

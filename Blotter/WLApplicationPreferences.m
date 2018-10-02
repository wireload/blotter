//
//  WLApplicationPreferences.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.02.13.
//  Copyright (c) 2013 WireLoad. All rights reserved.
//

#import "WLApplicationPreferences.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


@implementation WLApplicationPreferences

- (void)requestShareAnalyticsConsentIfNeeded
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];

    if (![d boolForKey:WLRequestShareAnalyticsConsentAtStartup])
        return;

    NSAlert *a = [NSAlert new];
    a.messageText = NSLocalizedString(@"Share Usage", @"User consent to share usage dialog's message text");
    a.informativeText = NSLocalizedString(@"Help WireLoad improve its products and services by automatically sending diagnostics and usage data.", @"User consent to share usage dialog's informative text");
    a.showsHelp = YES;
    a.delegate = self;
    [a addButtonWithTitle:NSLocalizedString(@"Allow", @"User consent to share usage dialog's allow button")];
    [a addButtonWithTitle:NSLocalizedString(@"Disallow", @"User consent to share usage dialog's disallow button")];
    [a beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse aReturnCode) {
        if (aReturnCode == NSAlertFirstButtonReturn)
            [d setBool:YES forKey:WLShareAnalytics];
        else
            [d setBool:NO forKey:WLShareAnalytics];

        [d setBool:NO forKey:WLRequestShareAnalyticsConsentAtStartup];
    }];
}

#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_privacyPolicyURL]];
    return YES;
}

#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    self.window.level = NSFloatingWindowLevel;
}

- (void)showWindow:(id)aSender
{
    if (!self.window.isVisible)
        [self.window center];

    [super showWindow:aSender];

    [self requestShareAnalyticsConsentIfNeeded];
}

@end

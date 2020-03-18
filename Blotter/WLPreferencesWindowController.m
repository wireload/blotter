//
//  WLPreferencesWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 7/25/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <ShortcutRecorder/ShortcutRecorder.h>

#import "WLPreferencesWindowController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


@implementation WLPreferencesWindowController
{
    SRShortcutItemCatalog *_shortcuts;
}

#pragma mark Properties

@dynamic contentViewController;

#pragma mark Methods

- (void)requestShareAnalyticsConsentIfNeeded
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    if (![defaults boolForKey:WLRequestShareAnalyticsConsentAtStartup])
        return;

    NSAlert *a = [NSAlert new];
    a.messageText = NSLocalizedString(@"Share Analytics", @"User consent to share usage dialog's message text");
    a.informativeText = NSLocalizedString(@"Help WireLoad improve its products and services by automatically sending diagnostics and usage data.",
                                          @"User consent to share usage dialog's informative text");
    a.showsHelp = YES;
    a.delegate = self;
    [a addButtonWithTitle:NSLocalizedString(@"Allow", @"User consent to share usage dialog's allow button")];
    [a addButtonWithTitle:NSLocalizedString(@"Disallow", @"User consent to share usage dialog's disallow button")];

    [a beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse aReturnCode) {
        [defaults setBool:(aReturnCode == NSAlertFirstButtonReturn) forKey:WLShareAnalytics];
        [defaults setBool:NO forKey:WLRequestShareAnalyticsConsentAtStartup];
    }];
}

#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [NSWorkspace.sharedWorkspace openURL:[NSUserDefaults.standardUserDefaults WL_privacyPolicyURL]];
    return YES;
}

#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.window.level = NSFloatingWindowLevel;
    self.contentViewController.transitionOptions = WLViewControllerTransitionResize;
    _shortcuts = [SRShortcutItemCatalog new];
    [_shortcuts addAction:@selector(performClose:) forKeyEquivalent:@"⌘W"];
}

- (void)showWindow:(id)aSender
{
    if (!self.window.isVisible)
        [self.window center];

    [super showWindow:aSender];
    [self requestShareAnalyticsConsentIfNeeded];
}

#pragma mark NSResponder

- (void)keyDown:(NSEvent *)anEvent
{
    if (![_shortcuts performEvent:anEvent onTarget:self.window])
        [super keyDown:anEvent];
}

@end

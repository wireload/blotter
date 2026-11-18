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
    SRLocalShortcutMonitor *_shortcuts;
}

#pragma mark Properties

@dynamic contentViewController;

#pragma mark Methods

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

    _shortcuts = [SRLocalShortcutMonitor new];
    __auto_type closeWindowAction = [_shortcuts addAction:@selector(performClose:) forKeyEquivalent:@"⌘W" tag:0];
    closeWindowAction.target = self.window;
}

- (void)showWindow:(id)aSender
{
    if (!self.window.isVisible)
        [self.window center];

    [super showWindow:aSender];
}

#pragma mark NSResponder

- (void)keyDown:(NSEvent *)anEvent
{
    if (![_shortcuts handleEvent:anEvent withTarget:nil])
        [super keyDown:anEvent];
}

@end

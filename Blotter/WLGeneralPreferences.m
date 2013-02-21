//
//  WLGeneralPreferences.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 WireLoad, Inc. All rights reserved.
//

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLGeneralPreferences.h"
#import "SystemPreferences.h"


@implementation WLGeneralPreferences

#pragma mark Methods

- (IBAction)quitBlotter:(id)aSender
{
    [[NSApplication sharedApplication] terminate:aSender];
}

- (IBAction)showMacOSXCalendarSettings:(id)aSender
{
    SystemPreferencesApplication *app = (SystemPreferencesApplication *)[SBApplication applicationWithBundleIdentifier:@"com.apple.systempreferences"];
    SystemPreferencesPane *pane = [[app panes] objectWithID:@"com.apple.Localization"];
    SystemPreferencesAnchor *anchor = nil;
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
        anchor = [[pane anchors] objectWithName:@"Formats"];
    else
        anchor = [[pane anchors] objectWithName:@"Region"];
    
    if ([anchor reveal] != nil)
        [app activate];
    else
    {
        NSAlert *a = [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"Failed to open System Preferences.", nil, [NSBundle bundleForClass:[self class]], @"Cannot open System Preferences alert message")
                                     defaultButton:NSLocalizedStringFromTableInBundle(@"Close", nil, [NSBundle bundleForClass:[self class]], @"Cannot open System Preferences alert default title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"You can open it manually by following:\n→System Preferences…→Language & Text→Formats", nil, [NSBundle bundleForClass:[self class]], @"Cannot open System Preferences alert informative text")];
        [a setAlertStyle:NSCriticalAlertStyle];
        [a setShowsHelp:YES];
        [a setDelegate:self];
        [a beginSheetModalForWindow:[self.view window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:NSImageNamePreferencesGeneral];
    anItem.label = NSLocalizedStringFromTableInBundle(@"General", nil, [NSBundle bundleForClass:[self class]], @"General pref pane title");
    anItem.toolTip = NSLocalizedStringFromTableInBundle(@"General Preferences", nil, [NSBundle bundleForClass:[self class]], @"General pref pane tooltip");
}


#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_getSupportURL]];
    return YES;
}

@end

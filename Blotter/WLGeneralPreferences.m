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
    // TODO: Would be wise to replace it with proper NSError
    BOOL is_successful = YES;
    
    // @try-@catch is used here because when Scripting Bridge fails due to sandboxing, exception is thrown rather than error.
    @try
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
            is_successful = NO;
    }
    @catch (...)
    {
        is_successful = NO;
    }
    @finally
    {
        if (!is_successful)
        {
            NSString *informativeTextWithFormat = @"";

            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
                informativeTextWithFormat = NSLocalizedString(@"You can open it manually by following:\n→System Preferences…→Language & Text→Formats", @"Cannot open System Preferences alert informative text for 10.6 and 10.7");
            else
                informativeTextWithFormat = NSLocalizedString(@"You can open it manually by following:\n→System Preferences…→Language & Text→Region", @"Cannot open System Preferences alert informative text for 10.8 and higher");

            NSAlert *a = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to open System Preferences.",  @"Cannot open System Preferences alert message")
                                         defaultButton:NSLocalizedString(@"Close", @"Cannot open System Preferences alert default title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:informativeTextWithFormat];
            a.alertStyle = NSCriticalAlertStyle;
            a.showsHelp = YES;
            a.delegate = self;
            [a beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        }
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

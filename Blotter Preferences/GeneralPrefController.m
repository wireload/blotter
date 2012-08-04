//
//  GeneralPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 WireLoad, Inc. All rights reserved.
//

#import "GeneralPrefController.h"
#import "PositionPrefController.h"
#import "CalendarsPrefController.h"
#import "LayoutPrefController.h"
#import "AboutPrefController.h"
#import "ShortcutsPrefController.h"
#import "SystemPreferences.h"


@implementation GeneralPrefController

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
                                   alternateButton:@""
                                       otherButton:@""
                         informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"You can open it manually by following:\n→System Preferences…→Language & Text→Formats", nil, [NSBundle bundleForClass:[self class]], @"Cannot open System Preferences alert informative text")];
        [a setAlertStyle:NSCriticalAlertStyle];
        [a setShowsHelp:YES];
        [a setDelegate:self];
        [a beginSheetModalForWindow:[_mainView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}


#pragma mark SS_PreferencePaneProtocol

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPrefController alloc] init] autorelease],
            [[[ShortcutsPrefController alloc] init] autorelease],
            [[[PositionPrefController alloc] init] autorelease],
            [[[LayoutPrefController alloc] init] autorelease],
            [[[CalendarsPrefController alloc] init] autorelease],
            [[[AboutPrefController alloc] init] autorelease],
            nil];
}

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"GeneralPrefPaneView" owner:self])
        {
            _mainView.preferredFrameSize = [_mainView frame].size;
        }
        else
            NSLog(@"Cannot load GeneralPrefPaneView");
    }
    return _mainView;
}

- (NSString *)paneName
{
    return NSLocalizedStringFromTableInBundle(@"General", nil, [NSBundle bundleForClass:[self class]], @"General pref pane title");
}

- (NSImage *)paneIcon
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}


- (NSString *)paneToolTip
{
    return NSLocalizedStringFromTableInBundle(@"General Preferences", nil, [NSBundle bundleForClass:[self class]], @"General pref pane tooltip");
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}


#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_getSupportURL]];
    return YES;
}

@end

//
//  WLShortcutsPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLShortcutsPreferences.h"


@implementation WLShortcutsPreferences

#pragma mark Methods

#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"shortcuts-icon"];
    anItem.label = NSLocalizedStringFromTableInBundle(@"Shortcuts", nil, [NSBundle bundleForClass:[self class]], @"Shortcuts pref pane title");
    anItem.toolTip = NSLocalizedStringFromTableInBundle(@"Keyboard shortcuts preferences", nil, [NSBundle bundleForClass:[self class]], @"Shortcuts pref pane tooltip");
}


#pragma mark NSView

- (void)loadView
{
    [super loadView];
    
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [_bringToFrontRecroderControl setAllowsKeyOnly:NO escapeKeysRecord:YES];
    [_bringToFrontRecroderControl setIsASCIIOnly:YES];
    [_bringToFrontRecroderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutBringToFront" options:nil];
    [_newEventRecorderControl setAllowsKeyOnly:NO escapeKeysRecord:YES];
    [_newEventRecorderControl setIsASCIIOnly:YES];
    [_newEventRecorderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutNewEvent" options:nil];
    [_newReminderRecorderControl setAllowsKeyOnly:NO escapeKeysRecord:YES];
    [_newReminderRecorderControl setIsASCIIOnly:YES];
    [_newReminderRecorderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutNewTask" options:nil];
    [_showNextWeekControl setAllowsKeyOnly:NO escapeKeysRecord:YES];
    [_showNextWeekControl setIsASCIIOnly:YES];
    [_showNextWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowNextWeek" options:nil];
    [_showCurrentWeekControl setAllowsKeyOnly:NO escapeKeysRecord:YES];
    [_showCurrentWeekControl setIsASCIIOnly:YES];
    [_showCurrentWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowCurrentWeek" options:nil];
    [_showPrevWeekControl setAllowsKeyOnly:NO escapeKeysRecord:YES];
    [_showPrevWeekControl setIsASCIIOnly:YES];
    [_showPrevWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowPreviousWeek" options:nil];
}


#pragma mark SRRecorderControlDelegate

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    KeyCombo keyCombo = SRMakeKeyCombo(keyCode, flags);
    if ((aRecorder != _newEventRecorderControl && SRKeyComboEqualToKeyCombo([_newEventRecorderControl keyCombo], keyCombo)) ||
        (aRecorder != _bringToFrontRecroderControl && SRKeyComboEqualToKeyCombo([_bringToFrontRecroderControl keyCombo], keyCombo)) ||
        (aRecorder != _newReminderRecorderControl && SRKeyComboEqualToKeyCombo([_newReminderRecorderControl keyCombo], keyCombo)) ||
        (aRecorder != _showNextWeekControl && SRKeyComboEqualToKeyCombo([_showNextWeekControl keyCombo], keyCombo)) ||
        (aRecorder != _showPrevWeekControl && SRKeyComboEqualToKeyCombo([_showPrevWeekControl keyCombo], keyCombo)) ||
        (aRecorder != _showCurrentWeekControl && SRKeyComboEqualToKeyCombo([_showCurrentWeekControl keyCombo], keyCombo)))
    {
        *aReason = NSLocalizedStringFromTableInBundle(@"it's already used as a different Blotter shortcut. To use this shortcut, first remove or change the other shortcut", nil, [NSBundle bundleForClass:[self class]], @"A reason to use other shortcut");;
        return YES;
    }
    else
        return NO;
}

- (BOOL)shortcutRecorderShouldCheckMenu:(SRRecorderControl *)aRecorder
{
    return NO;
}

@end

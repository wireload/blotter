//
//  WLShortcutsPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLShortcutsPreferences.h"


@implementation WLShortcutsPreferences
{
    SRValidator *_validator;
}

#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"preferences-shortcuts-icon"];
    anItem.label = NSLocalizedString(@"Shortcuts", @"Shortcuts pref pane title");
    anItem.toolTip = NSLocalizedString(@"Keyboard shortcuts preferences", @"Shortcuts pref pane tooltip");
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];

    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSDictionary *bindingOptions = @{
        NSValueTransformerNameBindingOption: NSKeyedUnarchiveFromDataTransformerName
    };

    [_bringToFrontRecroderControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _bringToFrontRecroderControl.drawsASCIIEquivalentOfShortcut = YES;
    [_bringToFrontRecroderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutBringToFront" options:bindingOptions];

    [_newEventRecorderControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _newEventRecorderControl.drawsASCIIEquivalentOfShortcut = YES;
    [_newEventRecorderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutNewEvent" options:bindingOptions];

    [_newReminderRecorderControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _newReminderRecorderControl.drawsASCIIEquivalentOfShortcut = YES;
    [_newReminderRecorderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutNewTask" options:bindingOptions];

    [_showNextWeekControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _showNextWeekControl.drawsASCIIEquivalentOfShortcut = YES;
    [_showNextWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowNextWeek" options:bindingOptions];

    [_showCurrentWeekControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _showCurrentWeekControl.drawsASCIIEquivalentOfShortcut = YES;
    [_showCurrentWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowCurrentWeek" options:bindingOptions];

    [_showPrevWeekControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _showPrevWeekControl.drawsASCIIEquivalentOfShortcut = YES;
    [_showPrevWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowPreviousWeek" options:bindingOptions];

    _validator = [[SRValidator alloc] initWithDelegate:self];
}


#pragma mark SRRecorderControlDelegate

- (BOOL)recorderControl:(SRRecorderControl *)aControl canRecordShortcut:(SRShortcut *)aShortcut
{
    __autoreleasing NSError *error = nil;
    BOOL isTaken = [_validator validateShortcut:aShortcut error:&error];

    if (isTaken)
    {
        NSBeep();
        [self presentError:error modalForWindow:[self view].window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }

    return !isTaken;
}

- (BOOL)recorderControl:(SRRecorderControl *)aControl shouldUnconditionallyAllowModifierFlags:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode
{
    // Don't allow disallowed flags.
    if ((aModifierFlags & aControl.allowedModifierFlags) != aModifierFlags)
        return NO;
    
    switch (aKeyCode)
    {
        case kVK_F1:
        case kVK_F2:
        case kVK_F3:
        case kVK_F4:
        case kVK_F5:
        case kVK_F6:
        case kVK_F7:
        case kVK_F8:
        case kVK_F9:
        case kVK_F10:
        case kVK_F11:
        case kVK_F12:
        case kVK_F13:
        case kVK_F14:
        case kVK_F15:
        case kVK_F16:
        case kVK_F17:
        case kVK_F18:
        case kVK_F19:
        case kVK_F20:
            return YES;
        default:
            return NO;
    }
}


#pragma mark SRValidatorDelegate

- (BOOL)shortcutValidator:(SRValidator *)aValidator isShortcutValid:(SRShortcut *)aShortcut reason:(NSString *__autoreleasing *)outReason
{
    SRRecorderControl *currentControl = (SRRecorderControl *)self.view.window.firstResponder;

    __auto_type IsShortcutTakenByOtherControl = ^(SRRecorderControl *aControl)
    {
        return (aControl != currentControl) && [aControl.objectValue isEqualToShortcut:aShortcut];
    };

    BOOL isTaken = IsShortcutTakenByOtherControl(_bringToFrontRecroderControl) ||
        IsShortcutTakenByOtherControl(_newEventRecorderControl) ||
        IsShortcutTakenByOtherControl(_newReminderRecorderControl) ||
        IsShortcutTakenByOtherControl(_showNextWeekControl) ||
        IsShortcutTakenByOtherControl(_showCurrentWeekControl) ||
        IsShortcutTakenByOtherControl(_showPrevWeekControl);

    if (isTaken)
    {
        if (outReason)
            *outReason = NSLocalizedString(@"it's already used as a different Blotter shortcut. To use this shortcut, first remove or change the other shortcut", @"A reason to use other shortcut");
        return NO;
    }
    else
        return YES;
}

- (BOOL)shortcutValidatorShouldCheckMenu:(SRValidator *)aValidator
{
    return NO;
}

@end

//
//  WLShortcutsPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLShortcutsPreferences.h"


@implementation WLShortcutsPreferences

#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"preferences-shortcuts-icon"];
    anItem.label = NSLocalizedStringFromTableInBundle(@"Shortcuts", nil, [NSBundle bundleForClass:[self class]], @"Shortcuts pref pane title");
    anItem.toolTip = NSLocalizedStringFromTableInBundle(@"Keyboard shortcuts preferences", nil, [NSBundle bundleForClass:[self class]], @"Shortcuts pref pane tooltip");
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];

    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];

    [_bringToFrontRecroderControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _bringToFrontRecroderControl.drawsASCIIEquivalentOfShortcut = YES;
    [_bringToFrontRecroderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutBringToFront" options:nil];

    [_newEventRecorderControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _newEventRecorderControl.drawsASCIIEquivalentOfShortcut = YES;
    [_newEventRecorderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutNewEvent" options:nil];

    [_newReminderRecorderControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _newReminderRecorderControl.drawsASCIIEquivalentOfShortcut = YES;
    [_newReminderRecorderControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutNewTask" options:nil];

    [_showNextWeekControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _showNextWeekControl.drawsASCIIEquivalentOfShortcut = YES;
    [_showNextWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowNextWeek" options:nil];

    [_showCurrentWeekControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _showCurrentWeekControl.drawsASCIIEquivalentOfShortcut = YES;
    [_showCurrentWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowCurrentWeek" options:nil];

    [_showPrevWeekControl setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:NO];
    _showPrevWeekControl.drawsASCIIEquivalentOfShortcut = YES;
    [_showPrevWeekControl bind:NSValueBinding toObject:defaultsController withKeyPath:@"values.shortcutShowPreviousWeek" options:nil];

    _validator = [[SRValidator alloc] initWithDelegate:self];
}


#pragma mark SRRecorderControlDelegate

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder canRecordShortcut:(NSDictionary *)aShortcut
{
    __autoreleasing NSError *error = nil;
    BOOL isTaken = [_validator isKeyCode:[aShortcut[SRShortcutKeyCode] unsignedShortValue] andFlagsTaken:[aShortcut[SRShortcutModifierFlagsKey] unsignedIntegerValue] error:&error];

    if (isTaken)
    {
        NSBeep();
        [self presentError:error modalForWindow:[[self view] window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }

    return !isTaken;
}


#pragma mark SRValidatorDelegate

- (BOOL)shortcutValidator:(SRValidator *)aValidator isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSUInteger)aFlags reason:(NSString **)outReason
{
#define IS_TAKEN(aRecorder) (recorder != (aRecorder) && SRShortcutEqualToShortcut(shortcut, [(aRecorder) objectValue]))
    WLRecorderControl *recorder = (WLRecorderControl *)self.view.window.firstResponder;

    if (![recorder isKindOfClass:[WLRecorderControl class]])
        return NO;
     NSDictionary *shortcut = SRShortcutWithCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);

    if (IS_TAKEN(_bringToFrontRecroderControl) ||
        IS_TAKEN(_newEventRecorderControl) ||
        IS_TAKEN(_newReminderRecorderControl) ||
        IS_TAKEN(_showNextWeekControl) ||
        IS_TAKEN(_showNextWeekControl) ||
        IS_TAKEN(_showCurrentWeekControl) ||
        IS_TAKEN(_showPrevWeekControl))
    {
        *outReason = NSLocalizedStringFromTableInBundle(@"it's already used as a different Blotter shortcut. To use this shortcut, first remove or change the other shortcut",
                                                        nil,
                                                        [NSBundle bundleForClass:[self class]],
                                                        @"A reason to use other shortcut");
        return YES;
    }
    else
        return NO;
#undef IS_TAKEN
}

- (BOOL)shortcutValidatorShouldCheckMenu:(SRValidator *)aValidator
{
    return NO;
}

@end

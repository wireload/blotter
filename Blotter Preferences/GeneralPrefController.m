//
//  GeneralPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <ShortcutRecorder/ShortcutRecorder.h>
#import "GeneralPrefController.h"
#import "PositionPrefController.h"
#import "CalendarsPrefController.h"
#import "LayoutPrefController.h"
#import "WLPrefPaneView.h"


@implementation GeneralPrefController

- (IBAction)quitBlotter:(id)sender
{
    [[NSApplication sharedApplication] terminate:sender];
}


#pragma mark SS_PreferencePaneProtocol

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPrefController alloc] init] autorelease],
            [[[PositionPrefController alloc] init] autorelease],
            [[[CalendarsPrefController alloc] init] autorelease],
            [[[LayoutPrefController alloc] init] autorelease],
            nil];
}

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"GeneralPrefPaneView" owner:self])
            _mainView.preferredFrameSize = [_mainView frame].size;
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


#pragma mark SRRecorderControlDelegate

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    KeyCombo keyCombo = SRMakeKeyCombo(keyCode, flags);
    if (SRKeyComboEqualToKeyCombo([newEventRecorderControl keyCombo], keyCombo) || SRKeyComboEqualToKeyCombo([newTaskRecorderControl keyCombo], keyCombo))
    {
        *aReason = NSLocalizedStringFromTableInBundle(@"it's already used as a different Blotter shortcut. To use this shortcut, first remove or change the other shortcut", nil, [NSBundle bundleForClass:[self class]], @"A reason to use other shortcut");;
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)shortcutRecorderShouldCheckMenu:(SRRecorderControl *)aRecorder
{
    return NO;
}

@end

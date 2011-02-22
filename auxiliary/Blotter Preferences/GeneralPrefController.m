//
//  GeneralPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "GeneralPrefController.h"
#import "PositionPrefController.h"
#import "CalendarsPrefController.h"

@implementation GeneralPrefController

- (IBAction)quitBlotter:(id)sender
{
    [[NSApplication sharedApplication] terminate:sender];
}


#pragma mark SS_PreferencePaneProtocol

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPrefController alloc] init] autorelease], [[[PositionPrefController alloc] init] autorelease], [[[CalendarsPrefController alloc] init] autorelease], nil];
}

- (NSView *)paneView
{
    BOOL loaded = YES;

    if (!prefsView)
        loaded = [NSBundle loadNibNamed:@"GeneralPrefPaneView" owner:self];

    if (loaded)
        return prefsView;

    return nil;
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

@end

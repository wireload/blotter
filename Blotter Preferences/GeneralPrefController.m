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


@implementation GeneralPrefController

- (IBAction)quitBlotter:(id)sender
{
    [[NSApplication sharedApplication] terminate:sender];
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

@end

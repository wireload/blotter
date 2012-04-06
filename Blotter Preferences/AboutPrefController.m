//
//  AboutPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "AboutPrefController.h"
#import "WLCustomCursorButton.h"


static NSString* const _WLCursorKey = @"cursor";


@implementation AboutPrefController

#pragma mark Methods

- (void)showHelp:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_getHelpURL]];
}

- (void)showGetSupport:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_getSupportURL]];
}

- (IBAction)showRateThisApp:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_rateThisAppURL]];
}

- (IBAction)showFollowUsOnTwitter:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_followOnTwitterURL]];
}

- (IBAction)showWireload:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_wireloadURL]];
}

- (IBAction)showBanner:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_bannerURL]];
}


#pragma mark SS_PreferencePaneProtocol

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"AboutPrefPaneView" owner:self])
        {
            _mainView.preferredFrameSize = [_mainView frame].size;

            [_versionView setStringValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
            [[_copyrightView cell] setBackgroundStyle:NSBackgroundStyleRaised];

            _bannerButton.cursor = [NSCursor pointingHandCursor];
            _wireloadButton.cursor = [NSCursor pointingHandCursor];
        }
        else
            NSLog(@"Cannot load AboutPrefPaneView");
    }
    return _mainView;
}

- (NSString *)paneName
{
    return NSLocalizedStringFromTableInBundle(@"About", nil, [NSBundle bundleForClass:[self class]], @"About pref pane title");
}

- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Blotter-toolbar-icon" ofType:@"png"]] autorelease];
}

- (NSString *)paneToolTip
{
    return NSLocalizedStringFromTableInBundle(@"Contacts, support and ratings", nil, [NSBundle bundleForClass:[self class]], @"About pref pane tooltip");
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

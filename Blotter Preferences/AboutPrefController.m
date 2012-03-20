//
//  AboutPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "AboutPrefController.h"


@implementation AboutPrefController

#pragma mark Methods

- (void)showHelp:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.wireload.net/forums/356140-frequently-asked-questions"]];
}

- (void)showGetSupport:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.wireload.net/home"]];
}

- (IBAction)showRateThisApp:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"macappstore://itunes.apple.com/app/id406580224?mt=12"]];
}

- (IBAction)showFollowUsOnTwitter:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitter.com/BlotterApp"]];
}

- (IBAction)showWireload:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wireload.net"]];
}

- (IBAction)showBanner:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wireload.net/products/quiet/"]];
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
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
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

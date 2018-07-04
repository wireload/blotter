//
//  WLAboutPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLAboutPreferences.h"
#import "DeskboardAppDelegate.h"


static NSString* const _WLCursorKey = @"cursor";


@implementation WLAboutPreferences

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
    [(DeskboardAppDelegate *)NSApp.delegate showRateThisApp:aSender];
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


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"preferences-about-blotter-icon"];
    anItem.label = NSLocalizedString(@"About", @"About pref pane title");
    anItem.toolTip = NSLocalizedString(@"Contacts, support and ratings", @"About pref pane tooltip");
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];

    _versionView.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    _copyrightView.cell.backgroundStyle = NSBackgroundStyleRaised;
    
    _bannerButton.cursor = [NSCursor pointingHandCursor];
    _wireloadButton.cursor = [NSCursor pointingHandCursor];
}

@end

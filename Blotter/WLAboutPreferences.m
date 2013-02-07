//
//  WLAboutPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLAboutPreferences.h"


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


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"about-blotter-icon"];
    anItem.label = NSLocalizedStringFromTableInBundle(@"About", nil, [NSBundle bundleForClass:[self class]], @"About pref pane title");
    anItem.toolTip = NSLocalizedStringFromTableInBundle(@"Contacts, support and ratings", nil, [NSBundle bundleForClass:[self class]], @"About pref pane tooltip");
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];

    [_versionView setStringValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [[_copyrightView cell] setBackgroundStyle:NSBackgroundStyleRaised];
    
    _bannerButton.cursor = [NSCursor pointingHandCursor];
    _wireloadButton.cursor = [NSCursor pointingHandCursor];
}

@end

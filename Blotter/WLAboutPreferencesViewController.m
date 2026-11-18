//
//  WLAboutPreferencesViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 7/29/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import "WLAboutPreferencesViewController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"
#import "DeskboardAppDelegate.h"


@implementation WLAboutPreferencesViewController

#pragma mark Methods

- (IBAction)showHelp:(id)aSender
{
    [NSWorkspace.sharedWorkspace openURL:[NSUserDefaults.standardUserDefaults WL_getHelpURL]];
}

- (IBAction)showGetSupport:(id)aSender
{
    [NSWorkspace.sharedWorkspace openURL:[NSUserDefaults.standardUserDefaults WL_getSupportURL]];
}

- (IBAction)showRateThisApp:(id)aSender
{
    [(DeskboardAppDelegate *)NSApp.delegate showRateThisApp:aSender];
}

- (IBAction)showFollowUsOnTwitter:(id)aSender
{
    [NSWorkspace.sharedWorkspace openURL:[NSUserDefaults.standardUserDefaults WL_followOnTwitterURL]];
}

#pragma mark WLPreferencesViewController

- (NSTabViewItem *)makeTabViewItem
{
    NSTabViewItem *t = [super makeTabViewItem];
    t.image = [NSImage imageNamed:@"preferences-about-blotter-icon"];
    t.label = NSLocalizedString(@"About", @"About pref pane title");
    t.toolTip = NSLocalizedString(@"Contacts, support and ratings", @"About pref pane tooltip");
    return t;
}

#pragma mark NSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _versionView.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    _copyrightView.cell.backgroundStyle = NSBackgroundStyleRaised;
}

@end

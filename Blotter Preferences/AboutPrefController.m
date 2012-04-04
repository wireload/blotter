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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wireload.net/products/blotter/faq/?utm_source=Blotter&utm_medium=app&utm_content=about_page_help&utm_campaign=Blotter_app"]];
}

- (void)showGetSupport:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wireload.net/products/blotter/help/?utm_source=Blotter&utm_medium=app&utm_content=about_page_support&utm_campaign=Blotter_app"]];
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wireload.net/?utm_source=Blotter&utm_medium=app&utm_content=about_page_wireload&utm_campaign=Blotter_app"]];
}

- (IBAction)showBanner:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wireload.net/products/quiet/?utm_source=Blotter&utm_medium=app&utm_content=about_page_quiet&utm_campaign=Blotter_app"]];
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

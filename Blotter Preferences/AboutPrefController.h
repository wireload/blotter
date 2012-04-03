//
//  AboutPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class WLPrefPaneView;

@class WLCustomCursorButton;


@interface AboutPrefController : NSObject <SS_PreferencePaneProtocol>
{
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet NSTextField *_versionView;
    IBOutlet NSTextField *_copyrightView;
    IBOutlet WLCustomCursorButton *_bannerButton;
    IBOutlet WLCustomCursorButton *_wireloadButton;
}

- (IBAction)showHelp:(id)aSender;

- (IBAction)showGetSupport:(id)aSender;

- (IBAction)showRateThisApp:(id)aSender;

- (IBAction)showFollowUsOnTwitter:(id)aSender;

- (IBAction)showWireload:(id)aSender;

- (IBAction)showBanner:(id)aSender;

@end

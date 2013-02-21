//
//  WLAboutPreferences.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLViewController.h"
#import "IKPreferencesRepresentation.h"
#import "WLCustomCursorButton.h"


@interface WLAboutPreferences : WLViewController <IKPreferencesRepresentation>
{
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

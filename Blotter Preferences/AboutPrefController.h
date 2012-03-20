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


@interface AboutPrefController : NSObject <SS_PreferencePaneProtocol>
{
    IBOutlet WLPrefPaneView *_mainView;
}

- (IBAction)showHelp:(id)aSender;

- (IBAction)showGetSupport:(id)aSender;

- (IBAction)showRateThisApp:(id)aSender;

- (IBAction)showFollowUsOnTwitter:(id)aSender;

@end

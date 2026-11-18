//
//  WLAboutPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 7/29/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WLPreferencesViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WLAboutPreferencesViewController : WLPreferencesViewController
{
    IBOutlet NSTextField *_versionView;
    IBOutlet NSTextField *_copyrightView;
}

- (IBAction)showHelp:(id)aSender;

- (IBAction)showGetSupport:(id)aSender;

- (IBAction)showRateThisApp:(id)aSender;

- (IBAction)showFollowUsOnTwitter:(id)aSender;

@end

NS_ASSUME_NONNULL_END

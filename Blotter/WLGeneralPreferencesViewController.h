//
//  WLGeneralPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11/7/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WLPreferencesViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WLGeneralPreferencesViewController : WLPreferencesViewController <NSAlertDelegate>

@property (nonatomic) BOOL shouldStartAtLogin;

- (IBAction)quitBlotter:(id)aSender;

- (IBAction)showMacOSXCalendarSettings:(id)aSender;

- (IBAction)showPrivacyPolicy:(id)aSender;

@end

NS_ASSUME_NONNULL_END

//
//  WLPreferencesWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 7/25/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLPreferencesTabViewController.h"


NS_ASSUME_NONNULL_BEGIN

/*!
 Window controller for the preferences window.
 */
@interface WLPreferencesWindowController : NSWindowController <NSAlertDelegate>

@property (nullable, strong) WLPreferencesTabViewController *contentViewController;

@end

NS_ASSUME_NONNULL_END

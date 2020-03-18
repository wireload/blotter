//
//  WLPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 7/30/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WLGeneralPreferencesViewController.h"
#import "WLShortcutsPreferencesViewController.h"
#import "WLPositioningPreferencesViewController.h"
#import "WLCalendarsPreferencesViewController.h"
#import "WLAboutPreferencesViewController.h"


NS_ASSUME_NONNULL_BEGIN

typedef NSToolbarItemIdentifier WLPreferencesIdentifier NS_TYPED_EXTENSIBLE_ENUM;
extern WLPreferencesIdentifier const WLGeneralPreferencesIdentifier;
extern WLPreferencesIdentifier const WLShortcutsPreferencesIdentifier;
extern WLPreferencesIdentifier const WLPositioningPreferencesIdentifier;
extern WLPreferencesIdentifier const WLCalendarsPreferencesIdentifier;
extern WLPreferencesIdentifier const WLAboutPreferencesIdentifier;


extern const NSViewControllerTransitionOptions WLViewControllerTransitionResize;


/*!
 Root view controller for the preferences window that manages transition between preferences tabs.
 */
@interface WLPreferencesTabViewController : NSTabViewController

@property (nullable, readonly) WLGeneralPreferencesViewController *generalController;

@property (nullable, readonly) WLShortcutsPreferencesViewController *shortcutsController;

@property (nullable, readonly) WLPositioningPreferencesViewController *positioningController;

@property (nullable, readonly) WLCalendarsPreferencesViewController *calendarsController;

@property (nullable, readonly) WLAboutPreferencesViewController *aboutController;

/*!
 Currently selected preferences view controller.

 Defaults to WLGeneralPreferencesIdentifier.
 */
@property (null_resettable, copy) WLPreferencesIdentifier selectedPreferencesIdentifier;

@end

NS_ASSUME_NONNULL_END

//
//  WLPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 12/13/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

@interface WLPreferencesViewController : NSViewController

@property (readonly) NSTabViewItem *tabViewItem;

- (NSTabViewItem *)makeTabViewItem;

/*!
 Called by the parent view controller trasitioned into the received.

 @discussion
 At the very least the view should set up its initial layout.
 */
- (void)viewControllerWillTransitionIn NS_REQUIRES_SUPER;

- (void)viewControllerDidTransitionIn NS_REQUIRES_SUPER;

- (void)viewControllerWillTransitionOut NS_REQUIRES_SUPER;

- (void)viewControllerDidransitionOut NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END

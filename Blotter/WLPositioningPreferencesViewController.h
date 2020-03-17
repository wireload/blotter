//
//  WLPositioningPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11/8/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WLFoundation/WLFoundation.h>

#import "WLPreferencesViewController.h"
#import "WLWindowArrangementView.h"
#import "WLScreensController.h"


NS_ASSUME_NONNULL_BEGIN

/*!
 Preferences pane controller for the size and position of the calendar window on the screen.

 @discussion
 When active, actively observers screen size and settings that affect positioning.

 Screen bounds may have origin other than (0, 0) when there are multiple displays involved.
 Dock may also appear on the same screen during one configuration but not during the other further
 complicating the layout.

 Window's layout is therefore stored as decimals in the (0.0, 1.0] range allowing the window to adjust
 dynamically to changes in Screen's visible frame. A side effect being that pixel size of Window
 may differ between configurations e.g. due to Dock's reappearance.
 */
@interface WLPositioningPreferencesViewController : WLPreferencesViewController <WLWindowArrangementDelegate>
{
    IBOutlet WLScreensController *_screensController;
}

@property (strong) IBOutlet WLWindowArrangementView *arrangementView;

@property (strong) IBOutlet NSLayoutConstraint *arrangementViewWidthConstraint;

@property (strong) IBOutlet NSLayoutConstraint *arrangementViewHeightConstraint;

/*!
 Called after either screen or relevant application settings changed.
 */
- (void)calendarWindowArrangementDidChange;

/*!
 Called to update state of the arrangement view, optionally animating.
 */
- (void)updateArrangementView:(BOOL)anIsAnimated;

#pragma mark Animations

/*!
 Preferred size for the arrangement view for current preferences.
 */
- (NSSize)preferredArrangementViewSize;

- (NSRect)mockupFrameRatiosForPosition:(BLPosition)aPosition size:(BLSize)aSize onScreen:(NSScreen *)aScreen;

/*!
 Animate window resize to accomodate new editing mode of the arrangement view.
 */
- (WLAnimationScene *)animateWindowResize;

/*!
 Animate change of the mockup view size.
 */
- (WLAnimationScene *)animateMockupResize;

/*!
 Animate change of the editing mode.
 */
- (WLAnimationScene *)animateEditingMode;

@end

NS_ASSUME_NONNULL_END

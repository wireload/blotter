//
//  WLCalendarWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 3/17/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WLFoundation/WLFoundation.h>

#import "WLCalendarViewController.h"


typedef NS_ENUM(NSInteger, _WLCalendarWindowState)
{
    WLCalendarWindowStateInactiveFaded = -1,
    WLCalendarWindowStateInactive = 0,
    WLCalendarWindowStateActive = 1
};


NS_ASSUME_NONNULL_BEGIN

@interface _WLCalendarWindow : NSWindow
@end


/*!
 Controller of the main Blotter window.

 @discussion
 Controls window's frame and appearance.
 */
@interface WLCalendarWindowController : NSWindowController <NSWindowDelegate>

/*!
 Main view controller that is displayed by the window.

 @discussion
 The window controller uses window's contentView for custom background which makes contentViewController unsuitable
 for the main view controller.

 The view is automatically added to the window and its constraints are set up appropriately.
 */
@property (readonly) WLCalendarViewController *calendarViewController;

@property (nonatomic) _WLCalendarWindowState windowState;

@property (nonatomic) BOOL isFadedOut;

/*!
 Window frame in screen coordiates for the current preferences.

 @discussion
 Unlike windowFrame it does not incldue auxiliarily shadows.

 @see windowFrame
 @see windowScreen
 */
@property (readonly) NSRect windowAlignmentFrame;

/*!
 Screen for the current preferences.

 @discussion
 Returned screen is not necessarily the current screen of the window, but rather
 a screen designated for the window.

 @note KVO-observable
 */
@property (nullable, readonly) NSScreen *windowScreen;

/*!
 Visible frame of windowScreen.

 @note KVO-observable
 */
@property (readonly) NSRect windowScreenVisibleFrame;

- (void)setWindowState:(_WLCalendarWindowState)newState animated:(BOOL)anIsAnimated;

/*!
 Window frame on a given screen with given preferences.

 @param aScreen Custom screen where the window will be laid on. If nil defaults to preferences.

 @param aPreferences If nil, defaults to standard user defaults.

 @return Frame in screen coordinates.
 */
+ (NSRect)windowFrameOnScreen:(nullable NSScreen *)aScreen preferences:(nullable NSDictionary *)aPreferences;

/*!
 Window screen with given preferences

 @param aPreferences If nil, defaults to standard user defaults.

 @return
 Screen for current user preferences and current system state. Can be nil
 if there are no connected screens.
 */
+ (nullable NSScreen *)windowScreenWithPreferences:(nullable NSDictionary *)aPreferences;

/*!
 Called when either configuration of the connected screens
 or user preferences change to update window's screen.

 @see NSApplicationDidChangeScreenParametersNotification
 */
- (void)windowScreenDidChange;

/*!
 Called when either configuration of the connected screens
 or user preferences change to update the main window position and size.
 */
- (void)windowFrameDidChange;

/*!
 Fade the window out and activate it.
 */
- (WLAnimationScene *)animateFadeOutAndActivate;

/*!
 Fade the window out and deactivate it.
 */
- (WLAnimationScene *)animateFadeOutAndDeactivate;

/*!
 Partially fade the window out.
 */
- (WLAnimationScene *)animatePartialFadeIn;

/*!
 Fade the window in.
 */
- (WLAnimationScene *)animateFadeIn;

@end

NS_ASSUME_NONNULL_END

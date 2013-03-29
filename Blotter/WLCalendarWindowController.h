//
//  WLCalendarWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLCalendarRemindersController.h"
#import "WLCalendarWindow.h"
#import "WLCalendarsController.h"


@class WLCalendarRemindersViewController;
@class WLCalendarDateViewController;
@class WLCalendarBoxView;
@class WLCalendarWindowBringToFrontAnimation;
@class WLCalendarFloatingWeekEventsViewController;
@class WLCalendarRightNowEventsViewController;


typedef enum
{
    WLFinderLevelState,
    WLFloatingLevelState,
} WLCalendarWindowState;


/*!
 @abstract      This class is responsible for sizing and placing its window according to user settings.
 It observes various system notifications to update its subcontrollers appropriately.
 @performance   You SHOULD prepare the controller and its window before you call -showWindow:
 @coclass       WLCalendarWindow The class of controller's window.
 */
@interface WLCalendarWindowController : NSWindowController <NSWindowDelegate, NSAnimationDelegate>
{
    WLCalendarWindowState windowState;
    BOOL isFadedOut;

    BOOL _isWindowShowed;
    WLCalendarFloatingWeekEventsViewController *_weekViewController;
    WLCalendarRightNowEventsViewController *_rightNowViewController;
    WLCalendarRemindersViewController *_remindersViewController;
    WLCalendarDateViewController *_dateViewController;
    WLCalendarBoxView *_tasksViewBox;
    WLCalendarBoxView *_rightNowViewBox;
    WLCalendarWindowBringToFrontAnimation *_fadeInAnimation;
    WLCalendarWindowBringToFrontAnimation *_fadeOutAnimation;
}

@property (nonatomic) WLCalendarWindowState windowState;

@property (nonatomic) BOOL isFadedOut;

@property (readonly) WLCalendarsController *calendarsController;

- (id)initWithWindow:(WLCalendarWindow *)aWindow;

- (IBAction)showWindow:(id)aSender;

- (IBAction)showNextWeek:(id)aSender;

- (IBAction)showPreviousWeek:(id)aSender;

- (IBAction)showCurrentWeek:(id)aSender;

- (BOOL)canShowNextWeek;

- (BOOL)canShowCurrentWeek;

- (BOOL)canShowPreviousWeek;

- (BOOL)isCurrentWeekShowed;

- (WLCalendarWindow *)window;

/*!
 @abstract      Animates setWindowState.
 @discussion    Takes into account isFadeOut.
 Alpha value of the window at WLFloatingLevelState is always 1.0. Alpha value at WLFinderLevelState depends on isFadeOut property.
 @see           isFadeOut
 */
- (void)setWindowState:(WLCalendarWindowState)newWindowState animated:(BOOL)isAnimated duration:(NSTimeInterval)aDuration;

- (void)flushWindowState;

- (BOOL)isAnimatingWindowState;

@end


typedef enum
{
    BLNarrowSize    = 0,
    BLNormalSize    = 1,
    BLFullSize      = 2,
    BLCustomSize    = 3
} BLSize;


typedef enum BLPosition
{
    BLPositionTopLeft =         0,
    BLPositionTopCenter =       1,
    BLPositionTopRight =        2,
    BLPositionCenterLeft =      3,
    BLPositionCenterCenter =    4,
    BLPositionCenterRight =     5,
    BLPositionBottomLeft =      6,
    BLPositionBottomCenter =    7,
    BLPositionBottomRight =     8
} BLPosition;


typedef enum
{
    WLCalendarCustomLayout = 1,
    WLCalendarNormalLayout = 0,
    WLCalendarToDoLayout = 2,
    WLCalendarRightNowLayout = 3
} WLCalendarLayout;


extern NSSize const BLNarrowMinimumSize;

extern NSSize const BLNormalMinimumSize;

@interface WLCalendarWindowController (Frame)

/*!
 @abstract  Returns frame of the calendar window on the window screen's visible frame in device pixel-aligned screen coordinates.
 @result    If it's impossible to calculate frame, returns NSZeroRect.
 @see       windowFrameOnScreen:withPosition:size:margin:
 @see       windowScreen
 */
- (NSRect)windowFrame;

/*!
 @abstract  Returns screen to show calendar window according to user settings.
 @result    Returns
 1. User selected screen
 2. If 1 doesn't exist, screen with the main menu
 3. If 2 doesn't exist, nil
 */
- (NSScreen *)windowScreen;

/*!
 @abstract  Designated method to calculate window frame.
 @result    If it's impossible to calculate frame, returns NSZeroRect.
 */
- (NSRect)windowFrameOnScreen:(NSScreen *)aScreen withPosition:(BLPosition)aPosition size:(BLSize)aSize;

@end


@interface WLCalendarWindowController (Layout)

/*!
 @abstract Resizes subviews of the contentView of controller's window according to the windowSize property.
 */
- (void)_applyWindowSizeToViews;

- (void)_applyNarrowSizeToViews;

- (void)_applyNormalSizeToViews;

- (void)_applyFullSizeToViews;

- (void)_applyCustomSizeToViews;

/*!
 @abstract Updates the controller's window frame.
 */
- (void)_updateFrame;

/*!
 @abstract Places views to the controller's window.
 */
- (void)_makeViews;

- (CGFloat)fixedInfoViewsWidth;

- (NSRect)dateViewFrame;

- (NSRect)tasksViewFrame;

- (NSRect)rightNowViewFrame;

- (NSRect)weekViewFrame;

- (CGFloat)defaultTasksViewHeight;
- (CGFloat)fullTasksViewHeight;

- (NSSize)minimumSize;

@end

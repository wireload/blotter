//
//  WLCalendarWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindow.h"
#import "WLViewFade.h"
#import "WLCalendarController.h"


@class WLCalendarWeekViewController;
@class WLCalendarTasksViewController;
@class WLCalendarDateViewController;
@class WLCalendarBoxView;


/*!
 @abstract      This class is responsible for sizing and placing its window according to user settings.
 It observes various system notifications to update its subcontrollers appropriately.
 @performance   You SHOULD prepare the controller and its window before you call -showWindow:
 @coclass       WLCalendarWindow The class of controller's window.
 */
@interface WLCalendarWindowController : NSObject <NSWindowDelegate> {
    WLCalendarWindow *window;
    WLViewFade *fadeController;

    WLCalendarWeekViewController *_weekViewController;
    WLCalendarWeekViewController *_rightNowViewController;
    WLCalendarTasksViewController *_tasksViewController;
    WLCalendarDateViewController *_dateViewController;
    WLCalendarBoxView *_tasksViewBox;
    WLCalendarBoxView *_rightNowViewBox;

    BOOL _isWindowShowed;
}

@property (readonly) WLCalendarWindow *window;

@property (readonly) WLViewFade *fadeController;

- (IBAction)showWindow:(id)aSender;

@end


typedef enum {
    BLNarrowSize    = 0,
    BLNormalSize    = 1,
    BLFullSize      = 2,
    BLCustomSize    = 3
} BLSize;


typedef enum BLPosition {
    BLPositionTopLeft,
    BLPositionTopCenter,
    BLPositionTopRight,
    BLPositionCenterLeft,
    BLPositionCenterCenter,
    BLPositionCenterRight,
    BLPositionBottomLeft,
    BLPositionBottomCenter,
    BLPositionBottomRight
} BLPosition;


typedef enum {
    WLCalendarNormalLayout = 0,
    WLCalendarCustomLayout
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

- (void)_applyNormalOrCustomSizeToViews;

- (void)_applyFullSizeToViews;

/*!
 @abstract Updates the controller's window frame.
 */
- (void)_updateFrame;

/*!
 @abstract Places views to the controller's window.
 */
- (void)_placeViews;

- (CGFloat)fixedInfoViewsWidth;

- (NSRect)dateViewFrame;

- (NSRect)tasksViewFrame;

- (NSRect)rightNowViewFrame;

- (NSRect)weekViewFrame;

- (CGFloat)defaultTasksViewHeight;

- (NSSize)minimumSize;

@end

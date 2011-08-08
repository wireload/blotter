//
//  WLCalendarWindowController.h
//  Blotter
//
//  Created by Илья Кулаков on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindow.h"
#import "WLCalendarWeekViewController.h"
#import "WLCalendarTasksViewController.h"
#import "BLCalendarFramer.h"


/*!
 @abstract      This class is responsible for sizing and placing its window according to user settings.
 @classdesign   This class is designed to be created in code. You MUST use -showWindow: method to place controller's window on screen.
 You MUST call this method only once.
 @performance   You SHOULD prepare the controller and its window before you call -showWindow:
 @dependency    Depends on the following user defaults settings: DisplayAllCalendars, Calendars,
 PerDayDate, RollingCalendar.
 @dependency    Observes NSApplicationDidChangeScreenParametersNotification.
 @coclass       WLCalendarWindow The class of controller's window.
 @helper        BLCalendarFramer
 */
@interface WLCalendarWindowController : NSWindowController <NSWindowDelegate> {
    BLSize windowSize;
    BLPosition windowPosition;
    NSNumber *windowScreenIdentifier;

    WLCalendarWeekViewController *_weekViewController;
    WLCalendarTasksViewController *_tasksViewController;

    BOOL _isWindowShowed;
}

/*!
 @abstract Specifies the type of size.
 */
@property (nonatomic) BLSize windowSize;

/*!
 @abstract Specifies the position on the screen.
 */
@property (nonatomic) BLPosition windowPosition;

/*!
 @abstract      Specifies the identifier of preferred screen that should be used to draw the window.
 @discussion    If there is no screen with this identifier, the primary screen is used.
 When screen with this identifier becomes available, the controller automatically moves its window to that screen.
 */
@property (nonatomic, copy) NSNumber *windowScreenIdentifier;

- (id)initWithWindow:(WLCalendarWindow *)aWindow;

- (WLCalendarWindow *)window;

/*!
 @abstract  Returns array of CalCalendar objects depending on DisplayAllCalendars and Calendars preferences.
 */
- (NSArray *)calendarsToDisplay;


/*!
 @abstract Updates the controller's window frame.
 */
- (void)_updateFrame;

- (void)_windowContentViewFrameDidChanged:(NSNotification *)aNotification;

/*!
 @abstract Resizes subviews of the contentView of controller's window according to the windowSize property.
 */
- (void)_applyWindowSizeToViews;

- (void)_applyNarrowSizeToViews;

- (void)_applyNormalSizeToViews;

- (void)_applyFullSizeToViews;

@end

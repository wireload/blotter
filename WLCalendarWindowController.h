//
//  WLCalendarWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindow.h"
#import "BLCalendarFramer.h"
#import "BLFadeController.h"
#import "WLCalendarController.h"


@class WLCalendarWeekViewController;
@class WLCalendarTasksViewController;
@class WLCalendarDateViewController;
@class WLCalendarBoxView;


/*!
 @abstract      This class is responsible for sizing and placing its window according to user settings.
 It observes various system notifications to update its subcontrollers appropriately.
 @performance   You SHOULD prepare the controller and its window before you call -showWindow:
 @dependency    Depends on the following user defaults settings: DisplayAllCalendars, Calendars,
 PerDayDate, RollingCalendar.
 @dependency    Observes NSApplicationDidChangeScreenParametersNotification, NSSystemClockDidChangeNotification,
 NSSystemTimeZoneDidChangeNotification, NSCurrentLocaleDidChangeNotification
 @dependency    Observes NSViewFrameDidChangeNotification posteb by contentView of its window.
 @coclass       WLCalendarWindow The class of controller's window.
 @helper        BLCalendarFramer
 @helper        BLFadeController
 */
@interface WLCalendarWindowController : NSObject <NSWindowDelegate> {
    WLCalendarWindow *window;
    BLSize windowSize;
    BLPosition windowPosition;
    NSNumber *windowScreenIdentifier;
    BLFadeController *fadeController;

    WLCalendarWeekViewController *_weekViewController;
    WLCalendarWeekViewController *_rightNowViewController;
    WLCalendarTasksViewController *_tasksViewController;
    WLCalendarDateViewController *_dateViewController;
    WLCalendarController *_calendarController;
    WLCalendarBoxView *_tasksViewBox;
    WLCalendarBoxView *_rightNowViewBox;

    NSCache *_cache;
    BOOL _isWindowShowed;
}

@property (readonly) WLCalendarWindow *window;

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

@property (readonly) BLFadeController *fadeController;

/*!
 @abstract  Returns array of CalCalendar objects depending on DisplayAllCalendars and Calendars preferences.
 */
- (NSArray *)calendarsToDisplay;

- (IBAction)showWindow:(id)aSender;


/*!
 @abstract Updates the controller's window frame.
 */
- (void)_updateFrame;

- (void)_placeViews;

@end


@interface WLCalendarWindowController (Layout)

/*!
 @abstract Resizes subviews of the contentView of controller's window according to the windowSize property.
 */
- (void)_applyWindowSizeToViews;

- (void)_applyNarrowSizeToViews;

- (void)_applyNormalSizeToViews;

- (void)_applyFullSizeToViews;

- (CGFloat)heightOfTasksAndRightNow;

- (NSRect)dateRect;

- (NSRect)tasksRect;

- (NSRect)rightNowRect;

- (NSRect)weekRect;

@end

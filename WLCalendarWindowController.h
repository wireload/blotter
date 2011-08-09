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


@class WLCalendarWeekViewController;
@class WLCalendarTasksViewController;
@class WLCalendarDateViewController;


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
    WLCalendarTasksViewController *_tasksViewController;
    WLCalendarDateViewController *_dateViewController;

    NSTimer *_nextDayTimer;
    NSCache *_cache;
    BOOL _isWindowShowed;
    struct {
        unsigned int updateCalendar:1;
        unsigned int updateDate:1;
    } _updateFlags;
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

- (void)_windowContentViewFrameDidChanged:(NSNotification *)aNotification;

/*!
 @abstract Resizes subviews of the contentView of controller's window according to the windowSize property.
 */
- (void)_applyWindowSizeToViews;

- (void)_applyNarrowSizeToViews;

- (void)_applyNormalSizeToViews;

- (void)_applyFullSizeToViews;

/*!
 @abstract      Sets a timer to call _updateViews.
 @discussion    Called when NSCurrentLocaleDidChangeNotification is posted.
 */
- (void)_localeChanged:(NSNotification *)aNotification;

/*!
 @abstract      Reloads the view. Invalidates _columnTitleFormat.
 @discussion    Called when either NSSystemClockDidChangeNotification or NSSystemTimeZoneDidChangeNotification is posted.
 */
- (void)_clockChanged:(NSNotification *)aNotification;

- (void)_updateViews;

/*!
 @abstract      Schedules a timer to update view when day ends.
 @discussion    Invalidated and rescheduled every time when the view is reloaded.
 @see           _showNextDay
 */
- (void)_scheduleNextDayTimer;

/*!
 @abstract      Updates view to display new day.
 @discussion    Called by a timer scheduled by _scheduleNextDayTimer.
 @see           _scheduleNextDayTimer
 */
- (void)_showNextDay;

@end

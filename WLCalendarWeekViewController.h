//
//  WLCalendarWeekViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "WLCalendarWeekView.h"


typedef enum
{
    WLCalendarWeekViewKeepsCurrentWeekMode,
    WLCalendarWeekViewKeepsCurrentDateMode
} WLCalendarWeekViewMode;


typedef enum
{
    WLCalendarWeekViewWeekdayTitleFormat,
    WLCalendarWeekViewWeekdayAndMonthdayTitleFormat
} WLCalendarWeekViewTitleFormat;


@class WLDateRange;


@interface WLCalendarWeekViewController : NSViewController <WLCalendarWeekViewDataSource> {
    WLCalendarWeekViewMode mode;
    WLCalendarWeekViewTitleFormat titleFormat;

    NSTimer *_scrollTimer;
    NSTimer *_nextDayTimer;
    NSTimer *_nextWeekTimer;
    NSDate *_representedDate;
    NSCache *_cache;
    NSMutableDictionary *_columnDateRanges;

    // Lifetime of this object is limited to
    // weekView:willAskForDataForColumnsAtIndexes: -> weekView:titleForColumnAtIndex: &
    //                                                weekView:eventsForColumnAtIndex: -> weekViewDidAskForData:
    NSMutableDictionary *_columnsData;
}

@property (nonatomic) WLCalendarWeekViewMode mode;

@property (nonatomic) WLCalendarWeekViewTitleFormat titleFormat;

- (WLCalendarWeekView *)view;

/*!
 @discussion    You have to prepare controller (set its properties, representedObject) before calling this method.
 */
- (void)setView:(WLCalendarWeekView *)newView;

- (NSArray *)representedObject;

- (void)setRepresentedObject:(NSArray *)newRepresentedObject;

- (void)scrollToCurrentHour;

- (NSDate *)firstDate;

- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate;


@property (nonatomic, retain) NSDateComponents *_oneDayComponent;

@property (nonatomic, retain) NSDateComponents *_oneWeekComponent;

@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSDate *_firstWeekday;

@property (nonatomic, retain) NSString *_columnTitleFormat;

@property (nonatomic, retain) NSDate *_representedDate;

@property (nonatomic, retain) NSCalendar *_calendar;

/*!
 @abstract      Updates events affected columns. Columns are determined by dates of changed events.
 @discussion    Called when either CalEventsChangedExternallyNotification or CalEventsChangedNotification is posted.
 */
- (void)_eventsChanged:(NSNotification *)aNotification;

/*!
 @abstract      Sets a timer to call _localeActuallyChanged.
 @discussion    Called when NSCurrentLocaleDidChangeNotification is posted.
 @see           _localeActuallyChanged
 */
- (void)_localeChanged:(NSNotification *)aNotification;

/*!
 @abstract      Reloads the view. Invalidates _firstWeekday, _columnTitleFormat, _calendar, _dateFormatter.
 */
- (void)_localeActuallyChanged;

/*!
 @abstract      Updates view to display new day.
 @discussion    Called by a timer scheduled by _scheduleNextDayTimer.
 @see           _scheduleNextDayTimer
 */
- (void)_showNextDay;

/*!
 @abstract      Updates view to display new week.
 @discussion    Called by a timer scheduled by _scheduleNextWeekTimer.
 @see           _scheduleNextWeekTimer
 */
- (void)_showNextWeek;

/*!
 @abstract      Reloads the view. Invalidates _columnTitleFormat.
 @discussion    Called when either NSSystemClockDidChangeNotification or NSSystemTimeZoneDidChangeNotification is posted.
 */
- (void)_clockChanged;

/*!
 @abstract      Schedules a repeated timer that causes the view to scroll to current hour.
 @see           scrollToCurrentHour
 */
- (void)_scheduleScrollTimer;

/*!
 @abstract      Schedules a timer to update view when day ends.
 @discussion    Invalidated and rescheduled every time when the view is reloaded.
 @see           _showNextDay
 */
- (void)_scheduleNextDayTimer;

/*!
 @abstract      Schedules a timer to update view when week ends.
 @discussion    Invalidated and rescheduled every time when the view is reloaded.
 @see           _showNextWeek
 */
- (void)_scheduleNextWeekTimer;

@end

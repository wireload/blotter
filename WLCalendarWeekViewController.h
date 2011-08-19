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
    WLCalendarWeekViewWeekMode,
    WLCalendarWeekViewDayMode
} WLCalendarWeekViewMode;


typedef enum
{
    WLCalendarWeekViewWeekdayTitleFormat,
    WLCalendarWeekViewWeekdayAndMonthdayTitleFormat
} WLCalendarWeekViewTitleFormat;


@interface WLCalendarWeekViewController : NSObject <WLCalendarWeekViewDataSource> {
    WLCalendarWeekView *view;
    WLCalendarWeekViewMode mode;
    WLCalendarWeekViewTitleFormat titleFormat;
    NSDate *date;
    NSArray *calcalendars;
    NSCalendar *calendar;
    BOOL highlightWeekends;

    NSTimer *_scrollTimer;
    NSCache *_cache;
    NSMutableDictionary *_columnDateRanges;
    // Lifetime of this object is limited to
    // weekView:willAskForDataForColumnsAtIndexes: -> weekView:titleForColumnAtIndex: &
    //                                                weekView:eventsForColumnAtIndex: -> weekViewDidAskForData:
    NSMutableDictionary *_columnsData;
    struct {
        unsigned int updateTitles:1;
        unsigned int updateEvents:1;
        unsigned int reload:1;
    } _updateFlags;
}

@property (readonly) WLCalendarWeekView *view;

@property (nonatomic) WLCalendarWeekViewMode mode;

@property (nonatomic) WLCalendarWeekViewTitleFormat titleFormat;

@property (nonatomic, copy) NSDate *date;

@property (nonatomic, copy) NSArray *calcalendars;

@property (nonatomic, retain) NSCalendar *calendar;

@property (nonatomic) BOOL highlightWeekends;

- (void)updateViewAnimated:(BOOL)isAnimated;

- (void)showNextDayAndScroll;

- (void)showNextWeekAndScroll;

- (CGFloat)currentHour;

- (void)scrollToCurrentHour;

- (NSUInteger)currentDay;

- (void)highlightCurrentDayIfNeeded;

- (NSDate *)firstColumnDate;

- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate;


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSString *_columnTitleFormat;

/*!
 @abstract      Updates events of affected columns which are determined by dates of changed events.
 @discussion    Called when either CalEventsChangedExternallyNotification or CalEventsChangedNotification is posted.
 */
- (void)_eventsChanged:(NSNotification *)aNotification;

/*!
 @abstract      Schedules a repeated timer that causes the view to scroll to current hour.
 @see           scrollToCurrentHour
 */
- (void)_scheduleScrollTimer;

@end

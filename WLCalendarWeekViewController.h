//
//  WLCalendarWeekViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "WLDateRange.h"
#import "WLCalendarWeekView.h"
#import "WLCalendarController.h"


typedef enum
{
    WLCalendarWeekViewWeekMode,
    WLCalendarWeekViewDayMode,
    WLCalendarWeekViewRightNowMode
} WLCalendarWeekViewMode;


typedef enum
{
    WLCalendarWeekViewWeekdayTitleFormat,
    WLCalendarWeekViewWeekdayAndMonthdayTitleFormat
} WLCalendarWeekViewTitleFormat;


@interface WLCalendarWeekViewController : NSViewController <WLCalendarWeekViewDataSource> {
    WLCalendarWeekViewMode mode;
    WLCalendarWeekViewTitleFormat titleFormat;
    BOOL highlightWeekends;

    BOOL isViewLoaded;
    NSCache *_cache;
    // Lifetime of this object is limited to
    // weekView:willAskForDataForColumnsAtIndexes: -> weekView:titleForColumnAtIndex: &
    //                                                weekView:eventsForColumnAtIndex: -> weekViewDidAskForData:
    NSMutableDictionary *_columnsData;
}

@property (nonatomic) WLCalendarWeekViewMode mode;

@property (nonatomic) WLCalendarWeekViewTitleFormat titleFormat;

@property (nonatomic) BOOL highlightWeekends;

- (CGFloat)currentHour;

- (void)scrollToCurrentHour;

- (NSUInteger)indexOfColumnForCurrentDay;

- (void)highlightCurrentDayIfNeeded;

- (NSDate *)firstColumnDate;

- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate;

- (WLCalendarWeekView *)view;

- (WLCalendarController *)representedObject;

- (WLDateRange *)dateRangeForColumnAtIndex:(NSUInteger)anIndex;


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSString *_columnTitleFormat;

/*!
 @abstract  Reloads data if there are only updated events.
 */
- (void)_calEventsDidChange:(NSNotification *)aNotification;

/*!
 @abstract  Reloads data if there are only updated calendars.
 */
- (void)_calCalendarsDidChange:(NSNotification *)aNotification;

@end

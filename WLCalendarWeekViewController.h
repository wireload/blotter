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
    NSMutableDictionary *_columnDateRanges;
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


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSString *_columnTitleFormat;

/*!
 @abstract      Updates events of affected columns which are determined by dates of changed events.
 @discussion    Called when either CalEventsChangedExternallyNotification or CalEventsChangedNotification is posted.
 */
- (void)_eventsDidChange:(NSNotification *)aNotification;

@end

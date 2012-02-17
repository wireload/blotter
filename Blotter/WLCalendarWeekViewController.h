//
//  WLCalendarWeekViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarWeekView.h"


typedef enum
{
    WLCalendarWeekViewWeekdayTitleFormat,
    WLCalendarWeekViewWeekdayAndMonthdayTitleFormat
} WLCalendarWeekViewTitleFormat;


@interface WLCalendarWeekViewController : NSViewController <WLCalendarWeekViewDataSource> {
    WLCalendarWeekViewTitleFormat titleFormat;
    BOOL highlightWeekends;
    BOOL isViewLoaded;

    NSCache *_cache;
    // Lifetime of this object is limited to
    // weekView:willAskForDataForColumnsAtIndexes: -> weekView:titleForColumnAtIndex: &
    //                                                weekView:eventsForColumnAtIndex: -> weekViewDidAskForData:
    NSMutableDictionary *_columnsData;
}

/*!
 @discussion    Default value is WLCalendarWeekViewWeekdayTitleFormat.
 */
@property (nonatomic) WLCalendarWeekViewTitleFormat titleFormat;

/*!
 @discussion    Default value is NO.
 */
@property (nonatomic) BOOL highlightWeekends;

/*!
 @abstract  Returns YES if view is loaded. Otherwise NO.
 */
@property (assign, readonly) BOOL isViewLoaded;

@property (readonly) CGFloat currentHour;

- (WLCalendarWeekView *)view;

- (WLCalendarController *)representedObject;

/*!
 @abstract      Returns events for columns at given indexes.
 @param         aFirstDate is the day of the column at index 0.
 @discussion    E.g. if want to get events for last 3 days of next week, pass the {4, 5, 6} index set and aFirstDate equal to the first date of the week.
 */
- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate;

/*!
 @abstract  Returns date range that column at a given index represents.
 */
- (WLDateRange *)dateRangeForColumnAtIndex:(NSUInteger)anIndex;

/*!
 @abstract   Subclass should implement this method.
 */
- (NSUInteger)indexOfColumnForToday;

/*!
 @abstract   Subclass should implement this method.
 */
- (NSDate *)firstColumnDate;

/*!
 @abstract   Subclass should implement this method to setup aView before it will receive -setupLayer.
 */
- (void)viewWillSetupLayers:(WLCalendarWeekView *)aView;

/*!
 @abstract   Subclass should implement this method and update week view appropriately.
 */
- (void)dateDidChangeFromDate:(NSDate *)anOldDate toDate:(NSDate *)aNewDate;


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSString *_columnTitleFormat;

@property (nonatomic, retain) NSString *_timeFormat;

/*!
 @abstract  Reloads data if there are only updated events.
 */
- (void)_calEventsDidChange:(NSNotification *)aNotification;

@end

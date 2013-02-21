//
//  WLCalendarWeekViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "WLCalendarController.h"
#import <WLFoundation/WLFoundation.h>
#import "WLCalendarWeekView.h"


@interface WLCalendarWeekViewController : NSViewController <WLCalendarWeekViewDataSource> {
    BOOL highlightsWeekends;
    BOOL isViewLoaded;

    NSCache *_cache;
    // Lifetime of this object is limited to
    // weekView:willAskForDataForColumnsAtIndexes: -> weekView:titleForColumnAtIndex: &
    //                                                weekView:eventsForColumnAtIndex: -> weekViewDidAskForData:
    NSMutableDictionary *_columnsData;
}

/*!
 @discussion    Default value is NO.
 */
@property (nonatomic) BOOL highlightsWeekends;

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
 @discussion    E.g. if want to get events for last 3 days of next week, pass the {4, 5, 6} index set and aFirstDate equal to the first date of next week.
 */
- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate;

/*!
 @abstract  Returns date range that column at a given index represents.
 */
- (WLDateRange *)dateRangeForColumnAtIndex:(NSUInteger)anIndex;

/*!
 @abstract   Subclass MUST implement this method.
 */
- (NSUInteger)indexOfColumnForToday;

/*!
 @abstract      Returns date of first column represented by view.
 Subclass MUST implement this method.
 @discussion    Hour MUST be set to noon of the date.
 */
- (NSDate *)firstColumnDate;

/*!
 @abstract   Subclass CAN implement this method to setup aView before it will receive -setupLayer. MUST call super.
 */
- (void)viewWillSetupLayers:(WLCalendarWeekView *)aView;

/*!
 @abstract   Subclass SHOULD implement this method and update week view appropriately.
 */
- (void)representedDateDidChangeFromDate:(NSDate *)anOldDate toDate:(NSDate *)aNewDate;


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSString *_timeFormat;


- (void)_calEventsDidChange:(NSNotification *)aNotification;

@end

//
//  WLCalendarWeekViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWeekView.h"


typedef enum
{
    WLCalendarWeekViewKeepsCurrentWeekMode,
    WLCalendarWeekViewKeepsCurrentDateMode
} WLCalendarWeekViewMode;


@class WLDateRange;


@interface WLCalendarWeekViewController : NSViewController <WLCalendarWeekViewDataSource> {
    WLCalendarWeekViewMode mode;

    NSTimer *_scrollTimer;
    NSTimer *_nextDayTimer;
    NSTimer *_nextWeekTimer;
    NSDate *_representedDate;
    NSCache *_cache;
    WLDateRange* _columnDateRanges[7]; // FIXME: see numberOfColumnsInWeekView:

    // Lifetime of this object is limited to
    // weekView:willAskForDataForColumnsAtIndexes: -> weekView:titleForColumnAtIndex: &
    //                                                weekView:eventsForColumnAtIndex: -> weekViewDidAskForData:
    NSMutableDictionary *_columnsData;
}

@property (nonatomic) WLCalendarWeekViewMode mode;

- (WLCalendarWeekView *)view;

- (void)setView:(WLCalendarWeekView *)newView;

- (NSArray *)representedObject;

- (void)setRepresentedObject:(NSArray *)newRepresentedObject;

- (void)scrollToCurrentHour;


@property (nonatomic, retain) NSDateComponents *_oneDayComponent;

@property (nonatomic, retain) NSDateComponents *_oneWeekComponent;

@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@property (nonatomic, retain) NSDate *_firstWeekday;

@property (nonatomic, retain) NSString *_columnTitleFormat;

@property (nonatomic, retain) NSDate *_representedDate;

@property (nonatomic, retain) NSCalendar *_calendar;

- (void)_eventsChanged:(NSNotification *)aNotification;

- (void)_localeChanged:(NSNotification *)aNotification;

- (void)_perDayDatePreferenceChanged;

- (void)_showNextDay;

- (void)_showNextWeek;

- (void)_clockChanged;

- (void)_scheduleScrollTimer;

- (void)_scheduleNextDayTimer;

- (void)_scheduleNextWeekTimer;

@end

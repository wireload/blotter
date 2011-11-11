//
//  WLCalendarData.h
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>


typedef enum
{
    WLCalendarUnknownType = 0,
    WLCalendarEventType = 1,
    WLCalendarReminderType = 2,
    WLCalendarBothType = 3
} WLCalendarType;


@interface WLCalendarController : NSObject {
    NSCalendar *calendar;
    NSDate *date;
    NSMutableArray *calCalendars;
    NSMutableArray *calEventCalendars;
    NSMutableArray *calReminderCalendars;

    NSTimer *_nextMinuteTimer;
    NSTimer *_nextDayTimer;
}

@property (nonatomic, retain, readonly) NSCalendar *calendar;

@property (nonatomic, retain, readonly) NSDate *date;

/*!
 @discussion    Sorted by uid.
 You may observe it for insertion, deletion and replacement.
 Calendar is replaced if color or title of the new one do not match to the old one.
 */
@property (nonatomic, copy, readonly) NSArray *calCalendars;

/*!
 @discussion    Sorted by uid.
 You may observe it for insertion, deletion and replacement.
 Calendar is replaced if color or title of the new one do not match to the old one.
 */
@property (nonatomic, copy, readonly) NSArray *calEventCalendars;

/*!
 @discussion    Sorted by uid.
 You may observe it for insertion, deletion and replacement.
 Calendar is replaced if color or title of the new one do not match to the old one.
 */
@property (nonatomic, copy, readonly) NSArray *calReminderCalendars;

+ (id)sharedController;

- (void)updateDate;

- (void)updateCalendar;

- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars;

- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars;


- (void)_scheduleNextMinuteTimer;

- (void)_scheduleNextDayTimer;

- (void)_nextDayTimerDidFire;

- (void)_nextMinuteTimerDidFire;

/*!
 @abstract  Updates calendar.
 */
- (void)_localeDidChange:(NSNotification *)aNotification;

/*!
 @abstract  Updates date.
 */
- (void)_systemClockDidChange:(NSNotification *)aNotification;

/*!
 @abstract  Updates calendar.
 */
- (void)_timeZoneDidChange:(NSNotification *)aNotification;

/*!
 @abstract  Inserts/deletes calendars of Calendars setting.
 */
- (void)_calCalendarsDidChange:(NSNotification *)aNotification;

- (NSArray *)_calCalendarsToDisplay;

@end


extern NSString* const WLTempEventNotes;

extern NSString* const WLTempTaskNotes;


@interface CalCalendar (WLCalendarController)

/*
 @discussion May cause to CalCalendarsChangedNotification, CalEventsChangedNotification, CalTasksChangedNotification,
 CalCalendarsChangedExternallyNotification, CalEventsChangedExternallyNotification, CalTasksChangedExternallyNotification.
 Ensure you remove observers before sending this method.
 */
- (WLCalendarType)WL_type;

@end
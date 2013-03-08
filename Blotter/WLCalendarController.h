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
    WLCalendarEventType = 1 << 0,
    WLCalendarReminderType = 1 << 1,
    WLCalendarBothType = WLCalendarEventType | WLCalendarReminderType
} WLCalendarType;


NSString * WLStringFromCalendarType(WLCalendarType aCalendarType);


@interface WLCalendarController : NSObject {
    NSCalendar *calendar;
    NSDate *date;
    NSArray *calCalendarsToDisplay;
    NSArray *calEventCalendarsToDisplay;
    NSArray *calReminderCalendarsToDisplay;
    NSArray *calCalendars;
    NSArray *calEventCalendars;
    NSArray *calReminderCalendars;

    NSTimer *_nextMinuteTimer;
    NSTimer *_nextDayTimer;
}

@property (nonatomic, retain, readonly) NSCalendar *calendar;

@property (nonatomic, retain, readonly) NSDate *date;

/*!
 @abstract      Returns calendars that are set to by a user to display.
 @discussion    Sorted by uid.
 You may observe it for insertion, deletion and replacement.
 Calendar is replaced if color or title of the new one do not match to the old one.
 */
@property (nonatomic, copy, readonly) NSArray *calCalendarsToDisplay;

/*!
 @abstract      Returns event calendars that are set to by a user to display.
 @discussion    Sorted by uid.
 You may observe it for insertion, deletion and replacement.
 Calendar is replaced if color or title of the new one do not match to the old one.
 */
@property (nonatomic, copy, readonly) NSArray *calEventCalendarsToDisplay;

/*!
 @abstract      Returns reminder calendars that are set to by a user to display.
 @discussion    Sorted by uid.
 You may observe it for insertion, deletion and replacement.
 Calendar is replaced if color or title of the new one do not match to the old one.
 */
@property (nonatomic, copy, readonly) NSArray *calReminderCalendarsToDisplay;

/*!
 @abstract      Returns all calendars represented by the Calendars setting.
 */
@property (nonatomic, copy, readonly) NSArray *calCalendars;

/*!
 @abstract      Returns all event calendars represented by the Calendars setting.
 */
@property (nonatomic, copy, readonly) NSArray *calEventCalendars;

/*!
 @abstract      Returns all reminder calendars represented by the Calendars setting.
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

- (NSArray *)_calCalendarsToDisplayEvents;

- (NSArray *)_calCalendarsToDisplayReminders;

- (NSArray *)_calCalendarsToDisplay;

- (NSArray *)_calCalendars;

@end

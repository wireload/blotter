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
    NSMutableArray *calCalendarsToDisplay;
    NSMutableArray *calEventCalendarsToDisplay;
    NSMutableArray *calReminderCalendarsToDisplay;
    NSMutableArray *calCalendars;
    NSMutableArray *calEventCalendars;
    NSMutableArray *calReminderCalendars;

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

+ (void)synchronizeCalendarInUserDefaultsWithCalCalendars;

- (void)updateDate;

- (void)updateCalendar;

- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars;

- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars;

- (void)setIsUsedForEvents:(BOOL)newIsUsed forCalendarWithUID:(NSString *)anUID;

- (BOOL)isCalendarWithUIDUsedForEvents:(NSString *)anUID;

- (void)setIsUsedForReminders:(BOOL)newIsUsed forCalendarWithUID:(NSString *)anUID;

- (BOOL)isCalendarWithUIDUsedForReminders:(NSString *)anUID;


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

/*!
 @param     aPredicate which will be evaluated with calendar dict or nil.
 @abstract  Returns calendars represented by the Calendars setting.
 */
- (NSArray *)_filteredCalCalendars:(NSPredicate *)aPredicate;

- (WLCalendarType)_typeForCalCalendar:(CalCalendar *)aCalCalendar;

+ (WLCalendarType)_typeForCalCalendar:(CalCalendar *)aCalCalendar;

@end


extern NSString* const WLTempEventNotes;

extern NSString* const WLTempTaskNotes;


@interface CalCalendar (WLCalendarController)

/*
 @discussion If AllowsAdvancedCalendarTypeCheck is set to YES in user defaults, may cause CalCalendarsChangedNotification, CalEventsChangedNotification, CalTasksChangedNotification,
 CalCalendarsChangedExternallyNotification, CalEventsChangedExternallyNotification or CalTasksChangedExternallyNotification to be posted.
 Ensure you properly update observers before sending this message.
 */
- (WLCalendarType)WL_type;

@end

//
//  WLCalendarData.h
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>


@interface WLCalendarController : NSObject {
    NSCalendar *calendar;
    NSDate *date;
    NSArray *calCalendars;

    NSTimer *_nextMinuteTimer;
    NSTimer *_nextDayTimer;
}

@property (nonatomic, retain, readonly) NSCalendar *calendar;

@property (nonatomic, retain, readonly) NSDate *date;

@property (nonatomic, copy, readonly) NSArray *calCalendars;

+ (id)sharedController;

- (void)updateDate;

- (void)updateCalendar;


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

- (NSArray *)_calendarsToDisplay;

@end

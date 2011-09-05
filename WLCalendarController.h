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

@property (nonatomic, retain) NSCalendar *calendar;

@property (nonatomic, retain) NSDate *date;

@property (nonatomic, copy) NSArray *calCalendars;


- (void)_localeDidChange:(NSNotification *)aNotification;

- (void)_updateCalendar;

- (void)_scheduleNextMinuteTimer;

- (void)_scheduleNextDayTimer;

- (void)_updateDate;

- (void)_nextDay;

- (void)_clockDidChange:(NSNotification *)aNotification;

- (void)_timeZoneDidChange:(NSNotification *)aNotification;

- (void)_updateClock;

- (NSArray *)_calendarsToDisplay;

@end

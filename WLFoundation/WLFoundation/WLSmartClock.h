//
//  WLSmartClock.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 20.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>


extern NSString* const WLSmartClockLogName;


/*!
    @brief      Represents Calendar and Date in KVO observable manner.

    @discussion Date is updated every 1 minute if computer is attached to AC wall
                and every 5 minutes if computer uses battery.
                Date is also updated when day is changed.
 */
@interface WLSmartClock : NSObject

@property (class, readonly) WLSmartClock *defaultClock;

@property (readonly, copy) NSCalendar *calendar;

@property (readonly) NSDate *date;

- (void)localeDidChange:(NSNotification *)aNotification;

- (void)systemClockDidChange:(NSNotification *)aNotification;

- (void)timeZoneDidChange:(NSNotification *)aNotification;

- (void)scheduleNextMinuteTimer;

- (void)scheduleNextDayTimer;

- (void)nextMinuteTimerDidFire;

- (void)nextDayTimerDidFire;

/*!
    @discussion Main Thread Only.
 */
- (void)dateDidChange;

/*!
    @discussion Main Thread Only.
*/
- (void)calendarDidChange;

@end

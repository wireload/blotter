//
//  WLSmartClock.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 20.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
    @brief      Represents Calendar and Date in KVO observable manner.

    @discussion Date is updated every 1 minute if computer is attached to AC wall
                and every 5 minutes if computer uses battery.
                Date is also updated when day is changed.
 */
@interface WLSmartClock : NSObject

@property (nonatomic, readonly) NSCalendar *calendar;

@property (readonly) NSDate *date;

/*!
    @brief  Returns shared instance.
*/
+ (instancetype)defaultClock;

- (void)localeDidChange:(NSNotification *)aNotification;

- (void)systemClockDidChange:(NSNotification *)aNotification;

- (void)timeZoneDidChange:(NSNotification *)aNotification;

- (void)scheduleNextMinuteTimer;

- (void)scheduleNextDayTimer;

- (void)nextMinuteTimerDidFire;

- (void)nextDayTimerDidFire;

- (void)dateDidChange;

- (void)calendarDidChange;

@end

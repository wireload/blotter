//
//  WLCalReminder
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 26.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalCalendarItem.h>


@protocol WLCalReminder <WLCalCalendarItem>

/*!
    @brief  Determines whether or not the reminder is marked completed.
 */
@property (readonly, getter=isCompleted) BOOL completed;

@property (copy, readonly) NSDate *completionDate;

/*!
    @brief      The date by which the reminder should be completed. May be nil.

    @discussion If current system is 10.6 or below, dueDateComponents does not contain timeZone and calendar.
                Use NSGregorianCalendar calendar with en_US_POSIX locale and time zone with 0 hours from GMT.

                nil value represents no due date.
 */
@property (copy, readonly) NSDateComponents *dueDateComponents;

/*!
    @see WLCalPriority
 */
@property (readonly) NSUInteger priority;

@end

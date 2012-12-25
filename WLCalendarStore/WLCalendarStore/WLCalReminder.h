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

@property (readonly, getter=isCompleted) BOOL completed;

@property (copy, readonly) NSDate *completionDate;

/*!
    If calendar is not set, represents date components of gregorian calendar.
 */
@property (copy, readonly) NSDateComponents *dueDateComponents;

/*!
    @see WLCalPriority
 */
@property (readonly) NSUInteger priority;

@end

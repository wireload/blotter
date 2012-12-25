//
//  WLCalSystemReminder.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalTask.h>
#import <WLCalendarStore/WLCalSystemCalendarItem.h>
#import <WLCalendarStore/WLCalReminder.h>


@interface WLCalSystemReminder : WLCalSystemCalendarItem <WLCalReminder>
{
    BOOL _completed;
    NSDate *_completionDate;
    NSDateComponents *_dueDateComponents;
    NSUInteger _priority;
}

- (instancetype)initWithStore:(id <WLCalStore>)aStore
                   csReminder:(CalTask *)aCSReminder
                  calCalendar:(id<WLCalCalendar>)aCalendar;

@end

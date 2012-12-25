//
//  WLCalSystemEvent.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalEvent.h>
#import <WLCalendarStore/WLCalSystemCalendarItem.h>
#import <WLCalendarStore/WLCalEvent.h>
#import <WLCalendarStore/WLCalTypes.h>


@interface WLCalSystemEvent : WLCalSystemCalendarItem <WLCalEvent>
{
    BOOL _allDay;
    NSDate *_startDate;
    NSDate *_endDate;
    BOOL _isDetached;
    NSDate *_occurrenceDate;
}

- (instancetype)initWithStore:(id <WLCalStore>)aStore
                      csEvent:(CalEvent *)aCSEvent
                  calCalendar:(id <WLCalCalendar>)aCalendar;

@end

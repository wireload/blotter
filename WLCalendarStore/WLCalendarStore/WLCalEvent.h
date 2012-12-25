//
//  WLCalEvent
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 26.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalCalendarItem.h>


@protocol WLCalEvent <WLCalCalendarItem>

@property (readonly, getter=isAllDay) BOOL allDay;

@property (copy, readonly) NSDate *startDate;

@property (copy, readonly) NSDate *endDate;

@property (readonly) BOOL isDetached;

@property (copy, readonly) NSDate *occurrenceDate;

@end

//
//  WLCalendarEventsStorage.h
//  Blotter
//
//  Created by Ilya Kulakov on 19.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>


@interface WLCalendarEventsStorage : NSObject

@property (readonly) NSCalendar *calendar;

@property (readonly) NSCalendarUnit calendarUnit;

- (instancetype)initWithEvents:(NSArray *)anEvents calendar:(NSCalendar *)aCalendar unit:(NSCalendarUnit)aUnit;

- (NSArray *)allDayEventsWithinDateRange:(WLDateRange *)aDateRange;

- (NSArray *)allDayEventsForDate:(NSDate *)aDate;

- (NSArray *)dayEventsWithinDateRange:(WLDateRange *)aDateRange;

- (NSArray *)dayEventsForDate:(NSDate *)aDate;

@end

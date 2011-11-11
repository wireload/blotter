//
//  NSDate+WLDayBoundaries.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSDate+WLDayBoundaries.h"


@implementation NSDate (WLDayBoundaries)

- (NSDate *)WL_startOfDay:(NSCalendar *)aCalendar
{
    NSDate *startDate = nil;
    [aCalendar rangeOfUnit:NSDayCalendarUnit startDate:&startDate interval:NULL forDate:self];
    return startDate;
}

- (NSDate *)WL_endOfDay:(NSCalendar *)aCalendar
{
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [aCalendar rangeOfUnit:NSDayCalendarUnit startDate:&startDate interval:&interval forDate:self];
    return [startDate dateByAddingTimeInterval:interval - 1.0];
}

@end

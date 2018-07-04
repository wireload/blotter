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
    [aCalendar rangeOfUnit:NSCalendarUnitDay startDate:&startDate interval:NULL forDate:self];
    return startDate;
}

- (NSDate *)WL_endOfDay:(NSCalendar *)aCalendar
{
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [aCalendar rangeOfUnit:NSCalendarUnitDay startDate:&startDate interval:&interval forDate:self];
    return [startDate dateByAddingTimeInterval:interval];
}

- (NSDate *)WL_nextHourDate:(NSCalendar *)aCalendar
{
    static NSDateComponents *oneHourComponents = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oneHourComponents = [[NSDateComponents alloc] init];
        oneHourComponents.hour = 1;
    });
    NSDate *nextHour = [aCalendar dateByAddingComponents:oneHourComponents toDate:self options:0];
    NSDate *roundedNextHour = nil;
    [aCalendar rangeOfUnit:NSCalendarUnitHour startDate:&roundedNextHour interval:NULL forDate:nextHour];
    return roundedNextHour;
}

- (NSDate *)WL_noon:(NSCalendar *)aCalendar
{
    NSDateComponents *dateNoonComponents = [aCalendar components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    NSRange hoursRange = [aCalendar rangeOfUnit:NSCalendarUnitHour inUnit:NSCalendarUnitDay forDate:self];
    dateNoonComponents.hour = (NSInteger)(hoursRange.location + hoursRange.length / 2);
    dateNoonComponents.minute = 0;
    dateNoonComponents.second = 0;
    return [aCalendar dateFromComponents:dateNoonComponents];
}

@end

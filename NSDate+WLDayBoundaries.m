//
//  NSDate+WLDayBoundaries.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSDate+WLDayBoundaries.h"


@implementation NSDate (WLDayBoundaries)

- (NSDate *)upperBoundaryWithCalendar:(NSCalendar *)calendar
{
    static const NSUInteger Units = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *components = [calendar components:Units fromDate:self];
    NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:self];
    [components setHour:hoursRange.location];
    NSDate *upperBoundary = [calendar dateFromComponents:components];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:upperBoundary];
    [components setMinute:minutesRange.location];
    upperBoundary = [calendar dateFromComponents:components];
    return upperBoundary;
}

- (NSDate *)lowerBoundaryWithCalendar:(NSCalendar *)calendar
{
    static const NSUInteger Units = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *components = [calendar components:Units fromDate:self];
    NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:self];
    [components setHour:NSMaxRange(hoursRange) - 1];
    NSDate *lowerBoundary = [calendar dateFromComponents:components];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:lowerBoundary];
    [components setMinute:NSMaxRange(minutesRange) - 1];
    lowerBoundary = [calendar dateFromComponents:components];
    return lowerBoundary;
}

@end

//
//  NSCalendar+WLWeekend.m
//  Blotter
//
//  Created by Ilya Kulakov on 21.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSCalendar+WLWeekend.h"


@implementation NSCalendar (WLWeekend)

- (BOOL)isWeekend:(NSUInteger)aWeekday
{
    NSAssert(aWeekday > 0, @"The weekday units are the numbers 1 through N (where for the Gregorian calendar N=7 and 1 is Sunday). See NSCalendar docs.");
    NSUInteger numberOfWeekdays = [self maximumRangeOfUnit:NSWeekdayCalendarUnit].length;
    // Weekdays are 1 based by default. make them 0 based.
    aWeekday -= 1;
    NSUInteger firstWeekday = [self firstWeekday] - 1;
    NSUInteger firstWeekend = (firstWeekday + numberOfWeekdays - 1) % (numberOfWeekdays);
    NSUInteger secondWeekend = (firstWeekday + numberOfWeekdays - 2) % (numberOfWeekdays);
    return (aWeekday == firstWeekend || aWeekday == secondWeekend);
}

@end

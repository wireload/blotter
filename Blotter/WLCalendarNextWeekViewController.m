//
//  WLCalendarNextWeekViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.01.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarNextWeekViewController.h"


@implementation WLCalendarNextWeekViewController

#pragma mark WLCalendarWeekViewController

- (NSDate *)firstColumnDate
{
    NSDate *showedFirstColumnDate = [super firstColumnDate];
    NSCalendar *calendar = [[self representedObject] calendar];
    switch (self.mode) {
        case WLCalendarWeekViewDayMode:
        {
            NSDateComponents *nextWeekDaysComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit
                                                                   fromDate:showedFirstColumnDate];
            [nextWeekDaysComponents setDay:[nextWeekDaysComponents day] + WLNumberOfDaysInWeek];
            return [calendar dateFromComponents:nextWeekDaysComponents];
        }
        case WLCalendarWeekViewWeekMode:
        {
            // To get the next week we first calculate number of days in current week and then append this value to the current day.
            NSRange currentWeekRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:showedFirstColumnDate];
            NSDateComponents *nextWeekComponents = [[NSDateComponents alloc] init];
            [nextWeekComponents setDay:currentWeekRange.length];
            NSDate *nextWeekDate = [calendar dateByAddingComponents:nextWeekComponents toDate:showedFirstColumnDate options:0];
            [nextWeekComponents release];
            // Now nextWeekDate points to some day in the next week. Get a date of the first day in this week.
            NSDate *firstWeekdayInNextWeek = nil;
            [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&firstWeekdayInNextWeek interval:NULL forDate:nextWeekDate];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:firstWeekdayInNextWeek];
            NSDateComponents *firstWeekdayComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                                   fromDate:firstWeekdayInNextWeek];
            [firstWeekdayComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:firstWeekdayComponents];
        }
        default:
            NSAssert(NO, @"You must take into account all possible modes");
            return nil;
    }
}

- (void)highlightCurrentDay
{
    return;
}

- (void)showNextDayAndScroll
{
    [[self view] reloadDataAnimated:YES];
}

- (void)showNextWeekAndScroll
{
    [[self view] reloadDataAnimated:YES];
}

- (NSUInteger)indexOfColumnForCurrentDay
{
    return NSNotFound;
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];
    [self view].showTimeIndicator = NO;
}

@end

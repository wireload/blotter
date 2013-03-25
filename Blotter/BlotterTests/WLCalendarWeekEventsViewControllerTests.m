//
//  WLCalendarWeekEventsViewControllerTests.m
//  Blotter
//
//  Created by Ilya Kulakov on 22.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalendarWeekEventsViewControllerTests.h"
#import "WLCalendarWeekEventsViewController.h"


@implementation WLCalendarWeekEventsViewControllerTests

- (void)testWeekAlignment
{
    WLCalendarWeekEventsViewController *w = [[WLCalendarWeekEventsViewController alloc] initWithNibName:nil bundle:nil];
    w.calendar = [NSCalendar currentCalendar];
    w.date = [NSDate date];
    [w setAlignmentUnit:NSWeekOfMonthCalendarUnit number:1 animated:NO];
    
    WLDateRange *thisWeekRange = [WLDateRange dateRangeWithStartDate:w.date endDate:w.date];
    thisWeekRange = [thisWeekRange dateRangeByAligningCalendarUnit:NSWeekOfMonthCalendarUnit
                                                          calendar:w.calendar
                                                           options:WLAlignOutward];
    STAssertEqualObjects(w.dateRangeOfColumns, thisWeekRange, @"Date ranges are no equal");
}

- (void)testDayAlignment
{
    WLCalendarWeekEventsViewController *w = [[WLCalendarWeekEventsViewController alloc] initWithNibName:nil bundle:nil];
    w.calendar = [NSCalendar currentCalendar];
    w.date = [NSDate date];
    [w setAlignmentUnit:NSDayCalendarUnit number:7 animated:NO];
    
    WLDateRange *thisDayRange = [WLDateRange dateRangeWithStartDate:w.date endDate:w.date];
    thisDayRange = [thisDayRange dateRangeByAligningCalendarUnit:NSDayCalendarUnit
                                                        calendar:w.calendar
                                                         options:WLAlignOutward];
    STAssertEqualObjects(w.dateRangeOfColumns.startDate, thisDayRange.startDate, @"Start dates are no equal");
}

- (void)testSwitchingAlignmentFromWeekToDay
{
    WLCalendarWeekEventsViewController *w = [[WLCalendarWeekEventsViewController alloc] initWithNibName:nil bundle:nil];
    w.calendar = [NSCalendar currentCalendar];
    w.date = [NSDate date];
    [w setAlignmentUnit:NSWeekOfMonthCalendarUnit number:1 animated:NO];

    WLDateRange *thisWeekRange = [WLDateRange dateRangeWithStartDate:w.date endDate:w.date];
    thisWeekRange = [thisWeekRange dateRangeByAligningCalendarUnit:NSWeekOfMonthCalendarUnit
                                                          calendar:w.calendar
                                                           options:WLAlignOutward];
    STAssertEqualObjects(w.dateRangeOfColumns, thisWeekRange, @"Date ranges are no equal");
    
    WLDateRange *thisDayRange = [WLDateRange dateRangeWithStartDate:w.date endDate:w.date];
    thisDayRange = [thisDayRange dateRangeByAligningCalendarUnit:NSDayCalendarUnit
                                                        calendar:w.calendar
                                                         options:WLAlignOutward];
    [w setAlignmentUnit:NSDayCalendarUnit number:7 animated:NO];
    STAssertEqualObjects(w.dateRangeOfColumns.startDate, thisDayRange.startDate, @"Start dates are no equal");
}

@end

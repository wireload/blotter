//
//  WLCalendarRightNowViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.01.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarRightNowViewController.h"
#import "NSDate+WLDayBoundaries.h"


@implementation WLCalendarRightNowViewController


#pragma mark WLCalendarRightNowViewController

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    return 1;
}

- (NSDate *)firstColumnDate
{
    NSParameterAssert([self representedObject] != nil);

    return [[self representedObject] date];
}

- (void)representedDateDidChangeFromDate:(NSDate *)anOldDate toDate:(NSDate *)aNewDate
{
    NSCalendar *calendar = [[self representedObject] calendar];
    // To properly animate date change, we have to know direction, and amount of days to update.
    NSDate *startOfOldDate = [anOldDate WL_startOfDay:calendar];
    NSDate *startOfNewDate = [aNewDate WL_startOfDay:calendar];
    NSInteger daysBetweenDates = [[calendar components:NSDayCalendarUnit fromDate:startOfOldDate toDate:startOfNewDate options:0] day];
    WLCalendarWeekView *v = [self view];
    [v stopAnimations];
    if (daysBetweenDates > 0)
        [v showDays:1 hideDays:1 direction:WLRightToLeftDirection animated:YES];
    else if (daysBetweenDates < 0)
        [v showDays:1 hideDays:1 direction:WLLeftToRightDirection animated:YES];
    [v scrollHour:[self currentHour] animated:YES];
}

- (void)viewWillSetupLayers:(WLCalendarWeekView *)aView
{
    [super viewWillSetupLayers:aView];
    aView.showsAllDayEvents = NO;
}

@end

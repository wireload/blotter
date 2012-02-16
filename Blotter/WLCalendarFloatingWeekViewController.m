//
//  WLCalendarNextWeekViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.01.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarFloatingWeekViewController.h"
#import "NSDate+WLDayBoundaries.h"


@implementation WLCalendarFloatingWeekViewController

#pragma mark Properties
@synthesize mode;
@synthesize weeksOffset;

- (void)setMode:(WLCalendarWeekViewMode)newMode
{
    NSParameterAssert([self representedObject] != nil);

    mode = newMode;
    if (self.isViewLoaded)
    {
        WLCalendarWeekView *v = [self view];
        [v stopAnimations];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [v setIndexOfHighlightedColumn:[self indexOfColumnForToday]];
        [v reloadDataAnimated:NO];
        [CATransaction commit];
    }
}

- (void)setWeeksOffset:(NSInteger)newWeeksOffset
{
    if (newWeeksOffset != weeksOffset)
    {
        NSInteger diff = newWeeksOffset - weeksOffset;
        weeksOffset = newWeeksOffset;
        WLCalendarWeekView *v = [self view];
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.25];
        [v showDays:[self numberOfColumnsInWeekView:v]
           hideDays:[v numberOfColumns]
          direction:(diff > 0) ? WLRightToLeftDirection : WLLeftToRightDirection
           animated:YES];
        [v setIndexOfHighlightedColumn:[self indexOfColumnForToday]];
        [CATransaction commit];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfWeeksOffset
{
    return NO;
}


#pragma mark Methods

- (IBAction)showNextWeek:(id)aSender
{
    if (self.weeksOffset != NSIntegerMax)
        self.weeksOffset += 1;
}

- (IBAction)showPreviousWeek:(id)aSender
{
    if (self.weeksOffset != NSIntegerMin)
        self.weeksOffset -= 1;
}

- (IBAction)showCurrentWeek:(id)aSender
{
    self.weeksOffset = 0;
}


#pragma mark WLCalendarWeekViewController

- (void)viewWillSetupLayers:(WLCalendarWeekView *)aView
{
    [super viewWillSetupLayers:aView];
    aView.fitsDayEvents = YES;
    aView.indexOfHighlightedColumn = [self indexOfColumnForToday];
    aView.showsDayColumnTitle = YES;
}

- (NSDate *)firstColumnDate
{
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSDate *date = [[self representedObject] date];
    NSDateComponents *weekComponents = [[NSDateComponents alloc] init];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        [weekComponents setWeek:self.weeksOffset];
    else
        [weekComponents setWeekOfMonth:self.weeksOffset];
    date = [calendar dateByAddingComponents:weekComponents toDate:date options:0];
    [weekComponents release];

    switch (mode) {
        case WLCalendarWeekViewDayMode:
        {
            NSDateComponents *dateNoonComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:date];
            [dateNoonComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:dateNoonComponents];
        }
        case WLCalendarWeekViewWeekMode:
        {
            NSDate *firstWeekday = nil;
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&firstWeekday interval:NULL forDate:date];
            else
                [calendar rangeOfUnit:NSWeekOfMonthCalendarUnit startDate:&firstWeekday interval:NULL forDate:date];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:firstWeekday];
            NSDateComponents *firstWeekdayNoonComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                                   fromDate:firstWeekday];
            [firstWeekdayNoonComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:firstWeekdayNoonComponents];
        }
    }
}

- (NSUInteger)indexOfColumnForToday
{
    NSParameterAssert([self representedObject] != nil);

    if (self.weeksOffset != 0)
        return NSNotFound;

    switch (self.mode)
    {
        case WLCalendarWeekViewDayMode:
            return 0;
        case WLCalendarWeekViewWeekMode:
        {
            NSCalendar *calendar = [[self representedObject] calendar];
            NSDateComponents *firstColumnDateComponents = [calendar components:NSWeekdayCalendarUnit fromDate:[self firstColumnDate]];
            NSDateComponents *todayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:[[self representedObject] date]];
            NSRange weekdaysRange = NSMakeRange(NSNotFound, 0);
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:[[self representedObject] date]];
            else
                weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekOfMonthCalendarUnit forDate:[[self representedObject] date]];
            /*
            Map weekday indexes into column indexes
            Calendar: gregorian
            First weekday: Tuesday
            Number of days in a week: 7
            0  3   Tuesday
            1  4   Wednesday
            2  5   Thursday
            3  6   Friday
            4  7   Saturday
            5  1   Sunday
            6  2   Monday

            Today is Saturday:
            (7 + (7 - 3)) % 7 = 4

            Today is Monday:
            (7 + (2 - 3)) % 7 = 6
            */
            
            return (weekdaysRange.length + [todayComponents weekday] - [firstColumnDateComponents weekday]) % weekdaysRange.length;
        }
    }
}

- (void)dateDidChangeFromDate:(NSDate *)anOldDate toDate:(NSDate *)aNewDate
{
    NSCalendar *calendar = [[self representedObject] calendar];
    // To properly animate date change, we have to know direction, and amount of days to update.
    NSDate *startOfOldDate = [anOldDate WL_startOfDay:calendar];
    NSDate *startOfNewDate = [aNewDate WL_startOfDay:calendar];
    NSInteger daysBetweenDates = [[calendar components:NSDayCalendarUnit fromDate:startOfOldDate toDate:startOfNewDate options:0] day];
    WLCalendarWeekView *v = [self view];
    if (daysBetweenDates == 0)
        [v scrollHour:[self currentHour] animated:YES];
    else if (daysBetweenDates > 0)
    {
        switch (self.mode)
        {
            case WLCalendarWeekViewWeekMode:
            {
                NSInteger oldWeek = 0;
                NSInteger newWeek = 0;
                if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                {
                    oldWeek = [[calendar components:NSWeekCalendarUnit fromDate:startOfOldDate] week];
                    newWeek = [[calendar components:NSWeekCalendarUnit fromDate:startOfNewDate] week];
                }
                else
                {
                    oldWeek = [[calendar components:NSWeekOfMonthCalendarUnit fromDate:startOfOldDate] weekOfMonth];
                    newWeek = [[calendar components:NSWeekOfMonthCalendarUnit fromDate:startOfNewDate] weekOfMonth];
                }

                if (oldWeek != newWeek)
                    [v showDays:[self numberOfColumnsInWeekView:v] hideDays:[v numberOfColumns] direction:WLRightToLeftDirection animated:YES];
                break;
            }
            case WLCalendarWeekViewDayMode:
                [v showDays:MIN((NSUInteger)daysBetweenDates, [self numberOfColumnsInWeekView:v])
                   hideDays:MIN((NSUInteger)daysBetweenDates, [v numberOfColumns])
                  direction:WLRightToLeftDirection
                   animated:YES];
                break;
        }
        [v scrollHour:[self currentHour] animated:YES];
    }
    else
    {
        switch (self.mode)
        {
            case WLCalendarWeekViewWeekMode:
            {
                NSInteger oldWeek = 0;
                NSInteger newWeek = 0;
                if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                {
                    oldWeek = [[calendar components:NSWeekCalendarUnit fromDate:startOfOldDate] week];
                    newWeek = [[calendar components:NSWeekCalendarUnit fromDate:startOfNewDate] week];
                }
                else
                {
                    oldWeek = [[calendar components:NSWeekOfMonthCalendarUnit fromDate:startOfOldDate] weekOfMonth];
                    newWeek = [[calendar components:NSWeekOfMonthCalendarUnit fromDate:startOfNewDate] weekOfMonth];
                }

                if (oldWeek != newWeek)
                    [v showDays:[self numberOfColumnsInWeekView:v] hideDays:[v numberOfColumns] direction:WLLeftToRightDirection animated:YES];
                break;
            }
            case WLCalendarWeekViewDayMode:
                [CATransaction begin];
                [CATransaction setAnimationDuration:1.5];
                [v showDays:MIN((NSUInteger)-daysBetweenDates, [self numberOfColumnsInWeekView:v])
                   hideDays:MIN((NSUInteger)-daysBetweenDates, [v numberOfColumns])
                  direction:WLLeftToRightDirection
                   animated:YES];
                [CATransaction commit];
                break;
        }
        [v scrollHour:[self currentHour] animated:YES];
    }
}


- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSParameterAssert([self representedObject] != nil);

    switch (self.mode) {
        case WLCalendarWeekViewWeekMode:
        {
            NSCalendar *calendar = [[self representedObject] calendar];
            NSDate *date = [[self representedObject] date];
            NSRange weekdaysRange = NSMakeRange(NSNotFound, 0);
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:date];
            else
                weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekOfMonthCalendarUnit forDate:date];
            return weekdaysRange.length;
        }
        case WLCalendarWeekViewDayMode:
            return [super numberOfColumnsInWeekView:aWeekView];
    }
}

@end

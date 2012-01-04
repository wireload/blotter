//
//  WLCalendarRightNowViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.01.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarRightNowViewController.h"


@implementation WLCalendarRightNowViewController


#pragma mark WLCalendarRightNowViewController

- (void)highlightCurrentDay
{
    return;
}

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    return 1;
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];
    [self view].fitDayEvents = NO;
    [self view].showTitle = NO;
    [self view].showAllDayEvents = NO;
}

@end

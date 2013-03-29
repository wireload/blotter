//
//  WLCalendarRightNowEventsViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 22.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalendarRightNowEventsViewController.h"


@implementation WLCalendarRightNowEventsViewController

#pragma mark NSViewController

- (void)setView:(WLCalendarWeekView *)newView
{
    super.view = newView;

    self.view.showsAllDayEvents = NO;
}

@end

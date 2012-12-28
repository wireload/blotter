//
//  WLCalendarEventsController.m
//  Blotter
//
//  Created by Ilya Kulakov on 28.12.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarEventsController.h"


@implementation WLCalendarEventsController

#pragma mark Properties

- (void)setCalendar:(NSCalendar *)newCalendar
{
    _calendar = newCalendar;
}

- (void)setCachePolicy:(WLCalendarEventsCachePolicy)newCachePolicy
{
    _cachePolicy = newCachePolicy;
}

@end

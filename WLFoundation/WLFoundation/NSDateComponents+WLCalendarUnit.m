//
//  NSDateComponents(WLCalendarUnit).m
//  WLFoundation
//
//  Created by Ilya Kulakov on 22.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "NSDateComponents+WLCalendarUnit.h"


@implementation NSDateComponents (WLCalendarUnit)

- (void)WL_setValue:(NSInteger)newValue forCalendarUnit:(NSCalendarUnit)aUnit
{
    switch (aUnit)
    {
        case NSEraCalendarUnit:
            self.era = newValue;
            break;
        case NSYearCalendarUnit:
            self.year = newValue;
            break;
        case NSMonthCalendarUnit:
            self.month = newValue;
            break;
        case NSDayCalendarUnit:
            self.day = newValue;
            break;
        case NSHourCalendarUnit:
            self.hour = newValue;
            break;
        case NSMinuteCalendarUnit:
            self.minute = newValue;
            break;
        case NSSecondCalendarUnit:
            self.second = newValue;
            break;
        case NSWeekCalendarUnit:
            self.week = newValue;
            break;
        case NSWeekdayCalendarUnit:
            self.weekday = newValue;
            break;
        case NSWeekdayOrdinalCalendarUnit:
            self.weekdayOrdinal = newValue;
            break;
        case NSQuarterCalendarUnit:
            self.quarter = newValue;
            break;
        case NSWeekOfMonthCalendarUnit:
            self.weekOfMonth = newValue;
            break;
        case NSWeekOfYearCalendarUnit:
            self.weekOfYear = newValue;
            break;
        case NSYearForWeekOfYearCalendarUnit:
            self.yearForWeekOfYear = newValue;
            break;
        default:
            [NSException raise:NSInvalidArgumentException format:@"CalendarUnit (%ld) is not supported.", aUnit];
    }
}

@end

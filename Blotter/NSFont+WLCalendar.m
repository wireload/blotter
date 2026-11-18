//
//  WLCalendar.m
//  Blotter
//
//  Created by Илья Кулаков on 11. 8. 25..
//  Copyright 2011  WireLoad. All rights reserved.
//

#import "NSFont+WLCalendar.h"


@implementation NSFont (WLCalendar)

+ (NSFont *)WL_columnTitleFont
{
    return [NSFont fontWithName:@"Helvetica Neue" size:11.0];
}

+ (NSFont *)WL_columnBoldTitleFont
{
    return [NSFont fontWithName:@"Helvetica Neue Bold" size:11.0];
}

+ (NSFont *)WL_dateViewMonthDayFont
{
    return [NSFont fontWithName:@"Helvetica Neue" size:200];
}

+ (NSFont *)WL_dateViewMonthAndYearFont
{
    return [NSFont fontWithName:@"Helvetica Neue Light" size:26.0];
}

+ (NSFont *)WL_dateViewWeekdayFont
{
    return [self WL_dateViewMonthAndYearFont];
}

+ (NSFont *)WL_boxViewTitleFont
{
    return [NSFont fontWithName:@"Helvetica Neue Light" size:26.0];
}

+ (NSFont *)WL_eventTitleFont
{
    return [NSFont fontWithName:@"Helvetica Neue Medium" size:10.0];
}

+ (NSFont *)WL_eventLocationFont
{
    return [NSFont fontWithName:@"Helvetica Neue Italic" size:10.0];
}

+ (NSFont *)WL_taskFont
{
    return [NSFont fontWithName:@"Helvetica Neue" size:15.0];
}

+ (NSFont *)WL_timeRulerMarkerFont
{
    return [NSFont fontWithName:@"Helvetica Neue" size:10.0];
}

@end

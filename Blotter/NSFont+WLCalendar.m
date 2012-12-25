//
//  WLCalendar.m
//  Blotter
//
//  Created by Илья Кулаков on 11. 8. 25..
//  Copyright 2011  WireLoad. All rights reserved.
//

#import "NSFont+WLCalendar.h"


@implementation NSFont (WLCalendar)

+ (CTFontRef)WL_columnTitleFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("HelveticaNeue"), 11.0, NULL) autorelease];
}

+ (CTFontRef)WL_columnBoldTitleFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("HelveticaNeue-Bold"), 11.0, NULL) autorelease];
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

+ (CTFontRef)WL_eventTitleFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("HelveticaNeue-Medium"), 10.0, nil) autorelease];
}

+ (CTFontRef)WL_eventLocationFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("HelveticaNeue-Italic"), 10.0, nil) autorelease];
}

+ (CTFontRef)WL_taskFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("HelveticaNeue"), 15.0, nil) autorelease];
}

+ (CTFontRef)WL_timeRulerMarkerFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("HelveticaNeue"), 10.0, nil) autorelease];
}

@end

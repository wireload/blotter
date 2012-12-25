//
//  NSColor+WLCalendar.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSColor+WLCalendar.h"


@implementation NSColor (WLCalendar)

+ (NSColor *)WL_weekendColor
{
    return [NSColor redColor];
}

+ (NSColor *)WL_columnColor
{
    return [NSColor colorWithCalibratedRed:101.0 / 255.0
                                     green:161.0 / 255.0
                                      blue:165.0 / 255.0
                                     alpha:1.0];
}

+ (NSColor *)WL_dateViewTextShadowColor
{
    return [NSColor colorWithCalibratedRed:47.0 / 255.0
                                     green:47.0 / 255.0
                                      blue:47.0 / 255.0
                                     alpha:0.25];
}

+ (NSColor *)WL_timelineShadowColor
{
    return [NSColor colorWithCalibratedRed:51.0 / 255.0
                                     green:51.0 / 255.0
                                      blue:51.0 / 255.0
                                     alpha:1.0];
}

+ (NSColor *)WL_timelineLineColor
{
    return [NSColor colorWithCalibratedRed:242.0 / 255.0
                                     green:242.0 / 255.0
                                      blue:242.0 / 255.0
                                     alpha:0.75];
}

+ (NSColor *)WL_timelineLineShadowColor
{
    return [NSColor colorWithCalibratedRed:0.0 / 255.0
                                     green:0.0 / 255.0
                                      blue:0.0 / 255.0
                                     alpha:0.25];
}

+ (NSColor *)WL_columnTitleShadowColor
{
    return [NSColor colorWithCalibratedRed:51.0 / 255.0
                                     green:51.0 / 255.0
                                      blue:51.0 / 255.0
                                     alpha:1.0];
}

+ (NSColor *)WL_eventLocationColor
{
    return [NSColor colorWithCalibratedWhite:210.0 / 255.0 alpha:1.0];
}

+ (NSColor *)WL_eventTextShadowColor
{
    return [NSColor colorWithCalibratedRed:0.0 / 255.0
                                     green:0.0 / 255.0
                                      blue:0.0 / 255.0
                                     alpha:0.3];
}

+ (NSColor *)WL_dateViewBackgroundColor
{
    return [NSColor colorWithPatternImage:[NSImage imageNamed:@"calendar-background-center"]];
}

+ (NSColor *)WL_dateViewTextColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)WL_boxViewTitleColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)WL_timeRulerMarkerColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)WL_taskTitleColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)WL_taskTextShadowColor
{
    return [NSColor colorWithCalibratedRed:47.0 / 255.0
                                     green:47.0 / 255.0
                                      blue:47.0 / 255.0
                                     alpha:0.3];
}

+ (NSColor *)WL_windowFrameBackgroundColor
{
    return [[NSColor blackColor] colorWithAlphaComponent:0.25];
}

+ (NSColor *)WL_defaultCalendarColorIfFrameworkFails
{
    return [NSColor blueColor];
}

@end

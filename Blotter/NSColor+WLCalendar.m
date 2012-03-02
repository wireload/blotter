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
    return [NSColor colorWithCalibratedRed:101.0f / 255.0f
                                     green:161.0f / 255.0f
                                      blue:165.0f / 255.0f
                                     alpha:1.0f];
}

+ (NSColor *)WL_dateViewTextShadowColor
{
    return [NSColor colorWithCalibratedRed:47.0f / 255.0f
                                     green:47.0f / 255.0f
                                      blue:47.0f / 255.0f
                                     alpha:0.25f];
}

+ (NSColor *)WL_timelineShadowColor
{
    return [NSColor colorWithCalibratedRed:51.0f / 255.0f
                                     green:51.0f / 255.0f
                                      blue:51.0f / 255.0f
                                     alpha:1.0f];
}

+ (NSColor *)WL_timelineLineColor
{
    return [NSColor colorWithCalibratedRed:242.0f / 255.0f
                                     green:242.0f / 255.0f
                                      blue:242.0f / 255.0f
                                     alpha:0.75f];
}

+ (NSColor *)WL_timelineLineShadowColor
{
    return [NSColor colorWithCalibratedRed:0.0f / 255.0f
                                     green:0.0f / 255.0f
                                      blue:0.0f / 255.0f
                                     alpha:0.25f];
}

+ (NSColor *)WL_columnTitleShadowColor
{
    return [NSColor colorWithCalibratedRed:51.0f / 255.0f
                                     green:51.0f / 255.0f
                                      blue:51.0f / 255.0f
                                     alpha:1.0f];
}

+ (NSColor *)WL_eventLocationColor
{
    return [NSColor colorWithCalibratedWhite:210.0f / 255.0f alpha:1.0f];
}

+ (NSColor *)WL_eventTextShadowColor
{
    return [NSColor colorWithCalibratedRed:0.0f / 255.0f
                                     green:0.0f / 255.0f
                                      blue:0.0f / 255.0f
                                     alpha:0.3f];
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
    return [NSColor colorWithCalibratedRed:47.0f / 255.0f
                                     green:47.0f / 255.0f
                                      blue:47.0f / 255.0f
                                     alpha:0.3f];
}

+ (NSColor *)WL_windowFrameBackgroundColor
{
    return [[NSColor blackColor] colorWithAlphaComponent:0.25f];
}

+ (NSColor *)WL_defaultCalendarColorIfFrameworkFails
{
    return [NSColor blackColor];
}

@end

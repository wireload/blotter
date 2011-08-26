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

+ (NSColor *)WL_tasksColor
{
    return [NSColor colorWithCalibratedRed:101.0f / 255.0f
                                     green:161.0f / 255.0f
                                      blue:165.0f / 255.0f
                                     alpha:0.15f];
}

+ (NSColor *)WL_tasksShadowColor
{
    return [NSColor colorWithCalibratedRed:47.0f / 255.0f
                                     green:47.0f / 255.0f
                                      blue:47.0f / 255.0f
                                     alpha:0.3f];
}

+ (NSColor *)WL_dateShadowColor
{
    return [NSColor colorWithCalibratedRed:47.0f / 255.0f
                                     green:47.0f / 255.0f
                                      blue:47.0f / 255.0f
                                     alpha:0.1f];
}

+ (NSColor *)WL_timelineShadowColor
{
    return [NSColor colorWithCalibratedRed:51.0f / 255.0f
                                     green:51.0f / 255.0f
                                      blue:51.0f / 255.0f
                                     alpha:1.0f];
}

+ (NSColor *)WL_columnTitleShadowColor
{
    return [NSColor colorWithCalibratedRed:51.0f / 255.0f
                                     green:51.0f / 255.0f
                                      blue:51.0f / 255.0f
                                     alpha:1.0f];
}

+ (NSColor *)WL_eventShadowColor
{
    return [NSColor colorWithCalibratedRed:47.0f / 255.0f
                                     green:47.0f / 255.0f
                                      blue:47.0f / 255.0f
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

@end

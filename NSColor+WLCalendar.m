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

@end

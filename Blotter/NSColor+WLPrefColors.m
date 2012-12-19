//
//  NSColor+WLPrefColors.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "NSColor+WLPrefColors.h"


@implementation NSColor (WLPrefColors)

+ (NSColor *)WL_activeDotColor
{
    return [NSColor colorWithCalibratedWhite:0.2f alpha:1.0];
}

+ (NSColor *)WL_activeDotShadowColor
{
    return [[NSColor whiteColor] colorWithAlphaComponent:0.2f];
}

+ (NSColor *)WL_dotColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)WL_dotShadowColor
{
    return [[NSColor blackColor] colorWithAlphaComponent:0.2f];
}

+ (NSColor *)WL_layoutViewTileColor
{
    return [NSColor colorWithPatternImage:[NSImage imageNamed:@"layout-noise"]];
}

@end

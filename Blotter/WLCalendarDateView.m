//
//  WLCalendarDateView.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarDateView.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


@implementation WLCalendarDateView

#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    NSRect bounds = self.bounds;
#ifdef DEBUG_LAYERS
    [[NSColor blackColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    CGContextRef cgContext = [NSGraphicsContext currentContext].graphicsPort;
    CGContextSetAllowsAntialiasing(cgContext, YES);
    CGContextSetShouldAntialias(cgContext, YES);
    CGContextSetAllowsFontSmoothing(cgContext, NO);

    NSShadow *s = [[NSShadow alloc] init];
    s.shadowColor = [NSColor WL_dateViewTextShadowColor];
    s.shadowBlurRadius = 0.0;
    // Shadow direction is /not/ flipped.
    s.shadowOffset = NSMakeSize(0.0, -1.0);
    NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
    p.alignment = NSCenterTextAlignment;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont WL_dateViewMonthDayFont],    NSFontAttributeName,
                                       [NSColor WL_dateViewTextColor],      NSForegroundColorAttributeName,
                                       s,                                   NSShadowAttributeName,
                                       p,                                   NSParagraphStyleAttributeName, nil];
    NSRect monthDayFrame = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, 200.0);
    if (NSIntersectsRect(monthDayFrame, aDirtyRect) && NSContainsRect(bounds, monthDayFrame))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(monthDayFrame);
#endif
        [self.monthDay drawInRect:monthDayFrame withAttributes:attributes];
    }

    NSRect monthAndYearFrame = NSMakeRect(bounds.origin.x, NSMaxY(monthDayFrame) + 10.0, bounds.size.width, 35.0);
    if (NSIntersectsRect(monthAndYearFrame, aDirtyRect) && NSContainsRect(bounds, monthAndYearFrame))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(monthAndYearFrame);
#endif
        attributes[NSFontAttributeName] = [NSFont WL_dateViewMonthAndYearFont];
        [self.monthAndYear drawInRect:monthAndYearFrame withAttributes:attributes];
    }

    NSRect weekdayFrame = NSMakeRect(bounds.origin.x, NSMaxY(monthAndYearFrame), bounds.size.width, 35.0);
    if (NSIntersectsRect(weekdayFrame, aDirtyRect) && NSContainsRect(bounds, weekdayFrame))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(weekdayFrame);
#endif
        attributes[NSFontAttributeName] = [NSFont WL_dateViewWeekdayFont];
        [self.weekday drawInRect:weekdayFrame withAttributes:attributes];
    }
    [NSGraphicsContext restoreGraphicsState];
}

@end

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

#pragma mark Properties
@synthesize monthDay;
@synthesize monthAndYear;
@synthesize weekday;


#pragma mark Methods


#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    NSRect bounds = [self bounds];

    NSShadow *s = [[NSShadow alloc] init];
    [s setShadowColor:[NSColor WL_dateShadowColor]];
    [s setShadowBlurRadius:0.0f];
    [s setShadowOffset:NSMakeSize(0.0f, 1.0f)];
    NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
    [p setAlignment:NSCenterTextAlignment];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont WL_dateViewMonthDayFont],    NSFontAttributeName,
                                       [NSColor WL_dateViewTextColor],      NSForegroundColorAttributeName,
                                       s,                                   NSShadowAttributeName,
                                       p,                                   NSParagraphStyleAttributeName, nil];
    [p release];
    [s release];
    NSRect monthDayFrame = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, 200.0f);
    if (NSIntersectsRect(monthDayFrame, aDirtyRect) && NSContainsRect(bounds, monthDayFrame))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(monthDayRect);
#endif
        [self.monthDay drawInRect:monthDayFrame withAttributes:attributes];
    }

    NSRect monthAndYearFrame = NSMakeRect(bounds.origin.x, NSMaxY(monthDayFrame) + 10.0f, bounds.size.width, 35.0f);
    if (NSIntersectsRect(monthAndYearFrame, aDirtyRect) && NSContainsRect(bounds, monthAndYearFrame))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(monthAndYearRect);
#endif
        [attributes setObject:[NSFont WL_dateViewMonthAndYearFont] forKey:NSFontAttributeName];
        [self.monthAndYear drawInRect:monthAndYearFrame withAttributes:attributes];
    }

    NSRect weekdayFrame = NSMakeRect(bounds.origin.x, NSMaxY(monthAndYearFrame), bounds.size.width, 35.0f);
    if (NSIntersectsRect(weekdayFrame, aDirtyRect) && NSContainsRect(bounds, weekdayFrame))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(weekdayRect);
#endif
        [attributes setObject:[NSFont WL_dateViewWeekdayFont] forKey:NSFontAttributeName];
        [self.weekday drawInRect:weekdayFrame withAttributes:attributes];
    }
}

@end

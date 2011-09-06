//
//  WLCalendarDateView.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarDateView.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSColor+CGColor.h"
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
    NSRect monthDayRect = NSMakeRect(bounds.origin.x, bounds.origin.y - 40, bounds.size.width, 200.0f);
    if (NSIntersectsRect(monthDayRect, aDirtyRect))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(monthDayRect);
#endif
        [self.monthDay drawInRect:monthDayRect withAttributes:attributes];
    }

    NSRect monthAndYearRect = NSMakeRect(bounds.origin.x, NSMaxY(monthDayRect) + 10.0f, bounds.size.width, 35.0f);
    if (NSIntersectsRect(monthAndYearRect, aDirtyRect))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(monthAndYearRect);
#endif
        [attributes setObject:[NSFont WL_dateViewMonthAndYearFont] forKey:NSFontAttributeName];
        [self.monthAndYear drawInRect:monthAndYearRect withAttributes:attributes];
    }

    NSRect weekdayRect = NSMakeRect(bounds.origin.x, NSMaxY(monthAndYearRect), bounds.size.width, 35.0f);
    if (NSIntersectsRect(weekdayRect, aDirtyRect))
    {
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] set];
        NSRectFill(weekdayRect);
#endif
        [attributes setObject:[NSFont WL_dateViewWeekdayFont] forKey:NSFontAttributeName];
        [self.weekday drawInRect:weekdayRect withAttributes:attributes];
    }
}

@end

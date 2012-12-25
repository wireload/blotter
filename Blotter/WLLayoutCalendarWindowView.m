//
//  WLLayoutCalendarWindowView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 23.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutCalendarWindowView.h"
#import "NSColor+WLCalendar.h"


@implementation WLLayoutCalendarWindowView

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    static const CGFloat CalendarWindowFrameLineWidth = 2.0;

    [NSGraphicsContext saveGraphicsState];
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect pathFrame = NSInsetRect([self bounds],
                                   CalendarWindowFrameLineWidth / 2,
                                   CalendarWindowFrameLineWidth / 2);
    [path appendBezierPathWithRoundedRect:pathFrame xRadius:5.0 yRadius:5.0];

    [[[NSColor blackColor] colorWithAlphaComponent:0.25] setFill];
    [path fill];

    [[[NSColor blackColor] colorWithAlphaComponent:0.75] setStroke];
    [path setLineWidth:CalendarWindowFrameLineWidth];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

@end

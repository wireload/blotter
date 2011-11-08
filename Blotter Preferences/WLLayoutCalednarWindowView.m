//
//  WLLayoutBackgroundView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 23.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutCalednarWindowView.h"
#import "NSColor+WLCalendar.h"


@implementation WLLayoutCalednarWindowView

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    static const CGFloat CalendarWindowFrameLineWidth = 5.0f;
    
    [NSGraphicsContext saveGraphicsState];
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect pathFrame = NSInsetRect([self bounds],
                                   CalendarWindowFrameLineWidth / 2,
                                   CalendarWindowFrameLineWidth / 2);
    [path appendBezierPathWithRoundedRect:pathFrame xRadius:5.0f yRadius:5.0f];
    
    [[[NSColor blackColor] colorWithAlphaComponent:0.25f] setFill];
    [path fill];
    
    [[[NSColor blackColor] colorWithAlphaComponent:0.75f] setStroke];
    [path setLineWidth:CalendarWindowFrameLineWidth];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}



@end

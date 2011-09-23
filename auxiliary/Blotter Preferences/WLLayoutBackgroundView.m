//
//  WLLayoutBackgroundView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 23.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutBackgroundView.h"
#import "NSColor+WLCalendar.h"


@implementation WLLayoutBackgroundView

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    [[NSColor WL_windowFrameBackgroundColor] set];
    NSRectFillUsingOperation([self bounds], NSCompositeSourceOver);
    [NSGraphicsContext restoreGraphicsState];
}



@end

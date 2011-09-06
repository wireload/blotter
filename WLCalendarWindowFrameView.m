//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowFrameView.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarWindowFrameView

#pragma mark Methods

+ (CGFloat)borderWidth
{
    return 10.0f;
}


#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect
{
    NSDrawThreePartImage(NSMakeRect(0.0f, 0.0f, [self bounds].size.width, 13.0f),
                         [NSImage imageNamed:@"calendar-background-top-left"],
                         [NSImage imageNamed:@"calendar-background-top"],
                         [NSImage imageNamed:@"calendar-background-top-right"],
                         NO,
                         NSCompositeSourceOver,
                         1.0f,
                         YES);
    NSDrawThreePartImage(NSMakeRect(0.0f, 13.0f, [self bounds].size.width, 69.0f),
                         [NSImage imageNamed:@"calendar-background-right-gradient"],
                         [NSImage imageNamed:@"calendar-background-center"],
                         [NSImage imageNamed:@"calendar-background-left-gradient"],
                         NO,
                         NSCompositeSourceOver,
                         1.0f,
                         YES);
    NSDrawNinePartImage(NSMakeRect(0.0f, 82.0f, [self bounds].size.width, [self bounds].size.height - 82.0f),
                        [NSImage imageNamed:@"calendar-background-left"],
                        [NSImage imageNamed:@"calendar-background-center"],
                        [NSImage imageNamed:@"calendar-background-right"],
                        [NSImage imageNamed:@"calendar-background-left"],
                        [NSImage imageNamed:@"calendar-background-center"],
                        [NSImage imageNamed:@"calendar-background-right"],
                        [NSImage imageNamed:@"calendar-background-bottom-left"],
                        [NSImage imageNamed:@"calendar-background-bottom"],
                        [NSImage imageNamed:@"calendar-background-bottom-right"],
                        NSCompositeSourceOver,
                        1.0f,
                        YES);
}

- (BOOL)isFlipped
{
    return YES;
}

@end

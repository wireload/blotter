//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowBackgroundView.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarWindowBackgroundView

#pragma mark Methods

+ (CGFloat)borderWidth
{
    return 20.0f;
}


#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    NSRect topFrame = NSMakeRect(0.0f,
                                 0.0f,
                                 [self bounds].size.width,
                                 20.0f);
    if (NSIntersectsRect(topFrame, aDirtyRect))
    {
        NSDrawThreePartImage(topFrame,
                             [NSImage imageNamed:@"calendar-background-top-left"],
                             [NSImage imageNamed:@"calendar-background-top"],
                             [NSImage imageNamed:@"calendar-background-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0f,
                             YES);
    }
    
    NSRect middleFrame = NSMakeRect(0.0f,
                                    NSMaxY(topFrame),
                                    [self bounds].size.width,
                                    63.0f);
    if (NSIntersectsRect(middleFrame, aDirtyRect))
    {
        NSDrawThreePartImage(middleFrame,
                             [NSImage imageNamed:@"calendar-background-left-gradient"],
                             [NSImage imageNamed:@"calendar-background-middle-gradient"],
                             [NSImage imageNamed:@"calendar-background-right-gradient"],
                             NO,
                             NSCompositeSourceOver,
                             1.0f,
                             YES);
    }
    
    NSRect bottomFrame = NSMakeRect(0.0f,
                                    NSMaxY(middleFrame),
                                    [self bounds].size.width,
                                    [self bounds].size.height - NSMaxY(middleFrame));
    if (NSIntersectsRect(bottomFrame, aDirtyRect))
    {
        NSDrawNinePartImage(bottomFrame,
                            [NSImage imageNamed:@"calendar-background-left"],
                            [NSImage imageNamed:@"calendar-background-middle"],
                            [NSImage imageNamed:@"calendar-background-right"],
                            [NSImage imageNamed:@"calendar-background-left"],
                            [NSImage imageNamed:@"calendar-background-middle"],
                            [NSImage imageNamed:@"calendar-background-right"],
                            [NSImage imageNamed:@"calendar-background-bottom-left"],
                            [NSImage imageNamed:@"calendar-background-bottom"],
                            [NSImage imageNamed:@"calendar-background-bottom-right"],
                            NSCompositeSourceOver,
                            1.0f,
                            YES);
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

@end

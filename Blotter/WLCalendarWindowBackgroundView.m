//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarWindowBackgroundView.h"

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
#ifndef DEBUG_LAYERS
    WLDrawScaledNinePartImage([self bounds],
                            [NSImage imageNamed:@"calendar-background-top-left"],
                            [NSImage imageNamed:@"calendar-background-top-middle"],
                            [NSImage imageNamed:@"calendar-background-top-right"],
                            [NSImage imageNamed:@"calendar-background-middle-left"],
                            [NSImage imageNamed:@"calendar-background-middle-middle"],
                            [NSImage imageNamed:@"calendar-background-middle-right"],
                            [NSImage imageNamed:@"calendar-background-bottom-left"],
                            [NSImage imageNamed:@"calendar-background-bottom-middle"],
                            [NSImage imageNamed:@"calendar-background-bottom-right"],
                            NSCompositeSourceOver,
                            1.0f,
                            YES);

    NSImage *noiseImage = [NSImage imageNamed:@"noise"];
    NSRect innerArea = NSInsetRect([self bounds], 3.0, 3.0);
    [[NSBezierPath bezierPathWithRoundedRect:innerArea xRadius:5 yRadius:5] setClip];
    
    NSDrawNinePartImage(innerArea, nil, nil, nil, nil, noiseImage, nil, nil, nil, nil, NSCompositeSourceOver, 0.03, NO);

#else
    [[NSColor lightGrayColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)addSubview:(NSView *)aView
{
    NSAssert([[self subviews] count] == 0, @"WLCalendarWindowBackgroundView can have only one subview");
    [super addSubview:aView];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    NSWindow *w = [self window];
    NSView *realContentView = [[self subviews] lastObject];
    [realContentView setFrame:[w contentRectForFrameRect:[w frame]]];
}

@end

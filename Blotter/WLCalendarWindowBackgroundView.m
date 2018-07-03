//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLGraphics.h"
#import "WLCalendarWindowBackgroundView.h"
#import "WLCalendarWindow.h"


static const CGFloat _WLCalendarBackgroundShadowTop = 6.0;

static const CGFloat _WLCalendarBackgroundShadowRight = 9.0;

static const CGFloat _WLCalendarBackgroundShadowBottom = 12.0;

static const CGFloat _WLCalendarBackgroundShadowLeft = 9.0;

static const CGFloat _WLCalendarBackgroundActiveDarkness = 0.20;


@implementation WLCalendarWindowBackgroundView

#pragma mark Methods

+ (NSColor *)backgroundNoisePatternColor
{
    static const CGFloat NoiseOpacity = 0.03;
    static NSColor *NoisePatternColor = nil;
    static dispatch_once_t Once;
    dispatch_once(&Once, ^
    {
        NSImage *transparentNoiseImage = [NSImage imageWithSize:[[NSImage imageNamed:@"calendar-background-noise"] size]
                                                           flipped:NO
                                                    drawingHandler:^BOOL(NSRect aDestinationRect)
            {
                [[NSImage imageNamed:@"calendar-background-noise"] drawInRect:aDestinationRect
                                                                     fromRect:aDestinationRect
                                                                    operation:NSCompositeSourceOver
                                                                     fraction:1.0];
                [[[NSColor clearColor] colorWithAlphaComponent:NoiseOpacity] set];
                NSRectFillUsingOperation(aDestinationRect, NSCompositeDestinationIn);
                return YES;
            }];

        NoisePatternColor = [[NSColor colorWithPatternImage:transparentNoiseImage] retain];
    });
    return NoisePatternColor;
}

+ (NSRect)glassRectForBounds:(NSRect)aBounds
{
    NSRect glassRect = aBounds;
    glassRect.origin.x += _WLCalendarBackgroundShadowLeft + 3.0;
    glassRect.origin.y += _WLCalendarBackgroundShadowTop + 3.0;
    glassRect.size.width -= _WLCalendarBackgroundShadowLeft + 3.0 + _WLCalendarBackgroundShadowRight + 3.0;
    glassRect.size.height -= _WLCalendarBackgroundShadowTop + 3.0 + _WLCalendarBackgroundShadowBottom + 3.0;
    return glassRect;
}

+ (NSRect)contentRectForFrameRect:(NSRect)aFrame
{
    NSRect contentRect = [self glassRectForBounds:aFrame];
    return NSInsetRect(contentRect, 17.0, 17.0);
}

+ (NSRect)frameRectForContentRect:(NSRect)aContentRect
{
    NSRect frameRect = NSInsetRect(aContentRect, -17.0, -17.0);
    frameRect.origin.x -= _WLCalendarBackgroundShadowLeft + 3.0;
    frameRect.origin.y -= _WLCalendarBackgroundShadowTop + 3.0;
    frameRect.size.width += _WLCalendarBackgroundShadowLeft + 3.0 + _WLCalendarBackgroundShadowRight + 3.0;
    frameRect.size.height += _WLCalendarBackgroundShadowTop + 3.0 + _WLCalendarBackgroundShadowBottom + 3.0;
    return frameRect;
}


#pragma mark NSView

- (void)viewWillDraw
{
    dispatch_once(&_didWarmUp, ^{
        [NSImage imageNamed:@"calendar-background-active-top-left"];
        [NSImage imageNamed:@"calendar-background-active-top-middle"];
        [NSImage imageNamed:@"calendar-background-active-top-right"];
        [NSImage imageNamed:@"calendar-background-active-middle-left"];
        [NSImage imageNamed:@"calendar-background-active-middle-middle"];
        [NSImage imageNamed:@"calendar-background-active-middle-right"];
        [NSImage imageNamed:@"calendar-background-active-bottom-left"];
        [NSImage imageNamed:@"calendar-background-active-bottom-middle"];
        [NSImage imageNamed:@"calendar-background-active-bottom-right"];
        [NSImage imageNamed:@"calendar-background-top-left"];
        [NSImage imageNamed:@"calendar-background-top-middle"];
        [NSImage imageNamed:@"calendar-background-top-right"];
        [NSImage imageNamed:@"calendar-background-middle-left"];
        [NSImage imageNamed:@"calendar-background-middle-middle"];
        [NSImage imageNamed:@"calendar-background-middle-right"];
        [NSImage imageNamed:@"calendar-background-bottom-left"];
        [NSImage imageNamed:@"calendar-background-bottom-middle"];
        [NSImage imageNamed:@"calendar-background-bottom-right"];
    });
    [super viewWillDraw];
}

- (void)drawRect:(NSRect)aDirtyRect
{
    BEGIN_TIMING();

    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
#ifndef DEBUG_LAYERS
    NSRect bounds = [self bounds];
    NSRect innerArea = [[self class] glassRectForBounds:bounds];
    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRoundedRect:innerArea xRadius:5 yRadius:5];

    if ([(WLCalendarWindow *)[self window] isFloatingWindow])
    {
        [NSGraphicsContext saveGraphicsState];
        [innerPath addClip];
        CIImage *blurredBackgroundImage = [(WLCalendarWindow *)[self window] cachedBlurredBackgroundImage:NO];
        CGRect blurredRect = [blurredBackgroundImage extent];

        [blurredBackgroundImage drawAtPoint:NSMakePoint(blurredRect.origin.x, blurredRect.origin.y)
                                   fromRect:NSRectFromCGRect(blurredRect)
                                  operation:NSCompositeCopy
                                   fraction:1.0];

        // Slightly darken the background with a blueish tint.
        [[NSColor colorWithCalibratedRed:21.0 / 255.0 green:44.0 / 255.0 blue:73.0 / 255.0 alpha:_WLCalendarBackgroundActiveDarkness] set];
        [innerPath fill];
        [NSGraphicsContext restoreGraphicsState];

        WLDrawScaledNinePartImage(bounds,
                                  [NSImage imageNamed:@"calendar-background-active-top-left"],
                                  [NSImage imageNamed:@"calendar-background-active-top-middle"],
                                  [NSImage imageNamed:@"calendar-background-active-top-right"],
                                  [NSImage imageNamed:@"calendar-background-active-middle-left"],
                                  [NSImage imageNamed:@"calendar-background-active-middle-middle"],
                                  [NSImage imageNamed:@"calendar-background-active-middle-right"],
                                  [NSImage imageNamed:@"calendar-background-active-bottom-left"],
                                  [NSImage imageNamed:@"calendar-background-active-bottom-middle"],
                                  [NSImage imageNamed:@"calendar-background-active-bottom-right"],
                                  NSCompositeSourceOver,
                                  1.0,
                                  [self isFlipped]);
    }
    else
    {
        WLDrawScaledNinePartImage(bounds,
                                  [NSImage imageNamed:@"calendar-background-top-left"],
                                  [NSImage imageNamed:@"calendar-background-top-middle"],
                                  [NSImage imageNamed:@"calendar-background-top-right"],
                                  [NSImage imageNamed:@"calendar-background-middle-left"],
                                  [NSImage imageNamed:@"calendar-background-middle-middle"],
                                  [NSImage imageNamed:@"calendar-background-middle-right"],
                                  [NSImage imageNamed:@"calendar-background-bottom-left"],
                                  [NSImage imageNamed:@"calendar-background-bottom-middle"],
                                  [NSImage imageNamed:@"calendar-background-bottom-right"],
                                  NSCompositeCopy,
                                  1.0,
                                  [self isFlipped]);
    }

    [[WLCalendarWindowBackgroundView backgroundNoisePatternColor] setFill];
    [innerPath fill];
#else
    [[NSColor lightGrayColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    [NSGraphicsContext restoreGraphicsState];

    END_TIMING(@"draw background");
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

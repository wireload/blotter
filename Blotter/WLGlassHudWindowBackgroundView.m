//
//  WLGlassHudView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLGlassHudWindowBackgroundView.h"


static const CGFloat _WLGlassHudBackgroundShadowTop = 6.0;

static const CGFloat _WLGlassHudBackgroundShadowRight = 9.0;

static const CGFloat _WLGlassHudBackgroundShadowBottom = 12.0;

static const CGFloat _WLGlassHudBackgroundShadowLeft = 9.0;

static const CGFloat _WLGlassHudBackgroundActiveDarkness = 0.9;


@implementation WLGlassHudWindowBackgroundView

#pragma mark Methods

+ (NSRect)glassRectForBounds:(NSRect)aBounds
{
    NSRect glassRect = aBounds;
    glassRect.origin.x += _WLGlassHudBackgroundShadowLeft + 3.0;
    glassRect.origin.y += _WLGlassHudBackgroundShadowBottom + 3.0;
    glassRect.size.width -= _WLGlassHudBackgroundShadowLeft + 3.0 + _WLGlassHudBackgroundShadowRight + 3.0;
    glassRect.size.height -= _WLGlassHudBackgroundShadowTop + 3.0 + _WLGlassHudBackgroundShadowBottom + 3.0;
    return glassRect;
}


#pragma mark NSView

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
    return YES;
}

- (BOOL)mouseDownCanMoveWindow
{
    return YES;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    NSRect innerArea = [[self class] glassRectForBounds:[self bounds]];
    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRoundedRect:innerArea xRadius:5 yRadius:5];
    [NSGraphicsContext saveGraphicsState];
    [innerPath addClip];

    // Slightly darken the background with a blueish tint.
    [[NSColor colorWithCalibratedRed:250.0 / 255.0
                               green:250.0 / 255.0
                                blue:250.0 / 255.0
                               alpha:_WLGlassHudBackgroundActiveDarkness] set];
    [innerPath fill];
    [NSGraphicsContext restoreGraphicsState];

    WLDrawScaledNinePartImage([self bounds],
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
                              1.0f,
                              [self isFlipped]);

    NSImage *noiseImage = [NSImage imageNamed:@"noise"];
    [innerPath addClip];
    NSDrawNinePartImage(innerArea,nil, nil, nil, nil, noiseImage, nil, nil, nil, nil, NSCompositeSourceOver, 0.03, [self isFlipped]);
    [NSGraphicsContext restoreGraphicsState];
}

@end

//
//  WLGlassHudView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLGlassHudWindowBackgroundView.h"

static const CGFloat _WLGlassHudBackgroundShadowTop = 6.0;

static const CGFloat _WLGlassHudBackgroundShadowRight = 10.0;

static const CGFloat _WLGlassHudBackgroundShadowBottom = 12.0;

static const CGFloat _WLGlassHudBackgroundShadowLeft = 8.0;

static const CGFloat _WLGlassHudBackgroundActiveDarkness = 0.70;


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
    [NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationHigh;

    NSRect innerArea = [[self class] glassRectForBounds:self.bounds];
    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRoundedRect:innerArea xRadius:5 yRadius:5];
    [NSGraphicsContext saveGraphicsState];

    // Heavily darken the background with an iPhoto like blackish tint.
    [[NSColor colorWithCalibratedRed:18 / 255.0
                               green:18 / 255.0
                                blue:18 / 255.0
                               alpha:_WLGlassHudBackgroundActiveDarkness] set];
    [innerPath fill];
    [NSGraphicsContext restoreGraphicsState];

    WLDrawScaledNinePartImage(self.bounds,
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
                              self.flipped);


    [NSColor.WL_noisePattern setFill];
    [innerPath fill];
    [NSGraphicsContext restoreGraphicsState];
}

@end

//
//  WLGlassHudView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLGlassHudWindowBackgroundView.h"


static const CGFloat _WLTopPadding = 18.0;

static const CGFloat _WLBottomPadding = 53.0;

static const CGFloat _WLLeftPadding = 18.0;

static const CGFloat _WLRightPadding = 18.0;


@implementation WLGlassHudWindowBackgroundView


#pragma mark NSView

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
    return YES;
}

- (BOOL)mouseDownCanMoveWindow
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    WLDrawScaledNinePartImage(bounds,
                        [NSImage imageNamed:@"glass-hud-top-left"],
                        [NSImage imageNamed:@"glass-hud-top"],
                        [NSImage imageNamed:@"glass-hud-top-right"],
                        [NSImage imageNamed:@"glass-hud-middle-left"],
                        [NSImage imageNamed:@"glass-hud-middle"],
                        [NSImage imageNamed:@"glass-hud-middle-right"],
                        [NSImage imageNamed:@"glass-hud-bottom-left"],
                        [NSImage imageNamed:@"glass-hud-bottom"],
                        [NSImage imageNamed:@"glass-hud-bottom-right"],
                        NSCompositeSourceOver,
                        1.0,
                        NO);
}

@end

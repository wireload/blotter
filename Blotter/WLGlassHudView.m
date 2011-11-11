//
//  WLGlassHudView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLGlassHudView.h"


static const CGFloat _WLTopPadding = 18.0;

static const CGFloat _WLBottomPadding = 53.0;

static const CGFloat _WLLeftPadding = 18.0;

static const CGFloat _WLRightPadding = 18.0;


@implementation WLGlassHudView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);
    NSRect bounds = [self bounds];

    WLDrawScaledNinePartImage(bounds, 
                        [NSImage imageNamed:@"glass-hud-top-left"], 
                        [NSImage imageNamed:@"glass-hud-top-middle"], 
                        [NSImage imageNamed:@"glass-hud-top-right"], 
                        [NSImage imageNamed:@"glass-hud-middle-left"], 
                        [NSImage imageNamed:@"glass-hud-middle-middle"], 
                        [NSImage imageNamed:@"glass-hud-middle-right"], 
                        [NSImage imageNamed:@"glass-hud-bottom-left"], 
                        [NSImage imageNamed:@"glass-hud-bottom-middle"], 
                        [NSImage imageNamed:@"glass-hud-bottom-right"], 
                        NSCompositeSourceOver, 
                        1.0, 
                        NO);
}

- (void)mouseDown:(NSEvent *)anEvent
{
    _draggingPoint = [[self window] convertBaseToScreen:[anEvent locationInWindow]];
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    NSWindow *window = [self window];
    NSPoint newPoint = [window convertBaseToScreen:[anEvent locationInWindow]];
    NSSize delta = NSMakeSize(newPoint.x - _draggingPoint.x, newPoint.y - _draggingPoint.y);
    NSRect newFrame = NSOffsetRect([window frame], delta.width, delta.height);
    [window setFrame:newFrame display:YES animate:NO];
    _draggingPoint = newPoint;
}

@end

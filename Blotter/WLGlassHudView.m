//
//  WLGlassHudView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudView.h"

#define NSRectFromSize(size) (NSMakeRect(0, 0, (size).width, (size).height))

/**
 Like NSDrawNinePartImage but scale the middle parts instead of tiling them. This allows some simple gradients
 from edge to edge as long as the detail is such that it scales up and down well with bilinear filtering.
*/
void WLDrawScaledNinePartImage(NSRect bounds, NSImage *topLeftCorner, NSImage *topEdgeFill, NSImage *topRightCorner, NSImage *leftEdgeFill, NSImage *centerFill, NSImage *rightEdgeFill, NSImage *bottomLeftCorner, NSImage *bottomEdgeFill, NSImage *bottomRightCorner, NSCompositingOperation op, CGFloat alphaFraction, BOOL flipped)
{
    NSSize topLeftSize = [topLeftCorner size];
    NSSize bottomRightSize = [bottomRightCorner size];
    CGFloat leftX = 0;
    CGFloat midX = topLeftSize.width;
    CGFloat rightX = bounds.size.width - bottomRightSize.width;
    CGFloat topY = bounds.size.height - topLeftSize.height;
    CGFloat midY = bottomRightSize.height;
    CGFloat bottomY = 0;

    if (flipped) {
        bottomY = topY;
        topY = 0;
    }
    
    [topLeftCorner drawInRect:NSMakeRect(leftX, topY, topLeftSize.width, topLeftSize.height) 
                     fromRect:NSRectFromSize([topLeftCorner size]) 
                    operation:op 
                     fraction:alphaFraction 
               respectFlipped:YES 
                        hints:nil];

    [topEdgeFill drawInRect:NSMakeRect(midX, topY, bounds.size.width - topLeftSize.width - bottomRightSize.width, topLeftSize.height) 
                   fromRect:NSRectFromSize([topEdgeFill size]) 
                  operation:op 
                   fraction:alphaFraction 
             respectFlipped:YES 
                      hints:nil];

    [topRightCorner drawInRect:NSMakeRect(rightX, topY, bottomRightSize.width, topLeftSize.height) 
                      fromRect:NSRectFromSize([topRightCorner size]) 
                     operation:op 
                      fraction:alphaFraction 
                respectFlipped:YES 
                         hints:nil];
    
    [leftEdgeFill drawInRect:NSMakeRect(leftX, midY, topLeftSize.width, bounds.size.height - topLeftSize.height - bottomRightSize.height) 
                  fromRect:NSRectFromSize([leftEdgeFill size]) 
                 operation:op 
                  fraction:alphaFraction 
            respectFlipped:YES 
                     hints:nil];
    
    [centerFill drawInRect:NSMakeRect(midX, midY, bounds.size.width - topLeftSize.width - bottomRightSize.width, bounds.size.height - topLeftSize.height - bottomRightSize.height) 
                  fromRect:NSRectFromSize([centerFill size]) 
                 operation:op 
                  fraction:alphaFraction 
            respectFlipped:YES 
                     hints:nil];
    
    [rightEdgeFill drawInRect:NSMakeRect(rightX, midY, bottomRightSize.width, bounds.size.height - topLeftSize.height - bottomRightSize.height) 
                     fromRect:NSRectFromSize([rightEdgeFill size]) 
                    operation:op 
                     fraction:alphaFraction 
               respectFlipped:YES 
                        hints:nil];
    
    [bottomLeftCorner drawInRect:NSMakeRect(leftX, bottomY, topLeftSize.width, bottomRightSize.height) 
                        fromRect:NSRectFromSize([bottomLeftCorner size]) 
                       operation:op 
                        fraction:alphaFraction 
                  respectFlipped:YES 
                           hints:nil];
    
    [bottomEdgeFill drawInRect:NSMakeRect(midX, bottomY, bounds.size.width - topLeftSize.width - bottomRightSize.width, bottomRightSize.height) 
                      fromRect:NSRectFromSize([bottomEdgeFill size]) 
                     operation:op 
                      fraction:alphaFraction 
                respectFlipped:YES 
                         hints:nil];
    
    [bottomRightCorner drawInRect:NSMakeRect(rightX, bottomY, bottomRightSize.width, bottomRightSize.height) 
                         fromRect:NSRectFromSize([bottomRightCorner size]) 
                        operation:op 
                         fraction:alphaFraction 
                   respectFlipped:YES 
                            hints:nil];
}

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

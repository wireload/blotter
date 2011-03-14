//
//  WLGlassHudView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

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
    
    // Calculate border part sizes
    NSSize bottomBorderSize = NSMakeSize(bounds.size.width, [[NSImage imageNamed:@"glass-hud-border-bottom"] size].height);
    NSSize topBorderSize = NSMakeSize(bounds.size.width, [[NSImage imageNamed:@"glass-hud-border-top"] size].height);
    NSSize centerBorderSize = NSMakeSize(bounds.size.width, bounds.size.height - bottomBorderSize.height - topBorderSize.height);
    
    // Draw border parts
    NSRect bottomBorderFrame = NSMakeRect(0.0, 0.0, bottomBorderSize.width, bottomBorderSize.height);
    if (NSIntersectsRect(dirtyRect, bottomBorderFrame))
    {
        NSDrawThreePartImage(bottomBorderFrame,
                             [NSImage imageNamed:@"glass-hud-border-bottom-left"],
                             [NSImage imageNamed:@"glass-hud-border-bottom"],
                             [NSImage imageNamed:@"glass-hud-border-bottom-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
    
    NSRect centerBorderFrame = NSMakeRect(0.0, NSMaxY(bottomBorderFrame), centerBorderSize.width, centerBorderSize.height);
    if (NSIntersectsRect(dirtyRect, centerBorderFrame))
    {
        [[NSGraphicsContext currentContext] setPatternPhase:centerBorderFrame.origin];
        NSImage *resizedCenterFill = [[NSImage imageNamed:@"glass-hud-border-middle"] copy];
        [resizedCenterFill setSize:NSMakeSize([resizedCenterFill size].width, centerBorderFrame.size.height)];
        NSColor *centerColor = [NSColor colorWithPatternImage:resizedCenterFill];
        [centerColor set];
        NSRectFill(centerBorderFrame);
        [resizedCenterFill release];
    }
    
    NSRect topBorderFrame = NSMakeRect(0.0, NSMaxY(centerBorderFrame), topBorderSize.width, topBorderSize.height);
    if (NSIntersectsRect(dirtyRect, topBorderFrame))
    {
        NSDrawThreePartImage(topBorderFrame,
                             [NSImage imageNamed:@"glass-hud-border-top-left"],
                             [NSImage imageNamed:@"glass-hud-border-top"],
                             [NSImage imageNamed:@"glass-hud-border-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
    
    // Calculate content part sizes
    NSSize bottomContentSize = NSMakeSize(bounds.size.width - _WLLeftPadding - _WLRightPadding, [[NSImage imageNamed:@"glass-hud-content-bottom"] size].height);
    NSSize topContentSize = NSMakeSize(bounds.size.width - _WLLeftPadding - _WLRightPadding, [[NSImage imageNamed:@"glass-hud-content-top"] size].height);
    NSSize centerContentSize = NSMakeSize(bounds.size.width - _WLLeftPadding - _WLRightPadding,
                                          bounds.size.height - _WLTopPadding - _WLBottomPadding - bottomContentSize.height - topContentSize.height);
    
    // Draw content parts
    NSRect bottomContentFrame = NSMakeRect(_WLLeftPadding, _WLBottomPadding, bottomContentSize.width, bottomContentSize.height);
    if (NSIntersectsRect(dirtyRect, bottomContentFrame))
    {
        NSDrawThreePartImage(bottomContentFrame,
                             [NSImage imageNamed:@"glass-hud-content-bottom-left"],
                             [NSImage imageNamed:@"glass-hud-content-bottom"],
                             [NSImage imageNamed:@"glass-hud-content-bottom-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
    
    NSRect centerContentFrame = NSMakeRect(_WLLeftPadding, NSMaxY(bottomContentFrame), centerContentSize.width, centerContentSize.height);
    if (NSIntersectsRect(dirtyRect, centerContentFrame))
    {
        [[NSGraphicsContext currentContext] setPatternPhase:centerContentFrame.origin];
        NSImage *resizedCenterFill = [[NSImage imageNamed:@"glass-hud-content-middle"] copy];
        [resizedCenterFill setSize:NSMakeSize([resizedCenterFill size].width, centerContentFrame.size.height)];
        NSColor *centerColor = [NSColor colorWithPatternImage:resizedCenterFill];
        [centerColor set];
        NSRectFillUsingOperation(centerContentFrame, NSCompositeSourceOver);
        [resizedCenterFill release];
    }
    
    NSRect topContentFrame = NSMakeRect(_WLLeftPadding, NSMaxY(centerContentFrame), topContentSize.width, topContentSize.height);
    if (NSIntersectsRect(dirtyRect, topContentFrame))
    {
        NSDrawThreePartImage(topContentFrame,
                             [NSImage imageNamed:@"glass-hud-content-top-left"],
                             [NSImage imageNamed:@"glass-hud-content-top"],
                             [NSImage imageNamed:@"glass-hud-content-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
}

- (void)mouseDown:(NSEvent *)event
{	
	NSWindow *window = [self window];
	NSPoint originalMouseLocation = [window convertBaseToScreen:[event locationInWindow]];
	NSRect originalFrame = [window frame];
	
    while (YES)
	{
        NSEvent *newEvent = [window nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		
        if ([newEvent type] == NSLeftMouseUp)
            break;
		
		NSPoint newMouseLocation = [window convertBaseToScreen:[newEvent locationInWindow]];
		NSPoint delta = NSMakePoint(newMouseLocation.x - originalMouseLocation.x, newMouseLocation.y - originalMouseLocation.y);
		
		NSRect newFrame = originalFrame;
		
        newFrame.origin.x += delta.x;
        newFrame.origin.y += delta.y;
        
		[window setFrame:newFrame display:YES animate:NO];
	}
}

@end

//
//  WLCalendarBoxView.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarBoxView.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"
#import "WLSoftEdgeLayer.h"


static const CGFloat _WLXPadding = 26.0f;

static const CGFloat _WLYPadding = 26.0f;

static const CGFloat _WLMysteriousExtraLeftSpace = 2.0f;

static const CGFloat _WLMysteriousExtraBottomSpace = 4.0f;

@implementation WLCalendarBoxView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        [self setAutoresizesSubviews:NO];
    }
    return self;
}


#pragma mark Properties
@synthesize title;
@dynamic contentView;
@synthesize softEdges;

- (NSView *)contentView
{
    return contentView;
}

- (void)setContentView:(NSView *)newContentView
{
    [newContentView setFrame:[self _contentFrame]];
    [newContentView setAutoresizingMask:NSViewHeightSizable];
    if (contentView != nil)
        [self replaceSubview:contentView with:newContentView];
    else
        [self addSubview:newContentView];
    contentView = newContentView;
    [contentView setNeedsDisplay:YES];
    self.softEdges = softEdges;
}

- (void)setSoftEdges:(BOOL)newSoftEdges
{
    softEdges = newSoftEdges;
    if (![self.contentView wantsLayer])
        return;
    else if (self.softEdges)
        [self.contentView layer].mask = [WLSoftEdgeLayer layer];
    else
        [self.contentView layer].mask = nil;
}


#pragma mark Methods

#pragma mark Private

- (NSDictionary *)_titleAttributes
{
    NSShadow *s = [[NSShadow alloc] init];
    [s setShadowColor:[NSColor WL_taskTextShadowColor]];
    [s setShadowBlurRadius:0.0f];
    // View is flipped
    [s setShadowOffset:NSMakeSize(0.0f, -1.0f)];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont WL_boxViewTitleFont],   NSFontAttributeName,
                                [NSColor WL_boxViewTitleColor], NSForegroundColorAttributeName,
                                s,                               NSShadowAttributeName, nil];
    [s release];
    return attributes;
}

- (NSRect)_titleFrame
{
    NSRect bounds = [self bounds];
    return NSIntegralRect(NSMakeRect(NSMinX(bounds) + _WLXPadding / 2 + _WLMysteriousExtraLeftSpace,
                                     NSMinY(bounds) + _WLYPadding / 2,
                                     NSWidth(bounds) - _WLXPadding,
                                     34.0f));
}

- (NSRect)_contentFrame
{
    NSRect bounds = [self bounds];
    NSRect titleFrame = [self _titleFrame];
    CGFloat yTopMargin = 10.0f;
    CGFloat yBottomMargin = _WLYPadding / 2 + _WLMysteriousExtraBottomSpace;
    if (self.softEdges)
    {
        yTopMargin = 5.0f;
        yBottomMargin = 14.0f;
    }
    return NSIntegralRect(NSMakeRect(NSMinX(bounds) + _WLXPadding / 2 + _WLMysteriousExtraLeftSpace,
                                     NSMaxY(titleFrame) + yTopMargin,
                                     NSWidth(bounds) - _WLXPadding,
                                     NSHeight(bounds) - NSMaxY(titleFrame) - yTopMargin - yBottomMargin));
}


#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    // (0, 0) is top left.
    [NSGraphicsContext saveGraphicsState];
    NSRect bounds = [self bounds];
#ifndef DEBUG_LAYERS
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setShouldAntialias:YES];
    [context setImageInterpolation:NSImageInterpolationHigh];

    WLDrawScaledNinePartImage(bounds, 
                              [NSImage imageNamed:@"info-top-left"], 
                              [NSImage imageNamed:@"info-top-middle"], 
                              [NSImage imageNamed:@"info-top-right"], 
                              [NSImage imageNamed:@"info-middle-left"], 
                              [NSImage imageNamed:@"info-middle-middle"], 
                              [NSImage imageNamed:@"info-middle-right"], 
                              [NSImage imageNamed:@"info-bottom-left"], 
                              [NSImage imageNamed:@"info-bottom-middle"], 
                              [NSImage imageNamed:@"info-bottom-right"],
                              NSCompositeSourceOver, 
                              1.0, 
                              YES);

    [NSGraphicsContext restoreGraphicsState];

#else
    [[NSColor blackColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetAllowsAntialiasing(cgContext, YES);
    CGContextSetShouldAntialias(cgContext, YES);
    CGContextSetAllowsFontSmoothing(cgContext, NO);
    
    NSRect titleFrame = [self _titleFrame];
    if (NSIntersectsRect(titleFrame, aDirtyRect) && NSContainsRect(bounds, titleFrame))
        [self.title drawInRect:titleFrame withAttributes:[self _titleAttributes]];

    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setFrame:(NSRect)newFrameRect
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [super setFrame:newFrameRect];
    [self.contentView setFrame:[self _contentFrame]];
    [self.contentView layer].mask.frame = NSRectToCGRect([self.contentView bounds]);
    [[self.contentView layer].mask setNeedsLayout];
    [[self.contentView layer].mask layoutIfNeeded];
    [CATransaction commit];
}

@end

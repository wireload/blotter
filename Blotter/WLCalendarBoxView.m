//
//  WLCalendarBoxView.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLCalendarBoxView.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"
#import "WLSoftEdgeLayer.h"


static const CGFloat _WLXPadding = 26.0;

static const CGFloat _WLYPadding = 26.0;

static const CGFloat _WLMysteriousExtraLeftSpace = 2.0;

static const CGFloat _WLMysteriousExtraBottomSpace = 4.0;

@implementation WLCalendarBoxView

- (instancetype)initWithFrame:(NSRect)aFrameRect
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
    newContentView.frame = [self _contentFrame];
    newContentView.autoresizingMask = NSViewHeightSizable;
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
    if (!(self.contentView).wantsLayer)
        return;
    else if (self.softEdges)
        (self.contentView).layer.mask = [WLSoftEdgeLayer layer];
    else
        (self.contentView).layer.mask = nil;
}


#pragma mark Methods

#pragma mark Private

- (NSDictionary *)_titleAttributes
{
    NSShadow *s = [[NSShadow alloc] init];
    s.shadowColor = [NSColor WL_taskTextShadowColor];
    s.shadowBlurRadius = 0.0;
    // View is flipped
    s.shadowOffset = NSMakeSize(0.0, -1.0);
    NSDictionary *attributes = @{NSFontAttributeName: [NSFont WL_boxViewTitleFont],
                                NSForegroundColorAttributeName: [NSColor WL_boxViewTitleColor],
                                NSShadowAttributeName: s};
    [s release];
    return attributes;
}

- (NSRect)_titleFrame
{
    NSRect bounds = self.bounds;
    return NSIntegralRect(NSMakeRect(NSMinX(bounds) + _WLXPadding / 2 + _WLMysteriousExtraLeftSpace,
                                     NSMinY(bounds) + _WLYPadding / 2,
                                     NSWidth(bounds) - _WLXPadding,
                                     34.0));
}

- (NSRect)_contentFrame
{
    NSRect bounds = self.bounds;
    NSRect titleFrame = [self _titleFrame];
    CGFloat yTopMargin = 10.0;
    CGFloat yBottomMargin = _WLYPadding / 2 + _WLMysteriousExtraBottomSpace;
    if (self.softEdges)
    {
        yTopMargin = 5.0;
        yBottomMargin = 14.0;
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
    NSRect bounds = self.bounds;
#ifndef DEBUG_LAYERS
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setShouldAntialias:YES];
    context.imageInterpolation = NSImageInterpolationHigh;

    WLDrawScaledNinePartImage(bounds,
                              [NSImage imageNamed:@"box-top-left"],
                              [NSImage imageNamed:@"box-top-middle"],
                              [NSImage imageNamed:@"box-top-right"],
                              [NSImage imageNamed:@"box-middle-left"],
                              [NSImage imageNamed:@"box-middle-middle"],
                              [NSImage imageNamed:@"box-middle-right"],
                              [NSImage imageNamed:@"box-bottom-left"],
                              [NSImage imageNamed:@"box-bottom-middle"],
                              [NSImage imageNamed:@"box-bottom-right"],
                              NSCompositeSourceOver,
                              1.0,
                              YES);

    [NSGraphicsContext restoreGraphicsState];

#else
    [[NSColor blackColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    CGContextRef cgContext = [NSGraphicsContext currentContext].graphicsPort;
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
    super.frame = newFrameRect;
    (self.contentView).frame = [self _contentFrame];
    (self.contentView).layer.mask.frame = NSRectToCGRect((self.contentView).bounds);
    [(self.contentView).layer.mask setNeedsLayout];
    [(self.contentView).layer.mask layoutIfNeeded];
    [CATransaction commit];
}

@end

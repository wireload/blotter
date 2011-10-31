//
//  WLCalendarBoxView.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarBoxView.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"
#import "WLSoftEdgeLayer.h"


static const CGFloat _WLXPadding = 26.0f;

static const CGFloat _WLYPadding = 26.0f;

static const CGFloat _WLMysteriousExtraLeftSpace = 2.0f;

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
    CGFloat yBottomMargin = _WLYPadding / 2;
    if (self.softEdges)
    {
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
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setShouldAntialias:YES];
    [context setImageInterpolation:NSImageInterpolationHigh];

    if ([self wantsLayer])
    {
        [[NSColor WL_windowFrameBackgroundColor] set];
        NSRectFill(aDirtyRect);
    }

    NSRect bounds = [self bounds];
    NSSize bottomSize = NSMakeSize(bounds.size.width, [[NSImage imageNamed:@"info-bottom"] size].height);
    NSSize topSize = NSMakeSize(bounds.size.width, [[NSImage imageNamed:@"info-top"] size].height);
    NSSize middleSize = NSMakeSize(bounds.size.width, bounds.size.height - bottomSize.height - topSize.height);

    static const CGFloat AlphaFraction = 1.0f;

    NSRect topFrame = NSMakeRect(NSMinX(bounds), NSMinY(bounds), topSize.width, topSize.height);
    if (NSIntersectsRect(topFrame, aDirtyRect))
    {
        NSDrawThreePartImage(topFrame,
                             [NSImage imageNamed:@"info-top-left"],
                             [NSImage imageNamed:@"info-top"],
                             [NSImage imageNamed:@"info-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             AlphaFraction,
                             YES);
    }

    NSRect middleFrame = NSMakeRect(NSMinX(bounds), NSMaxY(topFrame), middleSize.width, middleSize.height);
    if (NSIntersectsRect(middleFrame, aDirtyRect))
    {
        [(NSImage *)[NSImage imageNamed:@"info-middle-left"] drawInRect:NSMakeRect(0.0f,
                                                                                   middleFrame.origin.y,
                                                                                   2.0f,
                                                                                   middleFrame.size.height)
                                                               fromRect:NSZeroRect
                                                              operation:NSCompositeSourceOver
                                                               fraction:AlphaFraction
                                                         respectFlipped:YES
                                                                  hints:nil];
        [(NSImage *)[NSImage imageNamed:@"info-middle"] drawInRect:NSMakeRect(2.0f,
                                                                              middleFrame.origin.y,
                                                                              middleFrame.size.width - 4.0f,
                                                                              middleFrame.size.height)
                                                          fromRect:NSZeroRect
                                                         operation:NSCompositeSourceOver
                                                          fraction:AlphaFraction
                                                    respectFlipped:YES
                                                             hints:nil];
        [(NSImage *)[NSImage imageNamed:@"info-middle-right"] drawInRect:NSMakeRect(middleFrame.size.width - 2.0f,
                                                                                    middleFrame.origin.y,
                                                                                    2.0f,
                                                                                    middleFrame.size.height)
                                                                fromRect:NSZeroRect
                                                               operation:NSCompositeSourceOver
                                                                fraction:AlphaFraction
                                                          respectFlipped:YES
                                                                   hints:nil];
    }

    NSRect bottomFrame = NSMakeRect(NSMinX(bounds), NSMaxY(middleFrame), bottomSize.width, bottomSize.height);
    if (NSIntersectsRect(bottomFrame, aDirtyRect))
    {
        NSDrawThreePartImage(bottomFrame,
                             [NSImage imageNamed:@"info-bottom-left"],
                             [NSImage imageNamed:@"info-bottom"],
                             [NSImage imageNamed:@"info-bottom-right"],
                             NO,
                             NSCompositeSourceOver,
                             AlphaFraction,
                             YES);
    }

    [NSGraphicsContext saveGraphicsState];
    // Gradient is already applied to top images.
    NSGradient *whiteToTransparentGradient = [[NSGradient alloc] initWithStartingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.125f]
                                                                           endingColor:[NSColor clearColor]];
    // Images have 1px stroke.
    NSRect gradientFrame = NSInsetRect(bounds, 1.0f, 0.0f);
    gradientFrame.size.height -= topSize.height;
    gradientFrame.origin.y += topSize.height;
    [whiteToTransparentGradient drawInRect:gradientFrame angle:90];
    [whiteToTransparentGradient release];
    [NSGraphicsContext restoreGraphicsState];

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
    [super setFrame:newFrameRect];
    [self.contentView setFrame:[self _contentFrame]];
    [self.contentView layer].mask.frame = NSRectToCGRect([self.contentView bounds]);
}

@end

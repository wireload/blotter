//
//  WLLayoutArrangementView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLLayoutArrangementView.h"
#import "NSColor+WLPrefColors.h"
#import "NSColor+WLCalendar.h"


@implementation WLLayoutArrangementView

#pragma mark Methods

- (CGFloat)positionOfDividerAtIndex:(NSInteger)anIndex
{
    __auto_type arrangedSubviews = self.arrangedSubviews;
    __auto_type precedingView = arrangedSubviews[(NSUInteger)anIndex];
    __auto_type followingView = arrangedSubviews[(NSUInteger)anIndex + 1];

    if (![self isSubviewCollapsed:precedingView])
        return self.isVertical ? NSMaxX(precedingView.frame) : NSMaxY(precedingView.frame);
    else
        return (self.isVertical ? NSMinX(followingView.frame) : NSMinY(followingView.frame)) - self.dividerThickness;
}

#pragma mark Private

- (NSImage *)_dividerImage
{
    return [NSImage imageNamed:self.isVertical ? @"preferences-positioning-mockup-handle-vertical" : @"preferences-positioning-mockup-handle-horizontal"];
}

#pragma mark NSSplitView

- (void)setVertical:(BOOL)newVertical
{
    [super setVertical:newVertical];
    [self invalidateIntrinsicContentSize];
}

- (void)setArrangesAllSubviews:(BOOL)newArrangesAllSubviews
{
    [super setArrangesAllSubviews:newArrangesAllSubviews];
    [self invalidateIntrinsicContentSize];
}

- (CGFloat)dividerThickness
{
    return 9.0;
}

- (NSColor *)dividerColor
{
    return NSColor.clearColor;
}

- (void)drawDividerInRect:(NSRect)aRect
{
    __auto_type dividerImage = [self _dividerImage];
    [dividerImage drawInRect:NSMakeRect(NSMinX(aRect) + NSWidth(aRect) / 2.0 - dividerImage.size.width / 2.0,
                                        NSMinY(aRect) + NSHeight(aRect) / 2.0 - dividerImage.size.height / 2.0,
                                        dividerImage.size.width,
                                        dividerImage.size.height)];
}

#pragma mark NSView

- (void)didAddSubview:(NSView *)aSubview
{
    [super didAddSubview:aSubview];
    [self invalidateIntrinsicContentSize];
}

- (void)willRemoveSubview:(NSView *)aSubview
{
    [super willRemoveSubview:aSubview];
    [self invalidateIntrinsicContentSize];
}

- (NSSize)intrinsicContentSize
{
    CGFloat numberOfDividers = self.arrangesAllSubviews ? MAX(self.subviews.count - 1, 0) : MAX(self.arrangedSubviews.count - 1, 0);
    __auto_type dividerImage = [self _dividerImage];
    NSSize size = dividerImage.size;

    if (self.isVertical)
        size.width *= numberOfDividers;
    else
        size.height *= numberOfDividers;

    return size;
}

@end


#pragma mark - WLLayoutView

@implementation WLLayoutArrangementPaneAuxView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
}

#pragma mark NSView

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    static const CGFloat RoundRadius = 2.0;

    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext.imageInterpolation = NSImageInterpolationHigh;
    WLDrawScaledNinePartImage(self.bounds,
                              [NSImage imageNamed:@"preferences-layout-area-top-left"],
                              [NSImage imageNamed:@"preferences-layout-area-top-centre"],
                              [NSImage imageNamed:@"preferences-layout-area-top-right"],
                              [NSImage imageNamed:@"preferences-layout-area-centre-left"],
                              [NSImage imageNamed:@"preferences-layout-area-centre-centre"],
                              [NSImage imageNamed:@"preferences-layout-area-centre-right"],
                              [NSImage imageNamed:@"preferences-layout-area-bottom-left"],
                              [NSImage imageNamed:@"preferences-layout-area-bottom-centre"],
                              [NSImage imageNamed:@"preferences-layout-area-bottom-right"],
                              NSCompositeSourceOver,
                              1.0,
                              self.isFlipped);
    [NSGraphicsContext restoreGraphicsState];

    // Noise helps to hide interpolation artifacts from stretching.
    [NSGraphicsContext saveGraphicsState];
    NSRect tileFrame = NSInsetRect(self.bounds, 2.0, 1.0);
    if (NSWidth(tileFrame) >= RoundRadius && NSHeight(tileFrame) >= RoundRadius)
    {
        [[NSBezierPath bezierPathWithRoundedRect:tileFrame
                                         xRadius:RoundRadius
                                         yRadius:RoundRadius] setClip];
    }
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"preferences-layout-noise"]] setFill];
    NSRectFillUsingOperation(tileFrame, NSCompositeSourceOver);
    [NSGraphicsContext restoreGraphicsState];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(9.0, 8.0);
}

@end

//
//  WLLayoutArrangementView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLLayoutArrangementView.h"


@implementation WLDividerRange

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)aZone
{
    WLDividerRange *position = [self.class new];
    position.min = self.min;
    position.max = self.max;
    position.current = self.current;
    return position;
}

#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, current: %.1f, range: [%.1f, %.1f]>",
            self.className, self, self.current, self.min, self.max];
}

@end


@implementation WLLayoutArrangementView

#pragma mark Properties

- (CGFloat)distributableSize
{
    NSUInteger numberOfSubviews = self.arrangedSubviews.count;
    NSUInteger numberOfDividers = numberOfSubviews - 1;
    CGFloat dividerThickness = self.dividerThickness;
    return (self.isVertical ? NSWidth(self.bounds) : NSHeight(self.bounds)) - dividerThickness * numberOfDividers;
}

- (NSArray<NSNumber *> *)arrangedSubviewsSizeRatios
{
    __auto_type arrangedSubviews = self.arrangedSubviews;
    CGFloat distributableSize = self.distributableSize;

    __auto_type ratios = [NSMutableArray arrayWithCapacity:arrangedSubviews.count];
    for (NSView *v in arrangedSubviews)
    {
        if ([self isSubviewCollapsed:v])
            [ratios addObject:@0.0];
        else
            [ratios addObject:@((self.isVertical ? NSWidth(v.frame) : NSHeight(v.frame)) / distributableSize)];
    }

    return ratios;
}

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

- (NSArray<WLDividerRange *> *)layoutWithPreferredSizes:(NSArray<NSNumber *> *)aPreferredSizeRatios
                                       collapsibleSizes:(NSArray<NSNumber *> *)aCollapsibleSizeRatios
{
    __auto_type arrangedSubviews = self.arrangedSubviews;
    const NSUInteger numberOfSubviews = arrangedSubviews.count;

    NSParameterAssert(aCollapsibleSizeRatios.count == numberOfSubviews);
    NSParameterAssert(aCollapsibleSizeRatios.count == aPreferredSizeRatios.count);

    if (!numberOfSubviews)
        return @[];

    NSRect layoutRect = self.bounds;

    if (self.isVertical)
        layoutRect.size.height = 0.0;
    else
        layoutRect.size.width = 0.0;

    const NSUInteger numberOfDividers = numberOfSubviews - 1;
    const CGFloat dividerThickness = self.dividerThickness;
    const CGFloat distributableSize = self.distributableSize;

    //! Convert size ratios onto coordinate space of the receiver by adding divider where needed.
    __auto_type TransformSizes = ^(NSArray<NSNumber *> *aSizeRatios) {
        NSMutableArray<NSNumber *> *sizes = [NSMutableArray arrayWithCapacity:numberOfSubviews];

        for (NSUInteger i = 0; i < numberOfSubviews; ++i)
        {
            CGFloat dividerIfNeeded = i != 0 ? dividerThickness : 0.0;
            [sizes addObject:@(dividerIfNeeded + aSizeRatios[i].doubleValue * distributableSize)];
        }

        return sizes;
    };

    // Views that are currently collapsed should remain so, the rest are constraint to its collapsible sizes.

    NSMutableArray<NSNumber *> *minSizeRatios = [NSMutableArray arrayWithCapacity:numberOfSubviews];
    NSMutableArray<NSNumber *> *maxSizeRatios = [NSMutableArray arrayWithCapacity:numberOfSubviews];
    for (NSUInteger i = 0; i < numberOfSubviews; ++i)
    {
        CGFloat preferredSizeRatio = aPreferredSizeRatios[i].doubleValue;
        CGFloat collapsibleSizeRatio = aCollapsibleSizeRatios[i].doubleValue;
        NSParameterAssert(preferredSizeRatio == 0.0 || preferredSizeRatio >= collapsibleSizeRatio);

        if (preferredSizeRatio == 0.0)
        {
            [minSizeRatios addObject:@0.0];
            [maxSizeRatios addObject:@0.0];
        }
        else
        {
            [minSizeRatios addObject:@(collapsibleSizeRatio)];
            [maxSizeRatios addObject:@1.0];
        }
    }

    __auto_type collapsibleSizes = TransformSizes(aCollapsibleSizeRatios);
    __auto_type distributedSizes = [self WL_distributeRect:layoutRect
                                                  minSizes:TransformSizes(minSizeRatios)
                                                  maxSizes:TransformSizes(maxSizeRatios)
                                            preferredSizes:TransformSizes(aPreferredSizeRatios)];

    // Min and max positions for the divider are calculated with respect to collapsible
    // sizes of the views that precede and follow it.

    NSMutableArray<WLDividerRange *> *dividerPositions = [NSMutableArray arrayWithCapacity:numberOfDividers];
    CGFloat currentPosition = distributedSizes[0].doubleValue;

    for (NSUInteger i = 0; i < numberOfDividers; ++i)
    {
        __auto_type position = [WLDividerRange new];
        position.current = currentPosition;

        CGFloat precedingSize = distributedSizes[i].doubleValue;
        CGFloat precedingCollapsibleSize = collapsibleSizes[i].doubleValue;
        CGFloat followingSize = distributedSizes[i + 1].doubleValue;
        CGFloat followingCollapsibleSize = collapsibleSizes[i + 1].doubleValue;

        if (precedingSize == 0.0 || followingSize == 0.0)
        {
            position.min = currentPosition + followingSize - dividerThickness;
            position.max = currentPosition - precedingSize + (i != 0 ? dividerThickness : 0.0);

            NSParameterAssert(position.min == position.current || position.max == position.current);
        }
        else
        {
            NSMutableArray<NSNumber *> *preferredSizes = [distributedSizes mutableCopy];
            NSMutableArray<NSNumber *> *minSizes = [distributedSizes mutableCopy];
            NSMutableArray<NSNumber *> *maxSizes = [distributedSizes mutableCopy];

            minSizes[i] = @(precedingCollapsibleSize);
            minSizes[i + 1] = @(followingCollapsibleSize);
            maxSizes[i] = maxSizes[i + 1] = @(precedingSize + followingSize);

            // To find min position redistribute sizes assuming that divider's preceding view has collapsible size.
            preferredSizes[i] = @(precedingCollapsibleSize);
            preferredSizes[i + 1] = @(followingSize + precedingSize - precedingCollapsibleSize);

            __auto_type distributedSizesForMin = [self WL_distributeRect:layoutRect
                                                                minSizes:minSizes
                                                                maxSizes:maxSizes
                                                          preferredSizes:preferredSizes];

            for (NSUInteger j = 0; j <= i; ++j)
                position.min += distributedSizesForMin[j].doubleValue;

            // To find max position redistribute sizes assuming that divider's following view has collapsible size.
            preferredSizes[i] = @(precedingSize + followingSize - followingCollapsibleSize);
            preferredSizes[i + 1] = @(followingCollapsibleSize);

            __auto_type distributedSizesForMax = [self WL_distributeRect:layoutRect
                                                                minSizes:minSizes
                                                                maxSizes:maxSizes
                                                          preferredSizes:preferredSizes];

            for (NSUInteger j = 0; j <= i; ++j)
                position.max += distributedSizesForMax[j].doubleValue;
        }

        currentPosition += followingSize;
        [dividerPositions addObject:position];
    }

    return [dividerPositions copy];
}

- (void)adjustSubviewsWithLayout:(NSArray<WLDividerRange *> *)aLayout
{
    for (NSUInteger i = 0, count = aLayout.count; i < count; ++i)
        [self setPosition:aLayout[i].current ofDividerAtIndex:(NSInteger)i];
}

- (NSArray<NSNumber *> *)convertLayout:(NSArray<WLDividerRange *> *)aLayout
                                toView:(NSView *)aView
                               forRect:(NSRect)aBounds
                              minSizes:(NSArray<NSNumber *> *)aMinSizes
                              spacings:(NSArray<NSNumber *> *)aSpacings
{
    __auto_type sizeRatios = self.arrangedSubviewsSizeRatios;
    const NSUInteger numberOfSubviews = sizeRatios.count;

    NSParameterAssert(aLayout.count == numberOfSubviews - 1);
    NSParameterAssert(aMinSizes.count == numberOfSubviews);
    NSParameterAssert(aSpacings.count == numberOfSubviews - 1);

    NSMutableArray<NSNumber *> *minSizes = [NSMutableArray arrayWithCapacity:numberOfSubviews];
    NSMutableArray<NSNumber *> *maxSizes = [NSMutableArray arrayWithCapacity:numberOfSubviews];
    NSMutableArray<NSNumber *> *preferredSizes = [NSMutableArray arrayWithCapacity:numberOfSubviews];

    // Distributable size depends on the number of views actually shown. Collapsed views don't have spacing.

    CGFloat distributableSize = self.isVertical ? NSWidth(aBounds) : NSHeight(aBounds);
    CGFloat pendingSpacing = 0.0; // i.e. spacing before the next non-collapsed view

    for (NSUInteger i = 0; i < numberOfSubviews; ++i)
    {
        if (sizeRatios[i].doubleValue == 0.0)
            continue;

        distributableSize -= pendingSpacing;

        if (i != numberOfSubviews - 1)
            pendingSpacing = aSpacings[i].doubleValue;
    }

    // The distribution is constrained such that collapsed views and views with
    // min size remain so.

    pendingSpacing = 0.0;

    for (NSUInteger i = 0; i < numberOfSubviews; ++i)
    {
        CGFloat ratio = sizeRatios[i].doubleValue;

        BOOL isCollapsed = ratio == 0.0;

        if (isCollapsed)
        {
            // View should remain collapsed through conversion.
            [minSizes addObject:@0.0];
            [maxSizes addObject:@0.0];
            [preferredSizes addObject:@0.0];
            continue;
        }

        BOOL hasMinSize = NO;

        if (i == 0)
        {
            CGFloat followingDividerPosition = [self positionOfDividerAtIndex:(NSInteger)i];
            hasMinSize = followingDividerPosition == aLayout[i].min;
        }
        else if (i == numberOfSubviews - 1)
        {
            CGFloat precedingDividerPosition = [self positionOfDividerAtIndex:(NSInteger)i - 1];
            hasMinSize = precedingDividerPosition == aLayout[i - 1].max;
        }
        else
        {
            CGFloat precedingDividerPosition = [self positionOfDividerAtIndex:(NSInteger)i - 1];
            CGFloat followingDividerPosition = [self positionOfDividerAtIndex:(NSInteger)i];
            hasMinSize = ((precedingDividerPosition == aLayout[i - 1].current && followingDividerPosition == aLayout[i].min) ||
                          (followingDividerPosition == aLayout[i].current && precedingDividerPosition == aLayout[i - 1].max));
        }

        CGFloat minSize = pendingSpacing + aMinSizes[i].doubleValue;
        CGFloat maxSize = 0.0;
        CGFloat preferredSize = 0.0;

        if (hasMinSize)
        {
            // View should remain minimized through conversion.
            maxSize = preferredSize = minSize;
        }
        else
        {
            preferredSize = pendingSpacing + ratio * distributableSize;
            maxSize = distributableSize;
        }

        [minSizes addObject:@(minSize)];
        [maxSizes addObject:@(maxSize)];
        [preferredSizes addObject:@(preferredSize)];

        if (i != numberOfSubviews - 1)
            pendingSpacing = aSpacings[i].doubleValue;
    }

    NSRect layoutRect = aBounds;
    if (self.isVertical)
        layoutRect.size.height = 0.0;
    else
        layoutRect.size.width = 0.0;

    __auto_type distributedSizes = [aView WL_distributeRect:layoutRect
                                               minSizes:minSizes
                                               maxSizes:maxSizes
                                         preferredSizes:preferredSizes];

    // Distributed sizes include spacings between views that needs to be removed.

    NSMutableArray<NSNumber *> *sizes = [NSMutableArray arrayWithCapacity:numberOfSubviews];
    pendingSpacing = 0.0;

    for (NSUInteger i = 0; i < numberOfSubviews; ++i)
    {
        if (distributedSizes[i].doubleValue != 0.0)
        {
            [sizes addObject:@(distributedSizes[i].doubleValue - pendingSpacing)];

            if (i != numberOfSubviews - 1)
                pendingSpacing = aSpacings[i].doubleValue;
        }
        else
            [sizes addObject:@0.0];
    }

    return [sizes copy];
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

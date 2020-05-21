//
//  WLLayerHostedView.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "WLAnimation.h"
#import "WLLayerView.h"


static NSString * const _WLLayerSpeedToken = @"WLLayerSpeed";


@implementation NSView (WLLayerView)

- (void)WL_setFrameSize:(NSSize)newSize
{
    if (@available(macOS 10.12, *)) {}
    else
        self.needsLayout = YES;
}

- (void)WL_setBoundsSize:(NSSize)newSize
{
    if (@available(macOS 10.12, *)) {}
    else
        self.needsLayout = YES;
}

@end


@implementation _WLLayerView

#pragma mark Methods

- (void)performWhileAnimationsPaused:(NS_NOESCAPE void (^)(void))aBlock
{
    [self pauseAnimations];
    aBlock();
    [self resumeAnimations];
}

#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self WL_setFrameSize:newSize];
}

- (void)setBoundsSize:(NSSize)newSize
{
    [super setBoundsSize:newSize];
    [self WL_setBoundsSize:newSize];
}

- (void)stopAnimations
{
    [self.layer WL_performRecursively:^(CALayer *aLayer) {
        [aLayer removeAllAnimations];
    }];
}

- (void)pauseAnimations
{
    [self.layer WL_performRecursively:^(CALayer *aLayer) {
        objc_setAssociatedObject(aLayer, &_WLLayerSpeedToken, @(aLayer.speed), OBJC_ASSOCIATION_RETAIN);
        CFTimeInterval pausedTime = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil];
        aLayer.speed = 0.0f;
        aLayer.timeOffset = pausedTime;
    }];
}

- (void)resumeAnimations
{
    [self.layer WL_performRecursively:^(CALayer *aLayer) {
        NSNumber *speed = objc_getAssociatedObject(aLayer, &_WLLayerSpeedToken);
        objc_setAssociatedObject(aLayer, &_WLLayerSpeedToken, nil, OBJC_ASSOCIATION_ASSIGN);

        CFTimeInterval pausedTime = aLayer.timeOffset;
        aLayer.speed = speed != nil ? speed.floatValue : 1.0f;
        aLayer.timeOffset = 0.0;
        aLayer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        aLayer.beginTime = timeSincePause / aLayer.speed;
    }];
}

@end


@implementation WLLayerBackedView

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

#pragma mark Methods

- (void)prepareForBackingLayer
{
    self.translatesAutoresizingMaskIntoConstraints = NO;

    // macOS 10.14+ works better if it's left to decide whether a layer should be assigned.
    if (@available(macOS 10.14, *)) {}
    else
        self.wantsLayer = YES;

    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

@end


@implementation WLLayerHostingView

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
        [self prepareForHostingLayers];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self prepareForHostingLayers];

    return self;
}

#pragma mark Methods

- (void)prepareForHostingLayers
{
    if (self.layer)
        return;

    CALayer *l = [self makeHostedLayer];

    NSWindow *window = self.window;
    if (window && ![l.contents isKindOfClass:NSImage.class])
        l.contentsScale = window.backingScaleFactor;

    l.delegate = self;

    self.layer = l;
    self.wantsLayer = YES;
}

- (CALayer *)makeHostedLayer
{
    return [CALayer layer];
}

#pragma mark CALayerDelegate

- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow
{
    // There was a bug in AppKit implementation before 10.14 when this method
    // was called for layers with contents being an instance of NSImage.
    // Returning YES then would cause layer to redraw effectively discarding NSImage.
    if (@available(macOS 10.14, *))
        return YES;
    else
        return ![aLayer.contents isKindOfClass:NSImage.class];
}

- (id <CAAction>)actionForLayer:(CALayer *)aLayer forKey:(NSString *)aKey
{
    return nil;
}

#pragma mark NSView

- (void)addSubview:(NSView *)aView
{
    NSParameterAssert(NO);
    NSLog(@"Cannot add subview to a layer-hosted view");
}

@end


@implementation _WLLayerControl

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self WL_setFrameSize:newSize];
}

- (void)setBoundsSize:(NSSize)newSize
{
    [super setBoundsSize:newSize];
    [self WL_setBoundsSize:newSize];
}

@end


@implementation WLLayerBackedControl

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

#pragma mark Methods

- (void)prepareForBackingLayer
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.wantsLayer = YES;
}

@end


@implementation WLDrawingLayerBackedView

- (void)setDrawingBlock:(void (^)(__kindof WLDrawingLayerBackedView * _Nonnull, NSRect))newDrawingBlock
{
    _drawingBlock = [newDrawingBlock copy];
    self.needsDisplay = YES;
}

#pragma mark WLBackingLayerView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
}

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    if (_drawingBlock)
        _drawingBlock(self, aDirtyRect);
}

@end


@implementation WLFlippedView

- (BOOL)isFlipped
{
    return YES;
}

@end


@implementation NSView (WLAdditions)

- (NSLayoutConstraint *)WL_constraintWithIdentifier:(NSString *)anIdentifier
{
    __auto_type constraints = self.constraints;
    __auto_type i = [constraints indexOfObjectPassingTest:^BOOL(NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqual:anIdentifier];
    }];

    return i != NSNotFound ? constraints[i] : nil;
}

- (NSLayoutGuide *)WL_layoutGuideWithIdentifier:(NSString *)anIdentifier
{
    __auto_type guides = self.layoutGuides;
    __auto_type i = [guides indexOfObjectPassingTest:^BOOL(NSLayoutGuide * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqual:anIdentifier];
    }];

    return i != NSNotFound ? guides[i] : nil;
}

- (NSArray<NSNumber *> *)WL_distributeRect:(NSRect)aRect
                                  minSizes:(NSArray<NSNumber *> *)aMinSizes
                                  maxSizes:(NSArray<NSNumber *> *)aMaxSizes
                            preferredSizes:(NSArray<NSNumber *> *)aPreferredSizes
{
    if (NSWidth(aRect) > 0.0 && NSHeight(aRect) > 0.0)
        [NSException raise:NSInvalidArgumentException format:@"aRect cannot have more than one non-empty dimentsion"];

    NSParameterAssert(aMinSizes.count == aMaxSizes.count);
    NSParameterAssert(aMinSizes.count == aPreferredSizes.count);

    NSUInteger numberOfSizes = aMinSizes.count;

    if (!numberOfSizes)
        return @[];

    BOOL isVertical = NSHeight(aRect) > 0.0;

    NSLayoutGuide *rootGuide = [NSLayoutGuide new];
    rootGuide.identifier = @"WL_distributeRect_rootGuide";
    NSMutableArray<NSLayoutGuide *> *sizeGuides = [NSMutableArray arrayWithCapacity:numberOfSizes];
    NSMutableArray *constraints = [NSMutableArray new];

    // Configure the root guide.

    [self addLayoutGuide:rootGuide];

    [constraints addObjectsFromArray:@[
        [rootGuide.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:NSMinX(aRect)],
        [rootGuide.widthAnchor constraintEqualToConstant:NSWidth(aRect)],
        [rootGuide.heightAnchor constraintEqualToConstant:NSHeight(aRect)]
    ]];

    if (self.isFlipped)
        [constraints addObject:[rootGuide.topAnchor constraintEqualToAnchor:self.topAnchor constant:NSMinY(aRect)]];
    else
        [constraints addObject:[self.bottomAnchor constraintEqualToAnchor:rootGuide.bottomAnchor constant:NSMinY(aRect)]];

    // Configure the size guides.

    for (NSUInteger i = 0; i < numberOfSizes; ++i)
    {
        __auto_type sizeGuide = [NSLayoutGuide new];
        sizeGuide.identifier = [NSString stringWithFormat:@"WL_distributeRect_%luGuide", i];
        [sizeGuides addObject:sizeGuide];
        [self addLayoutGuide:sizeGuide];

        NSLayoutDimension *dimensionAnchor = isVertical ? sizeGuide.heightAnchor : sizeGuide.widthAnchor;
        __auto_type minAnchor = isVertical ? (NSLayoutAnchor *)sizeGuide.topAnchor : (NSLayoutAnchor *)sizeGuide.leftAnchor;
        __auto_type maxAnchor = isVertical ? (NSLayoutAnchor *)sizeGuide.bottomAnchor : (NSLayoutAnchor *)sizeGuide.rightAnchor;
        __auto_type minBoundsAnchor = isVertical ? (NSLayoutAnchor *)rootGuide.topAnchor : (NSLayoutAnchor *)rootGuide.leftAnchor;
        __auto_type maxBoundsAnchor = isVertical ? (NSLayoutAnchor *)rootGuide.bottomAnchor : (NSLayoutAnchor *)rootGuide.rightAnchor;

        if (i == 0)
            [constraints addObject:[minAnchor constraintEqualToAnchor:minBoundsAnchor]];
        else
        {
            __auto_type prevSizeGuide = sizeGuides[i - 1];
            __auto_type maxPrevAnchor = isVertical ? (NSLayoutAnchor *)prevSizeGuide.bottomAnchor : (NSLayoutAnchor *)prevSizeGuide.rightAnchor;
            [constraints addObject:[minAnchor constraintEqualToAnchor:maxPrevAnchor]];
        }

        if (i == numberOfSizes - 1)
            [constraints addObject:[maxAnchor constraintEqualToAnchor:maxBoundsAnchor]];

        __auto_type c = [dimensionAnchor constraintGreaterThanOrEqualToConstant:aMinSizes[i].doubleValue];
        c.priority = NSLayoutPriorityRequired - 2;
        [constraints addObject:c];

        c = [dimensionAnchor constraintEqualToConstant:aPreferredSizes[i].doubleValue];
        c.priority = NSLayoutPriorityDefaultLow;
        [constraints addObject:c];

        c = [dimensionAnchor constraintLessThanOrEqualToConstant:aMaxSizes[i].doubleValue];
        c.priority = NSLayoutPriorityRequired - 1;
        [constraints addObject:c];

        if (isVertical)
        {
            [constraints addObject:[sizeGuide.leftAnchor constraintEqualToAnchor:rootGuide.leftAnchor]];
            [constraints addObject:[sizeGuide.rightAnchor constraintEqualToAnchor:rootGuide.rightAnchor]];
        }
        else
        {
            [constraints addObject:[sizeGuide.topAnchor constraintEqualToAnchor:rootGuide.topAnchor]];
            [constraints addObject:[sizeGuide.bottomAnchor constraintEqualToAnchor:rootGuide.bottomAnchor]];
        }
    }

    // Use Auto Layout to distribute rect.

    [NSLayoutConstraint activateConstraints:constraints];
    [self layoutSubtreeIfNeeded];

    NSMutableArray *distribution = [NSMutableArray arrayWithCapacity:numberOfSizes];
    for (NSLayoutGuide *g in sizeGuides)
        [distribution addObject:@(isVertical ? NSHeight(g.frame) : NSWidth(g.frame))];

    // Clean up.

    [self removeLayoutGuide:rootGuide];
    for (NSLayoutGuide *g in sizeGuides)
        [self removeLayoutGuide:g];

    return [distribution copy];
}

@end

//
//  WLCalendarTasksView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTasksView.h"
#import "NSColor+CGColor.h"
#import "CATextLayer+WLStringSize.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static NSString* const _WLRootLayerName = @"root";

static NSString* const _WLTitleLayerName = @"title";

static NSString* const _WLScrollLayerName = @"scroll";

static NSString* const _WLTasksLayerName = @"task";


static NSString* const _WLOrderedSublayersKey = @"orderedSublayers";


@implementation WLCalendarTasksView
@synthesize dataSource;

- (void)dealloc
{
    [super dealloc];
}

- (void)createLayers
{
    [CATransaction begin];
    CALayer *rootLayer = [CALayer layer];
    rootLayer.delegate = self;
    rootLayer.name = _WLRootLayerName;
    rootLayer.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];
    [rootLayer.compositingFilter setDefaults];
    [CATransaction WL_performWithDisabledActions:^{
        rootLayer.needsDisplayOnBoundsChange = YES;
    }];
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    rootLayer.cornerRadius = 2.0f;
    rootLayer.masksToBounds = YES;
#ifdef DEBUG_LAYERS
    rootLayer.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif

    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.name = _WLTitleLayerName;
    titleLayer.string = @"To Do";
    titleLayer.fontSize = 26.0f;
    titleLayer.font = [NSFont fontWithName:@"Helvetica" size:26.0f];
    titleLayer.shadowColor = [[NSColor WL_tasksShadowColor] WL_CGColor];
    titleLayer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    titleLayer.shadowOpacity = 1.0f;
    titleLayer.shadowRadius = 0.0f;
    [titleLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                         relativeTo:@"superlayer"
                                                          attribute:kCAConstraintMinX
                                                             offset:14.0f]];
    [titleLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                         relativeTo:@"superlayer"
                                                          attribute:kCAConstraintWidth]];
    [titleLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                         relativeTo:@"superlayer"
                                                          attribute:kCAConstraintMaxY
                                                             offset:-16.0f]];
    titleLayer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNull null],  @"position",
                          [NSNull null],  @"bounds", nil];
#ifdef DEBUG_LAYERS
    titleLayer.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    [rootLayer addSublayer:titleLayer];

    _tasksLayer = [CALayer layer];
    [_tasksLayer setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    _tasksLayer.name = _WLTasksLayerName;
    _tasksLayer.layoutManager = self;
    _tasksLayer.masksToBounds = YES;
    _tasksLayer.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMinX
                                                              offset:14.0f]];
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMaxX
                                                              offset:-14]];
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                          relativeTo:_WLTitleLayerName
                                                           attribute:kCAConstraintMinY
                                                              offset:-15.0f]];
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMinY
                                                              offset:15.0f]];
    _tasksLayer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNull null], @"position",
                           [NSNull null], @"bounds",
                           [NSNull null], @"sublayers", nil];
#ifdef DEBUG_LAYERS
    _tasksLayer.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    [rootLayer addSublayer:_tasksLayer];

    [self reloadDataAnimated:NO];

    [self setLayer:rootLayer];
    [self setWantsLayer:YES];
    [CATransaction commit];
}

- (void)reloadDataAnimated:(BOOL)isAnimated
{
    NSAssert(dataSource != nil, @"You MUST set dataSource");

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    _tasksLayer.sublayers = nil;
    [_tasksLayer setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    for (NSUInteger i=0, size=[dataSource numberOfTasksInTasksView:self]; i<size; ++i)
        [self insertTaskAtIndex:i];
    [CATransaction commit];
}

- (void)insertTaskAtIndex:(NSUInteger)anIndex
{
    WLCalendarTaskLayer *taskLayer = [self _setupTaskLayerAtIndex:anIndex];
    [_tasksLayer addSublayer:taskLayer];
    [[_tasksLayer valueForKey:_WLOrderedSublayersKey] insertObject:taskLayer atIndex:anIndex];
}

- (void)removeTaskAtIndex:(NSUInteger)anIndex
{
    NSMutableArray *orderedTaskLayers = [_tasksLayer valueForKey:_WLOrderedSublayersKey];
    WLCalendarTaskLayer *taskLayer = [orderedTaskLayers objectAtIndex:anIndex];
    [orderedTaskLayers removeObjectAtIndex:anIndex];
    [taskLayer removeFromSuperlayer];
}

- (void)updateTaskAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    WLCalendarTaskLayer *taskLayer = [[_tasksLayer valueForKey:_WLOrderedSublayersKey] objectAtIndex:anIndex];
    taskLayer.string = task.title;
    taskLayer.markColor = [[[task calendar] color] WL_CGColor];
    [_tasksLayer setNeedsLayout];
}

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    if (oldIndex == newIndex)
        return;
    NSMutableArray *orderedTaskLayers = [_tasksLayer valueForKey:_WLOrderedSublayersKey];
    CalTask *movable = [orderedTaskLayers objectAtIndex:oldIndex];
    [orderedTaskLayers removeObjectAtIndex:oldIndex];
    [orderedTaskLayers insertObject:movable atIndex:newIndex];
    [_tasksLayer setNeedsLayout];
}


#pragma mark Private

- (WLCalendarTaskLayer *)_setupTaskLayerAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    WLCalendarTaskLayer *taskLayer = [WLCalendarTaskLayer layer];
    taskLayer.name = task.uid;
    taskLayer.string = task.title;
    taskLayer.markColor = [[[task calendar] color] WL_CGColor];
    CABasicAnimation *orderInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [orderInAnimation setFromValue:[NSNumber numberWithFloat:0.0]];
    [orderInAnimation setToValue:[NSNumber numberWithFloat:1.0]];
    taskLayer.actions = [NSDictionary dictionaryWithObject:orderInAnimation forKey:kCAOnOrderIn];
#ifdef DEBUG_LAYERS
    taskLayer.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    return taskLayer;
}


#pragma mark CALayerDelegate

- (void)drawLayer:(CALayer *)aLayer inContext:(CGContextRef)aContext
{
    NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
    [c setImageInterpolation:NSImageInterpolationHigh];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:c];

    NSSize bottomBorderSize = NSMakeSize(aLayer.bounds.size.width, [[NSImage imageNamed:@"info-bottom"] size].height);
    NSSize topBorderSize = NSMakeSize(aLayer.bounds.size.width, [[NSImage imageNamed:@"info-top"] size].height);
    NSSize middleBorderSize = NSMakeSize(aLayer.bounds.size.width, aLayer.bounds.size.height - bottomBorderSize.height - topBorderSize.height);

    NSRect dirtyRect = NSRectFromCGRect(CGContextGetClipBoundingBox(aContext));
    static CGFloat AlphaFraction = 0.5f;

    NSRect bottomBorderFrame = NSMakeRect(0.0, 0.0, bottomBorderSize.width, bottomBorderSize.height);
    if (NSIntersectsRect(bottomBorderFrame, dirtyRect))
    {
        NSDrawThreePartImage(bottomBorderFrame,
                             [NSImage imageNamed:@"info-bottom-left"],
                             [NSImage imageNamed:@"info-bottom"],
                             [NSImage imageNamed:@"info-bottom-right"],
                             NO,
                             NSCompositeSourceOver,
                             AlphaFraction,
                             NO);
    }


    NSRect middleBorderFrame = NSMakeRect(0.0, NSMaxY(bottomBorderFrame), middleBorderSize.width, middleBorderSize.height);
    if (NSIntersectsRect(middleBorderFrame, dirtyRect))
    {
        [[NSImage imageNamed:@"info-box"] drawInRect:middleBorderFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:AlphaFraction];
    }

    NSRect topBorderFrame = NSMakeRect(0.0, NSMaxY(middleBorderFrame), topBorderSize.width, topBorderSize.height);
    if (NSIntersectsRect(topBorderFrame, topBorderFrame))
    {
        NSDrawThreePartImage(topBorderFrame,
                             [NSImage imageNamed:@"info-top-left"],
                             [NSImage imageNamed:@"info-top"],
                             [NSImage imageNamed:@"info-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             AlphaFraction,
                             NO);
    }

    [NSGraphicsContext restoreGraphicsState];
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLTasksLayerName]);

    CGSize layerSize = layer.bounds.size;
    CGFloat top = layerSize.height;
    static const CGFloat TopMargin = 20.0f;
    static const CGFloat MaxHeight = 120.0f;
    for (WLCalendarTaskLayer *taskLayer in [layer valueForKey:_WLOrderedSublayersKey])
    {
        CGFloat preferredHeight = fminf([taskLayer maxHeightForWidth:layerSize.width], MaxHeight);
        taskLayer.frame = CGRectMake(0.0f, top - preferredHeight, layerSize.width, preferredHeight);
        top -= preferredHeight + TopMargin;
    }
}

@end

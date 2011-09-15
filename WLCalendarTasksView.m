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
    [self setWantsLayer:YES];
    [self reloadDataAnimated:NO];
}

- (void)reloadDataAnimated:(BOOL)isAnimated
{
    NSAssert(dataSource != nil, @"You MUST set dataSource");

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    CALayer *layer = [self layer];
    layer.sublayers = nil;
    [layer setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    for (NSUInteger i=0, size=[dataSource numberOfTasksInTasksView:self]; i<size; ++i)
        [self insertTaskAtIndex:i];
    [CATransaction commit];
}

- (void)insertTaskAtIndex:(NSUInteger)anIndex
{
    WLCalendarTaskLayer *taskLayer = [self _setupTaskLayerAtIndex:anIndex];
    CALayer *layer = [self layer];
    [layer addSublayer:taskLayer];
    [[layer valueForKey:_WLOrderedSublayersKey] insertObject:taskLayer atIndex:anIndex];
}

- (void)removeTaskAtIndex:(NSUInteger)anIndex
{
    CALayer *layer = [self layer];
    NSMutableArray *orderedTaskLayers = [layer valueForKey:_WLOrderedSublayersKey];
    WLCalendarTaskLayer *taskLayer = [orderedTaskLayers objectAtIndex:anIndex];
    [orderedTaskLayers removeObjectAtIndex:anIndex];
    [taskLayer removeFromSuperlayer];
}

- (void)updateTaskAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    CALayer *layer = [self layer];
    WLCalendarTaskLayer *taskLayer = [[layer valueForKey:_WLOrderedSublayersKey] objectAtIndex:anIndex];
    taskLayer.string = task.title;
    taskLayer.markColor = [[[task calendar] color] WL_CGColor];
    [layer setNeedsLayout];
}

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    if (oldIndex == newIndex)
        return;
    CALayer *layer = [self layer];
    NSMutableArray *orderedTaskLayers = [layer valueForKey:_WLOrderedSublayersKey];
    CalTask *movable = [orderedTaskLayers objectAtIndex:oldIndex];
    [orderedTaskLayers removeObjectAtIndex:oldIndex];
    [orderedTaskLayers insertObject:movable atIndex:newIndex];
    [layer setNeedsLayout];
}


#pragma mark NSView

- (CALayer *)makeBackingLayer
{
    CALayer *l = [super makeBackingLayer];
    l.needsDisplayOnBoundsChange = YES;
    l.layoutManager = self;
    l.cornerRadius = 2.0f;
    l.masksToBounds = YES;
    l.name = _WLTasksLayerName;
    l.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];
    l.actions = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNull null], @"position",
                              [NSNull null], @"bounds",
                              [NSNull null], @"sublayers", nil];
    [l.compositingFilter setDefaults];
    [l setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif
    return l;
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


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLTasksLayerName]);

    CGSize layerSize = layer.bounds.size;
    CGFloat top = layerSize.height;
    static const CGFloat TopMargin = 20.0f;
    for (WLCalendarTaskLayer *taskLayer in [layer valueForKey:_WLOrderedSublayersKey])
    {
        CGFloat preferredHeight = fminf([taskLayer maxHeightForWidth:layerSize.width], layerSize.height);
        taskLayer.frame = CGRectMake(0.0f, top - preferredHeight, layerSize.width, preferredHeight);
        taskLayer.hidden = !CGRectContainsRect(layer.bounds, taskLayer.frame);
        top -= preferredHeight + TopMargin;
    }
}

@end

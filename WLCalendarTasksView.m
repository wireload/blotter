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


static NSString* const _WLTasksLayerName = @"task";


static NSString* const _WLOrderedSublayersKey = @"orderedSublayers";


@implementation WLCalendarTasksView

- (void)dealloc
{
    [super dealloc];
}


#pragma mark Properties
@synthesize dataSource;


#pragma mark Methods

- (void)createLayers
{
    CALayer *l = [CALayer layer];
    l.layoutManager = self;
    l.masksToBounds = YES;
    l.name = _WLTasksLayerName;
    [l setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif
    [self setLayer:l];
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
    [CATransaction begin];
    WLCalendarTaskLayer *taskLayer = [self _setupTaskLayerAtIndex:anIndex];
    CALayer *layer = [self layer];
    [layer addSublayer:taskLayer];
    [[layer valueForKey:_WLOrderedSublayersKey] insertObject:taskLayer atIndex:anIndex];
    [CATransaction commit];
}

- (void)removeTaskAtIndex:(NSUInteger)anIndex
{
    [CATransaction begin];
    CALayer *layer = [self layer];
    NSMutableArray *orderedTaskLayers = [layer valueForKey:_WLOrderedSublayersKey];
    WLCalendarTaskLayer *taskLayer = [orderedTaskLayers objectAtIndex:anIndex];
    [orderedTaskLayers removeObjectAtIndex:anIndex];
    [taskLayer removeFromSuperlayer];
    [CATransaction commit];
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


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLTasksLayerName]);

    CGSize layerSize = layer.bounds.size;
    CGFloat top = layerSize.height;
    static const CGFloat TopMargin = 10.0f;
    for (WLCalendarTaskLayer *taskLayer in [layer valueForKey:_WLOrderedSublayersKey])
    {
        CGFloat preferredHeight = fminf([taskLayer maxHeightForWidth:layerSize.width], layerSize.height);
        taskLayer.frame = CGRectMake(0.0f, top - preferredHeight, layerSize.width, preferredHeight);
        taskLayer.hidden = !CGRectContainsRect(layer.bounds, taskLayer.frame);
        top -= preferredHeight + TopMargin;
    }
}


#pragma mark Private

- (WLCalendarTaskLayer *)_setupTaskLayerAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    WLCalendarTaskLayer *taskLayer = [WLCalendarTaskLayer layer];
    taskLayer.name = task.uid;
    taskLayer.string = task.title;
    taskLayer.markColor = [[[task calendar] color] WL_CGColor];
#ifdef DEBUG_LAYERS
    taskLayer.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    return taskLayer;
}

@end

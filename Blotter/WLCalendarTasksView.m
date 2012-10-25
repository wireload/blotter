//
//  WLCalendarTasksView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#include <tgmath.h>
#import "WLCalendarTasksView.h"
#import "NSFont+WLCalendar.h"
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

- (void)reloadDataAnimated:(BOOL)isAnimated
{
    NSAssert(dataSource != nil, @"You MUST set dataSource");

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    [rootLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [rootLayer setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    for (NSUInteger i=0, size=[dataSource numberOfTasksInTasksView:self]; i<size; ++i)
        [self insertTaskAtIndex:i];
    [CATransaction commit];
}

- (void)insertTaskAtIndex:(NSUInteger)anIndex
{
    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    NSAssert(anIndex <= [self numberOfTasks],
             @"anIndex (%ld) MUST be less or equal than number of tasks (%ld).", anIndex, [self numberOfTasks]);

    WLCalendarTaskLayer *taskLayer = [self makeTaskLayer];
    [rootLayer addSublayer:taskLayer];
    [[rootLayer valueForKey:_WLOrderedSublayersKey] insertObject:taskLayer atIndex:anIndex];
    [self updateTaskAtIndex:anIndex];
    [rootLayer setNeedsLayout];
}

- (void)removeTaskAtIndex:(NSUInteger)anIndex
{
    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    NSAssert(anIndex < [self numberOfTasks],
             @"anIndex (%ld) MUST point to a valid task (%ld tasks).", anIndex, [self numberOfTasks]);

    NSMutableArray *orderedTaskLayers = [rootLayer valueForKey:_WLOrderedSublayersKey];
    WLCalendarTaskLayer *taskLayer = [orderedTaskLayers objectAtIndex:anIndex];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [taskLayer removeFromSuperlayer];
    }];
    taskLayer.opacity = 0.0;
    [CATransaction commit];
    [orderedTaskLayers removeObjectAtIndex:anIndex];
    [rootLayer setNeedsLayout];
}

- (void)updateTaskAtIndex:(NSUInteger)anIndex
{
    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    NSAssert(anIndex < [self numberOfTasks],
             @"anIndex (%ld) MUST point to a valid task (%ld tasks).", anIndex, [self numberOfTasks]);

    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    WLCalendarTaskLayer *taskLayer = [[rootLayer valueForKey:_WLOrderedSublayersKey] objectAtIndex:anIndex];
    taskLayer.name = task.uid;
    taskLayer.title = [NSAttributedString WL_taskTitleWithString:task.title];
    NSColor *calendarColor = [task.calendar color];
    if (calendarColor == NULL || (id)calendarColor == [NSNull null])
        calendarColor = [NSColor WL_defaultCalendarColorIfFrameworkFails];
    taskLayer.mark = [NSAttributedString WL_taskMarkWithColor:[calendarColor WL_CGColor]];
    [rootLayer setNeedsLayout];
}

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    if (oldIndex == newIndex)
        return;

    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    NSAssert(oldIndex < [self numberOfTasks],
             @"oldIndex (%ld) MUST point to a valid task (%ld tasks).", oldIndex, [self numberOfTasks]);
    NSAssert(newIndex < [self numberOfTasks],
             @"newIndex (%ld) MUST be less than number of tasks (%ld tasks).", newIndex, [self numberOfTasks]);

    NSMutableArray *orderedTaskLayers = [rootLayer valueForKey:_WLOrderedSublayersKey];
    CalTask *movable = [orderedTaskLayers objectAtIndex:oldIndex];
    [orderedTaskLayers removeObjectAtIndex:oldIndex];
    [orderedTaskLayers insertObject:movable atIndex:newIndex];
    [rootLayer setNeedsLayout];
}

- (NSUInteger)numberOfTasks
{
    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    return [[rootLayer valueForKey:_WLOrderedSublayersKey] count];
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    // Origin is top left.
    if (![aLayer.name isEqualToString:_WLTasksLayerName])
        return;
    NSParameterAssert([aLayer.name isEqualToString:_WLTasksLayerName]);

    CGFloat taskLayerYOffset = 0.0;
    static const CGFloat TopMargin = 9.0;
    NSArray *orderedSublayers = [aLayer valueForKey:_WLOrderedSublayersKey];
    for (WLCalendarTaskLayer *taskLayer in orderedSublayers)
    {
        CGFloat preferredHeight = [taskLayer preferredHeightWithWidth:CGRectGetWidth(aLayer.bounds)];
        if (taskLayerYOffset < CGRectGetHeight(aLayer.bounds))
        {
            if (taskLayerYOffset + preferredHeight <= CGRectGetHeight(aLayer.bounds))
            {
                taskLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                            taskLayerYOffset,
                                                            CGRectGetWidth(aLayer.bounds),
                                                            preferredHeight));
                taskLayerYOffset += preferredHeight + TopMargin;
            }
            else
            {
                CGFloat minimumHeight = [taskLayer minimumHumanVisibleHeight];
                if (taskLayerYOffset + minimumHeight <= CGRectGetHeight(aLayer.bounds))
                {
                    taskLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                                taskLayerYOffset,
                                                                CGRectGetWidth(aLayer.bounds),
                                                                fdim(CGRectGetHeight(aLayer.bounds), taskLayerYOffset)));
                    taskLayerYOffset = CGRectGetHeight(aLayer.bounds) + TopMargin;
                }
                else
                {
                    taskLayerYOffset = CGRectGetHeight(aLayer.bounds) + TopMargin;
                    taskLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                                taskLayerYOffset,
                                                                CGRectGetWidth(aLayer.bounds),
                                                                preferredHeight));
                }
            }
        }
        else
        {
            taskLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                        taskLayerYOffset,
                                                        CGRectGetWidth(aLayer.bounds),
                                                        preferredHeight));
            taskLayerYOffset += preferredHeight + TopMargin;
        }
    }
}


#pragma mark CALayerDelegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return nil;
}

- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow
{
    return YES;
}


#pragma mark WLLayerBackedView

- (CALayer *)makeRootLayer
{
    CALayer *l = [CALayer layer];

    NSWindow *window = [self window];
    if (window)
        l.contentsScale = [window backingScaleFactor];

    l.layoutManager = self;
    l.masksToBounds = YES;
    l.name = _WLTasksLayerName;
    l.delegate = self;
    [l setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], _WLOrderedSublayersKey,
                             [NSNull null], @"contents",
                             [NSNull null], @"frame",
                             [NSNull null], @"bounds",
                             [NSNull null], @"position",
                             nil];
    l.actions = actions;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif

    return l;
}


#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

@end


@implementation WLCalendarTasksView (Layers)

- (WLCalendarTaskLayer *)makeTaskLayer
{
    WLCalendarTaskLayer *l = [WLCalendarTaskLayer layer];

    NSWindow *window = [self window];
    if (window)
        l.contentsScale = [window backingScaleFactor];

    l.needsDisplayOnBoundsChange = YES;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif

    return l;
}

@end

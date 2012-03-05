//
//  WLCalendarTasksView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
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
    WLCalendarTaskLayer *taskLayer = [self makeTaskLayer];
    [rootLayer addSublayer:taskLayer];
    [[rootLayer valueForKey:_WLOrderedSublayersKey] insertObject:taskLayer atIndex:anIndex];
    [self updateTaskAtIndex:anIndex];
    [rootLayer setNeedsLayout];
}

- (void)removeTaskAtIndex:(NSUInteger)anIndex
{
    CALayer *layer = [self layer];
    NSMutableArray *orderedTaskLayers = [layer valueForKey:_WLOrderedSublayersKey];
    WLCalendarTaskLayer *taskLayer = [orderedTaskLayers objectAtIndex:anIndex];
    [orderedTaskLayers removeObjectAtIndex:anIndex];
    [taskLayer removeFromSuperlayer];
    [layer setNeedsLayout];
}

- (void)updateTaskAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    CALayer *layer = [self layer];
    WLCalendarTaskLayer *taskLayer = [[layer valueForKey:_WLOrderedSublayersKey] objectAtIndex:anIndex];
    taskLayer.name = task.uid;
    taskLayer.title = [NSAttributedString WL_titleWithString:task.title];
    NSColor *calendarColor = [task.calendar color];
    if (calendarColor == NULL)
        calendarColor = [NSColor WL_defaultCalendarColorIfFrameworkFails];
    taskLayer.mark = [NSAttributedString WL_markWithColor:[calendarColor WL_CGColor]];
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

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    // Origin is top left.
    NSParameterAssert([aLayer.name isEqualToString:_WLTasksLayerName]);

    CGFloat taskLayerYOffset = 0.0;
    static const CGFloat TopMargin = 9.0;
    for (WLCalendarTaskLayer *taskLayer in [aLayer valueForKey:_WLOrderedSublayersKey])
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


#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    if ([CATransaction disableActions])
        [[self layer] layoutIfNeeded];
}

@end


@implementation WLCalendarTasksView (Layers)

- (void)makeLayers
{
    CALayer *l = [CALayer layer];
    l.layoutManager = self;
    l.masksToBounds = YES;
    l.name = _WLTasksLayerName;
    l.geometryFlipped = YES;
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
    [self setLayer:l];
    [self setWantsLayer:YES];
    [self reloadDataAnimated:NO];
}

- (WLCalendarTaskLayer *)makeTaskLayer
{
    WLCalendarTaskLayer *taskLayer = [WLCalendarTaskLayer layer];
    taskLayer.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
    taskLayer.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    return taskLayer;
}

@end


@implementation NSAttributedString (WLCalendarTasksView)

+ (NSAttributedString *)WL_titleWithString:(NSString *)aString
{
    if ([aString length] == 0)
        return nil;

    static dispatch_once_t onceToken;
    static NSDictionary *TitleAttributes = nil;
    dispatch_once(&onceToken, ^{
        TitleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           (id)[NSFont WL_taskFont],                      (id)kCTFontAttributeName,
                           (id)[[NSColor WL_taskTitleColor] WL_CGColor],  (id)kCTForegroundColorAttributeName,
                           nil];
    });
    return [[[NSAttributedString alloc] initWithString:aString attributes:TitleAttributes] autorelease];
}

+ (NSAttributedString *)WL_markWithColor:(CGColorRef)aColor
{
    if(aColor == NULL)
        return nil;

    static dispatch_once_t onceToken;
    static NSDictionary *MarkAttributes = nil;
    dispatch_once(&onceToken, ^{
        MarkAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                          (id)[NSFont WL_taskFont],                      (id)kCTFontAttributeName,
                          (id)[[NSColor WL_taskTitleColor] WL_CGColor],  (id)kCTForegroundColorAttributeName,
                          nil];
    });
    NSMutableDictionary *a = [[MarkAttributes mutableCopy] autorelease];
    [a setObject:(id)aColor forKey:(id)kCTForegroundColorAttributeName];
    return [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"●", @"Task's mark")
                                            attributes:a] autorelease];
}

@end

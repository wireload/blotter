//
//  WLCalendarTasksView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
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
    taskLayer.title = [self _titleWithString:task.title];
    NSColor *calendarColor = [task.calendar color];
    if (calendarColor == NULL)
        calendarColor = [NSColor WL_defaultCalendarColorIfFrameworkFails];
    taskLayer.mark = [self _markWithColor:[calendarColor WL_CGColor]];
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
    // Origin is bottom left.
    NSParameterAssert([aLayer.name isEqualToString:_WLTasksLayerName]);

    CGSize layerSize = aLayer.bounds.size;
    CGFloat offset = layerSize.height;
    CGFloat lastVisibleOffset = offset;
    WLCalendarTaskLayer *firstHiddenLayer = nil;
    static const CGFloat TopMargin = 9.0f;
    for (WLCalendarTaskLayer *taskLayer in [aLayer valueForKey:_WLOrderedSublayersKey])
    {
        CGFloat height = fminf([taskLayer preferredHeightWithWidth:layerSize.width], layerSize.height);
        if (offset - height >= 0.0f)
        {
            taskLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                        offset - height,
                                                        layerSize.width,
                                                        height));
            taskLayer.hidden = NO;
        }
        else
        {
            if (firstHiddenLayer == nil)
            {
                firstHiddenLayer = taskLayer;
                lastVisibleOffset = offset;
            }
            taskLayer.hidden = YES;
        }
        offset -= height + TopMargin;
    }
    
    // If the last layer didn't fit, but there is enough space to show at least one or more of its lines, show them.
    if (firstHiddenLayer != nil)
    {
        CGFloat minimumHeight = [firstHiddenLayer minimumHumanVisibleHeight];
        if (lastVisibleOffset - minimumHeight >= 0.0f)
        {
            firstHiddenLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                               0,
                                                               self.bounds.size.width,
                                                               lastVisibleOffset));
            firstHiddenLayer.hidden = NO;
        }
    }
}


#pragma mark Private

- (WLCalendarTaskLayer *)_setupTaskLayerAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    WLCalendarTaskLayer *taskLayer = [WLCalendarTaskLayer layer];
    taskLayer.name = task.uid;
    taskLayer.title = [self _titleWithString:task.title];
    taskLayer.mark = [self _markWithColor:[[[task calendar] color] WL_CGColor]];
    taskLayer.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
    taskLayer.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    return taskLayer;
}

- (NSAttributedString *)_titleWithString:(NSString *)aString
{
    if ([aString length] == 0)
        return nil;
    
    static NSDictionary *a = nil;
    if (a == nil)
    {
        a = [[NSDictionary alloc] initWithObjectsAndKeys:
             (id)[NSFont WL_taskFont],                      (id)kCTFontAttributeName,
             (id)[[NSColor WL_taskTitleColor] WL_CGColor],  (id)kCTForegroundColorAttributeName,
             nil];
    }
    return [[[NSAttributedString alloc] initWithString:aString attributes:a] autorelease];
}

- (NSAttributedString *)_markWithColor:(CGColorRef)aColor
{
    NSParameterAssert(aColor != NULL);

    static NSMutableDictionary *a = nil;
    if (a == nil)
    {       
        a = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
             (id)[NSFont WL_taskFont],                      (id)kCTFontAttributeName,
             (id)[[NSColor WL_taskTitleColor] WL_CGColor],  (id)kCTForegroundColorAttributeName,
             nil];
    }
    [a setObject:(id)aColor forKey:(id)kCTForegroundColorAttributeName];
    return [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"●", @"Task's mark")
                                            attributes:a] autorelease];
}


#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [super setFrameSize:newSize];
    [[self layer] layoutIfNeeded];
    [CATransaction commit];
}

@end

//
//  WLCalendarAllDayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 14.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"

static NSString* const _WLCalendarKey = @"calendar";


static const CGFloat _WLTopMargin = 10.0f;


@implementation WLCalendarAllDayEventsLayer
@dynamic events;

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedByUIDEventLayers = [[NSMutableArray alloc] init];
        _icalSortedEventLayers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_icalSortedEventLayers release];
    [_sortedByUIDEventLayers release];
    [super dealloc];
}

- (NSArray *)events
{
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:[_sortedByUIDEventLayers count]];
    for (WLCalendarEventLayer *eventLayer in _sortedByUIDEventLayers)
    {
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               eventLayer.name,             @"uid",
                               [eventLayer.title string],   @"title",
                               nil];
        [events addObject:event];
    }
    return events;
}

- (void)setEvents:(NSArray *)newEvents
{
    [_icalSortedEventLayers removeAllObjects];
    NSMutableArray *sublayersToRemove = [_sortedByUIDEventLayers mutableCopy];
    for (id event in newEvents)
    {
        BOOL isFound = NO;
        NSUInteger layerIdx = [self _indexOfEventLayerWithUID:[event uid] isFound:&isFound];
        if (isFound)
        {
            WLCalendarEventLayer *l = [_sortedByUIDEventLayers objectAtIndex:layerIdx];
            [self _updateEventLayer:l withEvent:event];
            [_icalSortedEventLayers addObject:l];
            [sublayersToRemove removeObjectIdenticalTo:l];
        }
        else
        {
            WLCalendarEventLayer *l = [self _setupEventLayer];
            [self _updateEventLayer:l withEvent:event];
            [_sortedByUIDEventLayers insertObject:l atIndex:layerIdx];
            [_icalSortedEventLayers addObject:l];
            [self addSublayer:l];
        }
    }
    [sublayersToRemove makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    for (WLCalendarEventLayer *l in sublayersToRemove)
        [_sortedByUIDEventLayers removeObjectIdenticalTo:l];
    [sublayersToRemove release];
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGFloat preferredHeight = 0.0f;
    for (WLCalendarEventLayer *layer in _sortedByUIDEventLayers)
        preferredHeight += _WLTopMargin + [layer preferredHeightWithWidth:aWidth];
    return preferredHeight;
}


#pragma mark Private

- (NSUInteger)_indexOfEventLayerWithUID:(NSString *)anUID isFound:(out BOOL *)outIsFound
{
    NSArray *layerNames = [_sortedByUIDEventLayers valueForKey:@"name"];
    NSUInteger idx = [layerNames indexOfObject:anUID
                                 inSortedRange:NSMakeRange(0, [_sortedByUIDEventLayers count])
                                       options:NSBinarySearchingFirstEqual
                               usingComparator:^(NSString *obj1, NSString *obj2)
    {
        return [obj1 compare:obj2];
    }];
    if (idx != NSNotFound)
    {
        if (outIsFound != NULL)
            *outIsFound = YES;
    }
    else
    {
        if (outIsFound != NULL)
            *outIsFound = NO;
        idx = [layerNames indexOfObject:anUID
                          inSortedRange:NSMakeRange(0, [_sortedByUIDEventLayers count])
                                options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                        usingComparator:^(NSString *obj1, NSString *obj2)
        {
            return [obj1 compare:obj2];
        }];
    }
    return idx;
}

- (WLCalendarEventLayer *)_setupEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    l.needsDisplayOnBoundsChange = YES;
#ifndef DEBUG_LAYERS
    l.contentsBackgroundOpacity = 0.45;
#endif
    return l;
}

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(CalEvent *)anEvent
{
    aLayer.name = [anEvent uid];
    NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 (id)[[NSColor whiteColor] WL_CGColor], (id)kCTForegroundColorAttributeName,
                                 (id)[NSFont WL_eventTitleFont],            (id)kCTFontAttributeName,
                                 nil];
    if ([[anEvent title] length])
        aLayer.title = [[[NSAttributedString alloc] initWithString:[anEvent title] attributes:attr] autorelease];
    else
        aLayer.title = nil;


    if ([[anEvent location] length])
    {
        [attr setObject:(id)[NSFont WL_eventLocationFont] forKey:(id)kCTFontAttributeName];
        [attr setObject:(id)[[NSColor WL_eventLocationColor] WL_CGColor] forKey:(id)kCTForegroundColorAttributeName];

        aLayer.location = [[[NSAttributedString alloc] initWithString:[anEvent location] attributes:attr] autorelease];
    }
    else
        aLayer.location = nil;
#ifdef DEBUG_LAYERS
    aLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    aLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#endif
}


#pragma mark CALayer

- (void)layoutSublayers
{
    // Origin is top left
    CGFloat maxHeight = self.bounds.size.height - _WLTopMargin;
    CGFloat offset = CGRectGetMinY(self.bounds) + _WLTopMargin;
    CGFloat lastVisibleOffset = offset;
    WLCalendarEventLayer *firstHiddenLayer = nil;
    for (WLCalendarEventLayer *layer in _icalSortedEventLayers)
    {
        CGFloat height = MIN([layer preferredHeightWithWidth:self.bounds.size.width], maxHeight);
        if (offset + height <= CGRectGetMaxY(self.bounds))
        {
            layer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds),
                                                    offset,
                                                    self.bounds.size.width,
                                                    height));
            layer.hidden = NO;
        }
        else
        {
            if (firstHiddenLayer == nil)
            {
                lastVisibleOffset = offset;
                firstHiddenLayer = layer;
            }
            layer.hidden = YES;
        }
        offset += height + _WLTopMargin;
    }

    // If there is enough space to fit at least one line of the first hidden layer, show this layer.
    if (firstHiddenLayer != nil)
    {
        CGFloat minimumHeight = [firstHiddenLayer minimumHumanVisibleHeight];
        if (CGRectGetMaxY(self.bounds) - lastVisibleOffset >= minimumHeight)
        {
            firstHiddenLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds),
                                                               lastVisibleOffset,
                                                               self.bounds.size.width,
                                                               CGRectGetMaxY(self.bounds) - lastVisibleOffset));
            firstHiddenLayer.hidden = NO;
        }
    }
}

- (CGSize)preferredFrameSize
{
    CGSize preferredSize = CGSizeMake(0.0f, 0.0f);
    for (WLCalendarEventLayer *layer in _icalSortedEventLayers)
    {
        CGSize layerSize = [layer preferredFrameSize];
        preferredSize.width = MAX(preferredSize.width, layerSize.width);
        preferredSize.height += _WLTopMargin + layerSize.height;
    }
    return preferredSize;
}

@end

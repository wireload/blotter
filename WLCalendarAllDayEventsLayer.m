//
//  WLCalendarAllDayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 14.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSColor+CGColor.h"
#import "CoreAnimation+WLCalendar.h"


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
                               [eventLayer.string string],  @"title", nil];
        [events addObject:event];
    }
    return events;
}

- (void)setEvents:(NSArray *)newEvents
{
    [CATransaction begin];
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
    [CATransaction commit];
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGFloat preferredHeight = 0.0f;
    for (WLCalendarEventLayer *layer in _sortedByUIDEventLayers)
        preferredHeight += _WLTopMargin + [layer preferredHeightWithWidth:aWidth];
    return preferredHeight;
}


#pragma mark Private

- (NSUInteger)_indexOfEventLayerWithUID:(NSString *)anUID isFound:(BOOL *)outIsFound
{
    __block BOOL found = NO;
    NSArray *layerNames = [_sortedByUIDEventLayers valueForKey:@"name"];
    NSUInteger idx = [layerNames indexOfObject:anUID
                                 inSortedRange:NSMakeRange(0, [_sortedByUIDEventLayers count])
                                       options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                               usingComparator:^(NSString *obj1, NSString *obj2)
    {
        NSComparisonResult result = [obj1 compare:obj2];
        if (!found) // since we pass NSBinarySearchingInsertionIndex, block may be called even when object is actually found.
            found = (result == NSOrderedSame);
        return result;
    }];
    if (outIsFound != NULL)
        *outIsFound = found;
    return idx;
}

- (WLCalendarEventLayer *)_setupEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.needsDisplayOnBoundsChange = YES;
    }];
#ifndef DEBUG_LAYERS
    l.contentsBackgroundOpacity = 0.6;
#endif
    return l;
}

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(id)anEvent
{
    aLayer.name = [anEvent uid];
    NSDictionary *attr = [NSDictionary dictionaryWithObject:(id)[[NSColor whiteColor] WL_CGColor]
                                                     forKey:(id)kCTForegroundColorAttributeName];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[anEvent title]
                                                                           attributes:attr];
    aLayer.string = attributedString;
    [attributedString release];
#ifdef DEBUG_LAYERS
    aLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    aLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#endif
}


#pragma mark CALayer

- (void)layoutSublayers
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    CGFloat maxHeight = self.bounds.size.height - _WLTopMargin;
    CGFloat offset = CGRectGetMinY(self.bounds) + _WLTopMargin;
    CGFloat lastVisibleOffset = offset;
    WLCalendarEventLayer *firstHiddenLayer = nil;
    for (WLCalendarEventLayer *layer in _icalSortedEventLayers)
    {
        CGFloat height = MIN([layer preferredHeightWithWidth:self.bounds.size.width], maxHeight);
        if (offset + height > CGRectGetMaxY(self.bounds))
        {
            lastVisibleOffset = offset;
            firstHiddenLayer = layer;
			[CATransaction WL_performWithDisabledActions:^{
				layer.hidden = YES;
			}];
        }
        else
        {
            layer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds), offset, self.bounds.size.width, height));
			[CATransaction WL_performWithDisabledActions:^{
				layer.hidden = NO;
			}];
        }
        offset += height + _WLTopMargin;
    }

    // If there is enough space to fit at least one line of the first hidden layer, show this layer.
    if (firstHiddenLayer != nil)
    {
        CGFloat minimalHeight = [firstHiddenLayer minimalHumanVisibleHeight];
        if (CGRectGetMaxY(self.bounds) - lastVisibleOffset >= minimalHeight)
        {
            firstHiddenLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds),
                                                               lastVisibleOffset,
                                                               self.bounds.size.width,
                                                               CGRectGetMaxY(self.bounds) - lastVisibleOffset));
            [CATransaction WL_performWithDisabledActions:^{
				firstHiddenLayer.hidden = NO;
			}];
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

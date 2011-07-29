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


static NSString* const _WLCalendarKey = @"calendar";


static const CGFloat _WLTopMargin = 10.0f;


@implementation WLCalendarAllDayEventsLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedEventLayers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_sortedEventLayers release];
    [super dealloc];
}

- (void)layoutSublayers
{
    CGFloat maxHeight = self.bounds.size.height - _WLTopMargin;
    CGFloat offset = _WLTopMargin;
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
    {
        CGFloat height = MIN([layer preferredHeightWithWidth:self.bounds.size.width], maxHeight);
        if (offset + height >= self.bounds.size.height)
        {
            // "Hide" event
            offset = self.bounds.size.height + 1.0f;
        }
        layer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds), offset, self.bounds.size.width, height));
        offset += height + _WLTopMargin;
    }
}

- (CGSize)preferredFrameSize
{
    CGSize preferredSize = CGSizeMake(0.0f, 0.0f);
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
    {
        CGSize layerSize = [layer preferredFrameSize];
        preferredSize.width = MAX(preferredSize.width, layerSize.width);
        preferredSize.height += _WLTopMargin + layerSize.height;
    }
    return preferredSize;
}

- (void)addEvent:(id)anEvent
{
    BOOL isFound = NO;
    [self _indexOfEventLayerForUID:[anEvent uid] isFound:&isFound];
    if (!isFound)
    {
        CALayer *eventLayer = [self _setupEventLayerWithEvent:anEvent];
        [_sortedEventLayers addObject:eventLayer];
        [self addSublayer:eventLayer];
    }
    else
        [self updateEvent:anEvent];
}

- (void)updateEvent:(id)anEvent
{
    BOOL isFound = NO;
    NSUInteger idx = [self _indexOfEventLayerForUID:[anEvent uid] isFound:&isFound];
    if (isFound)
    {
        WLCalendarEventLayer *eventLayer = [_sortedEventLayers objectAtIndex:idx];
#ifdef DEBUG_LAYERS
        eventLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
        eventLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#endif
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[anEvent title]];
        eventLayer.string = attributedString;
        [attributedString release];
        [self setNeedsLayout];
    }
}

- (void)removeEvent:(id)anEvent
{
    BOOL isFound = NO;
    NSUInteger idx = [self _indexOfEventLayerForUID:[anEvent uid] isFound:&isFound];
    if (isFound)
    {
        [[_sortedEventLayers objectAtIndex:idx] removeFromSuperlayer];
        [_sortedEventLayers removeObjectAtIndex:idx];
    }
}

- (void)setEvents:(NSArray *)events
{
    [CATransaction begin];
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
        [layer removeFromSuperlayer];
    [_sortedEventLayers removeAllObjects];
    for (id event in events)
        [self addEvent:event];
    [CATransaction commit];
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGFloat preferredHeight = 0.0f;
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
        preferredHeight += _WLTopMargin + [layer preferredHeightWithWidth:aWidth];
    return preferredHeight;
}


- (WLCalendarEventLayer *)_setupEventLayerWithEvent:(id)anEvent
{
    WLCalendarEventLayer *eventLayer = [WLCalendarEventLayer layer];
    eventLayer.name = [anEvent uid];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[anEvent title]];
    eventLayer.string = attributedString;
    [attributedString release];
    [CATransaction setDisableActions:YES];
    eventLayer.needsDisplayOnBoundsChange = YES;
    [CATransaction setDisableActions:NO];

#ifdef DEBUG_LAYERS
    eventLayer.contentsBackgroundOpacity = 0.0f;
    eventLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    eventLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
    eventLayer.contentsBackgroundOpacity = 0.6;
#endif
    return eventLayer;
}


#pragma mark Private

- (NSUInteger)_indexOfEventLayerForUID:(NSString *)anUID isFound:(BOOL *)isFound
{
    __block BOOL found = NO;
    NSArray *layerNames = [_sortedEventLayers valueForKey:@"name"];
    NSUInteger idx = [layerNames indexOfObject:anUID
                                 inSortedRange:NSMakeRange(0, [_sortedEventLayers count])
                                       options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                               usingComparator:^(id obj1, id obj2)
    {
        NSComparisonResult result = [obj1 compare:obj2];
        found = (result == NSOrderedSame);
        return result;
    }];
    if (isFound != NULL)
        *isFound = found;
    return idx;
}

@end

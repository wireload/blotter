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
@dynamic events;

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

- (NSArray *)events
{
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:[_sortedEventLayers count]];
    for (WLCalendarEventLayer *eventLayer in _sortedEventLayers)
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
    [_sortedEventLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_sortedEventLayers removeAllObjects];
    for (id event in newEvents)
    {
        BOOL isFound = NO;
        [self _indexOfEventLayerForUID:[event uid] isFound:&isFound];
        NSParameterAssert (isFound == NO);
        CALayer *eventLayer = [self _setupEventLayerWithEvent:event];
        [_sortedEventLayers addObject:eventLayer];
        [self addSublayer:eventLayer];
    }
    [CATransaction commit];
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGFloat preferredHeight = 0.0f;
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
        preferredHeight += _WLTopMargin + [layer preferredHeightWithWidth:aWidth];
    return preferredHeight;
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


#pragma mark CALayer

- (void)layoutSublayers
{
    CGFloat maxHeight = self.bounds.size.height - _WLTopMargin;
    CGFloat offset = CGRectGetMinY(self.bounds) + _WLTopMargin;
    CGFloat lastVisibleOffset = offset;
    WLCalendarEventLayer *firstHiddenLayer = nil;
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
    {
        CGFloat height = MIN([layer preferredHeightWithWidth:self.bounds.size.width], maxHeight);
        if (offset + height > CGRectGetMaxY(self.bounds))
        {
            lastVisibleOffset = offset;
            firstHiddenLayer = layer;
            layer.hidden = YES;
        }
        else
        {
            layer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds), offset, self.bounds.size.width, height));
            layer.hidden = NO;
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
            firstHiddenLayer.hidden = NO;
        }
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

@end

//
//  WLCalendarWeekdayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLCalendarWeekdayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSColor+CGColor.h"


static NSString* const _WLStartDateKey = @"startDate";

static NSString* const _WLEndDateKey = @"endDate";

static NSString* const _WLTopKey = @"top";

static NSString* const _WLBottomKey = @"bottom";

static NSString* const _WLNumberOfColumnsToSkipKey = @"skipColumns";


@implementation WLCalendarWeekdayEventsLayer
@synthesize timeRuler;
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

- (id)initWithLayer:(id)aLayer
{
    self = [super initWithLayer:aLayer];
    if (self != nil)
    {
        [self setValue:[aLayer valueForKey:@"timeRuler"] forKey:@"timeRuler"];
    }
    return self;
}

- (void)dealloc
{
    [_sortedEventLayers release];
    [_eventsLayoutTreeRootNode release];
    [super dealloc];
}

#define IS_LESS_OR_EQ_F(a, b) (BOOL)((a) <= (b) || (fabsf((b) - (a)) < FLT_EPSILON))

#define IS_LESS_F(a, b) (BOOL)((a) < (b) && !(fabsf((b) - (a)) < FLT_EPSILON))

- (void)layoutSublayers
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    NSUInteger numberOfLayers = [_sortedEventLayers count];
    if (numberOfLayers == 0)
        return;

    if (_eventsChanged || _cachedMaximumNumberOfColumns != [self maximumNumberOfColumns])
    {
        _cachedMaximumNumberOfColumns = [self maximumNumberOfColumns];
        _eventsChanged = NO;
        [self _buildEventsLayoutTree];
    }

    // Traverse tree and calculate frames.
    for (NSTreeNode *rowNode in [_eventsLayoutTreeRootNode childNodes])
    {
        NSUInteger numberOfColumns = [[rowNode childNodes] count];
        static const CGFloat XSpaceBetweenEvents = 1.0f;
        CGFloat width = fmaxf((self.bounds.size.width - XSpaceBetweenEvents * (numberOfColumns - 1)) / numberOfColumns,
                              [WLCalendarEventLayer minimalHumanVisibleWidth]);
        [[rowNode childNodes] enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger idx, BOOL *stop)
        {
            for (WLCalendarEventLayer *eventLayer in [columnNode representedObject])
            {
                CGFloat top = [[eventLayer valueForKey:_WLTopKey] floatValue];
                CGFloat bottom = [[eventLayer valueForKey:_WLBottomKey] floatValue];
                CGFloat minimalHeight = [eventLayer minimalHumanVisibleHeight];
                if (IS_LESS_F(bottom - top, minimalHeight))
                    bottom = top + minimalHeight;
                NSUInteger numberOfColumnsToSkip = [[eventLayer valueForKey:_WLNumberOfColumnsToSkipKey] unsignedIntegerValue];
                eventLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds) + idx * (width + XSpaceBetweenEvents),
                                                            top,
                                                            width + ((width + XSpaceBetweenEvents) * numberOfColumnsToSkip),
                                                            bottom - top));
            }
        }];
    }
}

- (CGSize)preferredFrameSize
{
    CGSize preferredSize = CGSizeMake(0.0f, 0.0f);
    for (WLCalendarEventLayer *layer in _sortedEventLayers)
    {
        CGSize layerSize = [layer preferredFrameSize];
        preferredSize.width = MAX(preferredSize.width, layerSize.width);
    }
    preferredSize.height = timeRuler.numberOfHours * timeRuler.heightOfHour;
    return preferredSize;
}

#ifdef DEBUG_LAYERS
- (void)drawInContext:(CGContextRef)aContext
{
    // Draw line for each hour.
    CGRect layerBounds = self.bounds;
    CGContextSaveGState(aContext);
    CGContextBeginPath(aContext);
    CGFloat hourHeight = timeRuler.heightOfHour;
    for (NSUInteger i=0, size=timeRuler.numberOfHours; i<size; ++i)
    {
        CGContextMoveToPoint(aContext, layerBounds.origin.x, CGRectGetMaxY(layerBounds) - hourHeight * i);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(layerBounds), CGRectGetMaxY(layerBounds) - hourHeight * i);
    }
    CGColorRef lineColor = [[NSColor blackColor] WL_CGColor];
    CGContextSetStrokeColorWithColor(aContext, lineColor);
    CGContextStrokePath(aContext);
    CGContextRestoreGState(aContext);
}
#endif

- (void)setEvents:(NSSet *)newEvents
{
    [_sortedEventLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_sortedEventLayers removeAllObjects];

    for (id event in newEvents)
    {
        NSUInteger idx = [self _indexOfEventLayerForStartDate:[event startDate]];
        WLCalendarEventLayer *eventLayer = [self _setupEventLayerWithEvent:event];
        [_sortedEventLayers insertObject:eventLayer atIndex:idx];
        [self addSublayer:eventLayer];
        _eventsChanged = YES;
    }
}

- (NSUInteger)maximumNumberOfColumns
{
    NSUInteger maximumNumberOfColumns = self.bounds.size.width / [WLCalendarEventLayer minimalHumanVisibleWidth];
    maximumNumberOfColumns = MAX(maximumNumberOfColumns, 1); // at least 1 column
    return maximumNumberOfColumns;
}


#pragma mark Private

- (WLCalendarEventLayer *)_setupEventLayerWithEvent:(id)anEvent
{
    [CATransaction setDisableActions:YES];
    WLCalendarEventLayer *eventLayer = [WLCalendarEventLayer layer];
    eventLayer.name = [anEvent uid];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[anEvent title]];
    eventLayer.string = attributedString;
    [attributedString release];
    [CATransaction setDisableActions:YES];
    eventLayer.needsDisplayOnBoundsChange = YES;
    [CATransaction setDisableActions:NO];

    [eventLayer setValue:[anEvent startDate] forKey:_WLStartDateKey];
    [eventLayer setValue:[anEvent endDate] forKey:_WLEndDateKey];
#ifdef DEBUG_LAYERS
    eventLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    eventLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
    eventLayer.contentsBackgroundOpacity = 0.6;
#endif
    [CATransaction setDisableActions:NO];
    return eventLayer;
}

- (NSUInteger)_indexOfEventLayerForStartDate:(id)aStartDate
{
    NSArray *dates = [_sortedEventLayers valueForKey:_WLStartDateKey];
    NSUInteger idx = [dates indexOfObject:aStartDate
                            inSortedRange:NSMakeRange(0, [_sortedEventLayers count])
                                  options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                          usingComparator:^(id obj1, id obj2) {
                              return [obj1 compare:obj2];
                          }];
    return idx;
}

- (void)_buildEventsLayoutTree
{
    [_eventsLayoutTreeRootNode release];
    _eventsLayoutTreeRootNode = [[NSTreeNode alloc] initWithRepresentedObject:self];

    /* Input:
     +-----+
     |     |
     |     | +-----+
     |     | |     |
     |     | |  b  |
     |     | +-----+
     |     |
     |     |        +-----+
     | a   |        |     |
     |     |        |     |
     |     |        |  c  | +-----+
     |     |        |     | |     |
     |     |        +-----+ |     |
     |     |                |     |
     |     |                |  d  |
     |     |                |     |
     |     |                |     |
     +-----+                +-----+
     +-----+
     |     |
     |     |  +-----+
     |     |  |     |
     |  e  |  |  f  |
     |     |  |     |
     |     |  +-----+
     |     |
     +-----+
     */

    // Step 1: Divde layers into rows, where each element of the row intersects all other elements of the row itself or through it's siblings.
    {
        __block NSTreeNode *rowNode = nil;
        __block CGFloat rowTop = 0.0f;
        __block CGFloat rowBottom = 0.0f;
        [_sortedEventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *eventLayer, NSUInteger idx, BOOL *stop)
         {
             CGFloat top = [timeRuler hourForDate:[eventLayer valueForKey:_WLStartDateKey]] * timeRuler.heightOfHour;
             CGFloat bottom = [timeRuler hourForDate:[eventLayer valueForKey:_WLEndDateKey]] * timeRuler.heightOfHour;
             [eventLayer setValue:[NSNumber numberWithFloat:top] forKey:_WLTopKey];
             [eventLayer setValue:[NSNumber numberWithFloat:bottom] forKey:_WLBottomKey];
             if (IS_LESS_F(top, rowBottom))
             {
                 rowBottom = fmaxf(rowBottom, bottom);
                 [[rowNode representedObject] addObject:eventLayer];
             }
             else
             {
                 if (rowNode != nil)
                 {
                     [[_eventsLayoutTreeRootNode mutableChildNodes] addObject:rowNode];
                     [rowNode release];
                     rowNode = nil;
                 }
                 rowNode = [[NSTreeNode alloc] initWithRepresentedObject:[NSMutableArray array]];
                 rowTop = top;
                 rowBottom = bottom;
                 [[rowNode representedObject] addObject:eventLayer];
             }
         }];
        if ([[rowNode representedObject] count])
            [[_eventsLayoutTreeRootNode mutableChildNodes] addObject:rowNode];
        [rowNode release];
    }

    /* After Step 1
     Row 0
     +-----+
     |     |
     |     | +-----+
     |     | |     |
     |     | |  b  |
     |     | +-----+
     |     |
     |     |        +-----+
     | a   |        |     |
     |     |        |     |
     |     |        |  c  | +-----+
     |     |        |     | |     |
     |     |        +-----+ |     |
     |     |                |     |
     |     |                |  d  |
     |     |                |     |
     |     |                |     |
     +-----+                +-----+

     Row 1
     +-----+
     |     |
     |     |  +-----+
     |     |  |     |
     |  e  |  |  f  |
     |     |  |     |
     |     |  +-----+
     |     |
     +-----+
     */
    // Step 2: Divide elements of each row into columns, where each element doesn't intersect all other elements of the column.
    {
        [[_eventsLayoutTreeRootNode childNodes] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                            usingBlock:^(NSTreeNode *rowNode, NSUInteger idx, BOOL *stop)
         {
             __block NSMutableArray *row = [rowNode representedObject];


             while ([row count] > 0 && [[rowNode childNodes] count] < _cachedMaximumNumberOfColumns)
             {
                 WLCalendarEventLayer *topLayer = [row objectAtIndex:0];
                 NSTreeNode *columnNode = [NSTreeNode treeNodeWithRepresentedObject:[NSMutableArray arrayWithObject:topLayer]];
                 [row removeObjectAtIndex:0];

                 if ([row count] > 0)
                 {
                     __block CGFloat columnBottom = [[topLayer valueForKey:_WLBottomKey] floatValue];
                     NSMutableIndexSet *usedObjectIndexes = [NSMutableIndexSet indexSet];
                     [row enumerateObjectsUsingBlock:^(WLCalendarEventLayer *eventLayer, NSUInteger idx, BOOL *stop)
                      {
                          CGFloat top = [[eventLayer valueForKey:_WLTopKey] floatValue];
                          CGFloat bottom = [[eventLayer valueForKey:_WLBottomKey] floatValue];
                          if (IS_LESS_OR_EQ_F(columnBottom, top))
                          {
                              [[columnNode representedObject] addObject:eventLayer];
                              columnBottom = bottom;
                              [usedObjectIndexes addIndex:idx];
                          }
                      }];
                     [row removeObjectsAtIndexes:usedObjectIndexes];
                     [usedObjectIndexes removeAllIndexes];
                 }
                 [[rowNode mutableChildNodes] addObject:columnNode];
             }

             // It's possible that not all objects are distributed among columns because of maximumNumberOfColumns.
             // Distribute them among available columns.
             [row enumerateObjectsUsingBlock:^(WLCalendarEventLayer *eventLayer, NSUInteger idx, BOOL *stop)
              {
                  NSArray *columnNodes = [rowNode childNodes];
                  NSMutableArray *column = [[columnNodes objectAtIndex:idx % _cachedMaximumNumberOfColumns] representedObject];
                  [column addObject:eventLayer];
              }];
         }];
    }
    /* After Step 2
     Row 0
     Column 1   Column 2    Column 3
     +-----+
     |     |
     |     |    +-----+
     |     |    |     |
     |     |    |  b  |
     |     |    +-----+
     |     |
     |     |    +-----+
     | a   |    |     |
     |     |    |     |
     |     |    |  c  |     +-----+
     |     |    |     |     |     |
     |     |    +-----+     |     |
     |     |                |     |
     |     |                |  d  |
     |     |                |     |
     |     |                |     |
     +-----+                +-----+

     Row 1
     Column 1   Column 2
     +-----+
     |     |
     |     |    +-----+
     |     |    |     |
     |  e  |    |  f  |
     |     |    |     |
     |     |    +-----+
     |     |
     +-----+
     */

    // Step 3 (Optional): for each layer we look right to see if it intersects layers of next columns.
    // If it doesn't then it's width may be extended.
    {
        NSArray *rowNodes = [_eventsLayoutTreeRootNode childNodes];
        for (NSTreeNode *rowNode in rowNodes)
        {
            __block NSArray *columnNodes = [rowNode childNodes];
            [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stop)
             {
                 NSArray *events = [columnNode representedObject];
                 for (WLCalendarEventLayer *eventLayer in events)
                 {
                     CGFloat eventTop = [[eventLayer valueForKey:_WLTopKey] floatValue];
                     CGFloat eventBottom = [[eventLayer valueForKey:_WLBottomKey] floatValue];
                     NSRange rightColumns = NSMakeRange(columnIdx + 1, [columnNodes count] - columnIdx - 1);
                     [columnNodes enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rightColumns]
                                                    options:0
                                                 usingBlock:^(NSTreeNode *rightColumnNode, NSUInteger layerIdx, BOOL *stop)
                      {
                          BOOL doesIntersectRightColumn = NO;
                          for (WLCalendarEventLayer *rightEventLayer in [rightColumnNode representedObject])
                          {
                              CGFloat top = [[rightEventLayer valueForKey:_WLTopKey] floatValue];
                              CGFloat bottom = [[rightEventLayer valueForKey:_WLBottomKey] floatValue];
                              if (IS_LESS_F(eventTop, bottom) && IS_LESS_F(top, eventBottom))
                              {
                                  doesIntersectRightColumn = YES;
                                  break;
                              }
                              else if (IS_LESS_F(eventBottom, top))
                                  break;
                          }
                          if (!doesIntersectRightColumn)
                          {
                              NSNumber *oldValue = [eventLayer valueForKey:_WLNumberOfColumnsToSkipKey];
                              if (oldValue == nil)
                                  oldValue = [NSNumber numberWithUnsignedInteger:1];
                              else
                                  oldValue = [NSNumber numberWithUnsignedInteger:[oldValue unsignedIntegerValue] + 1];
                              [eventLayer setValue:oldValue forKey:_WLNumberOfColumnsToSkipKey];
                          }
                          else
                              *stop = YES;
                      }];
                 }
             }];
        }
    }
    /* After Step 3
     +-----+
     |     |
     |     | +-------------+
     |     | |             |
     |     | |  b          |
     |     | +-------------+
     |     |
     |     | +-----+
     | a   | |     |
     |     | |     |
     |     | |  c  | +-----+
     |     | |     | |     |
     |     | +-----+ |     |
     |     |         |     |
     |     |         |  d  |
     |     |         |     |
     |     |         |     |
     +-----+         +-----+
     +---------+
     |         |
     |         | +---------+
     |         | |         |
     |  e      | |  f      |
     |         | |         |
     |         | +---------+
     |         |
     +---------+
     */
}

@end

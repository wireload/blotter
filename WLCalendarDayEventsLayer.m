//
//  WLCalendarWeekdayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSColor+CGColor.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSFont+WLCalendar.h"


static NSString* const _WLStartDateKey = @"startDate";

static NSString* const _WLEndDateKey = @"endDate";

static NSString* const _WLStartHourKey = @"startHour";

static NSString* const _WLEndHourKey = @"endHour";

static NSString* const _WLNumberOfColumnsToSkipKey = @"skipColumns";


#define IS_LESS_OR_EQ_F(a, b) (BOOL)((a) <= (b) || (fabsf((b) - (a)) < FLT_EPSILON))

#define IS_LESS_F(a, b) (BOOL)((a) < (b) && !(fabsf((b) - (a)) < FLT_EPSILON))


@implementation WLCalendarDayEventsLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedByUIDEventLayers = [[NSMutableArray alloc] init];
        _sortedByStartDateEventLayers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_sortedByStartDateEventLayers release];
    [_sortedByUIDEventLayers release];
    [_eventsLayoutTreeRootNode release];
    [super dealloc];
}


#pragma mark Properties
@dynamic timeRuler;
@dynamic events;
@synthesize keepTextOfEventsVisible;
@dynamic heightOfHour;

- (NSSet *)events
{
    NSMutableSet *events = [NSMutableSet setWithCapacity:[_sortedByUIDEventLayers count]];
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

- (void)setEvents:(NSSet *)newEvents
{
    [_sortedByStartDateEventLayers removeAllObjects];
    NSMutableArray *sublayersToRemove = [_sortedByUIDEventLayers mutableCopy];
    for (id event in newEvents)
    {
        BOOL isFound = NO;
        NSUInteger idxByUID = [self _indexOfEventLayerWithUID:[event uid] isFound:&isFound];
        WLCalendarEventLayer *layer = nil;
        if (isFound)
        {
            layer = [_sortedByUIDEventLayers objectAtIndex:idxByUID];
            [self _updateEventLayer:layer withEvent:event];
            [sublayersToRemove removeObjectIdenticalTo:layer];
        }
        else
        {
            layer = [self _setupEventLayer];
            [self _updateEventLayer:layer withEvent:event];
            [_sortedByUIDEventLayers insertObject:layer atIndex:idxByUID];
            [self addSublayer:layer];
        }

        NSUInteger idxByStartDate = [self _indexOfEventLayerWithStartDate:[event startDate]];
        [_sortedByStartDateEventLayers insertObject:layer atIndex:idxByStartDate];
        layer.zPosition = idxByStartDate;
    }
    [sublayersToRemove makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    for (WLCalendarEventLayer *l in sublayersToRemove)
        [_sortedByUIDEventLayers removeObjectIdenticalTo:l];
    [sublayersToRemove release];
    _eventsChanged = YES;
}

- (void)setKeepTextOfEventsVisible:(BOOL)newKeepTextOfEventsVisible
{
    keepTextOfEventsVisible = newKeepTextOfEventsVisible;
    for (WLCalendarEventLayer *l in _sortedByUIDEventLayers)
        l.keepTextVisible = keepTextOfEventsVisible;
}


#pragma mark Methods

- (NSUInteger)maximumNumberOfColumns
{
    NSUInteger n = self.bounds.size.width / [WLCalendarEventLayer minimumHumanVisibleWidth];
    n = MAX(n, (NSUInteger)1); // at least 1 column
    return n;
}

- (WLHourRange)hourRangeOfEvents
{
    if ([_sortedByStartDateEventLayers count] == 0)
        return WLHourRangeZero;

    NSDate *start = [[_sortedByStartDateEventLayers objectAtIndex:0] valueForKey:_WLStartDateKey];
    NSDate *end = nil;
    for (WLCalendarEventLayer *e in _sortedByStartDateEventLayers)
        end = [[e valueForKey:_WLEndDateKey] laterDate:end];
    return (WLHourRange) {
        .startHour = [self.timeRuler hourForDate:start],
        .endHour = [self.timeRuler hourForDate:end]
    };
}

- (WLHourRange)visibleHourRangeOfEventsForHeightOfHour:(CGFloat)aHeightOfHour
{
    if ([_sortedByStartDateEventLayers count] == 0)
        return WLHourRangeZero;

    WLCalendarEventLayer *lastEventLayer = [_sortedByStartDateEventLayers lastObject];
    CGFloat t = [self _minYOfEventLayer:lastEventLayer forHeightOfHour:aHeightOfHour];
    CGFloat b = [self _maxYOfEventLayer:lastEventLayer forHeightOfHour:aHeightOfHour minY:t];
    WLHourRange actualHourRange = [self hourRangeOfEvents];
    return (WLHourRange) {
        .startHour = actualHourRange.startHour,
        .endHour = fmaxf(actualHourRange.endHour, b / aHeightOfHour)
    };
}


#pragma mark Private

- (WLCalendarEventLayer *)_setupEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.needsDisplayOnBoundsChange = YES;
        l.masksToBounds = YES;
        l.contentsGravity = kCAGravityBottom;
        l.anchorPoint = CGPointMake(0.0f, 0.0f);
        l.keepTextVisible = self.keepTextOfEventsVisible;
#ifndef DEBUG_LAYERS
        l.contentsBackgroundOpacity = 0.3f;
#endif
    }];
    return l;
}

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(CalEvent *)anEvent
{
    aLayer.name = [anEvent uid];
    NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 (id)[[NSColor whiteColor] WL_CGColor], (id)kCTForegroundColorAttributeName,
                                 (id)[NSFont WL_eventTitleFont],        (id)kCTFontAttributeName,
                                 nil];
    if ([[anEvent title] length])
        aLayer.title = [[[NSAttributedString alloc] initWithString:[anEvent title] attributes:attr] autorelease];
    else
        aLayer.title = nil;

    if ([[anEvent location] length])
    {
        [attr setObject:(id)[NSFont WL_eventLocationFont] forKey:(id)kCTFontAttributeName];
        aLayer.location = [[[NSAttributedString alloc] initWithString:[anEvent location] attributes:attr] autorelease];
    }
    else
        aLayer.location = nil;

    [aLayer setValue:[anEvent startDate] forKey:_WLStartDateKey];
    [aLayer setValue:[anEvent endDate] forKey:_WLEndDateKey];
    [aLayer setValue:nil forKey:_WLStartHourKey];
    [aLayer setValue:nil forKey:_WLEndHourKey];
    [aLayer setValue:nil forKey:_WLNumberOfColumnsToSkipKey];
#ifdef DEBUG_LAYERS
    aLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    aLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#endif
}

- (NSUInteger)_indexOfEventLayerWithStartDate:(NSDate *)aStartDate
{
    NSArray *dates = [_sortedByStartDateEventLayers valueForKey:_WLStartDateKey];
    NSUInteger i = [dates indexOfObject:aStartDate
                          inSortedRange:NSMakeRange(0, [_sortedByStartDateEventLayers count])
                                options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                        usingComparator:^(NSDate *aDate, NSDate *bDate)
    {
        return [aDate compare:bDate];
    }];
    return i;
}

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

- (void)_buildEventsLayoutTree
{
    [_eventsLayoutTreeRootNode release];
    _eventsLayoutTreeRootNode = [[NSTreeNode alloc] initWithRepresentedObject:nil];

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
        [_sortedByStartDateEventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            CGFloat layerTop = [self _minYOfEventLayer:l forHeightOfHour:self.heightOfHour];
            CGFloat layerBottom = [self _maxYOfEventLayer:l forHeightOfHour:self.heightOfHour minY:layerTop];
            if (IS_LESS_F(layerTop, rowBottom))
            {
                rowBottom = fmaxf(rowBottom, layerBottom);
                [[rowNode representedObject] addObject:l];
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
                rowTop = layerTop;
                rowBottom = layerBottom;
                [[rowNode representedObject] addObject:l];
            }
        }];
        if ([(NSArray *)[rowNode representedObject] count])
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
                                                                 usingBlock:^(NSTreeNode *rowNode, NSUInteger rowIdx, BOOL *stopRow)
        {
            __block NSMutableArray *row = [rowNode representedObject];
            while ([row count] > 0 && [[rowNode childNodes] count] < _maximumNumberOfColumns)
            {
                WLCalendarEventLayer *topLayer = [row objectAtIndex:0];
                NSMutableArray *column = [NSMutableArray arrayWithObject:topLayer];
                NSTreeNode *columnNode = [NSTreeNode treeNodeWithRepresentedObject:column];
                [row removeObjectAtIndex:0];

                if ([row count] > 0)
                {
                    __block CGFloat columnTop = [self _minYOfEventLayer:topLayer forHeightOfHour:self.heightOfHour];
                    __block CGFloat columnBottom = [self _maxYOfEventLayer:topLayer forHeightOfHour:self.heightOfHour minY:columnTop];
                    NSMutableIndexSet *placedLayers = [NSMutableIndexSet indexSet];
                    [row enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
                    {
                        CGFloat layerTop = [self _minYOfEventLayer:l forHeightOfHour:self.heightOfHour];
                        CGFloat layerBottom = [self _maxYOfEventLayer:l forHeightOfHour:self.heightOfHour minY:layerTop];
                        if (IS_LESS_OR_EQ_F(columnBottom, layerTop))
                        {
                            [column addObject:l];
                            columnBottom = layerBottom;
                            [placedLayers addIndex:layerIdx];
                        }
                    }];
                    [row removeObjectsAtIndexes:placedLayers];
                    [placedLayers removeAllIndexes];
                }
                [[rowNode mutableChildNodes] addObject:columnNode];
            }

            // It's possible that not all objects are distributed among columns because of maximumNumberOfColumns.
            // Distribute them among available columns.
            [row enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
            {
                NSTreeNode *columnNode = [[rowNode childNodes] objectAtIndex:layerIdx % _maximumNumberOfColumns];
                NSMutableArray *column = [columnNode representedObject];
                [column addObject:l];
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
            [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stopColumn)
            {
                NSArray *events = [columnNode representedObject];
                for (WLCalendarEventLayer *left in events)
                {
                    CGFloat leftTop = [self _minYOfEventLayer:left forHeightOfHour:self.heightOfHour];
                    CGFloat leftBottom = [self _maxYOfEventLayer:left forHeightOfHour:self.heightOfHour minY:leftTop];
                    NSRange rightColumns = NSMakeRange(columnIdx + 1, [columnNodes count] - columnIdx - 1);
                    __block NSUInteger numberOfColumnsToSkip = 0;
                    [columnNodes enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rightColumns]
                                                   options:0
                                                usingBlock:^(NSTreeNode *rightColumnNode, NSUInteger rightColumnIdx, BOOL *stopRightColumn)
                    {
                        BOOL doesIntersectRightColumn = NO;
                        for (WLCalendarEventLayer *right in [rightColumnNode representedObject])
                        {
                            CGFloat rightTop = [self _minYOfEventLayer:right forHeightOfHour:self.heightOfHour];
                            CGFloat rightBottom = [self _maxYOfEventLayer:right forHeightOfHour:self.heightOfHour minY:rightTop];
                            if (IS_LESS_F(leftTop, rightBottom) && IS_LESS_F(rightTop, leftBottom))
                            {
                                doesIntersectRightColumn = YES;
                                break;
                            }
                            else if (IS_LESS_F(leftBottom, rightTop))
                                break;
                        }
                        if (!doesIntersectRightColumn)
                            ++numberOfColumnsToSkip;
                        else
                            *stopRightColumn = YES;
                     }];
                    [left setValue:[NSNumber numberWithUnsignedInteger:numberOfColumnsToSkip] forKey:_WLNumberOfColumnsToSkipKey];
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

- (CGFloat)_startHourOfEventLayer:(WLCalendarEventLayer *)aLayer
{
    NSNumber *startHour = [aLayer valueForKey:_WLStartHourKey];
    if (startHour == nil)
    {
        startHour = [NSNumber numberWithFloat:[self.timeRuler hourForDate:[aLayer valueForKey:_WLStartDateKey]]];
        [aLayer setValue:startHour forKey:_WLStartHourKey];
    }
    return [startHour floatValue];
}

- (CGFloat)_endHourOfEventLayer:(WLCalendarEventLayer *)aLayer
{
    NSNumber *endHour = [aLayer valueForKey:_WLEndHourKey];
    if (endHour == nil)
    {
        endHour = [NSNumber numberWithFloat:[self.timeRuler hourForDate:[aLayer valueForKey:_WLEndDateKey]]];
        [aLayer setValue:endHour forKey:_WLEndHourKey];
    }
    return [endHour floatValue];
}

- (CGFloat)_minYOfEventLayer:(WLCalendarEventLayer *)aLayer forHeightOfHour:(CGFloat)aHeightOfHour
{
    return [self _startHourOfEventLayer:aLayer] * aHeightOfHour;
}

- (CGFloat)_maxYOfEventLayer:(WLCalendarEventLayer *)aLayer forHeightOfHour:(CGFloat)aHeightOfHour minY:(CGFloat)aMinY
{
    CGFloat maxY = [self _endHourOfEventLayer:aLayer] * aHeightOfHour;
    CGFloat minimumHeight = [aLayer minimumHumanVisibleHeight];
    if (IS_LESS_F(maxY - aMinY, minimumHeight))
        maxY = aMinY + minimumHeight;
    return maxY;
}


#pragma mark CALayer

- (void)layoutSublayers
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    if ([_sortedByStartDateEventLayers count] == 0)
        return;

    if (_eventsChanged || _maximumNumberOfColumns != [self maximumNumberOfColumns])
    {
        _eventsChanged = NO;
        _maximumNumberOfColumns = [self maximumNumberOfColumns];
        [self _buildEventsLayoutTree];
    }

    // Traverse tree and calculate frames.
    for (NSTreeNode *rowNode in [_eventsLayoutTreeRootNode childNodes])
    {
        static const CGFloat XSpaceBetweenEvents = 2.0f;
        static const CGFloat CornerRadius = 5.0f;

        NSArray *columnNodes = [rowNode childNodes];
        NSUInteger n = [columnNodes count];
        CGFloat columnWidth = fmaxf((self.bounds.size.width - XSpaceBetweenEvents * (n - 1)) / n,
                                    [WLCalendarEventLayer minimumHumanVisibleWidth]);
        BOOL shouldRoundCorners = [columnNodes count] > 1;
        [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stop)
        {
            for (WLCalendarEventLayer *l in [columnNode representedObject])
            {
                CGFloat t = [self _minYOfEventLayer:l forHeightOfHour:self.heightOfHour];
                CGFloat b = [self _maxYOfEventLayer:l forHeightOfHour:self.heightOfHour minY:t];
                NSUInteger numberOfColumnsToSkip = [[l valueForKey:_WLNumberOfColumnsToSkipKey] unsignedIntegerValue];
                l.frame = CGRectMake(ceilf(CGRectGetMinX(self.bounds) + columnIdx * (columnWidth + XSpaceBetweenEvents)),
                                     floorf(t),
                                     floorf(columnWidth + (columnWidth + XSpaceBetweenEvents) * numberOfColumnsToSkip),
                                     floor(b - t));
                if (shouldRoundCorners)
                    l.cornerRadius = CornerRadius;
                else
                    l.cornerRadius = 0.0f;
                if (self.keepTextOfEventsVisible)
                        [l setNeedsDisplay];
            }
        }];
    }
}

- (CGSize)preferredFrameSize
{
    CGSize s = CGSizeMake(0.0f, 0.0f);
    for (WLCalendarEventLayer *l in _sortedByStartDateEventLayers)
    {
        CGSize ls = [l preferredFrameSize];
        s.width = ceilf(fmaxf(s.width, ls.width));
    }
    s.height = ceilf(self.timeRuler.numberOfHours * self.heightOfHour);
    return s;
}

#ifdef DEBUG_LAYERS
- (void)drawInContext:(CGContextRef)aContext
{
    // Draw line for each hour.
    CGContextSaveGState(aContext);
    CGContextSetFillColorWithColor(aContext, [[NSColor clearColor] WL_CGColor]);
    CGContextFillRect(aContext, CGContextGetClipBoundingBox(aContext));

    CGContextBeginPath(aContext);
    CGFloat hourHeight = self.heightOfHour;
    for (NSUInteger i=0, numberOfHours=self.timeRuler.numberOfHours; i<numberOfHours; ++i)
    {
        CGFloat y = self.bounds.origin.y + hourHeight * i;
        CGContextMoveToPoint(aContext, self.bounds.origin.x, y);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), y);
    }
    CGColorRef lineColor = [[NSColor blackColor] WL_CGColor];
    CGContextSetStrokeColorWithColor(aContext, lineColor);
    CGContextStrokePath(aContext);
    CGContextRestoreGState(aContext);
}
#endif

- (void)scrollPoint:(CGPoint)aPoint
{
    [super scrollPoint:aPoint];
    if (self.keepTextOfEventsVisible)
        [_sortedByUIDEventLayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (void)scrollRectToVisible:(CGRect)aRect
{
    [super scrollRectToVisible:aRect];
    if (self.keepTextOfEventsVisible)
        [_sortedByUIDEventLayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

@end

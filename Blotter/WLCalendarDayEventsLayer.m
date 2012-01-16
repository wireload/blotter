//
//  WLCalendarWeekdayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static NSString* const _WLStartDateKey = @"startDate";

static NSString* const _WLEndDateKey = @"endDate";

static NSString* const _WLNumberOfColumnsToSkipKey = @"skipColumns";


static const CGFloat _XSpaceBetweenEvents = 2.0f;


#define IS_EQ_F(a, b) (BOOL)(fabsf((b) - (a)) < FLT_EPSILON)

#define IS_LESS_OR_EQ_F(a, b) (BOOL)((a) <= (b) || IS_EQ_F(a, b))

#define IS_LESS_F(a, b) (BOOL)((a) < (b) && !IS_EQ_F(a, b))


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
@synthesize keepsTextOfEventsVisible;
@dynamic heightOfHour;

- (NSSet *)events
{
    NSMutableSet *events = [NSMutableSet setWithCapacity:[_sortedByUIDEventLayers count]];
    for (WLCalendarEventLayer *eventLayer in _sortedByUIDEventLayers)
    {
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               eventLayer.name,                 @"uid",
                               [eventLayer.title string],       @"title",
                               [eventLayer.location string],    @"location",
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
        NSUInteger idxByUID = [self _indexForInsertionOfEventLayerWithUID:[event uid] isFound:&isFound];
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

        NSUInteger idxByStartDate = [self _indexForInsertionOfEventLayerWithStartDate:[event startDate]];
        [_sortedByStartDateEventLayers insertObject:layer atIndex:idxByStartDate];
        layer.zPosition = idxByStartDate;
    }
    [sublayersToRemove makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    for (WLCalendarEventLayer *l in sublayersToRemove)
        [_sortedByUIDEventLayers removeObjectIdenticalTo:l];
    [sublayersToRemove release];
    _areEventsChanged = YES;
}

- (void)setKeepsTextOfEventsVisible:(BOOL)newKeepTextOfEventsVisible
{
    keepsTextOfEventsVisible = newKeepTextOfEventsVisible;
    for (WLCalendarEventLayer *l in _sortedByUIDEventLayers)
        l.keepTextVisible = keepsTextOfEventsVisible;
}

- (void)setBounds:(CGRect)newBounds
{
    if (!IS_EQ_F(newBounds.size.height, self.bounds.size.height))
        _isHeightChanged = YES;
    [super setBounds:newBounds];
}


#pragma mark Methods

- (NSUInteger)maximumNumberOfColumns
{
    NSUInteger n = (self.bounds.size.width + _XSpaceBetweenEvents) / ([WLCalendarEventLayer minimumHumanVisibleWidth] + _XSpaceBetweenEvents);
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

    WLCalendarEventLayer *minYLayer = [_sortedByStartDateEventLayers objectAtIndex:0];
    WLCalendarEventLayer *maxYLayer = nil;
    CGFloat maxYLayerBottom = 0.0f;
    for (WLCalendarEventLayer *e in _sortedByStartDateEventLayers)
    {
        CGFloat t = [self _minYOfEventLayer:e forHeightOfHour:aHeightOfHour];
        CGFloat b = [self _maxYOfEventLayer:e forHeightOfHour:aHeightOfHour minY:t];
        if (b >= maxYLayerBottom)
        {
            maxYLayer = e;
            maxYLayerBottom = b;
        }
    }
    WLHourRange hourRange = [self hourRangeOfEvents];
    return (WLHourRange) {
        .startHour = fminf(hourRange.startHour, [self _minYOfEventLayer:minYLayer forHeightOfHour:aHeightOfHour] / aHeightOfHour),
        .endHour = fmaxf(hourRange.endHour, maxYLayerBottom / aHeightOfHour)
    };
}


#pragma mark Private

- (WLCalendarEventLayer *)_setupEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    l.needsDisplayOnBoundsChange = YES;
    l.masksToBounds = YES;
    l.contentsGravity = kCAGravityBottom;
    l.anchorPoint = CGPointMake(0.0f, 0.0f);
    l.keepTextVisible = self.keepsTextOfEventsVisible;
#ifndef DEBUG_LAYERS
    l.contentsBackgroundOpacity = 0.45f;
#endif
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
        [attr setObject:(id)[[NSColor WL_eventLocationColor] WL_CGColor] forKey:(id)kCTForegroundColorAttributeName];

        aLayer.location = [[[NSAttributedString alloc] initWithString:[anEvent location] attributes:attr] autorelease];
    }
    else
        aLayer.location = nil;

    [aLayer setValue:[anEvent startDate] forKey:_WLStartDateKey];
    [aLayer setValue:[anEvent endDate] forKey:_WLEndDateKey];
    [aLayer setValue:nil forKey:_WLNumberOfColumnsToSkipKey];
#ifdef DEBUG_LAYERS
    aLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    aLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#endif
}

- (NSUInteger)_indexForInsertionOfEventLayerWithStartDate:(NSDate *)aStartDate
{
    NSArray *dates = [_sortedByStartDateEventLayers valueForKey:_WLStartDateKey];
    NSUInteger i = [dates indexOfObject:aStartDate
                          inSortedRange:NSMakeRange(0, [_sortedByStartDateEventLayers count])
                                options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                        usingComparator:^(NSDate *aDate, NSDate *bDate)
    {
        return [aDate compare:bDate];
    }];
    return i;
}

- (NSUInteger)_indexForInsertionOfEventLayerWithUID:(NSString *)anUID isFound:(out BOOL *)outIsFound
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

- (void)_buildEventsLayoutTreeIfNeeded
{
    NSUInteger newMaximumNumberOfColumns = [self maximumNumberOfColumns];
    if (_areEventsChanged || _isHeightChanged || _maximumNumberOfColumns != newMaximumNumberOfColumns)
    {
        _areEventsChanged = NO;
        _isHeightChanged = NO;
        _maximumNumberOfColumns = newMaximumNumberOfColumns;
        [self _buildEventsLayoutTree];
    }
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
    return [self.timeRuler hourForDate:[aLayer valueForKey:_WLStartDateKey]];
}

- (CGFloat)_endHourOfEventLayer:(WLCalendarEventLayer *)aLayer
{
    return [self.timeRuler hourForDate:[aLayer valueForKey:_WLEndDateKey]];
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

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"masksToBounds"])
        return [NSNumber numberWithBool:YES];
    else
        return [super defaultValueForKey:aKey];
}

- (void)layoutSublayers
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    if ([_sortedByStartDateEventLayers count] == 0)
        return;

    [self _buildEventsLayoutTreeIfNeeded];

    static const CGFloat CornerRadius = 5.0f;
    CGFloat lastHourY = self.timeRuler.numberOfHours * self.heightOfHour;
    // Traverse tree and calculate frames.
    for (NSTreeNode *rowNode in [_eventsLayoutTreeRootNode childNodes])
    {
        NSArray *columnNodes = [rowNode childNodes];
        NSUInteger numberOfColumnsInRow = [columnNodes count];
        CGFloat columnWidth = fmaxf((self.bounds.size.width - _XSpaceBetweenEvents * (numberOfColumnsInRow - 1)) / numberOfColumnsInRow,
                                    [WLCalendarEventLayer minimumHumanVisibleWidth]);
        BOOL shouldRoundCorners = [columnNodes count] > 1;
        [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stop)
        {

            NSArray *eventLayers = [columnNode representedObject];
            [eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stop) {
                CGFloat t = [self _minYOfEventLayer:l forHeightOfHour:self.heightOfHour];
                CGFloat b = [self _maxYOfEventLayer:l forHeightOfHour:self.heightOfHour minY:t];
                // If bottom of the event is equal or greater than Y of last hour, we should extend it to match bottom of the column.
                if (IS_LESS_OR_EQ_F(floorf(lastHourY), ceilf(b)))
                    b = CGRectGetMaxY(self.bounds) - 1.0f;

                NSUInteger numberOfColumnsToSkip = [[l valueForKey:_WLNumberOfColumnsToSkipKey] unsignedIntegerValue];
                CGFloat x = roundf(CGRectGetMinX(self.bounds) + columnIdx * (columnWidth + _XSpaceBetweenEvents));
                CGFloat y = roundf(t);
                CGFloat width = fminf(CGRectGetWidth(self.bounds) - x, roundf(columnWidth + (columnWidth + _XSpaceBetweenEvents) * numberOfColumnsToSkip));
                CGFloat height = fminf(CGRectGetHeight(self.bounds) - y, roundf(b) - y);
                l.frame = CGRectMake(x, y, width, height);

                if (shouldRoundCorners)
                    l.cornerRadius = CornerRadius;
                else
                    l.cornerRadius = 0.0f;

                if (self.keepsTextOfEventsVisible)
                    [l setNeedsDisplay];
            }];
        }];
    }
}

- (CGSize)preferredFrameSize
{
    CGSize s = CGSizeMake(0.0f, 0.0f);
    for (WLCalendarEventLayer *l in _sortedByStartDateEventLayers)
        s.width = fmaxf(s.width, [l preferredFrameSize].width);
    s.width = ceilf(s.width);
    s.height = ceilf(WLHourRangeLength([self visibleHourRangeOfEventsForHeightOfHour:self.heightOfHour]) * self.heightOfHour);
    return s;
}

#ifdef DEBUG_LAYERS
- (void)drawInContext:(CGContextRef)aContext
{
    // Draw line for each hour.
    CGContextSaveGState(aContext);
    CGContextSetFillColorWithColor(aContext, [[NSColor clearColor] WL_CGColor]);
    CGContextFillRect(aContext, CGContextGetClipBoundingBox(aContext));
    CGContextSetAllowsAntialiasing(aContext, NO);

    // Draw "real" hours.
    CGContextBeginPath(aContext);
    for (NSUInteger i = 0, numberOfHours = self.timeRuler.numberOfHours; i < numberOfHours; ++i)
    {
        CGFloat y = roundf(self.bounds.origin.y + self.heightOfHour * i);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, y);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), y);
    }
    CGColorRef lineColor = [[NSColor blackColor] WL_CGColor];
    CGContextSetStrokeColorWithColor(aContext, lineColor);
    CGContextStrokePath(aContext);

    // Draw "virtual" visible hours.
    CGContextBeginPath(aContext);
    for (NSUInteger i = self.timeRuler.numberOfHours, numberOfHours = ceilf([self visibleHourRangeOfEventsForHeightOfHour:self.heightOfHour].endHour); i <= numberOfHours; ++i)
    {
        CGFloat y = roundf(self.bounds.origin.y + self.heightOfHour * i);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, y);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), y);
    }
    lineColor = [[NSColor whiteColor] WL_CGColor];
    CGContextSetStrokeColorWithColor(aContext, lineColor);
    CGContextStrokePath(aContext);

    CGContextRestoreGState(aContext);
}
#endif

- (void)scrollPoint:(CGPoint)aPoint
{
    [super scrollPoint:aPoint];
    if (self.keepsTextOfEventsVisible)
        [_sortedByUIDEventLayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (void)scrollRectToVisible:(CGRect)aRect
{
    [super scrollRectToVisible:aRect];
    if (self.keepsTextOfEventsVisible)
        [_sortedByUIDEventLayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

@end

//
//  WLCalendarWeekdayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import <WLFoundation/WLFoundation.h>
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static NSString *const _WLEventKey = @"WLCalendarDayEventsLayer_event";

static NSString* const _WLHourRangeKey = @"WLCalendarDayEventsLayer_hourRange";

static NSString* const _WLNumberOfColumnsToSkipKey = @"WLCalendarDayEventsLayer_skipColumns";


static const CGFloat _XSpaceBetweenEvents = 2.0;


@implementation WLCalendarDayEventsLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedByStartDateEventLayers = [[NSMutableArray alloc] init];
        _needsUpdateToFitAllEventsCache = YES;
        hourRangeOfEvents = WLHourRangeZero;
    }
    return self;
}

- (id)initWithLayer:(id)aLayer
{
    self = [super initWithLayer:aLayer];
    if (self != nil)
    {
        hourRangeOfEvents = [aLayer hourRangeOfEvents];
    }
    return self;
}

- (void)dealloc
{
    [_sortedByStartDateEventLayers release];
    [_eventsLayoutTreeRootNode release];
    [super dealloc];
}


#pragma mark Properties
@dynamic timeRuler;
@dynamic events;
@synthesize keepsTextOfEventsVisible;
@synthesize hourRangeOfEvents;

- (NSSet *)events
{
    return [NSSet setWithArray:[_sortedByStartDateEventLayers valueForKey:_WLEventKey]];
}

- (void)setEvents:(NSSet *)newEvents
{
    NSMutableArray *unusedSublayers = [_sortedByStartDateEventLayers mutableCopy];
    [_sortedByStartDateEventLayers removeAllObjects];
    WLHourRange newHourRangeOfEvents = WLHourRangeInvalid;
    for (id event in newEvents)
    {
        NSUInteger indexOfUsedLayer = [unusedSublayers indexOfObjectPassingTest:^BOOL(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            id layerEvent = l.dayEvent;
            return [layerEvent isEqual:event] || (
                                                  [[layerEvent uid] isEqual:[event uid]] &&
                                                  [[[(CalEvent *)layerEvent calendar] uid] isEqual:[[(CalEvent *)event calendar] uid]]
                                                  );
        }];
        WLCalendarEventLayer *layer = nil;
        if (indexOfUsedLayer != NSNotFound)
        {
            // Layer for the event already exist. Update it.
            layer = [unusedSublayers objectAtIndex:indexOfUsedLayer];
            layer.dayEvent = event;
            [unusedSublayers removeObjectAtIndex:indexOfUsedLayer];
        }
        else
        {
            // Create new layer for the event.
            layer = [WLCalendarEventLayer dayEventLayer];
            layer.delegate = self.delegate;
            layer.contentsScale = self.contentsScale;
            layer.keepsTextVisible = self.keepsTextOfEventsVisible;
            [self addSublayer:layer];
            layer.dayEvent = event;
        }
        NSUInteger idxByStartDate = [self _indexForInsertionOfEventLayerWithEvent:event];
        [_sortedByStartDateEventLayers insertObject:layer atIndex:idxByStartDate];

        WLHourRange eventHourRange = layer.hourRange;
        newHourRangeOfEvents.startHour = fmin(newHourRangeOfEvents.startHour, eventHourRange.startHour);
        newHourRangeOfEvents.endHour = fmax(newHourRangeOfEvents.endHour, eventHourRange.endHour);
    }

    // Later events should be always displayed on top of early layers.
    [_sortedByStartDateEventLayers enumerateObjectsUsingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop) {
        l.zPosition = idx;
    }];
    [unusedSublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [unusedSublayers release];
    _needsUpdateToFitAllEventsCache = YES;

    BOOL areThereEvents = !WLHourRangeEqualToHourRange(newHourRangeOfEvents, WLHourRangeInvalid);
    if (!areThereEvents)
        newHourRangeOfEvents = WLHourRangeZero;

    if (!WLHourRangeEqualToHourRange(newHourRangeOfEvents, hourRangeOfEvents))
    {
        [self willChangeValueForKey:@"hourRangeOfEvents"];
        hourRangeOfEvents = newHourRangeOfEvents;
        [self didChangeValueForKey:@"hourRangeOfEvents"];
    }
}

- (void)setKeepsTextOfEventsVisible:(BOOL)newKeepTextOfEventsVisible
{
    keepsTextOfEventsVisible = newKeepTextOfEventsVisible;
    [_sortedByStartDateEventLayers makeObjectsPerformSelector:@selector(setKeepsTextVisible:)
                                                   withObject:[NSNumber numberWithBool:keepsTextOfEventsVisible]];
}

+ (BOOL)automaticallyNotifiesObserversOfHourRangeOfEvents
{
    return NO;
}


#pragma mark Methods

- (NSUInteger)maximumNumberOfColumns
{
    NSUInteger n = (NSUInteger)((self.bounds.size.width + _XSpaceBetweenEvents) / ([WLCalendarEventLayer minimumHumanVisibleWidth] + _XSpaceBetweenEvents));
    n = MAX(n, (NSUInteger)1); // at least 1 column
    return n;
}

- (CGFloat)preferredFrameWidth
{
    CGFloat w = 0.0;
    for (WLCalendarEventLayer *l in _sortedByStartDateEventLayers)
        w = fmax(w, [l preferredFrameSize].width);
    return w;
}

- (CGFloat)extent
{
    CGFloat availableHeight = [self.timeRuler locationForHour:[self.timeRuler hourRange].endHour];
    CGFloat extent = 0.0;
    for (WLCalendarEventLayer *l in _sortedByStartDateEventLayers)
    {
        extent = fmax(extent, fdim(WLSegmentGetMaxLocation([l segmentOnTimeRuler:self.timeRuler]), availableHeight));
    }
    return extent;
}

- (BOOL)toFitAllEventsWithinLayerHeight:(CGFloat)aLayerHeight
                       startingWithHour:(CGFloat)aStartHour
                              hourRange:(out WLHourRange *)outHourRange
        shouldBePlacedWithinLayerHeight:(out CGFloat *)outLayerHeight;
{
    NSParameterAssert(aLayerHeight >= 0.0);

    WLHourRange fixedHourRangeOfEvents = self.hourRangeOfEvents;
    if (WLHourRangeEqualToHourRange(fixedHourRangeOfEvents, WLHourRangeZero))
        return NO;
    else if (outHourRange == NULL && outLayerHeight == NULL)
        return YES;

    NSParameterAssert(aStartHour <= fixedHourRangeOfEvents.startHour);

    if (IS_EQ_CGFLOAT(aLayerHeight, 0.0))
    {
        if (outHourRange != NULL)
            *outHourRange = fixedHourRangeOfEvents;
        if (outLayerHeight != NULL)
            *outLayerHeight = 0.0;
        return YES;
    }

    // According to tests, this method is called very often with the same parameters.
    // Caching the result of last call improves performance.
    if (_needsUpdateToFitAllEventsCache ||
        !IS_EQ_CGFLOAT(_toFitAllEventsCache.cachedLayerHeight, aLayerHeight) ||
        !IS_EQ_CGFLOAT(_toFitAllEventsCache.cachedStartHour, aStartHour))
    {
        fixedHourRangeOfEvents.startHour = aStartHour;
        WLHourRange hourRangeOfEventsExceptBottommost = WLHourRangeZero;
        CGFloat availableLayerHeight = CGFLOAT_MAX;
        CGFloat heightOfHour = CGFLOAT_MAX;
        for (WLCalendarEventLayer *eventLayer in _sortedByStartDateEventLayers)
        {
            WLHourRange hourRangeOfEventsExceptEventLayer = WLHourRangeMake(fixedHourRangeOfEvents.startHour,
                                                                                   eventLayer.hourRange.startHour);
            CGFloat lengthOfHourRangeOfEventLayer = WLHourRangeLength(hourRangeOfEventsExceptEventLayer);
            if (lengthOfHourRangeOfEventLayer > 0.0)
            {
                CGFloat minHeightOfEventLayer = [eventLayer minimumHumanVisibleHeight];
                CGFloat currentAvailableLayerHeight = fdim(aLayerHeight, minHeightOfEventLayer);
                CGFloat currentHeightOfHour = currentAvailableLayerHeight / lengthOfHourRangeOfEventLayer;
                if (currentHeightOfHour < heightOfHour)
                {
                    hourRangeOfEventsExceptBottommost = hourRangeOfEventsExceptEventLayer;
                    availableLayerHeight = currentAvailableLayerHeight;
                    heightOfHour = currentHeightOfHour;
                }
            }
        }

        BOOL success = (availableLayerHeight != CGFLOAT_MAX && heightOfHour != CGFLOAT_MAX);
        if (success)
        {
            _toFitAllEventsCache.cachedLayerHeight = aLayerHeight;
            _toFitAllEventsCache.cachedStartHour = aStartHour;
            _toFitAllEventsCache.cachedOutHourRange = hourRangeOfEventsExceptBottommost;
            _toFitAllEventsCache.cachedOutLayerHeight = availableLayerHeight;
            _needsUpdateToFitAllEventsCache = NO;
            if (outHourRange != NULL)
                *outHourRange = _toFitAllEventsCache.cachedOutHourRange;
            if (outLayerHeight != NULL)
                *outLayerHeight = _toFitAllEventsCache.cachedOutLayerHeight;
        }
        return success;
    }
    else
    {
        if (outHourRange != NULL)
            *outHourRange = _toFitAllEventsCache.cachedOutHourRange;
        if (outLayerHeight != NULL)
            *outLayerHeight = _toFitAllEventsCache.cachedOutLayerHeight;
        return YES;
    }
}


#pragma mark Private

- (NSUInteger)_indexForInsertionOfEventLayerWithEvent:(id)anEvent
{
    NSArray *events = [_sortedByStartDateEventLayers valueForKeyPath:_WLEventKey];
    NSUInteger i = [events indexOfObject:anEvent
                           inSortedRange:NSMakeRange(0, [_sortedByStartDateEventLayers count])
                                 options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                         usingComparator:^(CalEvent *aEvent, CalEvent *bEvent)
    {
        // Storage can represent multiple instances of the same event because it may come from different servers/services.
        // To make layout consistent we compare different parameters of the event.
        NSComparisonResult result = [[aEvent startDate] compare:[bEvent startDate]];
        if (result == NSOrderedSame)
            result = [[aEvent uid] compare:[bEvent uid]];
        if (result == NSOrderedSame)
            result = [[[aEvent calendar] uid] compare:[[bEvent calendar] uid]];
        return result;
    }];
    return i;
}

- (void)_buildEventsLayoutTreeIfNeeded
{
    [self _buildEventsLayoutTree];
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

    // Step 1: Divide layers into rows, where each element of the row intersects all other elements of the row itself or through it's siblings.
    {
        __block NSTreeNode *rowNode = nil;
        __block CGFloat rowTop = 0.0;
        __block CGFloat rowBottom = 0.0;
        [_sortedByStartDateEventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            WLSegment s = [l segmentOnTimeRuler:self.timeRuler];
            CGFloat layerTop = WLSegmentGetMinLocation(s);
            CGFloat layerBottom = WLSegmentGetMaxLocation(s);
            if (IS_LESS_CGFLOAT(layerTop, rowBottom))
            {
                rowBottom = fmax(rowBottom, layerBottom);
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
            while ([row count] > 0 && [[rowNode childNodes] count] < [self maximumNumberOfColumns])
            {
                WLCalendarEventLayer *topLayer = [row objectAtIndex:0];
                NSMutableArray *column = [NSMutableArray arrayWithObject:topLayer];
                NSTreeNode *columnNode = [NSTreeNode treeNodeWithRepresentedObject:column];
                [row removeObjectAtIndex:0];

                if ([row count] > 0)
                {
                    __block CGFloat columnBottom = WLSegmentGetMaxLocation([topLayer segmentOnTimeRuler:self.timeRuler]);
                    NSMutableIndexSet *placedLayers = [NSMutableIndexSet indexSet];
                    [row enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
                    {
                        WLSegment s = [l segmentOnTimeRuler:self.timeRuler];
                        CGFloat layerTop = WLSegmentGetMinLocation(s);
                        CGFloat layerBottom = WLSegmentGetMaxLocation(s);
                        if (IS_LESS_OR_EQ_CGFLOAT(columnBottom, layerTop))
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
                NSTreeNode *columnNode = [[rowNode childNodes] objectAtIndex:layerIdx % [self maximumNumberOfColumns]];
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
                    WLSegment leftSegment = [left segmentOnTimeRuler:self.timeRuler];
                    CGFloat leftTop = WLSegmentGetMinLocation(leftSegment);
                    CGFloat leftBottom = WLSegmentGetMaxLocation(leftSegment);
                    NSRange rightColumns = NSMakeRange(columnIdx + 1, [columnNodes count] - columnIdx - 1);
                    __block NSUInteger numberOfColumnsToSkip = 0;
                    [columnNodes enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rightColumns]
                                                   options:0
                                                usingBlock:^(NSTreeNode *rightColumnNode, NSUInteger rightColumnIdx, BOOL *stopRightColumn)
                    {

                        BOOL doesIntersectRightColumn = NO;
                        NSArray *rightEventLayers = [rightColumnNode representedObject];
                        for (WLCalendarEventLayer *right in rightEventLayers)
                        {
                            WLSegment rightSegment = [right segmentOnTimeRuler:self.timeRuler];
                            CGFloat rightTop = WLSegmentGetMinLocation(rightSegment);
                            CGFloat rightBottom = WLSegmentGetMaxLocation(rightSegment);
                            if (IS_LESS_CGFLOAT(leftTop, rightBottom) && IS_LESS_CGFLOAT(rightTop, leftBottom))
                            {
                                doesIntersectRightColumn = YES;
                                break;
                            }
                            else if (IS_LESS_CGFLOAT(leftBottom, rightTop))
                                break;
                        }
                        if (!doesIntersectRightColumn)
                            ++numberOfColumnsToSkip;
                        else
                            *stopRightColumn = YES;
                    }];
                    left.numberOfColumnsToSkip = numberOfColumnsToSkip;
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

    if ([_sortedByStartDateEventLayers count] == 0 || self.bounds.size.width == 0.0 || self.bounds.size.height == 0.0)
    return;

    [self _buildEventsLayoutTreeIfNeeded];

    static const CGFloat CornerRadius = 5.0;

    CGFloat lastHourY = [self.timeRuler locationForHour:[self.timeRuler hourRange].endHour];

    // Layout rows.
    for (NSTreeNode *rowNode in [_eventsLayoutTreeRootNode childNodes])
    {
        NSArray *columnNodes = [rowNode childNodes];
        NSUInteger numberOfColumns = [columnNodes count];
        CGFloat effectiveRowWidth = fdim(self.bounds.size.width, _XSpaceBetweenEvents * (numberOfColumns - 1));
        CGFloat baseColumnWidth = floor(fmax(effectiveRowWidth / numberOfColumns, [WLCalendarEventLayer minimumHumanVisibleWidth]));
        CGFloat extendedColumnWidth = baseColumnWidth + 1.0;
        NSUInteger numberOfExtendedColumns = (NSUInteger)fmod(effectiveRowWidth, (CGFloat)numberOfColumns);
        NSParameterAssert(numberOfExtendedColumns < numberOfColumns);

        BOOL shouldRoundCorners = numberOfColumns > 1;
        // Layout columns of the row.
        __block CGFloat x = CGRectGetMinX(self.bounds);
        [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stopColumn)
        {
            NSArray *eventLayers = [columnNode representedObject];
            CGFloat columnWidth = columnIdx < numberOfExtendedColumns ? extendedColumnWidth : baseColumnWidth;
            [eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
            {
                WLSegment s = [l segmentOnTimeRuler:self.timeRuler];
                CGFloat t = WLSegmentGetMinLocation(s);
                CGFloat b = WLSegmentGetMaxLocation(s);
                // If bottom of the event is equal or greater than Y of last hour, it's visually better when it matches bottom of the column.
                if (IS_LESS_OR_EQ_CGFLOAT(floor(lastHourY), ceil(b)))
                b = CGRectGetMaxY(self.bounds);

                CGFloat y = t;
                CGFloat width = columnWidth;
                NSUInteger numberOfColumnsToSkip = l.numberOfColumnsToSkip;
                if (numberOfColumnsToSkip > 0)
                {
                    NSUInteger numberOfBaseColumnsToSkip = 0;
                    NSUInteger numberOfExtendedColumnsToSkip = 0;
                    if ((columnIdx + numberOfColumnsToSkip) < numberOfExtendedColumns)
                    numberOfExtendedColumnsToSkip = numberOfColumnsToSkip;
                    else if (columnIdx > numberOfExtendedColumns)
                    numberOfBaseColumnsToSkip = numberOfExtendedColumns;
                    else
                    {
                        numberOfBaseColumnsToSkip = columnIdx + numberOfColumnsToSkip - numberOfExtendedColumns;
                        numberOfExtendedColumnsToSkip = numberOfColumnsToSkip - numberOfBaseColumnsToSkip;
                    }
                    width += (_XSpaceBetweenEvents + baseColumnWidth) * numberOfBaseColumnsToSkip;
                    width += (_XSpaceBetweenEvents + extendedColumnWidth) * numberOfExtendedColumnsToSkip;
                }
                CGFloat height = fmin(fdim(CGRectGetHeight(self.bounds), y), fdim(b, y));
                l.frame = CGRectIntegral(CGRectMake(x, y, width, height));

                if (shouldRoundCorners)
                l.cornerRadius = CornerRadius;
                else
                l.cornerRadius = 0.0;

                if (self.keepsTextOfEventsVisible)
                [l setNeedsDisplay];
            }];
            x += columnWidth + _XSpaceBetweenEvents;
        }];
    }
}

- (CGSize)preferredFrameSize
{
    return CGSizeMake([self preferredFrameWidth],
                      ceil([self.timeRuler originOffset] + [self.timeRuler lengthForHourRange:[self.timeRuler hourRange]] + [self extent]));
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
    WLHourRange h = [self.timeRuler hourRange];
    for (NSUInteger i = h.startHour, numberOfHours = WLHourRangeLength(h); i < numberOfHours; ++i)
    {
        CGFloat y = round(self.bounds.origin.y + [self.timeRuler locationForHour:i]);
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
    [_sortedByStartDateEventLayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (void)scrollRectToVisible:(CGRect)aRect
{
    [super scrollRectToVisible:aRect];
    [_sortedByStartDateEventLayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithString:[super description]];
    [description appendFormat:@"\n"];
    [[_eventsLayoutTreeRootNode childNodes] enumerateObjectsUsingBlock:^(NSTreeNode *rowNode, NSUInteger rowIdx, BOOL *stopRow) {
        NSLog(@"Row #%lu", (unsigned long)rowIdx);
        NSArray *columnNodes = [rowNode childNodes];
        [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stopColumn)
        {
            NSLog(@"\tColumn #%lu", (unsigned long)columnIdx);
            NSArray *eventLayers = [columnNode representedObject];
            [eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
            {
                NSLog(@"\t\t%p: %@", l, [l valueForKeyPath:[NSString stringWithFormat:@"%@.title", _WLEventKey]]);
            }];
        }];
        NSLog(@"\n");
    }];
    return description;
}

@end


@implementation WLCalendarEventLayer (WLCalendarDayEventsLayer)

+ (WLCalendarEventLayer *)dayEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    l.needsDisplayOnBoundsChange = YES;
    l.masksToBounds = YES;
    l.contentsGravity = kCAGravityBottom;
    l.anchorPoint = CGPointMake(0.0, 0.0);

#ifndef DEBUG_LAYERS
    l.contentsBackgroundOpacity = 0.45;
#endif

    return l;
}


#pragma mark Properties
@dynamic dayEvent;
@dynamic numberOfColumnsToSkip;
@dynamic hourRange;

- (void)setDayEvent:(id)newEvent
{
    [self setValue:newEvent forKey:_WLEventKey];

    self.name = [newEvent uid];
    self.title = [NSAttributedString WL_eventTitleWithString:[newEvent title]];
    self.location = [NSAttributedString WL_eventLocationWithString:[(CalEvent *)newEvent location]];
    self.numberOfColumnsToSkip = 0;

    NSObject<WLCalendarTimeRuler> *timeRuler = [(WLCalendarDayEventsLayer *)[self superlayer] timeRuler];
    NSParameterAssert([[timeRuler class] conformsToProtocol:@protocol(WLCalendarTimeRuler)]);

    WLHourRange h = WLHourRangeZero;
    NSDate *startDate = [newEvent startDate];
    h.startHour = [timeRuler hourForDate:startDate];
    NSDate *endDate = [newEvent endDate];
    h.endHour = [timeRuler hourForDate:endDate];
    if (h.endHour <= h.startHour && [endDate timeIntervalSinceDate:startDate] > 0.0)
    {
        // If event ends at start of next day.
        h.endHour = [timeRuler hourRange].endHour;
    }
    self.hourRange = h;

    NSColor *calendarColor = [[(CalEvent *)newEvent calendar] color];
    if (calendarColor == NULL || (id)calendarColor == [NSNull null])
        calendarColor = [NSColor WL_defaultCalendarColorIfFrameworkFails];
#ifdef DEBUG_LAYERS
    self.backgroundColor = [calendarColor WL_CGColor];
#else
    self.contentsBackgroundColor = [calendarColor WL_CGColor];
#endif
}

- (id)dayEvent
{
    return [self valueForKey:_WLEventKey];
}

- (void)setNumberOfColumnsToSkip:(NSUInteger)newNumberOfColumnsToSkip
{
    [self setValue:[NSNumber numberWithUnsignedInteger:newNumberOfColumnsToSkip] forKey:_WLNumberOfColumnsToSkipKey];
}

- (NSUInteger)numberOfColumnsToSkip
{
    return [[self valueForKey:_WLNumberOfColumnsToSkipKey] unsignedIntegerValue];
}

- (void)setHourRange:(WLHourRange)newHourRange
{
    [self setValue:[NSValue valueWithBytes:&newHourRange objCType:@encode(WLHourRange)] forKey:_WLHourRangeKey];
}

- (WLHourRange)hourRange
{
    WLHourRange r;
    [[self valueForKey:_WLHourRangeKey] getValue:&r];
    return r;
}


#pragma mark Methods

- (WLSegment)segmentOnTimeRuler:(NSObject <WLCalendarTimeRuler> *)aTimeRuler
{
    WLHourRange h = self.hourRange;
    CGFloat startLocation = [aTimeRuler locationForHour:h.startHour];
    CGFloat endLocation = [aTimeRuler locationForHour:h.endHour];
    CGFloat minimumHeight = [self minimumHumanVisibleHeight];
    if (IS_LESS_CGFLOAT(endLocation - startLocation, minimumHeight))
        endLocation = startLocation + minimumHeight;
    return (WLSegment){startLocation, endLocation - startLocation};
}

@end

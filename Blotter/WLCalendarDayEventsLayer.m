//
//  WLCalendarWeekdayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#include <tgmath.h>
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static NSString *const _WLEventKey = @"event";

static NSString* const _WLStartDateKeyPath = @"event.startDate";

static NSString* const _WLEndDateKeyPath = @"event.endDate";

static NSString* const _WLStartHourKey = @"startHour";

static NSString* const _WLNumberOfColumnsToSkipKey = @"skipColumns";


static const CGFloat _XSpaceBetweenEvents = 2.0;


#define IS_EQ_F(a, b) (BOOL)(fabs((b) - (a)) < (CGFLOAT_IS_DOUBLE ? DBL_EPSILON : FLT_EPSILON))

#define IS_LESS_OR_EQ_F(a, b) (BOOL)((a) <= (b) || IS_EQ_F(a, b))

#define IS_LESS_F(a, b) (BOOL)((a) < (b) && !IS_EQ_F(a, b))


@implementation WLCalendarDayEventsLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedByStartDateEventLayers = [[NSMutableArray alloc] init];
        _needsUpdateHourRangeOfEvents = YES;
        _needsUpdateToFitAllEventsCache = YES;
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

- (NSSet *)events
{
    return [NSSet setWithArray:[_sortedByStartDateEventLayers valueForKey:_WLEventKey]];
}

- (void)setEvents:(NSSet *)newEvents
{
    NSMutableArray *unusedSublayers = [_sortedByStartDateEventLayers mutableCopy];
    [_sortedByStartDateEventLayers removeAllObjects];
    for (id event in newEvents)
    {
        NSUInteger indexOfUsedLayer = [unusedSublayers indexOfObjectPassingTest:^BOOL(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop) {
            id layerEvent = [l valueForKey:_WLEventKey];
            return [layerEvent isEqual:event] || (
                                                  [[layerEvent uid] isEqual:[event uid]] &&
                                                  [[(CalCalendar *)[layerEvent calendar] uid] isEqual:[(CalCalendar *)[event calendar] uid]]
                                                  );
        }];
        WLCalendarEventLayer *layer = nil;
        if (indexOfUsedLayer != NSNotFound)
        {
            // Layer for the event already exist. Update it.
            layer = [unusedSublayers objectAtIndex:indexOfUsedLayer];
            [self _updateEventLayer:layer withEvent:event];
            [unusedSublayers removeObjectAtIndex:indexOfUsedLayer];
        }
        else
        {
            // Create new layer for the event.
            layer = [self _setupEventLayer];
            [self _updateEventLayer:layer withEvent:event];
            [self addSublayer:layer];
        }
        NSUInteger idxByStartDate = [self _indexForInsertionOfEventLayerWithEvent:event];
        [_sortedByStartDateEventLayers insertObject:layer atIndex:idxByStartDate];
    }

    // Later events should be always displayed on top of early layers.
    [_sortedByStartDateEventLayers enumerateObjectsUsingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop) {
        l.zPosition = idx;
    }];
    [unusedSublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [unusedSublayers release];

    _needsUpdateHourRangeOfEvents = YES;
    _needsUpdateToFitAllEventsCache = YES;
}

- (void)setKeepsTextOfEventsVisible:(BOOL)newKeepTextOfEventsVisible
{
    keepsTextOfEventsVisible = newKeepTextOfEventsVisible;
    [_sortedByStartDateEventLayers makeObjectsPerformSelector:@selector(setKeepTextVisible:)
                                                   withObject:[NSNumber numberWithBool:keepsTextOfEventsVisible]];
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

    if (_needsUpdateHourRangeOfEvents)
    {
        NSDate *start = [[_sortedByStartDateEventLayers objectAtIndex:0] valueForKeyPath:_WLStartDateKeyPath];
        NSDate *end = nil;
        for (WLCalendarEventLayer *e in _sortedByStartDateEventLayers)
            end = [[e valueForKeyPath:_WLEndDateKeyPath] laterDate:end];
        hourRangeOfEvents = WLHourRangeMake([self.timeRuler hourForDate:start], [self.timeRuler hourForDate:end]);
        if (hourRangeOfEvents.endHour <= hourRangeOfEvents.startHour && [end timeIntervalSinceDate:start] > 0)
        {
            // If event ends at start of next day.
            hourRangeOfEvents.endHour = [self.timeRuler hourRange].endHour;
        }
        _needsUpdateHourRangeOfEvents = NO;
    }
    return hourRangeOfEvents;
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
    for (WLCalendarEventLayer *e in _sortedByStartDateEventLayers)
    {
        CGRect yAndHeight = [self _yAndHeightOfEventLayer:e];
        extent = fmax(extent, fdim(CGRectGetMaxY(yAndHeight), availableHeight));
    }
    return extent;
}

- (BOOL)toFitAllEventsWithinLayerHeight:(CGFloat)aLayerHeight
                       startingWithHour:(CGFloat)aStartHour
                              hourRange:(out WLHourRange *)outHourRange
        shouldBePlacedWithinLayerHeight:(out CGFloat *)outLayerHeight;
{
    NSParameterAssert(aLayerHeight >= 0.0);

    WLHourRange hourRange = [self hourRangeOfEvents];
    if (WLHourRangeEqualToHourRange(hourRange, WLHourRangeZero))
        return NO;
    else if (outHourRange == NULL && outLayerHeight == NULL)
        return YES;

    NSParameterAssert(aStartHour <= hourRange.startHour);

    if (IS_EQ_F(aLayerHeight, 0.0))
    {
        if (outHourRange != NULL)
            *outHourRange = hourRange;
        if (outLayerHeight != NULL)
            *outLayerHeight = 0.0;
        return YES;
    }

    // According to tests, this method is called very often with the same parameters.
    // Caching the result of last call improves performance.
    if (_needsUpdateToFitAllEventsCache ||
        !IS_EQ_F(_toFitAllEventsCache.cachedLayerHeight, aLayerHeight) ||
        !IS_EQ_F(_toFitAllEventsCache.cachedStartHour, aStartHour))
    {
        hourRange.startHour = aStartHour;
        WLHourRange hourRangeOfEventsExceptBottommost = WLHourRangeZero;
        CGFloat availableLayerHeight = CGFLOAT_MAX;
        CGFloat heightOfHour = CGFLOAT_MAX;
        for (WLCalendarEventLayer *eventLayer in _sortedByStartDateEventLayers)
        {
            WLHourRange hourRangeOfEventsExceptCurrentEventLayer = WLHourRangeMake(hourRange.startHour,
                                                                                   [self _hourRangeOfEventLayer:eventLayer].startHour);
            CGFloat l = WLHourRangeLength(hourRangeOfEventsExceptCurrentEventLayer);
            if (l > 0.0)
            {
                CGFloat minHeightOfEventLayer = [eventLayer minimumHumanVisibleHeight];
                CGFloat currentAvailableLayerHeight = fdim(aLayerHeight, minHeightOfEventLayer);
                CGFloat currentHeightOfHour = currentAvailableLayerHeight / l;
                if (currentHeightOfHour < heightOfHour)
                {
                    hourRangeOfEventsExceptBottommost = hourRangeOfEventsExceptCurrentEventLayer;
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

- (WLCalendarEventLayer *)_setupEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    l.needsDisplayOnBoundsChange = YES;
    l.masksToBounds = YES;
    l.contentsGravity = kCAGravityBottom;
    l.anchorPoint = CGPointMake(0.0, 0.0);
    l.keepsTextVisible = self.keepsTextOfEventsVisible;
#ifndef DEBUG_LAYERS
    l.contentsBackgroundOpacity = 0.45;
#endif
    return l;
}

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(CalEvent *)anEvent
{
    aLayer.name = [anEvent uid];
    [aLayer setValue:anEvent forKey:_WLEventKey];
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

    [aLayer setValue:nil forKey:_WLNumberOfColumnsToSkipKey];
    [aLayer setValue:nil forKey:_WLStartHourKey];
#ifdef DEBUG_LAYERS
    aLayer.backgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#else
    aLayer.contentsBackgroundColor = [[(CalCalendar *)[anEvent calendar] color] WL_CGColor];
#endif
}

- (NSUInteger)_indexForInsertionOfEventLayerWithEvent:(id)anEvent
{
    NSArray *events = [_sortedByStartDateEventLayers valueForKeyPath:_WLEventKey];
    NSUInteger i = [events indexOfObject:anEvent
                           inSortedRange:NSMakeRange(0, [_sortedByStartDateEventLayers count])
                                 options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                         usingComparator:^(id aEvent, id bEvent)
    {
        // Storage can represent multiple instances of the same event because it may come from different servers/services.
        // To make layout consistent we compare different parameters of the event.
        NSComparisonResult result = [[aEvent startDate] compare:[bEvent startDate]];
        if (result == NSOrderedSame)
            result = [[aEvent uid] compare:[bEvent uid]];
        if (result == NSOrderedSame)
            result = [[(CalCalendar *)[aEvent calendar] uid] compare:[(CalCalendar *)[bEvent calendar] uid]];
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

    // Step 1: Divde layers into rows, where each element of the row intersects all other elements of the row itself or through it's siblings.
    {
        __block NSTreeNode *rowNode = nil;
        __block CGFloat rowTop = 0.0;
        __block CGFloat rowBottom = 0.0;
        [_sortedByStartDateEventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            CGRect yAndHeight = [self _yAndHeightOfEventLayer:l];
            CGFloat layerTop = CGRectGetMinY(yAndHeight);
            CGFloat layerBottom = CGRectGetMaxY(yAndHeight);
            if (IS_LESS_F(layerTop, rowBottom))
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
                    CGRect yAndHeight = [self _yAndHeightOfEventLayer:topLayer];
                    __block CGFloat columnBottom = CGRectGetMaxY(yAndHeight);
                    NSMutableIndexSet *placedLayers = [NSMutableIndexSet indexSet];
                    [row enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
                    {
                        CGRect yAndHeight = [self _yAndHeightOfEventLayer:l];
                        CGFloat layerTop = CGRectGetMinY(yAndHeight);
                        CGFloat layerBottom = CGRectGetMaxY(yAndHeight);
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
                    CGRect yAndHeight = [self _yAndHeightOfEventLayer:left];
                    CGFloat leftTop = CGRectGetMinY(yAndHeight);
                    CGFloat leftBottom = CGRectGetMaxY(yAndHeight);
                    NSRange rightColumns = NSMakeRange(columnIdx + 1, [columnNodes count] - columnIdx - 1);
                    __block NSUInteger numberOfColumnsToSkip = 0;
                    [columnNodes enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rightColumns]
                                                   options:0
                                                usingBlock:^(NSTreeNode *rightColumnNode, NSUInteger rightColumnIdx, BOOL *stopRightColumn)
                    {
                        BOOL doesIntersectRightColumn = NO;
                        for (WLCalendarEventLayer *right in [rightColumnNode representedObject])
                        {
                            CGRect yAndHeight = [self _yAndHeightOfEventLayer:right];
                            CGFloat rightTop = CGRectGetMinY(yAndHeight);
                            CGFloat rightBottom = CGRectGetMaxY(yAndHeight);
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

- (WLHourRange)_hourRangeOfEventLayer:(WLCalendarEventLayer *)aLayer
{
    WLHourRange h = WLHourRangeZero;
    NSDate *start = [aLayer valueForKeyPath:_WLStartDateKeyPath];
    h.startHour = [self.timeRuler hourForDate:start];
    NSDate *end = [aLayer valueForKeyPath:_WLEndDateKeyPath];
    h.endHour = [self.timeRuler hourForDate:end];
    if (h.endHour <= h.startHour && [end timeIntervalSinceDate:start] > 0.0)
    {
        // If event ends at start of next day.
        h.endHour = [self.timeRuler hourRange].endHour;
    }
    return h;
}

- (CGRect)_yAndHeightOfEventLayer:(WLCalendarEventLayer *)aLayer
{
    WLHourRange h = [self _hourRangeOfEventLayer:aLayer];
    CGFloat minY = [self.timeRuler locationForHour:h.startHour];
    CGFloat maxY = [self.timeRuler locationForHour:h.endHour];
    CGFloat minimumHeight = [aLayer minimumHumanVisibleHeight];
    if (IS_LESS_F(maxY - minY, minimumHeight))
        maxY = minY + minimumHeight;
    return CGRectMake(0.0,
                      minY,
                      0.0,
                      maxY - minY);
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
        CGFloat baseColumnWidth = floor(fmax(effectiveRowWidth / numberOfColumns,
                                             [WLCalendarEventLayer minimumHumanVisibleWidth]));
        CGFloat extendedColumnWidth = baseColumnWidth + 1.0;
        NSUInteger numberOfExtendedColumns = (NSUInteger)fmod(effectiveRowWidth, (CGFloat)numberOfColumns);
        NSParameterAssert(numberOfExtendedColumns < numberOfColumns);

        BOOL shouldRoundCorners = numberOfColumns > 1;
        // Layour columns of the row.
        __block CGFloat x = CGRectGetMinX(self.bounds);
        [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stopColumn)
        {
            NSArray *eventLayers = [columnNode representedObject];
            CGFloat columnWidth = columnIdx < numberOfExtendedColumns ? extendedColumnWidth : baseColumnWidth;
            [eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
            {
                CGRect yAndHeight = [self _yAndHeightOfEventLayer:l];
                CGFloat t = CGRectGetMinY(yAndHeight);
                CGFloat b = CGRectGetMaxY(yAndHeight);
                // If bottom of the event is equal or greater than Y of last hour, it's visually better when it matches bottom of the column.
                if (IS_LESS_OR_EQ_F(floor(lastHourY), ceil(b)))
                    b = CGRectGetMaxY(self.bounds);

                CGFloat y = t;
                CGFloat width = columnWidth;
                NSUInteger numberOfColumnsToSkip = [[l valueForKey:_WLNumberOfColumnsToSkipKey] unsignedIntegerValue];
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
                CGFloat height = fmin(CGRectGetHeight(self.bounds) - y, b - y);
                l.frame = CGRectMake(x, y, width, height);

                if (shouldRoundCorners)
                    l.cornerRadius = CornerRadius;
                else
                    l.cornerRadius = 0.0f;

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
                      ceilf([self.timeRuler originOffset] + [self.timeRuler lengthForHourRange:[self.timeRuler hourRange]] + [self extent]));
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
        CGFloat y = roundf(self.bounds.origin.y + [self.timeRuler locationForHour:i]);
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
        NSLog(@"Row #%lu", rowIdx);
        NSArray *columnNodes = [rowNode childNodes];
        [columnNodes enumerateObjectsUsingBlock:^(NSTreeNode *columnNode, NSUInteger columnIdx, BOOL *stopColumn)
         {
             NSLog(@"\tColumn #%lu", columnIdx);
             NSArray *eventLayers = [columnNode representedObject];
             [eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger layerIdx, BOOL *stopLayer)
              {
                  NSLog(@"\t\t%p: %@", l, [l valueForKeyPath:@"event.title"]);
              }];
         }];
        NSLog(@"\n");
    }];
    return description;
}

@end

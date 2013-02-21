//
//  WLCalendarWeekView.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLCalendarWeekView.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


// Must be unique!
// These strings may be used directly in the code, look through it if you are going to change values.
static NSString* const _WLRootLayerName = @"root";

static NSString* const _WLTimeRulerRootLayerName = @"timeRulerRoot";

static NSString* const _WLTimeRulerBackgroundLayerName = @"timeRulerBackground";

static NSString* const _WLTimeRulerScrollLayerName = @"timeRulerScroll";

static NSString* const _WLTimeRulerLayerName = @"timeRuler";

static NSString* const _WLColumnRootLayerName = @"weekdayEventsContent";

static NSString *const _WLAllDayBackgroundLayerName = @"weekdayEventsAllDayBackground";

static NSString* const _WLDayBackgroundLayerName = @"weekdayEventsBackground";

static NSString* const _WLAllDayLayerName = @"weekdayEventsAllDay";

static NSString* const _WLDayScrollLayerName = @"weekdayEventsScroll";

static NSString* const _WLDayLayerName = @"weekdayEvents";

static NSString* const _WLTimeIndicatorRootLayerName = @"timeIndicatorRoot";

static NSString* const _WLTimeIndicatorLayerName = @"timeIndicator";

static NSString* const _WLEventsRootLayerName = @"eventsRootLayer";


static NSString* const _WLColumnLayersKey = @"columnLayers";


static const CGFloat _WLXMarginBetweenTimeRulerAndColumns = 6.0;

static const CGFloat _WLYMarginBetweenAllDayAndDayPartsOfColumn = 8.0;

static const CGFloat _WLXMarginBetweenTimeRulerAndTimeRulerRoot = 5.0;

static const CGFloat _WLXMarginBetweenColumns = 6.0;

static const CGFloat _WLYColumnTitleFrameBottomOffset = 2.0;


@implementation WLCalendarWeekView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        heightOfAllDayPartOfColumn = 114.0;
        showsTimeIndicator = YES;
        showsAllDayEvents = YES;
        alwaysVisibleHourRange = WLHourRangeMake(9.0, 17.0);
        [self setNeedsUpdateHoursLengthAndLocation];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


#pragma mark Properties
@synthesize dataSource;
@synthesize showsAllDayEvents;
@synthesize heightOfAllDayPartOfColumn;
@synthesize showsTimeIndicator;
@synthesize fitsDayEvents;
@synthesize alwaysVisibleHourRange;

- (void)setShowsAllDayEvents:(BOOL)newShowsAllDayEvents
{
    if (newShowsAllDayEvents != showsAllDayEvents)
    {
        [self willChangeValueForKey:@"showsAllDayEvents"];
        showsAllDayEvents = newShowsAllDayEvents;
        [self didChangeValueForKey:@"showsAllDayEvents"];

        if ([self wantsLayer])
        {
            CALayer *rootLayer = [self layer];
            NSParameterAssert(rootLayer != nil);
            [rootLayer setNeedsLayout];
        }
    }
}

- (void)setHeightOfAllDayPartOfColumn:(CGFloat)newHeightOfAllDayPartOfColumn
{
    if (newHeightOfAllDayPartOfColumn != heightOfAllDayPartOfColumn)
    {
        [self willChangeValueForKey:@"heightOfAllDayPartOfColumn"];
        heightOfAllDayPartOfColumn = newHeightOfAllDayPartOfColumn;
        [self didChangeValueForKey:@"heightOfAllDayPartOfColumn"];

        if ([self wantsLayer] && self.showsAllDayEvents)
        {
            CALayer *rootLayer = [self layer];
            NSParameterAssert(rootLayer != nil);
            [rootLayer setNeedsLayout];
        }
    }
}

- (void)setShowsTimeIndicator:(BOOL)newShowTimeIndicator
{
    if (newShowTimeIndicator != showsTimeIndicator)
    {
        [self willChangeValueForKey:@"showsTimeIndicator"];
        showsTimeIndicator = newShowTimeIndicator;
        [self didChangeValueForKey:@"showsTimeIndicator"];

        [self timeIndicatorLayer].hidden = !showsTimeIndicator;
    }
}

- (void)setFitsDayEvents:(BOOL)newFitDayEvents
{
    if (newFitDayEvents != fitsDayEvents)
    {
        [self willChangeValueForKey:@"fitsDayEvents"];
        fitsDayEvents = newFitDayEvents;
        [self didChangeValueForKey:@"fitsDayEvents"];

        [self needsUpdateHoursLengthAndLocation];
        if ([self wantsLayer])
        {
            NSArray *dayLayers = [self dayLayers];
            NSParameterAssert(dayLayers != nil);
            WLCalendarTimeRulerLayer *timeRulerLayer = [self timeRulerLayer];
            NSParameterAssert(timeRulerLayer != nil);
            if (fitsDayEvents)
            {
                [dayLayers makeObjectsPerformSelector:@selector(setKeepsTextOfEventsVisible:) withObject:[NSNumber numberWithBool:NO]];
                timeRulerLayer.onlyCompletelyVisibleMarkersShown = YES;
            }
            else
            {
                [dayLayers makeObjectsPerformSelector:@selector(setKeepsTextOfEventsVisible:) withObject:[NSNumber numberWithBool:YES]];
                timeRulerLayer.onlyCompletelyVisibleMarkersShown = NO;
            }

            CAScrollLayer *timeRulerScrollLayer = [self timeRulerScrollLayer];
            NSParameterAssert(timeRulerScrollLayer != nil);
            [timeRulerScrollLayer setNeedsLayout];

            NSArray *dayScrollLayers = [self dayScrollLayers];
            NSParameterAssert(dayScrollLayers != nil);
            [dayScrollLayers makeObjectsPerformSelector:@selector(setNeedsLayout)];

            CALayer *timeIndicatorRootLayer = [self timeIndicatorRootLayer];
            NSParameterAssert(timeIndicatorRootLayer != nil);
            [timeIndicatorRootLayer setNeedsLayout];
        }
    }
}

- (void)setAlwaysVisibleHourRange:(WLHourRange)newHourRange
{
    if (!WLHourRangeEqualToHourRange(newHourRange, alwaysVisibleHourRange))
    {
        [self willChangeValueForKey:@"alwaysVisibleHourRange"];
        alwaysVisibleHourRange = newHourRange;
        [self didChangeValueForKey:@"alwaysVisibleHourRange"];

        [self needsUpdateHoursLengthAndLocation];
        if ([self wantsLayer] && self.fitsDayEvents)
        {
            CAScrollLayer *timeRulerScrollLayer = [self timeRulerScrollLayer];
            NSParameterAssert(timeRulerScrollLayer != nil);
            [timeRulerScrollLayer setNeedsLayout];

            NSArray *dayScrollLayers = [self dayScrollLayers];
            NSParameterAssert(dayScrollLayers != nil);
            [dayScrollLayers makeObjectsPerformSelector:@selector(setNeedsLayout)];

            CALayer *timeIndicatorRootLayer = [self timeIndicatorRootLayer];
            NSParameterAssert(timeIndicatorRootLayer != nil);
            [timeIndicatorRootLayer setNeedsLayout];
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversOfShowsAllDayEvents
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfHeightOfAllDayPartOfColumn
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfShowsTimeIndicator
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfFitsDayEvents
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfAlwaysVisibleHourRange
{
    return NO;
}


#pragma mark Methods

- (void)reloadDataAnimated:(BOOL)isAnimated
{
    NSParameterAssert([self wantsLayer]);

    [self stopAnimations];

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    NSUInteger newNumberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    NSMutableArray *columnRootLayers = [self columnRootLayers];
    NSParameterAssert(columnRootLayers != nil);
    NSUInteger currentNumberOfColumns = [self numberOfColumns];
    CALayer *eventsRootLayer = [self eventsRootLayer];
    NSParameterAssert(eventsRootLayer != nil);
    if (currentNumberOfColumns < newNumberOfColumns)
    {
        for (NSUInteger i = 0, size = newNumberOfColumns - currentNumberOfColumns; i < size; ++i)
        {
            CALayer *c = [self setupColumnRootLayer];
            [columnRootLayers addObject:c];
            [eventsRootLayer addSublayer:c];
        }
    }
    else if (currentNumberOfColumns > newNumberOfColumns)
    {
        for (NSUInteger i = 0, size = currentNumberOfColumns - newNumberOfColumns; i < size; ++i)
        {
            CALayer *column = [columnRootLayers lastObject];
            [column removeFromSuperlayer];
            [columnRootLayers removeLastObject];
        }
    }
    [self setColumnRootLayers:columnRootLayers];
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newNumberOfColumns)] animated:isAnimated];
    WLCalendarTimeRulerLayer *timeRulerLayer = [self timeRulerLayer];
    NSParameterAssert(timeRulerLayer != nil);
    timeRulerLayer.markers = [self _timeRulerMarkers];

    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    [rootLayer setNeedsLayout];
    [CATransaction commit];
}

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated
{
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    _hour = aHour;

    if ([self wantsLayer])
    {
        CALayer *timeIndicatorRootLayer = [self timeIndicatorRootLayer];
        NSParameterAssert(timeIndicatorRootLayer != nil);
        [timeIndicatorRootLayer setNeedsLayout];
        if (!self.fitsDayEvents)
        {
            CAScrollLayer *timeRulerScrollLayer = [self timeRulerScrollLayer];
            NSParameterAssert(timeRulerScrollLayer != nil);
            [timeRulerScrollLayer setNeedsLayout];

            NSArray *dayScrollLayers = [self dayScrollLayers];
            NSParameterAssert(dayScrollLayers != nil);
            [dayScrollLayers makeObjectsPerformSelector:@selector(setNeedsLayout)];
        }
    }
    [CATransaction commit];
}

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated
{
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    if ([self.dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [self.dataSource weekView:self
                   willAskForData:WLCalendarWeekViewEventsDataUnit
              forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
         [self _updateEventsOfColumnAtIndex:idx];
    }];
    if ([self.dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [self.dataSource weekViewDidAskForData:self];

    if (self.fitsDayEvents)
    {
        NSArray *allDayLayers = [self allDayLayers];
        NSParameterAssert(allDayLayers != nil);
        [[allDayLayers objectsAtIndexes:anIndexSet] makeObjectsPerformSelector:@selector(setNeedsLayout)];

        NSArray *dayScrollLayers = [self dayScrollLayers];
        NSParameterAssert(dayScrollLayers != nil);
        [dayScrollLayers makeObjectsPerformSelector:@selector(setNeedsLayout)];

        CAScrollLayer *timeRulerScrollLayer = [self timeRulerScrollLayer];
        NSParameterAssert(timeRulerScrollLayer != nil);
        [timeRulerScrollLayer setNeedsLayout];

        CALayer *timeIndicatorRootLayer = [self timeIndicatorRootLayer];
        NSParameterAssert(timeIndicatorRootLayer != nil);
        [timeIndicatorRootLayer setNeedsLayout];
    }
    else
    {
        NSArray *allDayLayers = [self allDayLayers];
        NSParameterAssert(allDayLayers != nil);
        [[allDayLayers objectsAtIndexes:anIndexSet] makeObjectsPerformSelector:@selector(setNeedsLayout)];

        NSArray *dayLayers = [self dayLayers];
        NSParameterAssert(dayLayers != nil);
        [[dayLayers objectsAtIndexes:anIndexSet] makeObjectsPerformSelector:@selector(setNeedsLayout)];
    }
    [CATransaction commit];
}

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated
{
    if (![self.dataSource respondsToSelector:@selector(weekView:titleForColumnAtIndex:)])
        return;

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    if ([self.dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [self.dataSource weekView:self
                   willAskForData:WLCalendarWeekViewTitleDataUnit
              forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
         [self _updateTitleOfColumnAtIndex:idx];
    }];
    if ([self.dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [self.dataSource weekViewDidAskForData:self];

    WLBlockLayer *timeRulerBackgroundLayer = [self timeRulerBackgroundLayer];
    NSParameterAssert(timeRulerBackgroundLayer != nil);
    [timeRulerBackgroundLayer setNeedsLayout];

    NSArray *dayBackgroundLayers = [self dayBackgroundLayers];
    NSParameterAssert(dayBackgroundLayers != nil);
    [dayBackgroundLayers makeObjectsPerformSelector:@selector(setNeedsLayout)];

    CALayer *timeIndicatorRootLayer = [self timeIndicatorRootLayer];
    NSParameterAssert(timeIndicatorRootLayer != nil);
    [timeIndicatorRootLayer setNeedsLayout];
    [CATransaction commit];
}

- (void)updateHighlightsTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated
{
    if (![self.dataSource respondsToSelector:@selector(weekView:highlightsTitleForColumnAtIndex:)])
        return;

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    if ([self.dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [self.dataSource weekView:self
                   willAskForData:WLCalendarWeekViewTitleDataUnit
              forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
         [self _updateHighlightsTitleOfColumnAtIndex:idx];
    }];
    if ([self.dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [self.dataSource weekViewDidAskForData:self];

    WLBlockLayer *timeRulerBackgroundLayer = [self timeRulerBackgroundLayer];
    NSParameterAssert(timeRulerBackgroundLayer != nil);
    [timeRulerBackgroundLayer setNeedsLayout];

    NSArray *dayBackgroundLayers = [self dayBackgroundLayers];
    NSParameterAssert(dayBackgroundLayers != nil);
    [dayBackgroundLayers makeObjectsPerformSelector:@selector(setNeedsLayout)];

    CALayer *timeIndicatorRootLayer = [self timeIndicatorRootLayer];
    NSParameterAssert(timeIndicatorRootLayer != nil);
    [timeIndicatorRootLayer setNeedsLayout];
    [CATransaction commit];
}

- (void)updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;
{
    if (![self.dataSource respondsToSelector:@selector(weekView:colorForColumnAtIndex:)])
        return;

//    [CATransaction begin];
//    [CATransaction setDisableActions:!isAnimated];
//    if ([dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
//    {
//        [dataSource weekView:self
//              willAskForData:WLCalendarWeekViewColorDataUnit
//         forColumnsAtIndexes:anIndexSet];
//    }
//    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
//    {
//         [self _updateColorOfColumnAtIndex:idx];
//    }];
//    if ([dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
//        [dataSource weekViewDidAskForData:self];
//    [CATransaction commit];
}

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated
{
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    if ([self.dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        NSUInteger data = WLCalendarWeekViewEventsDataUnit;
        if ([self.dataSource respondsToSelector:@selector(weekView:titleForColumnAtIndex:)])
            data |= WLCalendarWeekViewTitleDataUnit;
        if ([self.dataSource respondsToSelector:@selector(weekView:highlightsTitleForColumnAtIndex:)])
            data |= WLCalendarWeekViewHighlightsTitleDataUnit;
        if ([self.dataSource respondsToSelector:@selector(weekView:colorForColumnAtIndex:)])
            data |= WLCalendarWeekViewColorDataUnit;
        [dataSource weekView:self
              willAskForData:data
         forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
     {
         [self _updateEventsOfColumnAtIndex:idx];
         if ([self.dataSource respondsToSelector:@selector(weekView:titleForColumnAtIndex:)])
             [self _updateTitleOfColumnAtIndex:idx];
         if ([self.dataSource respondsToSelector:@selector(weekView:highlightsTitleForColumnAtIndex:)])
             [self _updateHighlightsTitleOfColumnAtIndex:idx];
         if ([self.dataSource respondsToSelector:@selector(weekView:colorForColumnAtIndex:)])
             [self _updateColorOfColumnAtIndex:idx];
     }];
    if ([self.dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [self.dataSource weekViewDidAskForData:self];

    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    [rootLayer setNeedsLayout];
    [CATransaction commit];
}

- (void)showDays:(NSUInteger)aNumberOfDaysToShow
        hideDays:(NSUInteger)aNumberOfDaysToHide
       direction:(WLDayAppearanceDirection)aDirection
        animated:(BOOL)isAnimated
{
    NSUInteger oldNumberOfColumns = [self numberOfColumns];
    NSParameterAssert(aNumberOfDaysToHide <= oldNumberOfColumns);
    NSParameterAssert(oldNumberOfColumns + aNumberOfDaysToShow - aNumberOfDaysToHide == [self.dataSource numberOfColumnsInWeekView:self]);
    if ((aNumberOfDaysToShow == 0 && aNumberOfDaysToHide == 0) ||
        (aNumberOfDaysToShow == 0 && oldNumberOfColumns == 0))
    {
        return;
    }
    ++_numberOfActiveShowDaysTransactions;
    NSUInteger newNumberOfColumns = oldNumberOfColumns - aNumberOfDaysToHide + aNumberOfDaysToShow;

    /*
     Problem: since we want flow animation, when showing/hiding/moving columns we have to rely on current positions and current number of layers.
     This message can be received in the middle of animation and we have to update animations and end state of columns.

     Each receive of this message produces 2 groups of columns: h(iding)-columns and m(oving)-columns.
     h-columns will be removed from superlayer at the end of transaction.

     Initial layout:
     |                        |
     |---+  +---+  +---+  +---|
     |t  |  |t  |  |t  |  |t  | — type of column
     |   |  |   |  |   |  |   |
     |   |  |   |  |   |  |   |
     |   |  |   |  |   |  |   |
     |   |  |   |  |   |  |   |
     |   |  |   |  |   |  |   |
     |10 |  |11 |  |12 |  |13 | — "monthday" of column
     |---+  +---+  +---+  +---|
     |                        |



     Message was received with parameters:
     aNumberOfDaysToShow = 2
     aNumberOfDaysToHide = 2
     aDirection = WLRightToLeftDirection
     isAnimated = YES
     Assume that 3/4 of animation duration did pass:
              |                           |
     +---+  +-|-+  +---+  +---+  +---+  +-|-+
     |h  |  |h| |  |m  |  |m  |  |m  |  |m| |
     |   |  | | |  |   |  |   |  |   |  | | |
     |   |  | | |  |   |  |   |  |   |  | | |
     |   |  | | |  |   |  |   |  |   |  | | |
     |   |  | | |  |   |  |   |  |   |  | | |
     |   |  | | |  |   |  |   |  |   |  | | |
     |10 |  |11 |  |12 |  |13 |  |14 |  |15 |
     +---+  +-|-+  +---+  +---+  +---+  +-|-+
              |                           |
     first two columns become h-columns
     two m-columns were appended



     Then message was received with parameters:
     aNumberOfDaysToShow = 3
     aNumberOfDaysToHide = 3
     aDirection = WLLeftToRightDirection
     isAnimated = YES
                     |                           |
     +---+  +---+  +-|-+  +---+  +---+  +---+  +-|-+
     |m  |  |m  |  |m| |  |m  |  |h  |  |h  |  |h| |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |9  |  |10 |  |11 |  |12 |  |13 |  |14 |  |15 |
     +---+  +---+  +-|-+  +---+  +---+  +---+  +-|-+
                     |                           |
     one m-column was inserted at index 0
     both h-columns become m-columns
     last 3 m-columns become h-columns



     Then method was called with parameters:
     aNumberOfDaysToShow = 1
     aNumberOfDaysToHide = 1
     aDirection = WLRightToLeftDirection
     isAnimated = YES
                     |                           |
     +---+  +---+  +-|-+  +---+  +---+  +---+  +-|-+
     |h  |  |m  |  |m| |  |m  |  |m  |  |h  |  |h| |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |   |  |   |  | | |  |   |  |   |  |   |  | | |
     |9  |  |10 |  |11 |  |12 |  |13 |  |14 |  |15 |
     +---+  +---+  +-|-+  +---+  +---+  +---+  +-|-+
                     |                           |
    first m-column becomes h-column
    first h-column becomes m-column
    Even if WLRightToLeftDirection is specified, the columns still go left-to-right


     As stated above, h-layers will be removed from superlayer at the end of transaction. Since h-column can become m-column, we have to prevent removing. To do this, we assign number of interested transactions to the layer. When this value reaches 0, it's safe to remove column at the end of current transaction.
     */

    NSMutableArray *columnRootLayers = [[[self columnRootLayers] retain] autorelease];
    NSParameterAssert(columnRootLayers != nil);
    CALayer *eventsRootLayer = [self eventsRootLayer];
    NSParameterAssert(eventsRootLayer != nil);

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    // Ensure you retain all sublayers before changing its properties or adding animations.
    __block WLCalendarWeekView *selfBlock = self;
    [CATransaction setCompletionBlock:^{
        NSParameterAssert(selfBlock->_numberOfActiveShowDaysTransactions);
        selfBlock->_numberOfActiveShowDaysTransactions -= 1;
        if (selfBlock->_numberOfActiveShowDaysTransactions == 0)
        {
            [CATransaction setDisableActions:YES];
            NSMutableArray *blockColumnRootLayers = [selfBlock columnRootLayers];
            NSParameterAssert(blockColumnRootLayers != nil);
            CALayer *blockEventsRootLayer = [selfBlock eventsRootLayer];
            NSParameterAssert(blockEventsRootLayer != nil);
            if ([blockColumnRootLayers count] > 0)
            {
                NSUInteger indexOfFirstColumnRootLayer = [blockEventsRootLayer.sublayers indexOfObjectIdenticalTo:[blockColumnRootLayers objectAtIndex:0]];
                NSParameterAssert(indexOfFirstColumnRootLayer != NSNotFound);
                NSRange rangeOfColumnRootLayers = NSMakeRange(indexOfFirstColumnRootLayer, [blockColumnRootLayers count]);
                NSRange rangeOfLeftHidingColumns = NSMakeRange(0, rangeOfColumnRootLayers.location);
                NSRange rangeOfRightHidingColumns = NSMakeRange(NSMaxRange(rangeOfColumnRootLayers), [blockEventsRootLayer.sublayers count] - NSMaxRange(rangeOfColumnRootLayers));
                NSArray *hidingColumns = [blockEventsRootLayer.sublayers subarrayWithRange:rangeOfLeftHidingColumns];
                hidingColumns = [hidingColumns arrayByAddingObjectsFromArray:[blockEventsRootLayer.sublayers subarrayWithRange:rangeOfRightHidingColumns]];
                [hidingColumns makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
            }
            else
                [blockEventsRootLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        }
    }];

    NSUInteger indexOfFirstColumnRootLayer = [eventsRootLayer.sublayers indexOfObjectIdenticalTo:[columnRootLayers objectAtIndex:0]];
    NSParameterAssert(indexOfFirstColumnRootLayer != NSNotFound);
    __block NSRange rangeOfColumnRootLayers = NSMakeRange(indexOfFirstColumnRootLayer, oldNumberOfColumns);

    NSMutableArray *toFrames = [NSMutableArray arrayWithArray:[self framesForNumberOfColumns:newNumberOfColumns]];
    NSParameterAssert([toFrames count] == newNumberOfColumns);

    // Insert new columns if number of sublayers cannot fit aNumberOfDaysToShow.
    __block NSRange rangeOfInsertedColumns = NSMakeRange(NSNotFound, 0);
    [CATransaction WL_performWithDisabledActions:^{
        switch (aDirection) {
            case WLLeftToRightDirection:
            {
                if (rangeOfColumnRootLayers.location < aNumberOfDaysToShow)
                {
                    CGFloat maxXOfLayer = CGFLOAT_MAX;
                    if ([eventsRootLayer.sublayers count] > 0)
                    {
                        CALayer *leftmostLayer = [eventsRootLayer.sublayers objectAtIndex:0];
                        maxXOfLayer = CGRectGetMinX([(CALayer *)[leftmostLayer presentationLayer] frame]) - _WLXMarginBetweenColumns;
                    }
                    else
                        maxXOfLayer = CGRectGetMinX(eventsRootLayer.bounds) + _WLXMarginBetweenTimeRulerAndColumns - _WLXMarginBetweenColumns;
                    NSUInteger numberOfColumnsToInsert = aNumberOfDaysToShow - rangeOfColumnRootLayers.location;
                    for (NSUInteger i = numberOfColumnsToInsert; i > 0; --i)
                    {
                        CALayer *c = [self setupColumnRootLayer];
                        CGRect toFrame = NSRectToCGRect([[toFrames objectAtIndex:i - 1] rectValue]);
                        c.frame = CGRectMake(maxXOfLayer - CGRectGetWidth(toFrame),
                                             CGRectGetMinY(toFrame),
                                             CGRectGetWidth(toFrame),
                                             CGRectGetHeight(toFrame));
                        [eventsRootLayer insertSublayer:c atIndex:0];
                        maxXOfLayer -= _WLXMarginBetweenColumns + CGRectGetWidth(toFrame);
                    }
                    rangeOfInsertedColumns = NSMakeRange(0, numberOfColumnsToInsert);
                    rangeOfColumnRootLayers.location = 0;
                }
                else
                    rangeOfColumnRootLayers.location -= aNumberOfDaysToShow;
                rangeOfColumnRootLayers.length += (NSInteger)aNumberOfDaysToShow - aNumberOfDaysToHide;
                break;
            }
            case WLRightToLeftDirection:
            {
                if ([eventsRootLayer.sublayers count] - NSMaxRange(rangeOfColumnRootLayers) < aNumberOfDaysToShow)
                {
                    CGFloat minXOfLayer = CGFLOAT_MAX;
                    if ([eventsRootLayer.sublayers count] > 0)
                    {
                        CALayer *rightmostLayer = [eventsRootLayer.sublayers lastObject];
                        minXOfLayer = CGRectGetMaxX([(CALayer *)[rightmostLayer presentationLayer] frame]) + _WLXMarginBetweenColumns;
                    }
                    else
                        minXOfLayer = CGRectGetMaxX(eventsRootLayer.bounds) + _WLXMarginBetweenColumns;
                    NSUInteger numberOfColumnsToInsert = aNumberOfDaysToShow - ([eventsRootLayer.sublayers count] - NSMaxRange(rangeOfColumnRootLayers));
                    for (NSUInteger i = 0; i < numberOfColumnsToInsert; ++i)
                    {
                        CALayer *c = [self setupColumnRootLayer];
                        CGRect toFrame = NSRectToCGRect([[toFrames objectAtIndex:[toFrames count] - numberOfColumnsToInsert + i] rectValue]);
                        c.frame = CGRectMake(minXOfLayer,
                                             CGRectGetMinY(toFrame),
                                             CGRectGetWidth(toFrame),
                                             CGRectGetHeight(toFrame));
                        [eventsRootLayer addSublayer:c];
                        minXOfLayer += _WLXMarginBetweenColumns + CGRectGetWidth(toFrame);
                    }
                    rangeOfInsertedColumns = NSMakeRange([eventsRootLayer.sublayers count] - numberOfColumnsToInsert, numberOfColumnsToInsert);
                }
                rangeOfColumnRootLayers.location += aNumberOfDaysToHide;
                rangeOfColumnRootLayers.length += (NSInteger)aNumberOfDaysToShow - aNumberOfDaysToHide;
                break;
            }
        }
    }];

    NSParameterAssert(rangeOfInsertedColumns.location == NSNotFound || NSMaxRange(rangeOfInsertedColumns) <= [eventsRootLayer.sublayers count]);
    NSParameterAssert(NSMaxRange(rangeOfColumnRootLayers) <= [eventsRootLayer.sublayers count]);
    columnRootLayers = [NSMutableArray arrayWithArray:[eventsRootLayer.sublayers subarrayWithRange:rangeOfColumnRootLayers]];
    [self setColumnRootLayers:columnRootLayers];

    [CATransaction WL_performWithDisabledActions:^{
        NSRange rangeOfColumnsToUpdate = NSMakeRange(NSNotFound, 0);
        switch (aDirection)
        {
            case WLLeftToRightDirection:
                rangeOfColumnsToUpdate = NSMakeRange(0, aNumberOfDaysToShow);
                break;
            case WLRightToLeftDirection:
                rangeOfColumnsToUpdate = NSMakeRange(newNumberOfColumns - aNumberOfDaysToShow, aNumberOfDaysToShow);
                break;
        }
        [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeOfColumnsToUpdate] animated:NO];
    }];

    NSRange rangeOfLeftHidingColumns = NSMakeRange(0, rangeOfColumnRootLayers.location);
    NSParameterAssert(NSMaxRange(rangeOfLeftHidingColumns) <= [eventsRootLayer.sublayers count] || rangeOfLeftHidingColumns.length == 0);
    NSRange rangeOfRightHidingColumns = NSMakeRange(NSMaxRange(rangeOfColumnRootLayers), [eventsRootLayer.sublayers count] - NSMaxRange(rangeOfColumnRootLayers));
    NSParameterAssert(NSMaxRange(rangeOfRightHidingColumns) <= [eventsRootLayer.sublayers count] || rangeOfRightHidingColumns.length == 0);

    // Calculate toFrames for hiding columns.
    if (rangeOfLeftHidingColumns.length > 0)
    {
        __block CGFloat maxXOfLayer = CGFLOAT_MAX;
        if ([toFrames count] > 0)
            maxXOfLayer = NSMinX([[toFrames objectAtIndex:0] rectValue]) - _WLXMarginBetweenColumns;
        else
            maxXOfLayer = CGRectGetMinX(eventsRootLayer.bounds) + _WLXMarginBetweenTimeRulerAndColumns - _WLXMarginBetweenColumns;
        [eventsRootLayer.sublayers enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeOfLeftHidingColumns]
                                                     options:NSEnumerationReverse
                                                  usingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop)
         {
             CGRect toFrame = CGRectMake(maxXOfLayer - CGRectGetWidth(l.frame),
                                         CGRectGetMinY(l.frame),
                                         CGRectGetWidth(l.bounds),
                                         CGRectGetHeight(l.bounds));
             [toFrames insertObject:[NSValue valueWithRect:NSRectFromCGRect(toFrame)] atIndex:0];
             maxXOfLayer -= _WLXMarginBetweenColumns + CGRectGetWidth(toFrame);
         }];
    }
    if (rangeOfRightHidingColumns.length > 0)
    {
        __block CGFloat minXOfLayer = CGFLOAT_MAX;
        if ([toFrames count] > 0)
            minXOfLayer = NSMaxX([[toFrames lastObject] rectValue]) + _WLXMarginBetweenColumns;
        else
            minXOfLayer = CGRectGetMaxX(eventsRootLayer.bounds) + _WLXMarginBetweenColumns;
        [eventsRootLayer.sublayers enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeOfRightHidingColumns]
                                                     options:0
                                                  usingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop)
         {
             CGRect toFrame = CGRectMake(minXOfLayer,
                                         CGRectGetMinY(l.frame),
                                         CGRectGetWidth(l.bounds),
                                         CGRectGetHeight(l.bounds));
             [toFrames addObject:[NSValue valueWithRect:NSRectFromCGRect(toFrame)]];
             minXOfLayer += _WLXMarginBetweenColumns + CGRectGetWidth(toFrame);
         }];
    }
    NSParameterAssert([toFrames count] == [eventsRootLayer.sublayers count]);

    // Add animations.
    [eventsRootLayer.sublayers enumerateObjectsUsingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop)
    {
        CGRect toFrame = NSRectToCGRect([[toFrames objectAtIndex:idx] rectValue]);
        if (isAnimated)
        {
            CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
            boundsAnimation.fromValue = [NSValue valueWithRect:NSRectFromCGRect([(CALayer *)[l presentationLayer] bounds])];
            boundsAnimation.toValue = [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0,
                                                                                         0.0,
                                                                                         CGRectGetWidth(toFrame),
                                                                                         CGRectGetHeight(toFrame)))];
            CABasicAnimation *positionXAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            positionXAnimation.fromValue = [NSNumber numberWithDouble:CGRectGetMinX([(CALayer *)[l presentationLayer] frame])];
            positionXAnimation.toValue = [NSNumber numberWithDouble:CGRectGetMinX(toFrame)];
            if (idx >= rangeOfInsertedColumns.location && idx < NSMaxRange(rangeOfInsertedColumns))
            {
                CGRect fromFrame = [l frame];
                boundsAnimation.fromValue = [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0,
                                                                                               0.0,
                                                                                               CGRectGetWidth(fromFrame),
                                                                                               CGRectGetHeight(fromFrame)))];
                positionXAnimation.fromValue = [NSNumber numberWithDouble:CGRectGetMinX(fromFrame)];
            }
            CAAnimationGroup *g = [CAAnimationGroup animation];
            g.animations = [NSArray arrayWithObjects:boundsAnimation, positionXAnimation, nil];
            [l addAnimation:g forKey:@"boundsAndPositionX"];
        }
        l.frame = toFrame;
    }];

    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    [rootLayer setNeedsLayout];
    [CATransaction commit];
}

- (NSUInteger)numberOfColumns
{
    return [[self columnRootLayers] count];
}

- (WLHourRange)hourRangeOfEvents
{
    NSParameterAssert([self wantsLayer]);
    WLHourRange r = WLHourRangeInvalid;
    for (WLCalendarDayEventsLayer *l in [self dayLayers])
    {
        WLHourRange columnHourRange = [l hourRangeOfEvents];
        if (!WLHourRangeEqualToHourRange(columnHourRange, WLHourRangeZero))
        {
            r.startHour = fmin(r.startHour, columnHourRange.startHour);
            r.endHour = fmax(r.endHour, columnHourRange.endHour);
        }
    }
    r.startHour = floor(r.startHour);
    r.endHour = ceil(r.endHour);
    return r;
}

- (WLHourRange)visibleHourRange
{
    WLHourRange visibleHourRange = [self hourRangeOfEvents];
    visibleHourRange.startHour = fmin(visibleHourRange.startHour, self.alwaysVisibleHourRange.startHour);
    visibleHourRange.endHour = fmax(visibleHourRange.endHour, self.alwaysVisibleHourRange.endHour);
    return visibleHourRange;
}

- (BOOL)needsUpdateHoursLengthAndLocation
{
    return needsUpdateHoursLengthAndPositions;
}

- (void)setNeedsUpdateHoursLengthAndLocation
{
    needsUpdateHoursLengthAndPositions = YES;
}

- (void)updateHoursLengthAndLocationIfNeeded
{
    if ([self needsUpdateHoursLengthAndLocation])
    {
        static const CGFloat DefaultHeightOfHour = 40.0;

        WLHourRange timeRulerHourRange = [self hourRange];

        CGFloat availableHeight = fdim([self visibleHeightOfTimeRuler], [self originOffset]);
        if (self.fitsDayEvents)
        {
            static const double DoubleValue = 0.0;
            memset_pattern8(_lengthOfHours, &DoubleValue, 8 * sizeof(_lengthOfHours) / sizeof(CGFloat));
            memset_pattern8(_locationOfHours, &DoubleValue, 8 * sizeof(_locationOfHours) / sizeof(CGFloat));

            if (fabs(availableHeight) < CGFLOAT_EPSILON)
                return;

            WLHourRange fixedVisibleHourRange = [self visibleHourRange];
            if (WLHourRangeLength(fixedVisibleHourRange) == 0.0)
                return;

            NSArray *dayLayers = [self dayLayers];
            NSParameterAssert(dayLayers != nil);
            CGFloat effectiveAvailableHeight = availableHeight;
            WLHourRange effectiveVisibleHourRange = fixedVisibleHourRange;
            CGFloat effectiveHeightOfHour = availableHeight / WLHourRangeLength(fixedVisibleHourRange);
            for (WLCalendarDayEventsLayer *l in dayLayers)
            {
                WLHourRange r = WLHourRangeZero;
                CGFloat h = 0.0;
                BOOL success = [l toFitAllEventsWithinLayerHeight:availableHeight
                                                 startingWithHour:fixedVisibleHourRange.startHour
                                                        hourRange:&r
                                  shouldBePlacedWithinLayerHeight:&h];
                if (success)
                {
                    CGFloat newHeightOfHour = h / WLHourRangeLength(r);
                    if (newHeightOfHour < effectiveHeightOfHour)
                    {
                        effectiveAvailableHeight = h;
                        effectiveVisibleHourRange = r;
                        effectiveHeightOfHour = newHeightOfHour;
                    }
                }
            }
            CGFloat endVisibleHourBasedOnEffectiveHeightOfHour = fixedVisibleHourRange.startHour + availableHeight / effectiveHeightOfHour;
            fixedVisibleHourRange.endHour = fmax(fixedVisibleHourRange.endHour, endVisibleHourBasedOnEffectiveHeightOfHour);
            if (fixedVisibleHourRange.endHour < timeRulerHourRange.endHour)
                fixedVisibleHourRange.endHour = ceil(fixedVisibleHourRange.endHour);
            else
            {
                fixedVisibleHourRange.endHour = effectiveVisibleHourRange.endHour;
                availableHeight = effectiveAvailableHeight;
            }

            NSParameterAssert(WLHourRangeLength(fixedVisibleHourRange) > 0.0);
            NSParameterAssert(WLHourRangeContainsHourRange(timeRulerHourRange, fixedVisibleHourRange));
            CGFloat baseHeightOfHour = floor(availableHeight / WLHourRangeLength(fixedVisibleHourRange));
            CGFloat extendedHeightOfHour = baseHeightOfHour + 1.0;
            CGFloat lengthOfExtendedHourRange = round(fmod(availableHeight, WLHourRangeLength(fixedVisibleHourRange)));
            WLHourRange extendedHourRange = WLHourRangeMake(fixedVisibleHourRange.endHour - lengthOfExtendedHourRange + 1, fixedVisibleHourRange.endHour);
            _lengthOfHours[0] = baseHeightOfHour; // Guaranteed to be baseHeightOfHour
            _locationOfHours[0] = 0.0;
            size_t indexOfHour = 1;
            for (size_t end = fdim(extendedHourRange.startHour, timeRulerHourRange.startHour); indexOfHour < end; ++indexOfHour)
            {
                _lengthOfHours[indexOfHour] = baseHeightOfHour;
                _locationOfHours[indexOfHour] = _locationOfHours[indexOfHour - 1] + baseHeightOfHour;
            }
            for (size_t end = fdim(extendedHourRange.endHour, timeRulerHourRange.startHour); indexOfHour <= end; ++indexOfHour)
            {
                _lengthOfHours[indexOfHour] = extendedHeightOfHour;
                _locationOfHours[indexOfHour] = _locationOfHours[indexOfHour - 1] + extendedHeightOfHour;
            }
            for (size_t end = fdim(timeRulerHourRange.endHour, timeRulerHourRange.startHour); indexOfHour <= end; ++indexOfHour)
            {
                _lengthOfHours[indexOfHour] = baseHeightOfHour;
                _locationOfHours[indexOfHour] = _locationOfHours[indexOfHour - 1] + baseHeightOfHour;
            }
        }
        else
        {
            CGFloat heightOfBasedOnMaxHourRange = round(availableHeight / WLHourRangeLength(timeRulerHourRange));
            CGFloat heightOfHour = fmax(DefaultHeightOfHour, heightOfBasedOnMaxHourRange);
            _lengthOfHours[0] = heightOfHour;
            _locationOfHours[0] = 0.0;
            for (size_t i = 1, size = sizeof(_lengthOfHours) / sizeof(CGFloat); i < size; ++i)
            {
                _lengthOfHours[i] = heightOfHour;
                _locationOfHours[i] = _locationOfHours[i - 1] + heightOfHour;
            }
        }
        needsUpdateHoursLengthAndPositions = NO;
    }
}


#pragma mark CALayoutManager

- (void)invalidateLayoutOfLayer:(CALayer *)aLayer
{
    if ([aLayer.name isEqualToString:_WLTimeRulerRootLayerName])
        [self invalidateLayoutOfTimeRulerRootLayer:aLayer];
}

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    if ([aLayer.name isEqualToString:_WLRootLayerName])
        [self layoutSublayersOfRootLayer:aLayer];
    else if ([aLayer.name isEqualToString:_WLTimeRulerRootLayerName])
        [self layoutSublayersOfTimeRulerRootLayer:aLayer];
    else if ([aLayer.name isEqualToString:_WLTimeIndicatorRootLayerName])
        [self layoutSublayersOfTimeIndicatorRootLayer:aLayer];
    else if ([aLayer.name isEqualToString:_WLEventsRootLayerName])
        [self layoutSublayersOfEventsRootLayer:aLayer];
    else if ([aLayer.name isEqualToString:_WLTimeRulerBackgroundLayerName])
        [self layoutSublayersOfTimeRulerBackgroundLayer:(WLBlockLayer *)aLayer];
    else if ([aLayer.name isEqualToString:_WLTimeRulerScrollLayerName])
        [self layoutSublayersOfTimeRulerScrollLayer:(CAScrollLayer *)aLayer];
    else if ([aLayer.name isEqualToString:_WLColumnRootLayerName])
        [self layoutSublayersOfColumnRootLayer:aLayer];
    else if ([aLayer.name isEqualToString:_WLAllDayBackgroundLayerName])
        [self layoutSublayersOfAllDayBackgroundLayer:(WLBlockLayer *)aLayer];
    else if ([aLayer.name isEqualToString:_WLDayBackgroundLayerName])
        [self layoutSublayersOfDayBackgroundLayer:(WLCalendarDayEventsBackgroundLayer *)aLayer];
    else if ([aLayer.name isEqualToString:_WLDayScrollLayerName])
        [self layoutSublayersOfDayScrollLayer:(CAScrollLayer *)aLayer];
}


#pragma mark CALayerDelegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
#ifdef DEBUG_LAYERS
    NSLog(@"    %@: %@", layer.name, event);
#endif

    return nil;
}

- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow
{
    return YES;
}


#pragma mark WLCalendarTimeRuler

- (WLHourRange)hourRange
{
    WLHourRange r = [dataSource hourRangeOfColumnsInWeekView:self];
    NSAssert(r.startHour <= r.endHour, @"start hour MUST NOT be greater than endhour");
    NSAssert(r.startHour >= 0.0, @"start hour MUST NOT be less than 0");
    NSAssert(r.endHour < (sizeof(_locationOfHours) / sizeof(CGFloat)), @"end hour MUST be less than %d", (sizeof(_locationOfHours) / sizeof(CGFloat)));
    return r;
}

- (CGFloat)originOffset
{
    return ceil([[self timeRulerLayer] maximumHeightOfMarker] / 2.0);
}

- (CGFloat)locationForHour:(CGFloat)aHour
{
    NSParameterAssert(WLHourRangeContainsHour([self hourRange], aHour));

    [self updateHoursLengthAndLocationIfNeeded];

    CGFloat locationOfIntegerPart = _locationOfHours[(size_t)floor(aHour)];
    CGFloat lengthOfFractionalPart = fdim(aHour, (size_t)floor(aHour)) * _lengthOfHours[(size_t)ceil(aHour)];

    return [self originOffset] + locationOfIntegerPart + lengthOfFractionalPart;
}

- (CGFloat)lengthForHourRange:(WLHourRange)aHourRange
{
    [self updateHoursLengthAndLocationIfNeeded];

    return fdim([self locationForHour:aHourRange.endHour], [self locationForHour:aHourRange.startHour]);
}

- (CGFloat)hourForDate:(NSDate *)aDate
{
    return [self.dataSource weekView:self convertDateToHour:aDate];
}

- (NSString *)markerForHour:(NSUInteger)aHour
{
    NSParameterAssert(WLHourRangeContainsHour([self hourRange], (CGFloat)aHour));

    return [self.dataSource weekView:self stringForHour:aHour];
}


#pragma mark Private

- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex
{
    [self setNeedsUpdateHoursLengthAndLocation];

    NSMutableArray *columnEvents = [[[self.dataSource weekView:self eventsForColumnAtIndex:anIndex] mutableCopy] autorelease];
    NSIndexSet *allDayEventIndexes = [columnEvents indexesOfObjectsPassingTest:^BOOL(CalEvent *e, NSUInteger idx, BOOL *stop) {
        return e.isAllDay;
    }];
    NSArray *allDayEvents = [[[columnEvents objectsAtIndexes:allDayEventIndexes] retain] autorelease];
    [columnEvents removeObjectsAtIndexes:allDayEventIndexes];
    NSSet *dayEvents = [NSSet setWithArray:columnEvents];

    WLCalendarDayEventsLayer *dayLayer = [[self dayLayers] objectAtIndex:anIndex];
    NSParameterAssert(dayLayer != nil);
    [dayLayer setEvents:dayEvents];

    WLCalendarAllDayEventsLayer *allDayLayer = [[self allDayLayers] objectAtIndex:anIndex];
    NSParameterAssert(allDayLayer != nil);
    [allDayLayer setEvents:allDayEvents];
}

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex
{
    WLCalendarDayEventsBackgroundLayer *l = [[self dayBackgroundLayers] objectAtIndex:anIndex];
    NSParameterAssert(l != nil);
    NSString *newTitle = [self.dataSource weekView:self titleForColumnAtIndex:anIndex];
    l.title = newTitle;
}

- (void)_updateHighlightsTitleOfColumnAtIndex:(NSUInteger)anIndex
{
    WLCalendarDayEventsBackgroundLayer *l = [[self dayBackgroundLayers] objectAtIndex:anIndex];
    NSParameterAssert(l != nil);
    BOOL newIsTitleHighlighted = [self.dataSource weekView:self highlightsTitleForColumnAtIndex:anIndex];
    l.isTitleHighlighted = newIsTitleHighlighted;
}

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex
{
//    NSAssert([self wantsLayer], @"You MUST call -setupLayers before.");
//
//    if ([dataSource respondsToSelector:@selector(weekView:colorForColumnAtIndex:)])
//    {
//        CALayer *column = [_columnLayers objectAtIndex:anIndex];
//        WLCalendarBackgroundLayer *dayBackground = [column WL_dayBackgroundLayer];
//        WLCalendarBackgroundLayer *allDayBackground = [column WL_allDayBackgroundLayer];
//        CGColorRef c = [dataSource weekView:self colorForColumnAtIndex:anIndex];
//        dayBackground.contentsBackgroundColor = c;
//        allDayBackground.contentsBackgroundColor = c;
//    }
}

- (NSArray *)_timeRulerMarkers
{
    WLHourRange hourRange = [self hourRange];
    NSUInteger numberOfHours = (NSUInteger)ceil(WLHourRangeLength(hourRange));
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:numberOfHours];
    for (NSUInteger hour = (NSUInteger)floor(hourRange.startHour); hour < numberOfHours; ++hour)
        [markers addObject:[self markerForHour:hour]];
    return markers;
}


#pragma mark WLLayerBackedView

- (void)makeLayers
{
    [super makeLayers];
    [self reloadDataAnimated:NO];
    [[self layer] setNeedsLayout];
}

- (CALayer *)makeRootLayer
{
    CALayer *l = [CALayer layer];
    l.masksToBounds = YES;
    l.name = _WLRootLayerName;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif

    CALayer *timeRulerRootLayer = [self setupTimeRulerRootLayer];
    [l addSublayer:timeRulerRootLayer];
    [l setValue:timeRulerRootLayer forKey:timeRulerRootLayer.name];

    CALayer *timeIndicatorRootLayer = [self setupTimeIndicatorRootLayer];
    [l addSublayer:timeIndicatorRootLayer];
    [l setValue:timeIndicatorRootLayer forKey:timeIndicatorRootLayer.name];

    CALayer *eventsRootLayer = [self setupEventsRootLayer];
    [l addSublayer:eventsRootLayer];
    [l setValue:eventsRootLayer forKey:eventsRootLayer.name];

    return l;
}

@end


#pragma mark -

@implementation WLCalendarWeekView (Layers)

#pragma mark Time Ruler Layers

- (CALayer *)setupTimeRulerRootLayer
{
    CALayer *l = [CALayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLTimeRulerRootLayerName;
    l.layoutManager = self;
    l.masksToBounds = YES;
    l.zPosition = 0;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor darkGrayColor] WL_CGColor];
#endif

    WLBlockLayer *timeRulerBackgroundLayer = [self setupTimeRulerBackgroundLayer];
    [l addSublayer:timeRulerBackgroundLayer];
    [l setValue:timeRulerBackgroundLayer forKey:timeRulerBackgroundLayer.name];

    return l;
}

- (WLBlockLayer *)setupTimeRulerBackgroundLayer
{
    __block WLBlockLayer *l = [WLBlockLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLTimeRulerBackgroundLayerName;
    l.needsDisplayOnBoundsChange = YES;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifndef DEBUG_LAYERS
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect) {
        NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[aLayer contentsAreFlipped]];
        [c setImageInterpolation:NSImageInterpolationHigh];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:c];

        NSSize bottomBorderSize = NSMakeSize(aLayer.bounds.size.width, [[NSImage imageNamed:@"calendar-week-timeruler-bottom"] size].height);
        NSSize topBorderSize = NSMakeSize(aLayer.bounds.size.width, [[NSImage imageNamed:@"calendar-week-timeruler-top"] size].height);
        NSSize middleBorderSize = NSMakeSize(aLayer.bounds.size.width, aLayer.bounds.size.height - bottomBorderSize.height - topBorderSize.height);

        NSRect dirtyRect = NSRectFromCGRect(aDirtyRect);
        static CGFloat AlphaFraction = 0.5;

        NSRect bottomBorderFrame = NSMakeRect(0.0, 0.0, bottomBorderSize.width, bottomBorderSize.height);
        if (NSIntersectsRect(bottomBorderFrame, dirtyRect))
        {
            NSDrawThreePartImage(bottomBorderFrame,
                                 [NSImage imageNamed:@"calendar-week-timeruler-bottom-left"],
                                 [NSImage imageNamed:@"calendar-week-timeruler-bottom"],
                                 [NSImage imageNamed:@"calendar-week-timeruler-bottom-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 NO);
        }

        NSRect middleBorderFrame = NSMakeRect(0.0, NSMaxY(bottomBorderFrame), middleBorderSize.width, middleBorderSize.height);
        if (NSIntersectsRect(middleBorderFrame, dirtyRect))
        {
            [(NSImage *)[NSImage imageNamed:@"calendar-week-timeruler-middle-left"] drawInRect:NSMakeRect(0.0, middleBorderFrame.origin.y, 1.0, middleBorderFrame.size.height)
                                                                        fromRect:NSZeroRect
                                                                       operation:NSCompositeSourceOver
                                                                        fraction:AlphaFraction
                                                                  respectFlipped:YES
                                                                           hints:nil];
            [(NSImage *)[NSImage imageNamed:@"calendar-week-timeruler-middle"] drawInRect:NSMakeRect(1.0, middleBorderFrame.origin.y, middleBorderFrame.size.width - 2.0, middleBorderFrame.size.height)
                                                                   fromRect:NSZeroRect
                                                                  operation:NSCompositeSourceOver
                                                                   fraction:AlphaFraction
                                                             respectFlipped:YES
                                                                      hints:nil];
            [(NSImage *)[NSImage imageNamed:@"calendar-week-timeruler-middle-right"] drawInRect:NSMakeRect(middleBorderFrame.size.width - 1.0, middleBorderFrame.origin.y, 1.0, middleBorderFrame.size.height)
                                                                         fromRect:NSZeroRect
                                                                        operation:NSCompositeSourceOver
                                                                         fraction:AlphaFraction
                                                                   respectFlipped:YES
                                                                            hints:nil];
        }

        NSRect topBorderFrame = NSMakeRect(0.0, NSMaxY(middleBorderFrame), topBorderSize.width, topBorderSize.height);
        if (NSIntersectsRect(topBorderFrame, topBorderFrame))
        {
            NSDrawThreePartImage(topBorderFrame,
                                 [NSImage imageNamed:@"calendar-week-timeruler-top-left"],
                                 [NSImage imageNamed:@"calendar-week-timeruler-top"],
                                 [NSImage imageNamed:@"calendar-week-timeruler-top-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 NO);
        }
        [NSGraphicsContext restoreGraphicsState];
    };
#else
    l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif

    CAScrollLayer *timeRulerScrollLayer = [self setupTimeRulerScrollLayer];
    [l addSublayer:timeRulerScrollLayer];
    [l setValue:timeRulerScrollLayer forKey:timeRulerScrollLayer.name];

    return l;
}

- (CAScrollLayer *)setupTimeRulerScrollLayer
{
    CAScrollLayer *l = [CAScrollLayer layer];

    NSWindow *window = [self window];
    if (window)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLTimeRulerScrollLayerName;
    l.scrollMode = kCAScrollVertically;
    l.geometryFlipped = YES;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif

    WLCalendarTimeRulerLayer *timeRulerLayer = [self setupTimeRulerLayer];
    [l addSublayer:timeRulerLayer];
    [l setValue:timeRulerLayer forKey:timeRulerLayer.name];

    return l;
}

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer
{
    WLCalendarTimeRulerLayer *l = [WLCalendarTimeRulerLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLTimeRulerLayerName;
    l.timeRuler = self;
    l.onlyCompletelyVisibleMarkersShown = self.fitsDayEvents;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;
    l.markers = [self _timeRulerMarkers];

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blueColor] WL_CGColor];
#endif

    return l;
}


#pragma mark Event Layers

- (CALayer *)setupEventsRootLayer
{
    CALayer *l = [CALayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.masksToBounds = YES;
    l.name = _WLEventsRootLayerName;
    l.zPosition = 1;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[[NSColor darkGrayColor] colorWithAlphaComponent:0.5] WL_CGColor];
#endif

    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    NSMutableArray *columnLayers = [NSMutableArray arrayWithCapacity:numberOfColumns];
    for (NSUInteger i = 0; i < numberOfColumns; ++i)
    {
        CALayer *c = [self setupColumnRootLayer];
        WLBlockLayer *dayBackgroundLayer = [c valueForKey:_WLDayBackgroundLayerName];
        NSParameterAssert(dayBackgroundLayer != nil);
        [columnLayers addObject:c];
        [l addSublayer:c];
    }
    [l setValue:columnLayers forKey:_WLColumnLayersKey];

    return l;
}

- (CALayer *)setupColumnRootLayer
{
    CALayer *l = [CALayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.geometryFlipped = YES;
    l.name = _WLColumnRootLayerName;
    l.anchorPoint = CGPointMake(0.0, 0.0);
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor redColor] WL_CGColor];
#endif

    WLBlockLayer *allDayBackground = [self setupAllDayBackgroundLayer];
    [l addSublayer:allDayBackground];
    [l setValue:allDayBackground forKey:allDayBackground.name];

    WLCalendarDayEventsBackgroundLayer *dayBackground = [self setupDayBackgroundLayer];
    [l addSublayer:dayBackground];
    [l setValue:dayBackground forKey:dayBackground.name];

    return l;
}

- (WLBlockLayer *)setupAllDayBackgroundLayer
{
    __block WLBlockLayer *l = [WLBlockLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLAllDayBackgroundLayerName;
    l.needsDisplayOnBoundsChange = YES;
    l.masksToBounds = YES;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifndef DEBUG_LAYERS
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect) {
        // (0, 0) is top left.
        NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[aLayer contentsAreFlipped]];
        [c setImageInterpolation:NSImageInterpolationHigh];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:c];

        [c setImageInterpolation:NSImageInterpolationHigh];

        WLDrawScaledNinePartImage(NSRectFromCGRect(aLayer.bounds),
                                  [NSImage imageNamed:@"calendar-week-all-day-top-left"],
                                  [NSImage imageNamed:@"calendar-week-all-day-top-middle"],
                                  [NSImage imageNamed:@"calendar-week-all-day-top-right"],
                                  [NSImage imageNamed:@"calendar-week-all-day-middle-left"],
                                  [NSImage imageNamed:@"calendar-week-all-day-middle-middle"],
                                  [NSImage imageNamed:@"calendar-week-all-day-middle-right"],
                                  [NSImage imageNamed:@"calendar-week-all-day-bottom-left"],
                                  [NSImage imageNamed:@"calendar-week-all-day-bottom-middle"],
                                  [NSImage imageNamed:@"calendar-week-all-day-bottom-right"],
                                  NSCompositeSourceOver,
                                  1.0,
                                  YES);

        [NSGraphicsContext restoreGraphicsState];
    };
#else
    l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif

    WLCalendarAllDayEventsLayer *allDay = [self setupAllDayLayer];
    [l addSublayer:allDay];
    [l setValue:allDay forKey:allDay.name];

    return l;
}

- (WLCalendarDayEventsBackgroundLayer *)setupDayBackgroundLayer
{
    WLCalendarDayEventsBackgroundLayer *l = [WLCalendarDayEventsBackgroundLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLDayBackgroundLayerName;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif

    CAScrollLayer *scroll = [self setupDayScrollLayer];
    [l addSublayer:scroll];
    [l setValue:scroll forKey:scroll.name];

    return l;
}

- (WLCalendarAllDayEventsLayer *)setupAllDayLayer
{
    WLCalendarAllDayEventsLayer *l = [WLCalendarAllDayEventsLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLAllDayLayerName;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blueColor] WL_CGColor];
#endif

    return l;
}

- (CAScrollLayer *)setupDayScrollLayer
{
    CAScrollLayer *l = [CAScrollLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLDayScrollLayerName;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif

    WLCalendarDayEventsLayer *dayLayer = [self setupDayLayer];
    [l addSublayer:dayLayer];
    [l setValue:dayLayer forKey:dayLayer.name];

    return l;
}

- (WLCalendarDayEventsLayer *)setupDayLayer
{
    WLCalendarDayEventsLayer *l = [WLCalendarDayEventsLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLDayLayerName;
    l.timeRuler = self;
    l.keepsTextOfEventsVisible = !self.fitsDayEvents;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.needsDisplayOnBoundsChange = YES;
    l.backgroundColor = [[NSColor blueColor] WL_CGColor];
#endif

    return l;
}


#pragma mark Time Indicator Layers

- (CALayer *)setupTimeIndicatorRootLayer
{
    CALayer *l = [CALayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLTimeIndicatorRootLayerName;
    l.masksToBounds = YES;
    l.zPosition = 2;
    l.layoutManager = self;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[[NSColor darkGrayColor] colorWithAlphaComponent:0.7] WL_CGColor];
#endif

    WLCalendarTimeIndicatorLayer *timeIndicatorLayer = [self setupTimeIndicatorLayer];
    [l addSublayer:timeIndicatorLayer];
    [l setValue:timeIndicatorLayer forKey:timeIndicatorLayer.name];

    return l;
}

- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer
{
    WLCalendarTimeIndicatorLayer *l = [WLCalendarTimeIndicatorLayer layer];

    NSWindow *window = [self window];
    if (window && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = [window backingScaleFactor];

    l.name = _WLTimeIndicatorLayerName;
    l.anchorPoint = CGPointMake(0.0, 0.5);
    l.hidden = !self.showsTimeIndicator;
    NSDictionary *actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], kCAOnOrderIn,
                             [NSNull null], kCAOnOrderOut,
                             [NSNull null], kCATransition,
                             [NSNull null], @"contents",
                             nil];
    l.actions = actions;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor whiteColor] WL_CGColor];
#endif

    return l;
}


#pragma mark Access Layers

- (CALayer *)timeRulerRootLayer
{
    return [[self layer] valueForKey:_WLTimeRulerRootLayerName];
}

- (WLBlockLayer *)timeRulerBackgroundLayer
{
    return [[self timeRulerRootLayer] valueForKey:_WLTimeRulerBackgroundLayerName];
}

- (CAScrollLayer *)timeRulerScrollLayer
{
    return [[self timeRulerBackgroundLayer] valueForKey:_WLTimeRulerScrollLayerName];
}

- (WLCalendarTimeRulerLayer *)timeRulerLayer
{
    return [[self timeRulerScrollLayer] valueForKey:_WLTimeRulerLayerName];
}

- (CALayer *)eventsRootLayer
{
    return [[self layer] valueForKey:_WLEventsRootLayerName];
}

- (NSMutableArray *)columnRootLayers
{
    return [[self eventsRootLayer] valueForKey:_WLColumnLayersKey];
}

- (void)setColumnRootLayers:(NSMutableArray *)newColumnRootLayers
{
    [[self eventsRootLayer] setValue:newColumnRootLayers forKey:_WLColumnLayersKey];
}

- (NSArray *)allDayBackgroundLayers
{
    return [[self columnRootLayers] valueForKey:_WLAllDayBackgroundLayerName];
}

- (NSArray *)dayBackgroundLayers
{
    return [[self columnRootLayers] valueForKey:_WLDayBackgroundLayerName];
}

- (NSArray *)allDayLayers
{
    return [[self allDayBackgroundLayers] valueForKey:_WLAllDayLayerName];
}

- (NSArray *)dayScrollLayers
{
    return [[self columnRootLayers] valueForKeyPath:[NSString stringWithFormat:@"%@.%@", _WLDayBackgroundLayerName, _WLDayScrollLayerName]];
}

- (NSArray *)dayLayers
{
    return [[self columnRootLayers] valueForKeyPath:[NSString stringWithFormat:@"%@.%@.%@", _WLDayBackgroundLayerName, _WLDayScrollLayerName, _WLDayLayerName]];
}

- (CALayer *)timeIndicatorRootLayer
{
    return [[self layer] valueForKey:_WLTimeIndicatorRootLayerName];
}

- (WLCalendarTimeIndicatorLayer *)timeIndicatorLayer
{
    return [[self timeIndicatorRootLayer] valueForKey:_WLTimeIndicatorLayerName];
}

@end


#pragma mark -

@implementation WLCalendarWeekView (Layout)

#pragma mark Root Layer

- (void)layoutSublayersOfRootLayer:(CALayer *)aRootLayer
{
    if (aRootLayer.bounds.size.width == 0.0 || aRootLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aRootLayer.frame)));
#endif

    CALayer *timeRulerRootLayer = [aRootLayer valueForKey:_WLTimeRulerRootLayerName];
    NSParameterAssert(timeRulerRootLayer != nil);
    WLCalendarTimeRulerLayer *timeRulerLayer = [timeRulerRootLayer valueForKeyPath:[NSString stringWithFormat:@"%@.%@.%@",
                                                                                    _WLTimeRulerBackgroundLayerName,
                                                                                    _WLTimeRulerScrollLayerName,
                                                                                    _WLTimeRulerLayerName]];
    NSParameterAssert(timeRulerLayer != nil);
    timeRulerRootLayer.frame = CGRectIntegral(CGRectMake(0.0,
                                                         0.0,
                                                         [timeRulerLayer preferredFrameWidth] + 2.0 * _WLXMarginBetweenTimeRulerAndTimeRulerRoot,
                                                         fdim(CGRectGetHeight(aRootLayer.bounds), [self heightAndMarginOfAllDayEventsPartOfColumn])));
    [timeRulerRootLayer setNeedsLayout];

    CALayer *eventsRootLayer = [aRootLayer valueForKey:_WLEventsRootLayerName];
    NSParameterAssert(eventsRootLayer != nil);
    eventsRootLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMaxX(timeRulerRootLayer.frame),
                                                      0.0,
                                                      fdim(CGRectGetWidth(aRootLayer.bounds), CGRectGetMaxX(timeRulerRootLayer.frame)),
                                                      CGRectGetHeight(aRootLayer.bounds)));
    [eventsRootLayer setNeedsLayout];

    CALayer *timeIndicatorRootLayer = [aRootLayer valueForKey:_WLTimeIndicatorRootLayerName];
    NSParameterAssert(timeIndicatorRootLayer != nil);
    timeIndicatorRootLayer.frame = CGRectIntegral(CGRectMake(CGRectGetMaxX(timeRulerRootLayer.frame),
                                                             0.0,
                                                             fdim(CGRectGetWidth(aRootLayer.bounds), CGRectGetMaxX(timeRulerRootLayer.frame)),
                                                             [self visibleHeightOfTimeRuler]));
    [timeIndicatorRootLayer setNeedsLayout];
}


#pragma mark Time Ruler Layers

- (void)layoutSublayersOfTimeRulerRootLayer:(CALayer *)aTimeRulerRootLayer
{
    if (aTimeRulerRootLayer.bounds.size.width == 0.0 || aTimeRulerRootLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aTimeRulerRootLayer.frame)));
#endif

    WLBlockLayer *timeRulerBackgroundLayer = [aTimeRulerRootLayer valueForKey:_WLTimeRulerBackgroundLayerName];
    NSParameterAssert(timeRulerBackgroundLayer != nil);
    timeRulerBackgroundLayer.frame = aTimeRulerRootLayer.bounds;
    [timeRulerBackgroundLayer setNeedsLayout];
}

- (void)layoutSublayersOfTimeRulerBackgroundLayer:(CALayer *)aTimeRulerBackgroundLayer
{
    if (aTimeRulerBackgroundLayer.bounds.size.width == 0.0 || aTimeRulerBackgroundLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aTimeRulerBackgroundLayer.frame)));
#endif

    CAScrollLayer *timeRulerScrollLayer = [aTimeRulerBackgroundLayer valueForKey:_WLTimeRulerScrollLayerName];
    NSParameterAssert(timeRulerScrollLayer != nil);
    CGRect f = aTimeRulerBackgroundLayer.bounds;
    f.size.height -= NSMaxY([self columnTitleFrame]);
    timeRulerScrollLayer.frame = f;
    [timeRulerScrollLayer setNeedsLayout];
}

- (void)layoutSublayersOfTimeRulerScrollLayer:(CALayer *)aTimeRulerScrollLayer
{
    if (aTimeRulerScrollLayer.bounds.size.width == 0.0 || aTimeRulerScrollLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aTimeRulerScrollLayer.frame)));
#endif

    WLCalendarTimeRulerLayer *timeRulerLayer = [aTimeRulerScrollLayer valueForKey:_WLTimeRulerLayerName];
    NSParameterAssert(timeRulerLayer != nil);
    CGSize preferredFrameSize = [timeRulerLayer preferredFrameSize];
    CGPoint scrollPoint = [self scrollPoint];
    timeRulerLayer.frame = CGRectIntegral(CGRectInset(CGRectMake(0.0,
                                                                 -scrollPoint.y,
                                                                 aTimeRulerScrollLayer.bounds.size.width,
                                                                 preferredFrameSize.height),
                                                      _WLXMarginBetweenTimeRulerAndTimeRulerRoot,
                                                      0.0));
    [timeRulerLayer setNeedsLayout];
}

- (void)invalidateLayoutOfTimeRulerRootLayer:(CALayer *)aTimeRulerRootLayer
{
    [self setNeedsUpdateHoursLengthAndLocation];
}


#pragma mark Event Layers

- (void)layoutSublayersOfEventsRootLayer:(CALayer *)anEventsRootLayer
{
    if (anEventsRootLayer.bounds.size.width == 0.0 || anEventsRootLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(anEventsRootLayer.frame)));
#endif

    NSArray *columnLayers = [anEventsRootLayer valueForKey:_WLColumnLayersKey];

    NSParameterAssert(columnLayers != nil);
    NSUInteger numberOfColumns = [columnLayers count];
    if (numberOfColumns == 0)
        return;

    NSArray *frames = [self framesForNumberOfColumns:numberOfColumns];
    NSParameterAssert([frames count] == numberOfColumns);
    [columnLayers enumerateObjectsUsingBlock:^(CALayer *c, NSUInteger idx, BOOL *stop) {
        c.frame = NSRectToCGRect([[frames objectAtIndex:idx] rectValue]);
        [c setNeedsLayout];
    }];
}

- (void)layoutSublayersOfColumnRootLayer:(CALayer *)aColumnRootLayer
{
    if (aColumnRootLayer.bounds.size.width == 0.0 || aColumnRootLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aColumnRootLayer.frame)));
#endif

    WLBlockLayer *allDayBackgroundLayer = [aColumnRootLayer valueForKey:_WLAllDayBackgroundLayerName];
    NSParameterAssert(allDayBackgroundLayer != nil);
    if (self.showsAllDayEvents)
    {
        allDayBackgroundLayer.hidden = NO;
        allDayBackgroundLayer.frame = CGRectIntegral(CGRectMake(0.0,
                                                                0.0,
                                                                aColumnRootLayer.bounds.size.width,
                                                                self.heightOfAllDayPartOfColumn));
    }
    else
    {
        allDayBackgroundLayer.hidden = YES;
        allDayBackgroundLayer.frame = CGRectZero;
    }
    [allDayBackgroundLayer setNeedsLayout];

    WLCalendarDayEventsBackgroundLayer *dayBackgroundLayer = [aColumnRootLayer valueForKey:_WLDayBackgroundLayerName];
    NSParameterAssert(dayBackgroundLayer != nil);
    CGFloat heightAndMarginOfAllDayEventsPartOfColumn = [self heightAndMarginOfAllDayEventsPartOfColumn];
    dayBackgroundLayer.frame = CGRectIntegral(CGRectMake(0.0,
                                                         heightAndMarginOfAllDayEventsPartOfColumn,
                                                         aColumnRootLayer.bounds.size.width,
                                                         aColumnRootLayer.bounds.size.height - heightAndMarginOfAllDayEventsPartOfColumn));
    [dayBackgroundLayer setNeedsLayout];
}

- (void)layoutSublayersOfAllDayBackgroundLayer:(WLBlockLayer *)anAllDayBackgroundLayer
{
    if (anAllDayBackgroundLayer.bounds.size.width == 0.0 || anAllDayBackgroundLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(anAllDayBackgroundLayer.frame)));
#endif
    WLCalendarAllDayEventsLayer *allDayEventsLayer = [anAllDayBackgroundLayer valueForKey:_WLAllDayLayerName];
    NSParameterAssert(allDayEventsLayer != nil);
    allDayEventsLayer.frame = anAllDayBackgroundLayer.bounds;
    [allDayEventsLayer setNeedsLayout];
}

- (void)layoutSublayersOfDayBackgroundLayer:(WLCalendarDayEventsBackgroundLayer *)aDayBackgroundLayer
{
    if (aDayBackgroundLayer.bounds.size.width == 0.0 || aDayBackgroundLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aDayBackgroundLayer.frame)));
#endif
    CAScrollLayer *dayScrollLayer = [aDayBackgroundLayer valueForKey:_WLDayScrollLayerName];
    NSParameterAssert(dayScrollLayer != nil);
    NSRect titleFrame = [self columnTitleFrame];
    aDayBackgroundLayer.titleFrame = NSRectToCGRect(titleFrame);

    dayScrollLayer.frame = CGRectIntegral(CGRectInset(CGRectMake(0.0,
                                                                 NSMaxY(titleFrame),
                                                                 aDayBackgroundLayer.bounds.size.width,
                                                                 aDayBackgroundLayer.bounds.size.height - NSMaxY(titleFrame)),
                                                      1.0,
                                                      0.0));
    [dayScrollLayer setNeedsLayout];
}

- (void)layoutSublayersOfDayScrollLayer:(CAScrollLayer *)aDayScrollLayer
{
    if (aDayScrollLayer.bounds.size.width == 0.0 || aDayScrollLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aDayScrollLayer.frame)));
#endif
    WLCalendarDayEventsLayer *dayLayer = [aDayScrollLayer valueForKey:_WLDayLayerName];
    NSParameterAssert(dayLayer != nil);
    CGPoint scrollPoint = [self scrollPoint];
    dayLayer.frame = CGRectIntegral(CGRectMake(0.0,
                                               -scrollPoint.y,
                                               aDayScrollLayer.bounds.size.width,
                                               [dayLayer preferredFrameSize].height));
    [dayLayer setNeedsLayout];
}


#pragma mark Time Indicator Layers

- (void)layoutSublayersOfTimeIndicatorRootLayer:(CALayer *)aTimeIndicatorRootLayer
{
    if (aTimeIndicatorRootLayer.bounds.size.width == 0.0 || aTimeIndicatorRootLayer.bounds.size.height == 0.0)
        return;

#ifdef DEBUG_LAYERS
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), NSStringFromRect(NSRectFromCGRect(aTimeIndicatorRootLayer.frame)));
#endif
    WLCalendarTimeIndicatorLayer *timeIndicatorLayer = [aTimeIndicatorRootLayer valueForKey:_WLTimeIndicatorLayerName];
    NSParameterAssert(timeIndicatorLayer != nil);
    CGSize preferredTimeIndicatorLayerSize = [timeIndicatorLayer preferredFrameSize];
    timeIndicatorLayer.bounds = CGRectIntegral(CGRectMake(0.0,
                                                          0.0,
                                                          aTimeIndicatorRootLayer.bounds.size.width,
                                                          preferredTimeIndicatorLayerSize.height));
    timeIndicatorLayer.position = CGPointMake(0.0,
                                              round([self positionForTimeIndicator]));
}


#pragma mark Layout Calculations

- (CGFloat)heightAndMarginOfAllDayEventsPartOfColumn
{
    if ([self isAllDayPartOfColumnVisible])
        return self.heightOfAllDayPartOfColumn + _WLYMarginBetweenAllDayAndDayPartsOfColumn;
    else
        return 0.0;
}

- (NSArray *)framesForNumberOfColumns:(NSUInteger)aNumberOfColumns;
{
    if (aNumberOfColumns == 0)
        return [NSArray array];

    CALayer *eventsRootLayer = [self eventsRootLayer];
    NSParameterAssert(eventsRootLayer != nil);
    CGFloat effectiveEventsRootLayerWidth = fdim(eventsRootLayer.bounds.size.width, (aNumberOfColumns - 1) * _WLXMarginBetweenColumns + _WLXMarginBetweenTimeRulerAndColumns);
    CGFloat baseColumnWidth = floor(effectiveEventsRootLayerWidth / aNumberOfColumns);
    CGFloat extendedColumnWidth = baseColumnWidth + 1.0;
    NSUInteger numberOfExtendedColumns = (NSUInteger)fmod(effectiveEventsRootLayerWidth, (CGFloat)aNumberOfColumns);
    NSParameterAssert(numberOfExtendedColumns < aNumberOfColumns);

    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:aNumberOfColumns];
    CGFloat x = _WLXMarginBetweenTimeRulerAndColumns;
    for (NSUInteger i = 0; i < aNumberOfColumns; ++i)
    {
        CGFloat width = i < numberOfExtendedColumns ? extendedColumnWidth : baseColumnWidth;
        NSRect frame = NSMakeRect(x,
                                  0.0,
                                  width,
                                  eventsRootLayer.bounds.size.height);
        [frames addObject:[NSValue valueWithRect:frame]];
        x += width + _WLXMarginBetweenColumns;
    }
    return frames;
}

- (NSRect)columnTitleFrame
{
    NSUInteger numberOfColumns = [self numberOfColumns];
    if (![self.dataSource respondsToSelector:@selector(weekView:titleForColumnAtIndex:)] || numberOfColumns == 0)
        return NSZeroRect;

    static const CGFloat MinimumTitleHeight = 25.0;

    CGFloat height = MinimumTitleHeight;
    CGFloat width = CGFLOAT_MAX;
    CGFloat maximumHeight = height;
    CGFloat heightAndMarginOfAllDayEventsPartOfColumn = [self heightAndMarginOfAllDayEventsPartOfColumn];
    NSArray *frames = [self framesForNumberOfColumns:numberOfColumns];
    NSParameterAssert([frames count] == [frames count]);
    for (NSValue *frame in frames)
    {
        NSRect rectValue = [frame rectValue];
        width = fmin(width, rectValue.size.width);
        maximumHeight = fmax(maximumHeight, rectValue.size.height - heightAndMarginOfAllDayEventsPartOfColumn);
    }

    NSArray *dayBackgroundLayers = [self dayBackgroundLayers];
    NSParameterAssert(dayBackgroundLayers != nil);
    for (WLCalendarDayEventsBackgroundLayer *l in dayBackgroundLayers)
        height = fmax(height, [l preferredTitleFrameSizeWithBoundingSize:CGSizeMake(width, maximumHeight)].height);
    NSRect columnTitleFrame = NSIntegralRect(NSMakeRect(0.0,
                                                        0.0,
                                                        width,
                                                        height + _WLYColumnTitleFrameBottomOffset));
    return columnTitleFrame;
}

- (CGPoint)scrollPoint
{
    if (self.fitsDayEvents)
        return [self scrollPointToFocusOnDayEvents];
    else
        return [self scrollPointToFocusOnCurrentHour];
}

- (CGPoint)scrollPointToFocusOnDayEvents
{
    return CGPointMake(0.0,
                       floor(fdim([self locationForHour:[self visibleHourRange].startHour], [[self timeRulerLayer] maximumHeightOfMarker] / 2.0)));
}

- (CGPoint)scrollPointToFocusOnCurrentHour
{
    CGPoint p = CGPointMake(0.0,
                            [self locationForHour:_hour]);
    CGFloat visibleHeightOfTimeRuler = [self visibleHeightOfTimeRuler];
    // Center _hour until bottom limit is reached.
    p = CGPointMake(0.0,
                    floor(p.y - visibleHeightOfTimeRuler / 2.0));
    CGFloat topLimit = [self originOffset];
    CGFloat bottomLimit = fdim([self locationForHour:[self hourRange].endHour], visibleHeightOfTimeRuler);
    topLimit = fmin(topLimit, bottomLimit);
    WLCalendarTimeRulerLayer *timeRuler = [self timeRulerLayer];
    NSParameterAssert(timeRuler != nil);
    p.y = floor(fmin(fmax(p.y - [timeRuler maximumHeightOfMarker] / 2.0, topLimit), bottomLimit));
    return p;
}

- (BOOL)isAllDayPartOfColumnVisible
{
    return self.showsAllDayEvents && fabs(self.heightOfAllDayPartOfColumn - 0.0) > (CGFLOAT_IS_DOUBLE ? DBL_EPSILON : FLT_EPSILON);
}

- (CGFloat)visibleHeightOfTimeRuler
{
    return fdim([self frame].size.height, [self heightAndMarginOfAllDayEventsPartOfColumn] + NSMaxY([self columnTitleFrame]));
}

- (CGFloat)positionForTimeIndicator
{
    CGFloat hourPosition = [self locationForHour:_hour];
    CGPoint scrollPoint = [self scrollPoint];
    return [self visibleHeightOfTimeRuler] - (hourPosition - scrollPoint.y);
}

@end

//
//  WLCalendarWeekView.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWeekView.h"
#import "NSColor+CGColor.h"
#import "CoreAnimation+WLCalendar.h"


// Must be unique!
// These strings may be used directly in the code, look through it if you are going to change values.
static NSString* const _WLRootLayerName = @"root";

static NSString* const _WLTimeRulerBackgroundLayerName = @"timeRulerBackground";

static NSString* const _WLTimeRulerScrollLayerName = @"timeRulerScroll";

static NSString* const _WLTimeRulerLayerName = @"timeRuler";

static NSString* const _WLColumnLayerName = @"weekdayEventsContent";

static NSString *const _WLAllDayBackgroundLayerName = @"weekdayEventsAllDayBackground";

static NSString* const _WLDayBackgroundLayerName = @"weekdayEventsBackground";

static NSString* const _WLAllDayLayerName = @"weekdayEventsAllDay";

static NSString* const _WLTitleLayerName = @"weekdayEventsTitle";

static NSString* const _WLDayScrollLayerName = @"weekdayEventsScroll";

static NSString* const _WLDayLayerName = @"weekdayEvents";

static NSString* const _WLTimeIndicatorRootLayerName = @"timeIndicatorRoot";

static NSString* const _WLTimeIndicatorLayerName = @"timeIndicator";


static const CGFloat _WLYMarginBetweenAllDayAndWeekdayEvents = 10.0f;

static const CGFloat _WLXMarginBetweenColumns = 10.0f;

static const CGFloat _WLWeekdayEventsTitleLayerHeight = 25.0f;


BOOL WLHourRangeEqualToHourRange(WLHourRange l, WLHourRange r)
{
    return (l.startHour == r.startHour || fabsf(l.startHour - r.startHour) < FLT_EPSILON) &&
            (l.endHour == r.endHour || fabsf(l.endHour - r.endHour) < FLT_EPSILON);
}


@implementation WLCalendarWeekView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        indexOfHighlightedColumn = NSNotFound;
        minimumHeightOfAllDayEventsPartOfColumn = 100.0f;
        _columnLayers = [[NSMutableArray alloc] init];
        showTimeIndicator = YES;
        minimumHeightOfHour = 20.0f;
        maximumHeightOfHour = 100.0f;
    }
    return self;
}

- (void)dealloc
{
    [_columnLayers release];
    [super dealloc];
}


#pragma mark Properties
@synthesize dataSource;
@synthesize minimumHeightOfAllDayEventsPartOfColumn;
@synthesize showTimeIndicator;
@synthesize fitDayEvents;
@synthesize minimumHeightOfHour;
@synthesize maximumHeightOfHour;
@synthesize indexOfHighlightedColumn;

- (void)setIndexOfHighlightedColumn:(NSUInteger)newIndexOfHighlightedColumn
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    indexOfHighlightedColumn = newIndexOfHighlightedColumn;
    if ([self wantsLayer])
    {
        [_columnLayers enumerateObjectsUsingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop) {
            if (indexOfHighlightedColumn == NSNotFound)
                l.opacity = 1.0f;
            else if (indexOfHighlightedColumn == idx)
                l.opacity = 1.0f;
            else
                l.opacity = 0.5f;
        }];
    }
}

- (void)setShowTimeIndicator:(BOOL)newShowTimeIndicator
{
    showTimeIndicator = newShowTimeIndicator;
    _timeIndicatorRootLayer.hidden = !showTimeIndicator;
}

- (void)setFitDayEvents:(BOOL)newFitDayEvents
{
    fitDayEvents = newFitDayEvents;
    if ([self wantsLayer])
    {
        if (fitDayEvents)
            [self heightOfHourMayHaveChanged];
        else
            [self _focusOnHour];
    }
}


#pragma mark Methods

- (void)createLayers
{
    NSParameterAssert(![self wantsLayer]);

    _rootLayer = [self setupRootLayer];
    _rootLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

    _timeIndicatorRootLayer = [self setupTimeIndicatorRootLayer];
    _timeIndicatorRootLayer.hidden = !showTimeIndicator;
    [_rootLayer addSublayer:_timeIndicatorRootLayer];

    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    for (NSUInteger i=0, size=numberOfColumns; i<size; ++i)
    {
        CALayer *c = [self setupColumnRootLayer];
        [_columnLayers addObject:c];
        [_rootLayer insertSublayer:c below:_timeIndicatorRootLayer];
    }

    _timeRulerRootLayer = [self setupTimeRulerRootLayer];
    [_rootLayer addSublayer:_timeRulerRootLayer];

    [self setLayer:_rootLayer];
    [self setWantsLayer:YES];

    [self _updateTimeRuler];
    [self _updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];
}

- (void)reloadDataAnimated:(BOOL)isAnimated
{
    NSParameterAssert([self wantsLayer]);
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    NSUInteger currentNumberOfColumns = [_columnLayers count];
    if (currentNumberOfColumns < numberOfColumns)
    {
        for (NSUInteger i=0, size=numberOfColumns-currentNumberOfColumns; i<size; ++i)
        {
            CALayer *column = [self setupColumnRootLayer];
            [_columnLayers addObject:column];
            [_rootLayer insertSublayer:column below:_timeIndicatorRootLayer];
        }
    }
    else if (currentNumberOfColumns > numberOfColumns)
    {
        for (NSUInteger i=0, size=currentNumberOfColumns-numberOfColumns; i<size; ++i)
        {
            CALayer *column = [_columnLayers lastObject];
            [column removeFromSuperlayer];
            [_columnLayers removeLastObject];
        }
    }
    [self _updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];
    [self _updateTimeRuler];
    [_rootLayer setNeedsLayout];
    [CATransaction commit];
}

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated
{
    _hour = aHour;

    if (![self wantsLayer])
        return; // There is nothing to scroll.

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    if (!self.fitDayEvents)
        [self _focusOnHour];
    // Scroll timeRuler and columns before positioning timeIndicator, since its position is relative to them.
    [self _layoutTimeIndicatorLayer:[_timeIndicatorRootLayer WL_timeIndicatorLayer]];
    [CATransaction commit];
}

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    [self _updateEventsOfColumnsAtIndexes:anIndexSet];
    [self heightOfHourMayHaveChanged];
}

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    [self _updateTitleOfColumnsAtIndexes:anIndexSet];
}

- (void)updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    [self _updateColorOfColumnsAtIndexes:anIndexSet];
}

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    [self _updateColumnsAtIndexes:anIndexSet];
    [self heightOfHourMayHaveChanged];
}

- (void)showNextDay
{
    [self showNextDays:1];
}

- (void)showNextWeek
{
    [self showNextDays:[dataSource numberOfColumnsInWeekView:self]];
}

- (void)showNextDays:(NSUInteger)aNumberOfDays
{
    if ([self wantsLayer] && [_columnLayers count] > 0)
    {
        [CATransaction begin];
        [CATransaction setAnimationDuration:5];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

        [CATransaction setDisableActions:YES];
        NSArray *old = [_columnLayers subarrayWithRange:NSMakeRange(0, MIN(aNumberOfDays, [_columnLayers count]))];
        [CATransaction setCompletionBlock:^{
            [CATransaction setDisableActions:YES];
            [old makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        }];
        [_columnLayers removeObjectsInRange:NSMakeRange(0, [old count])];
        for (NSUInteger i=0; i<aNumberOfDays; ++i)
        {
            CALayer *c = [self setupColumnRootLayer];
            [_columnLayers addObject:c];
            [_rootLayer insertSublayer:c below:_timeIndicatorRootLayer];
        }
        NSIndexSet *newColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:
                                        NSMakeRange([_columnLayers count] - aNumberOfDays, aNumberOfDays)];
        [self _updateColumnsAtIndexes:newColumnIndexes];

        [_columnLayers enumerateObjectsUsingBlock:^(CALayer *c, NSUInteger idx, BOOL *stop)
        {
            [CATransaction setDisableActions:YES];
            [self _layoutColumnLayer:c atIndex:idx];
            [CATransaction setDisableActions:NO];
            CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            [positionAnimation setFromValue:
             [NSNumber numberWithFloat:c.position.x + MIN(aNumberOfDays, [old count]) * (c.bounds.size.width + _WLXMarginBetweenColumns)]];
            [positionAnimation setToValue:[NSNumber numberWithFloat:c.position.x]];
            [c addAnimation:positionAnimation forKey:@"position.x"];
        }];

        [CATransaction setDisableActions:NO];
        NSUInteger numberOfOldColumns = [old count];
        [old enumerateObjectsUsingBlock:^(CALayer *c, NSUInteger idx, BOOL *stop)
        {
            [c setValue:[NSNumber numberWithFloat:c.position.x - numberOfOldColumns * (c.bounds.size.width + _WLXMarginBetweenColumns)]
             forKeyPath:@"position.x"];
            c.opacity = 0.0f;
        }];
        [CATransaction commit];
    }
}

- (void)stopAnimations
{
    for (CALayer *c in _columnLayers)
        [[c WL_dayScrollLayer] removeAllAnimations];
    [[_timeRulerRootLayer WL_timeRulerScrollLayer] removeAllAnimations];
    [[_timeIndicatorRootLayer WL_timeIndicatorLayer] removeAllAnimations];
}

- (WLHourRange)eventsHourRange
{
    WLHourRange r = {CGFLOAT_MAX, 0.0f};
    BOOL areThereEvents = NO;
    for (WLCalendarDayEventsLayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
    {
        WLDateRange *columnRange = [l eventsDateRange];
        if (columnRange != nil)
        {
            r.startHour = fminf(r.startHour, [self hourForDate:columnRange.startDate]);
            r.endHour = fmaxf(r.endHour, [self hourForDate:columnRange.endDate]);
            areThereEvents = YES;
        }
    }
    if (areThereEvents)
        return r;
    else
        return WLHourRangeZero;
}

- (void)heightOfHourMayHaveChanged
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    [self _layoutTimeRulerLayer:[_timeRulerRootLayer WL_timeRulerLayer]];
    for (CALayer *c in _columnLayers)
        [self _layoutDayLayer:[c WL_dayLayer]];
    if (self.fitDayEvents)
        [self _focusOnDayEvents];
    else
        [self _focusOnHour];
    // Scroll timeRuler and columns before positioning timeIndicator, since its position is relative to them.
    [self _layoutTimeIndicatorLayer:[_timeIndicatorRootLayer WL_timeIndicatorLayer]];
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLRootLayerName]);

    [CATransaction WL_performWithDisabledActions:^(void) {
        [self _layoutTimeRulerRootLayer:_timeRulerRootLayer];
        [_columnLayers enumerateObjectsUsingBlock:^(CALayer *column, NSUInteger idx, BOOL *stop)
        {
            [self _layoutColumnLayer:column atIndex:idx];
            [self _layoutSublayersOfColumnLayer:column];
        }];
    }];
    [self _layoutTimeIndicatorRootLayer:_timeIndicatorRootLayer];
    [self heightOfHourMayHaveChanged];
}


#pragma mark WLCalendarTimeRuler

- (NSUInteger)numberOfHours
{
    return [dataSource numberOfHoursInWeekView:self];
}

- (CGFloat)heightOfHour
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");
    NSParameterAssert([_columnLayers count] > 0);
    NSParameterAssert(self.minimumHeightOfHour <= self.maximumHeightOfHour);

    CGFloat heightOfDayPartOfColumn = [[[_columnLayers objectAtIndex:0] WL_dayScrollLayer] bounds].size.height;
    if (self.fitDayEvents)
    {
        WLHourRange r = [self eventsHourRange];
        return fminf(self.maximumHeightOfHour, fmaxf(self.minimumHeightOfHour, heightOfDayPartOfColumn / (r.endHour - r.startHour)));
    }
    else
        return fminf(self.maximumHeightOfHour, fmaxf(self.minimumHeightOfHour, heightOfDayPartOfColumn / [self numberOfHours]));
}

- (CGFloat)hourForDate:(NSDate *)aDate
{
    return [dataSource weekView:self convertDateToHour:aDate];
}


#pragma mark Private

- (void)_updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    if ([dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [dataSource weekView:self
              willAskForData:WLCalendarWeekViewEventsDataUnit
         forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
     {
         [self _updateEventsOfColumnAtIndex:idx];
     }];
    if ([dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [dataSource weekViewDidAskForData:self];
}

- (void)_updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    if ([dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [dataSource weekView:self
              willAskForData:WLCalendarWeekViewTitleDataUnit
         forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
     {
         [self _updateTitleOfColumnAtIndex:idx];
     }];
    if ([dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [dataSource weekViewDidAskForData:self];
}

- (void)_updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    if ([dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [dataSource weekView:self
              willAskForData:WLCalendarWeekViewColorDataUnit
         forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
     {
         [self _updateColorOfColumnAtIndex:idx];
     }];
    if ([dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [dataSource weekViewDidAskForData:self];
}

- (void)_updateColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    if ([dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [dataSource weekView:self
              willAskForData:WLCalendarWeekViewTitleDataUnit | WLCalendarWeekViewEventsDataUnit | WLCalendarWeekViewColorDataUnit
         forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
     {
         [self _updateColumnAtIndex:idx];
     }];
    if ([dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [dataSource weekViewDidAskForData:self];
}

- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    NSMutableArray *columnEvents = [[dataSource weekView:self eventsForColumnAtIndex:anIndex] mutableCopy];
    NSArray *allDayEvents = [columnEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isAllDay == YES"]];
    for (id event in allDayEvents)
        [columnEvents removeObjectIdenticalTo:event];

    CALayer *column = [_columnLayers objectAtIndex:anIndex];
    WLCalendarDayEventsLayer *day = [column WL_dayLayer];
    [day setEvents:[NSSet setWithArray:columnEvents]];
    [day setNeedsLayout];
    [columnEvents release];
    WLCalendarAllDayEventsLayer *allDay = [column WL_allDayLayer];
    [allDay setEvents:allDayEvents];
    [allDay setNeedsLayout];
}

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    CALayer *column = [_columnLayers objectAtIndex:anIndex];
    CATextLayer *title = [column WL_titleLayer];
    title.string = [dataSource weekView:self titleForColumnAtIndex:anIndex];
}

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    if ([dataSource respondsToSelector:@selector(weekView:colorForColumnAtIndex:)])
    {
        CALayer *column = [_columnLayers objectAtIndex:anIndex];
        WLCalendarBackgroundLayer *dayBackground = [column WL_dayBackgroundLayer];
        WLCalendarBackgroundLayer *allDayBackground = [column WL_allDayBackgroundLayer];
        CGColorRef c = [dataSource weekView:self colorForColumnAtIndex:anIndex];
        dayBackground.contentsBackgroundColor = c;
        allDayBackground.contentsBackgroundColor = c;
    }
}

- (void)_updateColumnAtIndex:(NSUInteger)anIndex
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    [self _updateEventsOfColumnAtIndex:anIndex];
    [self _updateTitleOfColumnAtIndex:anIndex];
    [CATransaction WL_performWithDisabledActions:^{
        [self _updateColorOfColumnAtIndex:anIndex];
    }];
}

- (void)_updateTimeRuler
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    NSUInteger numberOfHours = [self numberOfHours];
    NSMutableArray *h = [NSMutableArray arrayWithCapacity:numberOfHours];
    for (NSUInteger i=0; i<numberOfHours; ++i)
        [h addObject:[dataSource weekView:self stringForHour:i]];
    [[_timeRulerRootLayer WL_timeRulerLayer] setHours:h];
}

- (void)_layoutTimeRulerRootLayer:(CALayer *)aRootLayer
{
    CAScrollLayer *timeRulerScrollLayer = [aRootLayer WL_timeRulerScrollLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [aRootLayer WL_timeRulerLayer];
    CGFloat timeRulerWidth = [timeRulerLayer preferredFrameWidth];
    aRootLayer.frame = CGRectMake(0.0f,
                                  0.0f,
                                  timeRulerWidth,
                                  self.bounds.size.height - self.minimumHeightOfAllDayEventsPartOfColumn - _WLYMarginBetweenAllDayAndWeekdayEvents);
    [timeRulerScrollLayer setValue:[NSNumber numberWithFloat:aRootLayer.bounds.size.height - _WLWeekdayEventsTitleLayerHeight]
                        forKeyPath:@"frame.size.height"];
}

- (void)_layoutTimeRulerLayer:(WLCalendarTimeRulerLayer *)aTimeRulerLayer
{
    CGSize timeRulerSize = [aTimeRulerLayer preferredFrameSize];
    [aTimeRulerLayer setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];
}

- (void)_layoutColumnLayer:(CALayer *)aColumnLayer atIndex:(NSUInteger)anIndex
{
    NSRect bounds = [self bounds];
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer WL_timeRulerLayer];
    CGFloat timeRulerWidth = [timeRulerLayer preferredFrameWidth];
    CGFloat sumOfXMarginsBetweenColumns = _WLXMarginBetweenColumns * ([_columnLayers count] + 1);
    CGFloat columnWidth = (bounds.size.width - timeRulerWidth - sumOfXMarginsBetweenColumns) / [_columnLayers count];
    CGFloat x = timeRulerWidth + _WLXMarginBetweenColumns + anIndex * (columnWidth + _WLXMarginBetweenColumns);
    aColumnLayer.frame = CGRectIntegral(CGRectMake(x, 0.0f, columnWidth, bounds.size.height));
}

- (void)_layoutSublayersOfColumnLayer:(CALayer *)aColumnLayer
{
    CALayer *allDayBackground = [aColumnLayer WL_allDayBackgroundLayer];
    allDayBackground.frame = CGRectIntegral(CGRectMake(aColumnLayer.bounds.origin.x,
                                                       aColumnLayer.bounds.origin.y,
                                                       aColumnLayer.bounds.size.width,
            minimumHeightOfAllDayEventsPartOfColumn));

    CALayer *dayBackground = [aColumnLayer WL_dayBackgroundLayer];
    dayBackground.frame = CGRectIntegral(CGRectMake(aColumnLayer.bounds.origin.x,
                                                    CGRectGetMaxY(allDayBackground.frame) + _WLYMarginBetweenAllDayAndWeekdayEvents,
                                                    aColumnLayer.bounds.size.width,
                                                    aColumnLayer.bounds.size.height - CGRectGetMaxY(allDayBackground.frame) - _WLYMarginBetweenAllDayAndWeekdayEvents));

    CATextLayer *title = [aColumnLayer WL_titleLayer];
    title.frame = CGRectIntegral(CGRectMake(dayBackground.bounds.origin.x,
                                            dayBackground.bounds.origin.y,
                                            dayBackground.bounds.size.width,
                                            _WLWeekdayEventsTitleLayerHeight));

    CAScrollLayer *dayScroll = [aColumnLayer WL_dayScrollLayer];
    WLCalendarTimeRulerLayer *timeRuler = [_timeRulerRootLayer WL_timeRulerLayer];
    dayScroll.frame = CGRectIntegral(CGRectMake(dayBackground.bounds.origin.x,
                                                CGRectGetMaxY(title.bounds) + [timeRuler firstHourYPadding],
                                                dayBackground.bounds.size.width,
                                                dayBackground.bounds.size.height - CGRectGetMaxY(title.bounds) - [timeRuler firstHourYPadding]));
}

- (void)_layoutDayLayer:(WLCalendarDayEventsLayer *)aDayLayer
{
    CGSize timeRulerSize = [[_timeRulerRootLayer WL_timeRulerLayer] preferredFrameSize];
    [aDayLayer setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];
}

- (void)_layoutTimeIndicatorRootLayer:(WLCalendarTimeIndicatorLayer *)aTimeIndicatorLayer
{
    // All day scroll layers have same size.
    CALayer *dayScroll = [[_columnLayers lastObject] WL_dayScrollLayer];
    _timeIndicatorRootLayer.frame = CGRectMake(_timeRulerRootLayer.frame.size.width,
                                           _timeRulerRootLayer.frame.origin.y,
                                           _rootLayer.bounds.size.width - _timeRulerRootLayer.frame.size.width,
                                           dayScroll.frame.size.height);
}

- (void)_layoutTimeIndicatorLayer:(WLCalendarTimeIndicatorLayer *)aTimeIndicatorLayer
{
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer WL_timeRulerLayer];
    CGPoint hourPoint = [timeRulerLayer pointForHour:_hour];
    CGPoint newTimeIndicatorPoint = [_timeIndicatorRootLayer convertPoint:hourPoint fromLayer:timeRulerLayer];
    [aTimeIndicatorLayer setValue:[NSNumber numberWithFloat:floorf(newTimeIndicatorPoint.y)] forKeyPath:@"position.y"];
}

- (void)_focusOnDayEvents
{
    WLHourRange r = [self eventsHourRange];
    if (WLHourRangeEqualToHourRange(r, WLHourRangeZero))
    {
        [self _focusOnHour]; // No events to focus. Better focus on current hour rather than 0:00.
        return;
    }

    CAScrollLayer *timeRulerScrollLayer = [_timeRulerRootLayer WL_timeRulerScrollLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer WL_timeRulerLayer];
    CGFloat m = r.startHour + (r.endHour - r.startHour) / 2;
    CGPoint newScrollPoint = [timeRulerLayer pointForHour:m];

    // Center _hour whenever possible
    CGFloat visibleHeight = timeRulerScrollLayer.bounds.size.height;
    newScrollPoint = CGPointMake(0.0f, floorf(newScrollPoint.y - visibleHeight / 2));
    CGFloat topLimit = CGRectGetMinY(timeRulerLayer.bounds);
    CGFloat bottomLimit = CGRectGetMaxY(timeRulerLayer.bounds) - visibleHeight;
    newScrollPoint.y = floorf(fminf(fmaxf(newScrollPoint.y, topLimit), bottomLimit));

    [timeRulerLayer scrollPoint:newScrollPoint];
    for (CALayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
        [l scrollPoint:newScrollPoint];
}

- (void)_focusOnHour
{
    CAScrollLayer *timeRulerScrollLayer = [_timeRulerRootLayer WL_timeRulerScrollLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer WL_timeRulerLayer];
    CGPoint newScrollPoint = [timeRulerLayer pointForHour:_hour];

    // Center _hour whenever possible
    CGFloat visibleHeight = timeRulerScrollLayer.bounds.size.height;
    newScrollPoint = CGPointMake(0.0f, floorf(newScrollPoint.y - visibleHeight / 2));
    CGFloat topLimit = CGRectGetMinY(timeRulerLayer.bounds);
    CGFloat bottomLimit = CGRectGetMaxY(timeRulerLayer.bounds) - visibleHeight;
    newScrollPoint.y = floorf(fminf(fmaxf(newScrollPoint.y, topLimit), bottomLimit));

    [timeRulerLayer scrollPoint:newScrollPoint];
    for (CALayer *l in [_columnLayers valueForKey:@"WL_dayScrollLayer"])
        [l scrollPoint:newScrollPoint];
}


#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [self stopAnimations];
    [super setFrameSize:newSize];
}

@end


#pragma mark -

@implementation WLCalendarWeekView (SetupLayers)

- (CALayer *)setupRootLayer
{
    __block CALayer *l = [CALayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLRootLayerName;
        l.masksToBounds = YES;
        l.layoutManager = self;
    }];
    return l;
}


#pragma mark Time Ruler

/*
 +--+ +--+ +--+
 |  | |  | |  |
 |  | |  | |  |
 |  | |  | |  |
 |  | |  | |  |
 |b | |s | |t |
 |a | |c | |i |
 |c | |r | |m |
 |k | |o | |e |
 |g | |l | |  |
 |r | |l | |r |
 |o | |  | |u |
 |u | |  | |l |
 |n | |  | |e |
 |d | |  | |r |
 |  | |  | |  |
 +--+ +--+ +--+

 <--depth-----+
 */

- (CALayer *)setupTimeRulerRootLayer
{
    __block WLCalendarBackgroundLayer *timeRulerBackground = [self setupTimeRulerBackgroundLayer];
    [CATransaction WL_performWithDisabledActions:^{
        CAScrollLayer *timeRulerScroll = [self setupTimeRulerScrollLayer];
        timeRulerScroll.autoresizingMask = kCALayerWidthSizable;
        [timeRulerBackground addSublayer:timeRulerScroll];
        [timeRulerBackground setValue:timeRulerScroll forKey:timeRulerScroll.name];

        WLCalendarTimeRulerLayer *timeRuler = [self setupTimeRulerLayer];
        timeRuler.autoresizingMask = kCALayerWidthSizable;
        [timeRulerScroll addSublayer:timeRuler];
        [timeRulerScroll setValue:timeRuler forKey:timeRuler.name];
    }];
    return timeRulerBackground;
}

- (WLCalendarBackgroundLayer *)setupTimeRulerBackgroundLayer
{
    __block WLCalendarBackgroundLayer *l = [WLCalendarBackgroundLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLTimeRulerBackgroundLayerName;
        l.masksToBounds = YES;
        l.needsDisplayOnBoundsChange = YES;
        l.contentsBackgroundOpacity = 0.15;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    }];
    return l;
}

- (CAScrollLayer *)setupTimeRulerScrollLayer
{
    __block CAScrollLayer *l = [CAScrollLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLTimeRulerScrollLayerName;
        l.scrollMode = kCAScrollVertically;
        l.geometryFlipped = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    }];
    return l;
}

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer
{
    __block WLCalendarTimeRulerLayer *l = [WLCalendarTimeRulerLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLTimeRulerLayerName;
        l.timeRuler = self;
    }];
    return l;
}


#pragma mark Column

/*
+---------+ +---------+ +---------+
|         | |         | |         |
|         | | back    | | all-day |
|         | | ground  | | events  |
|         | |         | |         |
| content | |         | |         |
|         | |         | |         |
|         | +---------+ +---------+
|         | +---------+ +---------+
|         | | back    | | title   |
|         | | ground  | +---------+
|         | |         | +---------+ +---------+
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | | scroll  | | day     |
|         | |         | |         | | events  |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
|         | |         | |         | |         |
+---------+ +---------+ +---------+ +---------+

<--depth----------------------------------------
*/

- (CALayer *)setupColumnRootLayer
{
    __block CALayer *root = [self setupColumnLayer];
    [CATransaction WL_performWithDisabledActions:^{
        WLCalendarBackgroundLayer *allDayBackground = [self setupAllDayBackgroundLayer];
        [root addSublayer:allDayBackground];
        [root setValue:allDayBackground forKey:allDayBackground.name];

        WLCalendarAllDayEventsLayer *allDay = [self setupAllDayLayer];
        allDay.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        [allDayBackground addSublayer:allDay];
        [allDayBackground setValue:allDay forKey:allDay.name];

        WLCalendarBackgroundLayer *dayBackground = [self setupDayBackgroundLayer];
        [root addSublayer:dayBackground];
        [root setValue:dayBackground forKey:dayBackground.name];

        CATextLayer *title = [self setupDayTitleLayer];
        [dayBackground addSublayer:title];
        [dayBackground setValue:title forKey:title.name];

        CAScrollLayer *scroll = [self setupDayScrollLayer];
        [dayBackground addSublayer:scroll];
        [dayBackground setValue:scroll forKey:scroll.name];

        WLCalendarDayEventsLayer *day = [self setupDayLayer];
        day.autoresizingMask = kCALayerWidthSizable;
        [scroll addSublayer:day];
        [scroll setValue:day forKey:day.name];
    }];
    return root;
}

- (CALayer *)setupColumnLayer
{
    __block CALayer *l = [CALayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.geometryFlipped = YES;
        l.name = _WLColumnLayerName;
        l.masksToBounds = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor redColor] WL_CGColor];
#endif
    }];
    return l;
}

- (WLCalendarBackgroundLayer *)setupAllDayBackgroundLayer
{
    __block WLCalendarBackgroundLayer *l = [WLCalendarBackgroundLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLAllDayBackgroundLayerName;
        l.needsDisplayOnBoundsChange = YES;
        l.contentsBackgroundOpacity = 0.15f;

#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    }];
    return l;
}

- (WLCalendarAllDayEventsLayer *)setupAllDayLayer
{
    __block WLCalendarAllDayEventsLayer *l = [WLCalendarAllDayEventsLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLAllDayLayerName;
    }];
    return l;
}

- (WLCalendarDayEventsLayer *)setupDayLayer
{
    __block WLCalendarDayEventsLayer *l = [WLCalendarDayEventsLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
#ifdef DEBUG_LAYERS
        l.needsDisplayOnBoundsChange = YES;
#endif
        l.name = _WLDayLayerName;
        l.timeRuler = self;
    }];
    return l;
}

- (CAScrollLayer *)setupDayScrollLayer
{
    __block CAScrollLayer *l = [CAScrollLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLDayScrollLayerName;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor purpleColor] WL_CGColor];
#endif
    }];
    return l;
}

- (CATextLayer *)setupDayTitleLayer
{
    CATextLayer *l = [CATextLayer layer];
    l.name = _WLTitleLayerName;
    l.wrapped = NO;
    l.truncationMode = kCATruncationNone;
    l.alignmentMode = kCAAlignmentCenter;
    l.fontSize = 14.0f;
//    l.shadowOpacity = 1.0f;
//    l.shadowOffset = CGSizeMake(0.0f, -1.0f);
//    l.shadowRadius = 1.0f;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    return l;
}

- (WLCalendarBackgroundLayer *)setupDayBackgroundLayer
{
    __block WLCalendarBackgroundLayer *l = [WLCalendarBackgroundLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLDayBackgroundLayerName;
        l.needsDisplayOnBoundsChange = YES;
        l.contentsBackgroundOpacity = 0.3f;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    }];
    return l;
}


#pragma mark Time Indicator

/*
 +---------+ +---------+
 |         | |         |
 |         | |         |
 |         | |         |
 |         | |         |
 | root    | |indicator|
 |         | |         |
 |         | |         |
 |         | |         |
 +---------+ +---------+

 <--depth---------------------------
 */

- (CALayer *)setupTimeIndicatorRootLayer
{
    CALayer *l = [CALayer layer];
    [CATransaction WL_performWithDisabledActions:^(void) {
        l.name = _WLTimeIndicatorRootLayerName;
        l.masksToBounds = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor magentaColor] WL_CGColor];
        l.opacity = 0.3f;
#endif
        WLCalendarTimeIndicatorLayer *timeIndicator = [self setupTimeIndicatorLayer];
        timeIndicator.frame = CGRectMake(0.0f, 0.0f, 0.0f, 2.0f);
        timeIndicator.autoresizingMask = kCALayerWidthSizable;
        [l addSublayer:timeIndicator];
        [l setValue:timeIndicator forKey:timeIndicator.name];
    }];
    return l;
}

- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer
{
    __block WLCalendarTimeIndicatorLayer *l = [WLCalendarTimeIndicatorLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.name = _WLTimeIndicatorLayerName;
        l.anchorPoint = CGPointMake(0.0f, 0.5f);
        l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor whiteColor] WL_CGColor];
#endif
    }];
    return l;
}

@end


@implementation CALayer (WLCalendarWeekView)

- (WLCalendarBackgroundLayer *)WL_allDayBackgroundLayer
{
    NSParameterAssert([self.name isEqual:_WLColumnLayerName]);
    return [self valueForKey:_WLAllDayBackgroundLayerName];
}

- (WLCalendarAllDayEventsLayer *)WL_allDayLayer
{
    return [[self WL_allDayBackgroundLayer] valueForKey:_WLAllDayLayerName];
}

- (WLCalendarBackgroundLayer *)WL_dayBackgroundLayer
{
    NSParameterAssert([self.name isEqual:_WLColumnLayerName]);
    return [self valueForKey:_WLDayBackgroundLayerName];
}

- (CAScrollLayer *)WL_dayScrollLayer
{
    return [[self WL_dayBackgroundLayer] valueForKey:_WLDayScrollLayerName];
}

- (WLCalendarDayEventsLayer *)WL_dayLayer
{
    return [[self WL_dayScrollLayer] valueForKey:_WLDayLayerName];
}

- (CATextLayer *)WL_titleLayer
{
    return [[self WL_dayBackgroundLayer] valueForKey:_WLTitleLayerName];
}

- (CAScrollLayer *)WL_timeRulerScrollLayer
{
    NSParameterAssert([self.name isEqual:_WLTimeRulerBackgroundLayerName]);
    return [self valueForKey:_WLTimeRulerScrollLayerName];
}

- (WLCalendarTimeRulerLayer *)WL_timeRulerLayer
{
    return [[self WL_timeRulerScrollLayer] valueForKey:_WLTimeRulerLayerName];
}

- (WLCalendarTimeIndicatorLayer *)WL_timeIndicatorLayer
{
    NSParameterAssert([self.name isEqual:_WLTimeIndicatorRootLayerName]);
    return [self valueForKey:_WLTimeIndicatorLayerName];
}

@end

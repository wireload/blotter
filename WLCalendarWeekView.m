//
//  WLCalendarWeekView.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWeekView.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


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

static NSString* const _WLDayScrollLayerName = @"weekdayEventsScroll";

static NSString* const _WLDayLayerName = @"weekdayEvents";

static NSString* const _WLTimeIndicatorRootLayerName = @"timeIndicatorRoot";

static NSString* const _WLTimeIndicatorLayerName = @"timeIndicator";


static NSString* const _WLDayBackgroundLayerTitleKey = @"title";

static NSString* const _WLDayBackgroundLayerShouldHighlightTitleKey = @"highlight";


static const NSInteger _WLDayBackgroundTitleAttributes = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine;


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
        heightOfAllDayPartOfColumn = 114.0f;
        _columnLayers = [[NSMutableArray alloc] init];
        showTimeIndicator = YES;
        showTitle = YES;
        showAllDayEvents = YES;
        rangeOfAlwaysVisibleHours = (WLHourRange){.startHour = 9.0f, .endHour = 17.0f};
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
@synthesize heightOfAllDayPartOfColumn;
@synthesize showTimeIndicator;
@synthesize fitDayEvents;
@synthesize indexOfHighlightedColumn;
@synthesize showAllDayEvents;
@synthesize showTitle;
@synthesize rangeOfAlwaysVisibleHours;

- (void)setIndexOfHighlightedColumn:(NSUInteger)newIndexOfHighlightedColumn
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    indexOfHighlightedColumn = newIndexOfHighlightedColumn;
    if ([self wantsLayer])
    {
        [[_columnLayers valueForKey:@"WL_dayBackgroundLayer"] enumerateObjectsUsingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop) {
            [l setValue:[NSNumber numberWithBool:(idx == indexOfHighlightedColumn)] forKey:_WLDayBackgroundLayerShouldHighlightTitleKey];
            [l setNeedsDisplay];
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
        {
            for (WLCalendarDayEventsLayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
                l.keepTextOfEventsVisible = NO;
            [_timeRulerRootLayer WL_timeRulerLayer].shouldHideHalfVisibleHourLabels = YES;
            [self heightOfHourMayHaveChanged];
        }
        else
        {
            for (WLCalendarDayEventsLayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
                l.keepTextOfEventsVisible = YES;
            [_timeRulerRootLayer WL_timeRulerLayer].shouldHideHalfVisibleHourLabels = NO;
            [self _focusOnHour];
        }
    }
}

- (void)setShowAllDayEvents:(BOOL)newShowAllDayEvents
{
    showAllDayEvents = newShowAllDayEvents;
    if ([self wantsLayer])
        [_rootLayer setNeedsLayout];
}

- (void)setShowTitle:(BOOL)newShowTitle
{
    showTitle = newShowTitle;
    if ([self wantsLayer])
        [_rootLayer setNeedsLayout];
}

- (void)setRangeOfAlwaysVisibleHours:(WLHourRange)newHourRange
{
    rangeOfAlwaysVisibleHours = newHourRange;
    if ([self wantsLayer] && self.fitDayEvents)
        [self heightOfHourMayHaveChanged];
}


#pragma mark Methods

- (void)createLayers
{
    NSParameterAssert(![self wantsLayer]);

    _rootLayer = [self setupRootLayer];
    [self setLayer:_rootLayer];
    [self setWantsLayer:YES];

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
    if (self.fitDayEvents)
        [_timeRulerRootLayer WL_timeRulerLayer].shouldHideHalfVisibleHourLabels = YES;
    [_rootLayer addSublayer:_timeRulerRootLayer];

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
    [self layoutTimeIndicatorLayer];
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
            CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            [CATransaction setDisableActions:YES];
            CGRect fromFrame = [self columnFrameAtIndex:idx + MIN(aNumberOfDays, [old count])];
            [positionAnimation setFromValue:[NSNumber numberWithFloat:fromFrame.origin.x]];
            [self layoutColumnLayer:c atIndex:idx];
            [positionAnimation setToValue:[NSNumber numberWithFloat:c.position.x]];
            [c addAnimation:positionAnimation forKey:@"position.x"];
        }];

        [CATransaction setDisableActions:NO];
        NSUInteger numberOfOldColumns = [old count];
        [old enumerateObjectsUsingBlock:^(CALayer *c, NSUInteger idx, BOOL *stop)
        {
            [c setValue:[NSNumber numberWithFloat:[self columnFrameAtIndex:idx - numberOfOldColumns].origin.x] forKeyPath:@"position.x"];
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

- (WLHourRange)rangeOfVisibleHours
{
    WLHourRange r = self.rangeOfAlwaysVisibleHours;
    for (WLCalendarDayEventsLayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
    {
        WLDateRange *columnRange = [l eventsDateRange];
        if (columnRange != nil)
        {
            r.startHour = fminf(r.startHour, [self hourForDate:columnRange.startDate]);
            r.endHour = fmaxf(r.endHour, [self hourForDate:columnRange.endDate]);
        }
    }
    return r;
}

- (void)heightOfHourMayHaveChanged
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    [self layoutTimeRulerLayer:[_timeRulerRootLayer WL_timeRulerLayer]];
    for (CALayer *c in _columnLayers)
        [self layoutDayLayer:[c WL_dayLayer]];
    if (self.fitDayEvents)
        [self _focusOnDayEvents];
    else
        [self _focusOnHour];
    // Scroll timeRuler and columns before positioning timeIndicator, since its position is relative to them.
    [self layoutTimeIndicatorLayer];
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    NSParameterAssert([aLayer.name isEqualToString:_WLRootLayerName]);

    [CATransaction WL_performWithDisabledActions:^(void) {
        [self layoutTimeRulerRoot];
        [self layoutColumnLayers];
    }];
    [self layoutTimeIndicatorRootLayer];
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

    if (self.fitDayEvents)
    {
        WLHourRange r = [self rangeOfVisibleHours];
        CGFloat endHour = ceilf(r.endHour);
        return ([self dayScrollFrame].size.height) / (endHour - floorf(r.startHour));
    }
    else
        return fmaxf([self dayScrollFrame].size.height / [self numberOfHours], 40.0f);
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
        NSUInteger data = 0;
        if (self.showTitle)
            data = WLCalendarWeekViewTitleDataUnit | WLCalendarWeekViewEventsDataUnit | WLCalendarWeekViewColorDataUnit;
        else
            data = WLCalendarWeekViewEventsDataUnit | WLCalendarWeekViewColorDataUnit;
        [dataSource weekView:self
              willAskForData:data
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

    CALayer *l = [[_columnLayers objectAtIndex:anIndex] WL_dayBackgroundLayer];
    [l setValue:[dataSource weekView:self titleForColumnAtIndex:anIndex] forKey:_WLDayBackgroundLayerTitleKey];
    [l setNeedsDisplay];
}

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex
{
//    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");
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

- (void)_updateColumnAtIndex:(NSUInteger)anIndex
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");

    [self _updateEventsOfColumnAtIndex:anIndex];
    if (self.showTitle)
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

- (void)_focusOnDayEvents
{
    WLHourRange r = [self rangeOfVisibleHours];
    if (WLHourRangeEqualToHourRange(r, WLHourRangeZero))
    {
        [self _focusOnHour]; // No events to focus. Better focus on current hour rather than 0:00.
        return;
    }

    WLCalendarTimeRulerLayer *timeRuler = [_timeRulerRootLayer WL_timeRulerLayer];
    CGPoint scrollPoint = [timeRuler pointForHour:floorf(r.startHour)];
    scrollPoint.y -= [timeRuler hourLabelYPadding];
    scrollPoint.x = floorf(scrollPoint.x);
    scrollPoint.y = floorf(scrollPoint.y);
    for (WLCalendarDayEventsLayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
        [l scrollPoint:scrollPoint];
    [timeRuler scrollPoint:scrollPoint];
}

- (void)_focusOnHour
{
    CAScrollLayer *timeRulerScrollLayer = [_timeRulerRootLayer WL_timeRulerScrollLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer WL_timeRulerLayer];
    CGPoint newScrollPoint = [timeRulerLayer pointForHour:_hour];

    // Center _hour whenever possible
    CGFloat visibleHeight = timeRulerScrollLayer.bounds.size.height;
    newScrollPoint = CGPointMake(0.0f, floorf(newScrollPoint.y - visibleHeight / 2.0));
    CGFloat topLimit = CGRectGetMinY(timeRulerLayer.bounds);
    CGFloat bottomLimit = CGRectGetMaxY(timeRulerLayer.bounds) - visibleHeight;
    newScrollPoint.y = floorf(fminf(fmaxf(newScrollPoint.y, topLimit), bottomLimit));

    newScrollPoint.y -= [timeRulerLayer hourLabelYPadding];
    newScrollPoint.x = floorf(newScrollPoint.x);
    newScrollPoint.y = floorf(newScrollPoint.y);
    for (WLCalendarDayEventsLayer *l in [_columnLayers valueForKey:@"WL_dayLayer"])
    {
        [l scrollPoint:newScrollPoint];
        [l positionTextOfEvents];
    }
    [timeRulerLayer scrollPoint:newScrollPoint];
}

- (NSDictionary *)_titleAttributesForColumnDayBackgroundLayer:(WLBlockLayer *)aLayer
{
    static NSDictionary *titleAttributes = nil;
    static NSMutableDictionary *boldTitleAttributes = nil;
    if (titleAttributes == nil)
    {
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        [p setAlignment:NSCenterTextAlignment];
        [p setLineBreakMode:NSLineBreakByWordWrapping];
        NSShadow *s = [[NSShadow alloc] init];
        [s setShadowBlurRadius:0.0f];
        [s setShadowColor:[NSColor WL_columnTitleShadowColor]];
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
            [s setShadowOffset:NSMakeSize(0.0f, -1.0f)];
        else
            [s setShadowOffset:NSMakeSize(0.0f, 1.0f)];
        titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                    (id)[NSFont WL_columnTitleFont],  NSFontAttributeName,
                                                    p,                                NSParagraphStyleAttributeName,
                                                    [NSColor whiteColor],             NSForegroundColorAttributeName,
                                                    s,                                NSShadowAttributeName,
                                                    nil];
        [s release];
        [p release];
    }
    if (boldTitleAttributes == nil)
    {
        boldTitleAttributes = [titleAttributes mutableCopy];
        [boldTitleAttributes setObject:(id)[NSFont WL_columnBoldTitleFont] forKey:NSFontAttributeName];
    }
    if ([[aLayer valueForKey:_WLDayBackgroundLayerShouldHighlightTitleKey] boolValue])
        return boldTitleAttributes;
    else
        return titleAttributes;
}


#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self stopAnimations];
    [_rootLayer setNeedsLayout];
}

@end


#pragma mark -

@implementation WLCalendarWeekView (Layout)

#pragma mark Time Ruler

static const CGFloat _WLYMarginBetweenTitleAndColumn = 5.0f;

static const CGFloat _WLYMarginBetweenAllDayAndDayPartsOfColumn = 8.0f;

static const CGFloat _WLXMarginBetweenTimeRulerAndTimeRulerRoot = 5.0f;

- (CGFloat)timeRulerWidth
{
    return [[_timeRulerRootLayer WL_timeRulerLayer] preferredFrameWidth];
}

- (CGFloat)timeRulerRootWidth
{
    return [self timeRulerWidth] + 2 * _WLXMarginBetweenTimeRulerAndTimeRulerRoot;
}

- (CGRect)timeRulerRootFrame
{
    CGFloat allDayHeightAndMargin = 0.0f;
    if (self.showAllDayEvents)
    allDayHeightAndMargin = self.heightOfAllDayPartOfColumn + _WLYMarginBetweenAllDayAndDayPartsOfColumn;
    return CGRectIntegral(CGRectMake(0.0f,
                                     0.0f,
                                     [self timeRulerRootWidth],
                                     _rootLayer.frame.size.height - allDayHeightAndMargin));
}

- (CGFloat)timerRulerScrollHeight
{
    CGFloat columnTitleHeightAndMargin = 0.0f;
    if (self.showTitle)
    columnTitleHeightAndMargin = [self columnTitleFrame].size.height + _WLYMarginBetweenTitleAndColumn;
    return _timeRulerRootLayer.frame.size.height - columnTitleHeightAndMargin;
}

- (CGRect)timeRulerScrollFrame
{
    return CGRectIntegral(CGRectMake(_WLXMarginBetweenTimeRulerAndTimeRulerRoot,
                                     0.0f,
                                     [self timeRulerWidth],
                                     [self timerRulerScrollHeight]));
}

- (void)layoutTimeRulerRoot
{
    // It's important to layout time ruler root before scroll.
    _timeRulerRootLayer.frame = [self timeRulerRootFrame];
    [_timeRulerRootLayer WL_timeRulerScrollLayer].frame = [self timeRulerScrollFrame];
}

- (void)layoutTimeRulerLayer:(WLCalendarTimeRulerLayer *)aTimeRulerLayer
{
    CGSize timeRulerSize = [aTimeRulerLayer preferredFrameSize];
    [aTimeRulerLayer setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];
}


#pragma mark Column

static const CGFloat _WLXMarginBetweenColumns = 6.0f;

static const CGFloat _WLXMarginBetweenTimeRulerAndColumns = 6.0f;

- (CGFloat)columnWidth
{
    NSUInteger numberOfColumns = [_columnLayers count];
    if (numberOfColumns == 0)
        return 0.0f;
    CGFloat width = _rootLayer.frame.size.width - [self timeRulerRootWidth] - _WLXMarginBetweenTimeRulerAndColumns -
        numberOfColumns * _WLXMarginBetweenColumns;
    width /= numberOfColumns;
    return width;
}

- (CGRect)columnFrameAtIndex:(NSInteger)anIndex
{
    CGFloat width = [self columnWidth];
    CGFloat x = [self timeRulerRootWidth] + _WLXMarginBetweenTimeRulerAndColumns + anIndex * (width + _WLXMarginBetweenColumns);
    return CGRectIntegral(CGRectMake(x,
                                     0.0f,
                                     width,
                                     _rootLayer.frame.size.height));
}

- (CGRect)allDayBackgroundFrame
{
    if (self.showAllDayEvents)
    {
        return CGRectIntegral(CGRectMake(0.0f,
                                         0.0f,
                                         [self columnWidth],
                                         self.heightOfAllDayPartOfColumn));
    }
    else
        return CGRectZero;
}

- (CGRect)dayBackgroundFrame
{
    CGFloat allDayHeightAndMargin = 0.0f;
    if (self.showAllDayEvents)
        allDayHeightAndMargin = self.heightOfAllDayPartOfColumn + _WLYMarginBetweenAllDayAndDayPartsOfColumn;
    return CGRectIntegral(CGRectMake(0.0f,
                                     allDayHeightAndMargin,
                                     [self columnWidth],
                                     _rootLayer.frame.size.height - allDayHeightAndMargin));
}

- (CGRect)dayScrollFrame
{
    CGFloat titleHeightAndMargin = 0;
    if (self.showTitle)
        titleHeightAndMargin = [self columnTitleFrame].size.height + _WLYMarginBetweenTitleAndColumn;
    // Height of the day must be less than time ruler by half of of the first hour.
    CGFloat hourLabelYPadding = [[_timeRulerRootLayer WL_timeRulerLayer] hourLabelYPadding];
    CGRect dayBackgroundFrame = [self dayBackgroundFrame];
    return CGRectIntegral(CGRectInset(CGRectMake(0.0f,
                                                 titleHeightAndMargin + hourLabelYPadding,
                                                 dayBackgroundFrame.size.width,
                                                 dayBackgroundFrame.size.height - titleHeightAndMargin - hourLabelYPadding),
                                      1.0f, 0.0f));
}

- (NSRect)columnTitleFrame
{
    CGFloat width = [self dayBackgroundFrame].size.width;
    CGFloat height = 25.0f;
    CGFloat maximumHeight = [[[_columnLayers lastObject] WL_dayBackgroundLayer] frame].size.height;
    for (WLBlockLayer *l in [_columnLayers valueForKeyPath:@"WL_dayBackgroundLayer"])
    {
        NSString *title = [l valueForKey:_WLDayBackgroundLayerTitleKey];
        NSDictionary *attributes = [self _titleAttributesForColumnDayBackgroundLayer:l];
        NSRect r = [title boundingRectWithSize:NSMakeSize(width, maximumHeight)
                                       options:_WLDayBackgroundTitleAttributes
                                    attributes:attributes];
        height = fmaxf(height, r.size.height);
    }
    return NSIntegralRect(NSMakeRect(0.0f,
                                     _WLYMarginBetweenTitleAndColumn,
                                     width,
                                     height));
}

- (void)layoutColumnLayers
{
    [_columnLayers enumerateObjectsUsingBlock:^(CALayer *l, NSUInteger idx, BOOL *stop)
    {
        [self layoutColumnLayer:l atIndex:idx];
    }];
}

- (void)layoutColumnLayer:(CALayer *)aColumnLayer atIndex:(NSInteger)anIndex
{
    aColumnLayer.frame = [self columnFrameAtIndex:anIndex];

    CALayer *allDayBackground = [aColumnLayer WL_allDayBackgroundLayer];
    if (self.showAllDayEvents)
    {
        allDayBackground.hidden = NO;
        allDayBackground.frame = [self allDayBackgroundFrame];
        CALayer *allDay = [aColumnLayer WL_allDayLayer];
        // Background has 1px stroke
        allDay.frame = CGRectIntegral(CGRectInset(allDayBackground.bounds, 1.0f, 0.0f));
    }
    else
        allDayBackground.hidden = YES;

    CALayer *dayBackground = [aColumnLayer WL_dayBackgroundLayer];
    dayBackground.frame = [self dayBackgroundFrame];

    CAScrollLayer *dayScroll = [aColumnLayer WL_dayScrollLayer];

    // Background has 1px stroke
    dayScroll.frame = [self dayScrollFrame];
}


- (void)layoutDayLayer:(WLCalendarDayEventsLayer *)aDayLayer
{
    WLCalendarTimeRulerLayer *timeRuler = [_timeRulerRootLayer WL_timeRulerLayer];
    CGFloat height = [timeRuler preferredFrameSize].height;
    [aDayLayer setValue:[NSNumber numberWithFloat:height] forKeyPath:@"frame.size.height"];
}


#pragma mark Time Indicator

- (void)layoutTimeIndicatorRootLayer
{
    CGRect timeRulerRootFrame = [self timeRulerRootFrame];
    _timeIndicatorRootLayer.frame = CGRectIntegral(CGRectMake(timeRulerRootFrame.size.width,
                                                              timeRulerRootFrame.origin.y,
                                                              _rootLayer.bounds.size.width - _timeRulerRootLayer.frame.size.width - _WLXMarginBetweenTimeRulerAndColumns,
                                                              [self dayScrollFrame].size.height));
}

- (void)layoutTimeIndicatorLayer
{
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer WL_timeRulerLayer];
    CGPoint hourPoint = [timeRulerLayer pointForHour:_hour];
    CGPoint newTimeIndicatorPoint = [_timeIndicatorRootLayer convertPoint:hourPoint fromLayer:timeRulerLayer];
    [[_timeIndicatorRootLayer WL_timeIndicatorLayer] setValue:[NSNumber numberWithFloat:floorf(newTimeIndicatorPoint.y)] forKeyPath:@"position.y"];
}

@end


#pragma mark -

@implementation WLCalendarWeekView (SetupLayers)

- (CALayer *)setupRootLayer
{
    CALayer *l = [CALayer layer];
    l.name = _WLRootLayerName;
    l.layoutManager = self;
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
    __block WLBlockLayer *timeRulerBackground = [self setupTimeRulerBackgroundLayer];
    CAScrollLayer *timeRulerScroll = [self setupTimeRulerScrollLayer];
    [timeRulerBackground addSublayer:timeRulerScroll];
    [timeRulerBackground setValue:timeRulerScroll forKey:timeRulerScroll.name];

    WLCalendarTimeRulerLayer *timeRuler = [self setupTimeRulerLayer];
    timeRuler.autoresizingMask = kCALayerWidthSizable;
    [timeRulerScroll addSublayer:timeRuler];
    [timeRulerScroll setValue:timeRuler forKey:timeRuler.name];
    return timeRulerBackground;
}

- (WLBlockLayer *)setupTimeRulerBackgroundLayer
{
    __block WLBlockLayer *l = [WLBlockLayer layer];
    l.name = _WLTimeRulerBackgroundLayerName;
    l.masksToBounds = YES;
    l.needsDisplayOnBoundsChange = YES;
#ifndef DEBUG_LAYERS
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect) {
        NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[aLayer contentsAreFlipped]];
        [c setImageInterpolation:NSImageInterpolationHigh];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:c];

        NSSize bottomBorderSize = NSMakeSize(aLayer.bounds.size.width, [[NSImage imageNamed:@"timeruler-bottom"] size].height);
        NSSize topBorderSize = NSMakeSize(aLayer.bounds.size.width, [[NSImage imageNamed:@"timeruler-top"] size].height);
        NSSize middleBorderSize = NSMakeSize(aLayer.bounds.size.width, aLayer.bounds.size.height - bottomBorderSize.height - topBorderSize.height);

        NSRect dirtyRect = NSRectFromCGRect(aDirtyRect);
        static CGFloat AlphaFraction = 0.5f;

        NSRect bottomBorderFrame = NSMakeRect(0.0, 0.0, bottomBorderSize.width, bottomBorderSize.height);
        if (NSIntersectsRect(bottomBorderFrame, dirtyRect))
        {
            NSDrawThreePartImage(bottomBorderFrame,
                                 [NSImage imageNamed:@"timeruler-bottom-left"],
                                 [NSImage imageNamed:@"timeruler-bottom"],
                                 [NSImage imageNamed:@"timeruler-bottom-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 NO);
        }

        NSRect middleBorderFrame = NSMakeRect(0.0, NSMaxY(bottomBorderFrame), middleBorderSize.width, middleBorderSize.height);
        if (NSIntersectsRect(middleBorderFrame, dirtyRect))
        {
            [(NSImage *)[NSImage imageNamed:@"timeruler-middle-left"] drawInRect:NSMakeRect(0.0f, middleBorderFrame.origin.y, 1.0f, middleBorderFrame.size.height)
                                                                        fromRect:NSZeroRect
                                                                       operation:NSCompositeSourceOver
                                                                        fraction:AlphaFraction
                                                                  respectFlipped:YES
                                                                           hints:nil];
            [(NSImage *)[NSImage imageNamed:@"timeruler-middle"] drawInRect:NSMakeRect(1.0f, middleBorderFrame.origin.y, middleBorderFrame.size.width - 2.0f, middleBorderFrame.size.height)
                                                                   fromRect:NSZeroRect
                                                                  operation:NSCompositeSourceOver
                                                                   fraction:AlphaFraction
                                                             respectFlipped:YES
                                                                      hints:nil];
            [(NSImage *)[NSImage imageNamed:@"timeruler-middle-right"] drawInRect:NSMakeRect(middleBorderFrame.size.width - 1.0f, middleBorderFrame.origin.y, 1.0f, middleBorderFrame.size.height)
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
                                 [NSImage imageNamed:@"timeruler-top-left"],
                                 [NSImage imageNamed:@"timeruler-top"],
                                 [NSImage imageNamed:@"timeruler-top-right"],
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
    return l;
}

- (CAScrollLayer *)setupTimeRulerScrollLayer
{
    __block CAScrollLayer *l = [CAScrollLayer layer];
    l.name = _WLTimeRulerScrollLayerName;
    l.scrollMode = kCAScrollVertically;
    l.geometryFlipped = YES;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    return l;
}

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer
{
    __block WLCalendarTimeRulerLayer *l = [WLCalendarTimeRulerLayer layer];
    l.name = _WLTimeRulerLayerName;
    l.timeRuler = self;
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
    WLBlockLayer *allDayBackground = [self setupAllDayBackgroundLayer];
    [root addSublayer:allDayBackground];
    [root setValue:allDayBackground forKey:allDayBackground.name];

    WLCalendarAllDayEventsLayer *allDay = [self setupAllDayLayer];
    [allDayBackground addSublayer:allDay];
    [allDayBackground setValue:allDay forKey:allDay.name];

    WLBlockLayer *dayBackground = [self setupDayBackgroundLayer];
    [root addSublayer:dayBackground];
    [root setValue:dayBackground forKey:dayBackground.name];

    CAScrollLayer *scroll = [self setupDayScrollLayer];
    [dayBackground addSublayer:scroll];
    [dayBackground setValue:scroll forKey:scroll.name];

    WLCalendarDayEventsLayer *day = [self setupDayLayer];
    day.autoresizingMask = kCALayerWidthSizable;
    [scroll addSublayer:day];
    [scroll setValue:day forKey:day.name];
    return root;
}

- (CALayer *)setupColumnLayer
{
    __block CALayer *l = [CALayer layer];
    l.geometryFlipped = YES;
    l.name = _WLColumnLayerName;
    l.anchorPoint = CGPointMake(0.0f, 0.0f);
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor redColor] WL_CGColor];
#endif
    return l;
}

- (WLBlockLayer *)setupAllDayBackgroundLayer
{
    __block WLBlockLayer *l = [WLBlockLayer layer];
    l.name = _WLAllDayBackgroundLayerName;
    l.needsDisplayOnBoundsChange = YES;
    l.masksToBounds = YES;
#ifndef DEBUG_LAYERS
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect) {
        NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[aLayer contentsAreFlipped]];
        [c setImageInterpolation:NSImageInterpolationHigh];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:c];

        NSSize bottomSize = NSMakeSize(aLayer.bounds.size.width,
                                       [[NSImage imageNamed:@"allday-bottom"] size].height);
        NSSize topSize = NSMakeSize(aLayer.bounds.size.width,
                                    [[NSImage imageNamed:@"allday-top"] size].height);
        NSSize middleSize = NSMakeSize(aLayer.bounds.size.width,
                                       aLayer.bounds.size.height - bottomSize.height - topSize.height);

        NSRect dirtyRect = NSRectFromCGRect(aDirtyRect);
        static CGFloat AlphaFraction = 1.0f;

        NSRect topFrame = NSMakeRect(0.0, 0.0, topSize.width, topSize.height);
        if (NSIntersectsRect(topFrame, topFrame))
        {
            NSDrawThreePartImage(topFrame,
                                 [NSImage imageNamed:@"allday-top-left"],
                                 [NSImage imageNamed:@"allday-top"],
                                 [NSImage imageNamed:@"allday-top-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 YES);
        }

        NSRect middleFrame = NSMakeRect(0.0, NSMaxY(topFrame), middleSize.width, middleSize.height);
        if (NSIntersectsRect(middleFrame, dirtyRect))
        {
            [(NSImage *)[NSImage imageNamed:@"allday-middle-left"] drawInRect:NSMakeRect(0.0f,
                                                                                         middleFrame.origin.y,
                                                                                         3.0f,
                                                                                         middleFrame.size.height)
                                                                     fromRect:NSZeroRect
                                                                    operation:NSCompositeSourceOver
                                                                     fraction:AlphaFraction
                                                               respectFlipped:YES
                                                                        hints:nil];
            [(NSImage *)[NSImage imageNamed:@"allday-middle"] drawInRect:NSMakeRect(3.0f,
                                                                                    middleFrame.origin.y,
                                                                                    middleFrame.size.width - 6.0f,
                                                                                    middleFrame.size.height)
                                                                fromRect:NSZeroRect
                                                               operation:NSCompositeSourceOver
                                                                fraction:AlphaFraction
                                                          respectFlipped:YES
                                                                   hints:nil];
            [(NSImage *)[NSImage imageNamed:@"allday-middle-right"] drawInRect:NSMakeRect(middleFrame.size.width - 3.0f,
                                                                                          middleFrame.origin.y,
                                                                                          3.0f,
                                                                                          middleFrame.size.height)
                                                                      fromRect:NSZeroRect
                                                                     operation:NSCompositeSourceOver
                                                                      fraction:AlphaFraction
                                                                respectFlipped:YES
                                                                         hints:nil];
        }

        NSRect bottomFrame = NSMakeRect(0.0, NSMaxY(middleFrame), bottomSize.width, bottomSize.height);
        if (NSIntersectsRect(bottomFrame, dirtyRect))
        {
            NSDrawThreePartImage(bottomFrame,
                                 [NSImage imageNamed:@"allday-bottom-left"],
                                 [NSImage imageNamed:@"allday-bottom"],
                                 [NSImage imageNamed:@"allday-bottom-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 YES);
        }

        [NSGraphicsContext restoreGraphicsState];
    };
#else
    l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    return l;
}

- (WLCalendarAllDayEventsLayer *)setupAllDayLayer
{
    __block WLCalendarAllDayEventsLayer *l = [WLCalendarAllDayEventsLayer layer];
    l.name = _WLAllDayLayerName;
    return l;
}

- (WLCalendarDayEventsLayer *)setupDayLayer
{
    __block WLCalendarDayEventsLayer *l = [WLCalendarDayEventsLayer layer];
    l.name = _WLDayLayerName;
    l.timeRuler = self;
    l.keepTextOfEventsVisible = !self.fitDayEvents;
#ifdef DEBUG_LAYERS
    l.needsDisplayOnBoundsChange = YES;
#endif
    return l;
}

- (CAScrollLayer *)setupDayScrollLayer
{
    __block CAScrollLayer *l = [CAScrollLayer layer];
    l.name = _WLDayScrollLayerName;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor purpleColor] WL_CGColor];
#endif
    return l;
}

- (WLBlockLayer *)setupDayBackgroundLayer
{
    __block WLBlockLayer *l = [WLBlockLayer layer];
    l.name = _WLDayBackgroundLayerName;
    l.needsDisplayOnBoundsChange = YES;
#ifndef DEBUG_LAYERS
    __block WLCalendarWeekView *selfBlock = self;
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect) {
        NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[aLayer contentsAreFlipped]];
        [c setImageInterpolation:NSImageInterpolationHigh];
        [c setShouldAntialias:YES];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:c];

        NSSize bottomSize = NSMakeSize(aLayer.bounds.size.width,
                                       [[NSImage imageNamed:@"allday-bottom"] size].height);
        NSSize topSize = NSMakeSize(aLayer.bounds.size.width,
                                    [[NSImage imageNamed:@"allday-top"] size].height);
        NSSize middleSize = NSMakeSize(aLayer.bounds.size.width,
                                       aLayer.bounds.size.height - bottomSize.height - topSize.height);
        NSRect dirtyRect = NSRectFromCGRect(aDirtyRect);
        static CGFloat AlphaFraction = 1.0f;

        NSRect topFrame = NSMakeRect(0.0,
                                     0.0,
                                     topSize.width,
                                     topSize.height);
        if (NSIntersectsRect(topFrame, topFrame))
        {
            NSDrawThreePartImage(topFrame,
                                 [NSImage imageNamed:@"day-top-left"],
                                 [NSImage imageNamed:@"day-top"],
                                 [NSImage imageNamed:@"day-top-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 YES);
        }

        NSRect middleFrame = NSMakeRect(0.0,
                                        NSMaxY(topFrame),
                                        middleSize.width,
                                        middleSize.height);
        if (NSIntersectsRect(middleFrame, dirtyRect))
        {
            [(NSImage *)[NSImage imageNamed:@"day-middle-left"] drawInRect:NSMakeRect(0.0f,
                                                                                      middleFrame.origin.y,
                                                                                      1.0f,
                                                                                      middleFrame.size.height)
                                                                  fromRect:NSZeroRect
                                                                 operation:NSCompositeSourceOver
                                                                  fraction:AlphaFraction
                                                            respectFlipped:YES
                                                                     hints:nil];
            [(NSImage *)[NSImage imageNamed:@"day-middle"] drawInRect:NSMakeRect(1.0f,
                                                                                 middleFrame.origin.y,
                                                                                 middleFrame.size.width - 2.0f,
                                                                                 middleFrame.size.height)
                                                             fromRect:NSZeroRect
                                                            operation:NSCompositeSourceOver
                                                             fraction:AlphaFraction
                                                       respectFlipped:YES
                                                                hints:nil];
            [(NSImage *)[NSImage imageNamed:@"day-middle-right"] drawInRect:NSMakeRect(middleFrame.size.width - 1.0f,
                                                                                       middleFrame.origin.y,
                                                                                       1.0f,
                                                                                       middleFrame.size.height)
                                                                   fromRect:NSZeroRect
                                                                  operation:NSCompositeSourceOver
                                                                   fraction:AlphaFraction
                                                             respectFlipped:YES
                                                                      hints:nil];
        }

        NSRect bottomFrame = NSMakeRect(0.0,
                                        NSMaxY(middleFrame),
                                        bottomSize.width,
                                        bottomSize.height);
        if (NSIntersectsRect(bottomFrame, dirtyRect))
        {
            NSDrawThreePartImage(bottomFrame,
                                 [NSImage imageNamed:@"day-bottom-left"],
                                 [NSImage imageNamed:@"day-bottom"],
                                 [NSImage imageNamed:@"day-bottom-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 AlphaFraction,
                                 YES);
        }

        NSString *dayName = [aLayer valueForKey:_WLDayBackgroundLayerTitleKey];
        [dayName drawWithRect:[selfBlock columnTitleFrame]
                      options:_WLDayBackgroundTitleAttributes
                   attributes:[self _titleAttributesForColumnDayBackgroundLayer:aLayer]];

        [NSGraphicsContext restoreGraphicsState];
    };
#else
    l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
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
    l.name = _WLTimeIndicatorRootLayerName;
    l.masksToBounds = YES;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor magentaColor] WL_CGColor];
    l.opacity = 0.3f;
#endif
    WLCalendarTimeIndicatorLayer *timeIndicator = [self setupTimeIndicatorLayer];
    CGSize preferredTimeIndicatorSize = [timeIndicator preferredFrameSize];
    timeIndicator.frame = CGRectMake(0.0f, 0.0f, preferredTimeIndicatorSize.width, preferredTimeIndicatorSize.height);
    timeIndicator.autoresizingMask = kCALayerWidthSizable;
    [l addSublayer:timeIndicator];
    [l setValue:timeIndicator forKey:timeIndicator.name];
    return l;
}

- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer
{
    __block WLCalendarTimeIndicatorLayer *l = [WLCalendarTimeIndicatorLayer layer];
    l.name = _WLTimeIndicatorLayerName;
    l.anchorPoint = CGPointMake(0.0f, 1.0f);
    l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor whiteColor] WL_CGColor];
#endif
    return l;
}

@end


@implementation CALayer (WLCalendarWeekView)

- (WLBlockLayer *)WL_allDayBackgroundLayer
{
    NSParameterAssert([self.name isEqual:_WLColumnLayerName]);
    return [self valueForKey:_WLAllDayBackgroundLayerName];
}

- (WLCalendarAllDayEventsLayer *)WL_allDayLayer
{
    return [[self WL_allDayBackgroundLayer] valueForKey:_WLAllDayLayerName];
}

- (WLBlockLayer *)WL_dayBackgroundLayer
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

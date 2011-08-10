//
//  WLCalendarWeekView.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWeekView.h"
#import "NSColor+CGColor.h"
#import "CATextLayer+WLStringSize.h"
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


static const CGFloat _WLYMarginBetweenAllDayAndWeekdayEvents = 10.0f;

static const CGFloat _WLXMarginBetweenColumns = 10.0f;

static const CGFloat _WLWeekdayEventsTitleLayerHeight = 25.0f;


@implementation WLCalendarWeekView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        allDayEventsHeight = 100.0f;
        _columnLayers = [[NSMutableArray alloc] init];
        showTimeIndicator = YES;
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
@synthesize allDayEventsHeight;
@synthesize showTimeIndicator;

- (void)setShowTimeIndicator:(BOOL)newShowTimeIndicator
{
    showTimeIndicator = newShowTimeIndicator;
    _timeIndicatorLayer.hidden = !showTimeIndicator;
}


#pragma mark Methods

- (void)setupLayersAnimated:(BOOL)isAnimated
{
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    [CATransaction setCompletionBlock:^{
        [CATransaction setDisableActions:!isAnimated];
        [dataSource weekViewDidSetupLayers:self];
    }];

    if (_rootLayer == nil)
    {
        _rootLayer = [self setupRootLayer];
        _rootLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    }

    if (_timeIndicatorLayer == nil)
    {
        _timeIndicatorLayer = [self setupTimeIndicatorLayer];
        _timeIndicatorLayer.hidden = !showTimeIndicator;
        [_rootLayer addSublayer:_timeIndicatorLayer];
    }

    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    NSUInteger currentNumberOfColumns = [_columnLayers count];
    if (currentNumberOfColumns < numberOfColumns)
    {
        for (NSUInteger i=0, size=numberOfColumns-currentNumberOfColumns; i<size; ++i)
        {
            CALayer *column = [self setupColumnRootLayer];
            [_columnLayers addObject:column];
            [_rootLayer insertSublayer:column below:_timeIndicatorLayer];
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
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];

    if (_timeRulerRootLayer == nil)
    {
        _timeRulerRootLayer = [self setupTimeRulerRootLayer];
        [_rootLayer addSublayer:_timeRulerRootLayer];
    }
    [self _updateTimeRuler];

    if ([_rootLayer superlayer] == nil)
    {
        CALayer *viewLayer = [CALayer layer];
#ifdef DEBUG_LAYERS
        viewLayer.backgroundColor = [[NSColor darkGrayColor] WL_CGColor];
#endif
        [viewLayer addSublayer:_rootLayer];
        [self setLayer:viewLayer];
        [self setWantsLayer:YES];
    }
    [CATransaction commit];
}

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    _hour = aHour;
    CAScrollLayer *timeRulerScrollLayer = [_timeRulerRootLayer valueForKeyPath:_WLTimeRulerScrollLayerName];
    WLCalendarTimeRulerLayer *timeRulerLayer = [timeRulerScrollLayer valueForKeyPath:_WLTimeRulerLayerName];
    CGPoint hourPoint = [timeRulerLayer pointForHour:_hour];

    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    CGPoint newScrollPoint = [timeRulerScrollLayer convertPoint:hourPoint fromLayer:timeRulerLayer];

    // Center _hour whenever possible
    newScrollPoint = CGPointMake(0.0f, floorf(newScrollPoint.y - timeRulerScrollLayer.bounds.size.height / 2));
    CGFloat topLimit = 0.0f;
    newScrollPoint.y = fmaxf(newScrollPoint.y, topLimit);
    CGFloat bottomLimit = CGRectGetMaxY(timeRulerLayer.bounds) - timeRulerScrollLayer.bounds.size.height;
    newScrollPoint.y = fminf(newScrollPoint.y, bottomLimit);

    [timeRulerScrollLayer scrollToPoint:newScrollPoint];
    for (CALayer *column in _columnLayers)
    {
        CAScrollLayer *scrollLayer = [column valueForKeyPath:@"weekdayEventsBackground.weekdayEventsScroll"];
        [scrollLayer scrollToPoint:newScrollPoint];
    }
    CGPoint newTimeIndicatorPoint = [_rootLayer convertPoint:hourPoint fromLayer:timeRulerLayer];
    [_timeIndicatorLayer setValue:[NSNumber numberWithFloat:newTimeIndicatorPoint.y] forKeyPath:@"position.y"];
    [CATransaction commit];
}

- (void)showNextDay
{
    if ([_columnLayers count] == 0)
        return;
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [CATransaction setDisableActions:YES];
    CALayer *newColumn = [self setupColumnRootLayer];

    [CATransaction setDisableActions:NO];
    [[_columnLayers objectAtIndex:0] removeFromSuperlayer];

    [CATransaction setDisableActions:YES];
    [_columnLayers removeObjectAtIndex:0];
    [_columnLayers addObject:newColumn];
    [_rootLayer insertSublayer:newColumn below:_timeIndicatorLayer];
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndex:[_columnLayers count] - 1]];
    [self _layoutColumnLayer:newColumn];

    [CATransaction setDisableActions:NO];
    [_columnLayers enumerateObjectsUsingBlock:^(CALayer *column, NSUInteger columnIdx, BOOL *stop) {
        [self _positionColumnLayer:column atIndex:columnIdx];
    }];

    CABasicAnimation *positionAnimation = [newColumn actionForKey:@"position"];
    NSPoint fromValue = NSMakePoint(newColumn.position.x + newColumn.frame.size.width + _WLXMarginBetweenColumns,
                                    newColumn.position.y);
    [positionAnimation setFromValue:[NSValue valueWithPoint:fromValue]];
    [positionAnimation setToValue:[NSValue valueWithPoint:NSPointFromCGPoint(newColumn.position)]];
    [newColumn addAnimation:positionAnimation forKey:@"position"];
    [CATransaction commit];
}

- (void)showNextWeek
{
    if ([_columnLayers count] == 0)
        return;
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    for (CALayer *oldWeekdayRootLayer in _columnLayers)
        [oldWeekdayRootLayer removeFromSuperlayer];

    [CATransaction setDisableActions:YES];
    [_columnLayers removeAllObjects];
    for (NSUInteger i=0; i<numberOfColumns; ++i)
    {
        CALayer *column = [self setupColumnRootLayer];
        [_columnLayers addObject:column];
        [_rootLayer insertSublayer:column below:_timeIndicatorLayer];
    }
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];

    [CATransaction setDisableActions:NO];
    [_columnLayers enumerateObjectsUsingBlock:^(CALayer *column, NSUInteger idx, BOOL *stop) {
        [self _positionColumnLayer:column atIndex:idx];
        [self _layoutColumnLayer:column];
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        NSPoint fromValue = NSMakePoint(column.position.x + _rootLayer.bounds.size.width,
                                        column.position.y);
        [positionAnimation setFromValue:[NSValue valueWithPoint:fromValue]];
        [positionAnimation setToValue:[NSValue valueWithPoint:NSPointFromCGPoint(column.position)]];
        [column addAnimation:positionAnimation forKey:@"position"];
    }];
    [CATransaction commit];
}

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
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

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet
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

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    if ([dataSource respondsToSelector:@selector(weekView:willAskForData:forColumnsAtIndexes:)])
    {
        [dataSource weekView:self
              willAskForData:WLCalendarWeekViewTitleDataUnit | WLCalendarWeekViewEventsDataUnit
         forColumnsAtIndexes:anIndexSet];
    }
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
        [self _updateColumnAtIndex:idx];
    }];
    if ([dataSource respondsToSelector:@selector(weekViewDidAskForData:)])
        [dataSource weekViewDidAskForData:self];
}

- (void)setShowTimeIndicator:(BOOL)newShowTimeIndicator
{
    showTimeIndicator = newShowTimeIndicator;
    _timeIndicatorLayer.hidden = !showTimeIndicator;
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    NSParameterAssert([layer.name isEqualToString:_WLRootLayerName]);

    [CATransaction setDisableActions:YES];
    [self _layoutTimerRulerRootlayer:_timeRulerRootLayer];
    [_columnLayers enumerateObjectsUsingBlock:^(CALayer *column, NSUInteger idx, BOOL *stop)
    {
        [self _positionColumnLayer:column atIndex:idx];
        [self _layoutColumnLayer:column];
    }];
    _timeIndicatorLayer.frame = CGRectMake(_timeRulerRootLayer.frame.size.width,
                                           0.0f,
                                           _rootLayer.frame.size.width - _timeRulerRootLayer.frame.size.width,
                                           1.0f);
    [self scrollHour:_hour animated:![CATransaction disableActions]];
}


#pragma mark Private

- (void)_updateTimeRuler
{
    NSUInteger numberOfHours = [dataSource numberOfHours];
    NSMutableArray *h = [NSMutableArray arrayWithCapacity:numberOfHours];
    for (NSUInteger i=0; i<numberOfHours; ++i)
        [h addObject:[dataSource stringForHour:i]];
    [[_timeRulerRootLayer valueForKeyPath:@"timeRulerScroll.timeRuler"] setHours:h];
}

- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex
{
    NSMutableArray *columnEvents = [[dataSource weekView:self eventsForColumnAtIndex:anIndex] mutableCopy];
    NSArray *allDayEvents = [columnEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isAllDay == YES"]];
    for (id event in allDayEvents)
        [columnEvents removeObjectIdenticalTo:event];

    CALayer *column = [_columnLayers objectAtIndex:anIndex];
    WLCalendarDayEventsLayer *day = [column valueForKeyPath:@"weekdayEventsBackground.weekdayEventsScroll.weekdayEvents"];
    [day setEvents:[NSSet setWithArray:columnEvents]];
    [day setNeedsLayout];
    [columnEvents release];
    WLCalendarAllDayEventsLayer *allDay = [column valueForKeyPath:@"weekdayEventsAllDayBackground.weekdayEventsAllDay"];
    [allDay setEvents:allDayEvents];
    [allDay setNeedsLayout];
}

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex
{
    CALayer *column = [_columnLayers objectAtIndex:anIndex];
    CATextLayer *title = [column valueForKeyPath:@"weekdayEventsBackground.weekdayEventsTitle"];
    title.string = [dataSource weekView:self titleForColumnAtIndex:anIndex];
}

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex
{
    if ([dataSource respondsToSelector:@selector(weekView:colorForColumnAtIndex:)])
    {
        CALayer *column = [_columnLayers objectAtIndex:anIndex];
        WLCalendarBackgroundLayer *dayBackground = [column valueForKey:_WLDayBackgroundLayerName];
        WLCalendarBackgroundLayer *allDayBackground = [column valueForKey:_WLAllDayBackgroundLayerName];
        CGColorRef c = [dataSource weekView:self colorForColumnAtIndex:anIndex];
        dayBackground.contentsBackgroundColor = c;
        allDayBackground.contentsBackgroundColor = c;
    }
}

- (void)_updateColumnAtIndex:(NSUInteger)anIndex
{
    [self _updateEventsOfColumnAtIndex:anIndex];
    [self _updateTitleOfColumnAtIndex:anIndex];
    [CATransaction WL_performWithDisabledActions:^{
        [self _updateColorOfColumnAtIndex:anIndex];
    }];
}

- (void)_layoutTimerRulerRootlayer:(CALayer *)aRootLayer
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    CAScrollLayer *timeRulerScrollLayer = [aRootLayer valueForKeyPath:_WLTimeRulerScrollLayerName];
    WLCalendarTimeRulerLayer *timeRulerLayer = [timeRulerScrollLayer valueForKeyPath:_WLTimeRulerLayerName];
    CGSize timeRulerSize = [timeRulerLayer preferredFrameSize];
    aRootLayer.frame = CGRectMake(0.0f,
                                  0.0f,
                                  timeRulerSize.width,
                                  self.bounds.size.height - self.allDayEventsHeight - _WLYMarginBetweenAllDayAndWeekdayEvents);
    [timeRulerLayer setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];
    [timeRulerScrollLayer setValue:[NSNumber numberWithFloat:aRootLayer.bounds.size.height - _WLWeekdayEventsTitleLayerHeight]
                        forKeyPath:@"frame.size.height"];
}

- (void)_layoutColumnLayer:(CALayer *)aRootLayer
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    WLCalendarTimeRulerLayer *timeRuler = [_timeRulerRootLayer valueForKeyPath:@"timeRulerScroll.timeRuler"];
    CGSize timeRulerSize = [timeRuler preferredFrameSize];

    CALayer *allDayBackground = [aRootLayer valueForKeyPath:_WLAllDayBackgroundLayerName];
    allDayBackground.frame = CGRectIntegral(CGRectMake(aRootLayer.bounds.origin.x,
                                                       aRootLayer.bounds.origin.y,
                                                       aRootLayer.bounds.size.width,
                                                       allDayEventsHeight));

    CALayer *dayBackground = [aRootLayer valueForKeyPath:_WLDayBackgroundLayerName];
    dayBackground.frame = CGRectIntegral(CGRectMake(aRootLayer.bounds.origin.x,
                                                    CGRectGetMaxY(allDayBackground.frame) + _WLYMarginBetweenAllDayAndWeekdayEvents,
                                                    aRootLayer.bounds.size.width,
                                                    aRootLayer.bounds.size.height - CGRectGetMaxY(allDayBackground.frame) - _WLYMarginBetweenAllDayAndWeekdayEvents));

    CATextLayer *title = [dayBackground valueForKeyPath:_WLTitleLayerName];
    title.frame = CGRectIntegral(CGRectMake(dayBackground.bounds.origin.x,
                                            dayBackground.bounds.origin.y,
                                            dayBackground.bounds.size.width,
                                            _WLWeekdayEventsTitleLayerHeight));

    CAScrollLayer *dayScroll = [dayBackground valueForKeyPath:_WLDayScrollLayerName];
    dayScroll.frame = CGRectIntegral(CGRectMake(dayBackground.bounds.origin.x,
                                                CGRectGetMaxY(title.bounds) + [timeRuler firstHourYPadding],
                                                dayBackground.bounds.size.width,
                                                dayBackground.bounds.size.height - CGRectGetMaxY(title.bounds) - [timeRuler firstHourYPadding]));

    WLCalendarDayEventsLayer *day = [dayBackground valueForKeyPath:@"weekdayEventsScroll.weekdayEvents"];
    [day setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];
}

- (void)_positionColumnLayer:(CALayer *)aRootLayer atIndex:(NSUInteger)anIndex
{
    NSRect bounds = [self bounds];

    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer valueForKeyPath:@"timeRulerScroll.timeRuler"];
    CGSize timeRulerSize = [timeRulerLayer preferredFrameSize];

    CGFloat spaces = _WLXMarginBetweenColumns * [_columnLayers count];
    CGFloat width = (self.bounds.size.width - timeRulerSize.width - spaces) / [_columnLayers count];
    CGFloat x = timeRulerSize.width + _WLXMarginBetweenColumns + anIndex * (width + _WLXMarginBetweenColumns);

    aRootLayer.frame = CGRectIntegral(CGRectMake(x, 0.0f, width, bounds.size.height));
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
        l.contentsBackgroundColor = [[NSColor colorWithCalibratedRed:101.0f / 255.0f
                                                               green:161.0f / 255.0f
                                                                blue:165.0f / 255.0f
                                                               alpha:1.0f] WL_CGColor];
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
        l.timeRuler = dataSource;
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
        l.contentsBackgroundColor = [[NSColor colorWithCalibratedRed:101.0f / 255.0f
                                                               green:161.0f / 255.0f
                                                                blue:165.0f / 255.0f
                                                               alpha:1.0f] WL_CGColor];
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
        l.timeRuler = dataSource;
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
        l.contentsBackgroundColor = [[NSColor colorWithCalibratedRed:101.0f / 255.0f
                                                               green:161.0f / 255.0f
                                                                blue:165.0f / 255.0f
                                                               alpha:1.0f] WL_CGColor];
        l.contentsBackgroundOpacity = 0.3f;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    }];
    return l;
}


#pragma mark Time Indicator

- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer
{
    __block WLCalendarTimeIndicatorLayer *l = [WLCalendarTimeIndicatorLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.anchorPoint = CGPointMake(0.0f, 0.5f);
        l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor whiteColor] WL_CGColor];
#endif
    }];
    return l;
}

@end


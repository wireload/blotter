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
#import "WLCalendarTimeRulerLayer.h"
#import "WLCalendarBackgroundLayer.h"
#import "WLCalendarWeekdayEventsLayer.h"
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarTimeIndicatorLayer.h"
#import "WLCalendarTimeIndicatorLayer.h"


// Must be unique!
// These strings may be used directly in the code, look through it if you are going to change values.
static NSString* const _WLRootLayerName = @"root";

static NSString* const _WLTimeRulerBackgroundLayer = @"timeRulerBackground";

static NSString* const _WLTimeRulerScrollLayer = @"timeRulerScroll";

static NSString* const _WLTimeRulerLayer = @"timeRuler";

static NSString* const _WLWeekdayEventsContent = @"weekdayEventsContent";

static NSString *const _WLWeekdayEventsAllDayBackgroundLayer = @"weekdayEventsAllDayBackground";

static NSString* const _WLWeekdayEventsBackgroundLayer = @"weekdayEventsBackground";

static NSString* const _WLWeekdayEventsAllDayLayer = @"weekdayEventsAllDay";

static NSString* const _WLWeekdayEventsTitleLayer = @"weekdayEventsTitle";

static NSString* const _WLWeekdayEventsScrollLayer = @"weekdayEventsScroll";

static NSString* const _WLWeekdayEventsLayer = @"weekdayEvents";


static const CGFloat _WLYMarginBetweenAllDayAndWeekdayEvents = 10.0f;

static const CGFloat _WLXMarginBetweenColumns = 10.0f;

static const CGFloat _WLWeekdayEventsTitleLayerHeight = 25.0f;


/* Layout scheme:
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
 +--+ +--+ +--+  |         | |         | +---------+ +---------+
 |  | |  | |  |  |         | |         | |         | |         |
 |  | |  | |  |  |         | |         | |         | |         |
 |  | |  | |  |  |         | |         | | scroll  | | day     |
 |  | |  | |  |  |         | |         | |         | | events  |
 |b | |s | |t |  |         | |         | |         | |         |
 |a | |c | |i |  |         | |         | |         | |         | +---------+
 |c | |r | |m |  |         | |         | |         | |         | |time     |
 |k | |o | |e |  |         | |         | |         | |         | |indicator|
 |g | |l | |  |  |         | |         | |         | |         | +---------+
 |r | |l | |r |  |         | |         | |         | |         |
 |o | |  | |u |  |         | |         | |         | |         |
 |u | |  | |l |  |         | |         | |         | |         |
 |n | |  | |e |  |         | |         | |         | |         |
 |d | |  | |r |  |         | |         | |         | |         |
 |  | |  | |  |  |         | |         | |         | |         |
 +--+ +--+ +--+  +---------+ +---------+ +---------+ +---------+

 <--depth-----+  <--depth--------------------------------------------------+
 */


@implementation WLCalendarWeekView
@synthesize dataSource;
@synthesize allDayEventsHeight;
@synthesize showTimeIndicator;

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        allDayEventsHeight = 100.0f;
        _weekdayRootLayers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_weekdayRootLayers release];
    [super dealloc];
}

- (void)setupLayers
{
    [CATransaction setDisableActions:YES];
    CALayer *rootLayer = [CALayer layer];
    rootLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    rootLayer.name = _WLRootLayerName;
    rootLayer.masksToBounds = YES;
    rootLayer.layoutManager = self;

    NSUInteger numberOfHours = [dataSource numberOfHours];
    NSMutableArray *hours = [NSMutableArray arrayWithCapacity:numberOfHours];
    for (NSUInteger i=0; i<numberOfHours; ++i)
        [hours addObject:[dataSource stringForHour:i]];
    _timeRulerRootLayer = [self _setupTimeRulerLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer valueForKeyPath:@"timeRulerScroll.timeRuler"];
    [timeRulerLayer setHours:hours];

    [_weekdayRootLayers removeAllObjects];
    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    for (NSUInteger i=0; i<numberOfColumns; ++i)
    {
        CALayer *weekdayRootLayer = [self _setupWeekdayLayer];
        [_weekdayRootLayers addObject:weekdayRootLayer];
        [rootLayer addSublayer:weekdayRootLayer];
    }
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];
    [rootLayer addSublayer:_timeRulerRootLayer];
    
    _timeIndicatorLayer = [WLCalendarTimeIndicatorLayer layer];
    _timeIndicatorLayer.anchorPoint = CGPointMake(0.0f, 0.0f);
    _timeIndicatorLayer.backgroundColor = [[NSColor whiteColor] WL_CGColor];
    [rootLayer addSublayer:_timeIndicatorLayer];
    
    CALayer *contentLayer = [self layer];
    if (contentLayer != nil)
    {
        rootLayer.bounds = _rootLayer.bounds;
        rootLayer.position = _rootLayer.position;
        [CATransaction setDisableActions:NO];
        [contentLayer replaceSublayer:_rootLayer with:rootLayer];
        [CATransaction setDisableActions:YES];
    }
    else
    {
        contentLayer = [CALayer layer];
#ifdef DEBUG_LAYERS
        contentLayer.backgroundColor = [[NSColor darkGrayColor] WL_CGColor];
#endif
        [contentLayer addSublayer:rootLayer];
        [self setLayer:contentLayer];
        [self setWantsLayer:YES];
    }
    _rootLayer = rootLayer;
    [dataSource weekViewDidSetupLayers:self];
}

- (void)scrollHour:(CGFloat)aHour
{
    _hour = aHour;
    CAScrollLayer *timeRulerScrollLayer = [_timeRulerRootLayer valueForKeyPath:_WLTimeRulerScrollLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [timeRulerScrollLayer valueForKeyPath:_WLTimeRulerLayer];
    CGPoint hourPoint = [timeRulerScrollLayer convertPoint:[timeRulerLayer pointForHour:aHour] fromLayer:timeRulerLayer];

    // Center aHour whenever possible
    hourPoint = CGPointMake(0.0f, floorf(hourPoint.y - timeRulerScrollLayer.bounds.size.height / 2));
    CGFloat topLimit = 0.0f;
    hourPoint.y = fmaxf(hourPoint.y, topLimit);
    CGFloat bottomLimit = CGRectGetMaxY(timeRulerLayer.bounds) - timeRulerScrollLayer.bounds.size.height;
    hourPoint.y = fminf(hourPoint.y, bottomLimit);
    
    [CATransaction begin];
    [timeRulerScrollLayer scrollToPoint:hourPoint];
    for (CALayer *weekdayRootLayer in _weekdayRootLayers)
    {
        CAScrollLayer *scrollLayer = [weekdayRootLayer valueForKeyPath:@"weekdayEventsBackground.weekdayEventsScroll"];
        [scrollLayer scrollToPoint:hourPoint];
    }
    [CATransaction commit];
    
    hourPoint = [timeRulerLayer pointForHour:aHour];
    hourPoint = [_rootLayer convertPoint:hourPoint fromLayer:timeRulerLayer];
    [_timeIndicatorLayer setValue:[NSNumber numberWithFloat:hourPoint.y] forKeyPath:@"position.y"];
}

- (void)nextDay
{
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    CALayer *newWeekdayRootLayer = [self _setupWeekdayLayer];

    [CATransaction setDisableActions:NO];
    [[_weekdayRootLayers objectAtIndex:0] removeFromSuperlayer];

    [CATransaction setDisableActions:YES];
    [_weekdayRootLayers removeObjectAtIndex:0];
    [_weekdayRootLayers addObject:newWeekdayRootLayer];
    [_rootLayer addSublayer:newWeekdayRootLayer];
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndex:[_weekdayRootLayers count] - 1]];

    [CATransaction setDisableActions:NO];
    [_weekdayRootLayers enumerateObjectsUsingBlock:^(CALayer *weekdayRootLayer, NSUInteger idx, BOOL *stop) {
        [self _positionWeekdayRootLayer:weekdayRootLayer atIndex:idx];
    }];
    [self _layoutWeekdayRootLayer:newWeekdayRootLayer];
    // Animate positioning of just added layer.
    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    NSPoint fromValue = NSMakePoint(newWeekdayRootLayer.position.x + newWeekdayRootLayer.frame.size.width + _WLXMarginBetweenColumns,
                                    newWeekdayRootLayer.position.y);
    [positionAnimation setFromValue:[NSValue valueWithPoint:fromValue]];
    [positionAnimation setToValue:[NSValue valueWithPoint:NSPointFromCGPoint(newWeekdayRootLayer.position)]];
    [newWeekdayRootLayer addAnimation:positionAnimation forKey:@"position"];
    [self scrollHour:_hour];
    [CATransaction commit];
}

- (void)nextWeek
{
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    NSUInteger numberOfColumns = [dataSource numberOfColumnsInWeekView:self];
    for (CALayer *oldWeekdayRootLayer in _weekdayRootLayers)
        [oldWeekdayRootLayer removeFromSuperlayer];

    [CATransaction setDisableActions:YES];
    [_weekdayRootLayers removeAllObjects];
    for (NSUInteger i=0; i<numberOfColumns; ++i)
    {
        CALayer *weekdayRootLayer = [self _setupWeekdayLayer];
        [_weekdayRootLayers addObject:weekdayRootLayer];
        [_rootLayer addSublayer:weekdayRootLayer];
    }
    [self updateColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];

    [CATransaction setDisableActions:NO];
    [_weekdayRootLayers enumerateObjectsUsingBlock:^(CALayer *weekdayRootLayer, NSUInteger idx, BOOL *stop) {
        [self _positionWeekdayRootLayer:weekdayRootLayer atIndex:idx];
        [self _layoutWeekdayRootLayer:weekdayRootLayer];
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        NSPoint fromValue = NSMakePoint(weekdayRootLayer.position.x + _rootLayer.bounds.size.width,
                                        weekdayRootLayer.position.y);
        [positionAnimation setFromValue:[NSValue valueWithPoint:fromValue]];
        [positionAnimation setToValue:[NSValue valueWithPoint:NSPointFromCGPoint(weekdayRootLayer.position)]];
        [weekdayRootLayer addAnimation:positionAnimation forKey:@"position"];
        [weekdayRootLayer addAnimation:positionAnimation forKey:@"position"];
        [self scrollHour:_hour];
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


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLRootLayerName]);

    // We don't cancel this change since we don't want CAConstraintLayoutManager animation.
    if ([self inLiveResize])
        [CATransaction setDisableActions:YES];
    [self _layoutTimerRulerRootlayer:_timeRulerRootLayer];
    [_weekdayRootLayers enumerateObjectsUsingBlock:^(CALayer *weekdayRootLayer, NSUInteger idx, BOOL *stop)
    {
        [self _positionWeekdayRootLayer:weekdayRootLayer atIndex:idx];
        [self _layoutWeekdayRootLayer:weekdayRootLayer];
    }];
    _timeIndicatorLayer.frame = CGRectMake(_timeRulerRootLayer.frame.size.width, 0.0f, _rootLayer.frame.size.width - _timeRulerRootLayer.frame.size.width, 5.0f);
    [self scrollHour:_hour];
}


#pragma mark Private

- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex
{
    NSMutableArray *weekdayEvents = [[dataSource weekView:self eventsForColumnAtIndex:anIndex] mutableCopy];
    NSArray *allDayEvents = [weekdayEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isAllDay == YES"]];
    for (id event in allDayEvents)
        [weekdayEvents removeObjectIdenticalTo:event];

    CALayer *weekdayRootLayer = [_weekdayRootLayers objectAtIndex:anIndex];
    WLCalendarWeekdayEventsLayer *weekdayLayer = [weekdayRootLayer
                                                  valueForKeyPath:@"weekdayEventsBackground.weekdayEventsScroll.weekdayEvents"];
    [weekdayLayer setEvents:[NSSet setWithArray:weekdayEvents]];
    [weekdayEvents release];
    WLCalendarAllDayEventsLayer *alldayLayer = [weekdayRootLayer
                                                valueForKeyPath:@"weekdayEventsAllDayBackground.weekdayEventsAllDay"];
    [alldayLayer setEvents:allDayEvents];
}

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex
{
    CALayer *weekdayRootLayer = [_weekdayRootLayers objectAtIndex:anIndex];
    CATextLayer *titleLayer = [weekdayRootLayer valueForKeyPath:@"weekdayEventsBackground.weekdayEventsTitle"];
    titleLayer.string = [dataSource weekView:self titleForColumnAtIndex:anIndex];
}

- (void)_updateColumnAtIndex:(NSUInteger)anIndex
{
    [CATransaction begin];
    [self _updateEventsOfColumnAtIndex:anIndex];
    [self _updateTitleOfColumnAtIndex:anIndex];
    [CATransaction commit];
}

- (CALayer *)_setupTimeRulerLayer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    WLCalendarTimeRulerLayer *timeRulerLayer = [WLCalendarTimeRulerLayer layer];
    timeRulerLayer.name = _WLTimeRulerLayer;
    timeRulerLayer.timeRuler = dataSource;
    timeRulerLayer.autoresizingMask = kCALayerWidthSizable;

    CAScrollLayer *scrollLayer = [CAScrollLayer layer];
    scrollLayer.name = _WLTimeRulerScrollLayer;
    scrollLayer.scrollMode = kCAScrollVertically;
    scrollLayer.geometryFlipped = YES;
    scrollLayer.autoresizingMask = kCALayerWidthSizable;
#ifdef DEBUG_LAYERS
    scrollLayer.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    [scrollLayer addSublayer:timeRulerLayer];
    [scrollLayer setValue:timeRulerLayer forKey:timeRulerLayer.name];

    WLCalendarBackgroundLayer *backgroundLayer = [WLCalendarBackgroundLayer layer];
    backgroundLayer.name = _WLTimeRulerBackgroundLayer;
    backgroundLayer.masksToBounds = YES;
    backgroundLayer.contentsBackgroundColor = [[NSColor colorWithCalibratedRed:101.0f / 255.0f
                                                                         green:161.0f / 255.0f
                                                                          blue:165.0f / 255.0f
                                                                         alpha:1.0f] WL_CGColor];
    backgroundLayer.contentsBackgroundOpacity = 0.15;
#ifdef DEBUG_LAYERS
    backgroundLayer.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    [backgroundLayer addSublayer:scrollLayer];
    [backgroundLayer setValue:scrollLayer forKey:scrollLayer.name];
    [CATransaction commit];
    return backgroundLayer;
}

- (CALayer *)_setupWeekdayLayer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    WLCalendarWeekdayEventsLayer *eventLayer = [WLCalendarWeekdayEventsLayer layer];
    eventLayer.name = _WLWeekdayEventsLayer;
    eventLayer.timeRuler = dataSource;
    eventLayer.autoresizingMask = kCALayerWidthSizable;

    CAScrollLayer *scrollLayer = [CAScrollLayer layer];
    scrollLayer.name = _WLWeekdayEventsScrollLayer;
    scrollLayer.geometryFlipped = YES;
#ifdef DEBUG_LAYERS
    scrollLayer.backgroundColor = [[NSColor orangeColor] WL_CGColor];
#endif
    [scrollLayer addSublayer:eventLayer];
    [scrollLayer setValue:eventLayer forKey:eventLayer.name];

    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.name = _WLWeekdayEventsTitleLayer;
    titleLayer.wrapped = NO;
    titleLayer.truncationMode = kCATruncationNone;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.fontSize = 14.0f;
    titleLayer.shadowOpacity = 1.0f;
    titleLayer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    titleLayer.shadowRadius = 1.0f;
#ifdef DEBUG_LAYERS
    titleLayer.backgroundColor = [[NSColor blueColor] WL_CGColor];
#endif

    WLCalendarBackgroundLayer *eventsBackgroundLayer = [WLCalendarBackgroundLayer layer];
    eventsBackgroundLayer.name = _WLWeekdayEventsBackgroundLayer;
    eventsBackgroundLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    eventsBackgroundLayer.contentsBackgroundColor = [[NSColor colorWithCalibratedRed:54.0f / 255.0f
                                                                               green:54.0f / 255.0f
                                                                                blue:54.0f / 255.0f
                                                                               alpha:1.0f] WL_CGColor];
    eventsBackgroundLayer.contentsBackgroundOpacity = 0.3f;
#ifdef DEBUG_LAYERS
    eventsBackgroundLayer.backgroundColor = [[NSColor darkGrayColor] WL_CGColor];
#endif
    [eventsBackgroundLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                                    relativeTo:@"superlayer"
                                                                     attribute:kCAConstraintMinX]];
    [eventsBackgroundLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                                    relativeTo:@"superlayer"
                                                                     attribute:kCAConstraintWidth]];
    [eventsBackgroundLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                                    relativeTo:_WLWeekdayEventsAllDayBackgroundLayer
                                                                     attribute:kCAConstraintMinY
                                                                        offset:_WLYMarginBetweenAllDayAndWeekdayEvents]];
    [eventsBackgroundLayer addSublayer:scrollLayer];
    [eventsBackgroundLayer addSublayer:titleLayer];
    [eventsBackgroundLayer setValue:scrollLayer forKey:scrollLayer.name];
    [eventsBackgroundLayer setValue:titleLayer forKey:titleLayer.name];

    WLCalendarAllDayEventsLayer *allDayEventsLayer = [WLCalendarAllDayEventsLayer layer];
    allDayEventsLayer.name = _WLWeekdayEventsAllDayLayer;
    allDayEventsLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    allDayEventsLayer.geometryFlipped = YES;

    WLCalendarBackgroundLayer *eventsAllDayBackgroundLayer = [WLCalendarBackgroundLayer layer];
    eventsAllDayBackgroundLayer.name = _WLWeekdayEventsAllDayBackgroundLayer;
    eventsAllDayBackgroundLayer.masksToBounds = YES;
    eventsAllDayBackgroundLayer.contentsBackgroundColor = [[NSColor colorWithCalibratedRed:101.0f / 255.0f
                                                                                     green:161.0f / 255.0f
                                                                                      blue:165.0f / 255.0f
                                                                                     alpha:1.0f] WL_CGColor];
    eventsAllDayBackgroundLayer.contentsBackgroundOpacity = 0.15f;

#ifdef DEBUG_LAYERS
    eventsAllDayBackgroundLayer.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    [eventsAllDayBackgroundLayer addSublayer:allDayEventsLayer];
    [eventsAllDayBackgroundLayer setValue:allDayEventsLayer forKey:allDayEventsLayer.name];

    CALayer *contentLayer = [CALayer layer];
    contentLayer.name = _WLWeekdayEventsContent;
    contentLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
#ifdef DEBUG_LAYERS
    contentLayer.backgroundColor = [[NSColor redColor] WL_CGColor];
#endif
    [contentLayer addSublayer:eventsBackgroundLayer];
    [contentLayer addSublayer:eventsAllDayBackgroundLayer];
    [contentLayer setValue:eventsBackgroundLayer forKey:eventsBackgroundLayer.name];
    [contentLayer setValue:eventsAllDayBackgroundLayer forKey:eventsAllDayBackgroundLayer.name];
    [CATransaction commit];
    return contentLayer;
}

- (NSArray *)_allDayEventsBackgroundLayerConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinX]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintWidth]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMaxY]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMaxY
                                                          offset:-allDayEventsHeight]];
    return constraints;
}

- (NSArray *)_weekdayEventsBackgrounLayerConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinX]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintWidth]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                      relativeTo:_WLWeekdayEventsAllDayBackgroundLayer
                                                       attribute:kCAConstraintMinY
                                                          offset:-_WLYMarginBetweenAllDayAndWeekdayEvents]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinY]];
    return constraints;
}

- (NSArray *)_weekdayTitleLayerConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinX]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintWidth]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMaxY]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMaxY
                                                          offset:-_WLWeekdayEventsTitleLayerHeight]];
    return constraints;
}

- (NSArray *)_weekdayEventsLayerConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinX]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintWidth]];
    return constraints;
}

- (NSArray *)_weekdayEventsScrollLayerConstraintsWithTopYMargin:(CGFloat)yMargin
{
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinX]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintWidth]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                      relativeTo:_WLWeekdayEventsTitleLayer
                                                       attribute:kCAConstraintMinY
                                                          offset:-yMargin]];
    [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                      relativeTo:@"superlayer"
                                                       attribute:kCAConstraintMinY]];
    return constraints;
}

- (void)_layoutTimerRulerRootlayer:(CALayer *)aRootLayer
{
    CAScrollLayer *timeRulerScrollLayer = [aRootLayer valueForKeyPath:_WLTimeRulerScrollLayer];
    WLCalendarTimeRulerLayer *timeRulerLayer = [timeRulerScrollLayer valueForKeyPath:_WLTimeRulerLayer];
    CGSize timeRulerSize = [timeRulerLayer preferredFrameSize];
    aRootLayer.frame = CGRectMake(0.0f,
                                  0.0f,
                                  timeRulerSize.width,
                                  self.bounds.size.height - self.allDayEventsHeight - _WLYMarginBetweenAllDayAndWeekdayEvents);
    [timeRulerLayer setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];
    [timeRulerScrollLayer setValue:[NSNumber numberWithFloat:aRootLayer.bounds.size.height - _WLWeekdayEventsTitleLayerHeight]
                        forKeyPath:@"frame.size.height"];
}

- (void)_layoutWeekdayRootLayer:(CALayer *)aRootLayer
{
    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer valueForKeyPath:@"timeRulerScroll.timeRuler"];
    CGSize timeRulerSize = [timeRulerLayer preferredFrameSize];

    CALayer *allDayEventsBackgroundLayer = [aRootLayer valueForKeyPath:_WLWeekdayEventsAllDayBackgroundLayer];
    allDayEventsBackgroundLayer.constraints = [self _allDayEventsBackgroundLayerConstraints];

    CALayer *weekdayEventsBackgroundLayer = [aRootLayer valueForKeyPath:_WLWeekdayEventsBackgroundLayer];
    weekdayEventsBackgroundLayer.constraints = [self _weekdayEventsBackgrounLayerConstraints];

    CAScrollLayer *weekdayEventsScrollLayer = [weekdayEventsBackgroundLayer valueForKeyPath:_WLWeekdayEventsScrollLayer];
    weekdayEventsScrollLayer.constraints = [self _weekdayEventsScrollLayerConstraintsWithTopYMargin:
                                            [timeRulerLayer firstHourYPadding]];

    WLCalendarWeekdayEventsLayer *weekdayEventsLayer = [weekdayEventsBackgroundLayer valueForKeyPath:
                                                        @"weekdayEventsScroll.weekdayEvents"];
    [weekdayEventsLayer setValue:[NSNumber numberWithFloat:timeRulerSize.height] forKeyPath:@"frame.size.height"];

    CATextLayer *textLayer = [weekdayEventsBackgroundLayer valueForKeyPath:_WLWeekdayEventsTitleLayer];
    textLayer.constraints = [self _weekdayTitleLayerConstraints];
}

- (void)_positionWeekdayRootLayer:(CALayer *)aRootLayer atIndex:(NSUInteger)anIndex
{
    NSRect bounds = [self bounds];

    WLCalendarTimeRulerLayer *timeRulerLayer = [_timeRulerRootLayer valueForKeyPath:@"timeRulerScroll.timeRuler"];
    CGSize timeRulerSize = [timeRulerLayer preferredFrameSize];

    CGFloat spaces = _WLXMarginBetweenColumns * [_weekdayRootLayers count];
    CGFloat width = (self.bounds.size.width - timeRulerSize.width - spaces) / [_weekdayRootLayers count];
    CGFloat x = timeRulerSize.width + _WLXMarginBetweenColumns + anIndex * (width + _WLXMarginBetweenColumns);

    aRootLayer.frame = CGRectMake(ceilf(x), 0.0f, width, bounds.size.height);
}

@end

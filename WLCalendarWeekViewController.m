//
//  WLCalendarWeekViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWeekViewController.h"
#import "NSDate+WLDayBoundaries.h"
#import "WLDateRange.h"
#import "NSColor+CGColor.h"


static NSString* const _WLDateFormatterCacheKey = @"dateFormatter";

static NSString* const _WLColumnTitleFormatCacheKey = @"titleFormat";


static NSString* const _WLTitleKey = @"title";

static NSString* const _WLEventsKey = @"events";


/*!
 @discussion Used when mode is WLCalendarWeekViewDayMode.
 */
static const NSInteger _WLNumberOfDaysInWeek = 7;


@implementation WLCalendarWeekViewController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        view = [[WLCalendarWeekView alloc] init];
        view.dataSource = self;
        view.fitDayEvents = YES;
        highlightWeekends = YES;
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(_eventsChanged:)
                                   name:CalEventsChangedExternallyNotification
                                 object:[CalCalendarStore defaultCalendarStore]];
        [notificationCenter addObserver:self
                               selector:@selector(_eventsChanged:)
                                   name:CalEventsChangedNotification
                                 object:[CalCalendarStore defaultCalendarStore]];

        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarWeekViewController cache"];
        _columnDateRanges = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [view release];
    [date release];
    [calcalendars release];
    [calendar release];

    [_cache release];
    [_scrollTimer invalidate];
    [_columnsData release];
    [_columnDateRanges release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Properties
@synthesize view;
@synthesize mode;
@synthesize titleFormat;
@synthesize date;
@synthesize calcalendars;
@synthesize calendar;
@synthesize highlightWeekends;

- (void)setMode:(WLCalendarWeekViewMode)newMode
{
    if (newMode != mode)
    {
        _updateFlags.reload = YES;
        mode = newMode;
    }
}

- (void)setTitleFormat:(WLCalendarWeekViewTitleFormat)newFormat
{
    if (newFormat != titleFormat)
    {
        _updateFlags.updateTitles = YES;
        self._columnTitleFormat = nil;
        titleFormat = newFormat;
    }
}

- (void)setDate:(NSDate *)newDate
{
    if (![newDate isEqual:date])
    {
        _updateFlags.reload = YES;
        [newDate retain];
        [date release];
        date = newDate;
    }
}

- (void)setCalcalendars:(NSArray *)newCalendars
{
    if (newCalendars != calcalendars)
    {
        _updateFlags.updateEvents = YES;
        [calcalendars release];
        calcalendars = [newCalendars copy];
    }
}

- (void)setCalendar:(NSCalendar *)newCalendar
{
    if (newCalendar != calendar) {
        _updateFlags.reload = YES;
        [newCalendar retain];
        [calendar release];
        calendar = newCalendar;
    }
}

- (void)setHighlightWeekends:(BOOL)newHighlight
{
    if (newHighlight != highlightWeekends)
    {
        _updateFlags.reload = YES;
        highlightWeekends = newHighlight;
    }
}


#pragma mark Methods

- (void)updateViewAnimated:(BOOL)isAnimated
{
    NSParameterAssert(date != nil);
    NSParameterAssert(calcalendars != nil);
    NSParameterAssert(calendar != nil);

    if ([view wantsLayer] && !_updateFlags.reload)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:!isAnimated];
        NSIndexSet *columnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfColumnsInWeekView:view])];
        if (_updateFlags.updateTitles && _updateFlags.updateEvents)
            [view updateColumnsAtIndexes:columnIndexes];
        else if (_updateFlags.updateTitles)
            [view updateTitleOfColumnsAtIndexes:columnIndexes];
        else if (_updateFlags.updateEvents)
            [view updateEventsOfColumnsAtIndexes:columnIndexes];
        [CATransaction commit];
    }
    else
    {
        [view setupLayersAnimated:isAnimated];
        [self _scheduleScrollTimer];
    }

    _updateFlags.reload = NO;
    _updateFlags.updateTitles = NO;
    _updateFlags.updateEvents = NO;
}

- (void)showNextDayAndScroll
{
    [CATransaction begin];
    [view showNextDay];
    [_scrollTimer fire];
    [CATransaction commit];
}

- (void)showNextWeekAndScroll
{
    [CATransaction begin];
    [view showNextWeek];
    [_scrollTimer fire];
    [CATransaction commit];
}

- (CGFloat)currentHour
{
    NSParameterAssert(calendar != nil);

    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit
                                               fromDate:now];
    CGFloat hour = [components hour];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:now];
    hour += (CGFloat)[components minute] / minutesRange.length;
    return hour;
}

- (void)scrollToCurrentHour
{
    [[self view] scrollHour:[self currentHour] animated:![CATransaction disableActions]];
}

- (NSDate *)firstColumnDate
{
    NSParameterAssert(date != nil);
    NSParameterAssert(calendar != nil);

    switch (mode) {
        case WLCalendarWeekViewDayMode:
        {
            NSDate *today = [NSDate date];
            NSDateComponents *todayNoonComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                                fromDate:today];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:today];
            [todayNoonComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:todayNoonComponents];
        }
        case WLCalendarWeekViewWeekMode:
        {
            NSDateComponents *firstWeekdayComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit
                                                              fromDate:date];
            NSRange weekdaysRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:date];
            [firstWeekdayComponents setDay:weekdaysRange.location];
            NSDate *firstWeekday = [calendar dateFromComponents:firstWeekdayComponents];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:firstWeekday];
            [firstWeekdayComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:firstWeekdayComponents];
        }
    }
}

- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate
{
    NSParameterAssert(calendar != nil);

#ifdef DEBUG_PERFORMANCE
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), anIndexSet);
#endif
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    [offset setDay:[anIndexSet firstIndex]];
    NSDate *startDate = [[calendar dateByAddingComponents:offset toDate:aFirstDate options:0] WL_upperBoundaryWithCalendar:calendar];
    [offset setDay:[anIndexSet lastIndex]];
    NSDate *endDate = [[calendar dateByAddingComponents:offset toDate:aFirstDate options:0] WL_lowerBoundaryWithCalendar:calendar];
    [offset release];
    NSPredicate *p = [CalCalendarStore eventPredicateWithStartDate:startDate
                                                           endDate:endDate
                                                         calendars:calcalendars];
    return [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:p];
}


#pragma mark WLCalendarWeekViewDataSource

- (NSUInteger)numberOfHoursInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSParameterAssert(calendar != nil);

    NSRange hoursRange = [calendar maximumRangeOfUnit:NSHourCalendarUnit];
    return hoursRange.length;
}

- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate
{
    NSParameterAssert(calendar != nil);

    NSDateComponents *comp = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:aDate];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:aDate];
    return ((CGFloat)[comp hour] + (CGFloat)([comp minute] - minutesRange.location) / minutesRange.length);
}

- (NSString *)stringForHour:(NSUInteger)aHour
{
    NSParameterAssert(calendar != nil);

    NSDateComponents *hourComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                   fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0.0]];
    [hourComponents setHour:aHour];

    NSDateFormatter *f = self._dateFormatter;
    [f setCalendar:calendar];
    [f setDateStyle:NSDateFormatterNoStyle];
    [f setTimeStyle:NSDateFormatterShortStyle];
    return [f stringFromDate:[calendar dateFromComponents:hourComponents]];
}

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSParameterAssert(calendar != nil);
    NSParameterAssert(date != nil);

    if (mode == WLCalendarWeekViewWeekMode)
    {
        NSRange weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:date];
        return weekdaysRange.length;
    }
    else
        return _WLNumberOfDaysInWeek;
}

// -[CalCalendarStore eventsWithPredicate:] can take a relatively long time. This optimization allows us to call that method only once.
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    NSParameterAssert(calendar != nil);

#ifdef DEBUG_PERFORMANCE
    NSLog(@"%@", NSStringFromSelector(_cmd));
#endif
    _columnsData = [[NSMutableDictionary alloc] initWithCapacity:[anIndexSet count]];

    NSDate *firstDate = [self firstColumnDate];

    NSArray *events = nil;
    if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        events = [self eventsForColumnsAtIndexes:anIndexSet firstDate:firstDate];

    NSDateComponents *columnDateComponents = [[NSDateComponents alloc] init];
    NSDateFormatter *titleFormatter = self._dateFormatter;
    [titleFormatter setCalendar:calendar];
    [titleFormatter setDateFormat:self._columnTitleFormat];
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger columnIdx, BOOL *stop)
     {
         [columnDateComponents setDay:columnIdx];
         NSDate *columnDate = [calendar dateByAddingComponents:columnDateComponents toDate:firstDate options:0];
         NSMutableDictionary *columnData = [NSMutableDictionary dictionary];

         if (dataUnits & WLCalendarWeekViewEventsDataUnit)
         {
#ifdef DEBUG_PERFORMANCE
             NSLog(@"Prepare weekView events");
#endif
             NSDate *upperBound = [columnDate WL_upperBoundaryWithCalendar:calendar];
             NSDate *lowerBound = [upperBound WL_lowerBoundaryWithCalendar:calendar];
             WLDateRange *columnDateRange = [WLDateRange dateRangeWithStartDate:upperBound endDate:lowerBound];
             [_columnDateRanges setObject:columnDateRange forKey:[NSNumber numberWithUnsignedInteger:columnIdx]];
             NSMutableArray *columnEvents = [NSMutableArray array];
             for (CalEvent *event in events)
             {
                 WLDateRange *eventRange = [WLDateRange dateRangeWithStartDate:event.startDate endDate:event.endDate];
                 WLPositionRelativeToRange position;
                 BOOL intresects = [columnDateRange intersectsRange:eventRange position:&position];
                 if (intresects)
                 {
                     if (position == WLWithinRange)
                         [columnEvents addObject:event];
                     // If an event takes more than 1 day, divide it into multiple events for each column.
                     else if (position == WLEarlierThanRange && [eventRange.endDate compare:columnDateRange.startDate] != NSOrderedSame)
                     {
                         CalEvent *partEvent = [event copy];
                         partEvent.startDate = upperBound;
                         [columnEvents addObject:partEvent];
                         [partEvent release];
                     }
                     else if (position == WLOverlapsRange)
                     {
                         CalEvent *partEvent = [event copy];
                         partEvent.startDate = upperBound;
                         partEvent.endDate = lowerBound;
                         [columnEvents addObject:partEvent];
                         [partEvent release];
                     }
                     else if (position == WLLaterThanRange && [columnDateRange.endDate compare:eventRange.startDate] != NSOrderedSame)
                     {
                         CalEvent *partEvent = [event copy];
                         partEvent.endDate = lowerBound;
                         [columnEvents addObject:partEvent];
                         [partEvent release];
                     }
                 }
             }
             [columnData setObject:columnEvents forKey:_WLEventsKey];
         }

         if (dataUnits & WLCalendarWeekViewTitleDataUnit)
         {
#ifdef DEBUG_PERFORMANCE
             NSLog(@"Prepare weekView title");
#endif
             [columnData setObject:[titleFormatter stringFromDate:columnDate] forKey:_WLTitleKey];
         }
         [_columnsData setObject:columnData forKey:[NSNumber numberWithUnsignedInteger:columnIdx]];
     }];
    [columnDateComponents release];
}

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex
{
    return [(NSDictionary *)[_columnsData objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] objectForKey:_WLTitleKey];
}

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex
{
    return [(NSDictionary *)[_columnsData objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] objectForKey:_WLEventsKey];
}

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView
{
    [_columnsData release];
    _columnsData = nil;
}

- (void)weekViewDidSetupLayers:(WLCalendarWeekView *)aWeekView
{
    [view scrollHour:[self currentHour] animated:![CATransaction disableActions]];
}

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex
{
    BOOL isWeekend = NO;
    if (highlightWeekends)
    {
        // heuristics: typically last 2 days of a week are weekends.
        if (mode == WLCalendarWeekViewWeekMode)
        {
            NSRange weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:date];
            isWeekend = (anIndex == NSMaxRange(weekdaysRange) - 2 || anIndex == NSMaxRange(weekdaysRange) - 3);
        }
        else
        {
            NSDateComponents *c = [calendar components:NSWeekdayCalendarUnit fromDate:[self firstColumnDate]];
            NSInteger columnWeekday = ([c weekday] + anIndex - [calendar firstWeekday]) %  _WLNumberOfDaysInWeek;
            isWeekend = (columnWeekday == _WLNumberOfDaysInWeek - 1 || columnWeekday == _WLNumberOfDaysInWeek - 2);
        }
    }

    if (isWeekend)
       return [[NSColor redColor] WL_CGColor];
    else
    {
        return [[NSColor colorWithCalibratedRed:101.0f / 255.0f
                                          green:161.0f / 255.0f
                                           blue:165.0f / 255.0f
                                          alpha:1.0f] WL_CGColor];
    }
}


#pragma mark Private
@dynamic _dateFormatter;
@dynamic _columnTitleFormat;

- (NSDateFormatter *)_dateFormatter
{
    NSDateFormatter *f = [_cache objectForKey:_WLDateFormatterCacheKey];
    if (f == nil) {
        f = [[[NSDateFormatter alloc] init] autorelease];
        [_cache setObject:f forKey:_WLDateFormatterCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLDateFormatterCacheKey);
#endif
    return f;
}

- (void)set_dateFormatter:(NSDateFormatter *)newDateFormatter
{
    NSParameterAssert(newDateFormatter == nil);
    [_cache removeObjectForKey:_WLDateFormatterCacheKey];
}

- (NSString *)_columnTitleFormat
{
    NSString *f = [_cache objectForKey:_WLColumnTitleFormatCacheKey];
    if (f == nil)
    {
        if (titleFormat == WLCalendarWeekViewWeekdayAndMonthdayTitleFormat)
            f = [NSDateFormatter dateFormatFromTemplate:@"eeedMMM" options:0 locale:[NSLocale autoupdatingCurrentLocale]];
        else
            f = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:[NSLocale autoupdatingCurrentLocale]];
        [_cache setObject:f forKey:_WLColumnTitleFormatCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLColumnTitleFormatCacheKey);
#endif
    return f;
}

- (void)set_columnTitleFormat:(NSString *)newFormat
{
    NSParameterAssert(newFormat == nil);
    [_cache removeObjectForKey:_WLColumnTitleFormatCacheKey];
}

- (void)_eventsChanged:(NSNotification *)aNotification
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"Update columns");
#endif
    NSUInteger numberOfColumns = [self numberOfColumnsInWeekView:[self view]];
    [[self view] updateEventsOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];
}

- (void)_scheduleScrollTimer
{
    NSParameterAssert(calendar != nil);

    [_scrollTimer invalidate];
    NSRange minutesRange = [calendar maximumRangeOfUnit:NSMinuteCalendarUnit];
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)minutesRange.length
                                                    target:self
                                                  selector:@selector(scrollToCurrentHour)
                                                  userInfo:nil
                                                   repeats:YES];
}

@end

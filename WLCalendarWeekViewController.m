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
#import "NSColor+WLCalendar.h"
#import "NSColor+CGColor.h"
#import "NSCalendar+WLWeekend.h"


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
        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarWeekViewController cache"];
        _columnDateRanges = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_cache release];
    [_columnsData release];
    [_columnDateRanges release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Properties
@synthesize mode;
@synthesize titleFormat;
@synthesize highlightWeekends;

- (void)setMode:(WLCalendarWeekViewMode)newMode
{
    NSParameterAssert([self representedObject] != nil);

    mode = newMode;
    if (isViewLoaded)
    {
        [[self view] reloadDataAnimated:YES];
        [self highlightCurrentDayIfNeeded];
    }
}

- (void)setTitleFormat:(WLCalendarWeekViewTitleFormat)newFormat
{
    NSParameterAssert([self representedObject] != nil);

    self._columnTitleFormat = nil;
    titleFormat = newFormat;
    if (isViewLoaded)
        [[self view] updateTitleOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfColumnsInWeekView:[self view]])]];
}

- (void)setHighlightWeekends:(BOOL)newHighlight
{
    NSParameterAssert([self representedObject] != nil);

    highlightWeekends = newHighlight;
    if (isViewLoaded)
        [[self view] updateColorOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfColumnsInWeekView:[self view]])]];
}


#pragma mark Methods

- (void)showNextDayAndScroll
{
    [[self view] showNextDay];
    [self highlightCurrentDayIfNeeded];
    [self scrollToCurrentHour];
}

- (void)showNextWeekAndScroll
{
    [[self view] showNextWeek];
    [self highlightCurrentDayIfNeeded];
    [self scrollToCurrentHour];
}

- (CGFloat)currentHour
{
    NSParameterAssert([self representedObject] != nil);

    NSDate *now = [[self representedObject] date];
    NSCalendar *calendar = [[self representedObject] calendar];
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

- (NSUInteger)currentDay
{
    NSParameterAssert([self representedObject] != nil);

    if (self.mode == WLCalendarWeekViewDayMode)
        return 0;
    else
    {
        NSCalendar *calendar = [[self representedObject] calendar];
        NSDateComponents *firstColumnDateComponents = [calendar components:NSDayCalendarUnit fromDate:[self firstColumnDate]];
        NSDateComponents *todayComponents = [calendar components:NSDayCalendarUnit fromDate:[[self representedObject] date]];
        return [todayComponents day] - [firstColumnDateComponents day];
    }
}

- (void)highlightCurrentDayIfNeeded
{
//    if (self.mode == WLCalendarWeekViewWeekMode)
//        [[self view] setIndexOfHighlightedColumn:[self currentDay]];
//    else
//        [[self view] setIndexOfHighlightedColumn:NSNotFound];
}

- (NSDate *)firstColumnDate
{
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSDate *date = [[self representedObject] date];
    switch (mode) {
        case WLCalendarWeekViewDayMode:
        {
            NSDateComponents *dateNoonComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:date];
            [dateNoonComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:dateNoonComponents];
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
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSArray *calCalendars = [[self representedObject] calCalendars];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    [offset setDay:[anIndexSet firstIndex]];
    NSDate *startDate = [[calendar dateByAddingComponents:offset toDate:aFirstDate options:0] WL_upperBoundaryWithCalendar:calendar];
    [offset setDay:[anIndexSet lastIndex]];
    NSDate *endDate = [[calendar dateByAddingComponents:offset toDate:aFirstDate options:0] WL_lowerBoundaryWithCalendar:calendar];
    [offset release];
    NSPredicate *p = [CalCalendarStore eventPredicateWithStartDate:startDate
                                                           endDate:endDate
                                                         calendars:calCalendars];
    return [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:p];
}


#pragma mark WLCalendarWeekViewDataSource

- (NSUInteger)numberOfHoursInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSParameterAssert([self representedObject] != nil);

    NSRange hoursRange = [[[self representedObject] calendar] maximumRangeOfUnit:NSHourCalendarUnit];
    return hoursRange.length;
}

- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate
{
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSDateComponents *c = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:aDate];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:aDate];
    return ((CGFloat)[c hour] + (CGFloat)([c minute] - minutesRange.location) / minutesRange.length);
}

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView stringForHour:(NSUInteger)aHour;
{
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
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
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSDate *date = [[self representedObject] date];
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
    _columnsData = [[NSMutableDictionary alloc] initWithCapacity:[anIndexSet count]];

    NSDate *firstDate = [self firstColumnDate];

    NSArray *events = nil;
    if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        events = [self eventsForColumnsAtIndexes:anIndexSet firstDate:firstDate];

    NSDateComponents *columnDateComponents = [[NSDateComponents alloc] init];
    NSDateFormatter *titleFormatter = self._dateFormatter;
    NSCalendar *calendar = [[self representedObject] calendar];
    [titleFormatter setCalendar:calendar];
    [titleFormatter setDateFormat:self._columnTitleFormat];
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger columnIdx, BOOL *stop)
    {
        [columnDateComponents setDay:columnIdx];
        NSDate *columnDate = [calendar dateByAddingComponents:columnDateComponents toDate:firstDate options:0];
        NSMutableDictionary *columnData = [NSMutableDictionary dictionary];
        NSDate *upperBound = [columnDate WL_upperBoundaryWithCalendar:calendar];
        NSDate *lowerBound = [upperBound WL_lowerBoundaryWithCalendar:calendar];
        WLDateRange *columnDateRange = [WLDateRange dateRangeWithStartDate:upperBound endDate:lowerBound];
        [_columnDateRanges setObject:columnDateRange forKey:[NSNumber numberWithUnsignedInteger:columnIdx]];

        if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        {
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
            [columnData setObject:[titleFormatter stringFromDate:columnDate] forKey:_WLTitleKey];
        [_columnsData setObject:columnData forKey:[NSNumber numberWithUnsignedInteger:columnIdx]];
    }];
    [columnDateComponents release];
}

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert(_columnsData != nil);

    return [(NSDictionary *)[_columnsData objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] objectForKey:_WLTitleKey];
}

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert(_columnsData != nil);

    return [(NSDictionary *)[_columnsData objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] objectForKey:_WLEventsKey];
}

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView
{
    [_columnsData release];
    _columnsData = nil;
}

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex
{
    BOOL isWeekend = NO;
    if (highlightWeekends)
    {
        NSCalendar *calendar = [[self representedObject] calendar];
        NSDate *columnDate = [(WLDateRange *)[_columnDateRanges objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] startDate];
        NSParameterAssert(columnDate != nil);
        NSDateComponents *c = [calendar components:NSWeekdayCalendarUnit fromDate:columnDate];
        isWeekend = [calendar isWeekend:(NSUInteger)[c weekday]];
    }

    if (isWeekend)
        return [[NSColor WL_weekendColor] WL_CGColor];
    else
        return [[NSColor WL_columnColor] WL_CGColor];
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
    return f;
}

- (void)set_columnTitleFormat:(NSString *)newFormat
{
    NSParameterAssert(newFormat == nil);
    [_cache removeObjectForKey:_WLColumnTitleFormatCacheKey];
}

- (void)_eventsDidChange:(NSNotification *)aNotification
{
    NSArray *insertedEvents = [[aNotification userInfo] objectForKey:CalInsertedRecordsKey];
    NSArray *deletedEvents = [[aNotification userInfo] objectForKey:CalDeletedRecordsKey];
    NSArray *updatedEvents = [[aNotification userInfo] objectForKey:CalUpdatedRecordsKey];
    NSMutableIndexSet *columnIndexes = [NSMutableIndexSet indexSet];
    NSUInteger numberOfColumns = [self numberOfColumnsInWeekView:[self view]];
    if ([updatedEvents count] == 0 && deletedEvents == 0)
    {
        for (NSString *uid in insertedEvents)
        {
            CalEvent *e = [[CalCalendarStore defaultCalendarStore] eventWithUID:uid occurrence:nil];
            for (NSNumber *idx in _columnDateRanges)
            {
                if ([[_columnDateRanges objectForKey:idx] intersectsRange:[WLDateRange dateRangeWithStartDate:e.startDate endDate:e.endDate]])
                    [columnIndexes addIndex:[idx unsignedIntegerValue]];
            }
            if ([columnIndexes containsIndexesInRange:NSMakeRange(0, numberOfColumns)])
                break;
        }
    }
    else
    {
        // Unfortunately, we don't know where events may be deleted or moved from.
        [columnIndexes addIndexesInRange:NSMakeRange(0, numberOfColumns)];
    }
    [[self view] updateEventsOfColumnsAtIndexes:columnIndexes];
}


#pragma mark NSViewController

- (void)loadView
{
    WLCalendarWeekView *v = [[WLCalendarWeekView alloc] init];
    [self setView:v];
    v.dataSource = self;
    v.fitDayEvents = YES;
    [v scrollHour:[self currentHour] animated:NO];
    [v createLayers];
//    if (self.mode == WLCalendarWeekViewWeekMode)
//        v.indexOfHighlightedColumn = [self currentDay];
    [v release];
    [self addObserver:self forKeyPath:@"representedObject.date" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"representedObject.calendar" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"representedObject.calCalendars" options:NSKeyValueObservingOptionNew context:NULL];
    NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
    [n addObserver:self
          selector:@selector(_eventsDidChange:)
              name:CalEventsChangedExternallyNotification
            object:[CalCalendarStore defaultCalendarStore]];
    [n addObserver:self
          selector:@selector(_eventsDidChange:)
              name:CalEventsChangedNotification
            object:[CalCalendarStore defaultCalendarStore]];
    isViewLoaded = YES;
}

- (WLCalendarWeekView *)view
{
    return (WLCalendarWeekView *)[super view];
}

- (WLCalendarController *)representedObject
{
    return (WLCalendarController *)[super representedObject];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqual:@"representedObject.calendar"] || [aKeyPath isEqual:@"representedObject.calCalendars"])
        [[self view] reloadDataAnimated:YES];
    else if ([aKeyPath isEqual:@"representedObject.date"])
    {
        NSDate *old = [aChange objectForKey:NSKeyValueChangeOldKey];
        NSDate *new = [aChange objectForKey:NSKeyValueChangeNewKey];
        if ([new compare:old] == NSOrderedAscending)
        {
            [[self view] reloadDataAnimated:YES];
            [self scrollToCurrentHour];
        }
        else
        {
            NSCalendar *calendar = [[self representedObject] calendar];
            NSDateComponents *oldComponents = [calendar components:NSWeekCalendarUnit | NSDayCalendarUnit fromDate:old];
            NSDateComponents *newComponents = [calendar components:NSWeekCalendarUnit | NSDayCalendarUnit fromDate:new];
            if (self.mode == WLCalendarWeekViewWeekMode && [oldComponents week] != [newComponents week])
                [self showNextWeekAndScroll];
            else if (self.mode == WLCalendarWeekViewDayMode && [oldComponents day] != [newComponents day])
                [self showNextDayAndScroll];
            else
                [self scrollToCurrentHour];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

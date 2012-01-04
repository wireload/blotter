//
//  WLCalendarWeekViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarWeekViewController.h"
#import "NSDate+WLDayBoundaries.h"
#import "NSColor+WLCalendar.h"
#import "NSCalendar+WLWeekend.h"


static NSString* const _WLDateFormatterCacheKey = @"dateFormatter";

static NSString* const _WLColumnTitleFormatCacheKey = @"titleFormat";

static NSString* const _WLTimeFormatCacheKey = @"timeFormat";


static NSString* const _WLTitleKey = @"title";

static NSString* const _WLEventsKey = @"events";


/*!
 @discussion Used when mode is WLCalendarWeekViewDayMode.
 */
static const NSUInteger _WLNumberOfDaysInWeek = 7;


@implementation WLCalendarWeekViewController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarWeekViewController cache"];
    }
    return self;
}

- (void)dealloc
{
    [_cache release];
    [_columnsData release];
    [self removeObserver:self forKeyPath:@"representedObject.date"];
    [self removeObserver:self forKeyPath:@"representedObject.calendar"];
    [self removeObserver:self forKeyPath:@"representedObject.calEventCalendarsToDisplay"];
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
        WLCalendarWeekView *v = [self view];
        [v reloadDataAnimated:YES];
        [self highlightCurrentDay];
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
    [self highlightCurrentDay];
    [self scrollToCurrentHour];
}

- (void)showNextWeekAndScroll
{
    [[self view] showNextWeek];
    [self highlightCurrentDay];
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

- (NSUInteger)indexOfColumnForCurrentDay
{
    NSParameterAssert([self representedObject] != nil);

    if (self.mode == WLCalendarWeekViewDayMode)
        return 0;
    else
    {
        NSCalendar *calendar = [[self representedObject] calendar];
        NSDateComponents *firstColumnDateComponents = [calendar components:NSWeekdayCalendarUnit fromDate:[self firstColumnDate]];
        NSDateComponents *todayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:[[self representedObject] date]];
        /*
         Map weekday indexes into column indexes
         Calendar: gregorian
         First weekday: Tuesday
         Number of days in a week: 7
         0  3   Tuesday
         1  4   Wednesday
         2  5   Thursday
         3  6   Friday
         4  7   Saturday
         5  1   Sunday
         6  2   Monday

         Today is Saturday:
         (7 + (7 - 3)) % 7 = 4
         */
        NSRange weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:[[self representedObject] date]];
        return (weekdaysRange.length + [todayComponents weekday] - [firstColumnDateComponents weekday]) % weekdaysRange.length;
    }
}

- (void)highlightCurrentDay
{
    [[self view] setIndexOfHighlightedColumn:[self indexOfColumnForCurrentDay]];
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
            NSDate *firstWeekday = nil;
            [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&firstWeekday interval:NULL forDate:date];
            NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:firstWeekday];
            NSDateComponents *firstWeekdayComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                                   fromDate:firstWeekday];
            [firstWeekdayComponents setHour:NSMaxRange(hoursRange) / 2];
            return [calendar dateFromComponents:firstWeekdayComponents];
        }
    }
}

- (WLDateRange *)dateRangeForColumnAtIndex:(NSUInteger)anIndex
{
    NSDateComponents *columnDateComponents = [[NSDateComponents alloc] init];
    [columnDateComponents setDay:anIndex];
    NSDate *firstColumnDate = [self firstColumnDate];
    NSCalendar *calendar = [[self representedObject] calendar];
    NSDate *columnDate = [calendar dateByAddingComponents:columnDateComponents toDate:firstColumnDate options:0];
    [columnDateComponents release];
    NSDate *upperBound = [columnDate WL_startOfDay:calendar];
    NSDate *lowerBound = [upperBound WL_endOfDay:calendar];
    return [WLDateRange dateRangeWithStartDate:upperBound endDate:lowerBound];
}

- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate
{
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSArray *calEventCalendars = [[self representedObject] calEventCalendarsToDisplay];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    [offset setDay:[anIndexSet firstIndex]];
    NSDate *startDate = [[calendar dateByAddingComponents:offset toDate:aFirstDate options:0] WL_startOfDay:calendar];
    [offset setDay:[anIndexSet lastIndex]];
    NSDate *endDate = [[calendar dateByAddingComponents:offset toDate:aFirstDate options:0] WL_endOfDay:calendar];
    [offset release];
    NSPredicate *p = [CalCalendarStore eventPredicateWithStartDate:startDate
                                                           endDate:endDate
                                                         calendars:calEventCalendars];
    // Assume there are a few calendars which events have the same UID.
    // We need to remove duplicates and do that consistently, so that the events from only 1 calendar will appear.
    NSMutableSet *eventUIDsToReturn = [NSMutableSet set];
    NSMutableArray *events = [[[[CalCalendarStore defaultCalendarStore] eventsWithPredicate:p] mutableCopy] autorelease];
    [events sortUsingComparator:^NSComparisonResult(CalEvent *e1, CalEvent *e2) {
        return [e1.calendar.uid compare:e2.calendar.uid];
    }];
    // Since events are sorted by calendar UID, by getting the first event with unique UID we will both remove duplicates and achieve consistent.
    NSMutableIndexSet *indexesOfEventsToDelete = [NSMutableIndexSet indexSet];
    [events enumerateObjectsUsingBlock:^(CalEvent *e, NSUInteger idx, BOOL *stop) {
        if (![eventUIDsToReturn containsObject:e.uid])
            [eventUIDsToReturn addObject:e.uid];
        else
            [indexesOfEventsToDelete addIndex:idx];
    }];
    [events removeObjectsAtIndexes:indexesOfEventsToDelete];
    return events;
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
    [f setDateFormat:self._timeFormat];
    return [f stringFromDate:[calendar dateFromComponents:hourComponents]];
}

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSParameterAssert([self representedObject] != nil);

    NSCalendar *calendar = [[self representedObject] calendar];
    NSDate *date = [[self representedObject] date];
    switch (self.mode) {
        case WLCalendarWeekViewWeekMode:
        {
            NSRange weekdaysRange = [calendar rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:date];
            return weekdaysRange.length;
        }
        case WLCalendarWeekViewDayMode:
            return _WLNumberOfDaysInWeek;
    }
}

// -[CalCalendarStore eventsWithPredicate:] can take a relatively long time. This optimization allows us to call that method only once.
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    _columnsData = [[NSMutableDictionary alloc] initWithCapacity:[anIndexSet count]];

    NSDate *firstDate = [self firstColumnDate];

    NSArray *events = nil;
    if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        events = [self eventsForColumnsAtIndexes:anIndexSet firstDate:firstDate];

    NSDateFormatter *titleFormatter = self._dateFormatter;
    NSCalendar *calendar = [[self representedObject] calendar];
    [titleFormatter setCalendar:calendar];
    [titleFormatter setDateFormat:self._columnTitleFormat];
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger columnIdx, BOOL *stop)
    {
        WLDateRange *columnDateRange = [self dateRangeForColumnAtIndex:columnIdx];
        NSMutableDictionary *columnData = [NSMutableDictionary dictionary];

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
                    // If an event takes more than 1 day, divide it into multiple events for each column.
                    if (position == WLWithinRange)
                        [columnEvents addObject:event];
                    else if (position == WLEarlierThanRange && [eventRange.endDate compare:columnDateRange.startDate] != NSOrderedSame)
                    {
                        CalEvent *partEvent = [event copy];
                        partEvent.startDate = columnDateRange.startDate;
                        [columnEvents addObject:partEvent];
                        [partEvent release];
                    }
                    else if (position == WLOverlapsRange)
                    {
                        CalEvent *partEvent = [event copy];
                        partEvent.startDate = columnDateRange.startDate;
                        partEvent.endDate = columnDateRange.endDate;
                        [columnEvents addObject:partEvent];
                        [partEvent release];
                    }
                    else if (position == WLLaterThanRange && [columnDateRange.endDate compare:eventRange.startDate] != NSOrderedSame)
                    {
                        CalEvent *partEvent = [event copy];
                        partEvent.endDate = columnDateRange.endDate;
                        [columnEvents addObject:partEvent];
                        [partEvent release];
                    }
                }
            }
            [columnData setObject:columnEvents forKey:_WLEventsKey];
        }

        if (dataUnits & WLCalendarWeekViewTitleDataUnit)
            [columnData setObject:[titleFormatter stringFromDate:columnDateRange.startDate] forKey:_WLTitleKey];
        [_columnsData setObject:columnData forKey:[NSNumber numberWithUnsignedInteger:columnIdx]];
    }];
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
        NSDate *columnDate = [[self dateRangeForColumnAtIndex:anIndex] startDate];
        NSParameterAssert(columnDate != nil);
        NSDateComponents *c = [calendar components:NSWeekdayCalendarUnit fromDate:columnDate];
        isWeekend = [calendar WL_isWeekend:(NSUInteger)[c weekday]];
    }

    if (isWeekend)
        return [[NSColor WL_weekendColor] WL_CGColor];
    else
        return [[NSColor WL_columnColor] WL_CGColor];
}


#pragma mark Private
@dynamic _dateFormatter;
@dynamic _columnTitleFormat;
@dynamic _timeFormat;

- (NSDateFormatter *)_dateFormatter
{
    NSDateFormatter *f = [[[_cache objectForKey:_WLDateFormatterCacheKey] retain] autorelease];
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
    NSString *f = [[[_cache objectForKey:_WLColumnTitleFormatCacheKey] retain] autorelease];
    if (f == nil)
    {
        NSCalendar *calendar = [[self representedObject] calendar];
        if (titleFormat == WLCalendarWeekViewWeekdayAndMonthdayTitleFormat)
            f = [NSDateFormatter dateFormatFromTemplate:@"eeedMMM" options:0 locale:[calendar locale]];
        else
            f = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:[calendar locale]];
        [_cache setObject:f forKey:_WLColumnTitleFormatCacheKey];
    }
    return f;
}

- (void)set_columnTitleFormat:(NSString *)newFormat
{
    NSParameterAssert(newFormat == nil);
    [_cache removeObjectForKey:_WLColumnTitleFormatCacheKey];
}

- (NSString *)_timeFormat
{
    NSString *f = [[[_cache objectForKey:_WLTimeFormatCacheKey] retain] autorelease];
    if (f == nil)
    {
        NSCalendar *calendar = [[self representedObject] calendar];
        NSDateFormatter *formatter = self._dateFormatter;
        // A user may put anything into time formatting field: year, month, day etc.
        // But we are only interested in showing hour, minute, second, AM/PM, time zone (whatever is set) and according delimiters.
        // The idea is to get the standard date format for the user specified Short Time Style and remove all other format strings, like y, M or d.
        [formatter setCalendar:calendar];
        [formatter setDateStyle:NSDateFormatterNoStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        NSMutableString *fixedFormat = [[[formatter dateFormat] mutableCopy] autorelease];
        [fixedFormat replaceOccurrencesOfString:@"G" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"y" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"Y" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"u" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"Q" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"q" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"M" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"L" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"w" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"W" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"d" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"D" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"F" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"g" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"E" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"e" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        [fixedFormat replaceOccurrencesOfString:@"c" withString:@"" options:0 range:NSMakeRange(0, [fixedFormat length])];
        f = [fixedFormat stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [_cache setObject:f forKey:_WLTimeFormatCacheKey];
    }
    return f;
}

- (void)set_timeFormat:(NSString *)newFormat
{
    NSParameterAssert(newFormat == nil);
    [_cache removeObjectForKey:_WLTimeFormatCacheKey];
}

- (void)_calEventsDidChange:(NSNotification *)aNotification
{
    NSUInteger numberOfColumns = [self numberOfColumnsInWeekView:[self view]];
    NSIndexSet *allColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)];
    [[self view] updateEventsOfColumnsAtIndexes:allColumnIndexes];
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
    v.indexOfHighlightedColumn = [self indexOfColumnForCurrentDay];
    [v release];
    [self addObserver:self forKeyPath:@"representedObject.date" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"representedObject.calendar" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"representedObject.calEventCalendarsToDisplay" options:NSKeyValueObservingOptionNew context:NULL];
    NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
    [n addObserver:self
          selector:@selector(_calEventsDidChange:)
              name:CalEventsChangedExternallyNotification
            object:[CalCalendarStore defaultCalendarStore]];
    [n addObserver:self
          selector:@selector(_calEventsDidChange:)
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
    if ([aKeyPath isEqual:@"representedObject.calendar"] || [aKeyPath isEqual:@"representedObject.calEventCalendarsToDisplay"])
    {
        if ([aKeyPath isEqual:@"representedObject.calendar"])
        {
            self._columnTitleFormat = nil;
            self._timeFormat = nil;
        }
        [[self view] reloadDataAnimated:YES];
        [self highlightCurrentDay];
    }
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
        [self highlightCurrentDay];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

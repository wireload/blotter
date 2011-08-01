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


static NSString* const _WLOneDayComponentCacheKey = @"oneDayComponent";

static NSString* const _WLOneWeekComponentCacheKey = @"oneWeekComponent";

static NSString* const _WLDateFormatterCacheKey = @"dateFormatter";

static NSString* const _WLFirstWeekdayCacheKey = @"firstWeekday";

static NSString* const _WLColumnTitleFormatCacheKey = @"titleFormat";

static NSString* const _WLCalendarCacheKey = @"calendar";


static NSString* const _WLTitleKey = @"title";

static NSString* const _WLEventsKey = @"events";


@implementation WLCalendarWeekViewController
@synthesize mode;
@synthesize titleFormat;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil)
    {
        mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"RollingCalendar"];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(_eventsChanged:)
                                   name:CalEventsChangedExternallyNotification
                                 object:[CalCalendarStore defaultCalendarStore]];
        [notificationCenter addObserver:self
                               selector:@selector(_eventsChanged:)
                                   name:CalEventsChangedNotification
                                 object:[CalCalendarStore defaultCalendarStore]];

        [notificationCenter addObserver:self
                               selector:@selector(_clockChanged)
                                   name:NSSystemClockDidChangeNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(_clockChanged)
                                   name:NSSystemTimeZoneDidChangeNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(_localeChanged:)
                                   name:NSCurrentLocaleDidChangeNotification
                                 object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(_clockChanged)
                                                                   name:NSWorkspaceDidWakeNotification
                                                                 object:nil];
        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarWeekViewController cache"];
        _columnDateRanges = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_cache release];
    [_scrollTimer invalidate];
    [_nextDayTimer invalidate];
    [_representedDate release];
    [_columnsData release];
    [_columnDateRanges release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"PerDayDate"])
        [self _perDayDatePreferenceChanged];
}

- (void)loadView
{
    if ([self nibName] != nil)
        [super loadView];
}

- (WLCalendarWeekView *)view
{
    return (WLCalendarWeekView *)[super view];
}

- (void)setView:(WLCalendarWeekView *)newView
{
    [self view].dataSource = nil;
    // Look at the -_localeChanged: method.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_localeActuallyChanged) object:nil];
    [super setView:newView];
    newView.dataSource = self;
    self._representedDate = [NSDate date];
    self._firstWeekday = nil;
    [newView setupLayers];
}

- (NSArray *)representedObject
{
    return (NSArray *)[super representedObject];
}

- (void)setRepresentedObject:(NSArray *)newRepresentedObject
{
    // Look at the -_localeChanged: method.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_localeActuallyChanged) object:nil];
    [super setRepresentedObject:newRepresentedObject];
    [[self view] setupLayers];
}

- (void)setMode:(WLCalendarWeekViewMode)newMode
{
    if (newMode != mode)
    {
        // Look at the -_localeChanged: method.
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_localeActuallyChanged) object:nil];
        mode = newMode;
        [[self view] setupLayers];
    }
}

- (void)setTitleFormat:(WLCalendarWeekViewTitleFormat)newTitleFormat
{
    if (newTitleFormat != titleFormat)
    {
        titleFormat = newTitleFormat;
        self._columnTitleFormat = nil;
        NSUInteger numberOfColumns = [self numberOfColumnsInWeekView:[self view]];
        [[self view] updateTitleOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];
    }
}

- (CGFloat)currenHour
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = self._calendar;
    NSDateComponents *components = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit
                                               fromDate:now];
    CGFloat hour = [components hour];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:now];
    hour += (CGFloat)[components minute] / minutesRange.length;
    return hour;
}

- (void)scrollToCurrentHour
{
    [[self view] scrollHour:[self currenHour]];
}

- (NSDate *)firstDate
{
    NSCalendar *cal = self._calendar;
    switch (mode) {
        case WLCalendarWeekViewKeepsCurrentDateMode:
        {
            NSDate *today = [NSDate date];
            NSDateComponents *todayNoonComponents = [cal components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                           fromDate:today];
            NSRange hoursRange = [cal rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:today];
            [todayNoonComponents setHour:NSMaxRange(hoursRange) / 2];
            return [cal dateFromComponents:todayNoonComponents];
        }
        case WLCalendarWeekViewKeepsCurrentWeekMode:
            return self._firstWeekday;
    }
}

- (NSArray *)eventsForColumnsAtIndexes:(NSIndexSet *)anIndexSet firstDate:(NSDate *)aFirstDate
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), anIndexSet);
#endif
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    NSCalendar *c = self._calendar;
    [offset setDay:[anIndexSet firstIndex]];
    NSDate *startDate = [[c dateByAddingComponents:offset toDate:aFirstDate options:0] WL_upperBoundaryWithCalendar:c];
    [offset setDay:[anIndexSet lastIndex]];
    NSDate *endDate = [[c dateByAddingComponents:offset toDate:aFirstDate options:0] WL_lowerBoundaryWithCalendar:c];
    [offset release];
    NSPredicate *p = [CalCalendarStore eventPredicateWithStartDate:startDate
                                                           endDate:endDate
                                                         calendars:[self representedObject]];
    return [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:p];
}


#pragma mark Private
@dynamic _oneDayComponent;
@dynamic _oneWeekComponent;
@dynamic _dateFormatter;
@dynamic _firstWeekday;
@dynamic _columnTitleFormat;
@dynamic _calendar;
@synthesize _representedDate;

- (NSDateComponents *)_oneDayComponent
{
    NSDateComponents *c = [_cache objectForKey:_WLOneDayComponentCacheKey];
    if (c == nil)
    {
        c = [[[NSDateComponents alloc] init] autorelease];
        [c setDay:1];
        [_cache setObject:c forKey:_WLOneDayComponentCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLOneDayComponentCacheKey);
#endif
    return c;
}

- (void)set_oneDayComponent:(NSDateComponents *)newComponents
{
    NSParameterAssert(newComponents == nil);
    [_cache removeObjectForKey:_WLOneDayComponentCacheKey];
}

- (NSDateComponents *)_oneWeekComponent
{
    NSDateComponents *oneWeekComponent = [_cache objectForKey:_WLOneWeekComponentCacheKey];
    if (oneWeekComponent == nil)
    {
        oneWeekComponent = [[[NSDateComponents alloc] init] autorelease];
        [oneWeekComponent setWeek:1];
        [_cache setObject:oneWeekComponent forKey:_WLOneWeekComponentCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLOneWeekComponentCacheKey);
#endif
    return oneWeekComponent;
}

- (void)set_oneWeekComponent:(NSDateComponents *)newComponents
{
    NSParameterAssert(newComponents == nil);
    [_cache removeObjectForKey:_WLOneWeekComponentCacheKey];
}

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

- (NSDate *)_firstWeekday
{
    NSDate *firstWeekday = [_cache objectForKey:_WLFirstWeekdayCacheKey];
    if (firstWeekday == nil)
    {
        static const NSUInteger Units = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit;

        NSCalendar *cal = self._calendar;
        NSRange weekdaysRange = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:self._representedDate];
        NSDateComponents *comp = [cal components:Units fromDate:self._representedDate];
        [comp setDay:weekdaysRange.location];
        firstWeekday = [cal dateFromComponents:comp];

        NSRange hoursRange = [cal rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:firstWeekday];
        [comp setHour:NSMaxRange(hoursRange) / 2]; // noon
        firstWeekday = [cal dateFromComponents:comp];
        [_cache setObject:firstWeekday forKey:_WLFirstWeekdayCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLFirstWeekdayCacheKey);
#endif
    return firstWeekday;
}

- (void)set_firstWeekday:(NSDate *)newDate
{
    NSParameterAssert(newDate == nil);
    [_cache removeObjectForKey:_WLFirstWeekdayCacheKey];
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

- (NSCalendar *)_calendar
{
    NSCalendar *c = [_cache objectForKey:_WLCalendarCacheKey];
    if (c == nil)
    {
        c = [NSCalendar autoupdatingCurrentCalendar];
        [_cache setObject:c forKey:_WLCalendarCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLCalendarCacheKey);
#endif
    return c;
}

- (void)set_calendar:(NSCalendar *)newCalendar
{
    NSParameterAssert(newCalendar == nil);
    [_cache removeObjectForKey:_WLCalendarCacheKey];
}

- (void)_eventsChanged:(NSNotification *)aNotification
{
    NSMutableIndexSet *affectedColumnsIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *changedEventUIDs = [NSMutableArray array];
    [changedEventUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalInsertedRecordsKey]];
    [changedEventUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalUpdatedRecordsKey]];
    [changedEventUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalDeletedRecordsKey]];

    NSUInteger numberOfColumns = [self numberOfColumnsInWeekView:[self view]];
    for (NSString *uid in changedEventUIDs)
    {
        if ([affectedColumnsIndexes count] == numberOfColumns)
            break;

        CalEvent *changedEvent = [[CalCalendarStore defaultCalendarStore] eventWithUID:uid occurrence:nil];
        // There are no start and end dates for a deleted event.
        if (changedEvent == nil)
        {
            affectedColumnsIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)];
            break;
        }

        WLDateRange *eventRange = [WLDateRange dateRangeWithStartDate:changedEvent.startDate endDate:changedEvent.endDate];
        for (NSUInteger i=0; i<numberOfColumns; ++i)
        {
            if ([[_columnDateRanges objectForKey:[NSNumber numberWithUnsignedInteger:i]] intersectsRange:eventRange])
                [affectedColumnsIndexes addIndex:i];
        }
    }
#ifdef DEBUG_PERFORMANCE
    NSLog(@"Update columns at indexes: %@", affectedColumnsIndexes);
#endif
    [[self view] updateEventsOfColumnsAtIndexes:affectedColumnsIndexes];
}

- (void)_localeChanged:(NSNotification *)aNotification
{
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_localeActuallyChanged) object:nil];
    static const NSTimeInterval AnyDelay = 1.0f;
    [self performSelector:@selector(_localeActuallyChanged) withObject:nil afterDelay:AnyDelay];
}

- (void)_localeActuallyChanged
{
    NSLog(@"_localeActuallyChanged");
    self._firstWeekday = nil;
    self._columnTitleFormat = nil;
    self._calendar = nil;
    self._dateFormatter = nil;
    [[self view] setupLayers];
}

- (void)_clockChanged
{
    // Look at the -_localeChanged: method.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_localeActuallyChanged) object:nil];
    self._firstWeekday = nil;
    self._representedDate = [NSDate date];
    [[self view] setupLayers];
}

- (void)_showNextDay
{
    NSCalendar *calendar = self._calendar;
    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [calendar components:NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
    NSDateComponents *representedComponents = [calendar components:NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self._representedDate];
    // This method is typically called by the timer which fire date is set to 1 second of the first day after _representedDate.
    // see _scheduleNextDayTimer
    // Though accuracy of NSTimer is documented as 50-100ms, we must ensure that day is actually changed.
    if ([nowComponents day] != [representedComponents day] || [nowComponents month] != [representedComponents month])
    {
        self._representedDate = now;
        self._firstWeekday = nil;
        [[self view] nextDay];
        [self scrollToCurrentHour];
        [self _scheduleNextDayTimer];
    }
    else
        [self performSelector:@selector(_showNextDay) withObject:nil afterDelay:0.1];
}

- (void)_showNextWeek
{
    NSCalendar *calendar = self._calendar;
    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [calendar components:NSMonthCalendarUnit | NSWeekCalendarUnit fromDate:now];
    NSDateComponents *representedComponents = [calendar components:NSMonthCalendarUnit | NSWeekCalendarUnit fromDate:self._representedDate];
    // This method is typically called by the timer which fire date is set to 1 second of the first day after _representedDate.
    // see _scheduleNextDayTimer
    // Though accuracy of NSTimer is documented as 50-100ms, we must ensure that week is actually changed.
    if ([nowComponents week] != [representedComponents week] || [nowComponents month] != [representedComponents month])
    {
        self._representedDate = now;
        self._firstWeekday = nil;
        [[self view] nextWeek];
        [self scrollToCurrentHour];
        [self _scheduleNextWeekTimer];
    }
    else
        [self performSelector:@selector(_showNextDay) withObject:nil afterDelay:0.1];
}

- (void)_scheduleScrollTimer
{
    [_scrollTimer invalidate];
    NSRange minutesRange = [self._calendar maximumRangeOfUnit:NSMinuteCalendarUnit];
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)minutesRange.length
                                                    target:self
                                                  selector:@selector(scrollToCurrentHour)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)_scheduleNextDayTimer
{
    [_nextDayTimer invalidate];
    NSCalendar *calendar = self._calendar;

    NSDate *nextDay = [calendar dateByAddingComponents:self._oneDayComponent toDate:self._representedDate options:0];
    nextDay = [nextDay WL_upperBoundaryWithCalendar:calendar];
    _nextDayTimer = [[NSTimer alloc] initWithFireDate:nextDay
                                             interval:0.0
                                               target:self
                                             selector:@selector(_showNextDay)
                                             userInfo:nil
                                              repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
    [_nextDayTimer release];
}

- (void)_scheduleNextWeekTimer
{
    [_nextWeekTimer invalidate];
    NSCalendar *calendar = self._calendar;

    NSDate *nextWeek = [calendar dateByAddingComponents:self._oneWeekComponent toDate:self._firstWeekday options:0];
    nextWeek = [nextWeek WL_upperBoundaryWithCalendar:calendar];
    _nextWeekTimer = [[NSTimer alloc] initWithFireDate:nextWeek
                                              interval:0.0
                                                target:self
                                              selector:@selector(_showNextWeek)
                                              userInfo:nil
                                               repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextWeekTimer forMode:NSDefaultRunLoopMode];
    [_nextWeekTimer release];
}


#pragma mark WLCalendarWeekViewDataSource

- (NSUInteger)numberOfHours
{
    NSRange hoursRange = [self._calendar maximumRangeOfUnit:NSHourCalendarUnit];
    return hoursRange.length;
}

- (CGFloat)heightOfHour
{
    return 50.0f;
}

- (CGFloat)hourForDate:(NSDate *)aDate
{
    NSCalendar *cal = self._calendar;
    NSDateComponents *comp = [cal components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:aDate];
    NSRange minutesRange = [cal rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:aDate];
    return ((CGFloat)[comp hour] + (CGFloat)([comp minute] - minutesRange.location) / minutesRange.length);
}

- (NSString *)stringForHour:(NSUInteger)aHour
{
    NSCalendar *cal = self._calendar;
    NSDateComponents *justHourComponents = [cal components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                    fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0.0]];
    [justHourComponents setHour:aHour];

    NSDateFormatter *f = self._dateFormatter;
    [f setDateStyle:NSDateFormatterNoStyle];
    [f setTimeStyle:NSDateFormatterShortStyle];
    return [f stringFromDate:[cal dateFromComponents:justHourComponents]];
}

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSCalendar *cal = self._calendar;
    if (mode == WLCalendarWeekViewKeepsCurrentWeekMode)
    {
        NSRange weekdaysRange = [cal rangeOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:self._representedDate];
        return weekdaysRange.length;
    }
    else
        return 7;
}

// -[CalCalendarStore eventsWithPredicate:] can take a relatively long time. This optimization allows us to call that method only once.
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%@", NSStringFromSelector(_cmd));
#endif
    NSCalendar *cal = self._calendar;
    _columnsData = [[NSMutableDictionary alloc] initWithCapacity:[anIndexSet count]];

    NSDate *firstDate = [self firstDate];

    NSArray *events = nil;
    if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        events = [self eventsForColumnsAtIndexes:anIndexSet firstDate:firstDate];

    NSDateComponents *columnDateComponents = [[NSDateComponents alloc] init];
    NSDateFormatter *titleFormatter = self._dateFormatter;
    [titleFormatter setDateFormat:self._columnTitleFormat];
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger columnIdx, BOOL *stop)
    {
        [columnDateComponents setDay:columnIdx];
        NSDate *columnDate = [cal dateByAddingComponents:columnDateComponents toDate:firstDate options:0];
        NSMutableDictionary *columnData = [NSMutableDictionary dictionary];

        if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        {
#ifdef DEBUG_PERFORMANCE
            NSLog(@"Prepare weekView events");
#endif
            NSDate *upperBound = [columnDate WL_upperBoundaryWithCalendar:cal];
            NSDate *lowerBound = [upperBound WL_lowerBoundaryWithCalendar:cal];
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
    return [[_columnsData objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] objectForKey:_WLTitleKey];
}

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex
{
    return [[_columnsData objectForKey:[NSNumber numberWithUnsignedInteger:anIndex]] objectForKey:_WLEventsKey];
}

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView
{
    [_columnsData release];
    _columnsData = nil;
}

- (void)weekViewDidSetupLayers:(WLCalendarWeekView *)aWeekView
{
    if (mode == WLCalendarWeekViewKeepsCurrentWeekMode)
    {
        [_nextDayTimer invalidate];
        _nextDayTimer = nil;
        [self _scheduleNextWeekTimer];
    }
    else if (mode == WLCalendarWeekViewKeepsCurrentDateMode)
    {
        [_nextWeekTimer invalidate];
        _nextWeekTimer = nil;
        [self _scheduleNextDayTimer];
    }
    [self _scheduleScrollTimer];
    [self scrollToCurrentHour];
}

@end


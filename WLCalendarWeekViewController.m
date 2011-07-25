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

        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"PerDayDate"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];

        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarWeekViewController cache"];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"PerDayDate"];
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
    [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(setupLayers) target:[self view] argument:nil];
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
    [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(setupLayers) target:[self view] argument:nil];
    [super setRepresentedObject:newRepresentedObject];
    [[self view] setupLayers];
}

- (void)setMode:(WLCalendarWeekViewMode)newMode
{
    if (newMode != mode)
    {
        // Look at the -_localeChanged: method.
        [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(setupLayers) target:[self view] argument:nil];
        mode = newMode;
        [[self view] setupLayers];
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
    NSDateComponents *oneDayComponent = [_cache objectForKey:_WLOneDayComponentCacheKey];
    if (oneDayComponent == nil)
    {
        oneDayComponent = [[NSDateComponents alloc] init];
        [oneDayComponent setDay:1];
        [_cache setObject:oneDayComponent forKey:_WLOneDayComponentCacheKey];
        [oneDayComponent release];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLOneDayComponentCacheKey);
#endif
    return oneDayComponent;
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
        oneWeekComponent = [[NSDateComponents alloc] init];
        [oneWeekComponent setWeek:1];
        [_cache setObject:oneWeekComponent forKey:_WLOneWeekComponentCacheKey];
        [oneWeekComponent release];
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
    NSDateFormatter *dateFormatter = [_cache objectForKey:_WLDateFormatterCacheKey];
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [_cache setObject:dateFormatter forKey:_WLDateFormatterCacheKey];
        [dateFormatter release];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLDateFormatterCacheKey);
#endif
    return dateFormatter;
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
        NSCalendar *calendar = self._calendar;
        NSUInteger units = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit;
        NSDateComponents *components = [calendar components:units fromDate:self._representedDate];
        NSRange weekdaysRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:self._representedDate];
        [components setDay:weekdaysRange.location];
        [components setHour:12];
        firstWeekday = [calendar dateFromComponents:components];
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
    NSString *format = [_cache objectForKey:_WLColumnTitleFormatCacheKey];
    if (format == nil)
    {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PerDayDate"])
            format = [NSDateFormatter dateFormatFromTemplate:@"eeedMMM" options:0 locale:[NSLocale autoupdatingCurrentLocale]];
        else
            format = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:[NSLocale autoupdatingCurrentLocale]];
        [_cache setObject:format forKey:_WLColumnTitleFormatCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLColumnTitleFormatCacheKey);
#endif
    return format;
}

- (void)set_columnTitleFormat:(NSString *)newFormat
{
    NSParameterAssert(newFormat == nil);
    [_cache removeObjectForKey:_WLColumnTitleFormatCacheKey];
}

- (NSCalendar *)_calendar
{
    NSCalendar *calendar = [_cache objectForKey:_WLCalendarCacheKey];
    if (calendar == nil)
    {
        calendar = [NSCalendar autoupdatingCurrentCalendar];
        [_cache setObject:calendar forKey:_WLCalendarCacheKey];
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLCalendarCacheKey);
#endif
    return calendar;
}

- (void)set_calendar:(NSCalendar *)newCalendar
{
    NSParameterAssert(newCalendar == nil);
    [_cache removeObjectForKey:_WLCalendarCacheKey];
}

- (void)_eventsChanged:(NSNotification *)aNotification
{
    NSMutableIndexSet *affectedColumnsIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *eventUIDs = [NSMutableArray array];
    [eventUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalInsertedRecordsKey]];
    [eventUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalUpdatedRecordsKey]];
    [eventUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalDeletedRecordsKey]];

    for (NSString *uid in eventUIDs)
    {
        if ([affectedColumnsIndexes count] == sizeof(_columnDateRanges)/sizeof(WLDateRange*))
            break;
        CalEvent *event = [[CalCalendarStore defaultCalendarStore] eventWithUID:uid occurrence:nil];
        // There are no start and end dates for deleted event.
        if (event == nil)
        {
            affectedColumnsIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sizeof(_columnDateRanges)/sizeof(WLDateRange*))];
            break;
        }
        WLDateRange *eventRange = [WLDateRange dateRangeWithStartDate:event.startDate endDate:event.endDate];
        for (NSUInteger i=0, size=sizeof(_columnDateRanges)/sizeof(WLDateRange*); i<size; ++i)
        {
            if ([_columnDateRanges[i] intersectsRange:eventRange])
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
    [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(setupLayers) target:[self view] argument:nil];
    static const NSTimeInterval AnyDelay = 1.0f;
    self._firstWeekday = nil;
    self._columnTitleFormat = nil;
    self._calendar = nil;
    [[self view] performSelector:@selector(setupLayers) withObject:nil afterDelay:AnyDelay];
}

- (void)_clockChanged
{
    // Look at the -_localeChanged: method.
    [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(setupLayers) target:[self view] argument:nil];
    self._firstWeekday = nil;
    self._representedDate = [NSDate date];
    [[self view] setupLayers];
}

- (void)_perDayDatePreferenceChanged
{
    self._columnTitleFormat = nil;
    NSUInteger numberOfColumns = [self numberOfColumnsInWeekView:[self view]];
    [[self view] updateTitleOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)]];
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
    NSCalendar *calendar = self._calendar;
    NSDateComponents *components = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:aDate];
    NSRange minutesRange = [calendar rangeOfUnit:NSMinuteCalendarUnit inUnit:NSHourCalendarUnit forDate:aDate];
    CGFloat result = ((CGFloat)[components hour] + (CGFloat)[components minute] / minutesRange.length);
    return result;
}

- (NSString *)stringForHour:(NSUInteger)aHour
{
    NSCalendar *calendar = self._calendar;
    NSDateComponents *components = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                               fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0.0f]];
    [components setHour:aHour];

    NSDateFormatter *dateFormatter = self._dateFormatter;
    [dateFormatter setCalendar:calendar];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:[calendar dateFromComponents:components]];
}

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    // FIXME: some calendar may have more or less than 7 days per week.
    return 7;
}

// -[CalCalendarStore eventsWithPredicate:] can take a relatively long time. This optimization allows us to call that method only once.
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%@", NSStringFromSelector(_cmd));
#endif
    NSCalendar *calendar = self._calendar;
    _columnsData = [[NSMutableDictionary alloc] initWithCapacity:[anIndexSet count]];
    NSDate *firstDate = nil;
    if (mode == WLCalendarWeekViewKeepsCurrentDateMode)
    {
        firstDate = [NSDate date];
        NSDateComponents *components = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                   fromDate:firstDate];
        NSRange hoursRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:firstDate];
        [components setHour:NSMaxRange(hoursRange) / 2]; // noon
        firstDate = [calendar dateFromComponents:components];
    }
    else if (mode == WLCalendarWeekViewKeepsCurrentWeekMode)
        firstDate = self._firstWeekday;

    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setHour:0];
    [components setDay:[anIndexSet firstIndex]];
    NSDate *startRangeDate = [calendar dateByAddingComponents:components toDate:firstDate options:0];
    startRangeDate = [startRangeDate WL_upperBoundaryWithCalendar:calendar];
    [components setDay:[anIndexSet lastIndex]];
    NSDate *endRangeDate = [calendar dateByAddingComponents:components toDate:firstDate options:0];
    endRangeDate = [endRangeDate WL_lowerBoundaryWithCalendar:calendar];

    NSArray *events = nil;
    if (dataUnits & WLCalendarWeekViewEventsDataUnit)
    {
#ifdef DEBUG_PERFORMANCE
        NSLog(@"Take weekView events from CalCalendarStore");
#endif
        NSPredicate *eventsPredicate = [CalCalendarStore eventPredicateWithStartDate:startRangeDate
                                                                             endDate:endRangeDate
                                                                           calendars:[self representedObject]];
        events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsPredicate];
    }
    [components setDay:0];
    [components setHour:0];
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
        [components setDay:idx];
        NSDate *noon = [calendar dateByAddingComponents:components toDate:firstDate options:0];
        NSMutableDictionary *columnData = [NSMutableDictionary dictionary];

        if (dataUnits & WLCalendarWeekViewEventsDataUnit)
        {
#ifdef DEBUG_PERFORMANCE
            NSLog(@"Prepare weekView events");
#endif
            NSDate *upperBound = [noon WL_upperBoundaryWithCalendar:calendar];
            NSDate *lowerBound = [upperBound WL_lowerBoundaryWithCalendar:calendar];
            WLDateRange *dayRange = [WLDateRange dateRangeWithStartDate:upperBound endDate:lowerBound];
            [_columnDateRanges[idx] release];
            _columnDateRanges[idx] = [dayRange retain];
            NSMutableArray *dayEvents = [NSMutableArray array];
            for (CalEvent *event in events)
            {
                WLDateRange *eventRange = [WLDateRange dateRangeWithStartDate:event.startDate endDate:event.endDate];
                WLPositionRelativeToRange position;
                BOOL intresects = [dayRange intersectsRange:eventRange position:&position];
                if (intresects)
                {
                    if (position == WLWithinRange)
                        [dayEvents addObject:event];
                    // If an event takes more than 1 day, divide it into multiple events for each column.
                    else if (position == WLEarlierThanRange && [eventRange.endDate compare:dayRange.startDate] != NSOrderedSame)
                    {
                        CalEvent *partEvent = [event copy];
                        partEvent.startDate = upperBound;
                        [dayEvents addObject:partEvent];
                        [partEvent release];
                    }
                    else if (position == WLOverlapsRange)
                    {
                        CalEvent *partEvent = [event copy];
                        partEvent.startDate = upperBound;
                        partEvent.endDate = lowerBound;
                        [dayEvents addObject:partEvent];
                        [partEvent release];
                    }
                    else if (position == WLLaterThanRange && [dayRange.endDate compare:eventRange.startDate] != NSOrderedSame)
                    {
                        CalEvent *partEvent = [event copy];
                        partEvent.endDate = lowerBound;
                        [dayEvents addObject:partEvent];
                        [partEvent release];
                    }
                }
            }
            [columnData setObject:dayEvents forKey:_WLEventsKey];
        }

        if (dataUnits & WLCalendarWeekViewTitleDataUnit)
        {
#ifdef DEBUG_PERFORMANCE
            NSLog(@"Prepare weekView title");
#endif
            NSDateFormatter *dateFormatter = self._dateFormatter;
            [dateFormatter setCalendar:calendar];
            [dateFormatter setLocale:[NSLocale currentLocale]];
            [dateFormatter setDateFormat:self._columnTitleFormat];
            NSString *title = [dateFormatter stringFromDate:noon];
            [columnData setObject:title forKey:_WLTitleKey];
        }
        [_columnsData setObject:columnData forKey:[NSNumber numberWithUnsignedInteger:idx]];
    }];
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

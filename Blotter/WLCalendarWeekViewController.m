//
//  WLCalendarWeekViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 11.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#include <tgmath.h>
#import "WLCalendarWeekViewController.h"
#import "NSDate+WLDayBoundaries.h"
#import "NSColor+WLCalendar.h"
#import "NSCalendar+WLWeekend.h"


static NSString* const _WLDateFormatterCacheKey = @"dateFormatter";

static NSString* const _WLColumnTitleFormatCacheKey = @"titleFormat";

static NSString* const _WLTimeFormatCacheKey = @"timeFormat";


static NSString* const _WLTitleKey = @"title";

static NSString* const _WLEventsKey = @"events";


@interface WLCalendarWeekViewController (/* Private */)

@property (assign) BOOL isViewLoaded;

@end


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
@synthesize highlightsWeekends;
@synthesize isViewLoaded;
@dynamic currentHour;

- (void)setHighlightsWeekends:(BOOL)newHighlight
{
    NSParameterAssert([self representedObject] != nil);

    highlightsWeekends = newHighlight;
    if (self.isViewLoaded)
    {
        WLCalendarWeekView *v = [self view];
        [v updateColorOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [v numberOfColumns])] animated:NO];
    }
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

+ (NSSet *)keyPathsForValuesAffectingCurrentHour
{
    return [NSSet setWithObjects:
                      @"self.representedObject.date",
                      @"self.representedObject.calendar",
                      nil];
}


#pragma mark Methods

- (NSUInteger)indexOfColumnForToday
{
    NSAssert(NO, @"You MUST implement this method");
    return 0;
}

- (NSDate *)firstColumnDate
{
    NSAssert(NO, @"You MUST implement this method");
    return nil;
}

- (WLDateRange *)dateRangeForColumnAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert([self representedObject] != nil);

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
    return [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:p];
}

- (void)viewWillSetupLayers:(WLCalendarWeekView *)aView
{
    aView.dataSource = self;
    [aView scrollHour:[self currentHour] animated:NO];
}

- (void)representedDateDidChangeFromDate:(NSDate *)anOldDate toDate:(NSDate *)aNewDate
{
}


#pragma mark WLCalendarWeekViewDataSource

- (WLHourRange)hourRangeOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    NSParameterAssert([self representedObject] != nil);

    NSRange hoursRange = [[[self representedObject] calendar] maximumRangeOfUnit:NSHourCalendarUnit];
    return WLHourRangeMake(hoursRange.location, NSMaxRange(hoursRange));
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

    NSRange weekdaysRange = [[[self representedObject] calendar] maximumRangeOfUnit:NSWeekdayCalendarUnit];
    return weekdaysRange.length;
}

// -[CalCalendarStore eventsWithPredicate:] can take a relatively long time. This optimization allows us to call that method only once.
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)aDataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet
{
    _columnsData = [[NSMutableDictionary alloc] initWithCapacity:[anIndexSet count]];

    if ((aDataUnits & WLCalendarWeekViewEventsDataUnit) == 0)
        return;

    NSDate *firstColumnDate = [self firstColumnDate];
    NSArray *events = nil;
    if (aDataUnits & WLCalendarWeekViewEventsDataUnit)
        events = [self eventsForColumnsAtIndexes:anIndexSet firstDate:firstColumnDate];
    [anIndexSet enumerateIndexesUsingBlock:^(NSUInteger columnIdx, BOOL *stop)
    {
        WLDateRange *columnDateRange = [self dateRangeForColumnAtIndex:columnIdx];
        NSMutableDictionary *columnData = [NSMutableDictionary dictionary];

        if (aDataUnits & WLCalendarWeekViewEventsDataUnit)
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
        [_columnsData setObject:columnData forKey:[NSNumber numberWithUnsignedInteger:columnIdx]];
    }];
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
    if (highlightsWeekends)
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
    WLCalendarWeekView *v = [self view];
    NSUInteger numberOfColumns = [v numberOfColumns];
    NSIndexSet *allColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfColumns)];
    [v updateEventsOfColumnsAtIndexes:allColumnIndexes animated:YES];
}


#pragma mark NSViewController

- (void)loadView
{
    WLCalendarWeekView *v = [[WLCalendarWeekView alloc] init];
    [self viewWillSetupLayers:v];
    [v makeLayers];
    [self setView:v];
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
    self.isViewLoaded = YES;
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
            self._timeFormat = nil;
        }
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [CATransaction setAnimationDuration:.25];
        [[self view] reloadDataAnimated:YES];
        [[self view] scrollHour:[self currentHour] animated:YES];
        [CATransaction commit];
    }
    else if ([aKeyPath isEqual:@"representedObject.date"])
    {
        NSDate *old = [aChange objectForKey:NSKeyValueChangeOldKey];
        NSDate *new = [aChange objectForKey:NSKeyValueChangeNewKey];
        [self representedDateDidChangeFromDate:old toDate:new];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

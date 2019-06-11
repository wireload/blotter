//
//  WLCalendarEventsStorage.m
//  Blotter
//
//  Created by Ilya Kulakov on 19.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <WLCalendarStore/WLCalEvent.h>
#import "WLCalendarEventsStorage.h"
#import "WLCalEventPart.h"


@implementation WLCalendarEventsStorage
{
    NSDictionary *_allDayEventsPerDateRange;
    NSDictionary *_dayEventsPerDateRange;
}

- (instancetype)initWithEvents:(NSArray *)anEvents calendar:(NSCalendar *)aCalendar unit:(NSCalendarUnit)aUnit
{
    self = [super init];

    if (self)
    {
        _events = [anEvents copy];
        _calendarUnit = aUnit;
        _calendar = [aCalendar copy];

        NSMutableArray *eventParts = [NSMutableArray arrayWithCapacity:anEvents.count];

        for (NSObject<WLCalEvent> *e in anEvents)
        {
            NSArray *p = [WLCalEventPart partsBySplittingEvent:e intoCalendarUnits:aUnit calendar:_calendar];
            [eventParts addObjectsFromArray:p];
        }

        NSIndexSet *indexesOfAllDayEvents = [eventParts indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                        passingTest:^BOOL(NSObject <WLCalEvent> *anEvent, NSUInteger idx, BOOL *stop)
        {
            return anEvent.isAllDay;
        }];
        NSMutableIndexSet *indexesOfDayEvents = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, eventParts.count)];
        [indexesOfDayEvents removeIndexes:indexesOfAllDayEvents];

        dispatch_group_t g = dispatch_group_create();

        NSCalendar *allDayEventsCalendarCopy = [_calendar copy];
        dispatch_group_async(g, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            NSArray *allDayEvents = [eventParts objectsAtIndexes:indexesOfAllDayEvents];
            // All day events will be sorted so that events with short duration will appear first.
            // Events with the same duration are grouped by calendar identifier.
            allDayEvents = [allDayEvents sortedArrayWithOptions:NSSortConcurrent | NSSortStable
                                                usingComparator:^NSComparisonResult(WLCalEventPart *anEvent1, WLCalEventPart *anEvent2)
            {
                NSTimeInterval event1Duration = [anEvent1.originalEvent.endDate timeIntervalSinceDate:anEvent1.originalEvent.startDate];
                NSTimeInterval event2Duration = [anEvent2.originalEvent.endDate timeIntervalSinceDate:anEvent2.originalEvent.startDate];

                if (event1Duration < event2Duration)
                    return NSOrderedDescending;
                else if (event1Duration > event2Duration)
                    return NSOrderedAscending;
                else
                    return [anEvent1.calendar.calendarIdentifier compare:anEvent2.calendar.calendarIdentifier];
            }];

            NSMutableDictionary *allDayEventsPerDateRange = [NSMutableDictionary dictionary];

            for (WLCalEventPart *e in allDayEvents)
            {
                WLDateRange *r = [WLDateRange dateRangeWithStartDate:e.startDate endDate:e.endDate];
                r = [r dateRangeByAligningCalendarUnit:aUnit calendar:allDayEventsCalendarCopy options:WLAlignOutward];

                NSMutableArray *events = allDayEventsPerDateRange[r];

                if (!events)
                {
                    events = [NSMutableArray array];
                    allDayEventsPerDateRange[r] = events;
                }

                [events addObject:e];
            }

            self->_allDayEventsPerDateRange = [allDayEventsPerDateRange copy];
        });

        NSCalendar *dayEventsCalendarCopy = [_calendar copy];
        dispatch_group_async(g, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            NSArray *dayEvents = [eventParts objectsAtIndexes:indexesOfDayEvents];
            dayEvents = [dayEvents sortedArrayWithOptions:NSSortConcurrent | NSSortStable
                                          usingComparator:^NSComparisonResult(WLCalEventPart *anEvent1, WLCalEventPart *anEvent2)
            {
                return [anEvent1.startDate compare:anEvent2.startDate];
            }];

            NSMutableDictionary *dayEventsPerDateRange = [NSMutableDictionary dictionary];

            for (WLCalEventPart *e in dayEvents)
            {
                WLDateRange *r = [WLDateRange dateRangeWithStartDate:e.startDate endDate:e.endDate];
                r = [r dateRangeByAligningCalendarUnit:aUnit calendar:dayEventsCalendarCopy options:WLAlignOutward];
                NSMutableArray *events = dayEventsPerDateRange[r];

                if (!events)
                {
                    events = [NSMutableArray array];
                    dayEventsPerDateRange[r] = events;
                }

                [events addObject:e];
            }

            self->_dayEventsPerDateRange = [dayEventsPerDateRange copy];
        });

        dispatch_group_wait(g, DISPATCH_TIME_FOREVER);
    }

    return self;
}


#pragma mark Methods

- (NSArray *)allDayEventsWithinDateRange:(WLDateRange *)aDateRange
{
    aDateRange = [aDateRange dateRangeByAligningCalendarUnit:self.calendarUnit calendar:_calendar options:WLAlignOutward];
    NSArray *keys = [aDateRange splitIntoCalendarUnits:self.calendarUnit calendar:_calendar];

    NSMutableArray *events = [NSMutableArray array];

    for (WLDateRange *k in keys)
    {
        [events addObjectsFromArray:_allDayEventsPerDateRange[k]];
    }

    return events;
}

- (NSArray *)allDayEventsForDate:(NSDate *)aDate
{
    WLDateRange *k = [WLDateRange dateRangeWithStartDate:aDate endDate:aDate];
    k = [k dateRangeByAligningCalendarUnit:self.calendarUnit calendar:_calendar options:WLAlignOutward];
    NSArray *events = _allDayEventsPerDateRange[k];
    return events != nil ? events.copy : @[];
}

- (NSArray *)dayEventsWithinDateRange:(WLDateRange *)aDateRange
{
    aDateRange = [aDateRange dateRangeByAligningCalendarUnit:self.calendarUnit calendar:_calendar options:WLAlignOutward];
    NSArray *keys = [aDateRange splitIntoCalendarUnits:self.calendarUnit calendar:_calendar];

    NSMutableArray *events = [NSMutableArray array];

    for (WLDateRange *k in keys)
    {
        [events addObjectsFromArray:_dayEventsPerDateRange[k]];
    }

    return events;
}

- (NSArray *)dayEventsForDate:(NSDate *)aDate
{
    WLDateRange *k = [WLDateRange dateRangeWithStartDate:aDate endDate:aDate];
    k = [k dateRangeByAligningCalendarUnit:self.calendarUnit calendar:_calendar options:WLAlignOutward];
    NSArray *events = _dayEventsPerDateRange[k];
    return events != nil ? events.copy : @[];
}


#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: { All Day Events: %@, Day Events: %@", super.description, _allDayEventsPerDateRange, _dayEventsPerDateRange];
}

@end

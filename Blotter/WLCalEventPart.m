//
//  WLCalEventPart.m
//  Blotter
//
//  Created by Ilya Kulakov on 19.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalEventPart.h"


@implementation WLCalEventPart
{
    NSDate *_startDate;
    NSDate *_endDate;
}

- (instancetype)initWithCalEvent:(NSObject <WLCalEvent> *)anEvent dateRange:(WLDateRange *)aDateRange
{
    if (aDateRange == nil)
        [NSException raise:NSInvalidArgumentException format:@"You MUST pass valid date range."];
    else if (anEvent == nil)
        [NSException raise:NSInvalidArgumentException format:@"You MUST pass valid event."];
    else if ([anEvent.startDate compare:aDateRange.startDate] == NSOrderedDescending)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Start date of passed date range (%@) MUST be >= start date of passed event (%@).", aDateRange.startDate, anEvent.startDate];
    }
    else if ([anEvent.endDate compare:aDateRange.endDate] == NSOrderedAscending)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"End date of passed date range (%@) MUST be <= end date of passed event (%@)", aDateRange.endDate, anEvent.endDate];
    }

    self = [super init];

    if (self)
    {
        _originalEvent = anEvent;
        _startDate = [aDateRange.startDate copy];
        _endDate = [aDateRange.endDate copy];
    }

    return self;
}

- (instancetype)init
{
    return [self initWithCalEvent:nil dateRange:nil];
}


#pragma mark Methods

+ (NSArray *)partsBySplittingEvent:(NSObject <WLCalEvent> *)anEvent intoCalendarUnits:(NSCalendarUnit)aUnit calendar:(NSCalendar *)aCalendar
{
    WLDateRange *r = [WLDateRange dateRangeWithStartDate:anEvent.startDate endDate:anEvent.endDate];
    NSArray *partDateRanges = [r splitIntoCalendarUnits:aUnit calendar:aCalendar];
    NSMutableArray *parts = [NSMutableArray arrayWithCapacity:[partDateRanges count]];

    for (WLDateRange *partDateRange in partDateRanges)
    {
        [parts addObject:[[self alloc] initWithCalEvent:anEvent dateRange:partDateRange]];
    }

    return parts;
}


#pragma mark WLCalEvent

- (BOOL)isAllDay
{
    return self.originalEvent.isAllDay;
}

- (NSDate *)startDate
{
    return _startDate;
}

- (NSDate *)endDate
{
    return _endDate;
}

- (BOOL)isDetached
{
    return self.originalEvent.isDetached;
}

- (NSDate *)occurrenceDate
{
    return self.originalEvent.occurrenceDate;
}

- (BOOL)isLikeEvent:(NSObject <WLCalEvent> *)anEvent
{
    return [self.originalEvent isLikeEvent:anEvent];
}


#pragma mark WLCalCalendarItem

- (NSObject <WLCalCalendar> *)calendar
{
    return self.originalEvent.calendar;
}

- (NSString *)notes
{
    return self.originalEvent.notes;
}

- (NSURL *)URL
{
    return self.originalEvent.URL;
}

- (NSString *)title
{
    return self.originalEvent.title;
}

- (NSDate *)lastModifiedDate
{
    return self.originalEvent.lastModifiedDate;
}

- (NSString *)location
{
    return self.originalEvent.location;
}

- (NSString *)itemIdentifier
{
    return self.originalEvent.itemIdentifier;
}

- (BOOL)hasRecurrenceRules
{
    return self.originalEvent.hasRecurrenceRules;
}


#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (of %@): %@",
                     [WLDateRange dateRangeWithStartDate:self.startDate endDate:self.endDate],
                     [WLDateRange dateRangeWithStartDate:self.originalEvent.startDate endDate:self.originalEvent.endDate],
                     self.itemIdentifier];
}

@end

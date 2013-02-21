//
//  WLDateRange.m
//  Blotter
//
//  Created by Ilya Kulakov on 25.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <AppKit/AppKit.h>
#import "WLDateRange.h"


@implementation WLDateRange

- (instancetype)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    self = [super init];

    if (self)
    {
        if (aStartDate)
            _startDate = [aStartDate copy];
        else
            _startDate = [NSDate date];

        if (anEndDate)
            _endDate = [anEndDate copy];
        else
            _endDate = [_startDate copy];
    }

    return self;
}

- (instancetype)init
{
    NSDate *now = [NSDate date];
    return [self initWithStartDate:now endDate:now];
}


#pragma mark Methods

+ (instancetype)dateRangeWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    return [[self alloc] initWithStartDate:aStartDate endDate:anEndDate];
}

+ (instancetype)emptyDateRange
{
    return [[self alloc] init];
}

- (WLDateRange *)dateRangeByUnitingWithDateRange:(WLDateRange *)aDateRange
{
    if (!aDateRange)
        [NSException raise:NSInvalidArgumentException format:@"aDateRange MUST NOT be nil."];

    return [[self class] dateRangeWithStartDate:[self.startDate earlierDate:aDateRange.startDate]
                                        endDate:[self.endDate laterDate:aDateRange.endDate]];
}

- (WLPositionRelativeToRange)positionOfDate:(NSDate *)aDate
{
    if (!aDate)
        [NSException raise:NSInvalidArgumentException format:@"aDate MUST NOT be nil."];

    NSComparisonResult result = [aDate compare:self.startDate];

    if (result == NSOrderedAscending)
        return WLEarlierThanRange;
    else if (result == NSOrderedSame || [aDate compare:self.endDate] == NSOrderedAscending)
        return WLWithinRange;
    else
        return WLLaterThanRange;
}

- (BOOL)intersectsRange:(WLDateRange *)aRange
{
    WLPositionRelativeToRange rangeStartDatePositionInSelf = [self positionOfDate:aRange.startDate];

    if (rangeStartDatePositionInSelf != WLLaterThanRange)
    {
        WLPositionRelativeToRange selfStartDatePositionInRange = [aRange positionOfDate:self.startDate];

        if (selfStartDatePositionInRange != WLLaterThanRange)
            return YES;
    }

    return NO;
}

- (BOOL)intersectsRange:(WLDateRange *)aRange position:(WLPositionRelativeToRange *)outPosition
{
    if (!aRange)
        [NSException raise:NSInvalidArgumentException format:@"aRange MUST NOT be nil."];

    if (!outPosition)
        [NSException raise:NSInvalidArgumentException format:@"outPosition MUST NOT be NULL."];

    NSComparisonResult selfStartDateToRangeStartDate = [self.startDate compare:aRange.startDate];
    NSComparisonResult selfStartDateToRangeEndDate = [self.startDate compare:aRange.endDate];
    NSComparisonResult selfEndDateToRangeStartDate = [self.endDate compare:aRange.startDate];
    NSComparisonResult selfEndDateToRangeEndDate = [self.endDate compare:aRange.endDate];

    if (selfStartDateToRangeEndDate != NSOrderedAscending && selfStartDateToRangeStartDate != NSOrderedSame)
    {
        *outPosition = WLEarlierThanRange;
        return NO;
    }

    if (selfEndDateToRangeStartDate != NSOrderedDescending && selfStartDateToRangeStartDate != NSOrderedSame)
    {
        *outPosition = WLLaterThanRange;
        return NO;
    }

    if (selfStartDateToRangeStartDate == NSOrderedAscending && selfEndDateToRangeEndDate == NSOrderedAscending)
        *outPosition = WLLaterThanRange;
    else if (selfStartDateToRangeStartDate == NSOrderedDescending && selfEndDateToRangeEndDate == NSOrderedDescending)
        *outPosition = WLEarlierThanRange;
    else if (selfStartDateToRangeStartDate != NSOrderedDescending && selfEndDateToRangeEndDate != NSOrderedAscending)
        *outPosition = WLWithinRange;
    else
        *outPosition = WLOverlapsRange;

    return YES;
}

- (BOOL)isEmpty
{
    return [self.startDate isEqualToDate:self.endDate];
}


#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)aZone
{
    return [WLDateRange dateRangeWithStartDate:self.startDate endDate:self.endDate];
}


#pragma mark NSObject

- (NSUInteger)hash
{
    return [self.startDate hash];
}

- (BOOL)isEqual:(WLDateRange *)anObject
{
    if ([super isEqual:anObject])
        return YES;
    else if (![anObject isKindOfClass:[WLDateRange class]])
        return NO;
    else if (![self.startDate isEqual:anObject.startDate])
        return NO;
    else if (![self.endDate isEqual:anObject.endDate])
        return NO;
    else
        return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: {%@, %@}", [super description], self.startDate, self.endDate];
}

@end


@implementation WLDateRange (Alignment)

- (WLDateRange *)dateRangeByAligningCalendarUnit:(NSCalendarUnit)aCalendarUnit calendar:(NSCalendar *)aCalendar options:(WLDateRangeAlignmentOptions)anOptions
{
    if (!aCalendar)
        aCalendar = [NSCalendar autoupdatingCurrentCalendar];

    NSDate *startDateOutward = nil;
    NSTimeInterval startDateInterval = 0.0;

    if (![aCalendar rangeOfUnit:aCalendarUnit startDate:&startDateOutward interval:&startDateInterval forDate:self.startDate])
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Cannot align (calendar unit: %lu) date range (%@) with calendar (%@) and options (%lu)", aCalendarUnit, self, aCalendar, anOptions];
    }

    NSDate *endDateInward = nil;
    NSTimeInterval endDateInterval = 0.0;

    if (![aCalendar rangeOfUnit:aCalendarUnit startDate:&endDateInward interval:&endDateInterval forDate:self.endDate])
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Cannot align (calendar unit: %lu) date range (%@) with calendar (%@) and options (%lu)", aCalendarUnit, self, aCalendar, anOptions];
    }

    NSDate *startDateInward = [startDateOutward dateByAddingTimeInterval:startDateInterval];
    NSDate *endDateOutward = [endDateInward dateByAddingTimeInterval:endDateInterval];

    if (([self.startDate isEqualToDate:startDateInward] || [self.startDate isEqualToDate:startDateOutward]) &&
        ([self.endDate isEqualToDate:endDateInward] || [self.endDate isEqualToDate:endDateOutward]))
    {
        // Current date range already aligned.
        return [self copy];
    }
    else if ((anOptions & WLAlignStartDateInward) && (anOptions & WLAlignEndDateInward))
        return [WLDateRange dateRangeWithStartDate:startDateInward endDate:endDateInward];
    else if ((anOptions & WLAlignStartDateInward) && (anOptions & WLAlignEndDateOutward))
        return [WLDateRange dateRangeWithStartDate:startDateInward endDate:endDateOutward];
    else if ((anOptions & WLAlignStartDateOutward) && (anOptions & WLAlignEndDateInward))
        return [WLDateRange dateRangeWithStartDate:startDateOutward endDate:endDateInward];
    else if ((anOptions & WLAlignStartDateOutward) && (anOptions & WLAlignEndDateOutward))
        return [WLDateRange dateRangeWithStartDate:startDateOutward endDate:endDateOutward];
    else
    {
        NSDate *startDateNearest = nil;
        NSDate *endDateNearest = nil;

        if (fabs([self.startDate timeIntervalSinceDate:startDateOutward]) <= fabs([self.startDate timeIntervalSinceDate:startDateInward]))
            startDateNearest = startDateOutward;
        else
            startDateNearest = startDateInward;

        if (fabs([self.endDate timeIntervalSinceDate:endDateOutward]) <= fabs([self.endDate timeIntervalSinceDate:endDateInward]))
            endDateNearest = endDateOutward;
        else
            endDateNearest = endDateInward;

        NSDate *startDate = nil;
        NSDate *endDate = nil;

        if (anOptions & WLAlignStartDateInward)
            startDate = startDateInward;
        else if (anOptions & WLAlignStartDateNearest)
            startDate = startDateNearest;
        else if (anOptions & WLAlignStartDateOutward)
            startDate = startDateOutward;
        else
            [NSException raise:NSInvalidArgumentException format:@"anOptions (%lu) does not specify alignment option for start date.", anOptions];

        if (anOptions & WLAlignEndDateInward)
            endDate = endDateInward;
        else if (anOptions & WLAlignEndDateNearest)
            endDate = endDateNearest;
        else if (anOptions & WLAlignEndDateOutward)
            endDate = endDateOutward;
        else
            [NSException raise:NSInvalidArgumentException format:@"anOptions (%lu) does not specify alignment option for end date.", anOptions];

        return [WLDateRange dateRangeWithStartDate:startDate endDate:endDate];
    }
}

@end


@implementation WLDateRange (Split)

- (NSArray *)splitIntoCalendarUnits:(NSCalendarUnit)aCalendarUnit calendar:(NSCalendar *)aCalendar
{
    if ([self.startDate compare:self.endDate] == NSOrderedDescending)
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"You cannot split reverse-date range (%@).", self];
    }

    if (!aCalendar)
        aCalendar = [NSCalendar autoupdatingCurrentCalendar];

    NSMutableArray *parts = [NSMutableArray array];
    NSDate *startUnitDate = nil;
    NSTimeInterval startUnitDateInterval = 0.0;
    NSDate *currentRangeStartDate = self.startDate;

    do
    {
        if (![aCalendar rangeOfUnit:aCalendarUnit startDate:&startUnitDate interval:&startUnitDateInterval forDate:currentRangeStartDate])
        {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Cannot split date range (%@) into calendar units (%lu) with calendar (%@)", self, aCalendarUnit, aCalendar];
        }

        NSDate *endUnitDate = [startUnitDate dateByAddingTimeInterval:startUnitDateInterval];
        [parts addObject:[WLDateRange dateRangeWithStartDate:currentRangeStartDate endDate:[endUnitDate earlierDate:self.endDate]]];
        startUnitDate = endUnitDate;
        currentRangeStartDate = startUnitDate;
    }
    while ([self.endDate compare:startUnitDate] == NSOrderedDescending);

    return parts;
}

@end

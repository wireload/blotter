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


NSString* const WLDateRangeLogName = @"net.wireload.mac.WLFoundation.WLDateRange";


@implementation WLDateRange

- (instancetype)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    self = [super init];

    if (self)
    {
        if (!aStartDate)
            aStartDate = [NSDate date];

        if (!anEndDate)
            anEndDate = [NSDate date];

        if ([aStartDate isGreaterThan:anEndDate])
            [[WLASLLog logForName:WLDateRangeLogName] logWarning:@"{%@, %@} is a reversed range", aStartDate, anEndDate];

        _startDate = [[aStartDate earlierDate:anEndDate] copy];
        _endDate = [[aStartDate laterDate:anEndDate] copy];
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
    return (self.startDate).hash;
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
    return [NSString stringWithFormat:@"{%@, %@}", self.startDate, self.endDate];
}

@end


@implementation WLDateRange (Alignment)

- (WLDateRange *)dateRangeByAligningCalendarUnit:(NSCalendarUnit)aCalendarUnit calendar:(NSCalendar *)aCalendar options:(WLDateRangeAlignmentOptions)anOptions
{
    if (!aCalendar)
        aCalendar = [NSCalendar currentCalendar];

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

    NSDate *startDate = self.startDate;
    NSDate *endDate = self.endDate;

    if (![startDate isEqualToDate:startDateInward] && ![startDate isEqualToDate:startDateOutward])
    {
        if (anOptions & WLAlignStartDateInward)
            startDate = startDateInward;
        else if (anOptions & WLAlignStartDateOutward)
            startDate = startDateOutward;
        else if (anOptions & WLAlignStartDateNearest)
        {
            NSDate *startDateNearest = nil;

            if (fabs([self.startDate timeIntervalSinceDate:startDateOutward]) <= fabs([self.startDate timeIntervalSinceDate:startDateInward]))
                startDateNearest = startDateOutward;
            else
                startDateNearest = startDateInward;

            startDate = startDateNearest;
        }
        else
            [NSException raise:NSInvalidArgumentException format:@"anOptions (%lu) does not specify alignment option for start date.", anOptions];
    }

    if (![endDate isEqualToDate:endDateInward] && ![endDate isEqualToDate:endDateOutward])
    {
        if (anOptions & WLAlignEndDateInward)
            endDate = endDateInward;
        else if (anOptions & WLAlignEndDateOutward)
            endDate = endDateOutward;
        else if (anOptions & WLAlignEndDateNearest)
        {
            NSDate *endDateNearest = nil;

            if (fabs([self.endDate timeIntervalSinceDate:endDateOutward]) <= fabs([self.endDate timeIntervalSinceDate:endDateInward]))
                endDateNearest = endDateOutward;
            else
                endDateNearest = endDateInward;

            endDate = endDateNearest;
        }
        else
            [NSException raise:NSInvalidArgumentException format:@"anOptions (%lu) does not specify alignment option for end date.", anOptions];
    }

    if ([startDate isGreaterThan:endDate])
        [[WLASLLog logForName:WLDateRangeLogName] logWarning:[NSString stringWithFormat:@"Alignment of %@ with %lu (%lu) resulted in reversed range", self, aCalendarUnit, anOptions]];

    return [WLDateRange dateRangeWithStartDate:startDate endDate:endDate];
}

@end


@implementation WLDateRange (Split)

- (NSArray *)splitIntoCalendarUnits:(NSCalendarUnit)aCalendarUnit calendar:(NSCalendar *)aCalendar
{
    if (!aCalendar)
        aCalendar = [NSCalendar currentCalendar];

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

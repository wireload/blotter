//
//  WLDateRange.m
//  Blotter
//
//  Created by Ilya Kulakov on 25.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLDateRange.h"


@implementation WLDateRange
@synthesize startDate;
@synthesize endDate;

+ (instancetype)dateRangeWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    return [[self alloc] initWithStartDate:aStartDate endDate:anEndDate];
}

- (instancetype)init
{
    NSDate *now = [NSDate date];
    return [self initWithStartDate:now endDate:now];
}

+ (instancetype)emptyDateRange
{
    return [[self alloc] init];
}

- (instancetype)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    self = [super init];

    if (self != nil)
    {
        startDate = [aStartDate copy];
        endDate = [anEndDate copy];
    }

    return self;
}

- (WLDateRange *)dateRangeByUnitingWithDateRange:(WLDateRange *)aDateRange
{
    return [[self class] dateRangeWithStartDate:[self.startDate earlierDate:aDateRange.startDate]
                                        endDate:[self.endDate laterDate:aDateRange.endDate]];
}


#pragma mark Methods

- (WLPositionRelativeToRange)positionOfDate:(NSDate *)aDate
{
    NSComparisonResult result = [aDate compare:startDate];
    if (result == NSOrderedAscending)
        return WLEarlierThanRange;
    else if (result == NSOrderedSame || [aDate compare:self.endDate] != NSOrderedDescending)
        return WLWithinRange;
    else
        return WLLaterThanRange;
}

- (BOOL)intersectsRange:(WLDateRange *)aRange
{
    WLPositionRelativeToRange startDatePosition = [self positionOfDate:aRange.startDate];
    if (startDatePosition != WLLaterThanRange)
    {
        WLPositionRelativeToRange endDatePosition = [self positionOfDate:aRange.endDate];
        if (endDatePosition != WLEarlierThanRange)
            return YES;
    }
    return NO;
}

- (BOOL)intersectsRange:(WLDateRange *)aRange position:(WLPositionRelativeToRange *)outPosition
{
    const WLPositionRelativeToRange startDatePosition = [self positionOfDate:aRange.startDate];
    if (startDatePosition != WLLaterThanRange)
    {
        const WLPositionRelativeToRange endDatePosition = [self positionOfDate:aRange.endDate];
        if (endDatePosition != WLEarlierThanRange)
        {
            if (startDatePosition == WLEarlierThanRange && endDatePosition == WLWithinRange)
                *outPosition = WLEarlierThanRange;
            else if (startDatePosition == WLEarlierThanRange && endDatePosition == WLLaterThanRange)
                *outPosition = WLOverlapsRange;
            else if (startDatePosition == WLWithinRange && endDatePosition == WLWithinRange)
                *outPosition = WLWithinRange;
            else if (startDatePosition == WLWithinRange && endDatePosition == WLLaterThanRange)
                *outPosition = WLLaterThanRange;
            return YES;
        }
        else
            *outPosition = WLEarlierThanRange;
    }
    else
        *outPosition = WLLaterThanRange;
    return NO;
}

- (BOOL)isEmpty
{
    return [self.startDate isEqualToDate:self.endDate];
}


#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] dateRangeWithStartDate:self.startDate endDate:self.endDate];
}

#pragma mark NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [WLMutableDateRange dateRangeWithStartDate:self.startDate endDate:self.endDate];
}


#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: {%@, %@}", [super description], startDate, endDate];
}

@end

//
//  WLDateRange.m
//  Blotter
//
//  Created by Ilya Kulakov on 25.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLDateRange.h"


@implementation WLDateRange
@synthesize startDate;
@synthesize endDate;

+ (id)dateRangeWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    return [[[self alloc] initWithStartDate:aStartDate endDate:anEndDate] autorelease];
}

- (id)init
{
    NSDate *now = [NSDate date];
    return [self initWithStartDate:now endDate:now];
}

- (id)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate
{
    self = [super init];
    if (self != nil)
    {
        startDate = [aStartDate retain];
        endDate = [anEndDate retain];
    }
    return self;
}

- (void)dealloc
{
    [startDate release];
    [endDate release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: {startDate :%@, endDate: %@}", [super description], startDate, endDate];
}

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

@end

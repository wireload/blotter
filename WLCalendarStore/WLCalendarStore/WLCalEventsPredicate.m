//
//  WLCalEventsPredicate.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 05.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalEventsPredicate.h"


@implementation WLCalEventsPredicate

- (instancetype)initWithDateRange:(WLDateRange *)aDateRange calendarIdentifiers:(NSArray *)aCalendarIdentifiers
{
    self = [super init];

    if (self)
    {
        _calendarIdentifiers = [aCalendarIdentifiers copy];
        _dateRange = [aDateRange copy];
    }

    return self;
}

- (instancetype)init
{
    return [self initWithDateRange:[WLDateRange emptyDateRange] calendarIdentifiers:nil];
}


#pragma mark Methods

+ (instancetype)predicateWithDateRange:(WLDateRange *)aDateRange calendarIdentifiers:(NSArray *)aCalendarIdentifiers
{
    return [[self alloc] initWithDateRange:aDateRange calendarIdentifiers:aCalendarIdentifiers];
}


#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self class] predicateWithDateRange:_dateRange calendarIdentifiers:_calendarIdentifiers];
}


#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@:\ndateRange: %@\ncalendars: %@", [super description], self.dateRange, self.calendarIdentifiers];
}

@end

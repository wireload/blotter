//
//  WLCalEventsPredicate.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 05.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalEventsPredicate.h"


@implementation WLCalEventsPredicate

- (instancetype)initWithDateRange:(WLDateRange *)aDateRange calendarIdentifiers:(NSArray *)calendarIdentifiers
{
    self = [super init];
    
    if (self)
    {
        _calendarIdentifiers = [calendarIdentifiers copy];
        _dateRange = [aDateRange copy];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithDateRange:[WLDateRange emptyDateRange] calendarIdentifiers:nil];
}


#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    WLCalEventsPredicate *p = [[WLCalEventsPredicate alloc] init];
    p->_dateRange = [_dateRange copy];
    p->_calendarIdentifiers = [_calendarIdentifiers copy];
    return p;
}


#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@:\ndateRange: %@\ncalendars: %@", [super description], self.dateRange, self.calendarIdentifiers];
}

@end

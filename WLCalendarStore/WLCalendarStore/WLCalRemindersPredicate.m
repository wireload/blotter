//
//  WLCalRemindersPredicate
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 05.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalRemindersPredicate.h"


@implementation WLCalRemindersPredicate

- (instancetype)initWithCompletionMask:(WLCalReminderCompletionMask)aCompletionMask calendarIdentifiers:(NSArray *)aCalendarIdentifiers
{
    self = [super init];

    if (self)
    {
        _calendarIdentifiers = [aCalendarIdentifiers copy];
        _completionMask = aCompletionMask;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithCompletionMask:WLCalReminderCompletionMaskIncomplete calendarIdentifiers:nil];
}


#pragma mark Methods

+ (instancetype)predicateWithCompletionMask:(WLCalReminderCompletionMask)aCompletionMask calendarIdentifiers:(NSArray *)aCalendarIdentifiers
{
    return [[self alloc] initWithCompletionMask:aCompletionMask calendarIdentifiers:aCalendarIdentifiers];
}


#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self class] predicateWithCompletionMask:_completionMask calendarIdentifiers:_calendarIdentifiers];
}


#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@:\ncompletionMask: %ld\ncalendars: %@", [super description],
            self.completionMask,
            self.calendarIdentifiers];
}

@end

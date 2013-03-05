//
//  WLCalSystemReminder.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalSystemReminder.h"


@implementation WLCalSystemReminder
@synthesize completed = _completed;
@synthesize completionDate = _completionDate;
@synthesize dueDateComponents = _dueDateComponents;
@synthesize priority = _priority;

- (WLCalSystemReminder *)initWithCSReminder:(CalTask *)aCSReminder calCalendar:(id <WLCalCalendar>)aCalendar
{
    NSParameterAssert(aCalendar != nil);

    self = [super init];

    if (self)
    {
        // WLCalCalendarItem
        self->_calendar = aCalendar;
        self->_notes = [aCSReminder.notes copy];
        self->_title = [aCSReminder.title copy];
        self->_lastModifiedDate = [aCSReminder.dateStamp copy];
        self->_location = @"";
        self->_itemIdentifier = [aCSReminder.uid copy];

        // WLCalReminder
        self->_completed = aCSReminder.isCompleted;
        self->_completionDate = [aCSReminder.completedDate copy];

        if (aCSReminder.dueDate)
        {
            NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            gregorianCalendar.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            gregorianCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            self->_dueDateComponents = [gregorianCalendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSCalendarCalendarUnit | NSTimeZoneCalendarUnit
                                                            fromDate:aCSReminder.dueDate];
        }
        self->_priority = aCSReminder.priority;
    }

    return self;
}


#pragma mark NSObject

- (BOOL)isEqual:(WLCalSystemReminder *)anObject
{
    if (![super isEqual:anObject])
        return NO;
    else if (self.completed != anObject.completed)
        return NO;
    else if (self.priority != anObject.priority)
        return NO;
    else if (![self.completionDate isEqual:anObject.completionDate])
        return NO;
    else if (![self.dueDateComponents isEqual:anObject.dueDateComponents])
        return NO;
    else
        return YES;
}

@end

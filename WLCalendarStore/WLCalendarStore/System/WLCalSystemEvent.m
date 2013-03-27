//
//  WLCalSystemEvent.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLCalSystemEvent.h"


@implementation WLCalSystemEvent
@synthesize allDay = _allDay;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize isDetached = _isDetached;
@synthesize occurrenceDate = _occurrenceDate;

- (WLCalSystemEvent *)initWithCSEvent:(CalEvent *)aCSEvent calCalendar:(NSObject <WLCalCalendar> *)aCalCalendar currentCalendar:(NSCalendar *)aCurrentCalendar
{
    NSParameterAssert(aCSEvent != nil);
    NSParameterAssert(aCalCalendar != nil);
    NSParameterAssert(aCurrentCalendar != nil);

    if (![aCSEvent.uid length])
        return nil;

    self = [super init];

    if (self)
    {
        // WLCalCalendarItem
        self->_calendar = aCalCalendar;
        self->_notes = [aCSEvent.notes copy];
        self->_title = [aCSEvent.title copy];
        self->_lastModifiedDate = [aCSEvent.dateStamp copy];
        self->_location = [aCSEvent.location copy];
        self->_itemIdentifier = [aCSEvent.uid copy];

        // WLCalEvent
        self->_allDay = aCSEvent.isAllDay;

        if (self->_allDay)
        {
            // It's known issue that CalendarStore fails to properly compute date range
            // of the floating event when timeZone changes (e.g. switching from summer to winder time).
            WLDateRange *r = [WLDateRange dateRangeWithStartDate:aCSEvent.startDate endDate:aCSEvent.endDate];
            r = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:aCurrentCalendar options:WLAlignInward];
            self->_startDate = r.startDate;
            self->_endDate = r.endDate;
        }
        else
        {
            self->_startDate = [aCSEvent.startDate copy];
            self->_endDate = [aCSEvent.endDate copy];
        }

        self->_isDetached = aCSEvent.isDetached;
        self->_occurrenceDate = [aCSEvent.occurrence copy];
    }

    return self;
}


#pragma mark NSObject

- (BOOL)isEqual:(WLCalSystemEvent *)anObject
{
    if (![super isEqual:anObject])
        return NO;
    else if (self.allDay != anObject.allDay)
        return NO;
    else if (self.isDetached != anObject.isDetached)
        return NO;
    else if (![self.startDate isEqual:anObject.startDate])
        return NO;
    else if (![self.endDate isEqual:anObject.endDate])
        return NO;
    else if (![self.startDate isEqual:anObject.startDate])
        return NO;
    else if (![self.occurrenceDate isEqual:anObject.occurrenceDate])
        return NO;
    else
        return YES;
}

- (NSString *)description
{
    NSMutableString *d = [NSMutableString stringWithFormat:@"%@: {", [super description]];
    [d appendFormat:@"Identifier: %@, ", self.itemIdentifier];
    [d appendFormat:@"Title: %@, ", self.title];
    [d appendFormat:@"Location: %@, ", self.location];
    [d appendFormat:@"Is All Day: %d, ", self.allDay];
    [d appendFormat:@"Is Detached: %d, ", self.isDetached];
    [d appendFormat:@"Start Date: %@, ", self.startDate];
    [d appendFormat:@"End Date: %@, ", self.endDate];
    [d appendFormat:@"Occurrence Date: %@, ", self.occurrenceDate];
    [d appendFormat:@"Last Modified Date: %@, ", self.lastModifiedDate];
    [d appendFormat:@"Notes: %@", self.notes];
    [d appendString:@"}"];
    return d;
}

@end

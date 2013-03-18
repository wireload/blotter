//
//  WLCalSystemEvent.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalSystemEvent.h"


@implementation WLCalSystemEvent
@synthesize allDay = _allDay;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize isDetached = _isDetached;
@synthesize occurrenceDate = _occurrenceDate;

- (WLCalSystemEvent *)initWithCSEvent:(CalEvent *)aCSEvent calCalendar:(id <WLCalCalendar>)aCalendar
{
    NSParameterAssert(aCSEvent != nil);
    NSParameterAssert(aCalendar != nil);

    if (![aCSEvent.uid length])
        return nil;

    self = [super init];

    if (self)
    {
        // WLCalCalendarItem
        self->_calendar = aCalendar;
        self->_notes = [aCSEvent.notes copy];
        self->_title = [aCSEvent.title copy];
        self->_lastModifiedDate = [aCSEvent.dateStamp copy];
        self->_location = [aCSEvent.location copy];
        self->_itemIdentifier = [aCSEvent.uid copy];

        // WLCalEvent
        self->_allDay = aCSEvent.isAllDay;
        self->_startDate = [aCSEvent.startDate copy];
        self->_endDate = [aCSEvent.endDate copy];
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

@end

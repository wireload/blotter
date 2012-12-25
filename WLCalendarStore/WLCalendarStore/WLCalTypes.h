//
//  WLCalTypes.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 12.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

typedef NS_ENUM(NSUInteger, WLCalCalendarType)
{
    WLCalendarTypeLocal,
    WLCalendarTypeCalDAV,
    WLCalendarTypeExchange,
    WLCalendarTypeSubscription,
    WLCalendarTypeBirthday,
    WLCalendarTypeIMAP
};


typedef NS_ENUM(NSUInteger, WLCalEntityType)
{
    WLCalEntityTypeEvent = 1,
    WLCalEntityTypeReminder
};


typedef NS_ENUM(NSUInteger, WLCalEntityMask)
{
    WLCalEntityMaskUnknown  = 0,
    WLCalEntityMaskEvent    = (1 << WLCalEntityTypeEvent),
    WLCalEntityMaskReminder = (1 << WLCalEntityTypeReminder),
};


typedef NS_ENUM(NSUInteger, WLCalEventAvailability)
{
    WLCalEventAvailabilityNotSupported  = -1,
    WLCalEventAvailabilityBusy          = 0,
    WLCalEventAvailabilityFree,
    WLCalEventAvailabilityTentative,
    WLCalEventAvailabilityUnavailable
};


typedef NS_ENUM(NSUInteger, WLCalEventStatus)
{
    WLCalEventStatusNone = 0,
    WLCalEventStatusConfirmed,
    WLCalEventStatusTentative,
    WLCalEventStatusCanceled,
};


typedef NS_ENUM(NSUInteger, WLCalCalendarEventAvailabilityMask)
{
    WLCalCalendarEventAvailabilityNone          = 0,    // calendar doesn't support event availability

    WLCalCalendarEventAvailabilityBusy          = (1 << 0),
    WLCalCalendarEventAvailabilityFree          = (1 << 1),
    WLCalCalendarEventAvailabilityTentative     = (1 << 2),
    WLCalCalendarEventAvailabilityUnavailable   = (1 << 3),
};


// Per RFC 5545, priorities of 1-4 are considered "high," a priority of 5 is "medium," and priorities of 6-9 are "low."
typedef NS_ENUM(NSUInteger, WLCalPriority)
{
    WLCalPriorityNone   = 0,
    WLCalPriorityHigh   = 1,
    WLCalPriorityMedium = 5,
    WLCalPriorityLow    = 9
};


typedef void (^WLCalErrorHandler)(NSError *anError);

typedef void (^WLCalUpdateHandler)();

//
//  WLCalTypes.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 12.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <EventKit/EventKit.h>


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
    WLCalEntityTypeEvent = EKEntityTypeEvent,
    WLCalEntityTypeReminder = EKEntityTypeReminder
};


typedef NS_ENUM(NSUInteger, WLCalEntityMask)
{
    WLCalEntityMaskUnknown  = 0,
    WLCalEntityMaskEvent    = (1 << WLCalEntityTypeEvent),
    WLCalEntityMaskReminder = (1 << WLCalEntityTypeReminder),
};


typedef NS_ENUM(NSInteger, WLCalEventAvailability)
{
    WLCalEventAvailabilityNotSupported = EKEventAvailabilityNotSupported,
    WLCalEventAvailabilityBusy = EKEventAvailabilityBusy,
    WLCalEventAvailabilityFree = EKEventAvailabilityFree,
    WLCalEventAvailabilityTentative = EKEventAvailabilityTentative,
    WLCalEventAvailabilityUnavailable = EKEventAvailabilityUnavailable
};


typedef NS_ENUM(NSUInteger, WLCalEventStatus)
{
    WLCalEventStatusNone = EKEventStatusNone,
    WLCalEventStatusConfirmed = EKEventStatusConfirmed,
    WLCalEventStatusTentative = EKEventStatusTentative,
    WLCalEventStatusCanceled = EKEventStatusCanceled,
};


typedef NS_ENUM(NSUInteger, WLCalCalendarEventAvailabilityMask)
{
    WLCalCalendarEventAvailabilityNone = EKCalendarEventAvailabilityNone,
    WLCalCalendarEventAvailabilityBusy = EKCalendarEventAvailabilityBusy,
    WLCalCalendarEventAvailabilityFree = EKCalendarEventAvailabilityFree,
    WLCalCalendarEventAvailabilityTentative = EKCalendarEventAvailabilityTentative,
    WLCalCalendarEventAvailabilityUnavailable = EKCalendarEventAvailabilityUnavailable,
};


// Per RFC 5545, priorities of 1-4 are considered "high," a priority of 5 is "medium," and priorities of 6-9 are "low."
typedef NS_ENUM(NSUInteger, WLCalPriority)
{
    WLCalPriorityNone   = 0,
    WLCalPriorityHigh   = 1,
    WLCalPriorityMedium = 5,
    WLCalPriorityLow    = 9
};


/*!
    @brief      Indicates the current authorization status for a specific entity type.

    @constant   WLCalAuthorizationStatusNotDetermined The user has not yet made a choice regarding whether the app may access the service.

    @constant   WLCalAuthorizationStatusRestricted The app is not authorized to access the service.
                The user cannot change this app’s authorization status, possibly due to active restrictions such as parental controls being in place.

    @constant   WLCalAuthorizationStatusDenied The user explicitly denied access to the service for the app.

    @constant   WLCalAuthorizationStatusAuthorized The app is authorized to access the service.
*/
typedef NS_ENUM(NSUInteger, WLCalAuthorizationStatus)
{
    WLCalAuthorizationStatusNotDetermined = EKAuthorizationStatusNotDetermined,
    WLCalAuthorizationStatusRestricted = EKAuthorizationStatusRestricted,
    WLCalAuthorizationStatusDenied = EKAuthorizationStatusDenied,
    WLCalAuthorizationStatusAuthorized = EKAuthorizationStatusAuthorized
};


typedef void (^WLCalErrorHandler)(NSError *anError);

typedef void (^WLCalUpdateHandler)(void);

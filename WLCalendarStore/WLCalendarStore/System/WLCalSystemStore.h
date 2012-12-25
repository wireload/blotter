//
//  WLCalSystemStore.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 11.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalStore.h>
#import <CalendarStore/CalendarStore.h>


/*!
    @discussion In method and variable naming Cal stands for WLCal, and CS stands for Apple's CalendarStore objects.
 */
@interface WLCalSystemStore : NSObject <WLCalStore>

/*!
    @brief  Asks iCal for calendar identifiers using AE.
    @result Returns UIDs of calendars in iCal or nil if it's not running.
 */
- (NSArray *)iCalCalendarUIDs;

/*!
    @brief      Fetches CalCalendar instances from CalendarStore.
    @param      anUIDs UIDs of CalCalendar instances you want to fetch.
    @param      outInvalidUIDs Points to an array that will contain UIDs of CalCalendar instances that cannot be fetched.
    @discussion Size of the result array may be less than [anUIDs count].

                Calendars have the same order as anUIDs.
                That is, if you remove objects from UIDs at outInvalidUIDs, order of calendars and the result UIDs will match.
                Thread safe.
 */
- (NSArray *)fetchCSCalendarsForUIDs:(NSArray *)anUIDs
                         invalidUIDs:(out __autoreleasing NSArray **)outInvalidUIDs;

/*!
    @brief      Fetches CalEvent instances from CalendarStore.
    @param      anEventsPredicate Predicate used to fetch events. MUST NOT be nil.
    @param      outCSCalendars Points to an array of calendars created while fetching events.
                It DOES NOT contain every calendar of fetched events. It SHOULD be used for caching only.
    @discussion Thread safe.
 */
- (NSArray *)fetchCSEventsMatchingPredicate:(WLCalEventsPredicate *)anEventsPredicate csCalednars:(__autoreleasing NSArray **)outCSCalendars;

/*!
    @brief      Fetches CalTask instances from CalendarStore.
    @param      aReminderPredicate Predicate used to fetch events. MUST NOT be nil.
    @param      outCSCalendars Points to an array of calendars created while fetching events.
                It DOES NOT contain every calendar of fetched reminders. It SHOULD be used for caching only.
    @discussion Thread safe.
 */
- (NSArray *)fetchCSRemindersMatchingPredicate:(WLCalRemindersPredicate *)aReminderPredicate csCalednars:(__autoreleasing NSArray **)outCSCalendars;

/*!
    @brief      Makes WLCalSystemCalendar instances from CalCalendar instances.
    @param      aCSCalendars CalCalendar instances.
    @result     An array of WLCalSystemCalendar instances created from csCalendar instances.
    @discussion Thread safe.
    @see        WLCalAllowsAdvancedCalendarTypeCheck
 */
- (NSArray *)makeCalendarsFromCSCalendars:(NSArray *)aCSCalendars;

/*!
    @brief      Returns allowed entity types for a given CalCalendar.
    @param      aCSCalendar An instance of CalCalendar which allowed entity types you want to know.
    @throws     Throws an exception if aCSCalendar is nil.
    @discussion Thread Safe.
 */
- (WLCalEntityMask)allowedEntityTypesForCSCalendar:(CalCalendar *)aCSCalendar;

@end

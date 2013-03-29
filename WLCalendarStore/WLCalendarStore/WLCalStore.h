//
//  WLCalStore.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 12.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalTypes.h>
#import <WLCalendarStore/WLCalEventsPredicate.h>
#import <WLCalendarStore/WLCalRemindersPredicate.h>


/*!
    @brief  Posted whenever calendar data represented by the object that adopts WLCalStore is changed.
 */
extern NSString *WLCalStoreDidChangeNotification;


/*!
    @brief  Comparator used to sort calendars returned by the object that adopts the WLCalStore protocol.
 */
extern NSComparator WLCalCalendarsComparator;

/*!
    @brief  Comparator used to sort and filter events returned by the object that adopts the WLCalStore protocol.
 */
extern NSComparator WLCalEventsComparator;

/*!
    @brief  Comparator used to sort and filter reminders returned by the object that adopts the WLCalStore protocol.
 */
extern NSComparator WLCalRemindersComparator;


@protocol WLCalCalendar;


/*!
    @brief      The WLCalStore protocol declares the elementary methods adopted by classes that provide access to internal calendar data.

    @discussion Object that adopts WLCalStore protocol is usually the top level object in the hierarchy (facade).
                It's responsible for fetching events observing external data and notifying users about changes.
 */
@protocol WLCalStore <NSObject>

/*!
    @brief      Returns store's calendars.

    @return     An array of objects that adopt the WLCalCalendar protocol sorted with  or an empty array if there are no calendars.

    @discussion Items in the returned array guaranteed to be unique in terms of WLCalCalendarsComparator.
                That is, there are no 2 objects that would return NSOrderedSame with WLCalCalendarsComparator this comparator.
 */
- (NSArray *)calendars;

/*!
    @brief  Returns calendar for a given identifier.

    @return An instance of object that adopts the WLCalCalendar protocol or nil if calendar for anIdentifier is not found.
 */
- (id<WLCalCalendar>)calendarWithIdentifier:(NSString *)anIdentifier;

/*!
    @brief      Returns events matching aPredicate.

    @param      aPredicate Predicate that specifies events to be fetched.

    @return     An array of objects that adopt the the WLCalEvent protocol sorted with WLCalEventsComparator or an empty array if there are no calendars.

    @discussion Events in the returned array are guaranteed to be unique in terms of WLCalEventsComparator.
                That is, there are no 2 objects that would return NSOrderedSame with this comparator.
 */
- (NSArray *)eventsMatchingPredicate:(WLCalEventsPredicate *)aPredicate;

/*!
    @brief      Returns reminders matching aPredicate.

    @param      aPredicate Predicate that specifies reminders to be fetched.

    @return     An array of objects that adopt the the WLCalReminder protocol sorted with WLCalRemindersComparator or an empty array if there are no calendars.

    @discussion Reminders in the returned array ar guaranteed to be unique in terms of WLCalRemindersComparator.
                That is, there are no 2 objects that would return NSOrderedSame with this comparator.
 */
- (NSArray *)remindersMatchingPredicate:(WLCalRemindersPredicate *)aPredicate;

/*!
    @brief      Unique identifier of the store.

    @discussion Framework does not use it, however it's useful to have unique identifier per store.
                If your store may have multiple instances (e.g. with different credentials), you're encouraged
                to have unique identifier per configuration.
 */
- (NSString *)storeIdentifier;

@end

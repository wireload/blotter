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


extern NSString *WLCalStoreDidChangeNotification;


extern NSComparator WLCalCalendarsComparator;

extern NSComparator WLCalEventsComparator;

extern NSComparator WLCalRemindersComparator;


@protocol WLCalCalendar;


/*!
    @brief  Object that adapts WLCalStore protocol is usually the top level object in the hierarchy (facade).
            It's responsible for fetching events observing external data and notifying users about changes.
 */
@protocol WLCalStore <NSObject>

- (NSArray *)calendars;

- (id<WLCalCalendar>)calendarWithIdentifier:(NSString *)anIdentifier;

/*!
    @discussion Events in the returned array is guaranteed to be unique in terms of WLCalEventsComparator.
                That is, there are no 2 objects that would return NSOrderedSame with this comparator.
 */
- (NSArray *)eventsMatchingPredicate:(WLCalEventsPredicate *)aPredicate;

/*!
    @discussion Reminders in the returned array is guaranteed to be unique in terms of WLCalRemindersComparator.
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

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

@end

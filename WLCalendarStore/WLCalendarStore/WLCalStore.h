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


@protocol WLCalCalendar;


@protocol WLCalStore <NSObject>

- (NSArray *)calendars;

- (id<WLCalCalendar>)calendarWithIdentifier:(NSString *)anIdentifier;

- (NSArray *)eventsMatchingPredicate:(WLCalEventsPredicate *)aPredicate;

- (NSArray *)remindersMatchingPredicate:(WLCalRemindersPredicate *)aPredicate;

@end

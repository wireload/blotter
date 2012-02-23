//
//  NSUserDefaults+WLApplicationDefaults.h
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 23.02.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>
#import "WLCalendarController.h"


extern NSInteger const WLBlotterBundleVersion2_1;

extern NSString* const WLLastMigratedBundleVersionKey;

extern NSString* const WLCalendarSizeKey;

extern NSString* const WLScreenIdentifierKey;

extern NSString* const WLDisplayAllCalendarsKey;

extern NSString* const WLCalendarsKey;

extern NSString* const WLCalendarUIDKey;

extern NSString* const WLCalendarIsUsedForEventsKey;

extern NSString* const WLCalendarIsUsedForRemindersKey;

extern NSString* const WLCalendarTypeKey;

extern NSString* const WLAllowsAdvancedCalendarTypeCheck;

typedef void (^WLCalendarsUpdaterBlock)(NSMutableArray *aCalendars);

extern NSComparator const WLCalendarsComparator;


@interface NSUserDefaults (WLApplicationDefaults)

- (void)WL_migrateIfNeeded;

- (void)WL_migrateTo2_1;

@end


@interface NSUserDefaults (WLScreensController)

- (void)WL_setDefaultScreenIdentifierIfNeeded;

- (void)WL_setScreenIdentifier:(NSNumber *)newScreenIdentifier;

- (NSNumber *)WL_screenIdentifier;

@end


@interface NSUserDefaults (WLCalendarController)

- (void)WL_setCalendars:(NSArray *)newCalendars;

- (NSArray *)WL_calendars;

- (void)WL_updateCalendars:(WLCalendarsUpdaterBlock)anUpdaterBlock;

- (void)WL_setDisplaysAllCalendars:(BOOL)newDisplaysAllCalendars;

- (BOOL)WL_displaysAllCalendars;

- (void)WL_setAllowsAdvancedCalendarTypeCheck:(BOOL)newAllowsAdvancedCalendarTypeCheck;

- (BOOL)WL_allowsAdvancedCalendarTypeCheck;

@end


@interface NSArray (WLCalendarController)

- (NSUInteger)WL_indexOfCalendarWithUID:(NSString *)anUID;

- (NSDictionary *)WL_calendarWithUID:(NSString *)anUID;

@end


@interface NSMutableArray (WLCalendarController)

- (void)WL_insertCalendar:(NSDictionary *)aCalendar;

- (void)WL_removeCalendarWithUID:(NSString *)anUID;

@end


@interface NSDictionary (WLCalendarController)

/*!
 @param aCalCalendar    MUST be non-nil.
 */
+ (NSDictionary *)WL_makeCalendarWithCalCalendar:(CalCalendar *)aCalCalendar;

@end

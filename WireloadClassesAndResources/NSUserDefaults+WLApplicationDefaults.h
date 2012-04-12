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

extern NSString* const WLSlowAnimationKey;

extern NSString* const WLApplicationRunTimerDelayKey;

extern NSString* const WLApplicationRunTimerElapsedSecondsKey;

extern NSString* const WLApplicationRunTimerIsFiredKey;

extern NSString* const WLShowRateThisAppInMenuKey;

extern NSString* const WLRateThisAppURLKey;

extern NSString* const WLGetHelpURLKey;

extern NSString* const WLGetSupportURLKey;

extern NSString* const WLFollowOnTwitterURLKey;

extern NSString* const WLWireloadURLKey;

extern NSString* const WLBannerURLKey;

extern NSString* const WLAnimateBringToFrontKey;

extern NSString* const WLAutoFadeKey;

extern NSString* const WLAutoFadeSecondsKey;

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


@interface NSUserDefaults (WLCalendarWindow)

- (BOOL)WL_slowsAnimation;

- (BOOL)WL_animatesBringToFront;

- (BOOL)WL_autoFades;

- (NSTimeInterval)WL_autoFadeSeconds;

@end


@interface NSUserDefaults (WLRateThisAppMenuItem)

- (NSTimeInterval)WL_applicationRunTimerDelay;

- (void)WL_setApplicationRunTimerDelay:(NSTimeInterval)newDelay;

- (NSTimeInterval)WL_applicationRunTimerElapsedSeconds;

- (void)WL_setApplicationRunTimerElapsedSeconds:(NSTimeInterval)newElapsed;

- (BOOL)WL_applicationRunTimerIsFired;

- (void)WL_setApplicationRunTimerIsFired:(BOOL)newIsFired;

- (BOOL)WL_showRateThisAppInMenu;

- (void)WL_setShowRateThisAppInMenu:(BOOL)newShow;

@end


@interface NSUserDefaults (WLURLs)

- (NSURL *)WL_rateThisAppURL;

- (NSURL *)WL_getHelpURL;

- (NSURL *)WL_getSupportURL;

- (NSURL *)WL_followOnTwitterURL;

- (NSURL *)WL_wireloadURL;

- (NSURL *)WL_bannerURL;

@end

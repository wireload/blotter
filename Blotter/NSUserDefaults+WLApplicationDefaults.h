//
//  NSUserDefaults+WLApplicationDefaults.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 23.02.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>


extern NSInteger const WLBlotterBundleVersion2_1;

extern NSInteger const WLBlotterBundleVersion2_2;

extern NSInteger const WLBlotterBundleVersion2_2_1;

extern NSInteger const WLBlotterBundleVersion2_2_2;

extern NSInteger const WLBlotterBundleVersion2_2_3;

extern NSInteger const WLBlotterBundleVersion2_2_4;

extern NSString* const WLLastMigratedBundleVersionKey;

extern NSString* const WLCalendarSizeKey;

extern NSString* const WLScreenIdentifierKey;

extern NSString* const WLDisplayAllCalendarsKey;

extern NSString* const WLCalendarsKey;

extern NSString* const WLCalendarIsUsedForEventsKey;

extern NSString* const WLCalendarIsUsedForRemindersKey;

extern NSString* const WLCalendarIsEnabledKey;

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

extern NSString* const WLPrivacyPolicyURLKey;

extern NSString* const WLAnimateBringToFrontKey;

extern NSString* const WLAutoFadeKey;

extern NSString* const WLAutoFadeSecondsKey;

extern NSString* const WLShowInMenuBar;

extern NSString* const WLShortcutNewEvent;

extern NSString* const WLShortcutNewTask;

extern NSString* const WLShortcutShowNextWeek;

extern NSString* const WLShortcutShowPreviousWeek;

extern NSString* const WLShortcutShowCurrentWeek;

extern NSString* const WLShortcutBringToFront;

extern NSString* const WLTitleFormatKey;

extern NSString* const WLShowsNext7DaysKey;

extern NSString* const WLLastSelectedCalEventCalendarUID;

extern NSString* const WLLastSelectedCalReminderCalendarUID;

extern NSString* const WLRequestShareAnalyticsConsentAtStartup;

extern NSString* const WLShareAnalytics;

extern NSString* const WLShowPreferencesAtStartUp;


@interface NSUserDefaults (WLApplicationDefaults)

- (void)WL_migrateIfNeeded;

- (void)WL_migrateTo2_1;

- (void)WL_migrateTo2_2;

- (void)WL_migrateTo2_2_1;

- (void)WL_migrateTo2_2_2;

- (void)WL_migrateTo2_2_3;

@end


@interface NSUserDefaults (WLScreensController)

- (void)WL_setDefaultScreenIdentifierIfNeeded;

- (void)WL_setScreenIdentifier:(NSNumber *)newScreenIdentifier;

- (NSNumber *)WL_screenIdentifier;

@end


@interface NSUserDefaults (WLCalendarWindow)

- (BOOL)WL_slowsAnimation;

- (BOOL)WL_animatesBringToFront;

- (BOOL)WL_autoFades;

- (NSTimeInterval)WL_autoFadeSeconds;

@end


@interface NSUserDefaults (WLRateThisAppMenuItem)

- (void)WL_resetTimer;

- (NSTimeInterval)WL_applicationRunTimerDelay;

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

- (NSURL *)WL_privacyPolicyURL;

@end


@interface NSUserDefaults (WLGeneralPreferences)

- (BOOL)WL_showInMenuBar;

- (BOOL)WL_showsNext7Days;

@end


@interface NSUserDefaults (WLCalendarsPreferences)

- (BOOL)WL_displaysAllCalendars;

- (void)WL_setDisplaysAllCalendars:(BOOL)newDisplaysAllCalendars;

@end


@interface NSUserDefaults (WLAboutPreferences)

- (BOOL)WL_requestShareAnalyticsConsentAtStartup;

- (BOOL)WL_shareAnalytics;

@end


#pragma mark - Deprecated

__attribute__((deprecated("Deprecated since 2.2"))) extern NSString* const WLCalendarUIDKey;

__attribute__((deprecated("Deprecated since 2.2"))) typedef void (^WLCalendarsUpdaterBlock)(NSMutableArray *aCalendars);

__attribute__((deprecated("Deprecated since 2.2"))) extern NSComparator const WLCalendarsComparator;


@interface NSUserDefaults (WLCalendarController)

- (void)WL_setCalendars:(NSArray *)newCalendars __attribute__((deprecated("Deprecated since 2.2")));

- (NSArray *)WL_calendars __attribute__((deprecated("Deprecated since 2.2")));

- (void)WL_updateCalendars:(WLCalendarsUpdaterBlock)anUpdaterBlock __attribute__((deprecated("Deprecated since 2.2")));

- (void)WL_setAllowsAdvancedCalendarTypeCheck:(BOOL)newAllowsAdvancedCalendarTypeCheck __attribute__((deprecated("Deprecated since 2.2")));

- (BOOL)WL_allowsAdvancedCalendarTypeCheck __attribute__((deprecated("Deprecated since 2.2")));

@end


@interface NSArray (WLCalendarController)

- (NSUInteger)WL_indexOfCalendarWithUID:(NSString *)anUID __attribute__((deprecated("Deprecated since 2.2")));

- (NSDictionary *)WL_calendarWithUID:(NSString *)anUID __attribute__((deprecated("Deprecated since 2.2")));

@end


@interface NSMutableArray (WLCalendarController)

- (void)WL_insertCalendar:(NSDictionary *)aCalendar __attribute__((deprecated("Deprecated since 2.2")));

- (void)WL_removeCalendarWithUID:(NSString *)anUID __attribute__((deprecated("Deprecated since 2.2")));

@end


@interface NSDictionary (WLCalendarController)

/*!
 @param aCalCalendar    MUST be non-nil.
 */
+ (NSDictionary *)WL_makeCalendarWithCalCalendar:(CalCalendar *)aCalCalendar __attribute__((deprecated("Deprecated since 2.2")));

@end

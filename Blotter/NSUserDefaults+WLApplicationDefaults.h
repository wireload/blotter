//
//  NSUserDefaults+WLApplicationDefaults.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 23.02.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CalendarStore/CalendarStore.h>


NS_ASSUME_NONNULL_BEGIN

extern NSInteger const WLBlotterBundleVersion2_1;

extern NSInteger const WLBlotterBundleVersion2_2;

extern NSInteger const WLBlotterBundleVersion2_2_1;

extern NSInteger const WLBlotterBundleVersion2_2_2;

extern NSInteger const WLBlotterBundleVersion2_2_3;

extern NSInteger const WLBlotterBundleVersion2_2_4;

extern NSInteger const WLBlotterBundleVersion2_2_5;

extern NSInteger const WLBlotterBundleVersion2_2_6;


extern NSString* const WLLastMigratedBundleVersionKey;

extern NSString* const WLCalendarSizeKey;

extern NSString* const WLScreenUUIDKey;

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

extern NSString* const WLLastReportedDailyEventAt;

extern NSString* const WLCustomFrameFactorsKey;

extern NSString* const WLCalendarPositionKey;

extern NSString* const WLCalendarLayoutKey;

extern NSString* const WLMinimumDateViewWidthtKey;

extern NSString* const WLMinimumDateViewHeightKey;

extern NSString* const WLMinimumWeekViewWidthKey;

extern NSString* const WLMinimumWeekViewHeightKey;

extern NSString* const WLMinimumTasksViewWidthKey;

extern NSString* const WLMinimumTasksViewHeightKey;

extern NSString* const WLMinimumRightNowViewWidthKey;

extern NSString* const WLMinimumRightNowViewHeightKey;

extern NSString* const WLInfoViewsWidthKey;

extern NSString* const WLDateViewHeightKey;

extern NSString* const WLTasksViewHeightKey;

extern NSString* const WLAllDayViewHeightKey;


typedef NS_ENUM(NSUInteger, BLSize)
{
    BLNarrowSize = 0,
    BLNormalSize = 1,
    BLFullSize = 2,
    BLCustomSize = 3
};

static const BLSize BLSizeCount = 4;


typedef NS_ENUM(NSUInteger, BLPosition)
{
    BLPositionTopLeft = 0,
    BLPositionTopCenter = 1,
    BLPositionTopRight = 2,
    BLPositionCenterLeft = 3,
    BLPositionCenterCenter = 4,
    BLPositionCenterRight = 5,
    BLPositionBottomLeft = 6,
    BLPositionBottomCenter = 7,
    BLPositionBottomRight = 8
};

static const BLPosition BLPositionCount = 9;


typedef NS_ENUM(NSUInteger, WLCalendarLayout)
{
    WLCalendarLayoutNormal = 0,
    WLCalendarLayoutCustom = 1,
    WLCalendarLayoutToDo = 2,
    WLCalendarLayoutRightNow = 3
};

static const WLCalendarLayout WLCalendarLayoutCount = 4;


@interface NSUserDefaults (WLApplicationDefaults)

- (void)WL_migrateIfNeeded;

- (void)WL_migrateTo2_1;

- (void)WL_migrateTo2_2;

- (void)WL_migrateTo2_2_1;

/*!
 @discussion
 - Transform NSDictionary-based shortcuts into SRShortcut
 */
- (void)WL_migrateTo2_2_5;

/*!
 @discussion
 - Replace screen identifier with screen UUID.
    Screen's identifier may change for the same screen when GPU is automatically switched (e.g. on MBP)
    while its UUID is more persistent.
 */
- (void)WL_migrateTo2_2_6;

/*!
 Register defaults values for application preferences.
 */
- (void)WL_registerDefaults;

/*!
 Verify that serialized application preferences are correct and fix them if needed.
 */
- (void)WL_validateAndFixIfNeeded;

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

@property (nullable, readonly, copy) NSURL *WL_rateThisAppURL;

@property (nullable, readonly, copy) NSURL *WL_getHelpURL;

@property (nullable, readonly, copy) NSURL *WL_getSupportURL;

@property (nullable, readonly, copy) NSURL *WL_followOnTwitterURL;

@property (nullable, readonly, copy) NSURL *WL_wireloadURL;

@property (nullable, readonly, copy) NSURL *WL_bannerURL;

@property (nullable, readonly, copy) NSURL *WL_privacyPolicyURL;

@end


@interface NSUserDefaults (WLPreferences)

@property BOOL WL_showPreferencesAtStartup;

@end


@interface NSUserDefaults (WLGeneralPreferences)

@property BOOL WL_showInMenuBar;

@property BOOL WL_showNext7Days;

@property BOOL WL_requestShareAnalyticsConsentAtStartup;

@property BOOL WL_shareAnalytics;

@end


@interface NSUserDefaults (WLCalendarsPreferences)

- (BOOL)WL_displaysAllCalendars;

- (void)WL_setDisplaysAllCalendars:(BOOL)newDisplaysAllCalendars;

@end


@interface NSUserDefaults (WLLayoutPreferences)

@property WLCalendarLayout WL_calendarLayout;

@property (readonly) CGFloat WL_minimumWeekViewWidth;

@property (readonly) CGFloat WL_minimumWeekViewHeight;

@property (readonly) CGFloat WL_minimumDateViewWidth;

@property (readonly) CGFloat WL_minimumDateViewHeight;

@property (readonly) CGFloat WL_minimumTasksViewWidth;

@property (readonly) CGFloat WL_minimumTasksViewHeight;

@property (readonly) CGFloat WL_minimumRightNowViewWidth;

@property (readonly) CGFloat WL_minimumRightNowViewHeight;

@property CGFloat WL_infoViewsWidth;

@property CGFloat WL_dateViewHeight;

@property CGFloat WL_tasksViewHeight;

@property CGFloat WL_allDayViewHeight;

@end


@interface NSUserDefaults (WLPositioningPreferences)

@property (readonly) NSSize WL_minimumWindowSize;

@property BLSize WL_calendarSize;

/*!
 Frame expressed using the screen coordinate system.
 */
@property NSRect WL_customFrameFactors;

@property BLPosition WL_calendarPosition;

/*!
 UUID of the screen selected by the user for the main window.
 */
@property (nullable, copy) NSUUID *WL_screenUUID;

@end


#pragma mark - Deprecated

extern NSString* const WLCalendarUIDKey __attribute__((deprecated("Deprecated since 2.2")));

extern NSString* const WLScreenIdentifierKey __attribute__((deprecated("Deprecated in 2.2.6", "WLScreenUUIDKey")));

typedef void (^WLCalendarsUpdaterBlock)(NSMutableArray *aCalendars) __attribute__((deprecated("Deprecated since 2.2"))) ;

extern NSComparator const WLCalendarsComparator __attribute__((deprecated("Deprecated since 2.2"))) ;


@interface NSUserDefaults (WLCalendarController)

- (void)WL_setCalendars:(NSArray *)newCalendars __attribute__((deprecated("Deprecated since 2.2")));

- (NSArray *)WL_calendars __attribute__((deprecated("Deprecated since 2.2")));

- (void)WL_updateCalendars:(WLCalendarsUpdaterBlock)anUpdaterBlock __attribute__((deprecated("Deprecated since 2.2")));

@end

NS_ASSUME_NONNULL_END

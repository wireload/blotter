//
//  NSUserDefaults+WLApplicationDefaults.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 23.02.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLCalendarWindowController.h"
#import "WLScreensController.h"
#import <ShortcutRecorder/ShortcutRecorder.h>


NSInteger const WLBlotterBundleVersion2_1 = 9;

NSInteger const WLBlotterBundleVersion2_2 = 10;

NSInteger const WLBlotterBundleVersion2_2_1 = 12;

NSInteger const WLBlotterBundleVersion2_2_2 = 13;

NSInteger const WLBlotterBundleVersion2_2_3 = 14;

NSInteger const WLBlotterBundleVersion2_2_4 = 23;

NSInteger const WLBlotterBundleVersion2_2_5 = 25;

NSInteger const WLBlotterBundleVersion2_2_6 = 27;

NSString* const WLLastMigratedBundleVersionKey = @"LastMigratedBundleVersion";

NSString* const WLCalendarSizeKey = @"CalendarSize";

NSString* const WLScreenIdentifierKey = @"ScreenIdentifier";

NSString* const WLScreenUUIDKey = @"ScreenUUID";

NSString* const WLCalendarsKey = @"Calendars";

NSString* const WLCalendarIsUsedForEventsKey = @"isUsedForEvents";

NSString* const WLCalendarIsUsedForRemindersKey = @"isUsedForReminders";

NSString* const WLCalendarIsEnabledKey = @"IsEnabled";

NSString* const WLDisplayAllCalendarsKey = @"DisplayAllCalendars";

NSString* const WLAllowsAdvancedCalendarTypeCheck = @"AllowsAdvancedCalendarTypeCheck";

NSString* const WLSlowAnimationKey = @"SlowAnimation";

NSString* const WLApplicationRunTimerDelayKey = @"ApplicationRunTimerDelay";

NSString* const WLApplicationRunTimerElapsedSecondsKey = @"ApplicationRunTimerElapsedSeconds";

NSString* const WLApplicationRunTimerIsFiredKey = @"ApplicationRunTimerIsFired";

NSString* const WLShowRateThisAppInMenuKey = @"ShowRateThisAppInMenu";

NSString* const WLRateThisAppURLKey = @"RateThisAppURL";

NSString* const WLGetHelpURLKey = @"GetHelpURL";

NSString* const WLGetSupportURLKey = @"GetSupportURL";

NSString* const WLFollowOnTwitterURLKey = @"FollowOnTwitterURL";

NSString* const WLWireloadURLKey = @"WireloadURL";

NSString* const WLBannerURLKey = @"BannerURL";

NSString* const WLPrivacyPolicyURLKey = @"PrivacyPolicyURL";

NSString* const WLAnimateBringToFrontKey = @"AnimateBringToFront";

NSString* const WLAutoFadeKey = @"AutoFade";

NSString* const WLAutoFadeSecondsKey = @"AutoFadeSeconds";

NSString* const WLShowInMenuBar = @"ShowInMenuBar";

NSString* const WLShortcutNewEvent = @"shortcutNewEvent";

NSString* const WLShortcutNewTask = @"shortcutNewTask";

NSString* const WLShortcutShowNextWeek = @"shortcutShowNextWeek";

NSString* const WLShortcutShowPreviousWeek = @"shortcutShowPreviousWeek";

NSString* const WLShortcutShowCurrentWeek = @"shortcutShowCurrentWeek";

NSString* const WLShortcutBringToFront = @"shortcutBringToFront";

NSString* const WLTitleFormatKey = @"PerDayDate";

NSString* const WLShowsNext7DaysKey = @"RollingCalendar";

NSString* const WLLastSelectedCalEventCalendarUID = @"uidOfLastSelectedCalendarInEvents";

NSString* const WLLastSelectedCalReminderCalendarUID = @"uidOfLastSelectedCalendarInTasks";

NSString* const WLRequestShareAnalyticsConsentAtStartup = @"RequestShareAnalyticsConsentAtStartup";

NSString* const WLShareAnalytics = @"ShareAnalytics";

NSString* const WLShowPreferencesAtStartUp = @"ShowPreferencesAtStartUp";

NSString* const WLLastReportedDailyEventAt = @"LastReportedDailyEventAt";

NSString* const WLCustomFrameFactorsKey = @"CustomFrameFactors";

NSString* const WLCalendarPositionKey = @"CalendarPosition";

NSString* const WLCalendarLayoutKey = @"CalendarLayout";

NSString* const WLMinimumDateViewWidthtKey = @"MinimumDateViewWidth";

NSString* const WLMinimumDateViewHeightKey = @"MinimumDateViewHeight";

NSString* const WLMinimumWeekViewWidthKey = @"MinimumWeekViewWidth";

NSString* const WLMinimumWeekViewHeightKey = @"MinimumWeekViewHeight";

NSString* const WLMinimumTasksViewWidthKey = @"MinimumTasksViewWidth";

NSString* const WLMinimumTasksViewHeightKey = @"MinimumTasksViewHeight";

NSString* const WLMinimumRightNowViewWidthKey = @"MinimumRightNowViewWidth";

NSString* const WLMinimumRightNowViewHeightKey = @"MinimumRightNowViewHeight";

NSString* const WLInfoViewsWidthKey = @"InfoViewsWidth";

NSString* const WLDateViewHeightKey = @"DateViewHeight";

NSString* const WLTasksViewHeightKey = @"TasksViewHeight";

NSString* const WLAllDayViewHeightKey = @"AllDayViewHeight";


@implementation NSUserDefaults (WLApplicationDefaults)

- (void)WL_migrateIfNeeded
{
    [NSProcessInfo.processInfo disableSuddenTermination];
    NSInteger lastMigratedBundleVersion = [self integerForKey:WLLastMigratedBundleVersionKey];
    NSBundle *blotterBundle = [NSBundle bundleWithIdentifier:@"net.wireload.blotter.mac"];
    NSInteger currentBundleVersion = [[blotterBundle objectForInfoDictionaryKey:@"CFBundleVersion"] integerValue];

    if (lastMigratedBundleVersion < currentBundleVersion)
    {
        // Actions to be perofmed each time app is updated.
        [self WL_resetTimer];
    }

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_1)
        [self WL_migrateTo2_1];

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2)
        [self WL_migrateTo2_2];

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2_1)
        [self WL_migrateTo2_2_1];

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2_5)
        [self WL_migrateTo2_2_5];

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2_6)
        [self WL_migrateTo2_2_6];

    lastMigratedBundleVersion = currentBundleVersion;
    [self setInteger:lastMigratedBundleVersion forKey:WLLastMigratedBundleVersionKey];
    [NSProcessInfo.processInfo enableSuddenTermination];
}

- (void)WL_migrateTo2_1
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_1);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // In pre 1.3 versions of Blotter CalendarSize was a string.
    if ([[self stringForKey:WLCalendarSizeKey] isEqualToString:@"Narrow"])
        [self setInteger:BLNarrowSize forKey:WLCalendarSizeKey];
    else if ([[self stringForKey:WLCalendarSizeKey] isEqualToString:@"Normal"])
        [self setInteger:BLNormalSize forKey:WLCalendarSizeKey];
    else if ([[self stringForKey:WLCalendarSizeKey] isEqualToString:@"Full"])
        [self setInteger:BLFullSize forKey:WLCalendarSizeKey];

    [self WL_updateCalendars:^(NSMutableArray *aCalendars) {
        for (NSUInteger i = 0, size = aCalendars.count; i < size; ++i)
        {
            NSMutableDictionary *calendarDict = [aCalendars[i] mutableCopy];
            NSNumber *oldCheck = [calendarDict valueForKey:@"check"];
            if (oldCheck != nil)
            {
                [calendarDict setValue:oldCheck forKey:WLCalendarIsUsedForEventsKey];
                [calendarDict setValue:oldCheck forKey:WLCalendarIsUsedForRemindersKey];
                [calendarDict removeObjectForKey:@"check"];
            }
            else
            {
                [calendarDict setValue:@(YES) forKey:WLCalendarIsUsedForEventsKey];
                [calendarDict setValue:@(YES) forKey:WLCalendarIsUsedForRemindersKey];
            }
            aCalendars[i] = calendarDict;
        }
    }];
#pragma clang diagnostic pop
}

- (void)WL_migrateTo2_2
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSArray *calendars = [self objectForKey:WLCalendarsKey];
    NSMutableDictionary *defaultsCalendars = [NSMutableDictionary dictionary];
    NSMutableDictionary *defaultsStore = [NSMutableDictionary dictionaryWithCapacity:calendars.count];

    for (NSDictionary *d in calendars)
    {
        if ([d[WLCalendarUIDKey] length] > 0)
        {
            defaultsStore[d[WLCalendarUIDKey]] = @{
                WLCalendarIsUsedForEventsKey: d[WLCalendarIsUsedForEventsKey],
                WLCalendarIsUsedForRemindersKey: d[WLCalendarIsUsedForRemindersKey]
            };
        }
    }

    defaultsCalendars[[WLCalendarStore systemStore].storeIdentifier] = defaultsStore;
    [self setObject:defaultsCalendars forKey:WLCalendarsKey];
#pragma clang diagnostic pop
}

- (void)WL_migrateTo2_2_1
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2_1);
    NSDictionary *calendarStores = [self objectForKey:WLCalendarsKey];
    NSMutableDictionary *newCalendarStores = [[NSMutableDictionary alloc] initWithCapacity:calendarStores.count];

    for (NSString *storeIdentifier in calendarStores)
    {
        NSDictionary *store = calendarStores[storeIdentifier];
        NSMutableDictionary *newStore = [[NSMutableDictionary alloc] initWithCapacity:store.count];

        for (NSString *calendarIdentifier in store)
        {
            NSMutableDictionary *calendar = [store[calendarIdentifier] mutableCopy];
            calendar[WLCalendarIsEnabledKey] = @(YES);
            newStore[calendarIdentifier] = calendar;
        }

        newCalendarStores[storeIdentifier] = newStore;
    }

    [self setObject:newCalendarStores forKey:WLCalendarsKey];
}

- (void)WL_migrateTo2_2_5
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2_5);

    __auto_type MigrateShortcut = ^(NSString *aKeyPath) {
        id shortcut = [self objectForKey:aKeyPath];

        if ([shortcut isKindOfClass:NSDictionary.class])
        {
            // shortcutWithDictionary: may return nil if the dict is invalid
            // which in turn will reset the shortcut to default by removing
            // it from the preferences file.
            shortcut = [SRShortcut shortcutWithDictionary:shortcut];
            [self setObject:[NSKeyedArchiver archivedDataWithRootObject:shortcut] forKey:aKeyPath];
        }
    };

    MigrateShortcut(WLShortcutNewTask);
    MigrateShortcut(WLShortcutNewEvent);
    MigrateShortcut(WLShortcutBringToFront);
    MigrateShortcut(WLShortcutShowNextWeek);
    MigrateShortcut(WLShortcutShowCurrentWeek);
    MigrateShortcut(WLShortcutShowPreviousWeek);
}

- (void)WL_migrateTo2_2_6
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2_6);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSNumber *screenIdentifier = [self objectForKey:WLScreenIdentifierKey];

    if (screenIdentifier != nil)
    {
        __auto_type screens = NSScreen.screens;
        NSUInteger currentScreenIdx = [screens indexOfObjectPassingTest:^BOOL(NSScreen *obj, NSUInteger idx, BOOL *stop) {
            return [obj.WL_identifier isEqual:screenIdentifier];
        }];

        if (currentScreenIdx != NSNotFound)
        {
            __auto_type currentScreen = screens[currentScreenIdx];
            [self setObject:currentScreen.WL_uuid.UUIDString forKey:WLScreenUUIDKey];
        }

        [self removeObjectForKey:WLScreenIdentifierKey];
    }
#pragma clang diagnostic pop
}

- (void)WL_registerDefaults
{
    NSURL *defaultsURL = [NSBundle.mainBundle URLForResource:@"defaults" withExtension:@"plist"];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithContentsOfURL:defaultsURL];

    // See -[WLCalendarWindowController tasksViewFrame] for default value of TasksViewHeight.

    __auto_type screens = NSScreen.screens;
    if (screens.count)
        defaults[WLScreenUUIDKey] = screens[0].WL_uuid.UUIDString;

    [self registerDefaults:defaults];
}

- (void)WL_validateAndFixIfNeeded
{
    // TODO: log error

    if (![[NSUUID alloc] initWithUUIDString:[self stringForKey:WLScreenUUIDKey]])
    {
        __auto_type screens = NSScreen.screens;

        if (screens.count)
            [self setObject:screens[0].WL_uuid.UUIDString forKey:WLScreenUUIDKey];
        else
            [self removeObjectForKey:WLScreenUUIDKey];
    }

    if (self.WL_calendarLayout >= WLCalendarLayoutCount)
        [self removeObjectForKey:WLCalendarLayoutKey];

    if (self.WL_calendarPosition >= BLPositionCount)
        [self removeObjectForKey:WLCalendarPositionKey];

    if (self.WL_calendarSize >= BLSizeCount)
        [self removeObjectForKey:WLCalendarSizeKey];

    NSRect factors = self.WL_customFrameFactors;
    factors.origin.x = MAX(0.0, MIN(1.0, factors.origin.x));
    factors.origin.y = MAX(0.0, MIN(1.0, factors.origin.y));
    factors.size.width = MAX(0.0, MIN(1.0, factors.size.width));
    factors.size.height = MAX(0.0, MIN(1.0, factors.size.height));

    if (NSIsEmptyRect(factors))
    {
        [self removeObjectForKey:WLCustomFrameFactorsKey];
        self.WL_calendarSize = BLNormalSize;
    }
    else
        self.WL_customFrameFactors = factors;
}

@end


#pragma mark -

@implementation NSUserDefaults (WLCalendarWindow)

- (BOOL)WL_slowsAnimation
{
    return [self boolForKey:WLSlowAnimationKey];
}

- (BOOL)WL_animatesBringToFront
{
    return [self boolForKey:WLAnimateBringToFrontKey];
}

- (BOOL)WL_autoFades
{
    return [self boolForKey:WLAutoFadeKey];
}

- (NSTimeInterval)WL_autoFadeSeconds
{
    return [self doubleForKey:WLAutoFadeSecondsKey];
}

@end


#pragma mark -

@implementation NSUserDefaults (WLRateThisAppMenuItem)

- (void)WL_resetTimer
{
    [self WL_setApplicationRunTimerElapsedSeconds:0.0];
    [self WL_setApplicationRunTimerIsFired:NO];
    [self WL_setShowRateThisAppInMenu:NO];
}

- (NSTimeInterval)WL_applicationRunTimerDelay
{
    return [self doubleForKey:WLApplicationRunTimerDelayKey];
}

- (NSTimeInterval)WL_applicationRunTimerElapsedSeconds
{
    return [self doubleForKey:WLApplicationRunTimerElapsedSecondsKey];
}

- (void)WL_setApplicationRunTimerElapsedSeconds:(NSTimeInterval)newElapsed
{
    [self setDouble:newElapsed forKey:WLApplicationRunTimerElapsedSecondsKey];
}

- (BOOL)WL_applicationRunTimerIsFired
{
    return [self boolForKey:WLApplicationRunTimerIsFiredKey];
}

- (void)WL_setApplicationRunTimerIsFired:(BOOL)newIsFired
{
    [self setBool:newIsFired forKey:WLApplicationRunTimerIsFiredKey];
}

- (BOOL)WL_showRateThisAppInMenu
{
    return [self boolForKey:WLShowRateThisAppInMenuKey];
}

- (void)WL_setShowRateThisAppInMenu:(BOOL)newShow
{
    [self setBool:newShow forKey:WLShowRateThisAppInMenuKey];
}

@end


#pragma mark -

@implementation NSUserDefaults (WLURLs)

#pragma mark Properties

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_rateThisAppURL
{
    return [NSSet setWithObject:WLRateThisAppURLKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_getHelpURL
{
    return [NSSet setWithObject:WLGetHelpURLKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_getSupportURL
{
    return [NSSet setWithObject:WLGetSupportURLKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_followOnTwitterURL
{
    return [NSSet setWithObject:WLFollowOnTwitterURLKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_wireloadURL
{
    return [NSSet setWithObject:WLWireloadURLKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_bannerURL
{
    return [NSSet setWithObject:WLBannerURLKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_privacyPolicyURL
{
    return [NSSet setWithObject:WLPrivacyPolicyURLKey];
}

- (NSURL *)WL_rateThisAppURL
{
    return [NSURL URLWithString:[self stringForKey:WLRateThisAppURLKey]];
}

- (NSURL *)WL_getHelpURL
{
    return [NSURL URLWithString:[self stringForKey:WLGetHelpURLKey]];
}

- (NSURL *)WL_getSupportURL
{
    return [NSURL URLWithString:[self stringForKey:WLGetSupportURLKey]];
}

- (NSURL *)WL_followOnTwitterURL
{
    return [NSURL URLWithString:[self stringForKey:WLFollowOnTwitterURLKey]];
}

- (NSURL *)WL_wireloadURL
{
    return [NSURL URLWithString:[self stringForKey:WLWireloadURLKey]];
}

- (NSURL *)WL_bannerURL
{
    return [NSURL URLWithString:[self stringForKey:WLBannerURLKey]];
}

- (NSURL *)WL_privacyPolicyURL
{
    return [NSURL URLWithString:[self stringForKey:WLPrivacyPolicyURLKey]];
}

@end


@implementation NSUserDefaults (WLGeneralPreferences)

- (BOOL)WL_showInMenuBar
{
    return [self boolForKey:WLShowInMenuBar];
}

- (BOOL)WL_showsNext7Days
{
    return [self boolForKey:WLShowsNext7DaysKey];
}

- (BOOL)WL_requestShareAnalyticsConsentAtStartup
{
    return [self boolForKey:WLRequestShareAnalyticsConsentAtStartup];
}

- (BOOL)WL_shareAnalytics
{
    return [self boolForKey:WLShareAnalytics];
}

@end


@implementation NSUserDefaults (WLLayoutPreferences)

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_calendarLayout
{
    return [NSSet setWithObject:WLCalendarLayoutKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumWeekViewWidth
{
    return [NSSet setWithObject:WLMinimumWeekViewWidthKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumWeekViewHeight
{
    return [NSSet setWithObject:WLMinimumWeekViewHeightKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_infoViewsWidth
{
    return [NSSet setWithObject:WLInfoViewsWidthKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_dateViewHeight
{
    return [NSSet setWithObject:WLDateViewHeightKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_tasksViewHeight
{
    return [NSSet setWithObject:WLTasksViewHeightKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_allDayViewHeight
{
    return [NSSet setWithObject:WLAllDayViewHeightKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumDateViewWidth
{
    return [NSSet setWithObject:WLMinimumDateViewWidthtKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumDateViewHeight
{
    return [NSSet setWithObject:WLMinimumDateViewHeightKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumTasksViewWidth
{
    return [NSSet setWithObject:WLMinimumTasksViewWidthKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumTasksViewHeight
{
    return [NSSet setWithObject:WLMinimumTasksViewHeightKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumRightNowViewWidth
{
    return [NSSet setWithObject:WLMinimumRightNowViewWidthKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_minimumRightNowViewHeight
{
    return [NSSet setWithObject:WLMinimumRightNowViewHeightKey];
}

- (WLCalendarLayout)WL_calendarLayout
{
    return [[self objectForKey:WLCalendarLayoutKey] unsignedIntegerValue];
}

- (void)setWL_calendarLayout:(WLCalendarLayout)newLayout
{
    [self setObject:@(newLayout) forKey:WLCalendarLayoutKey];
}

- (CGFloat)WL_minimumWeekViewHeight
{
    return [self doubleForKey:WLMinimumWeekViewHeightKey];
}

- (CGFloat)WL_minimumWeekViewWidth
{
    return [self doubleForKey:WLMinimumWeekViewWidthKey];
}

- (CGFloat)WL_infoViewsWidth
{
    return [self doubleForKey:WLInfoViewsWidthKey];
}

- (void)setWL_infoViewsWidth:(CGFloat)newWidth
{
    [self setDouble:newWidth forKey:WLInfoViewsWidthKey];
}

- (CGFloat)WL_dateViewHeight
{
    return [self doubleForKey:WLDateViewHeightKey];
}

- (void)setWL_dateViewHeight:(CGFloat)newHeight
{
    [self setDouble:newHeight forKey:WLDateViewHeightKey];
}

- (CGFloat)WL_tasksViewHeight
{
    return [self doubleForKey:WLTasksViewHeightKey];
}

- (void)setWL_tasksViewHeight:(CGFloat)newHeight
{
    [self setDouble:newHeight forKey:WLTasksViewHeightKey];
}

- (CGFloat)WL_allDayViewHeight
{
    return [self doubleForKey:WLAllDayViewHeightKey];
}

- (void)setWL_allDayViewHeight:(CGFloat)newHeight
{
    [self setDouble:newHeight forKey:WLAllDayViewHeightKey];
}

- (CGFloat)WL_minimumDateViewWidth
{
    return [self doubleForKey:WLMinimumDateViewWidthtKey];
}

- (CGFloat)WL_minimumDateViewHeight
{
    return [self doubleForKey:WLMinimumDateViewHeightKey];
}

- (CGFloat)WL_minimumTasksViewWidth
{
    return [self doubleForKey:WLMinimumTasksViewWidthKey];
}

- (CGFloat)WL_minimumTasksViewHeight
{
    return [self doubleForKey:WLMinimumTasksViewHeightKey];
}

- (CGFloat)WL_minimumRightNowViewWidth
{
    return [self doubleForKey:WLMinimumRightNowViewWidthKey];
}

- (CGFloat)WL_minimumRightNowViewHeight
{
    return [self doubleForKey:WLMinimumRightNowViewHeightKey];
}

@end


@implementation NSUserDefaults (WLPositioningPreferences)

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_customFrameFactors
{
    return [NSSet setWithObject:WLCustomFrameFactorsKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_calendarSize
{
    return [NSSet setWithObject:WLCalendarSizeKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_calendarPosition
{
    return [NSSet setWithObject:WLCalendarPositionKey];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_screenUUID
{
    return [NSSet setWithObject:WLScreenUUIDKey];
}

- (NSRect)WL_customFrameFactors
{
    return NSRectFromString([self stringForKey:WLCustomFrameFactorsKey]);
}

- (void)setWL_customFrameFactors:(NSRect)newFactors
{
    [self setObject:NSStringFromRect(newFactors) forKey:WLCustomFrameFactorsKey];
}

- (BLSize)WL_calendarSize
{
    return [[self objectForKey:WLCalendarSizeKey] unsignedIntegerValue];
}

- (void)setWL_calendarSize:(BLSize)newSize
{
    [self setObject:@(newSize) forKey:WLCalendarSizeKey];
}

- (BLPosition)WL_calendarPosition
{
    return [[self objectForKey:WLCalendarPositionKey] unsignedIntegerValue];
}

- (void)setWL_calendarPosition:(BLPosition)newPosition
{
    [self setObject:@(newPosition) forKey:WLCalendarPositionKey];
}

- (NSUUID *)WL_screenUUID
{
    return [[NSUUID alloc] initWithUUIDString:[self stringForKey:WLScreenUUIDKey]];
}

- (void)setWL_screenUUID:(NSUUID *)newUUID
{
    [self setObject:newUUID.UUIDString forKey:WLScreenUUIDKey];
}

@end


@implementation NSUserDefaults (WLCalendarsPreferences)

- (BOOL)WL_displaysAllCalendars
{
    return [self boolForKey:WLDisplayAllCalendarsKey];
}

- (void)WL_setDisplaysAllCalendars:(BOOL)newDisplaysAllCalendars
{
    [self setBool:newDisplaysAllCalendars forKey:WLDisplayAllCalendarsKey];
}

@end


#pragma mark - Deprecated

NSString* const WLCalendarUIDKey = @"uid";


NSComparator const WLCalendarsComparator = ^(id left, id right) {
    return [[left valueForKey:WLCalendarUIDKey] compare:[right valueForKey:WLCalendarUIDKey]];
};


@implementation NSUserDefaults (WLCalendarController)

- (void)WL_setCalendars:(NSArray *)newCalendars
{
    [self setObject:newCalendars forKey:WLCalendarsKey];
}

- (NSArray *)WL_calendars
{
    return [self arrayForKey:WLCalendarsKey];
}

- (void)WL_updateCalendars:(WLCalendarsUpdaterBlock)anUpdaterBlock
{
    if (anUpdaterBlock == NULL)
        return;
    NSMutableArray *calendars = [[self arrayForKey:WLCalendarsKey] mutableCopy];
    anUpdaterBlock(calendars);
    [self setObject:calendars forKey:WLCalendarsKey];
}

@end

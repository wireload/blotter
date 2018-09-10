//
//  NSUserDefaults+WLApplicationDefaults.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 23.02.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLCalendarWindowController.h"


NSInteger const WLBlotterBundleVersion2_1 = 9;

NSInteger const WLBlotterBundleVersion2_2 = 10;

NSInteger const WLBlotterBundleVersion2_2_1 = 12;

NSInteger const WLBlotterBundleVersion2_2_2 = 13;

NSInteger const WLBlotterBundleVersion2_2_3 = 14;

NSInteger const WLBlotterBundleVersion2_2_4 = 19;

NSString* const WLLastMigratedBundleVersionKey = @"LastMigratedBundleVersion";

NSString* const WLCalendarSizeKey = @"CalendarSize";

NSString* const WLScreenIdentifierKey = @"ScreenIdentifier";

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


@implementation NSUserDefaults (WLApplicationDefaults)

- (void)WL_migrateIfNeeded
{
    [[NSProcessInfo processInfo] disableSuddenTermination];
    NSInteger lastMigratedBundleVersion = [self integerForKey:WLLastMigratedBundleVersionKey];
    NSBundle *blotterBundle = [NSBundle bundleWithIdentifier:@"net.wireload.blotter.mac"];
    NSInteger currentBundleVersion = [[blotterBundle objectForInfoDictionaryKey:@"CFBundleVersion"] integerValue];

    if (lastMigratedBundleVersion < currentBundleVersion)
    {
        // Actions to be perofmed each time app is updated.
        [self WL_resetTimer];
    }

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_1)
    {
        [self WL_migrateTo2_1];
        lastMigratedBundleVersion = WLBlotterBundleVersion2_1;
    }

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2)
    {
        [self WL_migrateTo2_2];
        lastMigratedBundleVersion = WLBlotterBundleVersion2_2;
    }

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2_1)
    {
        [self WL_migrateTo2_2_1];
        lastMigratedBundleVersion = WLBlotterBundleVersion2_2_1;
    }

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2_2)
    {
        [self WL_migrateTo2_2_2];
        lastMigratedBundleVersion = WLBlotterBundleVersion2_2_2;
    }

    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_2_3)
    {
        [self WL_migrateTo2_2_3];
    }

    lastMigratedBundleVersion = currentBundleVersion;
    [self setInteger:lastMigratedBundleVersion forKey:WLLastMigratedBundleVersionKey];
    [[NSProcessInfo processInfo] enableSuddenTermination];
}

- (void)WL_migrateTo2_1
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_1);
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
}

- (void)WL_migrateTo2_2
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2);
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

- (void)WL_migrateTo2_2_2
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2_2);
}

- (void)WL_migrateTo2_2_3
{
    NSLog(@"Migrate Preferences to %d", (int)WLBlotterBundleVersion2_2_2);
}

@end


#pragma mark -

@implementation NSUserDefaults (WLScreensController)

- (void)WL_setDefaultScreenIdentifierIfNeeded
{
    if ([self WL_screenIdentifier] == nil)
    {
        NSArray *screens = [NSScreen screens];
        if (screens.count > 0)
            [self WL_setScreenIdentifier:[screens[0] deviceDescription][@"NSScreenNumber"]];
    }
}

- (void)WL_setScreenIdentifier:(NSNumber *)newScreenIdentifier
{
    [self setObject:newScreenIdentifier forKey:WLScreenIdentifierKey];
}

- (NSNumber *)WL_screenIdentifier
{
    return [self objectForKey:WLScreenIdentifierKey];
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

- (NSURL *)WL_rateThisAppURL
{
    NSString *s = [self stringForKey:WLRateThisAppURLKey];
    return [NSURL URLWithString:s];
}

- (NSURL *)WL_getHelpURL
{
    NSString *s = [self stringForKey:WLGetHelpURLKey];
    return [NSURL URLWithString:s];
}

- (NSURL *)WL_getSupportURL
{
    NSString *s = [self stringForKey:WLGetSupportURLKey];
    return [NSURL URLWithString:s];
}

- (NSURL *)WL_followOnTwitterURL
{
    NSString *s = [self stringForKey:WLFollowOnTwitterURLKey];
    return [NSURL URLWithString:s];
}

- (NSURL *)WL_wireloadURL
{
    NSString *s = [self stringForKey:WLWireloadURLKey];
    return [NSURL URLWithString:s];
}

- (NSURL *)WL_bannerURL
{
    NSString *s = [self stringForKey:WLBannerURLKey];
    return [NSURL URLWithString:s];
}

- (NSURL *)WL_privacyPolicyURL
{
    NSString *s = [self stringForKey:WLPrivacyPolicyURLKey];
    return [NSURL URLWithString:s];
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


@implementation NSUserDefaults (WLAboutPreferences)

- (BOOL)WL_requestShareAnalyticsConsentAtStartup
{
    return [self boolForKey:WLRequestShareAnalyticsConsentAtStartup];
}

- (BOOL)WL_shareAnalytics
{
    return [self boolForKey:WLShareAnalytics];
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

- (void)WL_setAllowsAdvancedCalendarTypeCheck:(BOOL)newAllowsAdvancedCalendarTypeCheck
{
    [self setBool:newAllowsAdvancedCalendarTypeCheck forKey:WLAllowsAdvancedCalendarTypeCheck];
}

- (BOOL)WL_allowsAdvancedCalendarTypeCheck
{
    return [self boolForKey:WLAllowsAdvancedCalendarTypeCheck];
}

@end


@implementation NSArray (WLCalendarController)

- (NSUInteger)WL_indexOfCalendarWithUID:(NSString *)anUID
{
    return [self indexOfObject:@{WLCalendarUIDKey: anUID}
                 inSortedRange:NSMakeRange(0, self.count)
                       options:NSBinarySearchingFirstEqual
               usingComparator:WLCalendarsComparator];
}

- (NSDictionary *)WL_calendarWithUID:(NSString *)anUID
{
    NSUInteger index = [self WL_indexOfCalendarWithUID:anUID];
    if (index != NSNotFound)
        return self[index];
    else
        return nil;
}

@end


@implementation NSMutableArray (WLCalendarController)

- (void)WL_insertCalendar:(NSDictionary *)aCalendar
{
    NSParameterAssert(aCalendar[WLCalendarUIDKey]);

    NSUInteger index = [self indexOfObject:aCalendar
                             inSortedRange:NSMakeRange(0, self.count)
                                   options:NSBinarySearchingInsertionIndex
                           usingComparator:WLCalendarsComparator];
    [self insertObject:aCalendar atIndex:index];
}

- (void)WL_removeCalendarWithUID:(NSString *)anUID
{
    NSUInteger index = [self WL_indexOfCalendarWithUID:anUID];
    if (index != NSNotFound)
        [self removeObjectAtIndex:index];
}

@end


@implementation NSDictionary (WLCalendarController)

+ (NSDictionary *)WL_makeCalendarWithCalCalendar:(CalCalendar *)aCalCalendar
{
    NSParameterAssert(aCalCalendar != nil);

    NSDictionary *calendar = @{WLCalendarUIDKey: aCalCalendar.uid,
                                               WLCalendarIsUsedForEventsKey: @(YES),
                                               WLCalendarIsUsedForRemindersKey: @(YES)};
    return calendar;
}

@end

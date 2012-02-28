//
//  NSUserDefaults+WLApplicationDefaults.m
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 23.02.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLCalendarWindowController.h"


NSInteger const WLBlotterBundleVersion2_1 = 9;

NSString* const WLLastMigratedBundleVersionKey = @"LastMigratedBundleVersion";

NSString* const WLCalendarSizeKey = @"CalendarSize";

NSString* const WLScreenIdentifierKey = @"ScreenIdentifier";

NSString* const WLCalendarsKey = @"Calendars";

NSString* const WLCalendarUIDKey = @"uid";

NSString* const WLCalendarIsUsedForEventsKey = @"isUsedForEvents";

NSString* const WLCalendarIsUsedForRemindersKey = @"isUsedForReminders";

NSString* const WLCalendarTypeKey = @"type";

NSString* const WLDisplayAllCalendarsKey = @"DisplayAllCalendars";

NSString* const WLAllowsAdvancedCalendarTypeCheck = @"AllowsAdvancedCalendarTypeCheck";

NSString* const WLSlowAnimationKey = @"SlowAnimation";

NSComparator const WLCalendarsComparator = ^(id left, id right) {
    return [[left valueForKey:WLCalendarUIDKey] compare:[right valueForKey:WLCalendarUIDKey]];
};


@implementation NSUserDefaults (WLApplicationDefaults)

- (void)WL_migrateIfNeeded
{
    [[NSProcessInfo processInfo] disableSuddenTermination];
    NSInteger lastMigratedBundleVersion = [self integerForKey:WLLastMigratedBundleVersionKey];
    if (lastMigratedBundleVersion < WLBlotterBundleVersion2_1)
    {
        [self WL_migrateTo2_1];
        lastMigratedBundleVersion = WLBlotterBundleVersion2_1;
    }

    NSBundle *blotterBundle = [NSBundle bundleWithIdentifier:@"net.wireload.blotter.mac"];
    lastMigratedBundleVersion = [[blotterBundle objectForInfoDictionaryKey:@"CFBundleVersion"] integerValue];
    [self setInteger:lastMigratedBundleVersion forKey:WLLastMigratedBundleVersionKey];
    [[NSProcessInfo processInfo] enableSuddenTermination];
}

- (void)WL_migrateTo2_1
{
    NSLog(@"Migrate to %d", WLBlotterBundleVersion2_1);
    // In pre 1.3 versions of Blotter CalendarSize was a string.
    if ([[self stringForKey:WLCalendarSizeKey] isEqualToString:@"Narrow"])
        [self setInteger:BLNarrowSize forKey:WLCalendarSizeKey];
    else if ([[self stringForKey:WLCalendarSizeKey] isEqualToString:@"Normal"])
        [self setInteger:BLNormalSize forKey:WLCalendarSizeKey];
    else if ([[self stringForKey:WLCalendarSizeKey] isEqualToString:@"Full"])
        [self setInteger:BLFullSize forKey:WLCalendarSizeKey];

    [self WL_updateCalendars:^(NSMutableArray *aCalendars) {
        for (NSUInteger i = 0, size = [aCalendars count]; i < size; ++i)
        {
            NSMutableDictionary *calendarDict = [[aCalendars objectAtIndex:i] mutableCopy];
            NSNumber *oldCheck = [calendarDict valueForKey:@"check"];
            if (oldCheck != nil)
            {
                [calendarDict setValue:oldCheck forKey:WLCalendarIsUsedForEventsKey];
                [calendarDict setValue:oldCheck forKey:WLCalendarIsUsedForRemindersKey];
                [calendarDict removeObjectForKey:@"check"];
            }
            else
            {
                [calendarDict setValue:[NSNumber numberWithBool:YES] forKey:WLCalendarIsUsedForEventsKey];
                [calendarDict setValue:[NSNumber numberWithBool:YES] forKey:WLCalendarIsUsedForRemindersKey];
            }
            [aCalendars replaceObjectAtIndex:i withObject:calendarDict];
            [calendarDict release];
        }
    }];
}

@end


#pragma mark -


@implementation NSUserDefaults (WLScreensController)

- (void)WL_setDefaultScreenIdentifierIfNeeded
{
    if ([self WL_screenIdentifier] == nil)
    {
        NSArray *screens = [NSScreen screens];
        if ([screens count] > 0)
            [self WL_setScreenIdentifier:[[[screens objectAtIndex:0] deviceDescription] objectForKey:@"NSScreenNumber"]];
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

    anUpdaterBlock([self mutableArrayValueForKey:WLCalendarsKey]);
    [self synchronize];
}

- (void)WL_setDisplaysAllCalendars:(BOOL)newDisplaysAllCalendars
{
    [self setBool:newDisplaysAllCalendars forKey:WLDisplayAllCalendarsKey];
}

- (BOOL)WL_displaysAllCalendars
{
    return [self boolForKey:WLDisplayAllCalendarsKey];
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
    return [self indexOfObject:[NSDictionary dictionaryWithObject:anUID forKey:WLCalendarUIDKey]
                 inSortedRange:NSMakeRange(0, [self count])
                       options:NSBinarySearchingFirstEqual
               usingComparator:WLCalendarsComparator];
}

- (NSDictionary *)WL_calendarWithUID:(NSString *)anUID
{
    NSUInteger index = [self WL_indexOfCalendarWithUID:anUID];
    if (index != NSNotFound)
        return [self objectAtIndex:index];
    else
        return nil;
}

@end


@implementation NSMutableArray (WLCalendarController)

- (void)WL_insertCalendar:(NSDictionary *)aCalendar
{
    NSParameterAssert([aCalendar objectForKey:WLCalendarUIDKey]);

    NSUInteger index = [self indexOfObject:aCalendar
                                  inSortedRange:NSMakeRange(0, [self count])
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

    NSDictionary *calendar = [NSDictionary dictionaryWithObjectsAndKeys:
                              aCalCalendar.uid,                                                                     WLCalendarUIDKey,
                              [NSNumber numberWithBool:YES],                                                        WLCalendarIsUsedForEventsKey,
                              [NSNumber numberWithBool:YES],                                                        WLCalendarIsUsedForRemindersKey,
                              [NSNumber numberWithInteger:[WLCalendarController _typeForCalCalendar:aCalCalendar]], WLCalendarTypeKey,
                              nil];
    return calendar;
}

@end


#pragma mark -

@implementation NSUserDefaults (WLCalendarWindowController)

- (BOOL)WL_slowsAnimation
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WLSlowAnimationKey];
}

@end


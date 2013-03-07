//
//  WLCalendarData.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLCalendarController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


NSString * WLStringFromCalendarType(WLCalendarType aCalendarType)
{
    switch (aCalendarType) {
        case WLCalendarUnknownType:
            return @"Unknown";
        case WLCalendarEventType:
            return @"Event";
        case WLCalendarReminderType:
            return @"Reminder";
        case WLCalendarBothType:
            return @"Both";
        default:
            return [NSString stringWithFormat:@"%d", aCalendarType];
    }
}


@interface WLCalendarController (/*Private*/)

@property (nonatomic, retain) NSCalendar *calendar;

@property (nonatomic, retain) NSDate *date;

@property (nonatomic, copy) NSArray *calCalendarsToDisplay;

@property (nonatomic, copy) NSArray *calEventCalendarsToDisplay;

@property (nonatomic, copy) NSArray *calReminderCalendarsToDisplay;

@property(nonatomic, copy) NSArray *calCalendars;

@property(nonatomic, copy) NSArray *calEventCalendars;

@property(nonatomic, copy) NSArray *calReminderCalendars;

@end


@implementation WLCalendarController
{
    id<WLCalStore> _calStore;
}

+ (WLCalendarController *)sharedController
{
    static dispatch_once_t onceToken;
    static WLCalendarController *sharedController = nil;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSNotificationCenter *n = [NSNotificationCenter defaultCenter];

        _calStore = [WLCalendarStore systemStore];

        calendar = [[NSCalendar autoupdatingCurrentCalendar] retain];
        date = [[NSDate date] retain];
        calCalendarsToDisplay = [[self _calCalendarsToDisplay] mutableCopy];
        calEventCalendarsToDisplay = [[self calEventCalendarsFromCalCalendars:[self _calCalendarsToDisplayEvents]] mutableCopy];
        calReminderCalendarsToDisplay = [[self calReminderCalendarsFromCalCalendars:[self _calCalendarsToDisplayReminders]] mutableCopy];
        calCalendars = [[self _filteredCalCalendars:nil] mutableCopy];
        calEventCalendars = [[self calEventCalendarsFromCalCalendars:calCalendars] mutableCopy];
        calReminderCalendars = [[self calReminderCalendarsFromCalCalendars:calCalendars] mutableCopy];

        [n addObserver:self
              selector:@selector(_localeDidChange:)
                  name:NSCurrentLocaleDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_systemClockDidChange:)
                  name:NSSystemClockDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_timeZoneDidChange:)
                  name:NSSystemTimeZoneDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_calCalendarsDidChange:)
                  name:CalCalendarsChangedNotification
                object:[CalCalendarStore defaultCalendarStore]];
        [n addObserver:self
              selector:@selector(_calCalendarsDidChange:)
                  name:CalCalendarsChangedExternallyNotification
                object:[CalCalendarStore defaultCalendarStore]];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(updateDate)
                                                                   name:NSWorkspaceDidWakeNotification
                                                                 object:nil];
        [userDefaults addObserver:self
                       forKeyPath:WLCalendarsKey
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        [userDefaults addObserver:self
                       forKeyPath:WLDisplayAllCalendarsKey
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        [self _scheduleNextDayTimer];
        [self _scheduleNextMinuteTimer];
    }
    return self;
}

- (void)dealloc
{
    [calendar release];
    [date release];
    [calCalendarsToDisplay release];
    [calEventCalendarsToDisplay release];
    [calReminderCalendarsToDisplay release];
    [calCalendars release];
    [calEventCalendars release];
    [calReminderCalendars release];
    [_nextMinuteTimer invalidate];
    [_nextDayTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:WLCalendarsKey];
    [userDefaults removeObserver:self forKeyPath:WLDisplayAllCalendarsKey];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCalendar) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDate) object:nil];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendar;
@synthesize date;
@synthesize calCalendarsToDisplay;
@synthesize calEventCalendarsToDisplay;
@synthesize calReminderCalendarsToDisplay;
@synthesize calCalendars;
@synthesize calEventCalendars;
@synthesize calReminderCalendars;

+ (BOOL)automaticallyNotifiesObserversOfCalCalendarsToDisplay
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfCalEventCalendarsToDisplay
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfCalReminderCalendarsToDisplay
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfCalCalendars
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfCalEventCalendars
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfCalReminderCalendars
{
    return NO;
}


#pragma mark Methods

- (void)updateCalendar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCalendar) object:nil];
    self.calendar = [NSCalendar autoupdatingCurrentCalendar];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (void)updateDate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDate) object:nil];
    self.date = [NSDate date];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    return [aCalCalendars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CalCalendar *c, NSDictionary *b)
    {
        WLCalEntityMask types = [_calStore calendarWithIdentifier:c.uid].allowedEntityTypes;
        return types == WLCalEntityMaskUnknown || (types & WLCalEntityMaskEvent) != 0;
    }]];
}

- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    return [aCalCalendars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CalCalendar *c, NSDictionary *b) {
        WLCalEntityMask types = [_calStore calendarWithIdentifier:c.uid].allowedEntityTypes;
        return types == WLCalEntityMaskUnknown || (types & WLCalEntityMaskReminder) != 0;
    }]];
}

- (void)setIsUsedForEvents:(BOOL)newIsUsed forCalendarWithUID:(NSString *)anUID
{
    [[NSUserDefaults standardUserDefaults] WL_updateCalendars:^(NSMutableArray *aCalendars) {
        NSUInteger index = [aCalendars WL_indexOfCalendarWithUID:anUID];
        if (index != NSNotFound)
        {
            NSMutableDictionary *calendarDict = [[aCalendars objectAtIndex:index] mutableCopy];
            [calendarDict setObject:[NSNumber numberWithBool:newIsUsed] forKey:WLCalendarIsUsedForEventsKey];
            [aCalendars replaceObjectAtIndex:index withObject:calendarDict];
            [calendarDict release];
        }
    }];
}

- (BOOL)isCalendarWithUIDUsedForEvents:(NSString *)anUID
{
    return [[[[[NSUserDefaults standardUserDefaults] WL_calendars] WL_calendarWithUID:anUID] objectForKey:WLCalendarIsUsedForEventsKey] boolValue];
}

- (void)setIsUsedForReminders:(BOOL)newIsUsed forCalendarWithUID:(NSString *)anUID
{
    [[NSUserDefaults standardUserDefaults] WL_updateCalendars:^(NSMutableArray *aCalendars) {
        NSUInteger index = [aCalendars WL_indexOfCalendarWithUID:anUID];
        if (index != NSNotFound)
        {
            NSMutableDictionary *calendarDict = [[aCalendars objectAtIndex:index] mutableCopy];
            [calendarDict setObject:[NSNumber numberWithBool:newIsUsed] forKey:WLCalendarIsUsedForRemindersKey];
            [aCalendars replaceObjectAtIndex:index withObject:calendarDict];
            [calendarDict release];
        }
    }];
}

- (BOOL)isCalendarWithUIDUsedForReminders:(NSString *)anUID
{
    return [[[[[NSUserDefaults standardUserDefaults] WL_calendars] WL_calendarWithUID:anUID] objectForKey:WLCalendarIsUsedForRemindersKey] boolValue];
}


#pragma mark Private

- (void)_localeDidChange:(NSNotification *)aNotification
{
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0;
    [self performSelector:@selector(updateCalendar) withObject:nil afterDelay:AnyDelay];
}

- (void)_scheduleNextMinuteTimer
{
    [_nextMinuteTimer invalidate];
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [self.calendar rangeOfUnit:NSMinuteCalendarUnit startDate:&startDate interval:&interval forDate:self.date];
    if (IKGetProvidingPowerSourceType() != IKACPowerType)
    {
        NSRange secondsRange = [self.calendar maximumRangeOfUnit:NSSecondCalendarUnit];
        static const NSTimeInterval BatteryModifier = 5;
        interval = BatteryModifier * secondsRange.length;
    }
    _nextMinuteTimer = [[NSTimer alloc] initWithFireDate:[startDate dateByAddingTimeInterval:interval]
                                                interval:0.0
                                                  target:self
                                                selector:@selector(_nextMinuteTimerDidFire)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextMinuteTimer forMode:NSDefaultRunLoopMode];
    [_nextMinuteTimer release];
}

- (void)_scheduleNextDayTimer
{
    [_nextDayTimer invalidate];
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [self.calendar rangeOfUnit:NSDayCalendarUnit startDate:&startDate interval:&interval forDate:self.date];
    _nextDayTimer = [[NSTimer alloc] initWithFireDate:[startDate dateByAddingTimeInterval:interval]
                                             interval:0.0
                                               target:self
                                             selector:@selector(_nextDayTimerDidFire)
                                             userInfo:nil
                                              repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
    [_nextDayTimer release];
}

- (void)_nextDayTimerDidFire
{
    _nextDayTimer = nil;
    [self updateDate];
}

- (void)_nextMinuteTimerDidFire
{
    _nextMinuteTimer = nil;
    [self updateDate];
}

- (void)_systemClockDidChange:(NSNotification *)aNotification
{
    // http://groups.google.com/group/cocoa-unbound/browse_thread/thread/46fe3433cfef6a97#
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        static const NSTimeInterval AnyDelay = 0.5;
        [self performSelector:@selector(updateDate) withObject:nil afterDelay:AnyDelay];
    }
    else
        [self updateDate];
}

- (void)_timeZoneDidChange:(NSNotification *)aNotification
{
    [self updateCalendar];
}

- (void)_calCalendarsDidChange:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] WL_updateCalendars:^(NSMutableArray *aCalendars) {
        NSArray *deletedCalCalendarUIDs = [[aNotification userInfo] objectForKey:CalDeletedRecordsKey];
        for (NSString *uid in deletedCalCalendarUIDs)
            [aCalendars WL_removeCalendarWithUID:uid];
        NSArray *insertedCalCalendarUIDs = [[aNotification userInfo] objectForKey:CalInsertedRecordsKey];
        for (NSString *uid in insertedCalCalendarUIDs)
        {
            CalCalendar *c = [[CalCalendarStore defaultCalendarStore] calendarWithUID:uid];
            if (c != nil)
            {
                NSDictionary *calendarDict = [NSDictionary WL_makeCalendarWithCalCalendar:c];
                [aCalendars WL_insertCalendar:calendarDict];
            }
        }
    }];
}

- (NSArray *)_calCalendarsToDisplayEvents
{
    if ([[NSUserDefaults standardUserDefaults] WL_displaysAllCalendars])
        return [self _filteredCalCalendars:nil];
    else
    {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == YES", WLCalendarIsUsedForEventsKey];
        return [self _filteredCalCalendars:p];
    }
}

- (NSArray *)_calCalendarsToDisplayReminders
{
    if ([[NSUserDefaults standardUserDefaults] WL_displaysAllCalendars])
        return [self _filteredCalCalendars:nil];
    else
    {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == YES", WLCalendarIsUsedForRemindersKey];
        return [self _filteredCalCalendars:p];
    }
}

- (NSArray *)_calCalendarsToDisplay
{
    if ([[NSUserDefaults standardUserDefaults] WL_displaysAllCalendars])
        return [self _filteredCalCalendars:nil];
    else
    {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"(%K == YES) || (%K == YES)", WLCalendarIsUsedForEventsKey, WLCalendarIsUsedForRemindersKey];
        return [self _filteredCalCalendars:p];
    }
}

- (NSArray *)_filteredCalCalendars:(NSPredicate *)aPredicate
{
    NSArray *calendars = [[NSUserDefaults standardUserDefaults] WL_calendars];
    NSMutableArray *filteredCalCalendars = [NSMutableArray arrayWithCapacity:[calendars count]];
    for (NSDictionary *calendarDict in calendars)
    {
        if (aPredicate != nil &&
            ![aPredicate evaluateWithObject:calendarDict])
        {
            continue;
        }

        NSString *uid = [calendarDict objectForKey:WLCalendarUIDKey];
        if ([uid length] > 0)
        {
            CalCalendar *c = [[CalCalendarStore defaultCalendarStore] calendarWithUID:uid];
            if (c != nil)
                [filteredCalCalendars addObject:c];
        }
        else
        {
            NSLog(@"UID of a calendar of the Calendars setting is invalid. It MUST be set to non-empty string.\
                  If you don't know how to modify app's settings plist, please contact us.");
        }
    }
    return filteredCalCalendars;
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if ([aKeyPath isEqualToString:WLDisplayAllCalendarsKey] || [aKeyPath isEqualToString:WLCalendarsKey])
    {
        static void (^UpdateCalendars)(WLCalendarController *aSelf, NSMutableArray *aProperty, NSString *aPropertyName, NSArray *aNewCalendars) = ^(WLCalendarController *aSelf, NSMutableArray *aProperty, NSString *aPropertyName, NSArray *aNewCalendars)
        {
            NSIndexSet *inserted = nil;
            NSIndexSet *deleted = nil;
            NSIndexSet *updated = nil;
            NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES]];

            [aProperty WL_indexesOfDeletedObject:&deleted
                        indexesOfInsertedObjects:&inserted
                         indexesOfUpdatedObjects:&updated
                                   toSortedArray:aNewCalendars
                                 sortDescriptors:sortDescriptors
                                   updateChecker:^BOOL(CalCalendar *aFromArrayObject, CalCalendar *aToArrayObject)
                                                 {
                                                     return (![aFromArrayObject.color isEqual:aToArrayObject.color] ||
                                                             ![aFromArrayObject.title isEqual:aToArrayObject.title]);
                                                 }];

            if ([deleted count] > 0)
            {
                [aSelf willChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:aPropertyName];
                [aProperty removeObjectsAtIndexes:deleted];
                [aSelf didChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:aPropertyName];
            }

            if ([inserted count] > 0)
            {
                [aSelf willChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:aPropertyName];
                [aProperty insertObjects:[aNewCalendars objectsAtIndexes:inserted] atIndexes:inserted];
                [aSelf didChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:aPropertyName];
            }

            if ([updated count] > 0)
            {
                [aSelf willChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:aPropertyName];
                [aProperty replaceObjectsAtIndexes:updated withObjects:[aNewCalendars objectsAtIndexes:updated]];
                [aSelf didChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:aPropertyName];
            }
        };

        NSArray *newCalCalendarsToDisplay = [self _calCalendarsToDisplay];
        UpdateCalendars(self, calCalendarsToDisplay, @"calCalendarsToDisplay", newCalCalendarsToDisplay);

        NSArray *newCalEventCalendarsToDisplay = [self calEventCalendarsFromCalCalendars:[self _calCalendarsToDisplayEvents]];
        UpdateCalendars(self, calEventCalendarsToDisplay, @"calEventCalendarsToDisplay", newCalEventCalendarsToDisplay);

        NSArray *newCalReminderCalendarsToDisplay = [self calReminderCalendarsFromCalCalendars:[self _calCalendarsToDisplayReminders]];
        UpdateCalendars(self, calReminderCalendarsToDisplay, @"calReminderCalendarsToDisplay", newCalReminderCalendarsToDisplay);

        NSArray *newCalCalendars = [self _filteredCalCalendars:nil];
        UpdateCalendars(self, calCalendars, @"calCalendars", newCalCalendars);

        NSArray *newCalEventCalendars = [self calEventCalendarsFromCalCalendars:newCalCalendars];
        UpdateCalendars(self, calEventCalendars, @"calEventCalendars", newCalEventCalendars);

        NSArray *newCalReminderCalendars = [self calReminderCalendarsFromCalCalendars:newCalCalendars];
        UpdateCalendars(self, calReminderCalendars, @"calReminderCalendars", newCalReminderCalendars);
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

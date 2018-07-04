//
//  WLCalendarsController.m
//  Blotter
//
//  Created by Ilya Kulakov on 06.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalendarsController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


NSString *WLCalCalendarsDidChangeNotification = @"WLCalCalendarsDidChangeNotification";

NSString *WLCalCalendarsToDisplayDidChangeNotification = @"WLCalCalendarsToDisplayDidChangeNotification";


NSString *WLChangedCalStoresKey = @"WLChangedCalStoresKey";


/*!
    WLCalendarsController is thread safe. To achieve this multiple queues and semaphores are used. This is the quick introdution into threading implementation.


    Once instance of the WLCalendarsController is initialized, it has:

    - serial operation queue per store
        Each store has its own queue to fetch updates because all stores are independent and therefore can be efficiently used concurrently.
        Each queue is serial because we want to ensure clients of WLCalendarsController's instance will only receive most recent updates.
        It also allows to cancel "old" fetch requests which in turn improves performance as well.

    - semaphore to protect accesses to queues
        Semaphore is used to avoid race conditions when a single store is changed from a multiple threads. Without a barrier "newer" and "older" threads may
        cancel and add operations simultaneously which would lead to 2 operations in queue instead of 1.

    - semaphore to protect accesses to calendars
        Semaphore is used to protect mutable data to be modified from the multiple threads simultaneously.

    - serial queue for user defaults
        Accesses to user defaults are serialized to avoid race conditions when new calendars are added or removed in multiple stores.
        NSUserDefaults is the "flat" dictionary and only allows to set top-level keys.

    Notifications are delivered via global queue because user info does not contain any data except calendar store which only points
    to the store that is changed.


    Once instance of WLCalendarsController is received last release it:

    - unsubscribes from all notifications
    - cancels all ongoing operations
    - waits until all queues are finished.
 */
@implementation WLCalendarsController
{
    NSMapTable *_calCalendarsPerStore;
    dispatch_semaphore_t _calCalendarsPerStoreSemaphore;
    NSMapTable *_fetchQueuesPerStore;
    dispatch_semaphore_t _fetchQueuesPerStoreSemaphore;
    dispatch_queue_t _accessUserDefaultsQueue;
}

- (instancetype)initWithCalStores:(NSArray *)aStores autosaveKeyPath:(NSString *)anAutosaveKeyPath
{
    NSParameterAssert([anAutosaveKeyPath length] > 0);

    self = [super init];

    if (self)
    {
        _calStores = [aStores copy];
        _autosaveKeyPath = [anAutosaveKeyPath copy];

        _calCalendarsPerStore = [NSMapTable strongToStrongObjectsMapTable];
        _fetchQueuesPerStore = [NSMapTable strongToStrongObjectsMapTable];

        for (NSObject<WLCalStore> *s in aStores)
        {
            [_calCalendarsPerStore setObject:@[] forKey:s];

            NSOperationQueue *q = [[NSOperationQueue alloc] init];
            q.name = [NSString stringWithFormat:@"Fetch Calendars From %@ Queue (Calendars)", s.storeIdentifier];
            q.maxConcurrentOperationCount = 1;
            [_fetchQueuesPerStore setObject:q forKey:s];
        }

        _calCalendarsPerStoreSemaphore = dispatch_semaphore_create(1);
        _fetchQueuesPerStoreSemaphore = dispatch_semaphore_create(1);
        _accessUserDefaultsQueue = dispatch_queue_create("Access NSUserDefaults Queue (Calendars)", 0);

        for (NSObject<WLCalStore> *s in aStores)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(calStoreDidChange:)
                                                         name:WLCalStoreDidChangeNotification
                                                       object:s];
            [self fetchCalCalendarsForStore:s withPriority:NSOperationQueuePriorityNormal];
        }

        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:WLDisplayAllCalendarsKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }

    return self;
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:WLDisplayAllCalendarsKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    for (NSObject<WLCalStore> *s in self.calStores)
    {
        NSOperationQueue *q = [_fetchQueuesPerStore objectForKey:s];
        [q cancelAllOperations];
        [q waitUntilAllOperationsAreFinished];
    }
}


#pragma mark Methods

- (NSArray *)calCalendarsForStore:(NSObject <WLCalStore> *)aStore
{
    NSArray *calCalendars = nil;
    dispatch_semaphore_wait(_calCalendarsPerStoreSemaphore, DISPATCH_TIME_FOREVER);
    calCalendars = [_calCalendarsPerStore objectForKey:aStore];
    dispatch_semaphore_signal(_calCalendarsPerStoreSemaphore);
    return calCalendars;
}

- (NSArray *)calReminderCalendarsForStore:(NSObject<WLCalStore> *)aStore
{
    return [self calReminderCalendarsFromCalCalendars:[self calCalendarsForStore:aStore]];
}

- (NSArray *)calEventCalendarsForStore:(NSObject <WLCalStore> *)aStore
{
    return [self calEventCalendarsFromCalCalendars:[self calCalendarsForStore:aStore]];
}

- (NSArray *)calCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore
{
    return [self calCalendarsToDisplayFromCalCalendars:[self calCalendarsForStore:aStore]];
}

- (NSArray *)calReminderCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore
{
    return [self calReminderCalendarsToDisplayFromCalCalendars:[self calReminderCalendarsForStore:aStore]];
}

- (NSArray *)calEventCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore
{
    return [self calEventCalendarsToDisplayFromCalCalendars:[self calEventCalendarsForStore:aStore]];
}

- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    if (!aCalCalendars.count)
        return @[];

    NSIndexSet *indexesOfCalReminderCalendars = [aCalCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                               passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        return aCalCalendar.allowedEntityTypes == WLCalEntityMaskUnknown || (aCalCalendar.allowedEntityTypes & WLCalEntityMaskReminder) != 0;
    }];
    return [aCalCalendars objectsAtIndexes:indexesOfCalReminderCalendars];
}

- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    if (!aCalCalendars.count)
        return @[];

    NSIndexSet *indexesOfCalReminderCalendars = [aCalCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                               passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        return aCalCalendar.allowedEntityTypes == WLCalEntityMaskUnknown || (aCalCalendar.allowedEntityTypes & WLCalEntityMaskEvent) != 0;
    }];
    return [aCalCalendars objectsAtIndexes:indexesOfCalReminderCalendars];
}

- (NSArray *)calCalendarsToDisplayFromCalCalendars:(NSArray *)aCalCalendars
{
    if (!aCalCalendars.count)
        return @[];

    if ([[NSUserDefaults standardUserDefaults] WL_displaysAllCalendars])
        return aCalCalendars;
    else
    {
        NSDictionary *defaultsCalendars = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath];
        NSIndexSet *indexesOfCalCalendarsToDisplay = [aCalCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                                    passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
        {
            NSDictionary *value = defaultsCalendars[aCalCalendar.store.storeIdentifier][aCalCalendar.calendarIdentifier];
            // value may be nil in case that calendar is already added, but not written to the user defaults yet.
            return [value[WLCalendarIsEnabledKey] boolValue] && ([value[WLCalendarIsUsedForEventsKey] boolValue] || [value[WLCalendarIsUsedForRemindersKey] boolValue]);
        }];
        return [aCalCalendars objectsAtIndexes:indexesOfCalCalendarsToDisplay];
    }
}

- (NSArray *)calReminderCalendarsToDisplayFromCalCalendars:(NSArray *)aCalCalendars
{
    if (!aCalCalendars.count)
        return @[];

    if ([[NSUserDefaults standardUserDefaults] WL_displaysAllCalendars])
        return aCalCalendars;
    else
    {
        NSDictionary *defaultsCalendars = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath];
        NSIndexSet *indexesOfCalReminderCalendarsToDisplay = [aCalCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                                            passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
        {
            NSDictionary *value = defaultsCalendars[aCalCalendar.store.storeIdentifier][aCalCalendar.calendarIdentifier];
            // value may be nil in case that calendar is already added, but not written to the user defaults yet.
            return [value[WLCalendarIsEnabledKey] boolValue] && [value[WLCalendarIsUsedForRemindersKey] boolValue];
        }];
        return [aCalCalendars objectsAtIndexes:indexesOfCalReminderCalendarsToDisplay];
    }
}

- (NSArray *)calEventCalendarsToDisplayFromCalCalendars:(NSArray *)aCalCalendars
{
    if (!aCalCalendars.count)
        return @[];

    if ([[NSUserDefaults standardUserDefaults] WL_displaysAllCalendars])
        return aCalCalendars;
    else
    {
        NSDictionary *defaultsCalendars = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath];
        NSIndexSet *indexesOfCalEventCalendarsToDisplay = [aCalCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                                        passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
        {
            NSDictionary *value = defaultsCalendars[aCalCalendar.store.storeIdentifier][aCalCalendar.calendarIdentifier];
            // value may be nil in case that calendar is already added, but not written to the user defaults yet.
            return [value[WLCalendarIsEnabledKey] boolValue] && [value[WLCalendarIsUsedForEventsKey] boolValue];
        }];
        return [aCalCalendars objectsAtIndexes:indexesOfCalEventCalendarsToDisplay];
    }
}

- (void)fetchCalCalendarsForStore:(NSObject <WLCalStore> *)aStore withPriority:(NSOperationQueuePriority)aPriority
{
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *unretainedOperation = operation;
    __unsafe_unretained WLCalendarsController *unretainedSelf = self;
    operation.queuePriority = aPriority;

    [operation addExecutionBlock:^
    {
        NSArray *calendars = [aStore calendars];

        if (unretainedOperation.cancelled)
            return;

        dispatch_sync(dispatch_get_main_queue(), ^
        {
            [unretainedSelf willChangeValueForKey:@"calCalendars"];
            [unretainedSelf willChangeValueForKey:@"calReminderCalendars"];
            [unretainedSelf willChangeValueForKey:@"calEventCalendars"];
        });

        dispatch_semaphore_wait(unretainedSelf->_calCalendarsPerStoreSemaphore, DISPATCH_TIME_FOREVER);
        [unretainedSelf->_calCalendarsPerStore setObject:calendars forKey:aStore];
        dispatch_semaphore_signal(unretainedSelf->_calCalendarsPerStoreSemaphore);

        dispatch_sync(dispatch_get_main_queue(), ^
        {
            [unretainedSelf didChangeValueForKey:@"calEventCalendars"];
            [unretainedSelf didChangeValueForKey:@"calReminderCalendars"];
            [unretainedSelf didChangeValueForKey:@"calCalendars"];
        });

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsDidChangeNotification
                                                                object:unretainedSelf
                                                              userInfo:@{WLChangedCalStoresKey : @[aStore]}];
        });

        // Since there can be more than one store simultaneously updating calendars in user defaults,
        // we should take additional care to ensure that all changes will be saved.
        dispatch_async(unretainedSelf->_accessUserDefaultsQueue, ^
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableDictionary *defaultsCalendars = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:unretainedSelf.autosaveKeyPath]];
            NSDictionary *oldDefaultsStore = defaultsCalendars[aStore.storeIdentifier];
            NSMutableDictionary *newDefaultsStore = [NSMutableDictionary dictionaryWithCapacity:calendars.count];

            // Preserve old calendars but disable them. They may reappear shortly after due to syncing problems.
            for (NSString *calendarIdentifier in oldDefaultsStore)
            {
                NSMutableDictionary *defaultsCalCalendar = [oldDefaultsStore[calendarIdentifier] mutableCopy];
                defaultsCalCalendar[WLCalendarIsEnabledKey] = @(NO);
                newDefaultsStore[calendarIdentifier] = defaultsCalCalendar;
            }

            // Preserve settings when adding new calendars. Re-enable them if needed.
            for (NSObject<WLCalCalendar> *c in calendars)
            {
                NSMutableDictionary *defaultsCalCalendar = [oldDefaultsStore[c.calendarIdentifier] mutableCopy];

                if (!defaultsCalCalendar)
                    defaultsCalCalendar = [@{WLCalendarIsUsedForRemindersKey:@(YES), WLCalendarIsUsedForEventsKey:@(YES)} mutableCopy];

                defaultsCalCalendar[WLCalendarIsEnabledKey] = @(YES);
                newDefaultsStore[c.calendarIdentifier] = defaultsCalCalendar;
            }

            defaultsCalendars[aStore.storeIdentifier] = newDefaultsStore;

            dispatch_sync(dispatch_get_main_queue(), ^
            {
                [unretainedSelf willChangeValueForKey:@"calCalendarsToDisplay"];
                [unretainedSelf willChangeValueForKey:@"calReminderCalendarsToDisplay"];
                [unretainedSelf willChangeValueForKey:@"calEventCalendarsToDisplay"];
            });

            [defaults setObject:defaultsCalendars forKey:unretainedSelf.autosaveKeyPath];

            dispatch_sync(dispatch_get_main_queue(), ^
            {
                [unretainedSelf didChangeValueForKey:@"calEventCalendarsToDisplay"];
                [unretainedSelf didChangeValueForKey:@"calReminderCalendarsToDisplay"];
                [unretainedSelf didChangeValueForKey:@"calCalendarsToDisplay"];
            });

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                                    object:unretainedSelf
                                                                  userInfo:@{WLChangedCalStoresKey : @[aStore]}];
            });
        });
    }];

    // Ensure there is no race between cancelling operations and adding new.
    dispatch_semaphore_wait(_fetchQueuesPerStoreSemaphore, DISPATCH_TIME_FOREVER);
    NSOperationQueue *q = [_fetchQueuesPerStore objectForKey:aStore];
    [q cancelAllOperations];
    [q addOperation:operation];
    dispatch_semaphore_signal(_fetchQueuesPerStoreSemaphore);
}

- (void)calStoreDidChange:(NSNotification *)aNotification
{
    [self fetchCalCalendarsForStore:aNotification.object withPriority:NSOperationQueuePriorityLow];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:WLDisplayAllCalendarsKey])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                            object:self
                                                          userInfo:@{WLChangedCalStoresKey : self.calStores}];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation WLCalendarsController (DisplayingPreferences)

- (BOOL)isCalCalendarUsedToDisplayReminders:(NSObject <WLCalCalendar> *)aCalendar
{
    return [self isCalCalendarWithIdentifierUsedToDisplayReminders:aCalendar.calendarIdentifier
                                                           ofStore:aCalendar.store];
}

- (void)setCalCalendar:(NSObject<WLCalCalendar> *)aCalendar usedToDisplayReminders:(BOOL)isUsed
{
    [self setCalCalendarWithIdentifier:aCalendar.calendarIdentifier
                               ofStore:aCalendar.store
                usedToDisplayReminders:isUsed];
}

- (BOOL)isCalCalendarUsedToDisplayEvents:(NSObject <WLCalCalendar> *)aCalendar
{
    return [self isCalCalendarWithIdentifierUsedToDisplayEvents:aCalendar.calendarIdentifier
                                                        ofStore:aCalendar.store];
}

- (void)setCalCalendar:(NSObject <WLCalCalendar> *)aCalendar usedToDisplayEvents:(BOOL)isUsed
{
    [self setCalCalendarWithIdentifier:aCalendar.calendarIdentifier
                               ofStore:aCalendar.store
                   usedToDisplayEvents:isUsed];
}

- (BOOL)isCalCalendarWithIdentifierUsedToDisplayReminders:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore
{
    if (![self.calStores containsObject:aStore])
        return NO;

    NSDictionary *defaultsCalendars = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath];
    NSDictionary *defaultsStore = defaultsCalendars[aStore.storeIdentifier];
    NSDictionary *defaultsCalCalendar = defaultsStore[anIdentifier];
    return [defaultsCalCalendar[WLCalendarIsUsedForRemindersKey] boolValue];
}

- (void)setCalCalendarWithIdentifier:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayReminders:(BOOL)isUsed
{
    if (![self.calStores containsObject:aStore])
        return;

    dispatch_sync(_accessUserDefaultsQueue, ^
    {
        NSMutableDictionary *defaultsCalendars = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath] mutableCopy];
        NSMutableDictionary *defaultsStore = [defaultsCalendars[aStore.storeIdentifier] mutableCopy];
        NSMutableDictionary *defaultsCalCalendar = [defaultsStore[anIdentifier] mutableCopy];

        if (!defaultsCalCalendar)
            return;

        defaultsCalCalendar[WLCalendarIsUsedForRemindersKey] = @(isUsed);
        defaultsStore[anIdentifier] = defaultsCalCalendar;
        defaultsCalendars[aStore.storeIdentifier] = defaultsStore;

        [self willChangeValueForKey:@"calCalendarsToDisplay"];
        [self willChangeValueForKey:@"calReminderCalendarsToDisplay"];
        [self willChangeValueForKey:@"calEventCalendarsToDisplay"];

        [[NSUserDefaults standardUserDefaults] setObject:defaultsCalendars forKey:self.autosaveKeyPath];

        [self didChangeValueForKey:@"calEventCalendarsToDisplay"];
        [self didChangeValueForKey:@"calReminderCalendarsToDisplay"];
        [self didChangeValueForKey:@"calCalendarsToDisplay"];
    });

    [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                        object:self
                                                      userInfo:@{WLChangedCalStoresKey : @[aStore]}];
}

- (BOOL)isCalCalendarWithIdentifierUsedToDisplayEvents:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore
{
    if (![self.calStores containsObject:aStore])
        return NO;

    NSDictionary *defaultsCalendars = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath];
    NSDictionary *defaultsStore = defaultsCalendars[aStore.storeIdentifier];
    NSDictionary *defaultsCalCalendar = defaultsStore[anIdentifier];
    return [defaultsCalCalendar[WLCalendarIsUsedForEventsKey] boolValue];
}

- (void)setCalCalendarWithIdentifier:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayEvents:(BOOL)isUsed
{
    if (![self.calStores containsObject:aStore])
        return;

    dispatch_sync(_accessUserDefaultsQueue, ^
    {
        NSMutableDictionary *defaultsCalendars = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath] mutableCopy];
        NSMutableDictionary *defaultsStore = [defaultsCalendars[aStore.storeIdentifier] mutableCopy];
        NSMutableDictionary *defaultsCalCalendar = [defaultsStore[anIdentifier] mutableCopy];

        if (!defaultsCalCalendar)
            return;

        defaultsCalCalendar[WLCalendarIsUsedForEventsKey] = @(isUsed);
        defaultsStore[anIdentifier] = defaultsCalCalendar;
        defaultsCalendars[aStore.storeIdentifier] = defaultsStore;

        [self willChangeValueForKey:@"calCalendarsToDisplay"];
        [self willChangeValueForKey:@"calReminderCalendarsToDisplay"];
        [self willChangeValueForKey:@"calEventCalendarsToDisplay"];

        [[NSUserDefaults standardUserDefaults] setObject:defaultsCalendars forKey:self.autosaveKeyPath];

        [self didChangeValueForKey:@"calEventCalendarsToDisplay"];
        [self didChangeValueForKey:@"calReminderCalendarsToDisplay"];
        [self didChangeValueForKey:@"calCalendarsToDisplay"];
    });

    [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                        object:self
                                                      userInfo:@{WLChangedCalStoresKey : @[aStore]}];
}

@end


@implementation WLCalendarsController (CalendarsAccessors)

+ (NSSet *)keyPathsForValuesAffectingCalCalendarsToDisplay
{
    return [NSSet setWithObject:@"calCalendars"];
}

+ (NSSet *)keyPathsForValuesAffectingCalReminderCalendarsToDisplay
{
    return [NSSet setWithObject:@"calReminderCalendars"];
}

+ (NSSet *)keyPathsForValuesAffectingCalEventCalendarsToDisplay
{
    return [NSSet setWithObject:@"calEventCalendars"];
}

- (NSArray *)calCalendars
{
    NSMutableArray *calCalendars = [NSMutableArray array];

    for (NSObject <WLCalStore> *store in self.calStores)
    {
        [calCalendars addObjectsFromArray:[self calCalendarsForStore:store]];
    }

    [calCalendars sortWithOptions:NSSortConcurrent | NSSortStable
                  usingComparator:^NSComparisonResult(NSObject <WLCalCalendar> *aCalendar1, NSObject <WLCalCalendar> *aCalendar2)
    {
        NSComparisonResult r = [aCalendar1.title compare:aCalendar2.title];

        if (r == NSOrderedSame)
            r = [aCalendar1.calendarIdentifier compare:aCalendar2.calendarIdentifier];

        return r;
    }];
    return calCalendars;
}

- (NSArray *)calReminderCalendars
{
    return [self calReminderCalendarsFromCalCalendars:self.calCalendars];
}

- (NSArray *)calEventCalendars
{
    return [self calEventCalendarsFromCalCalendars:self.calCalendars];
}

- (NSArray *)calCalendarsToDisplay
{
    return [self calCalendarsToDisplayFromCalCalendars:self.calCalendars];
}

- (NSArray *)calReminderCalendarsToDisplay
{
    return [self calReminderCalendarsToDisplayFromCalCalendars:self.calReminderCalendars];
}

- (NSArray *)calEventCalendarsToDisplay
{
    return [self calEventCalendarsToDisplayFromCalCalendars:self.calEventCalendars];
}

@end

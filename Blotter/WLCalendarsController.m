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

        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
        {
            _calCalendarsPerStore = [NSMapTable mapTableWithStrongToStrongObjects];
            _fetchQueuesPerStore = [NSMapTable mapTableWithStrongToStrongObjects];
        }
        else
        {
            _calCalendarsPerStore = [NSMapTable strongToStrongObjectsMapTable];
            _fetchQueuesPerStore = [NSMapTable strongToStrongObjectsMapTable];
        }

        for (NSObject<WLCalStore> *s in aStores)
        {
            [_calCalendarsPerStore setObject:@[] forKey:s];

            NSOperationQueue *q = [[NSOperationQueue alloc] init];
            [q setName:[NSString stringWithFormat:@"Fetch Calendars From %@ Queue (Calendars)", s.storeIdentifier]];
            [q setMaxConcurrentOperationCount:1];
            [_fetchQueuesPerStore setObject:q forKey:s];
        }

        _calCalendarsPerStoreSemaphore = dispatch_semaphore_create(1);
        _fetchQueuesPerStoreSemaphore = dispatch_semaphore_create(1);
        _accessUserDefaultsQueue = dispatch_queue_create("Access NSUserDefaults Queue (Calendars)", 0);
        _defaultFetchPriority = NSOperationQueuePriorityLow;

        for (NSObject<WLCalStore> *s in aStores)
        {
            [self fetchCalCalendarsForStore:s withPriority:_defaultFetchPriority];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(calStoreDidChange:)
                                                         name:WLCalStoreDidChangeNotification
                                                       object:s];
        }
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[_fetchQueuesPerStore dictionaryRepresentation] allValues] makeObjectsPerformSelector:@selector(cancelAllOperations)];
    dispatch_release(_calCalendarsPerStoreSemaphore);
    dispatch_release(_fetchQueuesPerStoreSemaphore);
    dispatch_release(_accessUserDefaultsQueue);
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
    NSArray *calCalendars = [self calCalendarsForStore:aStore];
    NSIndexSet *indexesOfCalRemindersCalendars = [calCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                               passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        return aCalCalendar.allowedEntityTypes == WLCalEntityMaskUnknown || (aCalCalendar.allowedEntityTypes & WLCalEntityMaskReminder) != 0;
    }];
    return [calCalendars objectsAtIndexes:indexesOfCalRemindersCalendars];
}

- (NSArray *)calEventCalendarsForStore:(NSObject <WLCalStore> *)aStore
{
    NSArray *calCalendars = [self calCalendarsForStore:aStore];
    NSIndexSet *indexesOfCalRemindersCalendars = [calCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                               passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        return aCalCalendar.allowedEntityTypes == WLCalEntityMaskUnknown || (aCalCalendar.allowedEntityTypes & WLCalEntityMaskEvent) != 0;
    }];
    return [calCalendars objectsAtIndexes:indexesOfCalRemindersCalendars];
}

- (NSArray *)calCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore
{
    NSString *keyPath = [NSString stringWithFormat:@"%@.%@", self.autosaveKeyPath, aStore.storeIdentifier];
    NSDictionary *defaultsCalCalendars = [[NSUserDefaults standardUserDefaults] valueForKeyPath:keyPath];
    NSArray *calCalendars = [self calCalendarsForStore:aStore];
    NSIndexSet *indexesOfCalCalendarsToDisplay = [calCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                               passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *value = defaultsCalCalendars[aCalCalendar.calendarIdentifier];
        return [value[WLCalendarIsUsedForEventsKey] boolValue] || [value[WLCalendarIsUsedForRemindersKey] boolValue];
    }];
    return [calCalendars objectsAtIndexes:indexesOfCalCalendarsToDisplay];
}

- (NSArray *)calReminderCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore
{
    NSString *keyPath = [NSString stringWithFormat:@"%@.%@", self.autosaveKeyPath, aStore.storeIdentifier];
    NSDictionary *defaultsCalCalendars = [[NSUserDefaults standardUserDefaults] valueForKeyPath:keyPath];
    NSArray *calCalendars = [self calReminderCalendarsForStore:aStore];
    NSIndexSet *indexesOfCalReminderCalendarsToDisplay = [calCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                                       passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *value = defaultsCalCalendars[aCalCalendar.calendarIdentifier];
        return [value[WLCalendarIsUsedForRemindersKey] boolValue];
    }];
    return [calCalendars objectsAtIndexes:indexesOfCalReminderCalendarsToDisplay];
}

- (NSArray *)calEventCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore
{
    NSString *keyPath = [NSString stringWithFormat:@"%@.%@", self.autosaveKeyPath, aStore.storeIdentifier];
    NSDictionary *defaultsCalCalendars = [[NSUserDefaults standardUserDefaults] valueForKeyPath:keyPath];
    NSArray *calCalendars = [self calEventCalendarsForStore:aStore];
    NSIndexSet *indexesOfCalEventsCalendarsToDisplay = [calCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                                     passingTest:^BOOL(NSObject<WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *value = defaultsCalCalendars[aCalCalendar.calendarIdentifier];
        return [value[WLCalendarIsUsedForEventsKey] boolValue];
    }];
    return [calCalendars objectsAtIndexes:indexesOfCalEventsCalendarsToDisplay];
}

- (BOOL)isUsedToDisplayRemindersCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore
{
    NSString *keyPath = [NSString stringWithFormat:@"%@.%@.%@.%@", self.autosaveKeyPath, aStore.storeIdentifier, anUID, WLCalendarIsUsedForRemindersKey];
    return [[[NSUserDefaults standardUserDefaults] valueForKeyPath:keyPath] boolValue];
}

- (void)setCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayReminders:(BOOL)isUsed
{
    dispatch_sync(_accessUserDefaultsQueue, ^
    {
        NSMutableDictionary *defaultsCalendars = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath] mutableCopy];
        NSMutableDictionary *defaultsStore = [defaultsCalendars[aStore.storeIdentifier] mutableCopy];
        NSMutableDictionary *defaultsCalCalendar = [defaultsStore[anUID] mutableCopy];

        if (!anUID)
            return;

        defaultsCalCalendar[WLCalendarIsUsedForRemindersKey] = @(isUsed);
        defaultsStore[anUID] = defaultsCalCalendar;
        defaultsCalendars[aStore.storeIdentifier] = defaultsStore;
        [[NSUserDefaults standardUserDefaults] setObject:defaultsCalendars forKey:self.autosaveKeyPath];
    });

    [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                        object:self
                                                      userInfo:@{WLChangedCalStoresKey : @[aStore]}];
}

- (BOOL)isUsedToDisplayEventsCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore
{
    NSString *keyPath = [NSString stringWithFormat:@"%@.%@.%@.%@", self.autosaveKeyPath, aStore.storeIdentifier, anUID, WLCalendarIsUsedForEventsKey];
    return [[[NSUserDefaults standardUserDefaults] valueForKeyPath:keyPath] boolValue];
}

- (void)setCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayEvents:(BOOL)isUsed
{
    dispatch_sync(_accessUserDefaultsQueue, ^
    {
        NSMutableDictionary *defaultsCalendars = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:self.autosaveKeyPath] mutableCopy];
        NSMutableDictionary *defaultsStore = [defaultsCalendars[aStore.storeIdentifier] mutableCopy];
        NSMutableDictionary *defaultsCalCalendar = [defaultsStore[anUID] mutableCopy];

        if (!anUID)
            return;

        defaultsCalCalendar[WLCalendarIsUsedForEventsKey] = @(isUsed);
        defaultsStore[anUID] = defaultsCalCalendar;
        defaultsCalendars[aStore.storeIdentifier] = defaultsStore;
        [[NSUserDefaults standardUserDefaults] setObject:defaultsCalendars forKey:self.autosaveKeyPath];
    });

    [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                        object:self
                                                      userInfo:@{WLChangedCalStoresKey : @[aStore]}];
}

- (void)fetchCalCalendarsForStore:(NSObject <WLCalStore> *)aStore withPriority:(NSOperationQueuePriority)aPriority
{
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *unretainedOperation = operation;
    __unsafe_unretained WLCalendarsController *unretainedSelf = self;
    [operation setQueuePriority:aPriority];
    dispatch_retain(_calCalendarsPerStoreSemaphore);

    [operation addExecutionBlock:^
    {
        NSArray *calendars = [aStore calendars];

        if ([unretainedOperation isCancelled])
            return;

        dispatch_semaphore_wait(_calCalendarsPerStoreSemaphore, DISPATCH_TIME_FOREVER);
        [_calCalendarsPerStore setObject:calendars forKey:aStore];
        dispatch_semaphore_signal(_calCalendarsPerStoreSemaphore);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsDidChangeNotification
                                                                object:unretainedSelf
                                                              userInfo:@{WLChangedCalStoresKey : @[aStore]}];
        });

        // Since can be more than one store simultaneously writing new calendars, we should take care that all changes will be saved.
        dispatch_async(_accessUserDefaultsQueue, ^
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableDictionary *defaultsCalendars = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:self.autosaveKeyPath]];
            NSDictionary *oldDefaultsStore = defaultsCalendars[aStore.storeIdentifier];
            NSMutableDictionary *newDefaultsStore = [NSMutableDictionary dictionaryWithCapacity:[calendars count]];

            for (NSObject<WLCalCalendar> *c in calendars)
            {
                NSDictionary *defaultsCalCalendar = oldDefaultsStore[c.calendarIdentifier];

                if (!defaultsCalCalendar)
                    defaultsCalCalendar = @{WLCalendarIsUsedForRemindersKey:@(YES), WLCalendarIsUsedForEventsKey:@(YES)};

                newDefaultsStore[c.calendarIdentifier] = defaultsCalCalendar;
            }

            defaultsCalendars[aStore.storeIdentifier] = newDefaultsStore;
            [defaults setObject:defaultsCalendars forKey:self.autosaveKeyPath];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:WLCalCalendarsToDisplayDidChangeNotification
                                                                    object:unretainedSelf
                                                                  userInfo:@{WLChangedCalStoresKey : @[aStore]}];
            });
        });
    }];

    [operation setCompletionBlock:^
    {
        dispatch_release(_calCalendarsPerStoreSemaphore);
    }];

    dispatch_semaphore_wait(_fetchQueuesPerStoreSemaphore, DISPATCH_TIME_FOREVER);
    NSOperationQueue *q = [_fetchQueuesPerStore objectForKey:aStore];
    [q cancelAllOperations];
    [q addOperation:operation];
    dispatch_semaphore_signal(_fetchQueuesPerStoreSemaphore);
}

- (void)calStoreDidChange:(NSNotification *)aNotification
{
    [self fetchCalCalendarsForStore:[aNotification object] withPriority:self.defaultFetchPriority];
}

@end

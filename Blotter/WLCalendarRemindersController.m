//
//  WLCalendarRemindersController.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalendarRemindersController.h"


NSString *WLCalendarRemindersDidChangeNotification = @"WLCalendarRemindersDidChangeNotification";


@implementation WLCalendarRemindersController
{
    NSCountedSet *_observedCompletionMasks;
    NSMapTable *_observedCalendarIdentifiers;
    NSOperationQueue *_fetchOperationsQueue;
    BOOL _isObserving;
    dispatch_semaphore_t _fetchPredicateSemaphore;
    dispatch_queue_t _notificationsDeliveryQueue;
}

- (instancetype)initWithCalStores:(NSArray *)aStores
{
    self = [super init];

    if (self)
    {
        _calStores = [aStores copy];
        _observedCompletionMasks = [NSCountedSet set];

        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
            _observedCalendarIdentifiers = [NSMapTable mapTableWithStrongToStrongObjects];
        else
            _observedCalendarIdentifiers = [NSMapTable strongToStrongObjectsMapTable];

        _fetchOperationsQueue = [[NSOperationQueue alloc] init];
        [_fetchOperationsQueue setName:@"Fetch Operations Queue (Reminders)"];
        [_fetchOperationsQueue setMaxConcurrentOperationCount:1];
        _fetchPredicateSemaphore = dispatch_semaphore_create(1);
        _notificationsDeliveryQueue = dispatch_queue_create("Notifications Queue (Reminders)", 0);
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_fetchOperationsQueue cancelAllOperations];
    dispatch_release(_fetchPredicateSemaphore);
    dispatch_release(_notificationsDeliveryQueue);
}


#pragma mark Methods

- (WLCalReminderCompletionMask)observedCompletionMask
{
    WLCalReminderCompletionMask mask = WLCalReminderCompletionMaskNothing;

    for (NSNumber *aMask in _observedCompletionMasks)
    {
        mask |= [aMask unsignedIntegerValue];

        if (mask == WLCalReminderCompletionMaskAny)
            break;
    }

    return mask;
}

- (void)addObservedCompletionMask:(WLCalReminderCompletionMask)aCompletionMask
{
    if (aCompletionMask == WLCalReminderCompletionMaskNothing)
        return;

    dispatch_semaphore_wait(_fetchPredicateSemaphore, DISPATCH_TIME_FOREVER);
    [self willChangeValueForKey:@"observedCompletionMask"];
    [_observedCompletionMasks addObject:@(aCompletionMask)];
    [self fetchPredicateDidChange];
    [self fetchCalRemindersForCompletionMask:aCompletionMask priority:NSOperationQueuePriorityNormal];
    [self didChangeValueForKey:@"observedCompletionMask"];
    dispatch_semaphore_signal(_fetchPredicateSemaphore);
}

- (void)removeObservedCompletionMask:(WLCalReminderCompletionMask)aCompletionMask
{
    if (aCompletionMask == WLCalReminderCompletionMaskNothing)
        return;

    dispatch_semaphore_wait(_fetchPredicateSemaphore, DISPATCH_TIME_FOREVER);
    [self willChangeValueForKey:@"observedCompletionMask"];
    [_observedCompletionMasks removeObject:@(aCompletionMask)];
    [self fetchPredicateDidChange];
    [self didChangeValueForKey:@"observedCompletionMask"];
    dispatch_semaphore_signal(_fetchPredicateSemaphore);
}

- (void)removeAllObservedCompletionMasks
{
    dispatch_semaphore_wait(_fetchPredicateSemaphore, DISPATCH_TIME_FOREVER);
    [self willChangeValueForKey:@"observedCompletionMask"];
    [_observedCompletionMasks removeAllObjects];
    [self fetchPredicateDidChange];
    [self didChangeValueForKey:@"observedCompletionMask"];
    dispatch_semaphore_signal(_fetchPredicateSemaphore);
}

- (NSArray *)observedCalendarIdentifiersForStore:(NSObject <WLCalStore> *)aStore
{
    if (![self.calStores containsObject:aStore])
        return @[];
    else
    {
        dispatch_semaphore_wait(_fetchPredicateSemaphore, DISPATCH_TIME_FOREVER);
        NSArray *a = [NSArray arrayWithArray:[_observedCalendarIdentifiers objectForKey:aStore]];
        dispatch_semaphore_signal(_fetchPredicateSemaphore);
        return a;
    }
}

- (void)setObservedCalendarIdentifiers:(NSSet *)aCalendarIdentifiers forStore:(NSObject <WLCalStore> *)aStore
{
    if (![self.calStores containsObject:aStore])
        return;

    dispatch_semaphore_wait(_fetchPredicateSemaphore, DISPATCH_TIME_FOREVER);
    [_observedCalendarIdentifiers setObject:[aCalendarIdentifiers copy] forKey:aStore];
    [self fetchPredicateDidChange];
    [self fetchCalRemindersWithPriority:NSOperationQueuePriorityNormal];
    dispatch_semaphore_signal(_fetchPredicateSemaphore);
}

- (void)fetchCalRemindersWithPriority:(NSOperationQueuePriority)aPriority
{
    // We will fetch all reminders for all observed completion masks.
    // Therefore we can safely cancel all other operations.
    [_fetchOperationsQueue cancelAllOperations];
    [self fetchCalRemindersForCompletionMask:self.observedCompletionMask priority:aPriority];
}

- (void)fetchCalRemindersForCompletionMask:(WLCalReminderCompletionMask)aCompletionMask priority:(NSOperationQueuePriority)aPriority
{
    if (aCompletionMask == WLCalReminderCompletionMaskNothing)
        return;

    // Capture parameters of the predicate because this method can be called concurrently.
    NSMapTable *localCalendarIdentifiers = [_observedCalendarIdentifiers copy];

    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *localOperation = operation;
    [operation setQueuePriority:aPriority];
    NSMapTable *userInfoPerStore = nil;
    dispatch_semaphore_t userInfoPerStoreSemaphore = dispatch_semaphore_create(1);

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
        userInfoPerStore = [NSMapTable mapTableWithStrongToStrongObjects];
    else
        userInfoPerStore = [NSMapTable strongToStrongObjectsMapTable];

    for (NSObject<WLCalStore> *store in self.calStores)
    {
        [operation addExecutionBlock:^
        {
            // Fetch reminders
            NSMutableArray *reminders = [NSMutableArray array];
            WLCalRemindersPredicate *p = [WLCalRemindersPredicate predicateWithCompletionMask:aCompletionMask
                                                                          calendarIdentifiers:[localCalendarIdentifiers objectForKey:store]];
            [reminders addObjectsFromArray:[store remindersMatchingPredicate:p]];

            if (![localOperation isCancelled])
            {
                // Parse reminders into per-store userInfo
                NSMutableDictionary *storeUserInfo = [NSMutableDictionary dictionaryWithCapacity:3];

                switch (aCompletionMask)
                {
                    case WLCalReminderCompletionMaskComplete:
                        storeUserInfo[@(WLCalReminderCompletionMaskComplete)] = reminders;
                        break;
                    case WLCalReminderCompletionMaskIncomplete:
                        storeUserInfo[@(WLCalReminderCompletionMaskIncomplete)] = reminders;
                        break;
                    case WLCalReminderCompletionMaskAny:
                    {
                        storeUserInfo[@(WLCalReminderCompletionMaskComplete)] = [reminders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == YES"]];
                        storeUserInfo[@(WLCalReminderCompletionMaskIncomplete)] = [reminders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == NO"]];
                        storeUserInfo[@(WLCalReminderCompletionMaskAny)] = reminders;
                        break;
                    }
                    default:
                        break;
                }

                if (![localOperation isCancelled])
                {
                    dispatch_semaphore_wait(userInfoPerStoreSemaphore, DISPATCH_TIME_FOREVER);
                    [userInfoPerStore setObject:storeUserInfo forKey:store];
                    dispatch_semaphore_signal(userInfoPerStoreSemaphore);
                }
            }
        }];
    }

    [operation setCompletionBlock:^
    {
        dispatch_release(userInfoPerStoreSemaphore);

        if ([localOperation isCancelled])
            return;

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];

        if (aCompletionMask & WLCalReminderCompletionMaskComplete)
            userInfo[@(WLCalReminderCompletionMaskComplete)] = [NSMutableArray array];

        if (aCompletionMask & WLCalReminderCompletionMaskIncomplete)
            userInfo[@(WLCalReminderCompletionMaskIncomplete)] = [NSMutableArray array];

        if (aCompletionMask & WLCalReminderCompletionMaskAny)
            userInfo[@(WLCalReminderCompletionMaskAny)] = [NSMutableArray array];

        for (NSDictionary *storeUserInfo in NSAllMapTableValues(userInfoPerStore))
        {
            [userInfo[@(WLCalReminderCompletionMaskComplete)] addObjectsFromArray:storeUserInfo[@(WLCalReminderCompletionMaskComplete)]];
            [userInfo[@(WLCalReminderCompletionMaskIncomplete)] addObjectsFromArray:storeUserInfo[@(WLCalReminderCompletionMaskIncomplete)]];
            [userInfo[@(WLCalReminderCompletionMaskAny)] addObjectsFromArray:storeUserInfo[@(WLCalReminderCompletionMaskAny)]];
        }

        if ([localOperation isCancelled])
            return;

        dispatch_async(_notificationsDeliveryQueue, ^
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:WLCalendarRemindersDidChangeNotification object:self userInfo:userInfo];
        });
    }];
    [_fetchOperationsQueue addOperation:operation];
}

- (void)calStoreDidChange:(NSNotification *)aNotification
{
    dispatch_semaphore_wait(_fetchPredicateSemaphore, DISPATCH_TIME_FOREVER);
    [self fetchCalRemindersWithPriority:NSOperationQueuePriorityLow];
    dispatch_semaphore_signal(_fetchPredicateSemaphore);
}

- (void)fetchPredicateDidChange
{
    if (_isObserving && self.observedCompletionMask == WLCalReminderCompletionMaskNothing)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [_fetchOperationsQueue cancelAllOperations];
        _isObserving = NO;
    }
    else if (!_isObserving && self.observedCompletionMask != WLCalReminderCompletionMaskNothing)
    {
        for (NSObject<WLCalStore> *store in _calStores)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(calStoreDidChange:)
                                                         name:WLCalStoreDidChangeNotification
                                                       object:store];
        }
        _isObserving = YES;
    }
}


#pragma mark NSObject

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@: {\n", [super description]];
    for (NSObject<WLCalStore> *store in self.calStores)
    {
        [description appendFormat:@"\t%@: %@\n", store, [self observedCalendarIdentifiersForStore:store]];
    }
    [description appendString:@"}"];
    return description;
}

@end

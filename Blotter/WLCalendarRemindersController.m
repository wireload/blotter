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
    dispatch_queue_t _accessQueue;
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
        _accessQueue = dispatch_queue_create("Access Queue (Reminders)", 0);
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_fetchOperationsQueue cancelAllOperations];
    dispatch_release(_accessQueue);
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

    [self willChangeValueForKey:@"observedCompletionMask"];
    dispatch_sync(_accessQueue, ^
    {
        [_observedCompletionMasks addObject:@(aCompletionMask)];
        [self fetchPredicateDidChange];
        [self fetchCalRemindersForCompletionMask:aCompletionMask priority:NSOperationQueuePriorityNormal];
    });
    [self didChangeValueForKey:@"observedCompletionMask"];
}

- (void)removeObservedCompletionMask:(WLCalReminderCompletionMask)aCompletionMask
{
    if (aCompletionMask == WLCalReminderCompletionMaskNothing)
        return;

    [self willChangeValueForKey:@"observedCompletionMask"];
    dispatch_sync(_accessQueue, ^
    {
        [_observedCompletionMasks removeObject:@(aCompletionMask)];
        [self fetchPredicateDidChange];
    });
    [self didChangeValueForKey:@"observedCompletionMask"];
}

- (void)removeAllObservedCompletionMasks
{
    [self willChangeValueForKey:@"observedCompletionMask"];
    dispatch_sync(_accessQueue, ^
    {
        [_observedCompletionMasks removeAllObjects];
        [self fetchPredicateDidChange];
    });
    [self didChangeValueForKey:@"observedCompletionMask"];
}

- (NSArray *)observedCalendarIdentifiersForStore:(NSObject <WLCalStore> *)aStore
{
    return [NSArray arrayWithArray:[_observedCalendarIdentifiers objectForKey:aStore]];
}

- (void)setObservedCalendarIdentifiers:(NSSet *)aCalendarIdentifiers forStore:(NSObject <WLCalStore> *)aStore
{
    dispatch_sync(_accessQueue, ^
    {
        [_observedCalendarIdentifiers setObject:[aCalendarIdentifiers copy] forKey:aStore];
        [self fetchPredicateDidChange];
        [self fetchCalRemindersWithPriority:NSOperationQueuePriorityNormal];
    });
}

- (void)fetchCalRemindersWithPriority:(NSOperationQueuePriority)aPriority
{
    [self fetchCalRemindersForCompletionMask:self.observedCompletionMask priority:aPriority];
}

- (void)fetchCalRemindersForCompletionMask:(WLCalReminderCompletionMask)aCompletionMask priority:(NSOperationQueuePriority)aPriority
{
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *unretainedOperation = operation;
    [operation setQueuePriority:aPriority];
    WLCalReminderCompletionMask mask = self.observedCompletionMask;
    NSMapTable *calendarIdentifiers = [_observedCalendarIdentifiers copy];
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
            WLCalRemindersPredicate *p = [WLCalRemindersPredicate predicateWithCompletionMask:mask calendarIdentifiers:[calendarIdentifiers objectForKey:store]];
            [reminders addObjectsFromArray:[store remindersMatchingPredicate:p]];

            if (![unretainedOperation isCancelled])
            {
                // Parse reminders into per-store userInfo
                NSMutableDictionary *storeUserInfo = [NSMutableDictionary dictionaryWithCapacity:3];

                switch (mask)
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

                if (![unretainedOperation isCancelled])
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

        if ([unretainedOperation isCancelled])
            return;

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];

        userInfo[@(WLCalReminderCompletionMaskComplete)] = [NSMutableArray array];
        userInfo[@(WLCalReminderCompletionMaskIncomplete)] = [NSMutableArray array];
        userInfo[@(WLCalReminderCompletionMaskAny)] = [NSMutableArray array];

        for (NSDictionary *storeUserInfo in NSAllMapTableValues(userInfoPerStore))
        {
            [userInfo[@(WLCalReminderCompletionMaskComplete)] addObjectsFromArray:storeUserInfo[@(WLCalReminderCompletionMaskComplete)]];
            [userInfo[@(WLCalReminderCompletionMaskIncomplete)] addObjectsFromArray:storeUserInfo[@(WLCalReminderCompletionMaskIncomplete)]];
            [userInfo[@(WLCalReminderCompletionMaskAny)] addObjectsFromArray:storeUserInfo[@(WLCalReminderCompletionMaskAny)]];
        }

        if ([unretainedOperation isCancelled])
            return;

        [[NSNotificationCenter defaultCenter] postNotificationName:WLCalendarRemindersDidChangeNotification object:self userInfo:userInfo];
    }];
    [_fetchOperationsQueue addOperation:operation];
}

- (void)calStoreDidChange:(NSNotification *)aNotification
{
    dispatch_sync(_accessQueue, ^
    {
        [self fetchCalRemindersWithPriority:NSOperationQueuePriorityLow];
    });
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

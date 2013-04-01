//
//  WLCalendarEventsController.m
//  Blotter
//
//  Created by Ilya Kulakov on 28.12.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarEventsController.h"


NSString *WLCalendarEventsDidChangeNotification = @"WLCalendarEventsDidChangeNotification";


@implementation WLCalendarEventsController
{
    NSCountedSet *_observedDateRanges;
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
        _observedDateRanges = [NSCountedSet set];

        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
            _observedCalendarIdentifiers = [NSMapTable mapTableWithStrongToStrongObjects];
        else
            _observedCalendarIdentifiers = [NSMapTable strongToStrongObjectsMapTable];

        _fetchOperationsQueue = [[NSOperationQueue alloc] init];
        [_fetchOperationsQueue setName:@"Fetch Operations Queue (Events)"];
        [_fetchOperationsQueue setMaxConcurrentOperationCount:1];
        _accessQueue = dispatch_queue_create("Access Queue (Events)", 0);
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

- (NSSet *)observedDateRanges
{
    return [NSSet setWithSet:_observedDateRanges];;
}

- (void)addObservedDateRange:(WLDateRange *)aRange
{
    if (!aRange || [aRange isEmpty])
        return;

    [self willChangeValueForKey:@"observedDateRanges"];
    dispatch_sync(_accessQueue, ^
    {
        [_observedDateRanges addObject:[aRange copy]];
        [self fetchPredicateDidChange];
        [self fetchCalEventsForDateRanges:[NSSet setWithObject:aRange] priority:NSOperationQueuePriorityNormal];
    });
    [self didChangeValueForKey:@"observedDateRanges"];
}

- (void)removeObservedDateRange:(WLDateRange *)aRange
{
    if (!aRange || [aRange isEmpty])
        return;

    [self willChangeValueForKey:@"observedDateRanges"];
    dispatch_sync(_accessQueue, ^
    {
        [_observedDateRanges removeObject:aRange];
        [self fetchPredicateDidChange];
    });
    [self didChangeValueForKey:@"observedDateRanges"];
}

- (void)removeAllObservedDateRanges
{
    if (![_observedDateRanges count])
        return;

    [self willChangeValueForKey:@"observedDateRanges"];
    dispatch_sync(_accessQueue, ^
    {
        [_observedDateRanges removeAllObjects];
        [self fetchPredicateDidChange];
    });
    [self didChangeValueForKey:@"observedDateRanges"];
}

- (NSArray *)observedCalendarIdentifiersForStore:(NSObject <WLCalStore> *)aStore
{
    if (![self.calStores containsObject:aStore])
        return @[];
    else
        return [NSArray arrayWithArray:[_observedCalendarIdentifiers objectForKey:aStore]];
}

- (void)setObservedCalendarIdentifiers:(NSArray *)aCalendarIdentifiers forStore:(NSObject <WLCalStore> *)aStore
{
    if (![self.calStores containsObject:aStore])
        return;

    dispatch_sync(_accessQueue, ^
    {
        [_observedCalendarIdentifiers setObject:[aCalendarIdentifiers copy] forKey:aStore];
        [self fetchPredicateDidChange];
        [self fetchCalEventsWithPriority:NSOperationQueuePriorityNormal];
    });
}

- (NSArray *)optimizeDateRanges:(NSArray *)aRanges
{
    if (!aRanges)
        [NSException raise:NSInvalidArgumentException format:@"aRanges cannot be nil."];

    if (![aRanges count])
        return @[];

    if ([aRanges count] == 1)
        return aRanges;

    NSArray *sortedRanges = [aRanges sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(WLDateRange *obj1, WLDateRange *obj2)
    {
        return [obj1.startDate compare:obj2.startDate];
    }];

    NSMutableArray *optimizedDateRanges = [NSMutableArray arrayWithCapacity:[sortedRanges count]];
    __block WLDateRange *currentDateRange = [sortedRanges objectAtIndex:0];

    [sortedRanges enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [sortedRanges count] - 1)]
                                    options:0
                                 usingBlock:^(WLDateRange *aRange, NSUInteger idx, BOOL *stop)
    {
        if ([aRange.startDate compare:currentDateRange.endDate] != NSOrderedDescending)
            currentDateRange = [currentDateRange dateRangeByUnitingWithDateRange:aRange];
        else
        {
            [optimizedDateRanges addObject:currentDateRange];
            currentDateRange = aRange;
        }
    }];
    [optimizedDateRanges addObject:currentDateRange];
    return optimizedDateRanges;
}

- (void)fetchCalEventsWithPriority:(NSOperationQueuePriority)aPriority
{
    [_fetchOperationsQueue cancelAllOperations];
    [self fetchCalEventsForDateRanges:self.observedDateRanges priority:aPriority];
}

- (void)fetchCalEventsForDateRanges:(NSSet *)aRanges priority:(NSOperationQueuePriority)aPriority
{
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *unretainedOperation = operation;
    [operation setQueuePriority:aPriority];
    NSArray *optimizedRanges = [self optimizeDateRanges:[aRanges allObjects]];
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
            // Fetch events
            NSMutableArray *events = [NSMutableArray array];

            for (WLDateRange *range in optimizedRanges)
            {
                WLCalEventsPredicate *p = [WLCalEventsPredicate predicateWithDateRange:range
                                                                   calendarIdentifiers:[calendarIdentifiers objectForKey:store]];
                [events addObjectsFromArray:[store eventsMatchingPredicate:p]];

                if ([unretainedOperation isCancelled])
                    break;
            }

            if (![unretainedOperation isCancelled])
            {
                // Parse events into per-store userInfo
                NSMutableDictionary *storeUserInfo = [NSMutableDictionary dictionaryWithCapacity:[aRanges count]];
                dispatch_semaphore_t storeUserInfoSemaphore = dispatch_semaphore_create(1);
                [aRanges enumerateObjectsWithOptions:NSEnumerationConcurrent
                                          usingBlock:^(WLDateRange *aRange, BOOL *stop)
                {
                    NSIndexSet *indexesOfRangeEvents = [events indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                               passingTest:^BOOL(NSObject<WLCalEvent> *anEvent, NSUInteger idx, BOOL *s)
                    {
                        return [aRange intersectsRange:[WLDateRange dateRangeWithStartDate:anEvent.startDate endDate:anEvent.endDate]];
                    }];
                    dispatch_semaphore_wait(storeUserInfoSemaphore, DISPATCH_TIME_FOREVER);
                    [storeUserInfo setObject:[events objectsAtIndexes:indexesOfRangeEvents] forKey:aRange];
                    dispatch_semaphore_signal(storeUserInfoSemaphore);

                    if ([unretainedOperation isCancelled])
                        *stop = YES;
                }];
                dispatch_release(storeUserInfoSemaphore);

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

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:[aRanges count]];
        NSArray *userInfos = NSAllMapTableValues(userInfoPerStore);

        for (WLDateRange *range in aRanges)
        {
            NSMutableArray *events = [NSMutableArray array];

            for (NSDictionary *storeUserInfo in userInfos)
                [events addObjectsFromArray:[storeUserInfo objectForKey:range]];

            [userInfo setObject:events forKey:range];
        }

        if ([unretainedOperation isCancelled])
            return;

        [[NSNotificationCenter defaultCenter] postNotificationName:WLCalendarEventsDidChangeNotification object:self userInfo:userInfo];
    }];
    [_fetchOperationsQueue addOperation:operation];
}

- (NSArray *)calEventsForDateRange:(WLDateRange *)aRange
{
    NSMutableArray *events = [NSMutableArray array];

    dispatch_sync(_accessQueue, ^
    {
        for (NSObject<WLCalStore> *store in self.calStores)
        {
            WLCalEventsPredicate *p = [WLCalEventsPredicate predicateWithDateRange:aRange
                                                               calendarIdentifiers:[_observedCalendarIdentifiers objectForKey:store]];
            [events addObjectsFromArray:[store eventsMatchingPredicate:p]];
        }
    });

    return events;
}

- (void)calStoreDidChange:(NSNotification *)aNotification
{
    dispatch_sync(_accessQueue, ^
    {
        [self fetchCalEventsWithPriority:NSOperationQueuePriorityLow];
    });
}

- (void)fetchPredicateDidChange
{
    if (_isObserving && ![self.observedDateRanges count])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [_fetchOperationsQueue cancelAllOperations];
        _isObserving = NO;
    }
    else if (!_isObserving && [self.observedDateRanges count])
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

@end

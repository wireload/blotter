//
//  WLCalSystemStore.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 11.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <EventKit/EventKit.h>
#import "iCal_10_7.h"
#import "iCal_10_8.h"
#import "WLCalSystemStore.h"
#import "WLCalSystemCalendar.h"
#import "WLCalSystemEvent.h"
#import "WLCalSystemReminder.h"


static const NSTimeInterval _WLAccumulateSystemNotificationsInterval = 5.0;


@implementation WLCalSystemStore
{
    CalCalendarStore *_store;
    EKEventStore *_calendarTypeStore;
    id _iCalApp;
    dispatch_semaphore_t _iCalAppSemaphore;

    NSCache *_calendarTypeCache;

    WLASLLog *_log;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _log = [[WLASLLog alloc] initWithName:@"net.wireload.WLCalendarStore.System"];
        _store = [CalCalendarStore defaultCalendarStore];

        if (!_store)
        {
            [_log logError:@"Unable to initialize CalCalendarStore. Probably CalendarStore.framework does not exist in the system or it's damaged. Please contact our support."];
            return nil;
        }

        _iCalApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iCal"];
        if (_iCalApp)
            _iCalAppSemaphore = dispatch_semaphore_create(1); // ensure we don't use it from multiple threads
        else
            [_log logWarning:@"iCal either does not exist or does not support scripting anymore. Please contact our support."];

        if (NSClassFromString(@"EKEventStore"))
            _calendarTypeStore = [[EKEventStore alloc] initWithAccessToEntityTypes:EKEntityMaskEvent | EKEntityMaskReminder];

        _calendarTypeCache = [[NSCache alloc] init];
        [_calendarTypeCache setName:@"net.wireload.WLCalendarStore.CalendarTypeCache"];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_systemStoreDidChange:)
                                                     name:CalCalendarsChangedNotification
                                                   object:_store];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_systemStoreDidChange:)
                                                     name:CalCalendarsChangedExternallyNotification
                                                   object:_store];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_systemStoreDidChange:)
                                                     name:CalEventsChangedNotification
                                                   object:_store];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_systemStoreDidChange:)
                                                     name:CalEventsChangedExternallyNotification
                                                   object:_store];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_systemStoreDidChange:)
                                                     name:CalTasksChangedNotification
                                                   object:_store];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_systemStoreDidChange:)
                                                     name:CalTasksChangedExternallyNotification
                                                   object:_store];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(_systemStoreDidChange:)
                                                                   name:NSWorkspaceDidLaunchApplicationNotification
                                                                 object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CalCalendarsChangedNotification
                                                  object:_store];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CalCalendarsChangedExternallyNotification
                                                  object:_store];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CalEventsChangedNotification
                                                  object:_store];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CalEventsChangedExternallyNotification
                                                  object:_store];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CalTasksChangedNotification
                                                  object:_store];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CalTasksChangedExternallyNotification
                                                  object:_store];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self
                                                                  name:NSWorkspaceDidLaunchApplicationNotification
                                                                object:nil];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyObservers) object:nil];
}



#pragma mark - Methods

- (NSArray *)iCalCalendarUIDs
{
    if (_iCalApp)
    {
        dispatch_semaphore_wait(_iCalAppSemaphore, DISPATCH_TIME_FOREVER);

        NSArray *UIDs = nil;
        if ([_iCalApp isRunning])
            UIDs = [[_iCalApp calendars] valueForKey:@"uid"];
        else
            [_log logNotice:@"Cannot get calendar UIDs from iCal since it's not running."];

        dispatch_semaphore_signal(_iCalAppSemaphore);

        return UIDs;
    }
    else
        return @[];
}

- (NSArray *)fetchCSCalendarsForUIDs:(NSArray *)anUIDs
                         invalidUIDs:(out __autoreleasing NSArray **)outInvalidUIDs
{
    if ([anUIDs count] == 0)
        return @[];

    NSMutableArray *csCalendars = [NSMutableArray arrayWithCapacity:[anUIDs count]];
    NSMutableIndexSet *indexesOfInvalidUIDs = [NSMutableIndexSet indexSet];

    [anUIDs enumerateObjectsUsingBlock:^(NSString *anUID, NSUInteger idx, BOOL *stop)
    {
        CalCalendar *c = [_store calendarWithUID:anUID];

        if (c)
            [csCalendars addObject:c];
        else
            [indexesOfInvalidUIDs addIndex:idx];
    }];

    if ([indexesOfInvalidUIDs count])
    {
        NSArray *invalidUIDs = [anUIDs objectsAtIndexes:indexesOfInvalidUIDs];
        if (outInvalidUIDs)
            *outInvalidUIDs = invalidUIDs;

        [_log logNotice:@"Cannot fetch CalCalendars with UIDs: %@", invalidUIDs];
    }

    return csCalendars;
}

- (NSArray *)fetchCSEventsMatchingPredicate:(WLCalEventsPredicate *)anEventsPredicate csCalednars:(__autoreleasing NSArray **)outCSCalendars
{
    NSParameterAssert(anEventsPredicate);

    if (!anEventsPredicate.dateRange || [anEventsPredicate.dateRange isEmpty])
        return @[];

    if (anEventsPredicate.calendarIdentifiers && [anEventsPredicate.calendarIdentifiers count] == 0)
        return @[];

    NSArray *csCalendars = nil; // means all calendars

    if (anEventsPredicate.calendarIdentifiers)
    {
        csCalendars = [self fetchCSCalendarsForUIDs:anEventsPredicate.calendarIdentifiers invalidUIDs:NULL];

        if (outCSCalendars)
            *outCSCalendars = csCalendars;

        if ([csCalendars count] == 0)
            return @[];
    }

    NSArray *csEvents = @[];
    NSPredicate *p = [[_store class] eventPredicateWithStartDate:anEventsPredicate.dateRange.startDate
                                                         endDate:anEventsPredicate.dateRange.endDate
                                                       calendars:csCalendars];
    if (p)
        csEvents = [_store eventsWithPredicate:p];
    else
        [_log logError:@"Cannot make event predicate with parameters: {startDate: %@, endDate: %@, calendars: %@",anEventsPredicate.dateRange.startDate, anEventsPredicate.dateRange.endDate, csCalendars];

    return csEvents;
}

- (NSArray *)fetchCSRemindersMatchingPredicate:(WLCalRemindersPredicate *)aReminderPredicate csCalednars:(__autoreleasing NSArray **)outCSCalendars
{
    NSParameterAssert(aReminderPredicate);

    if (aReminderPredicate.calendarIdentifiers && [aReminderPredicate.calendarIdentifiers count] == 0)
        return @[];

    NSArray *csCalendars = nil; // means all calendars

    if (aReminderPredicate.calendarIdentifiers)
    {
        csCalendars = [self fetchCSCalendarsForUIDs:aReminderPredicate.calendarIdentifiers invalidUIDs:NULL];

        if (outCSCalendars)
            *outCSCalendars = csCalendars;

        if ([csCalendars count] == 0)
            return @[];
    }

    NSArray *csReminders = @[];
    NSPredicate *p = nil;

    switch (aReminderPredicate.completionMask)
    {
        case WLCalReminderCompletionMaskComplete:
            p = [[_store class] taskPredicateWithTasksCompletedSince:nil calendars:csCalendars];
            break;
        case WLCalReminderCompletionMaskIncomplete:
            p = [[_store class] taskPredicateWithUncompletedTasks:csCalendars];
            break;
        case WLCalReminderCompletionMaskAny:
            p = [[_store class] taskPredicateWithCalendars:csCalendars];
            break;
    }

    if (p)
        csReminders = [_store tasksWithPredicate:p];
    else
        [_log logError:@"Cannot make reminder predicate with parameters: {completionMask: %d, calendars: %@", aReminderPredicate.completionMask, csCalendars];

    return csReminders;
}

- (NSArray *)makeCalendarsFromCSCalendars:(NSArray *)aCSCalendars
{
    if ([aCSCalendars count] == 0)
        return @[];

    NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:[aCSCalendars count]];

    for (CalCalendar *csCalendar in aCSCalendars)
    {
        WLCalEntityMask allowedEntityTypes = [self allowedEntityTypesForCSCalendar:csCalendar];
        WLCalSystemCalendar *calendar = [[WLCalSystemCalendar alloc] initWithStore:self
                                                                        csCalendar:csCalendar
                                                                allowedEntityTypes:allowedEntityTypes];
        [calendars addObject:calendar];
    }

    return calendars;
}

- (WLCalEntityMask)allowedEntityTypesForCSCalendar:(CalCalendar *)aCalendar
{
    NSParameterAssert(aCalendar.uid);

    WLCalEntityMask mask = (WLCalEntityMask)[[_calendarTypeCache objectForKey:aCalendar.uid] unsignedIntegerValue];

    if (mask == WLCalEntityMaskUnknown)
        mask = [self _fastAllowedEntityTypesForCSCalendar:aCalendar];

    if (mask == WLCalEntityMaskUnknown)
        mask = [self _slowAllowedEntityTypesForCSCalendar:aCalendar];

    if (mask != WLCalEntityMaskUnknown)
        [_calendarTypeCache setObject:@(mask) forKey:aCalendar.uid];

    return mask;
}


#pragma mark Private

- (WLCalEntityMask)_fastAllowedEntityTypesForCSCalendar:(CalCalendar *)aCalendar
{
    if (_calendarTypeStore)
    {
        EKCalendar *ekCalendar = [_calendarTypeStore calendarWithIdentifier:aCalendar.uid];
        EKEntityMask ekMask = ekCalendar.allowedEntityTypes;

        WLCalEntityMask calMask = WLCalEntityMaskUnknown;

        if (ekMask & EKEntityMaskEvent)
            calMask |= WLCalEntityMaskEvent;

        if (ekMask & EKEntityMaskReminder)
            calMask |= WLCalEntityMaskReminder;

        return calMask;
    }
    else
        return WLCalEntityMaskUnknown;
}

- (WLCalEntityMask)_slowAllowedEntityTypesForCSCalendar:(CalCalendar *)aCalendar
{
    if (aCalendar == nil)
        [NSException raise:NSInternalInconsistencyException format:@"You cannot get mask for nil."];

    static const NSUInteger MaximumNumberOfAttemptsToAddOrDelete = 5;
    static const NSTimeInterval AttemptDelay = 0.1;

    // CalendarStore allows us to get events that fall within a maximum four year timespan.
    static NSDate *StartOf4YearsPeriod = nil;
    static NSDate *EndOf4YearsPeriod = nil;
    static NSString *TmpItemsNotes = @"";
    static NSString *TmpItemsTitle = @"";
    static dispatch_once_t OncePredicate;

    dispatch_once(&OncePredicate, ^{
        EndOf4YearsPeriod = [NSDate date];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *minus4Years = [[NSDateComponents alloc] init];
        [minus4Years setYear:-4];
        StartOf4YearsPeriod = [calendar dateByAddingComponents:minus4Years toDate:EndOf4YearsPeriod options:0];

        TmpItemsTitle = [NSString stringWithFormat:@"Quit %@ and delete it.", [[NSProcessInfo processInfo] processName]];
        TmpItemsNotes = [[NSBundle mainBundle] bundleIdentifier];
        CFUUIDRef uuid = CFUUIDCreate(NULL);

        if (uuid)
        {
            CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
            if (uuidString)
            {
                TmpItemsNotes = [TmpItemsNotes stringByAppendingFormat:@".%@", uuidString];
                CFRelease(uuidString);
            }
            CFRelease(uuid);
        }
    });

    WLCalEntityMask allowedEntityTypes = WLCalEntityMaskUnknown;
    BOOL allowsAdvancedCalendarTypeCheck = [[NSUserDefaults standardUserDefaults] boolForKey:WLCalSystemStoreAllowsAdvancedCalendarTypeCheckKey];

    NSArray *events = @[];
    NSPredicate *p = [[_store class] eventPredicateWithStartDate:StartOf4YearsPeriod
                                                         endDate:EndOf4YearsPeriod
                                                       calendars:@[aCalendar]];
    if (p)
        events = [_store eventsWithPredicate:p];

    if ([events count] > 0)
        allowedEntityTypes |= WLCalEntityMaskEvent;
    else if (allowsAdvancedCalendarTypeCheck)
    {
        CalEvent *tmpEvent = [CalEvent event];
        tmpEvent.calendar = aCalendar;
        tmpEvent.notes = TmpItemsNotes;
        tmpEvent.title = TmpItemsTitle;
        tmpEvent.startDate = [NSDate dateWithTimeInterval:-3600*24*365 sinceDate:[NSDate date]];
        tmpEvent.endDate = [tmpEvent.startDate dateByAddingTimeInterval:3600];
        NSError *error = nil;
        BOOL canSaveEvent = NO;
        NSUInteger currentAttempt = 0;

        while (aCalendar.isEditable &&
               currentAttempt < MaximumNumberOfAttemptsToAddOrDelete &&
               !canSaveEvent &&
               [error code] != CalCalendarNotEditableError)
        {
            if (currentAttempt > 0)
                [NSThread sleepForTimeInterval:AttemptDelay];

            canSaveEvent = [_store saveEvent:tmpEvent span:CalSpanThisEvent error:&error];
            ++currentAttempt;
        }

        if (canSaveEvent)
        {
            currentAttempt = 0;
            BOOL canDeleteEvent = NO;

            while (currentAttempt < MaximumNumberOfAttemptsToAddOrDelete &&
                   !canDeleteEvent)
            {
                if (currentAttempt > 0)
                    [NSThread sleepForTimeInterval:AttemptDelay];

                canDeleteEvent = [[CalCalendarStore defaultCalendarStore] removeEvent:tmpEvent span:CalSpanThisEvent error:&error];
                ++currentAttempt;
            }

            if (currentAttempt == MaximumNumberOfAttemptsToAddOrDelete)
                [_log logError:@"Cannot delete tmp event (%@): %@.", tmpEvent.uid, [error localizedDescription]];

            allowedEntityTypes |= WLCalEntityMaskEvent;
        }
    }

    NSArray *reminders = @[];
    p = [[_store class] taskPredicateWithCalendars:@[aCalendar]];
    if (p)
        reminders = [_store tasksWithPredicate:p];

    if ([reminders count] > 0)
        allowedEntityTypes |= WLCalEntityMaskReminder;
    else if (allowsAdvancedCalendarTypeCheck)
    {
        CalTask *tmpReminder = [CalTask task];
        tmpReminder.notes = TmpItemsNotes;
        tmpReminder.title = TmpItemsTitle;
        tmpReminder.calendar = aCalendar;
        tmpReminder.isCompleted = YES;

        NSError *error = nil;
        BOOL canSaveTask = NO;
        NSUInteger currentAttempt = 0;

        while (aCalendar.isEditable &&
               currentAttempt < MaximumNumberOfAttemptsToAddOrDelete &&
               !canSaveTask &&
               [error code] != CalCalendarNotEditableError)
        {
            if (currentAttempt > 0)
                [NSThread sleepForTimeInterval:AttemptDelay];

            canSaveTask = [_store saveTask:tmpReminder error:&error];
            ++currentAttempt;
        }

        if (canSaveTask)
        {
            currentAttempt = 0;
            BOOL canDeleteTask = NO;

            while (currentAttempt < MaximumNumberOfAttemptsToAddOrDelete &&
                   !canDeleteTask)
            {
                if (currentAttempt > 0)
                    [NSThread sleepForTimeInterval:AttemptDelay];

                canDeleteTask = [[CalCalendarStore defaultCalendarStore] removeTask:tmpReminder error:&error];
                ++currentAttempt;
            }

            if (currentAttempt == MaximumNumberOfAttemptsToAddOrDelete)
                [_log logError:@"Cannot delete tmp event (%@): %@.", tmpReminder.uid, [error localizedDescription]];

            allowedEntityTypes |= WLCalEntityMaskReminder;
        }
    }

    return allowedEntityTypes;
}

- (void)_systemStoreDidChange:(NSNotification *)aNotification
{
    if ([[aNotification name] isEqual:NSWorkspaceDidLaunchApplicationNotification])
    {
        static NSString* const iCalBundleIdentifier = @"com.apple.iCal";
        static NSString* const remindersBundleIdentifier = @"com.apple.reminders";

        NSString *senderApplicationIdentifier = [[aNotification userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
        if (![senderApplicationIdentifier isEqual:iCalBundleIdentifier] && ![senderApplicationIdentifier isEqual:remindersBundleIdentifier])
            return;
    }

    @synchronized (self)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyObservers) object:nil];
        [self performSelector:@selector(_notifyObservers) withObject:nil afterDelay:_WLAccumulateSystemNotificationsInterval];
    }
}

- (void)_notifyObservers
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WLCalStoreDidChangeNotification object:self];
}


#pragma mark WLCalStore

- (NSArray *)calendars
{
    NSMutableArray *calendars = [NSMutableArray arrayWithArray:[self makeCalendarsFromCSCalendars:[_store calendars]]];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:WLCalSystemStoreChecksCalendarsAgainstICalKey])
    {
        NSArray *u = [self iCalCalendarUIDs];
        NSArray *csCalendars = [self fetchCSCalendarsForUIDs:u invalidUIDs:NULL];
        [calendars addObjectsFromArray:[self makeCalendarsFromCSCalendars:csCalendars]];
    }

    [calendars sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalCalendarsComparator];
    [calendars WL_removeDuplicatesInSortedArrayUsingComparator:WLCalCalendarsComparator];

    return calendars;
}

- (id <WLCalCalendar>)calendarWithIdentifier:(NSString *)anIdentifier
{
    return [[self makeCalendarsFromCSCalendars:@[[_store calendarWithUID:anIdentifier]]] lastObject];
}

- (NSArray *)eventsMatchingPredicate:(WLCalEventsPredicate *)aPredicate
{
    NSArray *csCalendars = nil;
    NSArray *csEvents = [self fetchCSEventsMatchingPredicate:aPredicate csCalednars:&csCalendars];

    NSMutableArray *cachedCalendars = [[self makeCalendarsFromCSCalendars:csCalendars] mutableCopy];
    [cachedCalendars sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalCalendarsComparator];
    [cachedCalendars WL_removeDuplicatesInSortedArrayUsingComparator:WLCalCalendarsComparator];

    NSMutableArray *events = [NSMutableArray arrayWithCapacity:[csEvents count]];

    for (CalEvent *csEvent in csEvents)
    {
        WLCalSystemCalendar *calendar = nil;
        NSUInteger cachedCalendarIndex = [cachedCalendars indexOfObject:@{ @"calendarIdentifier" : csEvent.calendar.uid }
                                                          inSortedRange:NSMakeRange(0, [cachedCalendars count])
                                                                options:NSBinarySearchingFirstEqual
                                                        usingComparator:WLCalCalendarsComparator];

        if (cachedCalendarIndex != NSNotFound)
            calendar = cachedCalendars[cachedCalendarIndex];
        else
        {
            WLCalSystemCalendar *newCalendar = [[self makeCalendarsFromCSCalendars:@[[_store calendarWithUID:csEvent.calendar.uid]]] lastObject];

            if (newCalendar)
            {
                NSUInteger newCalendarInsertionIndex = [cachedCalendars indexOfObject:newCalendar
                                                                        inSortedRange:NSMakeRange(0, [cachedCalendars count])
                                                                              options:NSBinarySearchingInsertionIndex
                                                                      usingComparator:WLCalCalendarsComparator];
                [cachedCalendars insertObject:newCalendar atIndex:newCalendarInsertionIndex];

                calendar = newCalendar;
            }
        }

        if (calendar)
        {
            WLCalSystemEvent *event = [[WLCalSystemEvent alloc] initWithStore:self
                                                                      csEvent:csEvent
                                                                  calCalendar:calendar];
            NSUInteger i = [events indexOfObject:event
                                   inSortedRange:NSMakeRange(0, [events count])
                                         options:NSBinarySearchingInsertionIndex
                                 usingComparator:WLCalEventsComparator];
            [events insertObject:event atIndex:i];
        }
    }

    [events WL_removeDuplicatesInSortedArrayUsingComparator:WLCalEventsComparator];

    return events;
}

- (NSArray *)remindersMatchingPredicate:(WLCalRemindersPredicate *)aPredicate
{
    NSArray *csCalendars = nil;
    NSArray *csReminders = [self fetchCSRemindersMatchingPredicate:aPredicate csCalednars:&csCalendars];

    NSMutableArray *cachedCalendars = [[self makeCalendarsFromCSCalendars:csCalendars] mutableCopy];
    [cachedCalendars sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalCalendarsComparator];
    [cachedCalendars WL_removeDuplicatesInSortedArrayUsingComparator:WLCalCalendarsComparator];

    NSMutableArray *reminders = [NSMutableArray arrayWithCapacity:[csReminders count]];

    for (CalTask *csReminder in csReminders)
    {
        WLCalSystemCalendar *calendar = nil;
        NSUInteger cachedCalendarIndex = [cachedCalendars indexOfObject:@{ @"calendarIdentifier" : csReminder.calendar.uid }
                                                          inSortedRange:NSMakeRange(0, [cachedCalendars count])
                                                                options:NSBinarySearchingFirstEqual
                                                        usingComparator:WLCalCalendarsComparator];

        if (cachedCalendarIndex != NSNotFound)
            calendar = cachedCalendars[cachedCalendarIndex];
        else
        {
            WLCalSystemCalendar *newCalendar = [[self makeCalendarsFromCSCalendars:@[[_store calendarWithUID:csReminder.calendar.uid]]] lastObject];

            if (newCalendar)
            {
                NSUInteger newCalendarInsertionIndex = [cachedCalendars indexOfObject:newCalendar
                                                                        inSortedRange:NSMakeRange(0, [cachedCalendars count])
                                                                              options:NSBinarySearchingInsertionIndex
                                                                      usingComparator:WLCalCalendarsComparator];
                [cachedCalendars insertObject:newCalendar atIndex:newCalendarInsertionIndex];

                calendar = newCalendar;
            }
        }

        if (calendar)
        {
            WLCalSystemReminder *reminder = [[WLCalSystemReminder alloc] initWithStore:self
                                                                            csReminder:csReminder
                                                                           calCalendar:calendar];
            NSUInteger i = [reminders indexOfObject:reminder
                                      inSortedRange:NSMakeRange(0, [reminders count])
                                            options:NSBinarySearchingInsertionIndex
                                    usingComparator:WLCalRemindersComparator];
            [reminders insertObject:reminder atIndex:i];
        }
    }

    [reminders WL_removeDuplicatesInSortedArrayUsingComparator:WLCalRemindersComparator];

    return reminders;
}

@end

//
//  WLCalSystemStore.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 11.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <EventKit/EventKit.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "iCal_10_7.h"
#import "iCal_10_8.h"
#import "WLCalSystemStore.h"
#import "WLCalSystemCalendar.h"
#import "WLCalSystemEvent.h"
#import "WLCalSystemReminder.h"


static const NSTimeInterval _WLAccumulateSystemNotificationsInterval = 1.0;


@implementation WLCalSystemStore
{
    CalCalendarStore *_calendarStore;
    dispatch_semaphore_t _calendarStoreSemaphore;
    EKEventStore *_calendarTypeStore;
    dispatch_semaphore_t _iCalAppSemaphore;
    
    BOOL _checkCalendarsAgainstICal;

    NSMutableDictionary *_calendarTypeCache;
    dispatch_semaphore_t _calendarTypeCacheSemaphore;

    WLASLLog *_log;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _log = [[WLASLLog alloc] initWithName:@"net.wireload.WLCalendarStore.System"];

        _calendarStoreSemaphore = dispatch_semaphore_create(1);

        _iCalAppSemaphore = dispatch_semaphore_create(1); // ensure we don't use app from multiple threads
        _checkCalendarsAgainstICal = [[NSUserDefaults standardUserDefaults] boolForKey:WLCalSystemStoreChecksCalendarsAgainstICalKey];

        if (!_checkCalendarsAgainstICal)
            [_log logWarning:@"Checking calendars against iCal is disabled"];

        if (NSClassFromString(@"EKEventStore"))
        {
            _calendarTypeStore = [[EKEventStore alloc] init];
            __weak __auto_type weakSelf = self;
            [_calendarTypeStore requestAccessToEntityType:EKEntityMaskEvent | EKEntityMaskReminder completion:^(BOOL granted, NSError *error) {
                __strong __auto_type strongSelf = weakSelf;
                if (granted && strongSelf)
                {
                    [strongSelf _systemStoreDidChange:[NSNotification notificationWithName:EKEventStoreChangedNotification object:strongSelf->_calendarTypeStore]];
                }
            }];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:EKEventStoreChangedNotification
                                                       object:_calendarTypeStore];
        }

        _calendarTypeCache = [[NSMutableDictionary alloc] init];
        _calendarTypeCacheSemaphore = dispatch_semaphore_create(1);

        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self
                                                               selector:@selector(_systemStoreDidChange:)
                                                                   name:NSWorkspaceDidLaunchApplicationNotification
                                                                 object:nil];
    }

    return self;
}

- (void)dealloc
{
    // The object was not initialized and nil was returned from -init.
    if (self.calendarStore)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:CalCalendarsChangedNotification
                                                      object:self.calendarStore];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:CalCalendarsChangedExternallyNotification
                                                      object:self.calendarStore];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:CalEventsChangedNotification
                                                      object:self.calendarStore];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:CalEventsChangedExternallyNotification
                                                      object:self.calendarStore];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:CalTasksChangedNotification
                                                      object:self.calendarStore];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:CalTasksChangedExternallyNotification
                                                      object:self.calendarStore];
        [[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self
                                                                      name:NSWorkspaceDidLaunchApplicationNotification
                                                                    object:nil];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:EKEventStoreChangedNotification
                                                  object:_calendarTypeStore];

    [[NSRunLoop mainRunLoop] cancelPerformSelector:@selector(_notifyObservers) target:self argument:nil];
}


#pragma mark Properties

- (CalCalendarStore *)calendarStore
{
    if (dispatch_semaphore_wait(_calendarStoreSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0)
    {
        [_log logError:@"Cannot access CalCalendarStore since it's locked for too long."];
        return nil;
    }

    if (!_calendarStore)
    {
        _calendarStore = [CalCalendarStore defaultCalendarStore];

        if (_calendarStore)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:CalCalendarsChangedNotification
                                                       object:_calendarStore];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:CalCalendarsChangedExternallyNotification
                                                       object:_calendarStore];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:CalEventsChangedNotification
                                                       object:_calendarStore];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:CalEventsChangedExternallyNotification
                                                       object:_calendarStore];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:CalTasksChangedNotification
                                                       object:_calendarStore];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_systemStoreDidChange:)
                                                         name:CalTasksChangedExternallyNotification
                                                       object:_calendarStore];
        }
        else
            [_log logWarning:@"Unable to initialize CalCalendarStore.\nPossbile reasons:\n\t- You've restricted access to Calendars or Reminders data\n\t- CalendarStore.framework does not exist in the system or it's damaged\nPlease contact our support."];
    }

    dispatch_semaphore_signal(_calendarStoreSemaphore);

    return _calendarStore;
}


#pragma mark Methods

- (NSSet *)iCalCalendarUIDs
{
    SBApplication *iCalApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iCal"];

    if (iCalApp)
    {
        if (dispatch_semaphore_wait(_iCalAppSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0)
        {
            [_log logError:@"Cannot fetch calendar UIDs from iCal since it's locked for too long."];
            return [NSSet set];
        }

        NSArray *UIDs = @[];

        // Scripting Bridge known to be very unreliable.
        @try
        {
            iCalApp.delegate = self;

            if (iCalApp.running)
            {
                UIDs = [[(id)iCalApp calendars] valueForKey:@"uid"];
                [_log logDebug:@"Successfuly fetched calendar UIDs from iCal: %@", UIDs];
            }
            else
                [_log logWarning:@"Cannot fetch calendar UIDs from iCal since it's not running."];
        }
        @catch (NSException *anException)
        {
            [_log logError:@"Exception occured while fetching calendar UIDs from iCal (%@): %@ (%@).", iCalApp, anException.reason, anException.userInfo];
        }
        @catch (...)
        {
            [_log logError:@"Unknown exception occured while fetching calendar UIDs from iCal (%@).", iCalApp];
        }
        @finally
        {
            dispatch_semaphore_signal(_iCalAppSemaphore);
            return [NSSet setWithArray:UIDs];
        }
    }
    else
    {
        [_log logError:@"Unable to create Scripting Bridge to iCal."];
        return [NSSet set];
    }
}

- (NSArray *)fetchCSCalendarsForUIDs:(NSSet *)anUIDs
                         invalidUIDs:(__autoreleasing NSSet **)outInvalidUIDs
{
    if (anUIDs.count == 0)
        return @[];

    // Accessing store is potentially long operation.
    // To improve the response time we access it concurrently.
    //
    // 2 Semaphores are used to protect mutable containers from being smashed.
    NSMutableArray *csCalendars = [NSMutableArray arrayWithCapacity:anUIDs.count];
    NSMutableSet *invalidUIDs = [NSMutableSet set];
    dispatch_semaphore_t csCalendarsSemaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_t invalidUIDsSemaphore = dispatch_semaphore_create(1);

    [anUIDs enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *anUID, BOOL *stop)
    {
        CalCalendar *c = [self.calendarStore calendarWithUID:anUID];

        if (c)
        {
            dispatch_semaphore_wait(csCalendarsSemaphore, DISPATCH_TIME_FOREVER);
            [csCalendars addObject:c];
            dispatch_semaphore_signal(csCalendarsSemaphore);
        }
        else
        {
            dispatch_semaphore_wait(invalidUIDsSemaphore, DISPATCH_TIME_FOREVER);
            [invalidUIDs addObject:anUID];
            dispatch_semaphore_signal(invalidUIDsSemaphore);
        }
    }];

    if (invalidUIDs.count)
    {
        if (outInvalidUIDs)
            *outInvalidUIDs = invalidUIDs;

        [_log logWarning:@"Cannot fetch CalCalendars with UIDs: %@", invalidUIDs];
    }

    return csCalendars;
}

- (NSArray *)fetchCSEventsMatchingPredicate:(WLCalEventsPredicate *)anEventsPredicate csCalednars:(__autoreleasing NSArray **)outCSCalendars
{
    NSParameterAssert(anEventsPredicate);

    if (!anEventsPredicate.dateRange || (anEventsPredicate.dateRange).empty)
        return @[];

    if ((anEventsPredicate.calendarIdentifiers).count == 0)
        return @[];

    NSArray *csCalendars = nil;

    if (anEventsPredicate.calendarIdentifiers)
    {
        csCalendars = [self fetchCSCalendarsForUIDs:anEventsPredicate.calendarIdentifiers invalidUIDs:NULL];

        if (outCSCalendars)
            *outCSCalendars = csCalendars;

        if (csCalendars.count == 0)
            return @[];
    }

    NSArray *csEvents = @[];
    NSPredicate *p = [[self.calendarStore class] eventPredicateWithStartDate:anEventsPredicate.dateRange.startDate
                                                                     endDate:anEventsPredicate.dateRange.endDate
                                                                   calendars:csCalendars];
    if (p)
        csEvents = [self.calendarStore eventsWithPredicate:p];
    else
        [_log logError:@"Cannot make event predicate with parameters: {startDate: %@, endDate: %@, calendars: %@", anEventsPredicate.dateRange.startDate, anEventsPredicate.dateRange.endDate, csCalendars];

    return (csEvents != nil) ? csEvents : @[];
}

- (NSArray *)fetchCSRemindersMatchingPredicate:(WLCalRemindersPredicate *)aReminderPredicate csCalednars:(__autoreleasing NSArray **)outCSCalendars
{
    NSParameterAssert(aReminderPredicate);

    if ((aReminderPredicate.calendarIdentifiers).count == 0)
        return @[];

    if (aReminderPredicate.completionMask == WLCalReminderCompletionMaskNothing)
        return @[];

    NSArray *csCalendars = nil;

    if (aReminderPredicate.calendarIdentifiers)
    {
        csCalendars = [self fetchCSCalendarsForUIDs:aReminderPredicate.calendarIdentifiers invalidUIDs:NULL];

        if (outCSCalendars)
            *outCSCalendars = csCalendars;

        if (csCalendars.count == 0)
            return @[];
    }

    NSArray *csReminders = @[];
    NSPredicate *p = nil;

    switch (aReminderPredicate.completionMask)
    {
        case WLCalReminderCompletionMaskComplete:
            p = [[self.calendarStore class] taskPredicateWithTasksCompletedSince:nil calendars:csCalendars];
            break;
        case WLCalReminderCompletionMaskIncomplete:
            p = [[self.calendarStore class] taskPredicateWithUncompletedTasks:csCalendars];
            break;
        case WLCalReminderCompletionMaskAny:
            p = [[self.calendarStore class] taskPredicateWithCalendars:csCalendars];
            break;
        case WLCalReminderCompletionMaskNothing:
            __builtin_unreachable();
            break;
    }

    if (p)
        csReminders = [self.calendarStore tasksWithPredicate:p];
    else
        [_log logError:@"Cannot make reminder predicate with parameters: {completionMask: %d, calendars: %@", aReminderPredicate.completionMask, csCalendars];

    return (csReminders != nil) ? csReminders : @[];
}

- (NSArray *)makeCalendarsFromCSCalendars:(NSArray *)aCSCalendars
{
    if (aCSCalendars.count == 0)
        return @[];

    NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:aCSCalendars.count];

    for (CalCalendar *csCalendar in aCSCalendars)
    {
        WLCalEntityMask allowedEntityTypes = [self allowedEntityTypesForCSCalendar:csCalendar];
        WLCalSystemCalendar *calendar = [[WLCalSystemCalendar alloc] initWithStore:self
                                                                        csCalendar:csCalendar
                                                                allowedEntityTypes:allowedEntityTypes];

        if (calendar)
            [calendars addObject:calendar];
    }

    return calendars;
}

- (WLCalEntityMask)allowedEntityTypesForCSCalendar:(CalCalendar *)aCalendar
{
    NSParameterAssert(aCalendar.uid);

    dispatch_semaphore_wait(_calendarTypeCacheSemaphore, DISPATCH_TIME_FOREVER);
    NSNumber *mask = _calendarTypeCache[aCalendar.uid];
    if (mask == nil)
    {
        WLCalEntityMask maskValue = [self _fastAllowedEntityTypesForCSCalendar:aCalendar];;

        if (maskValue == WLCalEntityMaskUnknown)
        {
            [_log logInfo:@"Fallback to slow check of calendar type for calendar %@.", aCalendar];
            [_log logInfo:@"If you experience crashes, try `defaults write net.wireload.blotter.mac WLCalSystemStoreAllowsAdvancedCalendarTypeCheck -bool NO`."];
            maskValue = [self _slowAllowedEntityTypesForCSCalendar:aCalendar];
        }

        if (maskValue == WLCalEntityMaskUnknown)
            [_log logWarning:@"Unable to determine type of calendar %@.", aCalendar];

        mask = @(maskValue);

        _calendarTypeCache[aCalendar.uid] = mask;
    }
    dispatch_semaphore_signal(_calendarTypeCacheSemaphore);

    return (WLCalEntityMask)mask.unsignedIntegerValue;
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
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *minus4Years = [[NSDateComponents alloc] init];
        minus4Years.year = -4;
        StartOf4YearsPeriod = [calendar dateByAddingComponents:minus4Years toDate:EndOf4YearsPeriod options:0];

        TmpItemsTitle = [NSString stringWithFormat:@"Quit %@ and delete me.", [NSProcessInfo processInfo].processName];
        TmpItemsNotes = [NSBundle mainBundle].bundleIdentifier;
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
    NSPredicate *p = [[self.calendarStore class] eventPredicateWithStartDate:StartOf4YearsPeriod
                                                                     endDate:EndOf4YearsPeriod
                                                                   calendars:@[aCalendar]];
    if (p)
        events = [self.calendarStore eventsWithPredicate:p];

    if (events.count > 0)
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
               error.code != CalCalendarNotEditableError)
        {
            if (currentAttempt > 0)
                [NSThread sleepForTimeInterval:AttemptDelay];

            canSaveEvent = [self.calendarStore saveEvent:tmpEvent span:CalSpanThisEvent error:&error];
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
                [_log logError:@"Cannot delete tmp event (%@): %@.", tmpEvent.uid, error.localizedDescription];

            allowedEntityTypes |= WLCalEntityMaskEvent;
        }
    }

    NSArray *reminders = @[];
    p = [[self.calendarStore class] taskPredicateWithCalendars:@[aCalendar]];
    if (p)
        reminders = [self.calendarStore tasksWithPredicate:p];

    if (reminders.count > 0)
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
               error.code != CalCalendarNotEditableError)
        {
            if (currentAttempt > 0)
                [NSThread sleepForTimeInterval:AttemptDelay];

            canSaveTask = [self.calendarStore saveTask:tmpReminder error:&error];
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
                [_log logError:@"Cannot delete tmp event (%@): %@.", tmpReminder.uid, error.localizedDescription];

            allowedEntityTypes |= WLCalEntityMaskReminder;
        }
    }

    return allowedEntityTypes;
}

- (void)_systemStoreDidChange:(NSNotification *)aNotification
{
    if ([aNotification.name isEqual:NSWorkspaceDidLaunchApplicationNotification])
    {
        static NSString* const iCalBundleIdentifier = @"com.apple.iCal";
        static NSString* const RemindersBundleIdentifier = @"com.apple.reminders";

        NSString *senderApplicationIdentifier = aNotification.userInfo[@"NSApplicationBundleIdentifier"];

        if (![senderApplicationIdentifier isEqual:iCalBundleIdentifier] &&
            ![senderApplicationIdentifier isEqual:RemindersBundleIdentifier])
        {
            return;
        }

        [_log logNotice:@"iCal/Calendars/Reminders was (re)launched."];
    }
    else if ([aNotification.name isEqual:EKEventStoreChangedNotification])
    {
        [_log logNotice:@"EKEventStore was changed."];
    }
    else
    {
        [_log logNotice:@"CalCalendarStore was changed."];
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyObservers) object:nil];
        [self performSelector:@selector(_notifyObservers) withObject:nil afterDelay:_WLAccumulateSystemNotificationsInterval];
    });
}

- (void)_notifyObservers
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WLCalStoreDidChangeNotification object:self];
}


#pragma mark SBApplicationDelegate

- (id)eventDidFail:(const AppleEvent *)anEvent withError:(NSError *)anError
{
    [_log logError:@"Scripting Bridge failed to deliver event: %@ (%@).", anError.localizedDescription, anError.userInfo];
    return nil;
}


#pragma mark WLCalStore

- (WLCalAuthorizationStatus)authorizationStatusForEntityType:(WLCalEntityType)aType
{
    return (WLCalAuthorizationStatus)[EKEventStore authorizationStatusForEntityType:(EKEntityType)aType];
}

- (NSArray *)calendars
{
    NSMutableArray *calendars = [NSMutableArray arrayWithArray:[self makeCalendarsFromCSCalendars:[self.calendarStore calendars]]];

    if (_checkCalendarsAgainstICal)
    {
        NSSet *u = [self iCalCalendarUIDs];
        NSArray *csCalendars = [self fetchCSCalendarsForUIDs:u invalidUIDs:NULL];
        [calendars addObjectsFromArray:[self makeCalendarsFromCSCalendars:csCalendars]];
    }

    [calendars sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalCalendarsComparator];
    [calendars WL_removeDuplicatesInSortedArrayUsingComparator:WLCalCalendarsComparator];

    return calendars;
}

- (id <WLCalCalendar>)calendarWithIdentifier:(NSString *)anIdentifier
{
    return [self makeCalendarsFromCSCalendars:@[[self.calendarStore calendarWithUID:anIdentifier]]].lastObject;
}

- (NSArray *)eventsMatchingPredicate:(WLCalEventsPredicate *)aPredicate
{
    NSArray *csCalendars = nil;
    // Calendar engines internally use Gregorian Calendar (see EKReminder documentation)
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSArray *csEvents = [self fetchCSEventsMatchingPredicate:aPredicate csCalednars:&csCalendars];

    NSMutableArray *cachedCalendars = [[self makeCalendarsFromCSCalendars:csCalendars] mutableCopy];
    [cachedCalendars sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalCalendarsComparator];
    [cachedCalendars WL_removeDuplicatesInSortedArrayUsingComparator:WLCalCalendarsComparator];

    NSMutableArray *events = [NSMutableArray arrayWithCapacity:csEvents.count];

    for (CalEvent *csEvent in csEvents)
    {
        WLCalSystemCalendar *calendar = nil;
        NSUInteger cachedCalendarIndex = [cachedCalendars indexOfObject:@{ @"calendarIdentifier" : csEvent.calendar.uid }
                                                          inSortedRange:NSMakeRange(0, cachedCalendars.count)
                                                                options:NSBinarySearchingFirstEqual
                                                        usingComparator:WLCalCalendarsComparator];

        if (cachedCalendarIndex != NSNotFound)
            calendar = cachedCalendars[cachedCalendarIndex];
        else
        {
            WLCalSystemCalendar *newCalendar = [self makeCalendarsFromCSCalendars:@[[self.calendarStore calendarWithUID:csEvent.calendar.uid]]].lastObject;

            if (newCalendar)
            {
                NSUInteger newCalendarInsertionIndex = [cachedCalendars indexOfObject:newCalendar
                                                                        inSortedRange:NSMakeRange(0, cachedCalendars.count)
                                                                              options:NSBinarySearchingInsertionIndex
                                                                      usingComparator:WLCalCalendarsComparator];
                [cachedCalendars insertObject:newCalendar atIndex:newCalendarInsertionIndex];

                calendar = newCalendar;
            }
        }

        if (calendar)
        {
            WLCalSystemEvent *event = [[WLCalSystemEvent alloc] initWithCSEvent:csEvent calCalendar:calendar currentCalendar:currentCalendar];

            if (event)
                [events addObject:event];
        }
    }

    [events sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalEventsComparator];
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

    NSMutableArray *reminders = [NSMutableArray arrayWithCapacity:csReminders.count];

    for (CalTask *csReminder in csReminders)
    {
        WLCalSystemCalendar *calendar = nil;
        NSUInteger cachedCalendarIndex = [cachedCalendars indexOfObject:@{ @"calendarIdentifier" : csReminder.calendar.uid }
                                                          inSortedRange:NSMakeRange(0, cachedCalendars.count)
                                                                options:NSBinarySearchingFirstEqual
                                                        usingComparator:WLCalCalendarsComparator];

        if (cachedCalendarIndex != NSNotFound)
            calendar = cachedCalendars[cachedCalendarIndex];
        else
        {
            WLCalSystemCalendar *newCalendar = [self makeCalendarsFromCSCalendars:@[[self.calendarStore calendarWithUID:csReminder.calendar.uid]]].lastObject;

            if (newCalendar)
            {
                NSUInteger newCalendarInsertionIndex = [cachedCalendars indexOfObject:newCalendar
                                                                        inSortedRange:NSMakeRange(0, cachedCalendars.count)
                                                                              options:NSBinarySearchingInsertionIndex
                                                                      usingComparator:WLCalCalendarsComparator];
                [cachedCalendars insertObject:newCalendar atIndex:newCalendarInsertionIndex];

                calendar = newCalendar;
            }
        }

        if (calendar)
        {
            WLCalSystemReminder *reminder = [[WLCalSystemReminder alloc] initWithCSReminder:csReminder calCalendar:calendar];

            if (reminder)
                [reminders addObject:reminder];
        }
    }

    [reminders sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:WLCalRemindersComparator];
    [reminders WL_removeDuplicatesInSortedArrayUsingComparator:WLCalRemindersComparator];

    return reminders;
}

- (NSString *)storeIdentifier
{
    return @"net.wireload.WLCalendarStore.System";
}


#pragma mark NSObject

- (BOOL)isEqual:(NSObject<WLCalStore> *)anObject
{
    if ([super isEqual:anObject])
        return YES;
    else if (![anObject conformsToProtocol:@protocol(WLCalStore)])
        return NO;
    else
        return [self.storeIdentifier isEqual:anObject.storeIdentifier];
}

- (NSUInteger)hash
{
    return (self.storeIdentifier).hash;
}

@end

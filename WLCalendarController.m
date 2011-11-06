//
//  WLCalendarData.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLCalendarController.h"
#import "IKPowerSources.h"
#import "NSArray+WLDelta.h"


@interface WLCalendarController (/*Private*/)

@property (nonatomic, retain) NSCalendar *calendar;

@property (nonatomic, retain) NSDate *date;

@property (nonatomic, copy) NSArray *calCalendars;

@property (nonatomic, copy) NSArray *calEventCalendars;

@property (nonatomic, copy) NSArray *calReminderCalendars;

@end


@implementation WLCalendarController

+ (void)initialize
{
    if (self == [WLCalendarController class])
    {
        // Delete calCalendars that are deleted from the CalCalendarStore.
        // Add new calCalendars that are added to the CalCalendarStore.
        NSMutableArray *calCalendarDicts = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"] mutableCopy] autorelease];
        NSMutableArray *calCalendarDictsToDelete = [[calCalendarDicts mutableCopy] autorelease];
        for (CalCalendar *c in [[CalCalendarStore defaultCalendarStore] calendars])
        {
            NSUInteger index = [calCalendarDicts indexOfObject:c
                                                 inSortedRange:NSMakeRange(0, [calCalendarDicts count])
                                                       options:NSBinarySearchingFirstEqual
                                               usingComparator:^(id left, id right)
            {
                return [[left valueForKey:@"uid"] compare:[right valueForKey:@"uid"]];;
            }];
            if (index != NSNotFound)
            {
                NSDictionary *calDict = [[[calCalendarDicts objectAtIndex:index] retain] autorelease];
                if ([calDict objectForKey:@"type"] == nil)
                {
                    // Add type to the dictionary.
                    NSMutableDictionary *d = [calDict mutableCopy];
                    [d setObject:[NSNumber numberWithUnsignedInteger:[c WL_type]] forKey:@"type"];
                    [calCalendarDicts replaceObjectAtIndex:index withObject:d];
                    [d release];
                }
                [calCalendarDictsToDelete removeObjectIdenticalTo:calDict];
            }
            else
            {
                NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                                   c.uid,                                               @"uid",
                                   [NSNumber numberWithBool:YES],                       @"check",
                                   [NSNumber numberWithUnsignedInteger:[c WL_type]],    @"type",
                                   nil];
                index = [calCalendarDicts indexOfObject:d
                                          inSortedRange:NSMakeRange(0, [calCalendarDicts count])
                                                options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                        usingComparator:^(id left, id right)
                {
                    return [[left valueForKey:@"uid"] compare:[right valueForKey:@"uid"]];;
                }];
                [calCalendarDicts insertObject:d atIndex:index];
            }
        }
        [calCalendarDicts removeObjectsInArray:calCalendarDictsToDelete];
        [[NSUserDefaults standardUserDefaults] setObject:calCalendarDicts forKey:@"Calendars"];
    }
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

        calendar = [[NSCalendar autoupdatingCurrentCalendar] retain];
        date = [[NSDate date] retain];
        calCalendars = [[self _calCalendarsToDisplay] mutableCopy];
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
                       forKeyPath:@"Calendars"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        [userDefaults addObserver:self
                       forKeyPath:@"DisplayAllCalendars"
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
    [calCalendars release];
    [calEventCalendars release];
    [calReminderCalendars release];
    [_nextMinuteTimer invalidate];
    [_nextDayTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:@"Calendars"];
    [userDefaults removeObserver:self forKeyPath:@"DisplayAllCalendars"];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendar;
@synthesize date;
@synthesize calCalendars;
@synthesize calEventCalendars;
@synthesize calReminderCalendars;

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
    self.calendar = [NSCalendar autoupdatingCurrentCalendar];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (void)updateDate
{
    self.date = [NSDate date];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    NSMutableArray *eventCalendars = [NSMutableArray array];
    NSArray *calCalendarDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"];
    for (CalCalendar *c in aCalCalendars)
    {
        NSUInteger index = [calCalendarDicts indexOfObject:c
                                             inSortedRange:NSMakeRange(0, [calCalendarDicts count])
                                                   options:NSBinarySearchingFirstEqual
                                           usingComparator:^(id left, id right)
        {
            return [[left valueForKey:@"uid"] compare:[right valueForKey:@"uid"]];
        }];
        WLCalendarType type = 0;
        if (index != NSNotFound)
            type = [[[calCalendarDicts objectAtIndex:index] objectForKey:@"type"] unsignedIntegerValue];

        if (type == WLCalendarUnknownType)
        {
            // Calendar may be changed since last time we updated user defaults it.
            NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
            [n removeObserver:self name:CalCalendarsChangedNotification object:[CalCalendarStore defaultCalendarStore]];
            [n removeObserver:self name:CalCalendarsChangedExternallyNotification object:[CalCalendarStore defaultCalendarStore]];
            type = [c WL_type];
            [n addObserver:self
                  selector:@selector(_calCalendarsDidChange:)
                      name:CalCalendarsChangedNotification
                    object:[CalCalendarStore defaultCalendarStore]];
            [n addObserver:self
                  selector:@selector(_calCalendarsDidChange:)
                      name:CalCalendarsChangedExternallyNotification
                    object:[CalCalendarStore defaultCalendarStore]];
        }
        switch (type)
        {
            case WLCalendarEventType:
            case WLCalendarBothType:
                [eventCalendars addObject:c];
            case WLCalendarUnknownType:
            case WLCalendarReminderType:
                continue;
        }
    }
    return eventCalendars;
}

- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    NSMutableArray *reminderCalendars = [NSMutableArray array];
    NSArray *calCalendarDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"];
    for (CalCalendar *c in aCalCalendars)
    {
        NSUInteger index = [calCalendarDicts indexOfObject:c
                                             inSortedRange:NSMakeRange(0, [calCalendarDicts count])
                                                   options:NSBinarySearchingFirstEqual
                                           usingComparator:^(id left, id right)
    {
        return [[left valueForKey:@"uid"] compare:[right valueForKey:@"uid"]];
    }];
        WLCalendarType type = 0;
        if (index != NSNotFound)
            type = [[[calCalendarDicts objectAtIndex:index] objectForKey:@"type"] unsignedIntegerValue];

        if (type == WLCalendarUnknownType)
        {
            // Calendar may be changed since last time we updated user defaults it.
            NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
            // We don't want blotter to be notified of any changes applied in WL_type.
            [n removeObserver:self name:CalCalendarsChangedNotification object:[CalCalendarStore defaultCalendarStore]];
            [n removeObserver:self name:CalCalendarsChangedExternallyNotification object:[CalCalendarStore defaultCalendarStore]];
            type = [c WL_type];
            [n addObserver:self
                  selector:@selector(_calCalendarsDidChange:)
                      name:CalCalendarsChangedNotification
                    object:[CalCalendarStore defaultCalendarStore]];
            [n addObserver:self
                  selector:@selector(_calCalendarsDidChange:)
                      name:CalCalendarsChangedExternallyNotification
                    object:[CalCalendarStore defaultCalendarStore]];
        }
        switch (type)
        {
            case WLCalendarReminderType:
            case WLCalendarBothType:
                [reminderCalendars addObject:c];
            case WLCalendarEventType:
            case WLCalendarUnknownType:
                continue;
        }
    }
    return reminderCalendars;
}


#pragma mark Private

- (void)_localeDidChange:(NSNotification *)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCalendar) object:nil];
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0f;
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

    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [self.calendar components:NSWeekCalendarUnit | NSDayCalendarUnit fromDate:now];
    NSDateComponents *representedComponents = [calendar components:NSWeekCalendarUnit | NSDayCalendarUnit fromDate:self.date];
    // Though accuracy of NSTimer is documented as 50-100ms, we must ensure day is actually changed.
    if ([nowComponents day] != [representedComponents day] || [nowComponents week] != [representedComponents week])
    {
        [self updateDate];
    }
    else
        [self performSelector:@selector(_nextDayTimerDidFire) withObject:nil afterDelay:0.1];
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
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDate) object:nil];
        [self performSelector:@selector(updateDate) withObject:nil afterDelay:0.5];
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
    NSMutableArray *calCalendarDicts = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"] mutableCopy] autorelease];
    NSArray *deletedCalCalendarUIDs = [[aNotification userInfo] objectForKey:CalDeletedRecordsKey];
    for (NSString *uid in deletedCalCalendarUIDs)
    {
        NSUInteger index = [calCalendarDicts indexOfObject:[NSDictionary dictionaryWithObject:uid forKey:@"uid"]
                                             inSortedRange:NSMakeRange(0, [calCalendarDicts count])
                                                   options:NSBinarySearchingFirstEqual
                                           usingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2)
                            {
                                return [[obj1 objectForKey:@"uid"] compare:[obj2 objectForKey:@"uid"]];
                            }];
        if (index != NSNotFound)
            [calCalendarDicts removeObjectAtIndex:index];
    }

    NSArray *insertedCalCalendarUIDs = [[aNotification userInfo] objectForKey:CalInsertedRecordsKey];
    for (NSString *uid in insertedCalCalendarUIDs)
    {
        NSUInteger index = [calCalendarDicts indexOfObject:[NSDictionary dictionaryWithObject:uid forKey:@"uid"]
                                             inSortedRange:NSMakeRange(0, [calCalendarDicts count])
                                                   options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                           usingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2)
                            {
                                return [[obj1 objectForKey:@"uid"] compare:[obj2 objectForKey:@"uid"]];
                            }];
        CalCalendar *c = [[CalCalendarStore defaultCalendarStore] calendarWithUID:uid];
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           c.uid,                                               @"uid",
                           [NSNumber numberWithBool:YES],                       @"check",
                           [NSNumber numberWithUnsignedInteger:[c WL_type]],    @"type",
                           nil];
        [calCalendarDicts insertObject:d atIndex:index];
    }
    [[NSUserDefaults standardUserDefaults] setObject:calCalendarDicts forKey:@"Calendars"];
}

- (NSArray *)_calCalendarsToDisplay
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayAllCalendars"])
        return [[[CalCalendarStore defaultCalendarStore] calendars] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES]]];
    else
    {
        NSArray *selectedCalCalendarDicts = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Calendars"];
        NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:[selectedCalCalendarDicts count]];
        for (NSDictionary *d in selectedCalCalendarDicts)
        {
            if ([[d objectForKey:@"check"] boolValue])
            {
                CalCalendar *c = [[CalCalendarStore defaultCalendarStore] calendarWithUID:[d objectForKey:@"uid"]];
                if (c != nil)
                    [calendars addObject:c];
            }
        }
        return calendars;
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"DisplayAllCalendars"] || [aKeyPath isEqualToString:@"Calendars"])
    {
        NSIndexSet *inserted = nil;
        NSIndexSet *deleted = nil;
        NSIndexSet *updated = nil;
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES]];

        // Update calCalendars
        NSArray *calCalendarsToDisplay = [self _calCalendarsToDisplay];
        [calCalendars WL_indexesOfDeletedObject:&deleted
                       indexesOfInsertedObjects:&inserted
                        indexesOfUpdatedObjects:&updated
                                  toSortedArray:calCalendarsToDisplay
                                sortDescriptors:sortDescriptors
                                  updateChecker:^BOOL(CalCalendar *aFromArrayObject, CalCalendar *aToArrayObject)
        {
            return (![aFromArrayObject.color isEqual:aToArrayObject.color] ||
                    ![aFromArrayObject.title isEqual:aToArrayObject.title]);
        }];

        if ([deleted count] > 0)
        {
            [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:@"calCalendars"];
            [calCalendars removeObjectsAtIndexes:deleted];
            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:@"calCalendars"];
        }

        if ([inserted count] > 0)
        {
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:@"calCalendars"];
            [calCalendars insertObjects:[calCalendarsToDisplay objectsAtIndexes:inserted] atIndexes:inserted];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:@"calCalendars"];
        }

        if ([updated count] > 0)
        {
            [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:@"calCalendars"];
            [calCalendars replaceObjectsAtIndexes:updated withObjects:[calCalendarsToDisplay objectsAtIndexes:updated]];
            [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:@"calCalendars"];
        }

        // Update calEventCalendars
        inserted = nil;
        deleted = nil;
        updated = nil;
        NSArray *calEventCalendarsToDisplay = [self calEventCalendarsFromCalCalendars:calCalendarsToDisplay];
        [calEventCalendars WL_indexesOfDeletedObject:&deleted
                            indexesOfInsertedObjects:&inserted
                             indexesOfUpdatedObjects:&updated
                                       toSortedArray:calEventCalendarsToDisplay
                                     sortDescriptors:sortDescriptors
                                       updateChecker:^BOOL(CalCalendar *aFromArrayObject, CalCalendar *aToArrayObject)
        {
            return (![aFromArrayObject.color isEqual:aToArrayObject.color] ||
                    ![aFromArrayObject.title isEqual:aToArrayObject.title]);
        }];

        if ([deleted count] > 0)
        {
            [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:@"calEventCalendars"];
            [calEventCalendars removeObjectsAtIndexes:deleted];
            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:@"calEventCalendars"];
        }

        if ([inserted count] > 0)
        {
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:@"calEventCalendars"];
            [calEventCalendars insertObjects:[calEventCalendarsToDisplay objectsAtIndexes:inserted] atIndexes:inserted];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:@"calEventCalendars"];
        }

        if ([updated count] > 0)
        {
            [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:@"calEventCalendars"];
            [calEventCalendars replaceObjectsAtIndexes:updated withObjects:[calEventCalendarsToDisplay objectsAtIndexes:updated]];
            [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:@"calEventCalendars"];
        }

        // Update calReminderCalendars
        inserted = nil;
        deleted = nil;
        updated = nil;
        NSArray *calReminderCalendarsToDisplay = [self calReminderCalendarsFromCalCalendars:calCalendarsToDisplay];
        [calReminderCalendars WL_indexesOfDeletedObject:&deleted
                                    indexesOfInsertedObjects:&inserted
                                     indexesOfUpdatedObjects:&updated
                                               toSortedArray:calReminderCalendarsToDisplay
                                             sortDescriptors:sortDescriptors
                                               updateChecker:^BOOL(CalCalendar *aFromArrayObject, CalCalendar *aToArrayObject)
        {
            return (![aFromArrayObject.color isEqual:aToArrayObject.color] ||
                    ![aFromArrayObject.title isEqual:aToArrayObject.title]);
        }];

        if ([deleted count] > 0)
        {
            [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:@"calReminderCalendars"];
            [calReminderCalendars removeObjectsAtIndexes:deleted];
            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:deleted forKey:@"calReminderCalendars"];
        }

        if ([inserted count] > 0)
        {
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:@"calReminderCalendars"];
            [calReminderCalendars insertObjects:[calReminderCalendarsToDisplay objectsAtIndexes:inserted] atIndexes:inserted];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:inserted forKey:@"calReminderCalendars"];
        }

        if ([updated count] > 0)
        {
            [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:@"calReminderCalendars"];
            [calReminderCalendars replaceObjectsAtIndexes:updated withObjects:[calReminderCalendarsToDisplay objectsAtIndexes:updated]];
            [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:updated forKey:@"calReminderCalendars"];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


NSString* const WLTempEventNotes = @"net.wireload.blotter.tempevent";

NSString* const WLTempTaskNotes = @"net.wireload.blotter.temptask";


@implementation CalCalendar (WLCalendarController)

- (WLCalendarType)WL_type
{
    static const NSUInteger MaximumNumberOfAttemptsToAddOrDelete = 5;
    static const NSTimeInterval AttemptDelay = 0.1;

    WLCalendarType type = 0;

    NSPredicate *allEventsPredicate = [CalCalendarStore eventPredicateWithStartDate:[NSDate distantPast]
                                                                            endDate:[NSDate distantFuture]
                                                                          calendars:[NSArray arrayWithObject:self]];
    NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:allEventsPredicate];
    if ([events count] > 0)
        type |= WLCalendarEventType;
    else
    {
        CalEvent *tmpEvent = [CalEvent event];
        tmpEvent.calendar = self;
        tmpEvent.notes = WLTempEventNotes;
        tmpEvent.title = @"Blotter's tmp event";
        tmpEvent.startDate = [NSDate date];
        tmpEvent.endDate = [[NSDate date] dateByAddingTimeInterval:1];
        NSError *error = nil;
        BOOL canSaveEvent = NO;
        NSUInteger currentAttempt = 0;
        while (self.isEditable &&
               currentAttempt < MaximumNumberOfAttemptsToAddOrDelete &&
               !canSaveEvent &&
               [error code] != CalCalendarNotEditableError)
        {
            if (currentAttempt > 0)
                [NSThread sleepForTimeInterval:AttemptDelay];
            canSaveEvent = [[CalCalendarStore defaultCalendarStore] saveEvent:tmpEvent span:CalSpanThisEvent error:&error];
            ++currentAttempt;
        }
        if (canSaveEvent)
        {
            currentAttempt = 0;
            while (currentAttempt < MaximumNumberOfAttemptsToAddOrDelete)
            {
                if (currentAttempt > 0)
                    [NSThread sleepForTimeInterval:AttemptDelay];
                if ([[CalCalendarStore defaultCalendarStore] removeEvent:tmpEvent span:CalSpanThisEvent error:&error])
                    break;
                ++currentAttempt;
            }
            if (currentAttempt == MaximumNumberOfAttemptsToAddOrDelete)
                NSLog(@"Unable to delete event: %@\nError:%@", tmpEvent, error);
            type |= WLCalendarEventType;
        }
    }

    NSPredicate *allRemindersPredicate = [CalCalendarStore taskPredicateWithCalendars:[NSArray arrayWithObject:self]];
    NSArray *reminders = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:allRemindersPredicate];
    if ([reminders count] > 0)
        type |= WLCalendarReminderType;
    else
    {
        CalTask *tmpReminder = [CalTask task];
        tmpReminder.notes = WLTempTaskNotes;
        tmpReminder.calendar = self;
        tmpReminder.title = @"Blotter's tmp task";
        tmpReminder.isCompleted = YES;
        tmpReminder.dueDate = [[NSDate date] dateByAddingTimeInterval:1];
        tmpReminder.priority = CalPriorityNone;
        NSError *error = nil;
        BOOL canSaveTask = NO;
        NSUInteger currentAttempt = 0;
        while (self.isEditable &&
               currentAttempt < MaximumNumberOfAttemptsToAddOrDelete &&
               !canSaveTask &&
               [error code] != CalCalendarNotEditableError)
        {
            if (currentAttempt > 0)
                [NSThread sleepForTimeInterval:AttemptDelay];
            canSaveTask = [[CalCalendarStore defaultCalendarStore] saveTask:tmpReminder error:&error];
            ++currentAttempt;
        }
        if (canSaveTask)
        {
            currentAttempt = 0;
            while (currentAttempt < MaximumNumberOfAttemptsToAddOrDelete)
            {
                if (currentAttempt > 0)
                    [NSThread sleepForTimeInterval:AttemptDelay];
                if ([[CalCalendarStore defaultCalendarStore] removeTask:tmpReminder error:&error])
                    break;
                ++currentAttempt;
            }
            if (currentAttempt == MaximumNumberOfAttemptsToAddOrDelete)
                NSLog(@"Unable to delete task: %@\nError:%@", tmpReminder, error);
            type |= WLCalendarReminderType;
        }
    }
    return type;
}


@end
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
                    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [calDict objectForKey:@"uid"],                       @"uid",
                                       [calDict objectForKey:@"check"],                     @"check",
                                       [NSNumber numberWithUnsignedInteger:[c WL_type]],    @"type",
                                       nil];
                    [calCalendarDicts replaceObjectAtIndex:index withObject:d];
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

        calendar = [[NSCalendar autoupdatingCurrentCalendar] retain];
        date = [[NSDate date] retain];
        calCalendars = [[self _calendarsToDisplay] copy];
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
        NSUInteger index = [aCalCalendars indexOfObject:c
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
            type = [c WL_type];
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
    return nil;
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
    NSArray *deletedCalCalendarUIDs = [[aNotification userInfo] objectForKey:CalDeletedRecordsKey];
    NSArray *insertedCalCalendarUIDs = [[aNotification userInfo] objectForKey:CalInsertedRecordsKey];
    if ([deletedCalCalendarUIDs count] == 0 && [insertedCalCalendarUIDs count] == 0)
        return;

    NSMutableArray *calCalendarDicts = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"] mutableCopy] autorelease];

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

- (NSArray *)_calendarsToDisplay
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayAllCalendars"])
        return [[CalCalendarStore defaultCalendarStore] calendars];
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
        self.calCalendars = [self _calendarsToDisplay];
        self.calEventCalendars = [self calEventCalendarsFromCalCalendars:self.calEventCalendars];
        self.calReminderCalendars = [self calReminderCalendarsFromCalCalendars:self.calEventCalendars];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation CalCalendar (WLCalendarController)

- (WLCalendarType)WL_type
{
    static const NSUInteger MaximumNumberOfAttemptsToAddOrDelete = 5;
    static const NSTimeInterval AttemptDelay = 0.1;

    WLCalendarType type = 0;

    CalEvent *tmpEvent = [CalEvent event];
    tmpEvent.calendar = self;
    tmpEvent.title = @"Blotter's tmp event";
    tmpEvent.startDate = [NSDate distantPast];
    tmpEvent.endDate = [[NSDate distantPast] dateByAddingTimeInterval:1];
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
    else
    {
        // If the calendar has events it conforms to WLCalendarEventType.
        NSPredicate *allEventsPredicate = [CalCalendarStore eventPredicateWithStartDate:[NSDate distantPast]
                                                                                endDate:[NSDate distantFuture]
                                                                              calendars:[NSArray arrayWithObject:self]];
        NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:allEventsPredicate];
        if ([events count] > 0)
            type |= WLCalendarEventType;
    }

    CalTask *tmpReminder = [CalTask task];
    tmpReminder.calendar = self;
    tmpReminder.title = @"Blotter's tmp task";
    // To hide task from Blotter, mark it completed.
    tmpReminder.isCompleted = YES;
    // To hide it from other apps which could monitor due date.
    tmpReminder.dueDate = [NSDate distantFuture];
    tmpReminder.priority = CalPriorityNone;
    error = nil;
    BOOL canSaveTask = NO;
    currentAttempt = 0;
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
    else
    {
        // If the calendar has tasks it conforms to WLCalendarReminderType.
        NSPredicate *allRemindersPredicate = [CalCalendarStore taskPredicateWithCalendars:[NSArray arrayWithObject:self]];
        NSArray *tasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:allRemindersPredicate];
        if ([tasks count] > 0)
            type |= WLCalendarReminderType;
    }
    return type;
}


@end
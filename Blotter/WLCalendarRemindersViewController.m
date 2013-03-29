//
//  WLCalendarRemindersViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 09.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarRemindersViewController.h"
#import "WLCalendarController.h"


@implementation WLCalendarRemindersViewController
{
    NSMutableArray *_reminders;
    NSComparator _comparator;
    dispatch_semaphore_t _comparatorSemaphore;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self)
    {
        _reminders = [NSMutableArray array];
        _comparatorSemaphore = dispatch_semaphore_create(1);
    }

    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(remindersComparatorDidChange) object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_release(_comparatorSemaphore);
}


#pragma mark Methods

- (void)setReminders:(NSArray *)newReminders sortedUsingComparator:(NSComparator)aComparator animated:(BOOL)isAnimated
{
    if (self.isViewLoaded)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:!isAnimated];

        // Update
        NSMutableArray *indexesOfOldReminders = [NSMutableArray array];
        NSMutableArray *indexesOfNewObjects = [NSMutableArray array];
        dispatch_semaphore_t s = dispatch_semaphore_create(1);
        [_reminders enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSObject<WLCalReminder> *oldReminder, NSUInteger oldReminderIndex, BOOL *stop)
        {
            NSUInteger newReminderIndex = [newReminders indexOfObjectWithOptions:NSEnumerationConcurrent
                                                                     passingTest:^BOOL(NSObject<WLCalReminder> *newReminder, NSUInteger i, BOOL *stop2)
            {
                return [newReminder.calendar.calendarIdentifier isEqualToString:oldReminder.calendar.calendarIdentifier] &&
                       [newReminder.itemIdentifier isEqualToString:oldReminder.itemIdentifier];
            }];

            if (newReminderIndex != NSNotFound && ![oldReminder isEqual:newReminders[newReminderIndex]])
            {
                dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER);
                [indexesOfOldReminders addObject:@(oldReminderIndex)];
                [indexesOfNewObjects addObject:@(newReminderIndex)];
                dispatch_semaphore_signal(s);
            }
        }];
        dispatch_release(s);

        NSParameterAssert([indexesOfOldReminders count] == [indexesOfNewObjects count]);

        [indexesOfOldReminders enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger i, BOOL *stop)
        {
            NSUInteger oldReminderIndexValue = [obj unsignedIntegerValue];
            NSUInteger newReminderIndexValue = [indexesOfNewObjects[i] unsignedIntegerValue];
            [_reminders replaceObjectAtIndex:oldReminderIndexValue
                                  withObject:newReminders[newReminderIndexValue]];
            [(WLCalendarRemindersView *)self.view updateReminderAtIndex:oldReminderIndexValue];
        }];

        // Move
        NSArray *unsortedOldReminders = [_reminders copy];
        NSArray *sortedOldReminders = [_reminders sortedArrayWithOptions:NSSortStable usingComparator:aComparator];
        [unsortedOldReminders enumerateObjectsUsingBlock:^(NSObject<WLCalReminder> *aReminder, NSUInteger idx, BOOL *stop)
        {
            NSUInteger oldReminderIndex = [_reminders indexOfObjectIdenticalTo:aReminder];
            NSUInteger newReminderIndex = [sortedOldReminders indexOfObjectIdenticalTo:aReminder];

            if (newReminderIndex != oldReminderIndex)
            {
                [_reminders removeObjectAtIndex:oldReminderIndex];
                [_reminders insertObject:aReminder atIndex:newReminderIndex];
                [(WLCalendarRemindersView *)self.view moveReminderAtIndex:oldReminderIndex toIndex:newReminderIndex];
            }
        }];

        // Delete old and Insert new
        __autoreleasing NSIndexSet *deleted = nil;
        __autoreleasing NSIndexSet *inserted = nil;
        [_reminders WL_indexesOfDeletedObjects:&deleted
                      indexesOfInsertedObjects:&inserted
                               relativeToArray:newReminders
                         sortedUsingComparator:aComparator];

        [deleted enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop)
        {
            [_reminders removeObjectAtIndex:idx];
            [(WLCalendarRemindersView *)self.view removeReminderAtIndex:idx];
        }];

        [inserted enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
        {
            [_reminders insertObject:newReminders[idx] atIndex:idx];
            [(WLCalendarRemindersView *)self.view insertReminderAtIndex:idx];
        }];
        [CATransaction commit];
    }
    else
        [_reminders setArray:newReminders];

    _comparator = [aComparator copy];
}

- (NSComparator)makeRemindersComparator
{
    NSCalendar *floatingCalendar = nil;

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        floatingCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        floatingCalendar.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        floatingCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    else
    {
        floatingCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        floatingCalendar.locale = [NSLocale currentLocale];
        floatingCalendar.timeZone = [NSTimeZone systemTimeZone];
    }

    return ^NSComparisonResult(NSObject<WLCalReminder> *r1, NSObject<WLCalReminder> *r2)
    {
        if ([r1 isEqual:r2])
            return NSOrderedSame;

        // dueDate
        NSDate *dueDate1 = nil;
        NSDate *dueDate2 = nil;

        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        {
            if (r1.dueDateComponents)
                dueDate1 = [floatingCalendar dateFromComponents:r1.dueDateComponents];

            if (r2.dueDateComponents)
                dueDate2 = [floatingCalendar dateFromComponents:r2.dueDateComponents];
        }
        else
        {
            NSDateComponents *components1 = [r1.dueDateComponents copy];
            NSDateComponents *components2 = [r2.dueDateComponents copy];

            if (!components1.calendar)
                components1.calendar = floatingCalendar;

            if (!components1.timeZone)
                components1.timeZone = floatingCalendar.timeZone;

            if (!components2.calendar)
                components2.calendar = floatingCalendar;

            if (!components2.timeZone)
                components2.timeZone = floatingCalendar.timeZone;

            dueDate1 = components1.date;
            dueDate2 = components2.date;
        }

        if (!dueDate1)
            dueDate1 = [NSDate distantFuture];

        if (!dueDate2)
            dueDate2 = [NSDate distantFuture];

        NSComparisonResult r = [dueDate1 compare:dueDate2];

        if (r != NSOrderedSame)
            return r;

        // priority
        WLCalPriority priority1 = r1.priority;
        WLCalPriority priority2 = r2.priority;

        if (priority1 != priority2)
        {
            if (priority1 == WLCalPriorityNone)
                return NSOrderedDescending;
            else if (priority2 == WLCalPriorityNone)
                return NSOrderedAscending;
            else
                r = priority1 < priority2 ? NSOrderedAscending : NSOrderedDescending;
        }
        else
            r = NSOrderedSame;

        if (r != NSOrderedSame)
            return r;

        // calendar title
        r = [r1.calendar.title localizedStandardCompare:r2.calendar.title];

        if (r != NSOrderedSame)
            return r;

        // title
        r = [r1.title localizedStandardCompare:r2.title];

        if (r != NSOrderedSame)
            return r;

        // UID
        r = [r1.itemIdentifier compare:r2.itemIdentifier];

        if (r != NSOrderedSame)
            return r;

        return WLCalRemindersComparator(r1, r2);
    };
}

- (void)remindersDidChange:(NSNotification *)aNotification
{
    dispatch_semaphore_wait(_comparatorSemaphore, DISPATCH_TIME_FOREVER);
    NSComparator c = _comparator;

    if (!c)
        c = [self makeRemindersComparator];

    NSArray *r = [[aNotification userInfo][@(WLCalReminderCompletionMaskIncomplete)] sortedArrayWithOptions:NSSortStable
                                                                                            usingComparator:c];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self setReminders:r sortedUsingComparator:c animated:YES];
    });
    dispatch_semaphore_signal(_comparatorSemaphore);
}

- (void)timeZoneDidChange:(NSNotification *)aNotification
{
    [NSTimeZone resetSystemTimeZone];
    [self remindersComparatorDidChange];
}

- (void)localeDidChange:(NSNotification *)aNotification
{
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the System Preferences).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0;
    [self performSelector:@selector(remindersComparatorDidChange) withObject:nil afterDelay:AnyDelay];
}

- (void)remindersComparatorDidChange
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(remindersComparatorDidChange) object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_semaphore_wait(_comparatorSemaphore, DISPATCH_TIME_FOREVER);
        NSComparator c = [self makeRemindersComparator];
        NSArray *reminders = [_reminders sortedArrayWithOptions:NSSortStable usingComparator:c];
        [self setReminders:reminders sortedUsingComparator:c animated:YES];
        dispatch_semaphore_signal(_comparatorSemaphore);
    });
}


#pragma mark WLCalendarTasksViewDataSource

- (NSUInteger)numberOfRemindersInRemindersView:(WLCalendarRemindersView *)aTasksView
{
    return [_reminders count];
}

- (NSObject <WLCalReminder> *)remindersView:(WLCalendarRemindersView *)aTasksView reminderAtIndex:(NSUInteger)anIndex
{
    return [_reminders objectAtIndex:anIndex];
}


#pragma mark NSViewController

- (void)loadView
{
    WLCalendarRemindersView *v = [[WLCalendarRemindersView alloc] initWithFrame:NSZeroRect];
    v.dataSource = self;
    [v makeLayers];
    self.view = v;
    [CATransaction WL_performWithDisabledActions:^{
        [(WLCalendarRemindersView *)self.view reloadData];
    }];
}

- (void)setRepresentedObject:(id)newRepresentedObject
{
    if (self.representedObject)
    {
        [self.representedObject removeObservedCompletionMask:WLCalReminderCompletionMaskIncomplete];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

    super.representedObject = newRepresentedObject;

    if (self.representedObject)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(remindersDidChange:)
                                                     name:WLCalendarRemindersDidChangeNotification
                                                   object:newRepresentedObject];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(timeZoneDidChange:)
                                                     name:NSSystemTimeZoneDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(localeDidChange:)
                                                     name:NSCurrentLocaleDidChangeNotification
                                                   object:nil];
        [newRepresentedObject addObservedCompletionMask:WLCalReminderCompletionMaskIncomplete];
    }
}

@end

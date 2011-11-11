//
//  WLCalendarTasksViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 09.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTasksViewController.h"


@implementation WLCalendarTasksViewController

- (void)dealloc
{
    [sortDescriptors release];
    [_tasks release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Properties
@synthesize sortDescriptors;

- (void)setSortDescriptors:(NSArray *)newDescriptors
{
    [sortDescriptors release];
    sortDescriptors = [newDescriptors copy];
    if (_isViewLoaded)
        [self fetchTasksAndReloadViewDataAnimated:YES];
}


#pragma mark Methods

- (void)fetchTasksAndReloadViewDataAnimated:(BOOL)isAnimated
{
    NSParameterAssert([sortDescriptors count] > 0);

    [_tasks release];
    NSPredicate *p = [CalCalendarStore taskPredicateWithUncompletedTasks:[[self representedObject] calReminderCalendars]];
    _tasks = [[[CalCalendarStore defaultCalendarStore] tasksWithPredicate:p] mutableCopy];
    [_tasks makeObjectsPerformSelector:@selector(WL_fixPriorityAndDueDate)];
    [_tasks sortUsingDescriptors:self.sortDescriptors];
    [[self view] reloadDataAnimated:isAnimated];
}


#pragma mark Private

- (void)_calTasksDidChange:(NSNotification *)aNotification
{
    NSParameterAssert([sortDescriptors count] > 0);

    NSMutableArray *insertedTaskUIDs = [NSMutableArray arrayWithArray:[[aNotification userInfo] objectForKey:CalInsertedRecordsKey]];
    NSArray *updatedTaskUIDs = [[aNotification userInfo] objectForKey:CalUpdatedRecordsKey];
    NSMutableArray *deletedTaskUIDs = [NSMutableArray arrayWithArray:[[aNotification userInfo] objectForKey:CalDeletedRecordsKey]];
    NSPredicate *calendarPredicate = [NSPredicate predicateWithFormat:@"(calendar in %@) AND (isCompleted == NO)", [[self representedObject] calReminderCalendars]];

    [CATransaction begin];
    static const NSInteger CurrentCalendarIsChecked = 1 << 0;
    static const NSInteger CurrentCalendarIsUnchecked = 1 << 1;
    static const NSInteger PreviousCalendarIsChecked = 1 << 2;
    static const NSInteger PreviousCalendarIsUnchecked = 1 << 3;
    for (NSString *taskUID in updatedTaskUIDs)
    {
        NSInteger mode = 0;
        CalTask *updatedTask = [[CalCalendarStore defaultCalendarStore] taskWithUID:taskUID];
        if (![calendarPredicate evaluateWithObject:updatedTask])
            mode |= CurrentCalendarIsUnchecked;
        else
            mode |= CurrentCalendarIsChecked;
        NSUInteger oldIndex = [_tasks indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return [[obj uid] isEqualToString:taskUID];
        }];
        if (oldIndex == NSNotFound)
            mode |= PreviousCalendarIsUnchecked;
        else
            mode |= PreviousCalendarIsChecked;

        if ((mode & PreviousCalendarIsChecked) && (mode & CurrentCalendarIsChecked))
        {
            // Continue normal execution.
        }
        else if ((mode & PreviousCalendarIsUnchecked) && (mode & CurrentCalendarIsUnchecked))
        {
            // Task must not appear.
            continue;
        }
        else if ((mode & PreviousCalendarIsUnchecked) && (mode & CurrentCalendarIsChecked))
        {
            [insertedTaskUIDs addObject:taskUID];
            continue;
        }
        else/* ((mode & PreviousCalendarIsChecked) && (mode & CurrentCalendarIsUnchecked)) */
        {
            [deletedTaskUIDs addObject:taskUID];
            continue;
        }

        NSAssert(oldIndex != NSNotFound, @"Index of the removed item must not be NSNotFound at this point: %d", mode);

        [_tasks removeObjectAtIndex:oldIndex];
        [updatedTask WL_fixPriorityAndDueDate];
        NSUInteger newIndex = [_tasks indexOfObject:updatedTask
                                      inSortedRange:NSMakeRange(0, [_tasks count])
                                            options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                    usingComparator:^(id obj1, id obj2)
        {
            NSComparisonResult result = NSOrderedSame;
            for (NSSortDescriptor *descriptor in sortDescriptors)
            {
                result = [descriptor compareObject:obj1 toObject:obj2];
                if (result != NSOrderedSame)
                    break;
            }
            return result;
        }];
        [_tasks insertObject:updatedTask atIndex:newIndex];
        [[self view] moveTaskAtIndex:oldIndex toIndex:newIndex];
        [[self view] updateTaskAtIndex:newIndex];
    }
    for (NSString *taskUID in deletedTaskUIDs)
    {
        NSUInteger index = [_tasks indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
        {
            return [[obj uid] isEqualToString:taskUID];
        }];
        if (index == NSNotFound)
        {
            // Due to timings problem caused by WLCalendarController and iCal, delete may be posted before insert.
            continue;
        }
        [_tasks removeObjectAtIndex:index];
        [[self view] removeTaskAtIndex:index];
    }
    for (NSString *taskUID in insertedTaskUIDs)
    {
        CalTask *newTask = [[CalCalendarStore defaultCalendarStore] taskWithUID:taskUID];
        if (![calendarPredicate evaluateWithObject:newTask])
            continue;
        [newTask WL_fixPriorityAndDueDate];
        NSUInteger index = [_tasks indexOfObject:newTask
                                   inSortedRange:NSMakeRange(0, [_tasks count])
                                         options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                 usingComparator:^(CalTask *task1, CalTask *task2)
        {
            NSComparisonResult result = NSOrderedSame;
            for (NSSortDescriptor *descriptor in sortDescriptors)
            {
                result = [descriptor compareObject:task1 toObject:task2];
                if (result != NSOrderedSame)
                    break;
            }
            return result;
        }];
        [_tasks insertObject:newTask atIndex:index];
        [[self view] insertTaskAtIndex:index];
    }
    [CATransaction commit];
}


#pragma mark WLCalendarTasksViewDataSource

- (NSUInteger)numberOfTasksInTasksView:(WLCalendarTasksView *)aTasksView
{
    return [_tasks count];
}

- (CalTask *)tasksView:(WLCalendarTasksView *)aTasksView taskAtIndex:(NSUInteger)anIndex
{
    return [_tasks objectAtIndex:anIndex];
}


#pragma mark NSView

- (void)loadView
{
    WLCalendarTasksView *v = [[WLCalendarTasksView alloc] initWithFrame:NSZeroRect];
    [self setView:v];
    v.dataSource = self;
    [v createLayers];
    [v release];
    [self fetchTasksAndReloadViewDataAnimated:NO];
    [self addObserver:self forKeyPath:@"representedObject.calReminderCalendars" options:NSKeyValueObservingOptionNew context:NULL];
    NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
    [n addObserver:self
          selector:@selector(_calTasksDidChange:)
              name:CalTasksChangedExternallyNotification
            object:[CalCalendarStore defaultCalendarStore]];
    [n addObserver:self
          selector:@selector(_calTasksDidChange:)
              name:CalTasksChangedNotification
            object:[CalCalendarStore defaultCalendarStore]];
    _isViewLoaded = YES;
}

- (WLCalendarTasksView *)view
{
    return (WLCalendarTasksView *)[super view];
}

- (WLCalendarController *)representedObject
{
    return (WLCalendarController *)[super representedObject];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath hasPrefix:@"representedObject"])
        [self fetchTasksAndReloadViewDataAnimated:YES];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation CalTask (WLCalendarTasksViewController)

- (void)WL_fixPriorityAndDueDate
{
    if (self.priority == CalPriorityNone)
        self.priority = CalPriorityLow + 1;
    if (self.dueDate == nil)
        self.dueDate = [NSDate distantFuture];
}

@end

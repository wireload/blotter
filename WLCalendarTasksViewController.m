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
        [self updateView];
}


#pragma mark Methods

- (void)updateView
{
    NSParameterAssert([sortDescriptors count] > 0);

    [_tasks release];
    NSPredicate *p = [CalCalendarStore taskPredicateWithUncompletedTasks:[[self representedObject] calCalendars]];
    _tasks = [[[CalCalendarStore defaultCalendarStore] tasksWithPredicate:p] mutableCopy];
    for (CalTask *task in _tasks)
        [self _preprocessTask:task];
    [_tasks sortUsingDescriptors:self.sortDescriptors];
    [[self view] reloadDataAnimated:YES];
}


#pragma mark Private

- (void)_tasksDidChange:(NSNotification *)aNotification
{
    NSParameterAssert([sortDescriptors count] > 0);

    NSMutableArray *insertedTaskUIDs = [NSMutableArray array];
    [insertedTaskUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalInsertedRecordsKey]];
    NSArray *updatedTaskUIDs = [[aNotification userInfo] objectForKey:CalUpdatedRecordsKey];
    NSMutableArray *deletedTaskUIDs = [NSMutableArray array];
    [deletedTaskUIDs addObjectsFromArray:[[aNotification userInfo] objectForKey:CalDeletedRecordsKey]];
    NSPredicate *calendarPredicate = [NSPredicate predicateWithFormat:@"calendar in %@", [[self representedObject] calCalendars]];

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

        if (((mode & PreviousCalendarIsChecked) && (mode & CurrentCalendarIsChecked)) ||
            ((mode & PreviousCalendarIsUnchecked) && (mode & CurrentCalendarIsUnchecked)))
        {
            // Continue normal execution.
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

        // It's important to remove object from data before looking for a new index
        [_tasks removeObjectAtIndex:oldIndex];
        NSUInteger newIndex = [_tasks indexOfObject:updatedTask
                                      inSortedRange:NSMakeRange(0, [_tasks count])
                                            options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
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
        [self _preprocessTask:updatedTask];
        [_tasks insertObject:updatedTask atIndex:newIndex];
        [[self view] moveTaskAtIndex:oldIndex toIndex:newIndex];
        [[self view] updateTaskAtIndex:newIndex];
    }
    for (NSString *taskUID in deletedTaskUIDs)
    {
        NSUInteger index = [_tasks indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return [[obj uid] isEqualToString:taskUID];
        }];
        [_tasks removeObjectAtIndex:index];
        [[self view] removeTaskAtIndex:index];
    }
    for (NSString *taskUID in insertedTaskUIDs)
    {
        CalTask *newTask = [[CalCalendarStore defaultCalendarStore] taskWithUID:taskUID];
        if (![calendarPredicate evaluateWithObject:newTask])
            continue;
        [self _preprocessTask:newTask];
        NSUInteger index = [_tasks indexOfObject:newTask
                                   inSortedRange:NSMakeRange(0, [_tasks count])
                                         options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
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
        [_tasks insertObject:newTask atIndex:index];
        [[self view] insertTaskAtIndex:index];
    }
    [CATransaction commit];
}

- (void)_preprocessTask:(CalTask *)aTask;
{
    if (aTask.priority == CalPriorityNone)
        aTask.priority = CalPriorityLow + 1;

    if (aTask.dueDate == nil)
        aTask.dueDate = [NSDate distantFuture];
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
    [self updateView];
    [self addObserver:self forKeyPath:@"representedObject.calCalendars" options:NSKeyValueObservingOptionNew context:NULL];
    NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
    [n addObserver:self
          selector:@selector(_tasksDidChange:)
              name:CalTasksChangedExternallyNotification
            object:[CalCalendarStore defaultCalendarStore]];
    [n addObserver:self
          selector:@selector(_tasksDidChange:)
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
        [self updateView];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}
@end

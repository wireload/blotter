//
//  WLCalendarTasksViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 09.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTasksViewController.h"


@implementation WLCalendarTasksViewController
@synthesize taskPredicate;
@synthesize sortDescriptors;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil)
    {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(_tasksChanged:)
                                   name:CalTasksChangedExternallyNotification
                                 object:[CalCalendarStore defaultCalendarStore]];
        [notificationCenter addObserver:self
                               selector:@selector(_tasksChanged:)
                                   name:CalTasksChangedNotification
                                 object:[CalCalendarStore defaultCalendarStore]];
    }
    return self;
}

- (void)dealloc
{
    [taskPredicate release];
    [sortDescriptors release];
    [_tasks release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (WLCalendarTasksView *)view
{
    return (WLCalendarTasksView *)[super view];
}

- (void)setView:(WLCalendarTasksView *)newView
{
    [self view].dataSource = nil;
    [super setView:newView];
    newView.dataSource = self;
    [self _reloadData];
    [newView setupLayers];

}

- (void)setTaskPredicate:(NSPredicate *)newPredicate
{
    if (![newPredicate isEqual:taskPredicate])
    {
        [taskPredicate release];
        taskPredicate = [newPredicate retain];
        if ([self view] != nil)
            [self _reloadData];
    }
}

- (void)setSortDescriptors:(NSArray *)newDescriptors
{
    if (![newDescriptors isEqual:sortDescriptors])
    {
        [sortDescriptors release];
        sortDescriptors = [newDescriptors copy];
        if ([self view] != nil)
            [self _reloadData];
    }
}


#pragma mark Private

- (void)_reloadData
{
    [_tasks release];
    _tasks = [[[CalCalendarStore defaultCalendarStore] tasksWithPredicate:self.taskPredicate] mutableCopy];
    for (CalTask *task in _tasks)
        [self _preprocessTask:task];
    [_tasks sortUsingDescriptors:self.sortDescriptors];
    [[self view] reloadData];
}

- (void)_tasksChanged:(NSNotification *)aNotification
{
    NSParameterAssert([sortDescriptors count] > 0);

    NSArray *insertedTasks = [[aNotification userInfo] objectForKey:CalInsertedRecordsKey];
    NSArray *updatedTasks = [[aNotification userInfo] objectForKey:CalUpdatedRecordsKey];
    NSArray *deletedTasks = [[aNotification userInfo] objectForKey:CalDeletedRecordsKey];

    [CATransaction begin];
    for (NSString *taskUID in deletedTasks)
    {
        NSUInteger index = [_tasks indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return [[obj uid] isEqualToString:taskUID];
        }];
        [_tasks removeObjectAtIndex:index];
        [[self view] removeTaskAtIndex:index];
    }
    for (NSString *taskUID in updatedTasks)
    {
        CalTask *updatedTask = [[CalCalendarStore defaultCalendarStore] taskWithUID:taskUID];
        [self _preprocessTask:updatedTask];
        NSUInteger oldIndex = [_tasks indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return [[obj uid] isEqualToString:taskUID];
        }];
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
        [_tasks insertObject:updatedTask atIndex:newIndex];
        [[self view] moveTaskAtIndex:oldIndex toIndex:newIndex];
        [[self view] updateTaskAtIndex:newIndex];
    }
    for (NSString *taskUID in insertedTasks)
    {
        CalTask *newTask = [[CalCalendarStore defaultCalendarStore] taskWithUID:taskUID];
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
    if ([self nibName] != nil)
        [super loadView];
}

@end

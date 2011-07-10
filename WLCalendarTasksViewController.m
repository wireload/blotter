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
    NSParameterAssert([newView isKindOfClass:[WLCalendarTasksView class]]);
    [super setView:newView];
    [newView setDataSource:self];
}

- (void)setRepresentedObject:(id)aRepresentedObject
{
    [super setRepresentedObject:aRepresentedObject];
    if ([aRepresentedObject isKindOfClass:[CalCalendarStore class]])
    {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(_tasksChanged:)
                                   name:CalTasksChangedExternallyNotification
                                 object:aRepresentedObject];
        [notificationCenter addObserver:self
                               selector:@selector(_tasksChanged:)
                                   name:CalTasksChangedNotification
                                 object:aRepresentedObject];
    }
}

- (void)setTaskPredicate:(NSPredicate *)newPredicate
{
    if (![newPredicate isEqual:taskPredicate])
    {
        [taskPredicate release];
        taskPredicate = [newPredicate retain];
    }
}

- (void)setSortDescriptors:(NSArray *)newDescriptors
{
    if (![newDescriptors isEqual:sortDescriptors])
    {
        [sortDescriptors release];
        sortDescriptors = [newDescriptors copy];
    }
}

- (void)reloadData
{
    if ([self view] != nil && [self representedObject] != nil && taskPredicate != nil && [sortDescriptors count] > 0)
    {
        [_tasks release];
        _tasks = [[[self representedObject] tasksWithPredicate:self.taskPredicate] mutableCopy];
        [_tasks sortUsingDescriptors:self.sortDescriptors];
        [[self view] reloadData];
    }
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
        CalTask *updatedTask = [[self representedObject] taskWithUID:taskUID];
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
        CalTask *newTask = [[self representedObject] taskWithUID:taskUID];
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


#pragma mark WLCalendarTasksViewDataSource

- (NSUInteger)numberOfTasks
{
    return [_tasks count];
}

- (CalTask *)taskAtIndex:(NSUInteger)anIndex
{
    return [_tasks objectAtIndex:anIndex];
}

@end

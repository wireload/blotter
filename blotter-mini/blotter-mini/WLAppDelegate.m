//
//  WLAppDelegate.m
//  Blotter-mini
//
//  Created by Ilya Kulakov on 27.09.12.
//  Copyright (c) 2012 Wireload. All rights reserved.
//

#import "WLAppDelegate.h"
#import <EventKit/EventKit.h>


@implementation WLAppDelegate
{
    NSOperationQueue *calendarsQueue;
    NSOperationQueue *eventsQueue;
    NSOperationQueue *remindersQueue;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDictionary *defaults = @{
        WLCalSystemStoreAllowsAdvancedCalendarTypeCheckKey : @(YES),
        WLCalSystemStoreChecksCalendarsAgainstICalKey : @(YES)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    calendarsQueue = [[NSOperationQueue alloc] init];
    [calendarsQueue setMaxConcurrentOperationCount:1];
    [calendarsQueue setName:@"Calendars"];
    
    eventsQueue = [[NSOperationQueue alloc] init];
    [eventsQueue setMaxConcurrentOperationCount:1];
    [eventsQueue setName:@"Events"];
    
    remindersQueue = [[NSOperationQueue alloc] init];
    [remindersQueue setMaxConcurrentOperationCount:1];
    [remindersQueue setName:@"Reminders"];
    
    self.store = [WLCalendarStore systemStore];
    self.fromDatePicker.dateValue = [[NSDate date] dateByAddingTimeInterval:-3600*24*7];
    self.toDatePicker.dateValue = [[NSDate date] dateByAddingTimeInterval:3600*24*7];
    
    [self _storeDidChange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_storeDidChange) name:WLCalStoreDidChangeNotification object:self.store];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(process:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [calendarsQueue cancelAllOperations];
    [eventsQueue cancelAllOperations];
    [remindersQueue cancelAllOperations];
    
    [calendarsQueue waitUntilAllOperationsAreFinished];
    [eventsQueue waitUntilAllOperationsAreFinished];
    [remindersQueue waitUntilAllOperationsAreFinished];
}

- (void)process:(NSNotification *)aNotification
{
    NSLog(@"%@", aNotification);
}

- (void)_storeDidChange
{
    [self calendarsDidChange:nil];
    [self eventPredicateDidChange:nil];
    [self reminderPredicateDidChage:nil];
}

- (void)calendarsDidChange:(id)sender
{
    [calendarsQueue cancelAllOperations];
    NSBlockOperation *b = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *bBlock = b;
    [b addExecutionBlock:^{
        NSArray *calendars = [self.store calendars];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (![bBlock isCancelled])
                self.calendars = calendars;
        });
    }];
    [calendarsQueue addOperation:b];
}

- (IBAction)eventPredicateDidChange:(id)sender
{
    [eventsQueue cancelAllOperations];
    NSBlockOperation *b = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *bBlock = b;
    [b addExecutionBlock:^{
        WLCalEventsPredicate *p = [[WLCalEventsPredicate alloc] initWithDateRange:[WLDateRange dateRangeWithStartDate:self.fromDatePicker.dateValue endDate:self.toDatePicker.dateValue]
                                                              calendarIdentifiers:[[self.calendarsController selectedObjects] valueForKey:@"calendarIdentifier"]];
        NSArray *events = [self.store eventsMatchingPredicate:p];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (![bBlock isCancelled])
                self.events = events;
        });
    }];
    [eventsQueue addOperation:b];
}

- (IBAction)reminderPredicateDidChage:(id)sender
{
    [remindersQueue cancelAllOperations];
    NSBlockOperation *b = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *bBlock = b;
    [b addExecutionBlock:^{
        WLCalReminderCompletionMask mask = 0;
        if ([self.completedRemindersCheckBox integerValue])
            mask |= WLCalReminderCompletionMaskComplete;
        if ([self.uncompletedRemindersCheckbox integerValue])
            mask |= WLCalReminderCompletionMaskIncomplete;
        WLCalRemindersPredicate *p = [[WLCalRemindersPredicate alloc] initWithCompletionMask:mask calendarIdentifiers:[[self.calendarsController selectedObjects] valueForKey:@"calendarIdentifier"]];
        NSArray *reminders = [self.store remindersMatchingPredicate:p];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (![bBlock isCancelled])
                self.remidners = reminders;
        });
    }];
    [remindersQueue addOperation:b];
}


#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self eventPredicateDidChange:nil];
    [self reminderPredicateDidChage:nil];
}

@end

//
//  WLNewReminderWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "NSDate+WLDayBoundaries.h"
#import "WLGlassHudTextView.h"
#import "WLNewReminderWindowController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


@implementation WLNewReminderWindowController
{
    id _titleViewObserver;
}

- (void)dealloc
{
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];
}


#pragma mark Properties

+ (NSSet *)keyPathsForValuesAffectingCanCreateReminder
{
    return [NSSet setWithObject:@"self.calCalendars"];
}

- (void)setSelectedCalCalendarIndex:(NSUInteger)newSelectedCalCalendarIndex
{
    NSObject <WLCalCalendar> *c = [self.calCalendars objectAtIndex:newSelectedCalCalendarIndex];
    [[NSUserDefaults standardUserDefaults] setObject:c.calendarIdentifier forKey:WLLastSelectedCalReminderCalendarUID];
}

- (NSUInteger)selectedCalCalendarIndex
{
    NSUInteger index = NSNotFound;
    NSString *lastSelectedCalendarUID = [[NSUserDefaults standardUserDefaults] objectForKey:WLLastSelectedCalReminderCalendarUID];

    if (lastSelectedCalendarUID != nil)
    {
        index = [self.calCalendars indexOfObjectPassingTest:^BOOL(NSObject <WLCalCalendar> *aCalCalendar, NSUInteger idx, BOOL *stop)
        {
            return [aCalCalendar.calendarIdentifier isEqualToString:lastSelectedCalendarUID];
        }];

        if (index == NSNotFound)
            index = 0;
    }
    else
        index = 0;

    return index;
}

- (BOOL)canCreateReminder
{
    return [self.calCalendars count] > 0;
}


#pragma mark Methods

- (IBAction)resetDefaults:(id)aSender
{
    self.title = NSLocalizedString(@"New Reminder", @"Default text for title field of the New Reminder panel");
    self.isDueDate = NO;
    // The due date is an 'all day' date.
    // Due date is set to next hour to mini iCal behavior when due date of a reminder created at 23:XX is set to next day.
    NSDate *newDueDate = nil;
    NSTimeInterval timeInterval = 0.0;
    [[NSCalendar currentCalendar] rangeOfUnit:NSHourCalendarUnit startDate:&newDueDate interval:&timeInterval forDate:[NSDate date]];
    self.dueDate = [newDueDate dateByAddingTimeInterval:timeInterval];;
    self.priority = CalPriorityNone;

    [(NSTextView *)_titleView selectAll:self];
}

- (IBAction)create:(id)aSender
{
    CalTask *task = [CalTask task];
    task.title = self.title;
    if (self.isDueDate)
        task.dueDate = self.dueDate;
    task.priority = self.priority;
    NSObject <WLCalCalendar> *selectedCalendar = [self.calCalendars objectAtIndex:self.selectedCalCalendarIndex];
    task.calendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:selectedCalendar.calendarIdentifier];

    NSError *error = nil;

    if ([[CalCalendarStore defaultCalendarStore] saveTask:task error:&error])
        [[self window] orderOut:self];
    else
    {
        NSBeep();
        [NSApp presentError:error];
    }
}


#pragma mark NSWindowController

- (void)windowDidLoad
{
    [[self window] setLevel:NSFloatingWindowLevel];

    unichar keyEquiv = NSEnterCharacter;
    NSString *equivString = [NSString stringWithCharacters:&keyEquiv length:1];
    [_createButton setKeyEquivalent:equivString];

    [(NSTextView *)_titleView setFont:[NSFont boldSystemFontOfSize:16]];

    _titleViewObserver = [[NSNotificationCenter defaultCenter] addObserverForName:WLViewSizeDidChangeNotification
                                                                           object:_titleView
                                                                            queue:nil
                                                                       usingBlock:^(NSNotification *arg1)
    {
        CGFloat heightDiff = [[[arg1 userInfo] objectForKey:WLSizeDiff] sizeValue].height;
        NSRect newWindowFrame = [[self window] frame];
        newWindowFrame.size.height += heightDiff;
        newWindowFrame.origin.y -= heightDiff;

        [[self window] setFrame:newWindowFrame display:YES animate:YES];
    }];
    _titleView.postsSizeChangedNotifications = YES;

    [[_titleView valueForKey:@"_textView"] bind:NSValueBinding
                                       toObject:self
                                    withKeyPath:@"title"
                                        options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSContinuouslyUpdatesValueBindingOption]];

    [self resetDefaults:nil];
}

@end

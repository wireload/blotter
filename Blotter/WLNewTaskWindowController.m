//
//  WLNewTaskWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "NSDate+WLDayBoundaries.h"
#import "WLGlassHudTextView.h"
#import "WLNewTaskWindowController.h"


@implementation WLNewTaskWindowController

- (id)initWithCalendarController:(WLCalendarController *)aCalendarController
{
    self = [self initWithWindowNibName:@"NewTaskWindow"];
    if (self != nil)
    {
        _calendarController = [aCalendarController retain];
    }
    return self;
}


- (void)dealloc
{
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];
    [_calendarController release];
    [dueDate release];
    [title release];
    [super dealloc];
}


#pragma mark Properties
@synthesize isDueDate;
@synthesize dueDate;
@synthesize title;
@synthesize priority;
@dynamic taskCalCalendars;
@dynamic selectedTaskCalCalendarIndex;
@dynamic canCreateTask;

- (NSArray *)taskCalCalendars
{
    return [_calendarController.calReminderCalendarsToDisplay filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isEditable == YES"]];
}

- (void)setSelectedTaskCalCalendarIndex:(NSUInteger)newSelectedTaskCalCalendarIndex
{
    CalCalendar *c = [self.taskCalCalendars objectAtIndex:newSelectedTaskCalCalendarIndex];
    [[NSUserDefaults standardUserDefaults] setObject:[c uid] forKey:@"uidOfLastSelectedCalendarInTasks"];
}

- (NSUInteger)selectedTaskCalCalendarIndex
{
    NSUInteger index = NSNotFound;
    NSString *lastSelectedCalendarUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"uidOfLastSelectedCalendarInTasks"];
    if (lastSelectedCalendarUID != nil)
    {
        index = [self.taskCalCalendars indexOfObjectPassingTest:^BOOL(CalCalendar *calCalendar, NSUInteger idx, BOOL *stop) {
            return [calCalendar.uid isEqualToString:lastSelectedCalendarUID];
        }];
        if (index == NSNotFound)
            index = 0;
    }
    else
        index = 0;
    return index;
}

- (BOOL)canCreateTask
{
    return [self.taskCalCalendars count] > 0;
}


#pragma mark Methods

+ (id)sharedWindowController
{
    static dispatch_once_t onceToken;
    static WLNewTaskWindowController *controller = nil;
    dispatch_once(&onceToken, ^{
        controller = [[self alloc] initWithCalendarController:[WLCalendarController sharedController]];
    });
    return controller;
}

- (IBAction)setDefaults:(id)aSender
{
    self.title = NSLocalizedString(@"New Reminder", @"Default text for title field of the New Reminder panel");
    self.isDueDate = NO;
    // The due date is an 'all day' date, but we still base it on the next hour so that if you create an
    // event at 23:XX, the suggested due date is tomorrow instead of the same day which is more helpful.
    self.dueDate = [[NSDate date] WL_nextHourDate];
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
    task.calendar = [self.taskCalCalendars objectAtIndex:self.selectedTaskCalCalendarIndex];

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

    [self setDefaults:nil];
}


#pragma mark NSObject

+ (NSSet *)keyPathsForValuesAffectingCanCreateTask
{
    return [NSSet setWithObject:@"taskCalCalendars"];
}

+ (NSSet *)keyPathsForValuesAffectingTaskCalCalendars
{
    return [NSSet setWithObject:@"_calendarController.calReminderCalendarsToDisplay"];
}

@end

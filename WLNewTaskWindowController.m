//
//  WLNewTaskWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLNewTaskWindowController.h"


@interface WLNewTaskWindowController (/* Private */)
@property (copy) NSArray *calendars;

@end


static WLNewTaskWindowController *_sharedInstance;

@implementation WLNewTaskWindowController
@synthesize calendars;

+ (BOOL)canCreateTask
{
    return [[[CalCalendarStore defaultCalendarStore] calendars] count];
}

+ (id)sharedWindowController
{
    @synchronized (self)
    {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] initWithWindowNibName:@"NewTaskWindow"];
        }
    }
    return _sharedInstance;
}

- (id)initWithWindow:(NSWindow *)window
{
    if (self = [super initWithWindow:window])
    {
        self.calendars = [[CalCalendarStore defaultCalendarStore] calendars];
        _calendarsChangedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CalCalendarsChangedExternallyNotification
                                                                                      object:[CalCalendarStore defaultCalendarStore]
                                                                                       queue:nil
                                                                                  usingBlock:^(NSNotification *arg1)
                                     {
                                         self.calendars = [[CalCalendarStore defaultCalendarStore] calendars];
                                     }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_calendarsChangedObserver];
    [calendars release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [self reset];
}

- (void)reset
{
    [_titleField setStringValue:NSLocalizedString(@"New Task", @"Default text for title field on the New Task panel")];
    [_titleField selectText:nil];
    [_dueDatePicker setDateValue:[NSDate date]];
    [_priorityPopUp selectItemWithTag:CalPriorityNone];
}

- (IBAction)create:(id)aSender
{
    CalTask *task = [CalTask task];
    task.title = [_titleField stringValue];
    task.dueDate = [_dueDatePicker dateValue];
    task.priority = [[_priorityPopUp selectedItem] tag];

    NSUInteger selectedCalendarIndex = [_calendarsController selectionIndex];
    if (selectedCalendarIndex != NSNotFound)
        task.calendar = [[_calendarsController arrangedObjects] objectAtIndex:selectedCalendarIndex];

    NSError *error = nil;
    if ([[CalCalendarStore defaultCalendarStore] saveTask:task error:&error])
        [[self window] performClose:aSender];
    else
    {
        // TODO: show the error.
        NSLog(@"Cannot create event: %@", error);
    }
}

@end

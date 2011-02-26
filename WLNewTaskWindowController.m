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
    [_dueDatePicker setDateValue:[NSDate date]];
    [_priorityPopUp setTag:CalPriorityNone];
}

- (IBAction)create:(id)aSender
{
}

@end

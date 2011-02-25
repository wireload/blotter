//
//  WLNewEventWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLNewEventWindowController.h"
#import <CalendarStore/CalendarStore.h>


@interface WLNewEventWindowController (/* Private */)
@property (copy) NSArray *calendars;

@end


static WLNewEventWindowController *_sharedInstance;

@implementation WLNewEventWindowController
@synthesize calendars;

+ (BOOL)canCreateEvent
{
    return [[[CalCalendarStore defaultCalendarStore] calendars] count];
}

+ (id)sharedWindowController
{
    @synchronized (self)
    {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] initWithWindowNibName:@"NewEventWindow"];
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
    [_titleField setStringValue:NSLocalizedString(@"New Event", @"Default text for title field on the New Event panel")];
    [_locationField setStringValue:@""];
    [_isAllDayButton setState:NSOffState];
    [_startDatePicker setDateValue:[NSDate date]];
    [_endDatePicker setDateValue:[[NSDate date] dateByAddingTimeInterval:3600]];
}

- (IBAction)create:(id)aSender;
{
    CalEvent *event = [CalEvent event];
    event.title = [_titleField stringValue];
    event.location = [_locationField stringValue];
    event.isAllDay = ([_isAllDayButton state] == NSOnState);
    event.startDate = [_startDatePicker dateValue];
    event.endDate = [_startDatePicker dateValue];
    
    NSUInteger selectedCalendarIndex = [_calendarsController selectionIndex];
    if (selectedCalendarIndex != NSNotFound)
        event.calendar = [[_calendarsController arrangedObjects] objectAtIndex:selectedCalendarIndex];
    
    NSError *error = nil;
    if ([[CalCalendarStore defaultCalendarStore] saveEvent:event span:CalSpanThisEvent error:&error]) {
        [[self window] performClose:aSender];
    }
    else {
        // TODO: show the error.
        NSLog(@"Cannot create event: %@", error);
    }
}

@end

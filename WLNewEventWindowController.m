//
//  WLNewEventWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLNewEventWindowController.h"
#import "WLGlassHudTextView.h"


static const CGFloat _WLMaxTitleHeight = 250.0f;


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
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];
    if (_locationViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_locationViewObserver];
    [calendars release];
    [super dealloc];
}

- (void)windowDidLoad
{
    _titleViewObserver = [[NSNotificationCenter defaultCenter] addObserverForName:WLViewSizeDidChangeNotification
                                                                           object:_titleView
                                                                            queue:nil
                                                                       usingBlock:^(NSNotification *arg1)
    {
        CGFloat heightDiff = [[[arg1 userInfo] objectForKey:WLSizeDiff] sizeValue].height;
        // Resize window
        NSRect newWindowFrame = [[self window] frame];
        newWindowFrame.size.height += heightDiff;
        newWindowFrame.origin.y -= heightDiff;

        [[self window] setFrame:newWindowFrame display:YES animate:NO];
    }];
    _titleView.postsSizeChangedNotifications = YES;

    _locationViewObserver = [[NSNotificationCenter defaultCenter] addObserverForName:WLViewSizeDidChangeNotification
                                                                              object:_locationView
                                                                               queue:nil
                                                                          usingBlock:^(NSNotification *arg1)
    {
        CGFloat heightDiff = [[[arg1 userInfo] objectForKey:WLSizeDiff] sizeValue].height;
        NSRect newWindowFrame = [[self window] frame];
        newWindowFrame.size.height += heightDiff;
        newWindowFrame.origin.y -= heightDiff;
        [_locationViewContainer setAutoresizingMask:([_locationViewContainer autoresizingMask] | NSViewHeightSizable) ^ NSViewMaxYMargin];
        [[self window] setFrame:newWindowFrame display:YES animate:NO];
        [_locationViewContainer setAutoresizingMask:([_locationViewContainer autoresizingMask] ^ NSViewHeightSizable) | NSViewMaxYMargin];
    }];
    _locationView.postsSizeChangedNotifications = YES;

    [(NSTextView *)_titleView setDrawsBackground:NO];
    [(NSTextView *)_titleView setFont:[NSFont boldSystemFontOfSize:16]];
    [(NSTextView *)_locationView setDrawsBackground:NO];
    [self reset];
}

- (void)reset
{
    [(NSTextView *)_titleView setString:NSLocalizedString(@"New Event", @"Default text for title field on the New Event panel")];
    [(NSTextView *)_titleView selectAll:self];
    [(NSTextView *)_locationView setString:@""];
    [_isAllDayButton setState:NSOffState];
    [_startDatePicker setDateValue:[NSDate date]];
    [_endDatePicker setDateValue:[[NSDate date] dateByAddingTimeInterval:3600]];
    [[self window] makeFirstResponder:_titleView];
}

- (IBAction)create:(id)aSender;
{
    CalEvent *event = [CalEvent event];
    event.title = [(NSTextView *)_titleView string];
    event.location = [(NSTextView *)_locationView string];
    event.isAllDay = ([_isAllDayButton state] == NSOnState);
    event.startDate = [_startDatePicker dateValue];
    event.endDate = [_startDatePicker dateValue];

    NSUInteger selectedCalendarIndex = [_calendarsController selectionIndex];
    if (selectedCalendarIndex != NSNotFound)
        event.calendar = [[_calendarsController arrangedObjects] objectAtIndex:selectedCalendarIndex];

    NSError *error = nil;
    if ([[CalCalendarStore defaultCalendarStore] saveEvent:event span:CalSpanThisEvent error:&error])
        [[self window] orderOut:self];
    else
    {
        NSBeep();
        // TODO: show the error.
        NSLog(@"Cannot create event: %@", error);
    }
}

@end

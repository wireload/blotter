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


static const NSTimeInterval _WLDefaultTimeDiff = 3600; // seconds


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
    [_isAllDayButton removeObserver:self forKeyPath:@"cell.state"];
    [[NSNotificationCenter defaultCenter] removeObserver:_calendarsChangedObserver];
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];
    if (_locationViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_locationViewObserver];
    [calendars release];
    [_datePickerValueBackup release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualTo:@"cell.state"])
    {
        NSInteger newState = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (newState == NSOnState)
        {
            [_startDatePicker setDatePickerElements:NSYearMonthDayDatePickerElementFlag];
            [_endDatePicker setDatePickerElements:NSYearMonthDayDatePickerElementFlag];
        }
        else
        {
            [_startDatePicker setDatePickerElements:NSYearMonthDayDatePickerElementFlag | NSHourMinuteDatePickerElementFlag];
            [_endDatePicker setDatePickerElements:NSYearMonthDayDatePickerElementFlag | NSHourMinuteDatePickerElementFlag];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)windowDidLoad
{
    unichar keyEquiv = NSEnterCharacter;
    NSString *equivString = [NSString stringWithCharacters:&keyEquiv length:1];
    [_createButton setKeyEquivalent:equivString];
    [_startDatePicker setDelegate:self];
    [_endDatePicker setDelegate:self];
    [(NSTextView *)_titleView setDrawsBackground:NO];
    [(NSTextView *)_titleView setFont:[NSFont boldSystemFontOfSize:16]];
    [(NSTextView *)_locationView setDrawsBackground:NO];

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
        [[self window] setFrame:newWindowFrame display:YES animate:YES];
        [_locationViewContainer setAutoresizingMask:([_locationViewContainer autoresizingMask] ^ NSViewHeightSizable) | NSViewMaxYMargin];
    }];
    _locationView.postsSizeChangedNotifications = YES;

    [_isAllDayButton addObserver:self forKeyPath:@"cell.state" options:NSKeyValueObservingOptionNew context:NULL];

    [self reset];
}

- (void)reset
{
    [(NSTextView *)_titleView setString:NSLocalizedString(@"New Event", @"Default text for title field on the New Event panel")];
    [(NSTextView *)_locationView setString:@""];
    [_isAllDayButton setState:NSOffState];
    [_startDatePicker setDateValue:[NSDate date]];
    [_endDatePicker setDateValue:[[_startDatePicker dateValue] dateByAddingTimeInterval:_WLDefaultTimeDiff]];
    [(NSTextView *)_titleView selectAll:self];
    [_datePickerValueBackup release], _datePickerValueBackup = nil;
}

- (IBAction)create:(id)aSender;
{
    CalEvent *event = [CalEvent event];
    event.title = [(NSTextView *)_titleView string];
    event.location = [(NSTextView *)_locationView string];
    event.isAllDay = ([_isAllDayButton state] == NSOnState);
    event.startDate = [_startDatePicker dateValue];
    event.endDate = [_endDatePicker dateValue];

    event.calendar = [[_calendarsController selectedObjects] lastObject];

    NSError *error = nil;
    if ([[CalCalendarStore defaultCalendarStore] saveEvent:event span:CalSpanThisEvent error:&error])
        [[self window] orderOut:self];
    else
    {
        NSBeep();
        [NSApp presentError:error];
    }
}


#pragma mark NSDatePickerDelegate

- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell
validateProposedDateValue:(NSDate **)proposedDateValue
          timeInterval:(NSTimeInterval *)proposedTimeInterval
{

}

- (void)datePickerCellDidResignFirstResponder:(NSDatePickerCell *)aDatePickerCell
{
    if (aDatePickerCell == [_startDatePicker cell])
    {
        NSDate *newDate = [_startDatePicker dateValue];
        NSTimeInterval diffBetweenDates = [newDate timeIntervalSinceDate:_datePickerValueBackup];
        if (diffBetweenDates >= 0)
            [_endDatePicker setDateValue:[[_endDatePicker dateValue] dateByAddingTimeInterval:diffBetweenDates]];
        else
            [_endDatePicker setDateValue:[newDate dateByAddingTimeInterval:_WLDefaultTimeDiff]];
    }
    else if (aDatePickerCell == [_endDatePicker cell])
    {
        if ([[_endDatePicker dateValue] compare:[_startDatePicker dateValue]] == NSOrderedAscending)
        {
            NSBeep();
            [_endDatePicker setDateValue:_datePickerValueBackup];
        }
    }
    [_datePickerValueBackup release], _datePickerValueBackup = nil;
}

- (void)datePickerCellDidBecomeFirstResponder:(NSDatePickerCell *)aDatePickerCell
{
    _datePickerValueBackup = [[aDatePickerCell dateValue] copy];
}

@end

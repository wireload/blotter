//
//  WLNewEventWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "NSDate+WLDayBoundaries.h"
#import "WLGlassHudTextView.h"
#import "WLNewEventWindowController.h"


static const NSTimeInterval _WLDefaultTimeDiff = 3600; // seconds


@implementation WLNewEventWindowController

- (id)initWithCalendarController:(WLCalendarController *)aCalendarController
{
    self = [self initWithWindowNibName:@"NewEventWindow"];
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
    if (_locationViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_locationViewObserver];
    [_datePickerValueBackup release];
    [_calendarController release];
    [title release];
    [location release];
    [startDate release];
    [endDate release];
    [super dealloc];
}


#pragma mark Properties
@synthesize title;
@synthesize location;
@synthesize isAllDay;
@synthesize startDate;
@synthesize endDate;
@dynamic eventCalCalendars;
@dynamic selectedEventCalCalendarIndex;
@dynamic canCreateEvent;

- (NSArray *)eventCalCalendars
{
    return [_calendarController.calEventCalendarsToDisplay filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isEditable == YES"]];
}

- (void)setSelectedEventCalCalendarIndex:(NSUInteger)newSelectedEventCalCalendarIndex
{
    CalCalendar *c = [self.eventCalCalendars objectAtIndex:newSelectedEventCalCalendarIndex];
    [[NSUserDefaults standardUserDefaults] setObject:[c uid] forKey:@"uidOfLastSelectedCalendarInEvents"];
}

- (NSUInteger)selectedEventCalCalendarIndex
{
    NSUInteger index = NSNotFound;
    NSString *lastSelectedCalendarUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"uidOfLastSelectedCalendarInEvents"];
    if (lastSelectedCalendarUID != nil)
    {
        index = [self.eventCalCalendars indexOfObjectPassingTest:^BOOL(CalCalendar *calCalendar, NSUInteger idx, BOOL *stop) {
            return [calCalendar.uid isEqualToString:lastSelectedCalendarUID];
        }];
        if (index == NSNotFound)
            index = 0;
    }
    else
        index = 0;
    return index;
}

- (BOOL)canCreateEvent
{
    return [self.eventCalCalendars count] > 0;
}


#pragma mark Methods

+ (id)sharedWindowController
{
    static dispatch_once_t onceToken;
    static WLNewEventWindowController *controller = nil;
    dispatch_once(&onceToken, ^{
        controller = [[self alloc] initWithCalendarController:[WLCalendarController sharedController]];
    });
    return controller;
}

- (IBAction)setDefaults:(id)aSender
{
    // It is important to change string of _locationView before _titleView, because resizing of _locationView is followed by resizing of _titleView and that
    // will result in wrong frame of _titleView.
    // FIXME: It is probably a bug and current implementation of resizing methods are wrong (Look up _titleViewObserver and _locationViewObserver) // :Ilya Kulakov:20110411
    self.location = @"";
    self.title = NSLocalizedString(@"New Event", @"Default text for title field on the New Event panel");
    self.isAllDay = NO;
    self.startDate = [[NSDate date] WL_nextHourDate];
    self.endDate = [self.startDate dateByAddingTimeInterval:_WLDefaultTimeDiff];
    
    [(NSTextView *)_titleView selectAll:self];
    [_datePickerValueBackup release], _datePickerValueBackup = nil;
}

- (IBAction)create:(id)aSender;
{
    CalEvent *event = [CalEvent event];
    event.title = self.title;
    event.location = self.location;
    event.isAllDay = self.isAllDay;
    event.startDate = self.startDate;
    event.endDate = self.endDate;
    event.calendar = [self.eventCalCalendars objectAtIndex:self.selectedEventCalCalendarIndex];

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

- (void)datePickerCellDidResignFirstResponder:(NSDatePickerCell *)aDatePickerCell
{
    if (aDatePickerCell == [_startDatePicker cell])
    {
        NSTimeInterval diffBetweenDates = [self.startDate timeIntervalSinceDate:_datePickerValueBackup];
        if (diffBetweenDates >= 0)
            self.endDate = [self.endDate dateByAddingTimeInterval:diffBetweenDates];
        else
            self.endDate = [self.startDate dateByAddingTimeInterval:_WLDefaultTimeDiff];
    }
    else if (aDatePickerCell == [_endDatePicker cell])
    {
        if ([self.endDate compare:self.startDate] == NSOrderedAscending)
        {
            NSBeep();
            self.endDate = _datePickerValueBackup;
        }
    }
    [_datePickerValueBackup release], _datePickerValueBackup = nil;
}

- (void)datePickerCellDidBecomeFirstResponder:(NSDatePickerCell *)aDatePickerCell
{
    _datePickerValueBackup = [[aDatePickerCell dateValue] copy];
}


#pragma mark Private
@dynamic _datePickerElements;

- (NSInteger)_datePickerElements
{
    if (self.isAllDay)
        return NSYearMonthDayDatePickerElementFlag;
    else
        return NSYearMonthDayDatePickerElementFlag | NSHourMinuteDatePickerElementFlag;
}


#pragma mark NSWindowController

- (void)windowDidLoad
{
    [[self window] setLevel:NSFloatingWindowLevel];

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
                                 [_titleView setAutoresizingMask:([_titleView autoresizingMask] ^ NSViewHeightSizable) | NSViewMinYMargin];
                                 [[self window] setFrame:newWindowFrame display:YES animate:YES];
                                 [_titleView setAutoresizingMask:([_titleView autoresizingMask] | NSViewHeightSizable) ^ NSViewMinYMargin];
                                 [_locationViewContainer setAutoresizingMask:([_locationViewContainer autoresizingMask] ^ NSViewHeightSizable) | NSViewMaxYMargin];
                             }];
    _locationView.postsSizeChangedNotifications = YES;
    
    [[_titleView valueForKey:@"_textView"] bind:NSValueBinding
                                       toObject:self
                                    withKeyPath:@"title"
                                        options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSContinuouslyUpdatesValueBindingOption]];
    [[_locationView valueForKey:@"_textView"] bind:NSValueBinding
                                          toObject:self
                                       withKeyPath:@"location"
                                           options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSContinuouslyUpdatesValueBindingOption]];
    [_startDatePicker bind:@"datePickerElements" toObject:self withKeyPath:@"_datePickerElements" options:nil];
    [_endDatePicker bind:@"datePickerElements" toObject:self withKeyPath:@"_datePickerElements" options:nil];

    [self setDefaults:nil];
}


#pragma mark NSObject

+ (NSSet *)keyPathsForValuesAffectingCanCreateEvent
{
    return [NSSet setWithObject:@"self.eventCalCalendars"];
}

+ (NSSet *)keyPathsForValuesAffectingEventCalCalendars
{
    return [NSSet setWithObject:@"_calendarController.calEventCalendarsToDisplay"];
}

+ (NSSet *)keyPathsForValuesAffecting_datePickerElements
{
    return [NSSet setWithObject:@"self.isAllDay"];
}

@end

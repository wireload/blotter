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
#import "NSUserDefaults+WLApplicationDefaults.h"


@implementation WLNewEventWindowController
{
    NSDate *_datePickerValueBackup;
    id _titleViewObserver;
    id _locationViewObserver;
}

- (void)dealloc
{
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];

    if (_locationViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_locationViewObserver];
}


#pragma mark Properties

+ (NSSet *)keyPathsForValuesAffectingCanCreateEvent
{
    return [NSSet setWithObject:@"self.calCalendars"];
}

- (void)setSelectedCalCalendarIndex:(NSUInteger)newSelectedCalCalendarIndex
{
    NSObject <WLCalCalendar> *c = [self.calCalendars objectAtIndex:newSelectedCalCalendarIndex];
    [[NSUserDefaults standardUserDefaults] setObject:c.calendarIdentifier forKey:WLLastSelectedCalEventCalendarUID];
}

- (NSUInteger)selectedCalCalendarIndex
{
    NSUInteger index = NSNotFound;
    NSString *lastSelectedCalendarUID = [[NSUserDefaults standardUserDefaults] objectForKey:WLLastSelectedCalEventCalendarUID];

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

- (BOOL)canCreateEvent
{
    return [self.calCalendars count] > 0;
}


#pragma mark Methods

- (IBAction)resetDefaults:(id)aSender
{
    // It is important to change string of _locationView before _titleView, because resizing of _locationView is followed by resizing of _titleView and that
    // will result in wrong frame of _titleView.
    // FIXME: It is probably a bug and current implementation of resizing methods are wrong (Look up _titleViewObserver and _locationViewObserver) // :Ilya Kulakov:20110411
    self.location = @"";
    self.title = NSLocalizedString(@"New Event", @"Default text for title field on the New Event panel");
    self.isAllDay = NO;

    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDate *currentDate = [NSDate date];
    NSDate *newStartDate = nil;
    NSTimeInterval timeInterval = 0.0;
    [currentCalendar rangeOfUnit:NSHourCalendarUnit startDate:&newStartDate interval:&timeInterval forDate:currentDate];
    newStartDate = [newStartDate dateByAddingTimeInterval:timeInterval];
    NSDate *newEndDate = nil;
    [currentCalendar rangeOfUnit:NSHourCalendarUnit startDate:&newEndDate interval:&timeInterval forDate:newStartDate];
    newEndDate = [newEndDate dateByAddingTimeInterval:timeInterval];

    if (!newStartDate || !newEndDate || [newStartDate compare:newEndDate] != NSOrderedAscending)
    {
        newStartDate = currentDate;
        newEndDate = [newStartDate dateByAddingTimeInterval:3600];
    }

    self.startDate = newStartDate;
    self.endDate = newEndDate;

    [(NSTextView *)_titleView selectAll:self];
    _datePickerValueBackup = nil;
}

- (IBAction)create:(id)aSender;
{
    CalEvent *event = [CalEvent event];
    event.title = self.title;
    event.location = self.location;
    event.isAllDay = self.isAllDay;
    event.startDate = self.startDate;
    event.endDate = self.endDate;
    NSObject <WLCalCalendar> *selectedCalendar = [self.calCalendars objectAtIndex:self.selectedCalCalendarIndex];
    event.calendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:selectedCalendar.calendarIdentifier];

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
        {
            NSDateComponents *c = [[NSDateComponents alloc] init];
            c.hour = 1;
            self.endDate = [[NSCalendar currentCalendar] dateByAddingComponents:c toDate:self.startDate options:0];
        }
    }
    else if (aDatePickerCell == [_endDatePicker cell])
    {
        if ([self.endDate compare:self.startDate] == NSOrderedAscending)
        {
            NSBeep();
            self.endDate = _datePickerValueBackup;
        }
    }

    _datePickerValueBackup = nil;
}

- (void)datePickerCellDidBecomeFirstResponder:(NSDatePickerCell *)aDatePickerCell
{
    _datePickerValueBackup = [[aDatePickerCell dateValue] copy];
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
    [_startDatePicker bind:@"datePickerElements" toObject:self withKeyPath:@"datePickerElements" options:nil];
    [_endDatePicker bind:@"datePickerElements" toObject:self withKeyPath:@"datePickerElements" options:nil];

    [self resetDefaults:nil];
}

@end


@implementation WLNewEventWindowController (Appearance)

+ (NSSet *)keyPathsForValuesAffectingDatePickerElements
{
    return [NSSet setWithObject:@"self.isAllDay"];
}

- (NSDatePickerElementFlags)datePickerElements
{
    if (self.isAllDay)
        return NSYearMonthDayDatePickerElementFlag;
    else
        return NSYearMonthDayDatePickerElementFlag | NSHourMinuteDatePickerElementFlag;
}

@end

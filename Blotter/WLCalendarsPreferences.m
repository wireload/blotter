//
//  WLCalendarsPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLCalendarsPreferences.h"
#import "WLColorCheckboxCell.h"
#import "NSColor+WLCalendar.h"
#import "DeskboardAppDelegate.h"


@implementation WLCalendarsPreferences
{
    NSArray *_calEventCalendars;
    NSArray *_calReminderCalendars;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Methods

- (void)calCalendarsDidChange:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        WLCalendarsController *c = [[[NSApp delegate] calendarWindowController] calendarsController];
        _calEventCalendars = [c.calEventCalendars copy];
        _calReminderCalendars = [c.calReminderCalendars copy];
        [_eventsTableView reloadData];
        [_remindersTableView reloadData];
    });
}


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kToolbarLabelsIcon)];
    anItem.label = NSLocalizedStringFromTableInBundle(@"Calendars", nil, [NSBundle bundleForClass:[self class]], @"Calendars pref pane title");
    anItem.toolTip = NSLocalizedStringFromTableInBundle(@"Calendars to display", nil, [NSBundle bundleForClass:[self class]], @"Calendars pref pane tooltip");
}


#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        WLColorCheckboxCell *cell = aCell;
        NSColor *calColor = nil;

        if (aTableView == _eventsTableView)
            calColor = [_calEventCalendars[rowIndex] color];
        else
            calColor = [_calReminderCalendars[rowIndex] color];

        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == _eventsTableView)
        return [_calEventCalendars count];
    else
        return [_calReminderCalendars count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    WLCalendarsController *c = [[[NSApp delegate] calendarWindowController] calendarsController];
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        if (aTableView == _eventsTableView)
            return @([c isCalCalendarUsedToDisplayEvents:_calEventCalendars[rowIndex]]);
        else
            return @([c isCalCalendarUsedToDisplayReminders:_calReminderCalendars[rowIndex]]);
    }
    else
    {
        if (aTableView == _eventsTableView)
            return [_calEventCalendars[rowIndex] title];
        else
            return [_calReminderCalendars[rowIndex] title];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        WLCalendarsController *c = [[[NSApp delegate] calendarWindowController] calendarsController];
        if (aTableView == _eventsTableView)
            [c setCalCalendar:_calEventCalendars[rowIndex] usedToDisplayEvents:[anObject boolValue]];
        else
            [c setCalCalendar:_calReminderCalendars[rowIndex] usedToDisplayReminders:[anObject boolValue]];
    }
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];

    [_eventsTableView setIntercellSpacing:NSMakeSize(3.0, 0.0)];
    [_eventsTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [_remindersTableView setIntercellSpacing:NSMakeSize(3.0, 0.0)];
    [_remindersTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];

    WLCalendarsController *c = [[[NSApp delegate] calendarWindowController] calendarsController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(calCalendarsDidChange:)
                                                 name:WLCalCalendarsDidChangeNotification
                                               object:c];
    [self calCalendarsDidChange:nil];
}

@end

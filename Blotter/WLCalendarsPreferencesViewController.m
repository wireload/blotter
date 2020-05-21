//
//  WLCalendarsPreferencesViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 11/7/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import "WLCalendarsPreferencesViewController.h"
#import "WLColorCheckboxCell.h"
#import "DeskboardAppDelegate.h"


@implementation WLCalendarsPreferencesViewController
{
    NSArray *_calEventCalendars;
    NSArray *_calReminderCalendars;
}

#pragma mark Methods

- (void)calCalendarsDidChange:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        __auto_type calendarsController = WLAppDelegate.calendarsController;
        self->_calEventCalendars = [calendarsController.calEventCalendars copy];
        self->_calReminderCalendars = [calendarsController.calReminderCalendars copy];
        [self->_eventsTableView reloadData];
        [self->_remindersTableView reloadData];
    });
}

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualToString:@"check"])
    {
        WLColorCheckboxCell *cell = aCell;
        NSColor *calColor = nil;

        if (aTableView == _eventsTableView)
            calColor = [_calEventCalendars[(NSUInteger)rowIndex] color];
        else
            calColor = [_calReminderCalendars[(NSUInteger)rowIndex] color];

        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == _eventsTableView)
        return (NSInteger)_calEventCalendars.count;
    else
        return (NSInteger)_calReminderCalendars.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    WLCalendarsController *c = WLAppDelegate.calendarsController;
    if ([aTableColumn.identifier isEqualToString:@"check"])
    {
        if (aTableView == _eventsTableView)
            return @([c isCalCalendarUsedToDisplayEvents:_calEventCalendars[(NSUInteger)rowIndex]]);
        else
            return @([c isCalCalendarUsedToDisplayReminders:_calReminderCalendars[(NSUInteger)rowIndex]]);
    }
    else
    {
        if (aTableView == _eventsTableView)
            return [_calEventCalendars[(NSUInteger)rowIndex] title];
        else
            return [_calReminderCalendars[(NSUInteger)rowIndex] title];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualToString:@"check"])
    {
        __auto_type c = WLAppDelegate.calendarsController;
        if (aTableView == _eventsTableView)
            [c setCalCalendar:_calEventCalendars[(NSUInteger)rowIndex] usedToDisplayEvents:[anObject boolValue]];
        else
            [c setCalCalendar:_calReminderCalendars[(NSUInteger)rowIndex] usedToDisplayReminders:[anObject boolValue]];
    }
}

#pragma mark WLPreferencesViewController

- (NSTabViewItem *)makeTabViewItem
{
    NSTabViewItem *t = [super makeTabViewItem];
    t.image = [NSImage imageNamed:@"preferences-calendars-icon"];
    t.label = NSLocalizedString(@"Calendars", @"Calendars pref pane title");
    t.toolTip = NSLocalizedString(@"Calendars to display", @"Calendars pref pane tooltip");
    return t;
}

#pragma mark NSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _eventsTableView.intercellSpacing = NSMakeSize(3.0, 0.0);
    _eventsTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    _remindersTableView.intercellSpacing = NSMakeSize(3.0, 0.0);
    _remindersTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;

    __auto_type c = WLAppDelegate.calendarsController;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(calCalendarsDidChange:)
                                                 name:WLCalCalendarsDidChangeNotification
                                               object:c];
    [self calCalendarsDidChange:nil];
}

@end

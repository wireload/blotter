//
//  WLCalendarsPreferences.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLCalendarsPreferences.h"
#import "WLColorCheckboxCell.h"
#import "NSColor+WLCalendar.h"


@implementation WLCalendarsPreferences

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.isViewLoaded)
    {
        [(WLCalendarController *)[WLCalendarController sharedController] removeObserver:self forKeyPath:@"calEventCalendars"];
        [(WLCalendarController *)[WLCalendarController sharedController] removeObserver:self forKeyPath:@"calReminderCalendars"];
    }
    [super dealloc];
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
        WLCalendarController *c = [WLCalendarController sharedController];
        if (aTableView == _eventsTableView)
            calColor = [[c.calEventCalendars objectAtIndex:rowIndex] color];
        else
            calColor = [[c.calReminderCalendars objectAtIndex:rowIndex] color];
        if (calColor == nil || (id)calColor == [NSNull null])
            calColor = [NSColor WL_defaultCalendarColorIfFrameworkFails];
        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    WLCalendarController *c = [WLCalendarController sharedController];
    if (aTableView == _eventsTableView)
        return [c.calEventCalendars count];
    else
        return [c.calReminderCalendars count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    WLCalendarController *c = [WLCalendarController sharedController];
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        if (aTableView == _eventsTableView)
            return [NSNumber numberWithBool:[c isCalendarWithUIDUsedForEvents:[[c.calEventCalendars objectAtIndex:rowIndex] uid]]];
        else
            return [NSNumber numberWithBool:[c isCalendarWithUIDUsedForReminders:[[c.calReminderCalendars objectAtIndex:rowIndex] uid]]];
    }
    else
    {
        if (aTableView == _eventsTableView)
            return [[c.calEventCalendars objectAtIndex:rowIndex] title];
        else
            return [[c.calReminderCalendars objectAtIndex:rowIndex] title];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        WLCalendarController *c = [WLCalendarController sharedController];
        if (aTableView == _eventsTableView)
            [c setIsUsedForEvents:[anObject boolValue] forCalendarWithUID:[[c.calEventCalendars objectAtIndex:rowIndex] uid]];
        else
            [c setIsUsedForReminders:[anObject boolValue] forCalendarWithUID:[[c.calReminderCalendars objectAtIndex:rowIndex] uid]];
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
    [(WLCalendarController *)[WLCalendarController sharedController] addObserver:self
                                                                      forKeyPath:@"calEventCalendars"
                                                                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                                         context:NULL];
    [(WLCalendarController *)[WLCalendarController sharedController] addObserver:self
                                                                      forKeyPath:@"calReminderCalendars"
                                                                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                                         context:NULL];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"calEventCalendars"])
        [_eventsTableView reloadData];
    else if ([aKeyPath isEqualToString:@"calReminderCalendars"])
        [_remindersTableView reloadData];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aChange];
}

@end

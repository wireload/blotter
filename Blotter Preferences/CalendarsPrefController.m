//
//  CalendarsPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "CalendarsPrefController.h"
#import "WLColorCheckboxCell.h"


@implementation CalendarsPrefController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_mainView != nil)
    {
        [(WLCalendarController *)[WLCalendarController sharedController] removeObserver:self forKeyPath:@"calEventCalendars"];
        [(WLCalendarController *)[WLCalendarController sharedController] removeObserver:self forKeyPath:@"calReminderCalendars"];
    }
    [super dealloc];
}


#pragma mark SS_PreferencePaneProtocol

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"CalendarsPrefPaneView" owner:self])
        {
            _mainView.preferredFrameSize = [_mainView frame].size;
            [_eventsTableView setIntercellSpacing:NSMakeSize(3.0f, 0.0f)];
            [_eventsTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
            [_remindersTableView setIntercellSpacing:NSMakeSize(3.0f, 0.0f)];
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
        else
            NSLog(@"Cannot load CalendarsPrefPaneView");
    }
    return _mainView;
}

- (NSString *)paneName
{
    return NSLocalizedStringFromTableInBundle(@"Calendars", nil, [NSBundle bundleForClass:[self class]], @"Calendars pref pane title");
}

- (NSImage *)paneIcon
{
    return [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kToolbarLabelsIcon)];
}

- (NSString *)paneToolTip
{
    return NSLocalizedStringFromTableInBundle(@"Calendars to display", nil, [NSBundle bundleForClass:[self class]], @"Calendars pref pane tooltip");
}

- (BOOL)allowsHorizontalResizing
{
    return NO;
}

- (BOOL)allowsVerticalResizing
{
    return NO;
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
        NSString *uid = nil;
        if (aTableView == _eventsTableView)
            uid = [[c.calEventCalendars objectAtIndex:rowIndex] uid];
        else
            uid = [[c.calReminderCalendars objectAtIndex:rowIndex] uid];
        return [NSNumber numberWithBool:[c checkForCalendarWithUID:uid]];
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
        NSString *uid = nil;
        WLCalendarController *c = [WLCalendarController sharedController];
        if (aTableView == _eventsTableView)
            uid = [[c.calEventCalendars objectAtIndex:rowIndex] uid];
        else
            uid = [[c.calReminderCalendars objectAtIndex:rowIndex] uid];
        [c setDisplay:[anObject boolValue] forCalendarWithUID:uid];
    }
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

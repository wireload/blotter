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
#import "WLPrefPaneView.h"
#import "WLCalendarController.h"


@implementation CalendarsPrefController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"Calendars"];
    [_cachedEventCalCalendars release];
    [_cachedReminderCalCalendars release];
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
            [[NSUserDefaults standardUserDefaults] addObserver:self
                                                    forKeyPath:@"Calendars"
                                                       options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                       context:NULL];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_calCalendarsDidChange:)
                                                         name:CalCalendarsChangedExternallyNotification
                                                       object:[CalCalendarStore defaultCalendarStore]];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_calCalendarsDidChange:)
                                                         name:CalCalendarsChangedNotification
                                                       object:[CalCalendarStore defaultCalendarStore]];
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
        if (aTableView == _eventsTableView)
            calColor = [[self._cachedEventCalCalendars objectAtIndex:rowIndex] color];
        else
            calColor = [[self._cachedReminderCalCalendars objectAtIndex:rowIndex] color];
        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == _eventsTableView)
        return [self._cachedEventCalCalendars count];
    else
        return [self._cachedReminderCalCalendars count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        NSString *uid = nil;
        if (aTableView == _eventsTableView)
            uid = [[self._cachedEventCalCalendars objectAtIndex:rowIndex] uid];
        else
            uid = [[self._cachedReminderCalCalendars objectAtIndex:rowIndex] uid];
        return [[self _calCalendarDictForUID:uid] objectForKey:@"check"];
    }
    else
    {
        if (aTableView == _eventsTableView)
            return [[self._cachedEventCalCalendars objectAtIndex:rowIndex] title];
        else
            return [[self._cachedReminderCalCalendars objectAtIndex:rowIndex] title];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        NSString *uid = nil;
        if (aTableView == _eventsTableView)
            uid = [[self._cachedEventCalCalendars objectAtIndex:rowIndex] uid];
        else
            uid = [[self._cachedReminderCalCalendars objectAtIndex:rowIndex] uid];
        [self _setState:anObject forCalCalendarWithUID:uid];
    }
}


#pragma mark Private
@synthesize _cachedEventCalCalendars;
@synthesize _cachedReminderCalCalendars;

- (NSDictionary *)_calCalendarDictForUID:(NSString *)anUID
{
    NSArray *calendars = [[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"];
    NSUInteger index = [calendars indexOfObject:[NSDictionary dictionaryWithObject:anUID forKey:@"uid"]
                                  inSortedRange:NSMakeRange(0, [calendars count])
                                        options:NSBinarySearchingFirstEqual
                                usingComparator:^(id left, id right) {
                                    return [[left objectForKey:@"uid"] compare:[right objectForKey:@"uid"]];
                                }];
    if (index != NSNotFound)
        return [calendars objectAtIndex:index];
    else
    {
        NSLog(@"Cannot find calendar with UID %@. Please, contact the developers.", anUID);
        return  nil;
    }
}

- (void)_setState:(NSNumber *)newState forCalCalendarWithUID:(NSString *)anUID
{
    NSMutableArray *calendars = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"] mutableCopy] autorelease];

    NSUInteger index = [calendars indexOfObject:[NSDictionary dictionaryWithObject:anUID forKey:@"uid"]
                                  inSortedRange:NSMakeRange(0, [calendars count])
                                        options:NSBinarySearchingFirstEqual
                                usingComparator:^(id left, id right) {
                                    return [[left objectForKey:@"uid"] compare:[right objectForKey:@"uid"]];
                                }];
    if (index != NSNotFound)
    {
        NSMutableDictionary *newCalendar = [[calendars objectAtIndex:index] mutableCopy];
        [newCalendar setObject:newState forKey:@"check"];
        [calendars replaceObjectAtIndex:index withObject:newCalendar];
        [[NSUserDefaults standardUserDefaults] setObject:calendars forKey:@"Calendars"];
    }
    else
        NSLog(@"Cannot find calendar with UID %@. Please, contact the developers.", anUID);
}

- (void)_calCalendarsDidChange:(NSNotification *)aNotification
{
    NSSet *updatedCalCalendarUIDs = [NSSet setWithArray:[[aNotification userInfo] objectForKey:CalUpdatedRecordsKey]];
    NSSet *calCalendarUIDs = [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"Calendars.uid"]];
    if ([updatedCalCalendarUIDs intersectsSet:calCalendarUIDs])
    {
        for (NSString *uid in updatedCalCalendarUIDs)
        {
            CalCalendar *updatedCalCalendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:uid];
            NSUInteger index = [self._cachedEventCalCalendars indexOfObjectPassingTest:^BOOL(CalCalendar *c, NSUInteger idx, BOOL *stop) {
                return [c.uid isEqualToString:uid];
            }];
            if (index != NSNotFound)
                [self._cachedEventCalCalendars replaceObjectAtIndex:index withObject:updatedCalCalendar];
            else
            {
                index = [self._cachedReminderCalCalendars indexOfObjectPassingTest:^BOOL(CalCalendar *c, NSUInteger idx, BOOL *stop) {
                    return [c.uid isEqualToString:uid];
                }];
                [self._cachedReminderCalCalendars replaceObjectAtIndex:index withObject:updatedCalCalendar];
            }
        }
        [self._cachedEventCalCalendars sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                                                              ascending:YES
                                                                                                               selector:@selector(localizedCaseInsensitiveCompare:)]]];
        [_eventsTableView reloadData];
        [self._cachedReminderCalCalendars sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                                                                   ascending:YES
                                                                                                                    selector:@selector(localizedCaseInsensitiveCompare:)]]];
        [_remindersTableView reloadData];
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"Calendars"])
    {
        NSArray *calCalendarUIDs = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"Calendars.uid"];
        NSMutableArray *calCalendars = [NSMutableArray arrayWithCapacity:[calCalendarUIDs count]];
        for (NSString *uid in calCalendarUIDs)
        {
            CalCalendar *c = [[CalCalendarStore defaultCalendarStore] calendarWithUID:uid];
            if (c != nil)
                [calCalendars addObject:c];
        }
        [calCalendars sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                                                  ascending:YES
                                                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]]];
        self._cachedEventCalCalendars = [[[[NSClassFromString(@"WLCalendarController") sharedController] calEventCalendarsFromCalCalendars:calCalendars] mutableCopy] autorelease];
        [_eventsTableView reloadData];
        self._cachedReminderCalCalendars = [[[[NSClassFromString(@"WLCalendarController") sharedController] calReminderCalendarsFromCalCalendars:calCalendars] mutableCopy] autorelease];
        [_remindersTableView reloadData];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aChange];
}

@end

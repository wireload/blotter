//
//  CalendarsPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "CalendarsPrefController.h"
#import "ColorCheckboxCell.h"


@implementation CalendarsPrefController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"Calendars"];
    [_cachedCalCalendars release];
    [super dealloc];
}


#pragma mark SS_PreferencePaneProtocol

- (NSView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"CalendarsPrefPaneView" owner:self])
        {
            [_tableView setIntercellSpacing:NSMakeSize(3, 0)];
            [_tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
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
        ColorCheckboxCell *cell = aCell;
        NSColor *calColor = [[self._cachedCalCalendars objectAtIndex:rowIndex] color];
        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self._cachedCalCalendars count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        NSString *uid = [[self._cachedCalCalendars objectAtIndex:rowIndex] uid];
        return [[self _calCalendarDictForUID:uid] objectForKey:@"check"];
    }
    else
        return [[self._cachedCalCalendars objectAtIndex:rowIndex] title];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"check"])
    {
        NSString *uid = [[self._cachedCalCalendars objectAtIndex:rowIndex] uid];
        [self _setState:anObject forCalCalendarWithUID:uid];
    }
}


#pragma mark Private
@synthesize _cachedCalCalendars;

- (NSDictionary *)_calCalendarDictForUID:(NSString *)anUID
{
    NSArray *calendars = [[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"];
    NSUInteger index = [calendars indexOfObject:[NSDictionary dictionaryWithObject:anUID forKey:@"uid"]
                                  inSortedRange:NSMakeRange(0, [calendars count])
                                        options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
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
        NSDictionary *newCalendar = [NSDictionary dictionaryWithObjectsAndKeys:anUID, @"uid", newState, @"check", nil];
        [calendars replaceObjectAtIndex:index withObject:newCalendar];
        [[NSUserDefaults standardUserDefaults] setObject:calendars forKey:@"Calendars"];
    }
    else
    {
        NSLog(@"Cannot find calendar with UID %@. Please, contact the developers.", anUID);
    }
}

- (void)_calCalendarsDidChange:(NSNotification *)aNotification
{
    // Only update calendars (to match color, title etc).
    NSSet *updatedCalCalendarUIDs = [NSSet setWithArray:[[aNotification userInfo] objectForKey:CalUpdatedRecordsKey]];
    NSSet *calCalendarUIDs = [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"Calendars.uid"]];
    if ([updatedCalCalendarUIDs intersectsSet:calCalendarUIDs])
    {
        for (NSString *uid in updatedCalCalendarUIDs)
        {
            NSUInteger index = [self._cachedCalCalendars indexOfObjectPassingTest:^BOOL(CalCalendar *c, NSUInteger idx, BOOL *stop) {
                return [c.uid isEqualToString:uid];
            }];
            CalCalendar *updatedCalCalendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:uid];
            [self._cachedCalCalendars replaceObjectAtIndex:index withObject:updatedCalCalendar];
        }
        [self._cachedCalCalendars sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                                                              ascending:YES
                                                                                                               selector:@selector(localizedCaseInsensitiveCompare:)]]];
        [_tableView reloadData];
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
        self._cachedCalCalendars = calCalendars;
        [_tableView reloadData];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aChange];
}

@end

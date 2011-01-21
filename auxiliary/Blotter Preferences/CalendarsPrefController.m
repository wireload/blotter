//
//  CalendarsPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "CalendarsPrefController.h"
#import "ColorCheckboxCell.h"

@interface CalendarsPrefController (/* Private */)
@property (copy) NSArray *_cachedCalCalendars;

- (NSDictionary *)_calendarForUID:(NSString *)anUID;

- (void)_setState:(NSNumber *)newState forCalendarWithUID:(NSString *)anUID;

@end


@implementation CalendarsPrefController
@synthesize _cachedCalCalendars;

- (id)init {
    if (self = [super init]) {
        _calCalendarStoreObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CalCalendarsChangedExternallyNotification
                                                                                      object:[CalCalendarStore defaultCalendarStore]
                                                                                       queue:nil
                                                                                  usingBlock:^(NSNotification *arg1) {
                                                                                      self._cachedCalCalendars = [[CalCalendarStore defaultCalendarStore] calendars];
                                                                                      [_tableView reloadData];
                                                                                  }];
        self._cachedCalCalendars = [[CalCalendarStore defaultCalendarStore] calendars];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:_calCalendarStoreObserver];
    [super dealloc];
}

- (NSDictionary *)_calendarForUID:(NSString *)anUID {
    NSMutableArray *calendars = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"] mutableCopy] autorelease];

    NSUInteger index = [calendars indexOfObject:[NSDictionary dictionaryWithObject:anUID forKey:@"uid"]
                                  inSortedRange:NSMakeRange(0, [calendars count])
                                        options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                usingComparator:^(id left, id right) {
                                    return [[left objectForKey:@"uid"] compare:[right objectForKey:@"uid"]];
                                }];

    if (index != NSNotFound && index != [calendars count] && [[[calendars objectAtIndex:index] objectForKey:@"uid"] isEqualToString:anUID]) {
        return [calendars objectAtIndex:index];
    }
    else {
        NSDictionary *newCalendar = [NSDictionary dictionaryWithObjectsAndKeys:anUID, @"uid", [NSNumber numberWithBool:YES], @"check", nil];
        [calendars insertObject:newCalendar
                        atIndex:index];
        [[NSUserDefaults standardUserDefaults] setObject:calendars forKey:@"Calendars"];
        return newCalendar;
    }
}

- (void)_setState:(NSNumber *)newState forCalendarWithUID:(NSString *)anUID {
    NSMutableArray *calendars = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendars"] mutableCopy] autorelease];

    NSUInteger index = [calendars indexOfObject:[NSDictionary dictionaryWithObject:anUID forKey:@"uid"]
                                  inSortedRange:NSMakeRange(0, [calendars count])
                                        options:NSBinarySearchingFirstEqual
                                usingComparator:^(id left, id right) {
                                    return [[left objectForKey:@"uid"] compare:[right objectForKey:@"uid"]];
                                }];

    if (index != NSNotFound) {
        NSDictionary *newCalendar = [NSDictionary dictionaryWithObjectsAndKeys:anUID, @"uid", newState, @"check", nil];
        [calendars replaceObjectAtIndex:index withObject:newCalendar];
        [[NSUserDefaults standardUserDefaults] setObject:calendars forKey:@"Calendars"];
    }
}


#pragma mark SS_PreferencePaneProtocol

- (NSView *)paneView
{
    BOOL loaded = YES;

    if (!_mainView)
    {
        loaded = [NSBundle loadNibNamed:@"CalendarsPrefPaneView" owner:self];
        [_tableView setIntercellSpacing:NSMakeSize(3, 0)];
        [_tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    }

    if (loaded)
        return _mainView;

    return nil;
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

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
        ColorCheckboxCell *cell = aCell;
        NSColor *calColor = [[self._cachedCalCalendars objectAtIndex:rowIndex] color];
        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self._cachedCalCalendars count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
        NSString *uid = [[self._cachedCalCalendars objectAtIndex:rowIndex] uid];
        return [[self _calendarForUID:uid] objectForKey:@"check"];
    }
    else {
        return [[self._cachedCalCalendars objectAtIndex:rowIndex] title];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
        NSString *uid = [[self._cachedCalCalendars objectAtIndex:rowIndex] uid];
        [self _setState:anObject forCalendarWithUID:uid];
    }
}

@end

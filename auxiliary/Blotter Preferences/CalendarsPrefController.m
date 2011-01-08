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

- (NSDictionary *)_calendarForUID:(NSString *)anUID;

- (void)_setState:(NSNumber *)newState forCalendarWithUID:(NSString *)anUID;

@end


@implementation CalendarsPrefController

- (void)dealloc {
    if (tableView != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:tableView];
    }
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

    if (!mainView)
    {
        loaded = [NSBundle loadNibNamed:@"CalendarsPrefPaneView" owner:self];
        [tableView setIntercellSpacing:NSMakeSize(3, 0)];
        [[NSNotificationCenter defaultCenter] addObserver:tableView
                                                 selector:@selector(reloadData)
                                                     name:CalCalendarsChangedExternallyNotification
                                                   object:[CalCalendarStore defaultCalendarStore]];
    }

    if (loaded)
        return mainView;

    return nil;
}

- (NSString *)paneName
{
    return @"Calendars";
}

- (NSImage *)paneIcon
{
    return [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kToolbarDesktopFolderIcon)];

}

- (NSString *)paneToolTip
{
    return @"Calendars to display";
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
        NSColor *calColor = [[[[CalCalendarStore defaultCalendarStore] calendars] objectAtIndex:rowIndex] color];
        [cell setButtonColor:calColor];
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[[CalCalendarStore defaultCalendarStore] calendars] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
        NSArray *calendars = [[CalCalendarStore defaultCalendarStore] calendars];
        NSString *uid = [[calendars objectAtIndex:rowIndex] uid];
        return [[self _calendarForUID:uid] objectForKey:@"check"];
    }
    else {
        return [[[[CalCalendarStore defaultCalendarStore] calendars] objectAtIndex:rowIndex] title];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
        NSString *uid = [[[[CalCalendarStore defaultCalendarStore] calendars] objectAtIndex:rowIndex] uid];
        [self _setState:anObject forCalendarWithUID:uid];
    }
}

@end

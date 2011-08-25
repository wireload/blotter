//
//  WLCalendarWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowController.h"
#import "WLCalendarWeekViewController.h"
#import "WLCalendarTasksViewController.h"
#import "WLCalendarDateViewController.h"
#import "NSDate+WLDayBoundaries.h"
#import "CoreAnimation+WLCalendar.h"


@implementation WLCalendarWindowController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        window = [[WLCalendarWindow alloc] init];
        [window setDelegate:self];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        NSView *contentView = [window contentView];

        _calendarController = [[WLCalendarController alloc] init];

        _weekViewController = [[WLCalendarWeekViewController alloc] init];
        [_weekViewController setRepresentedObject:_calendarController];
        [_weekViewController bind:@"mode" toObject:defaults withKeyPath:@"RollingCalendar" options:nil];
        [_weekViewController bind:@"titleFormat" toObject:defaults withKeyPath:@"PerDayDate" options:nil];
        _weekViewController.highlightWeekends = YES;
        [contentView addSubview:[_weekViewController view]];

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        [_tasksViewController setRepresentedObject:_calendarController];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)], nil];
        _tasksViewController.sortDescriptors = sortDescriptors;
        [contentView addSubview:[_tasksViewController view]];

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        [_dateViewController setRepresentedObject:_calendarController];
        [contentView addSubview:[_dateViewController view]];

        _cache = [[NSCache alloc] init];

        fadeController = [[BLFadeController alloc] initWithView:contentView];
    }
    return self;
}

- (void)dealloc
{
    [window setDelegate:nil];
    [window release];
    [windowScreenIdentifier release];
    [fadeController release];

    [_weekViewController release];
    [_tasksViewController release];
    [_dateViewController release];
    [_cache release];
    [_calendarController release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Properties
@synthesize window;
@synthesize windowSize;
@synthesize windowPosition;
@synthesize windowScreenIdentifier;
@synthesize fadeController;

- (void)setWindowSize:(BLSize)newSize
{
    if (newSize != windowSize)
    {
        windowSize = newSize;
        if (_isWindowShowed)
            [self _updateFrame];
    }
}

- (void)setWindowPosition:(BLPosition)newPosition
{
    if (newPosition != windowPosition)
    {
        windowPosition = newPosition;
        if (_isWindowShowed)
            [self _updateFrame];
    }
}

- (void)setWindowScreenIdentifier:(NSNumber *)newIdentifier
{
    if (windowScreenIdentifier == nil || ![newIdentifier isEqualToNumber:windowScreenIdentifier])
    {
        [windowScreenIdentifier release];
        windowScreenIdentifier = [newIdentifier copy];
        if (_isWindowShowed)
            [self _updateFrame];
    }
}


#pragma mark Methods

- (NSArray *)calendarsToDisplay
{
    BOOL displayAllCalendars = [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayAllCalendars"];
    if (displayAllCalendars)
        return [[CalCalendarStore defaultCalendarStore] calendars];
    else
    {
        NSArray *userCalendars = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Calendars"];
        NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:[userCalendars count]];
        for (NSDictionary *userCalendar in userCalendars)
        {
            if ([[userCalendar objectForKey:@"check"] boolValue])
            {
                CalCalendar *calendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:[userCalendar objectForKey:@"uid"]];
                if (calendar != nil)
                    [calendars addObject:calendar];
            }
        }
        return calendars;
    }
}

- (IBAction)showWindow:(id)aSender
{
    if (!_isWindowShowed)
    {
        [self _updateFrame];
        [self _placeViews];
        [window orderBack:aSender];
        _isWindowShowed = YES;
    }
}


#pragma mark NSWindowDelegate

- (void) windowDidChangeScreen:(NSNotification *)aNotification
{
    [self _updateFrame];
}


#pragma mark Private

- (void)_updateFrame
{
    NSArray *screens = [NSScreen screens];
    NSUInteger selectedScreenIdx = [screens indexOfObjectPassingTest:^(NSScreen *screen, NSUInteger idx, BOOL *stop)
    {
        return [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] isEqualToNumber:windowScreenIdentifier];
    }];

    NSRect screenFrame = NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f);
    if (selectedScreenIdx != NSNotFound)
        screenFrame = [[screens objectAtIndex:selectedScreenIdx] visibleFrame];
    else if ([screens count] > 0)
        screenFrame = [[screens objectAtIndex:0] visibleFrame];

    NSRect windowFrame = [BLCalendarFramer frameForPosition:windowPosition inFrame:screenFrame size:windowSize];
    NSDisableScreenUpdates();
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^(void) {
        [window displayIfNeeded];
        NSEnableScreenUpdates();
    }];
    [window setFrame:windowFrame display:NO];
    [self _applyWindowSizeToViews];
    [CATransaction commit];
}

- (void)_applyWindowSizeToViews
{
    switch (windowSize)
    {
        case BLNarrowSize:
            [self _applyNarrowSizeToViews];
            break;
        case BLNormalSize:
            [self _applyNormalSizeToViews];
            break;
        case BLFullSize:
            [self _applyFullSizeToViews];
            break;
    }
}

- (void)_placeViews
{
    NSRect contentBounds = [window contentViewBounds];
    NSView *contentView = [window contentView];

    WLCalendarDateView *dateView = [_dateViewController view];
    NSRect dateViewFrame = NSMakeRect(NSMinX(contentBounds) + 19.0f,
            NSMinY(contentBounds) + 8.0f,
            255.0f,
            252.0f);
    dateViewFrame = [contentView centerScanRect:dateViewFrame];
    [dateView setFrame:dateViewFrame];

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    NSRect tasksViewFrame = NSMakeRect(NSMinX(dateViewFrame),
            NSMaxY(dateViewFrame),
            dateViewFrame.size.width,
            contentBounds.size.height - (NSMaxY(dateViewFrame) - NSMinY(contentBounds)) - 8.0f);
    tasksViewFrame = [contentView centerScanRect:tasksViewFrame];
    [tasksView setFrame:tasksViewFrame];
    [tasksView setAutoresizingMask:NSViewHeightSizable];

    WLCalendarWeekView *weekView = [_weekViewController view];
    NSRect weekViewFrame = NSMakeRect(NSMaxX(dateViewFrame) + 17.0f,
            NSMinY(dateViewFrame),
            contentBounds.size.width - (NSMaxX(dateViewFrame) - NSMinX(contentBounds)) - 17.0f - 6.0f,
            contentBounds.size.height - (NSMinY(dateViewFrame) - NSMinY(contentBounds)) - 8.0f);
    weekViewFrame = [contentView centerScanRect:weekViewFrame];
    [weekView setFrame:weekViewFrame];
    [weekView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
}

- (void)_applyNarrowSizeToViews
{
    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setHidden:YES];
}

- (void)_applyNormalSizeToViews
{
    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setHidden:NO];
}

- (void)_applyFullSizeToViews
{
    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setHidden:NO];
}

@end

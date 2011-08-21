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


@implementation WLCalendarWindowController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        window = [[WLCalendarWindow alloc] init];
        [window setDelegate:self];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter addObserver:self
                               selector:@selector(_clockChanged:)
                                   name:NSSystemClockDidChangeNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(_clockChanged:)
                                   name:NSSystemTimeZoneDidChangeNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(_localeChanged:)
                                   name:NSCurrentLocaleDidChangeNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(_windowContentViewFrameDidChanged:)
                                   name:NSViewFrameDidChangeNotification
                                 object:[window contentView]];

        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"Calendars"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];

        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"DisplayAllCalendars"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(_clockChanged)
                                                                   name:NSWorkspaceDidWakeNotification
                                                                 object:nil];

        NSView *contentView = [window contentView];

        _weekViewController = [[WLCalendarWeekViewController alloc] init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver:self forKeyPath:@"PerDayDate" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"RollingCalendar" options:NSKeyValueObservingOptionNew context:NULL];
        _weekViewController.titleFormat = [defaults integerForKey:@"PerDayDate"];
        _weekViewController.mode = [defaults integerForKey:@"RollingCalendar"];
        _weekViewController.calcalendars = [self calendarsToDisplay];
        _weekViewController.calendar = [NSCalendar autoupdatingCurrentCalendar];
        _weekViewController.date = [NSDate date];
        [_weekViewController.view setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [contentView addSubview:_weekViewController.view];

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        _tasksViewController.taskPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:[self calendarsToDisplay]];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)], nil];
        _tasksViewController.sortDescriptors = sortDescriptors;
        WLCalendarTasksView *tasksView = [[WLCalendarTasksView alloc] initWithFrame:NSZeroRect];
        [tasksView setAutoresizingMask:NSViewHeightSizable];
        [_tasksViewController setView:tasksView];
        [contentView addSubview:tasksView];
        [tasksView release];

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        _dateViewController.calendar = [NSCalendar autoupdatingCurrentCalendar];
        _dateViewController.date = [NSDate date];
        [_dateViewController.view setAutoresizingMask:NSViewNotSizable];
        [contentView addSubview:_dateViewController.view];

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

    [_weekViewController release];
    [_tasksViewController release];
    [_dateViewController release];
    [_cache release];
    [fadeController release];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"Calendars"];
    [defaults removeObserver:self forKeyPath:@"DisplayAllCalendars"];
    [defaults removeObserver:self forKeyPath:@"PerDayDate"];
    [defaults removeObserver:self forKeyPath:@"RollingCalendar"];
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
        [_weekViewController updateViewAnimated:NO];
        [_dateViewController updateViewAnimated:NO];
        [self _updateFrame];
        [window orderBack:aSender];
        [self _scheduleNextDayTimer];
        _isWindowShowed = YES;
    }
}


#pragma mark NSWindowDelegate

- (void) windowDidChangeScreen:(NSNotification *)aNotification
{
    [self _updateFrame];
    [_weekViewController updateViewAnimated:NO];
    [_dateViewController updateViewAnimated:NO];
}


#pragma mark Private

- (void)_updateFrame
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%@", NSStringFromSelector(_cmd));
#endif
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
    [window setFrame:windowFrame display:NO];
    if (!_isWindowShowed)
        [self _placeViews];
    [self _applyWindowSizeToViews];
    [window displayIfNeeded];
    NSEnableScreenUpdates();
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
    NSRect dateViewFrame = NSMakeRect(NSMinX(contentBounds), NSMinY(contentBounds), 250.0f, 210.0f);
    dateViewFrame = [contentView centerScanRect:dateViewFrame];
    [dateView setFrame:dateViewFrame];

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    NSRect tasksViewFrame = NSMakeRect(NSMinX(contentBounds),
            NSMaxY([dateView frame]),
            [dateView frame].size.width,
            contentBounds.size.height - [dateView frame].size.height);
    tasksViewFrame = [contentView centerScanRect:tasksViewFrame];
    [tasksView setFrame:tasksViewFrame];
    [tasksView setAutoresizingMask:NSViewHeightSizable];

    WLCalendarWeekView *weekView = [_weekViewController view];
    NSRect weekViewFrame = NSMakeRect(NSMaxX([tasksView frame]) + 10.0f,
            NSMinY(contentBounds),
            contentBounds.size.width - [tasksView frame].size.width,
            contentBounds.size.height);
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

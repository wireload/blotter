//
//  WLCalendarWindowController.m
//  Blotter
//
//  Created by Илья Кулаков on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowController.h"


@implementation WLCalendarWindowController
@synthesize windowSize;
@synthesize windowPosition;
@synthesize windowScreenIdentifier;

- (id)initWithWindow:(WLCalendarWindow *)aWindow
{
    self = [super initWithWindow:aWindow];
    if (self != nil)
    {
        [[self window] setDelegate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_updateFrame)
                                                     name:NSApplicationDidChangeScreenParametersNotification
                                                   object:nil];

        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"Calendars"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"DisplayAllCalendars"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];

        NSView *contentView = [[self window] contentView];
        _weekViewController = [[WLCalendarWeekViewController alloc] initWithNibName:nil bundle:nil];
        [_weekViewController bind:@"titleFormat" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"PerDayDate" options:nil];
        [_weekViewController bind:@"mode" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"RollingCalendar" options:nil];
        [_weekViewController setRepresentedObject:[self calendarsToDisplay]];
        WLCalendarWeekView *weekView = [[WLCalendarWeekView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f)];
        [_weekViewController setView:weekView];
        [contentView addSubview:weekView];
        [weekView release];

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        _tasksViewController.taskPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:[self calendarsToDisplay]];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)], nil];
        _tasksViewController.sortDescriptors = sortDescriptors;
        WLCalendarTasksView *tasksView = [[WLCalendarTasksView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f)];
        [_tasksViewController setView:tasksView];
        [contentView addSubview:tasksView];
        [tasksView release];
    }
    return self;
}

- (void)dealloc
{
    [[self window] setDelegate:nil];
    [_weekViewController release];
    [_tasksViewController release];
    [windowScreenIdentifier release];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"Calendars"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"DisplayAllCalendars"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (WLCalendarWindow *)window
{
    return (WLCalendarWindow *)[super window];
}

- (void)setWindow:(WLCalendarWindow *)newWindow
{
    [super setWindow:newWindow];
}

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


#pragma mark NSWindowDelegate

- (void)windowDidChangeScreenProfile:(NSNotification *)aNotification
{

}

- (void)windowDidChangeScreen:(NSNotification *)aNotification
{
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
    [[self window] setFrame:windowFrame display:NO];
    [self _applyWindowSizeToViews];
    [[self window] displayIfNeeded];
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

- (void)_applyNarrowSizeToViews
{
    WLCalendarTasksView *tasksView = [_tasksViewController view];
    [tasksView setFrame:[[self window] contentViewBounds]];

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setHidden:YES];
}

- (void)_applyNormalSizeToViews
{
    NSRect contentBounds = [[self window] contentViewBounds];

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    [tasksView setFrame:NSMakeRect(contentBounds.origin.x,
                                   contentBounds.origin.y,
                                   250.0f,
                                   contentBounds.size.height)];

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setFrame:NSMakeRect(contentBounds.origin.x + [tasksView frame].size.width,
                                  contentBounds.origin.y,
                                  contentBounds.size.width - [tasksView frame].size.width,
                                  contentBounds.size.height)];
    [weekView setHidden:NO];
}

- (void)_applyFullSizeToViews
{
    NSRect contentBounds = [[self window] contentViewBounds];

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    [tasksView setFrame:NSMakeRect(contentBounds.origin.x,
                                   contentBounds.origin.y,
                                   250.0f,
                                   contentBounds.size.height)];

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setFrame:NSMakeRect(contentBounds.origin.x + [tasksView frame].size.width,
                                  contentBounds.origin.y,
                                  contentBounds.size.width - [tasksView frame].size.width,
                                  contentBounds.size.height)];
    [weekView setHidden:NO];
}


#pragma mark NSWindow

- (IBAction)showWindow:(id)aSender
{
    NSAssert(!_isWindowShowed, @"Must be called only once after controller is initialized");
    [self _updateFrame];
    [[self window] orderBack:self];
    _isWindowShowed = YES;
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"DisplayAllCalendars"] || [aKeyPath isEqualToString:@"Calendars"])
    {
        [_weekViewController setRepresentedObject:[self calendarsToDisplay]];
        _tasksViewController.taskPredicate = [CalCalendarStore taskPredicateWithCalendars:[self calendarsToDisplay]];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

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
                               selector:@selector(_updateFrame)
                                   name:NSApplicationDidChangeScreenParametersNotification
                                 object:nil];

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
        [contentView addSubview:[_weekViewController view]];

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        _tasksViewController.taskPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:[self calendarsToDisplay]];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)], nil];
        _tasksViewController.sortDescriptors = sortDescriptors;
        WLCalendarTasksView *tasksView = [[WLCalendarTasksView alloc] initWithFrame:NSZeroRect];
        [_tasksViewController setView:tasksView];
        [contentView addSubview:tasksView];
        [tasksView release];

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        _dateViewController.calendar = [NSCalendar autoupdatingCurrentCalendar];
        _dateViewController.date = [NSDate date];
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
        [self _updateViews];
        [self _updateFrame];
        [window orderBack:aSender];
        _isWindowShowed = YES;
        [self _scheduleNextDayTimer];
    }
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
    [window setFrame:windowFrame display:YES];
}

- (void)_windowContentViewFrameDidChanged:(NSNotification *)aNotification
{
    [self _applyWindowSizeToViews];
}

- (void)_applyWindowSizeToViews
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
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
    [CATransaction commit];
}

- (void)_applyNarrowSizeToViews
{
    NSRect contentBounds = [window contentViewBounds];

    WLCalendarDateView *dateView = [_dateViewController view];
    [dateView setFrame:NSMakeRect(NSMinX(contentBounds), NSMinY(contentBounds), contentBounds.size.width, 250.0f)];
    dateView.fontSize = BLNarrowSize;

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    [tasksView setFrame:NSMakeRect(NSMinX(contentBounds),
                                   NSMaxY([dateView frame]),
                                   contentBounds.size.width,
                                   contentBounds.size.height)];

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setHidden:YES];
}

- (void)_applyNormalSizeToViews
{
    NSRect contentBounds = [window contentViewBounds];

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    [tasksView setFrame:NSMakeRect(NSMinX(contentBounds),
                                   NSMinY(contentBounds),
                                   250.0f,
                                   contentBounds.size.height - 210.0f)];

    WLCalendarDateView *dateView = [_dateViewController view];
    [dateView setFrame:NSMakeRect(NSMinX(contentBounds), NSMaxY([tasksView frame]), 250.0f, 210.0f)];
    dateView.fontSize = BLNormalSize;

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setFrame:NSMakeRect(NSMaxX([tasksView frame]),
                                  NSMinY(contentBounds),
                                  contentBounds.size.width - [tasksView frame].size.width,
                                  contentBounds.size.height)];
    [weekView setHidden:NO];
}

- (void)_applyFullSizeToViews
{
    NSRect contentBounds = [window contentViewBounds];

    WLCalendarTasksView *tasksView = [_tasksViewController view];
    [tasksView setFrame:NSMakeRect(NSMinX(contentBounds),
                                   NSMinY(contentBounds),
                                   250.0f,
                                   contentBounds.size.height - 210.0f)];

    WLCalendarDateView *dateView = [_dateViewController view];
    [dateView setFrame:NSMakeRect(NSMinX(contentBounds), NSMaxY([tasksView frame]), 250.0f, 210.0f)];
    dateView.fontSize = BLNormalSize;

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setFrame:NSMakeRect(NSMaxX([tasksView frame]),
                                  NSMinY(contentBounds),
                                  contentBounds.size.width - [tasksView frame].size.width,
                                  contentBounds.size.height)];
    [weekView setHidden:NO];
}

- (void)_localeChanged:(NSNotification *)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateViews) object:nil];
    _updateFlags.updateCalendar = YES;
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0f;
    [self performSelector:@selector(_updateViews) withObject:nil afterDelay:AnyDelay];
}

- (void)_clockChanged:(NSNotification *)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateViews) object:nil];
    _updateFlags.updateDate = YES;
    [self _scheduleNextDayTimer];
    // http://groups.google.com/group/cocoa-unbound/browse_thread/thread/46fe3433cfef6a97#
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        [self performSelector:@selector(_updateViews) withObject:nil afterDelay:0.5];
    else
        [self _updateViews];
}

- (void)_updateViews
{
    if (_updateFlags.updateCalendar)
    {
        NSCalendar *c = [NSCalendar autoupdatingCurrentCalendar];
        _weekViewController.calendar = c;
        _dateViewController.calendar = c;
    }

    if (_updateFlags.updateDate)
    {
        _weekViewController.date = [NSDate date];
        _dateViewController.date = [NSDate date];
    }

    [_weekViewController updateViewAnimated:_isWindowShowed];
    [_dateViewController updateViewAnimated:_isWindowShowed];

    _updateFlags.updateCalendar = NO;
    _updateFlags.updateDate = NO;
}

- (void)_scheduleNextDayTimer
{
    [_nextDayTimer invalidate];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];

    NSDateComponents *oneDayComponents = [[NSDateComponents alloc] init];
    [oneDayComponents setDay:1];
    NSDate *nextDay = [calendar dateByAddingComponents:oneDayComponents toDate:[NSDate date] options:0];
    [oneDayComponents release];
    nextDay = [nextDay WL_upperBoundaryWithCalendar:calendar];
    _nextDayTimer = [[NSTimer alloc] initWithFireDate:nextDay
                                             interval:0.0
                                               target:self
                                             selector:@selector(_showNextDay)
                                             userInfo:nil
                                              repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
    [_nextDayTimer release];
}

- (void)_showNextDay
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [calendar components:NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
    NSDateComponents *representedComponents = [calendar components:NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit
                                                          fromDate:_weekViewController.date];
    // Though accuracy of NSTimer is documented as 50-100ms, we must ensure that day is actually changed.
    if ([nowComponents day] != [representedComponents day] || [nowComponents month] != [representedComponents month])
    {
        _weekViewController.date = now;
        _dateViewController.date = now;
        [CATransaction begin];
        if (_weekViewController.mode == WLCalendarWeekViewWeekMode && [nowComponents week] != [representedComponents week])
            [_weekViewController showNextWeekAndScroll];
        else
            [_weekViewController showNextDayAndScroll];
        [_dateViewController updateViewAnimated:YES];
        [CATransaction commit];
        [self _scheduleNextDayTimer];
    }
    else
        [self performSelector:@selector(_showNextDay) withObject:nil afterDelay:0.1];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"DisplayAllCalendars"] || [aKeyPath isEqualToString:@"Calendars"])
    {
        _weekViewController.calcalendars = [self calendarsToDisplay];
        [_weekViewController updateViewAnimated:YES];
        _tasksViewController.taskPredicate = [CalCalendarStore taskPredicateWithCalendars:[self calendarsToDisplay]];
    }
    else if ([aKeyPath isEqualToString:@"RollingCalendar"])
    {
        _weekViewController.mode = [[aChange objectForKey:NSKeyValueChangeNewKey] integerValue];
        [_weekViewController updateViewAnimated:YES];
    }
    else if ([aKeyPath isEqualToString:@"PerDayDate"])
    {
        _weekViewController.titleFormat = [[aChange objectForKey:NSKeyValueChangeNewKey] integerValue];
        [_weekViewController updateViewAnimated:YES];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

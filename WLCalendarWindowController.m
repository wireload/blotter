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
#import "WLCalendarBoxView.h"


@implementation WLCalendarWindowController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        window = [[WLCalendarWindow alloc] init];
        [window setDelegate:self];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:window
                                                               selector:@selector(display)
                                                                   name:NSWorkspaceActiveSpaceDidChangeNotification
                                                                 object:nil];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        _calendarController = [[WLCalendarController alloc] init];

        _weekViewController = [[WLCalendarWeekViewController alloc] init];
        [_weekViewController setRepresentedObject:_calendarController];
        [_weekViewController bind:@"mode" toObject:defaults withKeyPath:@"RollingCalendar" options:nil];
        [_weekViewController bind:@"titleFormat" toObject:defaults withKeyPath:@"PerDayDate" options:nil];
        _weekViewController.highlightWeekends = YES;

        _rightNowViewController = [[WLCalendarWeekViewController alloc] init];
        [_rightNowViewController setRepresentedObject:_calendarController];
        _rightNowViewController.mode = WLCalendarWeekViewRightNowMode;

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        [_tasksViewController setRepresentedObject:_calendarController];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)], nil];
        _tasksViewController.sortDescriptors = sortDescriptors;

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        [_dateViewController setRepresentedObject:_calendarController];

        _cache = [[NSCache alloc] init];

        fadeController = [[BLFadeController alloc] initWithView:[window contentView]];
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
    [_rightNowViewController release];
    [_tasksViewController release];
    [_dateViewController release];
    [_cache release];
    [_calendarController release];
    [_tasksViewBox release];
    [_rightNowViewBox release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

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

- (IBAction)showWindow:(id)aSender
{
    if (!_isWindowShowed)
    {
        [self _placeViews];
        [self _updateFrame];
        [window orderBack:aSender];
        _isWindowShowed = YES;
    }
}


#pragma mark NSWindowDelegate

- (void)windowDidChangeScreen:(NSNotification *)aNotification
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

- (void)_placeViews
{
    NSView *contentView = [window contentView];

    [contentView addSubview:[_dateViewController view]];

    _tasksViewBox = [[WLCalendarBoxView alloc] initWithFrame:NSZeroRect];
    _tasksViewBox.title = NSLocalizedString(@"To Do", @"Header of To Do items list");
    _tasksViewBox.contentView = [_tasksViewController view];
    [contentView addSubview:_tasksViewBox];
    [_tasksViewBox release];

    _rightNowViewBox = [[WLCalendarBoxView alloc] initWithFrame:NSZeroRect];
    _rightNowViewBox.title = NSLocalizedString(@"Right Now", @"Header of Right Now items list");
    _rightNowViewBox.contentView = [_rightNowViewController view];
    _rightNowViewBox.showSoftTopAndBottomEdges = YES;
    [contentView addSubview:_rightNowViewBox];
    [_rightNowViewBox release];

    WLCalendarWeekView *weekView = [_weekViewController view];
    [weekView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [contentView addSubview:weekView];
}

@end


@implementation  WLCalendarWindowController (Layout)

static const CGFloat _WLYMarginBetweenTasksAndRightNow = 10.0f;

static const CGFloat _WLWidthOfDateTasksAndRightNow = 255.0f;

static const CGFloat _WLHeightOfDateView = 252.0f;

static const CGFloat _WLXMarginBetweenInfoAndWeek = 17.0f;

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
    [[_dateViewController view] setFrame:[self dateRect]];
    [_tasksViewBox setFrame:[self tasksRect]];
    [_rightNowViewBox setFrame:[self rightNowRect]];
    [[_weekViewController view] setFrame:[self weekRect]];
    [[_weekViewController view] setHidden:YES];
}

- (void)_applyNormalSizeToViews
{
    [[_dateViewController view] setFrame:[self dateRect]];
    [_tasksViewBox setFrame:[self tasksRect]];
    [_rightNowViewBox setFrame:[self rightNowRect]];
    [[_weekViewController view] setFrame:[self weekRect]];
    [[_weekViewController view] setHidden:NO];
}

- (void)_applyFullSizeToViews
{
    [[_dateViewController view] setFrame:[self dateRect]];
    [_tasksViewBox setFrame:[self tasksRect]];
    [_rightNowViewBox setFrame:[self rightNowRect]];
    [[_weekViewController view] setFrame:[self weekRect]];
    [[_weekViewController view] setHidden:NO];
}

- (CGFloat)heightOfTasksAndRightNow
{
    return (NSHeight([window contentViewBounds]) - _WLYMarginBetweenTasksAndRightNow - NSHeight([self dateRect])) / 2.0f;
}

- (NSRect)dateRect
{
    NSRect bounds = [window contentViewBounds];
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                           NSMinY(bounds),
                                                           _WLWidthOfDateTasksAndRightNow,
                                                           _WLHeightOfDateView)];
}

- (NSRect)tasksRect
{
    NSRect bounds = [window contentViewBounds];
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                           NSMaxY([self dateRect]),
                                                           _WLWidthOfDateTasksAndRightNow,
                                                           [self heightOfTasksAndRightNow])];
}

- (NSRect)rightNowRect
{
    NSRect bounds = [window contentViewBounds];
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                           NSMaxY([self tasksRect]) + _WLYMarginBetweenTasksAndRightNow,
                                                           _WLWidthOfDateTasksAndRightNow,
                                                           [self heightOfTasksAndRightNow])];
}

- (NSRect)weekRect
{
    NSRect bounds = [window contentViewBounds];
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds) + _WLWidthOfDateTasksAndRightNow + _WLXMarginBetweenInfoAndWeek,
                                                           NSMinY(bounds),
                                                           NSWidth(bounds) - _WLWidthOfDateTasksAndRightNow - _WLXMarginBetweenInfoAndWeek,
                                                           NSHeight(bounds))];
}

@end
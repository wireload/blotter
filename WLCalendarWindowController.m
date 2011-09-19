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

        _weekViewController = [[WLCalendarWeekViewController alloc] init];
        [_weekViewController setRepresentedObject:[WLCalendarController sharedController]];
        [_weekViewController bind:@"mode" toObject:defaults withKeyPath:@"RollingCalendar" options:nil];
        [_weekViewController bind:@"titleFormat" toObject:defaults withKeyPath:@"PerDayDate" options:nil];
        _weekViewController.highlightWeekends = YES;

        _rightNowViewController = [[WLCalendarWeekViewController alloc] init];
        [_rightNowViewController setRepresentedObject:[WLCalendarController sharedController]];
        _rightNowViewController.mode = WLCalendarWeekViewRightNowMode;

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        [_tasksViewController setRepresentedObject:[WLCalendarController sharedController]];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    nil];
        _tasksViewController.sortDescriptors = sortDescriptors;

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        [_dateViewController setRepresentedObject:[WLCalendarController sharedController]];

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
    [_tasksViewBox release];
    [_rightNowViewBox release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"InfoViewsWidth"];
    [defaults removeObserver:self forKeyPath:@"DateViewHeight"];
    [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
    [defaults removeObserver:self forKeyPath:@"AllDayViewHeight"];
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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver:self forKeyPath:@"InfoViewsWidth" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"DateViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"AllDayViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [self.window orderBack:aSender];
        _isWindowShowed = YES;
    }
}


#pragma mark NSWindowDelegate

- (void)windowDidChangeScreen:(NSNotification *)aNotification
{
    if (_isWindowShowed)
        [self _updateFrame];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"InfoViewsWidth"] ||
        [aKeyPath isEqualToString:@"DateViewHeight"] ||
        [aKeyPath isEqualToString:@"TasksViewHeight"] ||
        [aKeyPath isEqualToString:@"AllDayViewHeight"])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateFrame) object:nil];
        [self performSelector:@selector(_updateFrame) withObject:nil afterDelay:0.0];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation  WLCalendarWindowController (Layout)

static const CGFloat _WLYMarginBetweenTasksAndRightNow = 10.0f;

static const CGFloat _WLXMarginBetweenInfoAndWeek = 17.0f;

static const CGFloat _WLYMarginBetweenBoundsAndDate = -40.0f;

- (void)_applyWindowSizeToViews
{
    switch (self.windowSize)
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
    [[_dateViewController view] setFrame:[self dateViewFrame]];
    [_tasksViewBox setFrame:[self tasksViewFrame]];
    [_rightNowViewBox setFrame:[self rightNowViewFrame]];
    [[_weekViewController view] setHidden:YES];
}

- (void)_applyNormalSizeToViews
{
    [[_dateViewController view] setFrame:[self dateViewFrame]];
    [_tasksViewBox setFrame:[self tasksViewFrame]];
    [_rightNowViewBox setFrame:[self rightNowViewFrame]];
    NSRect weekViewFrame = [self weekViewFrame];
    [_weekViewController view].heightOfAllDayPartOfColumn = [[NSUserDefaults standardUserDefaults] floatForKey:@"AllDayViewHeight"];
    [[_weekViewController view] setFrame:weekViewFrame];
    [[_weekViewController view] setHidden:NO];
}

- (void)_applyFullSizeToViews
{
    [[_dateViewController view] setFrame:[self dateViewFrame]];
    [_tasksViewBox setFrame:[self tasksViewFrame]];
    [_rightNowViewBox setFrame:[self rightNowViewFrame]];
    NSRect weekViewFrame = [self weekViewFrame];
    [_weekViewController view].heightOfAllDayPartOfColumn = [[NSUserDefaults standardUserDefaults] floatForKey:@"AllDayViewHeight"];
    [[_weekViewController view] setFrame:weekViewFrame];
    [[_weekViewController view] setHidden:NO];
}

- (void)_updateFrame
{
    NSArray *screens = [NSScreen screens];
    NSUInteger selectedScreenIdx = [screens indexOfObjectPassingTest:^(NSScreen *screen, NSUInteger idx, BOOL *stop)
                                    {
                                        return [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] isEqualToNumber:self.windowScreenIdentifier];
                                    }];

    NSRect screenFrame = NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f);
    if (selectedScreenIdx != NSNotFound)
        screenFrame = [[screens objectAtIndex:selectedScreenIdx] visibleFrame];
    else if ([screens count] > 0)
        screenFrame = [[screens objectAtIndex:0] visibleFrame];

    NSRect windowFrame = [BLCalendarFramer frameForPosition:self.windowPosition inFrame:screenFrame size:windowSize];
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
    NSParameterAssert(!_isWindowShowed);
    NSView *contentView = [window contentView];
    [contentView setAutoresizesSubviews:NO];

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

- (NSRect)dateViewFrame
{
    NSRect bounds = [[window contentView] bounds];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                           NSMinY(bounds) + _WLYMarginBetweenBoundsAndDate,
                                                           [defaults floatForKey:@"InfoViewsWidth"],
                                                           [defaults floatForKey:@"DateViewHeight"] - _WLYMarginBetweenBoundsAndDate)];
}

- (NSRect)tasksViewFrame
{
    NSRect bounds = [[window contentView] bounds];
    // By default tasks and right now have the same height. Since window size is unknown until user start blotter
    // set the default value here.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"TasksViewHeight"] == nil)
        [defaults setFloat:[self defaultTasksViewHeight] forKey:@"TasksViewHeight"];
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                           NSMaxY([self dateViewFrame]),
                                                           [defaults floatForKey:@"InfoViewsWidth"],
                                                           [defaults floatForKey:@"TasksViewHeight"])];
}

- (NSRect)rightNowViewFrame
{
    NSRect tasksViewFrame = [self tasksViewFrame];
    CGFloat margin = 0.0f;
    if (tasksViewFrame.size.height == 0.0f || fabsf(tasksViewFrame.size.height - 0.0f) < FLT_EPSILON)
        margin = 0.0f;
    else
        margin = _WLYMarginBetweenTasksAndRightNow;
    NSRect bounds = [[self.window contentView] bounds];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat height = NSHeight(bounds) - NSMaxY([self tasksViewFrame]) - margin;
    return [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                           NSMaxY([self tasksViewFrame]) + margin,
                                                           [defaults floatForKey:@"InfoViewsWidth"],
                                                           height)];
}

- (NSRect)weekViewFrame
{
    NSRect bounds = [[window contentView] bounds];
    CGFloat width = NSWidth(bounds) - [[NSUserDefaults standardUserDefaults] floatForKey:@"InfoViewsWidth"] - _WLXMarginBetweenInfoAndWeek;
    return [[window contentView] centerScanRect:NSMakeRect(NSMaxX(bounds) - width,
                                                           NSMinY(bounds),
                                                           width,
                                                           NSHeight(bounds))];
}

- (CGFloat)defaultTasksViewHeight
{
    NSRect bounds = [[self.window contentView] bounds];
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
    return roundf((NSHeight(bounds) - ([[defaults objectForKey:@"DateViewHeight"] floatValue]) - _WLYMarginBetweenTasksAndRightNow) / 2);
}

@end
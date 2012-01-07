//
//  WLCalendarWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowController.h"
#import "WLCalendarWeekViewController.h"
#import "WLCalendarRightNowViewController.h"
#import "WLCalendarNextWeekViewController.h"
#import "WLCalendarTasksViewController.h"
#import "WLCalendarDateViewController.h"
#import "WLCalendarBoxView.h"


// Sizes are chosen so that when switching between these 2 modes only week view is disappeard. that is the date, todo and right now vies are visually unchanged.
// @see WLCalendarWindowController
const NSSize BLNarrowMinimumSize = {290, 750};

const NSSize BLNormalMinimumSize = {950, 750};

/**
    This is the overall smallest possible size for Blotter when using custom sizing.
*/
const NSSize BLMinimumSize = {280, 215};


@interface WLCalendarWindowController (/* Private */)

@property (assign) BOOL isNextWeekHidden;

@end


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

        _rightNowViewController = [[WLCalendarRightNowViewController alloc] init];
        [_rightNowViewController setRepresentedObject:[WLCalendarController sharedController]];
        _rightNowViewController.mode = WLCalendarWeekViewDayMode;

        _nextWeekViewController = [[WLCalendarNextWeekViewController alloc] init];
        [_nextWeekViewController setRepresentedObject:[WLCalendarController sharedController]];
        [_nextWeekViewController bind:@"mode" toObject:_weekViewController withKeyPath:@"mode" options:nil];
        [_nextWeekViewController bind:@"titleFormat" toObject:defaults withKeyPath:@"PerDayDate" options:nil];

        _tasksViewController = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
        [_tasksViewController setRepresentedObject:[WLCalendarController sharedController]];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)],
                                    [NSSortDescriptor sortDescriptorWithKey:@"dateStamp" ascending:YES],
                                    nil];
        _tasksViewController.sortDescriptors = sortDescriptors;

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        [_dateViewController setRepresentedObject:[WLCalendarController sharedController]];

        [defaults addObserver:self forKeyPath:@"CalendarSize" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"CalendarPosition" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"ScreenIdentifier" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"CustomFrameFactors" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"InfoViewsWidth" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"DateViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"AllDayViewHeight" options:NSKeyValueObservingOptionNew context:NULL];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_updateFrame)
                                                     name:NSApplicationDidChangeScreenParametersNotification
                                                   object:NSApp];

        isNextWeekHidden = YES;
    }
    return self;
}

- (void)dealloc
{
    [window setDelegate:nil];
    [window release];
    [fadeController release];

    [_weekViewController release];
    [_rightNowViewController release];
    [_nextWeekViewController release];
    [_tasksViewController release];
    [_dateViewController release];
    [_tasksViewBox release];
    [_rightNowViewBox release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"InfoViewsWidth"];
    [defaults removeObserver:self forKeyPath:@"DateViewHeight"];
    [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
    [defaults removeObserver:self forKeyPath:@"AllDayViewHeight"];
    [defaults removeObserver:self forKeyPath:@"CalendarSize"];
    [defaults removeObserver:self forKeyPath:@"CalendarPosition"];
    [defaults removeObserver:self forKeyPath:@"ScreenIdentifier"];
    [defaults removeObserver:self forKeyPath:@"CustomFrameFactors"];
    [super dealloc];
}


#pragma mark Properties
@synthesize window;
@synthesize fadeController;
@synthesize isNextWeekHidden;


#pragma mark Methods

- (IBAction)showWindow:(id)aSender
{
    if (!_isWindowShowed)
    {
        [self _placeViews];
        [self _updateFrame];
        fadeController = [[WLViewFade alloc] initWithView:[self.window realContentView]];
        [self.window orderBack:aSender];
        _isWindowShowed = YES;
    }
}

- (IBAction)showNextWeekView:(id)aSender
{
    if (_isWindowShowed && self.isNextWeekHidden)
    {
        WLCalendarWeekView *v = [_nextWeekViewController view];
        [CATransaction begin];
        [[v layer] setValue:[NSNumber numberWithBool:YES] forKeyPath:@"backgroundFilters.blur.enabled"];
        [v layer].opacity = 1.0f;
        [CATransaction commit];
        self.isNextWeekHidden = NO;
    }
}

- (IBAction)hideNextWeekView:(id)aSender
{
    if (_isWindowShowed && !self.isNextWeekHidden)
    {
        WLCalendarWeekView *v = [_nextWeekViewController view];
        [CATransaction begin];
        [[v layer] setValue:[NSNumber numberWithBool:NO] forKeyPath:@"backgroundFilters.blur.enabled"];
        [v layer].opacity = 0.0f;
        [CATransaction commit];
        self.isNextWeekHidden = YES;
    }
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
    else if ([aKeyPath isEqualToString:@"CalendarSize"] ||
             [aKeyPath isEqualToString:@"CalendarPosition"] ||
             [aKeyPath isEqualToString:@"ScreenIdentifier"] ||
             [aKeyPath isEqualToString:@"CustomFrameFactors"])
    {
        BLSize calendarSize = (BLSize)[[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"];
        if (![aKeyPath isEqualToString:@"CustomFrameFactors"] ||
            ([aKeyPath isEqualToString:@"CustomFrameFactors"] && calendarSize == BLCustomSize))
        {
            if (_isWindowShowed)
                [self _updateFrame];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation WLCalendarWindowController (Frame)

- (NSRect)windowFrame
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [self windowFrameOnScreen:[self windowScreen]
                        withPosition:(BLPosition)[defaults integerForKey:@"CalendarPosition"]
                                size:(BLSize)[defaults integerForKey:@"CalendarSize"]];
}

- (NSRect)windowFrameOnScreen:(NSScreen *)aScreen withPosition:(BLPosition)aPosition size:(BLSize)aSize
{
    if (aScreen == nil)
        return NSZeroRect;

    NSRect screenFrame = [aScreen visibleFrame];
    NSRect windowFrame = NSZeroRect;
    if (aSize != BLCustomSize)
    {
        static const NSSize Margin = {.width = 14.0f, .height = 14.0f};
        screenFrame = NSInsetRect(screenFrame, Margin.width, Margin.height);
        switch (aSize) {
            case BLNarrowSize:
                windowFrame.size.width = BLNarrowMinimumSize.width;
                windowFrame.size.height = fminf(BLNarrowMinimumSize.height, NSHeight(screenFrame));
                break;
            case BLNormalSize:
                windowFrame.size.width = fmaxf(BLNormalMinimumSize.width, NSWidth(screenFrame) / 2);
                windowFrame.size.height = fmaxf(BLNormalMinimumSize.height, NSHeight(screenFrame) / 2);
                break;
            case BLFullSize:
                windowFrame.size = screenFrame.size;
                break;
            default:
                break;
        }

        CGFloat px = 0.0f;
        CGFloat py = 0.0f;

        if (aPosition == BLPositionTopCenter ||
            aPosition == BLPositionCenterCenter ||
            aPosition == BLPositionBottomCenter)
        {
            px = floor(NSWidth(screenFrame) / 2.0f - NSWidth(windowFrame) / 2.0f);
        }
        else if (aPosition == BLPositionTopRight ||
            aPosition == BLPositionCenterRight ||
            aPosition == BLPositionBottomRight)
        {
            px = NSWidth(screenFrame) - NSWidth(windowFrame);
        }

        if (aPosition == BLPositionTopLeft ||
            aPosition == BLPositionTopCenter ||
            aPosition == BLPositionTopRight)
        {
            py = NSHeight(screenFrame) - NSHeight(windowFrame);
        }
        else if (aPosition == BLPositionCenterLeft ||
            aPosition == BLPositionCenterCenter ||
            aPosition == BLPositionCenterRight)
        {
            py = NSHeight(screenFrame) / 2.0f - NSHeight(windowFrame) / 2.0f;
        }
        windowFrame.origin = NSMakePoint(screenFrame.origin.x + px, screenFrame.origin.y + py);
    }
    else
    {
        NSRect customFrameFactos = NSRectFromString([[NSUserDefaults standardUserDefaults] stringForKey:@"CustomFrameFactors"]);
        windowFrame = NSMakeRect(screenFrame.origin.x + customFrameFactos.origin.x * screenFrame.size.width,
                                 screenFrame.origin.y + customFrameFactos.origin.y * screenFrame.size.height,
                                 customFrameFactos.size.width * screenFrame.size.width,
                                 customFrameFactos.size.height * screenFrame.size.height);
    }

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        return NSIntegralRect(windowFrame);
    else
        return [aScreen backingAlignedRect:windowFrame options:NSAlignAllEdgesInward];
}

- (NSScreen *)windowScreen
{
    NSArray *screens = [NSScreen screens];
    NSNumber *screenIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScreenIdentifier"];
    if ([screens count] > 0)
    {
        NSUInteger index = NSNotFound;
        if (screenIdentifier != nil)
        {
            index = [screens indexOfObjectPassingTest:^(NSScreen *screen, NSUInteger idx, BOOL *stop)
            {
                return [[screen valueForKeyPath:@"deviceDescription.NSScreenNumber"] isEqualToNumber:screenIdentifier];
            }];
        }
        if (index != NSNotFound)
            return [screens objectAtIndex:index];
        else
            return [screens objectAtIndex:0];
    }
    else
        return nil;
}

@end


@implementation  WLCalendarWindowController (Layout)

// Belongs to the right now view.
static const CGFloat _WLYMarginBetweenTasksAndRightNow = 10.0f;

// Belongs to the calendar view.
static const CGFloat _WLXMarginBetweenInfoAndWeek = 17.0f;

// Belongs to the date view.
static const CGFloat _WLYMarginBetweenBoundsAndDate = -40.0f;

- (void)_applyWindowSizeToViews
{
    switch ((BLSize)[[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"])
    {
        case BLNarrowSize:
            [self _applyNarrowSizeToViews];
            break;
        case BLCustomSize:
            [self _applyCustomSizeToViews];
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
    // Ignore width for info section, but don't overwrite it in user defaults.
    CGFloat width = [[self.window contentView] bounds].size.width;

    [self _applyCustomSizeToViews];

    NSRect r = [[_dateViewController view] frame];
    r.size.width = width;
    [[_dateViewController view] setFrame:r];
    [[_dateViewController view] setNeedsDisplay:YES];

    r = [_tasksViewBox frame];
    r.size.width = width;
    [_tasksViewBox setFrame:r];
    [_tasksViewBox setNeedsDisplay:YES];

    r = [_rightNowViewBox frame];
    r.size.width = width;
    [_rightNowViewBox setFrame:r];
    [_rightNowViewBox setNeedsDisplay:YES];

    [[_weekViewController view] setHidden:YES];
    [[_nextWeekViewController view] setHidden:YES];
}

- (void)_applyCustomSizeToViews
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSRect dateViewFrame = [self dateViewFrame];
    NSSize minimumDateViewSize = NSMakeSize([defaults floatForKey:@"MinimumDateViewWidth"],
                                            [defaults floatForKey:@"MinimumDateViewHeight"]);
    BOOL showDateView = (dateViewFrame.size.width >= minimumDateViewSize.width &&
                         dateViewFrame.size.height >= minimumDateViewSize.height);
    [[_dateViewController view] setHidden:!showDateView];
    [[_dateViewController view] setFrame:dateViewFrame];
    [[_dateViewController view] setNeedsDisplay:YES];

    NSRect tasksViewFrame = [self tasksViewFrame];
    NSSize minimumTasksViewSize = NSMakeSize([defaults floatForKey:@"MinimumTasksViewWidth"],
                                             [defaults floatForKey:@"MinimumTasksViewHeight"]);
    BOOL showTasksView = (tasksViewFrame.size.width >= minimumTasksViewSize.width &&
                          tasksViewFrame.size.height >= minimumTasksViewSize.height);
    [_tasksViewBox setHidden:!showTasksView];
    [_tasksViewBox setFrame:tasksViewFrame];
    [_tasksViewBox setNeedsDisplay:YES];

    NSRect rightNowViewFrame = [self rightNowViewFrame];
    NSSize minimumRightNowViewSize = NSMakeSize([defaults floatForKey:@"MinimumRightNowViewWidth"],
                                                [defaults floatForKey:@"MinimumRightNowViewHeight"]);
    BOOL showRightNowView = (rightNowViewFrame.size.width >= minimumRightNowViewSize.width &&
                             rightNowViewFrame.size.height >= minimumRightNowViewSize.height);
    [_rightNowViewBox setHidden:!showRightNowView];
    [_rightNowViewBox setFrame:rightNowViewFrame];
    [_rightNowViewBox setNeedsDisplay:YES];

    NSRect weekViewFrame = [self weekViewFrame];
    [_weekViewController view].heightOfAllDayPartOfColumn = [defaults floatForKey:@"AllDayViewHeight"];
    [[_weekViewController view] setFrame:weekViewFrame];

    // Sizes in defaults know nothing about margins. Take care of them here.
    NSSize minimumWeekViewSize = NSMakeSize([defaults floatForKey:@"MinimumWeekViewWidth"] - _WLXMarginBetweenInfoAndWeek,
                                            [defaults floatForKey:@"MinimumWeekViewHeight"]);
    BOOL isTooSmall = (weekViewFrame.size.width < minimumWeekViewSize.width ||
                       weekViewFrame.size.height < minimumWeekViewSize.height);
    [[_weekViewController view] setHidden:isTooSmall];
    [[_weekViewController view] setNeedsDisplay:YES];

    [_nextWeekViewController view].heightOfAllDayPartOfColumn = [defaults floatForKey:@"AllDayViewHeight"];
    [[_nextWeekViewController view] setFrame:weekViewFrame];
    [[_nextWeekViewController view] setNeedsDisplay:YES];
    [[_nextWeekViewController view] setHidden:isTooSmall];
}

- (void)_applyNormalSizeToViews
{
    [self _applyCustomSizeToViews];
}

- (void)_applyFullSizeToViews
{
    [self _applyCustomSizeToViews];
}

- (void)_updateFrame
{
    NSRect windowFrame = [self windowFrame];
    NSDisableScreenUpdates();
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^(void) {
        [self.window displayIfNeeded];
        NSEnableScreenUpdates();
    }];
    [self.window setFrame:windowFrame display:NO];
    [self _applyWindowSizeToViews];
    [CATransaction commit];
}

- (void)_placeViews
{
    // TODO: There is no need make views to be layer-backed if AutoFade is disabled.
    NSParameterAssert(!_isWindowShowed);
    [[self.window realContentView] setWantsLayer:YES];
    NSView *contentView = [self.window contentView];
    [contentView setAutoresizesSubviews:NO];

    NSView *dateView = [_dateViewController view];
    [dateView setWantsLayer:YES];
    [contentView addSubview:dateView];

    _tasksViewBox = [[WLCalendarBoxView alloc] initWithFrame:NSZeroRect];
    _tasksViewBox.title = NSLocalizedString(@"To Do", @"Header of To Do items list");
    _tasksViewBox.contentView = [_tasksViewController view];
    [_tasksViewBox setWantsLayer:YES];
    [contentView addSubview:_tasksViewBox];
    [_tasksViewBox release];

    _rightNowViewBox = [[WLCalendarBoxView alloc] initWithFrame:NSZeroRect];
    _rightNowViewBox.title = NSLocalizedString(@"Right Now", @"Header of Right Now items list");
    _rightNowViewBox.contentView = [_rightNowViewController view];
    _rightNowViewBox.softEdges = YES;
    [_rightNowViewBox setWantsLayer:YES];
    [contentView addSubview:_rightNowViewBox];
    [_rightNowViewBox release];

    [contentView addSubview:[_weekViewController view]];

    CIFilter *filter = [CIFilter filterWithName:@"CIDiscBlur"];
    filter.name = @"blur";
    filter.enabled = NO;
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:2.0f] forKey:kCIInputRadiusKey];
    WLCalendarWeekView *nextWeekView = [_nextWeekViewController view];
    [nextWeekView layer].backgroundFilters = [NSArray arrayWithObject:filter];
    [nextWeekView layer].opacity = 0.0f;
    [contentView addSubview:nextWeekView];
}

- (CGFloat)fixedInfoViewsWidth
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat infoViewWidth = [defaults floatForKey:@"InfoViewsWidth"];
    CGFloat minWeekWidth = [defaults floatForKey:@"MinimumWeekViewWidth"];
    NSRect bounds = [[window contentView] bounds];
    CGFloat weekWidth = NSWidth(bounds) - infoViewWidth;
    if (weekWidth > minWeekWidth)
        return infoViewWidth;
    else if (weekWidth < minWeekWidth / 2.0f)
        return NSWidth(bounds);
    else
        return NSWidth(bounds) - minWeekWidth;
}

- (NSRect)dateViewFrame
{
    NSRect bounds = [[window contentView] bounds];
    NSRect r = [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                               NSMinY(bounds) + _WLYMarginBetweenBoundsAndDate,
                                                               [self fixedInfoViewsWidth],
                                                               [[NSUserDefaults standardUserDefaults] floatForKey:@"DateViewHeight"] - _WLYMarginBetweenBoundsAndDate)];
    r.origin.x = fmaxf(NSMinX(bounds), fminf(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmaxf(NSMinY(bounds) + _WLYMarginBetweenBoundsAndDate, fminf(NSMaxY(bounds), r.origin.y));
    r.size.width = fminf(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fminf(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (NSRect)tasksViewFrame
{
    NSRect bounds = [[window contentView] bounds];
    // By default tasks and right now have the same height. Since window size is unknown until user start blotter
    // set the default value here.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"TasksViewHeight"] == nil || [defaults integerForKey:@"CalendarLayout"] == WLCalendarNormalLayout)
    {
        [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
        [defaults setFloat:[self defaultTasksViewHeight] forKey:@"TasksViewHeight"];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
    }
    else if ([defaults integerForKey:@"CalendarLayout"] == WLCalendarToDoLayout)
    {
        [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
        [defaults setFloat:[self fullTasksViewHeight] forKey:@"TasksViewHeight"];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
    }
    NSRect r = [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                               NSMaxY([self dateViewFrame]),
                                                               [self fixedInfoViewsWidth],
                                                               [defaults floatForKey:@"TasksViewHeight"])];
    r.origin.x = fmaxf(NSMinX(bounds), fminf(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmaxf(NSMinY(bounds), fminf(NSMaxY(bounds), r.origin.y));
    r.size.width = fminf(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fminf(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (NSRect)rightNowViewFrame
{
    NSRect tasksViewFrame = [self tasksViewFrame];
    CGFloat margin = 0.0f;
    if (fabsf(tasksViewFrame.size.height - 0.0f) > FLT_EPSILON)
        margin = _WLYMarginBetweenTasksAndRightNow;
    NSRect bounds = [[self.window contentView] bounds];
    NSRect r = [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                               NSMaxY(tasksViewFrame) + margin,
                                                               [self fixedInfoViewsWidth],
                                                               NSHeight(bounds) - NSMaxY([self tasksViewFrame]) - margin)];
    r.origin.x = fmaxf(NSMinX(bounds), fminf(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmaxf(NSMinY(bounds) + margin, fminf(NSMaxY(bounds), r.origin.y));
    r.size.width = fminf(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fminf(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (NSRect)weekViewFrame
{
    NSRect bounds = [[window contentView] bounds];
    CGFloat infoViewWidth = [self fixedInfoViewsWidth];
    if (fabsf(infoViewWidth - 0.0f) > FLT_EPSILON)
        infoViewWidth += _WLXMarginBetweenInfoAndWeek;
    NSRect r = [[window contentView] centerScanRect:NSMakeRect(NSMinX(bounds) + infoViewWidth,
                                                               NSMinY(bounds),
                                                               NSWidth(bounds) - infoViewWidth,
                                                               NSHeight(bounds))];
    r.origin.x = fmaxf(NSMinX(bounds), fminf(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmaxf(NSMinY(bounds), fminf(NSMaxY(bounds), r.origin.y));
    r.size.width = fminf(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fminf(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (CGFloat)defaultTasksViewHeight
{
    NSRect bounds = [[self.window contentView] bounds];
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
    return roundf((NSHeight(bounds) - ([[defaults objectForKey:@"DateViewHeight"] floatValue]) - _WLYMarginBetweenTasksAndRightNow) / 2);
}

- (CGFloat)fullTasksViewHeight
{
    NSRect bounds = [[self.window contentView] bounds];
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
    return roundf(NSHeight(bounds) - ([[defaults objectForKey:@"DateViewHeight"] floatValue]));
}

- (NSSize)minimumSize
{
    return BLMinimumSize;
}

@end

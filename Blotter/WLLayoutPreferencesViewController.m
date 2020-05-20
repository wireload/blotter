//
//  LayoutPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <objc/runtime.h>

#import "WLLayoutPreferencesViewController.h"
#import "DeskboardAppDelegate.h"
#import "WLCalendarWindowController.h"
#import "WLCalendarViewController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


static void *_WLFrameObservationContext = &_WLFrameObservationContext;

static void *_WLLayoutPreferencesObservationContext = &_WLLayoutPreferencesObservationContext;

static void *_WLCalendarLayoutObservationContext = &_WLCalendarLayoutObservationContext;


@implementation WLLayoutPreferencesViewController
{
    IBOutlet WLLayoutArrangementView *_rootArrangementView;
    IBOutlet WLLayoutArrangementView * _Nullable _infoArrangementView;
    IBOutlet WLLayoutArrangementView * _Nullable _weekArrangementView;

    IBOutlet NSLayoutConstraint *_desktopViewWidthConstraint;
    IBOutlet NSLayoutConstraint *_desktopViewHeightConstraint;

    IBOutlet NSLayoutConstraint *_mockupViewWidthConstraint;
    IBOutlet NSLayoutConstraint *_mockupViewAspectRatioConstraint;

    WLCalendarViewLayout * _Nullable _layout;

    NSArray<WLDividerRange *> *_rootArrangementLayout;
    NSArray<WLDividerRange *> *_infoArrangementLayout;
    NSArray<WLDividerRange *> *_weekArrangementLayout;

    BOOL _isUpdatingArrangementView;
}

#pragma mark Methods

- (void)layoutDidChange
{
    __auto_type calendarViewController = WLAppDelegate._calendarWindowController.arrangedViewController;
    _layout = [calendarViewController layoutWithPreferences:nil];

    _isUpdatingArrangementView = YES;
    [self _layoutRootSplitView];
    [self _layoutInfoSplitView];
    [self _layoutWeekSplitView];
    _isUpdatingArrangementView = NO;
}

- (void)userDidChangeLayout:(WLLayoutArrangementView *)aSender
{
    __auto_type defaults = NSUserDefaults.standardUserDefaults;

    defaults.WL_calendarLayout = WLCalendarLayoutCustom;

    if (aSender == _rootArrangementView)
    {
        __auto_type sizes = [_rootArrangementView convertLayout:_rootArrangementLayout
                                                         toView:_layout.owningView
                                                        forRect:_layout.bounds
                                                       minSizes:@[@(_layout.minInfoWidth), @(_layout.minWeekWidth)]
                                                       spacings:@[@(_layout.spacingAfterInfo)]];
        defaults.WL_infoViewsWidth = sizes[0].doubleValue;
    }
    else if (aSender == _infoArrangementView)
    {
        if (_layout.canFitDate && _layout.canFitReminders && _layout.canFitRightNow)
        {
            __auto_type sizes = [_infoArrangementView convertLayout:_infoArrangementLayout
                                                             toView:_layout.owningView
                                                            forRect:_layout.bounds
                                                           minSizes:@[@(_layout.minDateHeight), @(_layout.minRemindersHeight), @(_layout.minRightNowHeight)]
                                                           spacings:@[@(_layout.spacingAfterDate), @(_layout.spacingAfterReminders)]];
            defaults.WL_dateViewHeight = sizes[0].doubleValue;
            defaults.WL_tasksViewHeight = sizes[1].doubleValue;
        }
        else if (_layout.canFitDate && _layout.canFitReminders)
        {
            __auto_type sizes = [_infoArrangementView convertLayout:_infoArrangementLayout
                                                             toView:_layout.owningView
                                                            forRect:_layout.bounds
                                                           minSizes:@[@(_layout.minDateHeight), @(_layout.minRemindersHeight)]
                                                           spacings:@[@(_layout.spacingAfterDate)]];
            defaults.WL_dateViewHeight = sizes[0].doubleValue;
            defaults.WL_tasksViewHeight = sizes[1].doubleValue;
        }
        else if (_layout.canFitDate && _layout.canFitRightNow)
        {
            __auto_type sizes = [_infoArrangementView convertLayout:_infoArrangementLayout
                                                             toView:_layout.owningView
                                                            forRect:_layout.bounds
                                                           minSizes:@[@(_layout.minDateHeight), @(_layout.minRightNowHeight)]
                                                           spacings:@[@(_layout.spacingAfterDate)]];
            defaults.WL_dateViewHeight = sizes[0].doubleValue;
            defaults.WL_tasksViewHeight = 0.0;
        }
        else if (_layout.canFitReminders && _layout.canFitRightNow)
        {
            __auto_type sizes = [_infoArrangementView convertLayout:_infoArrangementLayout
                                                             toView:_layout.owningView
                                                            forRect:_layout.bounds
                                                           minSizes:@[@(_layout.minRemindersHeight), @(_layout.minRightNowHeight)]
                                                           spacings:@[@(_layout.spacingAfterReminders)]];
            defaults.WL_dateViewHeight = 0.0;
            defaults.WL_tasksViewHeight = sizes[0].doubleValue;
        }
    }
    else if (aSender == _weekArrangementView)
    {
        NSAssert(defaults.WL_calendarSize != BLNarrowSize, @"User should not be able to change the week view when calendar size is Narrow.");

        __auto_type sizes = [_weekArrangementView convertLayout:_weekArrangementLayout
                                                         toView:_layout.owningView
                                                        forRect:_layout.bounds
                                                       minSizes:@[@(_layout.minAllDayEventsHeight), @(_layout.minDayEventsHeight)]
                                                       spacings:@[@(_layout.spacingAfterAllDayEvents)]];
        defaults.WL_allDayViewHeight = sizes[0].doubleValue;
    }
    else
        NSAssert(NO, @"Unexpected split view.");

    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layoutDidChange) object:nil];
    [self layoutDidChange];
}

#pragma mark NSSplitViewDelegate

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
    if (_isUpdatingArrangementView)
        return;

    BOOL isResizedByUser = [[aNotification.userInfo objectForKey:@"NSSplitViewUserResizeKey"] boolValue];
    if (!isResizedByUser)
        return;

    NSSplitView *splitView = aNotification.object;
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(userDidChangeLayout:) object:splitView];
    [self performSelector:@selector(userDidChangeLayout:) withObject:splitView afterDelay:0.0];
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMinCoordinate:(CGFloat)aProposedMinimumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (_isUpdatingArrangementView)
        return aProposedMinimumPosition;

    if (aSplitView == _rootArrangementView)
        return fmax(aProposedMinimumPosition, _rootArrangementLayout[0].min);
    else if (aSplitView == _infoArrangementView)
        return fmax(aProposedMinimumPosition, _infoArrangementLayout[(NSUInteger)aDividerIndex].min);
    else if (aSplitView == _weekArrangementView)
        return fmax(aProposedMinimumPosition, _weekArrangementLayout[0].min);
    else
        return aProposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)aProposedMaximumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (_isUpdatingArrangementView)
        return aProposedMaximumPosition;

    if (aSplitView == _rootArrangementView)
        return fmin(aProposedMaximumPosition, _rootArrangementLayout[0].max);
    else if (aSplitView == _infoArrangementView)
        return fmin(aProposedMaximumPosition, _infoArrangementLayout[(NSUInteger)aDividerIndex].max);
    else if (aSplitView == _weekArrangementView)
        return fmin(aProposedMaximumPosition, _weekArrangementLayout[0].max);
    else
        return aProposedMaximumPosition;
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aSubview
{
    return YES;
}

#pragma mark Private

- (void)_scheduleLayoutDidChange
{
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layoutDidChange) object:nil];
    [self performSelector:@selector(layoutDidChange) withObject:nil afterDelay:0.0];
}

- (void)_configureArrangementView:(WLLayoutArrangementView *)aView forNumberOfPanes:(NSUInteger)aCount
{
    NSUInteger oldCount = aView.arrangedSubviews.count;

    for (NSUInteger i = oldCount; i < aCount; ++i)
        [aView addArrangedSubview:[WLLayoutArrangementPaneAuxView new]];

    for (NSUInteger i = oldCount; i > aCount; --i)
        [aView.arrangedSubviews[0] removeFromSuperview];

    [aView adjustSubviews];
    aView.needsDisplay = YES;
}

- (void)_layoutRootSplitView
{
    if (_layout.canFitInfo && !_infoArrangementView)
    {
        _infoArrangementView = [WLLayoutArrangementView new];
        [_rootArrangementView insertArrangedSubview:_infoArrangementView atIndex:0];
    }
    else if (!_layout.canFitInfo && _infoArrangementView)
    {
        [_infoArrangementView removeFromSuperview];
        _infoArrangementView = nil;
    }

    if (_layout.canFitWeek && !_weekArrangementView)
    {
        _weekArrangementView = [WLLayoutArrangementView new];
        [_rootArrangementView addArrangedSubview:_weekArrangementView];
    }
    else if (!_layout.canFitWeek && _weekArrangementView)
    {
        [_weekArrangementView removeFromSuperview];
        _weekArrangementView = nil;
    }

    [_rootArrangementView adjustSubviews];
    _rootArrangementView.needsDisplay = YES;

    if (_rootArrangementView.arrangedSubviews.count < 2)
        return;

    CGFloat distributableSpace = _layout.infoWidth + _layout.weekWidth;

    __auto_type preferredSizes = @[
        @(_layout.infoWidth / distributableSpace),
        @(_layout.weekWidth / distributableSpace)
    ];
    __auto_type collapsibleSizes = @[
        @(_layout.minInfoWidth / distributableSpace),
        @(_layout.minWeekWidth / distributableSpace)
    ];
    _rootArrangementLayout = [_rootArrangementView layoutWithPreferredSizes:preferredSizes
                                                           collapsibleSizes:collapsibleSizes];
    [_rootArrangementView adjustSubviewsWithLayout:_rootArrangementLayout];
}

- (void)_layoutInfoSplitView
{
    if (!_infoArrangementView)
        return;

    NSUInteger numberOfPanes = (NSUInteger)(_layout.canFitDate + _layout.canFitReminders + _layout.canFitRightNow);
    [self _configureArrangementView:_infoArrangementView forNumberOfPanes:numberOfPanes];

    if (numberOfPanes < 2)
        return;

    CGFloat distributableSpace = _layout.dateHeight + _layout.remindersHeight + _layout.rightNowHeight;
    NSArray *preferredSizes = nil;
    NSArray *collapsibleSizes = nil;

    if (_layout.canFitDate && _layout.canFitReminders && _layout.canFitRightNow)
    {
        preferredSizes = @[
            @(_layout.dateHeight / distributableSpace),
            @(_layout.remindersHeight / distributableSpace),
            @(_layout.rightNowHeight / distributableSpace)
        ];
        collapsibleSizes = @[
            @(_layout.minDateHeight / distributableSpace),
            @(_layout.minRemindersHeight / distributableSpace),
            @(_layout.minRightNowHeight / distributableSpace)
        ];
    }
    else if (_layout.canFitDate && _layout.canFitReminders)
    {
        preferredSizes = @[
            @(_layout.dateHeight / distributableSpace),
            @(_layout.remindersHeight / distributableSpace)
        ];
        collapsibleSizes = @[
            @(_layout.minDateHeight / distributableSpace),
            @(_layout.minRemindersHeight / distributableSpace)
        ];
    }
    else if (_layout.canFitDate && _layout.canFitRightNow)
    {
        preferredSizes = @[
            @(_layout.dateHeight / distributableSpace),
            @(_layout.rightNowHeight / distributableSpace)
        ];
        collapsibleSizes = @[
            @(_layout.minDateHeight / distributableSpace),
            @(_layout.minRightNowHeight / distributableSpace)
        ];
    }
    else if (_layout.canFitReminders && _layout.canFitRightNow)
    {
        preferredSizes = @[
            @(_layout.remindersHeight / distributableSpace),
            @(_layout.rightNowHeight / distributableSpace)
        ];
        collapsibleSizes = @[
            @(_layout.minRemindersHeight / distributableSpace),
            @(_layout.minRightNowHeight / distributableSpace)
        ];
    }

    _infoArrangementLayout = [_infoArrangementView layoutWithPreferredSizes:preferredSizes
                                                           collapsibleSizes:collapsibleSizes];
    [_infoArrangementView adjustSubviewsWithLayout:_infoArrangementLayout];
}

- (void)_layoutWeekSplitView
{
    if (!_weekArrangementView)
        return;

    NSUInteger numberOfPanes = (NSUInteger)(_layout.canFitAllDayEvents + _layout.canFitDayEvents);
    [self _configureArrangementView:_weekArrangementView forNumberOfPanes:numberOfPanes];

    if (numberOfPanes < 2)
        return;

    CGFloat distributableSpace = fdim(NSHeight(_layout.bounds), _layout.spacingAfterAllDayEvents);

    __auto_type preferredSizes = @[
        @(_layout.allDayEventsHeight >= distributableSpace ? 1.0 : _layout.allDayEventsHeight / distributableSpace),
        @(_layout.dayEventsHeight >= distributableSpace ? 1.0 : _layout.dayEventsHeight / distributableSpace)
    ];
    __auto_type collapsibleSizes = @[
        @(_layout.minAllDayEventsHeight / distributableSpace),
        @(_layout.minDayEventsHeight / distributableSpace)
    ];
    _weekArrangementLayout = [_weekArrangementView layoutWithPreferredSizes:preferredSizes
                                                           collapsibleSizes:collapsibleSizes];
    [_weekArrangementView adjustSubviewsWithLayout:_weekArrangementLayout];
}

#pragma mark WLPreferencesViewController

- (NSTabViewItem *)makeTabViewItem
{
    NSTabViewItem *t = [super makeTabViewItem];
    t.image = [NSImage imageNamed:@"preferences-layout-icon"];
    t.label = NSLocalizedString(@"Layout", @"Layout pref pane title");
    t.toolTip = NSLocalizedString(@"Layout Preferences", @"Layout pref pane tooltip");
    return t;
}

- (void)viewControllerWillTransitionIn
{
    [super viewControllerWillTransitionIn];
    self.view.needsUpdateConstraints = YES;
}

#pragma mark NSViewController

- (void)viewWillAppear
{
    [super viewWillAppear];

    __auto_type calendarController = WLAppDelegate._calendarWindowController;
    [calendarController addObserver:self
                         forKeyPath:@"windowFrame"
                            options:0
                            context:_WLFrameObservationContext];
    [calendarController addObserver:self
                         forKeyPath:@"windowScreenVisibleFrame"
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                            context:_WLFrameObservationContext];

    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    [defaults addObserver:self
               forKeyPath:WLCalendarLayoutKey
                  options:0
                  context:_WLLayoutPreferencesObservationContext];
    [defaults addObserver:self
               forKeyPath:WLCalendarSizeKey
                  options:0
                  context:_WLLayoutPreferencesObservationContext];
    [defaults addObserver:self
               forKeyPath:WLInfoViewsWidthKey
                  options:0
                  context:_WLLayoutPreferencesObservationContext];
    [defaults addObserver:self
               forKeyPath:WLDateViewHeightKey
                  options:0
                  context:_WLLayoutPreferencesObservationContext];
    [defaults addObserver:self
               forKeyPath:WLTasksViewHeightKey
                  options:0
                  context:_WLLayoutPreferencesObservationContext];
    [defaults addObserver:self
               forKeyPath:WLAllDayViewHeightKey
                  options:0
                  context:_WLLayoutPreferencesObservationContext];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_scheduleLayoutDidChange)
                                               name:NSViewFrameDidChangeNotification
                                             object:calendarController.arrangedViewController.view];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_scheduleLayoutDidChange)
                                               name:NSViewFrameDidChangeNotification
                                             object:_rootArrangementView];
}

- (void)viewDidAppear
{
    [super viewDidAppear];

    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layoutDidChange) object:nil];
    [self layoutDidChange];
}

- (void)viewDidDisappear
{
    __auto_type calendarController = WLAppDelegate._calendarWindowController;
    [calendarController removeObserver:self forKeyPath:@"windowFrame" context:_WLFrameObservationContext];
    [calendarController removeObserver:self forKeyPath:@"windowScreenVisibleFrame" context:_WLFrameObservationContext];

    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:WLCalendarLayoutKey context:_WLLayoutPreferencesObservationContext];
    [defaults removeObserver:self forKeyPath:WLCalendarSizeKey context:_WLLayoutPreferencesObservationContext];
    [defaults removeObserver:self forKeyPath:WLInfoViewsWidthKey context:_WLLayoutPreferencesObservationContext];
    [defaults removeObserver:self forKeyPath:WLDateViewHeightKey context:_WLLayoutPreferencesObservationContext];
    [defaults removeObserver:self forKeyPath:WLTasksViewHeightKey context:_WLLayoutPreferencesObservationContext];
    [defaults removeObserver:self forKeyPath:WLAllDayViewHeightKey context:_WLLayoutPreferencesObservationContext];

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSViewFrameDidChangeNotification
                                                object:calendarController.arrangedViewController.view];
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSViewFrameDidChangeNotification
                                                object:_rootArrangementView];

    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layoutDidChange) object:nil];
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(userDidChangeLayout:) object:_rootArrangementView];
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(userDidChangeLayout:) object:_infoArrangementView];
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(userDidChangeLayout:) object:_weekArrangementView];

    [super viewDidDisappear];
}

- (void)updateViewConstraints
{
    static const CGFloat DesktopViewLongestSideLength = 480.0;
    static const CGFloat MockupViewLongestSideLength = 400.0;

    // The Desktop view is sized to the aspect ratio of calendar window's screen.

    __auto_type windowController = WLAppDelegate._calendarWindowController;
    NSRect screenFrame = windowController.windowScreenVisibleFrame;
    CGFloat screenAspectRatio = NSHeight(screenFrame) > 0.0 ? NSWidth(screenFrame) / NSHeight(screenFrame) : 16.0 / 10.0;

    if (screenAspectRatio > 1.0)
    {
        _desktopViewWidthConstraint.constant = DesktopViewLongestSideLength;
        _desktopViewHeightConstraint.constant = DesktopViewLongestSideLength / screenAspectRatio;
    }
    else
    {
        _desktopViewWidthConstraint.constant = DesktopViewLongestSideLength * screenAspectRatio;
        _desktopViewHeightConstraint.constant = DesktopViewLongestSideLength;
    }

    // The longest side of the mockup view is set to a predefined constant.
    // Auto Layout (see XIB) takes care of scaling it up fit within the Desktop view,
    // while simultaneously respecting mockup's aspect ratio.

    NSRect windowFrame = windowController.windowFrame;
    CGFloat mockupAspectRatio = NSHeight(windowFrame) > 0.0 ? NSWidth(windowFrame) / NSHeight(windowFrame) : 16.0 / 10.0;

    if (mockupAspectRatio > 1.0)
        _mockupViewWidthConstraint.constant = MockupViewLongestSideLength;
    else
        _mockupViewWidthConstraint.constant = MockupViewLongestSideLength * mockupAspectRatio;

    NSView *mockupView = (NSView *)_mockupViewAspectRatioConstraint.firstItem;
    _mockupViewAspectRatioConstraint.active = NO;
    __auto_type priority = _mockupViewAspectRatioConstraint.priority;
    _mockupViewAspectRatioConstraint = [mockupView.widthAnchor constraintEqualToAnchor:mockupView.heightAnchor multiplier:mockupAspectRatio];
    _mockupViewAspectRatioConstraint.priority = priority;
    _mockupViewAspectRatioConstraint.active = YES;

    [super updateViewConstraints];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if (aContext == _WLFrameObservationContext)
        self.view.needsUpdateConstraints = YES;
    else if (aContext == _WLLayoutPreferencesObservationContext)
        [self _scheduleLayoutDidChange];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

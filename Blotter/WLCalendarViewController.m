//
//  WLCalendarViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 3/24/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>

#import "WLCalendarViewController.h"

#import "DeskboardAppDelegate.h"
#import "WLSoftEdgeLayer.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


static void *_WLLayoutObservationContext = &_WLLayoutObservationContext;
static void *_WLClockDateObservationContext = &_WLClockDateObservationContext;
static void *_WLClockCalendarObservationContext = &_WLClockCalendarObservationContext;
static void *_WLShowsNext7DaysObservationContext = &_WLShowsNext7DaysObservationContext;


@implementation WLCalendarViewController
{
    BOOL _isViewAppeared;
    WLSmartClock *_clock;
}

- (instancetype)initWithNibName:(NSNibName)aNibNameOrNil bundle:(NSBundle *)aNibBundleOrNil
{
    self = [super initWithNibName:aNibNameOrNil bundle:aNibBundleOrNil];

    if (self)
    {
        __auto_type v = [WLFlippedView new];
        v.translatesAutoresizingMaskIntoConstraints = NO;
        self.view = v;
    }

    return self;
}

#pragma mark Properties

- (WLSmartClock *)clock
{
    if (!_clock)
        _clock = WLSmartClock.defaultClock;

    return _clock;
}

- (BOOL)canShowNextWeek
{
    return _weekViewController.canShowNextWeek;
}

- (BOOL)canShowCurrentWeek
{
    return _weekViewController.canShowCurrentWeek;
}

- (BOOL)canShowPreviousWeek
{
    return _weekViewController.canShowPreviousWeek;
}

- (BOOL)isCurrentWeekShown
{
    return _weekViewController && _weekViewController.weekOffset == 0;
}

#pragma mark Methods

- (WLCalendarViewLayout *)layoutWithPreferences:(nullable NSDictionary *)aPreferences
{
    return [[WLCalendarViewLayout alloc] initWithBounds:self.view.frame
                                          forParentView:self.view
                                        withPreferences:aPreferences];
}

- (NSView *)embedView:(NSView *)aContentView inBoxWithTitle:(NSString *)aTitle softEdges:(BOOL)aShouldSoftEdges
{
    __auto_type backgroundView = [WLDrawingLayerBackedView new];
    backgroundView.translatesAutoresizingMaskIntoConstraints = YES;
    backgroundView.drawingBlock = ^(__kindof WLDrawingLayerBackedView * _Nonnull aView, NSRect aDirtyRect) {
        [NSGraphicsContext saveGraphicsState];
        __auto_type context = NSGraphicsContext.currentContext;
#ifndef DEBUG_LAYERS
        context.shouldAntialias = YES;
        context.imageInterpolation = NSImageInterpolationHigh;
        WLDrawScaledNinePartImage(aView.bounds,
                                  [NSImage imageNamed:@"box-top-left"],
                                  [NSImage imageNamed:@"box-top-middle"],
                                  [NSImage imageNamed:@"box-top-right"],
                                  [NSImage imageNamed:@"box-middle-left"],
                                  [NSImage imageNamed:@"box-middle-middle"],
                                  [NSImage imageNamed:@"box-middle-right"],
                                  [NSImage imageNamed:@"box-bottom-left"],
                                  [NSImage imageNamed:@"box-bottom-middle"],
                                  [NSImage imageNamed:@"box-bottom-right"],
                                  NSCompositingOperationCopy,
                                  1.0,
                                  aView.isFlipped);
#else
        [NSColor.blackColor setFill];
        NSRectFill(aDirtyRect);
#endif
        [NSGraphicsContext restoreGraphicsState];
    };

    static NSDictionary *TitleAttributes = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        NSShadow *shadow = [NSShadow new];
        shadow.shadowColor = [NSColor WL_taskTextShadowColor];
        shadow.shadowBlurRadius = 0.0;
        // View is flipped
        shadow.shadowOffset = NSMakeSize(0.0, -1.0);
        TitleAttributes = @{
            NSFontAttributeName: [NSFont WL_boxViewTitleFont],
            NSForegroundColorAttributeName: [NSColor WL_boxViewTitleColor],
            NSShadowAttributeName: shadow
        };
    });

    __auto_type titleView = [NSTextField new];
    titleView.translatesAutoresizingMaskIntoConstraints = NO;
    titleView.editable = NO;
    titleView.selectable = NO;
    titleView.drawsBackground = NO;
    titleView.bordered = NO;
    titleView.bezeled = NO;
    titleView.attributedStringValue = [[NSAttributedString alloc] initWithString:aTitle attributes:TitleAttributes];

    if (aShouldSoftEdges)
    {
        aContentView.wantsLayer = YES;
        aContentView.layer.mask = [WLSoftEdgeLayer layer];
        aContentView.layer.mask.frame = aContentView.layer.mask.bounds;
        aContentView.layer.mask.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    }

    aContentView.translatesAutoresizingMaskIntoConstraints = NO;

    [backgroundView addSubview:titleView];
    [backgroundView addSubview:aContentView];

    static const CGFloat LeftPadding = 15.0;
    static const CGFloat RightPadding = 13.0;
    static const CGFloat TopPadding = 13.0;
    static const CGFloat TitleHeight = 34.0;
    static const CGFloat Spacing = 10.0;
    static const CGFloat SoftSpacing = 5.0;
    static const CGFloat BottomPadding = 17.0;
    static const CGFloat SoftBottomPadding = 14.0;

    [NSLayoutConstraint activateConstraints:@[
        [titleView.leftAnchor constraintEqualToAnchor:backgroundView.leftAnchor constant:LeftPadding],
        [titleView.topAnchor constraintEqualToAnchor:backgroundView.topAnchor constant:TopPadding],
        [backgroundView.rightAnchor constraintLessThanOrEqualToAnchor:titleView.rightAnchor constant:RightPadding],

        [aContentView.leftAnchor constraintEqualToAnchor:backgroundView.leftAnchor constant:LeftPadding],
        [aContentView.topAnchor constraintEqualToAnchor:titleView.topAnchor
                                               constant:TitleHeight + (aShouldSoftEdges ? SoftSpacing : Spacing)],
        [backgroundView.rightAnchor constraintEqualToAnchor:aContentView.rightAnchor constant:RightPadding],
        [backgroundView.bottomAnchor constraintEqualToAnchor:aContentView.bottomAnchor
                                                    constant:aShouldSoftEdges ? SoftBottomPadding : BottomPadding]
    ]];

    return backgroundView;
}

- (IBAction)showNextWeek:(id)aSender
{
    if (self.canShowNextWeek)
        [_weekViewController showNextWeek:aSender animated:(self.view.window.occlusionState & NSWindowOcclusionStateVisible)];
}

- (IBAction)showPreviousWeek:(id)aSender
{
    if (self.canShowPreviousWeek)
        [_weekViewController showPreviousWeek:aSender animated:(self.view.window.occlusionState & NSWindowOcclusionStateVisible)];
}

- (IBAction)showCurrentWeek:(id)aSender
{
    if (self.canShowCurrentWeek)
        [_weekViewController showCurrentWeek:aSender animated:(self.view.window.occlusionState & NSWindowOcclusionStateVisible)];
}

#pragma mark NSViewController

- (void)viewWillLayout
{
    [super viewWillLayout];

    __auto_type newLayout = [self layoutWithPreferences:nil];

    BOOL shouldShowDate = !newLayout.isInfoCollapsed && !newLayout.isDateCollapsed;
    BOOL shouldShowReminders = !newLayout.isInfoCollapsed && !newLayout.isRemindersCollapsed;
    BOOL shouldShowRightNow = !newLayout.isInfoCollapsed && !newLayout.isRightNowCollapsed;
    BOOL shouldShowWeek = !newLayout.isWeekCollapsed && (!newLayout.isAllDayEventsCollapsed || !newLayout.isDayEventsCollapsed);

    if (shouldShowDate && !_dateViewController)
    {
        [self willChangeValueForKey:@"dateViewController"];
        _dateViewController = [WLCalendarDateViewController new];
        [_dateViewController bind:@"clock" toObject:self withKeyPath:@"clock" options:nil];
        _dateViewController.clock = self.clock;
        [self.view addSubview:_dateViewController.view];
        [self didChangeValueForKey:@"dateViewController"];
    }
    else if (!shouldShowDate && _dateViewController)
    {
        [self willChangeValueForKey:@"dateViewController"];
        [_dateViewController unbind:@"clock"];
        [_dateViewController.view removeFromSuperview];
        _dateViewController = nil;
        [self didChangeValueForKey:@"dateViewController"];
    }

    if (shouldShowReminders && !_remindersViewController)
    {
        [self willChangeValueForKey:@"remindersViewController"];
        _remindersViewController = [WLCalendarRemindersViewController new];
        _remindersViewController.representedObject = WLAppDelegate.calendarRemindersController;
        __auto_type boxView = [self embedView:_remindersViewController.view
                               inBoxWithTitle:NSLocalizedString(@"To Do", @"Header of To Do items list")
                                    softEdges:NO];
        [self.view addSubview:boxView];
        [self didChangeValueForKey:@"remindersViewController"];
    }
    else if (!shouldShowReminders && _remindersViewController)
    {
        [self willChangeValueForKey:@"remindersViewController"];
        [_remindersViewController.view.superview removeFromSuperview];
        _remindersViewController = nil;
        [self didChangeValueForKey:@"remindersViewController"];
    }

    if (shouldShowRightNow && !_rightNowViewController)
    {
        [self willChangeValueForKey:@"rightNowViewController"];
        _rightNowViewController = [WLCalendarRightNowEventsViewController new];
        _rightNowViewController.date = _clock.date;
        _rightNowViewController.calendar = _clock.calendar;
        [_rightNowViewController setAlignmentUnit:NSCalendarUnitDay number:1 animated:NO];
        _rightNowViewController.representedObject = WLAppDelegate.calendarEventsController;
        __auto_type boxView = [self embedView:_rightNowViewController.view
                               inBoxWithTitle:NSLocalizedString(@"Right Now", @"Header of Right Now items list")
                                    softEdges:YES];
        [self.view addSubview:boxView];
        [self didChangeValueForKey:@"rightNowViewController"];
    }
    else if (!shouldShowRightNow && _rightNowViewController)
    {
        [self willChangeValueForKey:@"rightNowViewController"];
        [_rightNowViewController.view.superview removeFromSuperview];
        _rightNowViewController = nil;
        [self didChangeValueForKey:@"rightNowViewController"];
    }

    if (shouldShowWeek && !_weekViewController)
    {
        [self willChangeValueForKey:@"weekViewController"];
        _weekViewController = [WLCalendarFloatingWeekEventsViewController new];
        _weekViewController.date = _clock.date;
        _weekViewController.calendar = _clock.calendar;

        if (NSUserDefaults.standardUserDefaults.WL_showNext7Days)
            [_weekViewController setAlignmentUnit:NSCalendarUnitDay number:7 animated:_isViewAppeared];
        else
            [_weekViewController setAlignmentUnit:NSCalendarUnitWeekOfMonth number:1 animated:_isViewAppeared];

        _weekViewController.representedObject = WLAppDelegate.calendarEventsController;
        [_weekViewController bind:@"titleFormat"
                         toObject:NSUserDefaults.standardUserDefaults
                      withKeyPath:WLTitleFormatKey
                          options:nil];
        [self.view addSubview:_weekViewController.view];
        [self didChangeValueForKey:@"weekViewController"];
    }
    else if (!shouldShowWeek && _weekViewController)
    {
        [self willChangeValueForKey:@"weekViewController"];
        [_weekViewController unbind:@"titleFormat"];
        [_weekViewController.view removeFromSuperview];
        _weekViewController = nil;
        [self didChangeValueForKey:@"weekViewController"];
    }

    NSRect dateFrame = newLayout.dateFrame;
    dateFrame.origin.y -= 40.0;
    dateFrame.size.height += 40.0;
    _dateViewController.view.frame = dateFrame;
    _remindersViewController.view.superview.frame = newLayout.remindersFrame;
    _rightNowViewController.view.superview.frame = newLayout.rightNowFrame;
    _weekViewController.view.frame = newLayout.weekFrame;
    _weekViewController.view.heightOfAllDayPartOfColumn = newLayout.allDayEventsHeight;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    __auto_type _defaults = NSUserDefaults.standardUserDefaults;
    [_defaults addObserver:self
                forKeyPath:WLInfoViewsWidthKey
                   options:0
                   context:_WLLayoutObservationContext];
    [_defaults addObserver:self
                forKeyPath:WLDateViewHeightKey
                   options:0
                   context:_WLLayoutObservationContext];
    [_defaults addObserver:self
                forKeyPath:WLTasksViewHeightKey
                   options:0
                   context:_WLLayoutObservationContext];
    [_defaults addObserver:self
                forKeyPath:WLAllDayViewHeightKey
                   options:0
                   context:_WLLayoutObservationContext];
    [_defaults addObserver:self
                forKeyPath:WLCalendarSizeKey
                   options:0
                   context:_WLLayoutObservationContext];
    [_defaults addObserver:self
                forKeyPath:WLCalendarLayoutKey
                   options:0
                   context:_WLLayoutObservationContext];
    [_defaults addObserver:self
                forKeyPath:WLShowsNext7DaysKey
                   options:NSKeyValueObservingOptionNew
                   context:_WLShowsNext7DaysObservationContext];

    [self addObserver:self
           forKeyPath:@"clock.date"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:_WLClockDateObservationContext];
    [self addObserver:self
           forKeyPath:@"clock.calendar"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:_WLClockCalendarObservationContext];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    _isViewAppeared = YES;
}

- (void)viewDidDisappear
{
    _isViewAppeared = NO;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:WLInfoViewsWidthKey context:_WLLayoutObservationContext];
    [defaults removeObserver:self forKeyPath:WLDateViewHeightKey context:_WLLayoutObservationContext];
    [defaults removeObserver:self forKeyPath:WLTasksViewHeightKey context:_WLLayoutObservationContext];
    [defaults removeObserver:self forKeyPath:WLAllDayViewHeightKey context:_WLLayoutObservationContext];
    [defaults removeObserver:self forKeyPath:WLCalendarSizeKey context:_WLLayoutObservationContext];
    [defaults removeObserver:self forKeyPath:WLCalendarLayoutKey context:_WLLayoutObservationContext];
    [defaults removeObserver:self forKeyPath:WLShowsNext7DaysKey context:_WLShowsNext7DaysObservationContext];

    [self removeObserver:self forKeyPath:@"clock.date" context:_WLClockDateObservationContext];
    [self removeObserver:self forKeyPath:@"clock.calendar" context:_WLClockCalendarObservationContext];

    [super viewDidDisappear];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)aChange
                       context:(void *)aContext
{
    if (aContext == _WLLayoutObservationContext)
        self.view.needsLayout = YES;
    else if (aContext == _WLClockDateObservationContext)
    {
        [_weekViewController setDate:aChange[NSKeyValueChangeNewKey] animated:_isViewAppeared];
        [_rightNowViewController setDate:aChange[NSKeyValueChangeNewKey] animated:_isViewAppeared];
    }
    else if (aContext == _WLClockCalendarObservationContext)
    {
        [_weekViewController setCalendar:aChange[NSKeyValueChangeNewKey] animated:_isViewAppeared];
        [_rightNowViewController setCalendar:aChange[NSKeyValueChangeNewKey] animated:_isViewAppeared];
    }
    else if (aContext == _WLShowsNext7DaysObservationContext)
    {
        if ([aChange[NSKeyValueChangeNewKey] boolValue])
            [_weekViewController setAlignmentUnit:NSCalendarUnitDay number:7 animated:_isViewAppeared];
        else
            [_weekViewController setAlignmentUnit:NSCalendarUnitWeekOfMonth number:1 animated:_isViewAppeared];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

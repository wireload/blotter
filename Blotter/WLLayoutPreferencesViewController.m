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


static const NSAlignmentOptions _WLLeftward = NSAlignMaxXNearest | NSAlignMinYNearest | NSAlignWidthOutward | NSAlignHeightNearest;
static const NSAlignmentOptions _WLUpward = NSAlignMinXNearest | NSAlignMaxYNearest | NSAlignWidthNearest | NSAlignHeightOutward;
static const NSAlignmentOptions _WLDownward = NSAlignMinXNearest | NSAlignMinYNearest | NSAlignWidthNearest | NSAlignHeightOutward;
static const NSAlignmentOptions _WLRightward = NSAlignMinXNearest | NSAlignMinYNearest | NSAlignWidthOutward | NSAlignHeightNearest;


typedef struct {
    CGFloat min;
    CGFloat max;
} _WLPositionRange;


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

    // Transforms may be nil if current layout preferences cannot be sensibly displayed.

    NSAffineTransform * _Nullable _toMockupRootTransform;
    NSAffineTransform * _Nullable _fromMockupRootTransform;

    NSAffineTransform * _Nullable _toMockupInfoTransform;
    NSAffineTransform * _Nullable _fromMockupInfoTransform;

    NSAffineTransform * _Nullable _toMockupWeekTransform;
    NSAffineTransform * _Nullable _fromMockupWeekTransform;

    // Range is valid iff there is a corresponding divider.

    _WLPositionRange _rootDividerPositionRange;
    _WLPositionRange _infoDividerPositionRange[2];
    _WLPositionRange _weekDividerPositionRange;

    BOOL _isUpdatingArrangementView;
}

#pragma mark Methods

- (void)layoutDidChange
{
    __auto_type calendarViewController = WLAppDelegate._calendarWindowController.arrangedViewController;
    _layout = [calendarViewController layoutWithPreferences:nil];
    [self updateTransforms];
    [self updateArrangementView];
}

- (void)userDidChangeLayout:(WLLayoutArrangementView *)aSender
{
    __auto_type defaults = NSUserDefaults.standardUserDefaults;

    defaults.WL_calendarLayout = WLCalendarLayoutCustom;

    if (aSender == _rootArrangementView)
    {
        if ([_rootArrangementView isSubviewCollapsed:_infoArrangementView])
            defaults.WL_infoViewsWidth = 0.0;
        else if ([_rootArrangementView isSubviewCollapsed:_weekArrangementView])
            defaults.WL_infoViewsWidth = _layout.boundsWidth;
        else
        {
            CGFloat dividerPosition = [_rootArrangementView positionOfDividerAtIndex:0];

            if (dividerPosition == _rootDividerPositionRange.min)
                defaults.WL_infoViewsWidth = _layout.minInfoWidth;
            else if (dividerPosition == _rootDividerPositionRange.max)
                defaults.WL_infoViewsWidth = fdim(_layout.boundsWidth, _layout.minWeekWidth + _layout.spacingAfterInfo);
            else
                defaults.WL_infoViewsWidth = round([_fromMockupRootTransform transformSize:NSMakeSize(dividerPosition, 0.0)].width);
        }
    }
    else if (aSender == _infoArrangementView)
    {
        __auto_type arrangedSubviews = _infoArrangementView.arrangedSubviews;

        if (_layout.canFitDate && _layout.canFitReminders && _layout.canFitRightNow)
        {
            __auto_type dateView = arrangedSubviews[0];
            __auto_type remindersView = arrangedSubviews[1];
            __auto_type rightNowView = arrangedSubviews[2];

            BOOL isDateCollapsed = [_infoArrangementView isSubviewCollapsed:dateView];
            BOOL isRemindersCollapsed = [_infoArrangementView isSubviewCollapsed:remindersView];
            BOOL isRightNowCollapsed = [_infoArrangementView isSubviewCollapsed:rightNowView];

            if (isDateCollapsed && isRemindersCollapsed)
            {
                defaults.WL_dateViewHeight = 0.0;
                defaults.WL_tasksViewHeight = 0.0;
            }
            else if (isDateCollapsed && isRightNowCollapsed)
            {
                defaults.WL_dateViewHeight = 0.0;
                defaults.WL_tasksViewHeight = _layout.boundsHeight;
            }
            else if (isRemindersCollapsed && isRightNowCollapsed)
            {
                defaults.WL_dateViewHeight = _layout.boundsHeight;
                defaults.WL_tasksViewHeight = 0.0;
            }
            else if (isDateCollapsed)
            {
                defaults.WL_dateViewHeight = 0.0;

                CGFloat dividerPosition = [_infoArrangementView positionOfDividerAtIndex:1];

                if (dividerPosition == _infoDividerPositionRange[1].min)
                    defaults.WL_tasksViewHeight = _layout.minRemindersHeight;
                else if (dividerPosition == _infoDividerPositionRange[1].max)
                    defaults.WL_tasksViewHeight = fdim(_layout.boundsHeight, _layout.minRightNowHeight + _layout.spacingAfterReminders);
                else
                    defaults.WL_tasksViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(remindersView.frame))].height);
            }
            else if (isRemindersCollapsed)
            {
                defaults.WL_dateViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(dateView.frame))].height);
                defaults.WL_tasksViewHeight = 0.0;
            }
            else if (isRightNowCollapsed)
            {
                CGFloat dividerPosition = [_infoArrangementView positionOfDividerAtIndex:0];

                if (dividerPosition == _infoDividerPositionRange[0].min)
                    defaults.WL_dateViewHeight = _layout.minDateHeight;
                else if (dividerPosition == _infoDividerPositionRange[0].max)
                    defaults.WL_dateViewHeight = fdim(_layout.boundsHeight, _layout.minRemindersHeight + _layout.spacingAfterDate);
                else
                    defaults.WL_dateViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(dateView.frame))].height);

                defaults.WL_tasksViewHeight = fdim(_layout.boundsHeight, defaults.WL_dateViewHeight + _layout.spacingAfterDate);
            }
            else
            {
                CGFloat divider0Position = [_infoArrangementView positionOfDividerAtIndex:0];
                CGFloat divider1Position = [_infoArrangementView positionOfDividerAtIndex:1];

                if (divider0Position == _infoDividerPositionRange[0].min)
                    defaults.WL_dateViewHeight = _layout.minDateHeight;
                else if (divider0Position == _infoDividerPositionRange[0].max)
                    defaults.WL_dateViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(dateView.frame))].height);
                else
                    defaults.WL_dateViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(dateView.frame))].height);

                // Mockup's height for the Reminders view includes the spacing after the Date view
                // that needs to be accounted for.

                if (divider1Position == _infoDividerPositionRange[1].min)
                    defaults.WL_tasksViewHeight = _layout.minRemindersHeight;
                else if (divider1Position == _infoDividerPositionRange[1].max)
                    defaults.WL_tasksViewHeight = fdim(round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(remindersView.frame))].height), _layout.spacingAfterDate);
                else
                    defaults.WL_tasksViewHeight = fdim(round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, NSHeight(remindersView.frame))].height), _layout.spacingAfterDate);
            }
        }
        else if (_layout.canFitDate && _layout.canFitReminders)
        {
            __auto_type dateView = arrangedSubviews[0];
            __auto_type remindersView = arrangedSubviews[1];

            if ([_infoArrangementView isSubviewCollapsed:dateView])
                defaults.WL_dateViewHeight = 0.0;
            else if ([_infoArrangementView isSubviewCollapsed:remindersView])
                defaults.WL_dateViewHeight = _layout.boundsHeight;
            else
            {
                CGFloat dividerPosition = [_infoArrangementView positionOfDividerAtIndex:0];

                if (dividerPosition == _infoDividerPositionRange[0].min)
                    defaults.WL_dateViewHeight = _layout.minDateHeight;
                else if (dividerPosition == _infoDividerPositionRange[0].max)
                    defaults.WL_dateViewHeight = fdim(_layout.boundsHeight, _layout.minRemindersHeight + _layout.spacingAfterDate);
                else
                    defaults.WL_dateViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, dividerPosition)].height);
            }
        }
        else if (_layout.canFitDate && _layout.canFitRightNow)
        {
            __auto_type dateView = arrangedSubviews[0];
            __auto_type rightNowView = arrangedSubviews[1];

            if ([_infoArrangementView isSubviewCollapsed:dateView])
                defaults.WL_dateViewHeight = 0.0;
            else if ([_infoArrangementView isSubviewCollapsed:rightNowView])
                defaults.WL_dateViewHeight = _layout.boundsHeight;
            else
            {
                CGFloat dividerPosition = [_infoArrangementView positionOfDividerAtIndex:0];

                if (dividerPosition == _infoDividerPositionRange[0].min)
                    defaults.WL_dateViewHeight = _layout.minDateHeight;
                else if (dividerPosition == _infoDividerPositionRange[0].max)
                    defaults.WL_dateViewHeight = fdim(_layout.boundsHeight, _layout.minRightNowHeight + _layout.spacingAfterDate);
                else
                    defaults.WL_dateViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, dividerPosition)].height);
            }
        }
        else
        {
            __auto_type remindersView = arrangedSubviews[0];
            __auto_type rightNowView = arrangedSubviews[1];

            if ([_infoArrangementView isSubviewCollapsed:remindersView])
                defaults.WL_tasksViewHeight = 0.0;
            else if ([_infoArrangementView isSubviewCollapsed:rightNowView])
                defaults.WL_tasksViewHeight = _layout.boundsHeight;
            else
            {
                CGFloat dividerPosition = [_infoArrangementView positionOfDividerAtIndex:0];

                if (dividerPosition == _infoDividerPositionRange[0].min)
                    defaults.WL_tasksViewHeight = _layout.minRemindersHeight;
                else if (dividerPosition == _infoDividerPositionRange[0].max)
                    defaults.WL_tasksViewHeight = fdim(_layout.boundsHeight, _layout.minRightNowHeight + _layout.spacingAfterReminders);
                else
                    defaults.WL_tasksViewHeight = round([_fromMockupInfoTransform transformSize:NSMakeSize(0.0, dividerPosition)].height);
            }
        }
    }
    else if (aSender == _weekArrangementView)
    {
        NSAssert(defaults.WL_calendarSize != BLNarrowSize, @"User should not be able to change the week view when calendar size is Narrow.");

        __auto_type arrangedSubviews = _weekArrangementView.arrangedSubviews;
        __auto_type allDayView = arrangedSubviews[0];
        __auto_type dayView = arrangedSubviews[1];

        if ([_weekArrangementView isSubviewCollapsed:allDayView])
            defaults.WL_allDayViewHeight = 0.0;
        else if ([_weekArrangementView isSubviewCollapsed:dayView])
            defaults.WL_allDayViewHeight = _layout.boundsHeight;
        else
        {
            CGFloat dividerPosition = [_weekArrangementView positionOfDividerAtIndex:0];

            if (dividerPosition == _weekDividerPositionRange.min)
                defaults.WL_allDayViewHeight = _layout.minAllDayEventsHeight;
            else if (dividerPosition == _weekDividerPositionRange.max)
                defaults.WL_allDayViewHeight = fdim(_layout.boundsHeight, _layout.minDayEventsHeight + _layout.spacingAfterAllDayEvents);
            else
                defaults.WL_allDayViewHeight = round([_fromMockupWeekTransform transformSize:NSMakeSize(0.0, dividerPosition)].height);
        }
    }
    else
        NSAssert(NO, @"Unexpected split view.");

    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layoutDidChange) object:nil];
    [self layoutDidChange];
}

- (void)updateTransforms
{
    // Transforms are configured such that whenever an individual pane takes all available space
    // on its arrangement view (i.e. bounds - all dividers), its size corresponds to the bounding size.
    // E.g. if the Info view is resized to take all available space, it's transformed into _layout.boundsWidth.
    //
    // Consequently all panes starting with the 2nd include height of the spacing between the current view
    // and the preceding view.

    _toMockupRootTransform = nil;
    _fromMockupRootTransform = nil;

    _toMockupInfoTransform = nil;
    _fromMockupInfoTransform = nil;

    _toMockupWeekTransform = nil;
    _fromMockupWeekTransform = nil;

    CGFloat calendarWidth = _layout.boundsWidth;
    CGFloat calendarHeight = _layout.boundsHeight;

    if (calendarWidth <= 0.0 || calendarHeight <= 0.0)
        return;

    // Update the Root view transforms.

    NSInteger numberOfDividers = _layout.canFitInfoAndWeek ? 1 : 0;
    CGFloat availableRootWidth = NSWidth(_rootArrangementView.bounds) - numberOfDividers * _rootArrangementView.dividerThickness;

    if (availableRootWidth <= 0.0)
        return;

    _toMockupRootTransform = [NSAffineTransform new];
    [_toMockupRootTransform scaleBy:availableRootWidth / calendarWidth];
    _fromMockupRootTransform = [_toMockupRootTransform copy];
    [_fromMockupRootTransform invert];

    if (_layout.canFitDateRemindersAndRightNow)
        numberOfDividers = 2;
    else if (_layout.canFitDateAndReminders || _layout.canFitDateAndRightNow || _layout.canFitRemindersAndRightNow)
        numberOfDividers = 1;
    else
        numberOfDividers = 0;

    // Update the Info view transforms.

    CGFloat availableInfoHeight = NSHeight(_infoArrangementView.bounds) - numberOfDividers * _infoArrangementView.dividerThickness;

    if (availableInfoHeight > 0.0)
    {
        _toMockupInfoTransform = [NSAffineTransform new];
        [_toMockupInfoTransform scaleBy:availableInfoHeight / calendarHeight];
        _fromMockupInfoTransform = [_toMockupInfoTransform copy];
        [_fromMockupInfoTransform invert];
    }

    // Update the Week view transforms.

    numberOfDividers = _layout.canFitAllDayAndDayEvents ? 1 : 0;
    CGFloat availableWeekHeight = NSHeight(_infoArrangementView.bounds) - numberOfDividers * _weekArrangementView.dividerThickness;

    if (availableWeekHeight > 0.0)
    {
        _toMockupWeekTransform = [NSAffineTransform new];
        [_toMockupWeekTransform scaleBy:availableWeekHeight / calendarHeight];
        _fromMockupWeekTransform = [_toMockupWeekTransform copy];
        [_fromMockupWeekTransform invert];
    }
}

- (void)updateArrangementView
{
    _isUpdatingArrangementView = YES;
    [self _layoutRootSplitView];
    [self _layoutInfoSplitView];
    [self _layoutWeekSplitView];
    _isUpdatingArrangementView = NO;
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
        return fmax(aProposedMinimumPosition, _rootDividerPositionRange.min);
    else if (aSplitView == _infoArrangementView)
        return fmax(aProposedMinimumPosition, _infoDividerPositionRange[(NSUInteger)aDividerIndex].min);
    else if (aSplitView == _weekArrangementView)
        return fmax(aProposedMinimumPosition, _weekDividerPositionRange.min);
    else
        return aProposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)aProposedMaximumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (_isUpdatingArrangementView)
        return aProposedMaximumPosition;

    if (aSplitView == _rootArrangementView)
        return fmin(aProposedMaximumPosition, _rootDividerPositionRange.max);
    else if (aSplitView == _infoArrangementView)
        return fmin(aProposedMaximumPosition, _infoDividerPositionRange[(NSUInteger)aDividerIndex].max);
    else if (aSplitView == _weekArrangementView)
        return fmin(aProposedMaximumPosition, _weekDividerPositionRange.max);
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

- (_WLPositionRange)_calcPositionRangeForArrangementView:(WLLayoutArrangementView *)aView
                                            dividerIndex:(NSInteger)aDividerIndex
                                                minSizeA:(CGFloat)aMinSizeA
                                                minSizeB:(CGFloat)aMinSizeB
                                              canFitBoth:(BOOL)aCanFitBoth
{
    __auto_type precedingView = aView.arrangedSubviews[(NSUInteger)aDividerIndex];
    __auto_type followingView = aView.arrangedSubviews[(NSUInteger)aDividerIndex + 1];
    BOOL isVertical = aView.isVertical;
    CGFloat availableSpace = 0.0;
    CGFloat minPosition = 0.0;
    CGFloat maxPosition = 0.0;

    if ([aView isSubviewCollapsed:precedingView])
    {
        NSRect followingFrame = followingView.frame;

        if (isVertical)
        {
            minPosition = NSMinX(followingFrame) - aView.dividerThickness;
            maxPosition = NSMaxX(followingFrame) - aView.dividerThickness;
            availableSpace = NSWidth(followingFrame);
        }
        else
        {
            minPosition = NSMinY(followingFrame) - aView.dividerThickness;
            maxPosition = NSMaxY(followingFrame) - aView.dividerThickness;
            availableSpace = NSHeight(followingFrame);
        }
    }
    else if ([aView isSubviewCollapsed:followingView])
    {
        NSRect precedingFrame = precedingView.frame;

        if (isVertical)
        {
            minPosition = NSMinX(precedingFrame);
            maxPosition = NSMaxX(precedingFrame);
            availableSpace = NSWidth(precedingView.frame);
        }
        else
        {
            minPosition = NSMinY(precedingFrame);
            maxPosition = NSMaxY(precedingFrame);
            availableSpace = NSHeight(precedingView.frame);
        }
    }
    else
    {
        NSRect followingFrame = followingView.frame;
        NSRect precedingFrame = precedingView.frame;

        if (isVertical)
        {
            minPosition = NSMinX(precedingFrame);
            maxPosition = NSMaxX(followingFrame) - aView.dividerThickness;
            availableSpace = NSWidth(precedingFrame) + NSWidth(followingFrame);
        }
        else
        {
            minPosition = NSMinY(precedingFrame);
            maxPosition = NSMaxY(followingFrame) - aView.dividerThickness;
            availableSpace = NSHeight(precedingFrame) + NSHeight(followingFrame);
        }
    }

    if (aCanFitBoth)
    {
        // If calendar's space that can be re-allocated towards A or B takes less than 1 pixel on mockup
        // user-driven resize should act as if only either A or B can be displayed.

        CGFloat alignedMinSizeA = 0.0;
        CGFloat alignedMinSizeB = 0.0;
        CGFloat alignedMinSizeBoth = 0.0;

        if (isVertical)
        {
            alignedMinSizeA = NSWidth([aView backingAlignedRect:NSMakeRect(minPosition, 0.0, aMinSizeA, 1.0)
                                                        options:_WLRightward]);
            alignedMinSizeB = NSWidth([aView backingAlignedRect:NSMakeRect(maxPosition - aMinSizeB, 0.0, aMinSizeB, 1.0)
                                                        options:_WLLeftward]);
            alignedMinSizeBoth = NSWidth([aView backingAlignedRect:NSMakeRect(minPosition, 0.0, alignedMinSizeA + alignedMinSizeB, 1.0)
                                                           options:_WLRightward]);
        }
        else
        {
            alignedMinSizeA = NSHeight([aView backingAlignedRect:NSMakeRect(0.0, minPosition, 1.0, aMinSizeA)
                                                         options:_WLDownward]);
            alignedMinSizeB = NSHeight([aView backingAlignedRect:NSMakeRect(0.0, maxPosition - aMinSizeB, 1.0, aMinSizeB)
                                                         options:_WLUpward]);
            alignedMinSizeBoth = NSHeight([aView backingAlignedRect:NSMakeRect(0.0, minPosition, alignedMinSizeA + alignedMinSizeB, 1.0)
                                                            options:_WLDownward]);
        }

        aCanFitBoth = alignedMinSizeBoth <= availableSpace;
    }

    if (aCanFitBoth)
    {
        if (isVertical)
        {
            return (_WLPositionRange){
                .min = NSMaxX([aView backingAlignedRect:NSMakeRect(minPosition, 0.0, aMinSizeA, 1.0) options:_WLRightward]),
                .max = NSMaxX([aView backingAlignedRect:NSMakeRect(minPosition, 0.0, availableSpace - aMinSizeB, 1.0) options:_WLLeftward])
            };
        }
        else
        {
            return (_WLPositionRange){
                .min = NSMaxY([aView backingAlignedRect:NSMakeRect(0.0, minPosition, 1.0, aMinSizeA) options:_WLDownward]),
                .max = NSMaxY([aView backingAlignedRect:NSMakeRect(0.0, minPosition, 1.0, availableSpace - aMinSizeB) options:_WLUpward])
            };
        }
    }
    else
        return (_WLPositionRange){ .min = maxPosition, .max = minPosition };
}

- (void)_layoutRootSplitView
{
    if (!_toMockupRootTransform)
        return;

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

    if (!_layout.canFitInfo || !_layout.canFitWeek)
        return;

    // Transform layout width to mockup width.
    __auto_type Transform = ^(CGFloat aWidth)
    {
        return [self->_toMockupRootTransform transformSize:NSMakeSize(aWidth, 0.0)].width;
    };

    // Align mockup width to pixel bounds. Only MaxX is expected to be unaligned.
    __auto_type Align = ^(CGFloat aMaxX)
    {
        return NSMaxX([self->_rootArrangementView backingAlignedRect:NSMakeRect(0.0, 0.0, aMaxX, 1.0)
                                                             options:_WLRightward]);
    };

    CGFloat dividerPosition = 0.0;

    if (_layout.isInfoCollapsed)
        dividerPosition = 0.0;
    else if (_layout.isWeekCollapsed)
        dividerPosition = NSWidth(_rootArrangementView.bounds) - _rootArrangementView.dividerThickness;
    else
        dividerPosition = Align(Transform(_layout.infoWidth));

    [_rootArrangementView setPosition:dividerPosition ofDividerAtIndex:0];

    _rootDividerPositionRange = [self _calcPositionRangeForArrangementView:_rootArrangementView
                                                              dividerIndex:0
                                                                  minSizeA:Transform(_layout.minInfoWidth)
                                                                  minSizeB:Transform(_layout.minWeekWidth + _layout.spacingAfterInfo)
                                                                canFitBoth:_layout.canFitInfoAndWeek];
}

- (void)_layoutInfoSplitView
{
    if (!_infoArrangementView)
        return;

    NSUInteger numberOfPanes = (NSUInteger)(_layout.canFitDate + _layout.canFitReminders + _layout.canFitRightNow);
    [self _configureArrangementView:_infoArrangementView forNumberOfPanes:numberOfPanes];
    if (numberOfPanes < 2)
        return;

    // Transform layout height to mockup height.
    __auto_type Transform = ^(CGFloat aHeight)
    {
        return [self->_toMockupInfoTransform transformSize:NSMakeSize(0.0, aHeight)].height;
    };

    // Align mockup height to pixel bounds.
    __auto_type Align = ^(CGFloat aMinY, CGFloat aHeight)
    {
        return NSMaxY([self->_infoArrangementView backingAlignedRect:NSMakeRect(0.0, aMinY, 1.0, aHeight) options:_WLDownward]);
    };

    if (_layout.canFitDate && _layout.canFitReminders && _layout.canFitRightNow)
    {
        CGFloat divider0Position = 0.0;
        CGFloat divider1Position = 0.0;

        if (_layout.isDateCollapsed && _layout.isRemindersCollapsed)
        {
            divider0Position = 0.0;
            divider1Position = _infoArrangementView.dividerThickness;
        }
        else if (_layout.isDateCollapsed && _layout.isRightNowCollapsed)
        {
            divider0Position = 0.0;
            divider1Position = NSHeight(_infoArrangementView.bounds) - _infoArrangementView.dividerThickness;
        }
        else if (_layout.isRemindersCollapsed && _layout.isRightNowCollapsed)
        {
            divider1Position = NSHeight(_infoArrangementView.bounds) - _infoArrangementView.dividerThickness;
            divider0Position = divider1Position - _infoArrangementView.dividerThickness;
        }
        else if (_layout.isDateCollapsed)
        {
            divider0Position = 0.0;
            divider1Position = Align(_infoArrangementView.dividerThickness, Transform(_layout.remindersHeight));
        }
        else if (_layout.isRemindersCollapsed)
        {
            divider0Position = Align(0.0, Transform(_layout.dateHeight));
            divider1Position = divider0Position + _infoArrangementView.dividerThickness;
        }
        else if (_layout.isRightNowCollapsed)
        {
            divider0Position = Align(0.0, Transform(_layout.dateHeight));
            divider1Position = NSHeight(_infoArrangementView.bounds) - _infoArrangementView.dividerThickness;
        }
        else
        {
            divider0Position = Align(0.0, Transform(_layout.dateHeight));
            divider1Position = Align(divider0Position + _infoArrangementView.dividerThickness, Transform(_layout.remindersHeight + _layout.spacingAfterDate));
        }

        if (divider0Position <= ([_infoArrangementView positionOfDividerAtIndex:1] - _infoArrangementView.dividerThickness))
        {
            [_infoArrangementView setPosition:divider0Position ofDividerAtIndex:0];
            [_infoArrangementView setPosition:divider1Position ofDividerAtIndex:1];
        }
        else
        {
            [_infoArrangementView setPosition:divider1Position ofDividerAtIndex:1];
            [_infoArrangementView setPosition:divider0Position ofDividerAtIndex:0];
        }

        _infoDividerPositionRange[0] = [self _calcPositionRangeForArrangementView:_infoArrangementView
                                                                     dividerIndex:0
                                                                         minSizeA:Transform(_layout.minDateHeight)
                                                                         minSizeB:Transform(_layout.minRemindersHeight + _layout.spacingAfterDate)
                                                                       canFitBoth:_layout.canFitDateAndReminders];
        _infoDividerPositionRange[1] = [self _calcPositionRangeForArrangementView:_infoArrangementView
                                                                     dividerIndex:1
                                                                         minSizeA:Transform(_layout.minRemindersHeight + _layout.spacingAfterDate)
                                                                         minSizeB:Transform(_layout.minRightNowHeight + _layout.spacingAfterReminders)
                                                                       canFitBoth:_layout.canFitRemindersAndRightNow];
    }
    else if (_layout.canFitDate && _layout.canFitReminders)
    {
        CGFloat dividerPosition = 0.0;

        if (_layout.isDateCollapsed)
            dividerPosition = 0.0;
        else if (_layout.isRemindersCollapsed)
            dividerPosition = NSHeight(_infoArrangementView.bounds) - _infoArrangementView.dividerThickness;
        else
            dividerPosition = Align(0.0, Transform(_layout.dateHeight));

        [_infoArrangementView setPosition:dividerPosition ofDividerAtIndex:0];

        _infoDividerPositionRange[0] = [self _calcPositionRangeForArrangementView:_infoArrangementView
                                                                     dividerIndex:0
                                                                         minSizeA:Transform(_layout.minDateHeight)
                                                                         minSizeB:Transform(_layout.minRemindersHeight + _layout.spacingAfterDate)
                                                                       canFitBoth:_layout.canFitDateAndReminders];
    }
    else if (_layout.canFitDate && _layout.canFitRightNow)
    {
        CGFloat dividerPosition = 0.0;

        if (_layout.isDateCollapsed)
            dividerPosition = 0.0;
        else if (_layout.isRightNowCollapsed)
            dividerPosition = NSHeight(_infoArrangementView.bounds) - _infoArrangementView.dividerThickness;
        else
            dividerPosition = Align(0.0, Transform(_layout.dateHeight));

        [_infoArrangementView setPosition:dividerPosition ofDividerAtIndex:0];

        _infoDividerPositionRange[0] = [self _calcPositionRangeForArrangementView:_infoArrangementView
                                                                     dividerIndex:0
                                                                         minSizeA:Transform(_layout.minDateHeight)
                                                                         minSizeB:Transform(_layout.minRightNowHeight + _layout.spacingAfterDate)
                                                                       canFitBoth:_layout.canFitDateAndRightNow];
    }
    else if (_layout.canFitRemindersAndRightNow)
    {
        CGFloat dividerPosition = 0.0;

        if (_layout.isRemindersCollapsed)
            dividerPosition = 0.0;
        else if (_layout.isRightNowCollapsed)
            dividerPosition = NSHeight(_infoArrangementView.bounds) - _infoArrangementView.dividerThickness;
        else
            dividerPosition = Align(0.0, Transform(_layout.remindersHeight));

        [_infoArrangementView setPosition:dividerPosition ofDividerAtIndex:0];

        _infoDividerPositionRange[0] = [self _calcPositionRangeForArrangementView:_infoArrangementView
                                                                     dividerIndex:0
                                                                         minSizeA:Transform(_layout.minRemindersHeight)
                                                                         minSizeB:Transform(_layout.minRightNowHeight + _layout.spacingAfterReminders)
                                                                       canFitBoth:_layout.canFitRemindersAndRightNow];
    }
}

- (void)_layoutWeekSplitView
{
    if (!_weekArrangementView)
        return;

    [self _configureArrangementView:_weekArrangementView forNumberOfPanes:(NSUInteger)(_layout.canFitAllDayEvents + _layout.canFitDayEvents)];
    if (_weekArrangementView.arrangedSubviews.count < 2)
        return;

    // Transform layout height to mockup height.
    __auto_type Transform = ^(CGFloat aHeight)
    {
        return [self->_toMockupWeekTransform transformSize:NSMakeSize(0.0, aHeight)].height;
    };

    // Align mockup height to pixel bounds.
    __auto_type Align = ^(CGFloat aMaxY)
    {
        return NSMaxY([self->_weekArrangementView backingAlignedRect:NSMakeRect(0.0, 0.0, 1.0, aMaxY) options:_WLDownward]);
    };

    CGFloat dividerPosition = 0.0;

    if (_layout.isAllDayEventsCollapsed)
        dividerPosition = 0.0;
    else if (_layout.isDayEventsCollapsed)
        dividerPosition = NSHeight(_weekArrangementView.bounds) - _weekArrangementView.dividerThickness;
    else
        dividerPosition = Align(Transform(_layout.allDayEventsHeight));

    [_weekArrangementView setPosition:dividerPosition ofDividerAtIndex:0];

    _weekDividerPositionRange = [self _calcPositionRangeForArrangementView:_weekArrangementView
                                                              dividerIndex:0
                                                                  minSizeA:Transform(_layout.minAllDayEventsHeight)
                                                                  minSizeB:Transform(_layout.minDayEventsHeight + _layout.spacingAfterAllDayEvents)
                                                                canFitBoth:_layout.canFitAllDayAndDayEvents];
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

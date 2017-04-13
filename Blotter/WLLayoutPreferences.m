//
//  LayoutPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutPreferences.h"
#import "WLLayoutCalendarWindowView.h"
#import "DeskboardAppDelegate.h"
#import "WLCalendarWindowController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


@implementation WLLayoutPreferences

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.isViewLoaded)
    {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"CalendarLayout"];
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:WLScreenIdentifierKey];
    }
}


#pragma mark Methods

- (NSSize)preferredFrameSizeOfPaneView
{
    NSSize mainViewSize = self.view.bounds.size;
    NSSize layoutControlSize = [_layoutControl frame].size;
    NSSize layoutControlMargin = NSMakeSize(mainViewSize.width - layoutControlSize.width,
                                            mainViewSize.height - layoutControlSize.height);
    // Width is persistant. Adjust height according to aspect ratio.
    WLCalendarWindowController *w = [(DeskboardAppDelegate *)[NSApp delegate] calendarWindowController];
    NSRect screenFrame = [[w windowScreen] visibleFrame];
    CGFloat aspectRatio = !NSEqualRects(screenFrame, NSZeroRect) ? screenFrame.size.width / screenFrame.size.height : 16.0 / 10.0;
    CGFloat preferredLayoutControlHeight = (mainViewSize.width - layoutControlMargin.width) / aspectRatio;
    // Align frame.
    NSRect preferredLayoutControlFrame = [_layoutControl frame];
    preferredLayoutControlFrame.size.height = preferredLayoutControlHeight;
    preferredLayoutControlFrame = [self.view centerScanRect:preferredLayoutControlFrame];
    preferredLayoutControlHeight = preferredLayoutControlFrame.size.height;
    return NSMakeSize(mainViewSize.width,
                      preferredLayoutControlHeight + layoutControlMargin.height);
}


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"preferences-layout-icon"];
    anItem.label = NSLocalizedString(@"Layout", @"Layout pref pane title");
    anItem.toolTip = NSLocalizedString(@"Layout Preferences", @"Layout pref pane tooltip");
}


#pragma mark WLLayoutSplitViewDelegate

- (void)splitViewWillTrackMouse:(WLLayoutSplitView *)aSplitView
{
    _resizedSplitView = aSplitView;
    _areSplitViewsResizedUsingMouse = YES;
}

- (void)splitViewDidTrackMouse:(WLLayoutSplitView *)aSplitView
{
    _areSplitViewsResizedUsingMouse = NO;
    _resizedSplitView = nil;
}


#pragma mark NSSplitViewDelegate

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
    NSSplitView *splitView = [aNotification object];
    if (!_areSplitViewsResizedUsingMouse || splitView != _resizedSplitView)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"CalendarLayout"] != WLCalendarCustomLayout)
        [defaults setInteger:WLCalendarCustomLayout forKey:@"CalendarLayout"];

    // A User shouldn't be able to rewrite defaults of info section while calendar size is Narrow.
    // E.g. before setting calendar size to Narrow size was 600. After setting calendar size to Narrow
    // width will be forced to a specific value (@see -[WLCalendarWindowController _applyNarrowSizeToViews),
    // but defaults will contain original setting (600). If the user drags divider of _infoWidthSplitView,
    // it won't be moved, but this method will be called and defaults will be overwritten.
    // To prevent this, we are checking CalendarSize.
    if (splitView == _rootSplitView && [defaults integerForKey:@"CalendarSize"] != BLNarrowSize)
    {
        CGFloat width = 0.0;
        if (![_rootSplitView isSubviewCollapsed:[_rootSplitView viewWithTag:WLLayoutInfoSplitViewTag]])
        {
            NSSize infoViewsSize = NSMakeSize([_infoSplitView frame].size.width, 0.0);
            infoViewsSize = [self._rootSplitViewToBlotterWindowTransform transformSize:infoViewsSize];
            width = infoViewsSize.width;
        }
        [defaults setDouble:floor(width) forKey:@"InfoViewsWidth"];
    }
    else
    {
        for (NSView *v in [[aNotification object] subviews])
        {
            switch ([v tag])
            {
                case WLLayoutDateViewTag:
                {
                    CGFloat height = 0.0;
                    if (![_infoSplitView isSubviewCollapsed:v])
                    {
                        NSSize dateViewSize = NSMakeSize(0.0, [v frame].size.height);
                        dateViewSize = [self._infoSplitViewToBlotterWindowTransform transformSize:dateViewSize];
                        height = dateViewSize.height;
                    }
                    [defaults setDouble:floor(height) forKey:@"DateViewHeight"];
                    break;
                }
                case WLLayoutTasksViewTag:
                {
                    CGFloat height = 0.0;
                    if (![_infoSplitView isSubviewCollapsed:v])
                    {
                        NSSize tasksViewSize = NSMakeSize(0.0, [v frame].size.height);
                        tasksViewSize = [self._infoSplitViewToBlotterWindowTransform transformSize:tasksViewSize];
                        height = tasksViewSize.height;
                    }
                    [defaults setDouble:floor(height) forKey:@"TasksViewHeight"];
                    break;
                }
                case WLLayoutAllDayViewTag:
                {
                    CGFloat height = 0.0;
                    if (![_weekSplitView isSubviewCollapsed:v])
                    {
                        NSSize allDayViewSize = NSMakeSize(0.0, [v frame].size.height);
                        allDayViewSize = [self._weekSplitViewToBlotterWindowTransform transformSize:allDayViewSize];
                        height = allDayViewSize.height;
                    }
                    [defaults setDouble:floor(height) forKey:@"AllDayViewHeight"];
                    break;
                }
                default:
                    break;
            }
        }
    }
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(CGFloat)aProposedPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    // Snap to grid if Alt is pressed.
    if ([NSEvent modifierFlags] & NSAlternateKeyMask)
        return round(aProposedPosition / 10.0) * 10.0;
    else
        return aProposedPosition;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMinCoordinate:(CGFloat)aProposedMinimumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (aSplitView == _rootSplitView)
    {
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"] == BLNarrowSize)
            return [aSplitView bounds].size.width - [aSplitView dividerThickness];
        else
            return 0;
    }
    else
        return aProposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)aProposedMaximumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (aSplitView == _rootSplitView)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        CGFloat splitViewWidth = [aSplitView bounds].size.width;
        if ([defaults integerForKey:@"CalendarSize"] == BLNarrowSize)
            return splitViewWidth - [aSplitView dividerThickness];
        else
        {
            NSSize minWeekViewSize = NSMakeSize([defaults floatForKey:@"MinimumWeekViewWidth"], 0.0);
            minWeekViewSize = [self._blotterWindowToRootSplitViewTransform transformSize:minWeekViewSize];
            return splitViewWidth - [aSplitView dividerThickness] - minWeekViewSize.width;
        }
    }
    else
        return aProposedMaximumPosition;
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aSubview
{
    return YES;
}

- (BOOL)splitView:(NSSplitView *)aSplitView shouldHideDividerAtIndex:(NSInteger)aDividerIndex
{
    // User unable to change width of the info views when size is narrow, because only info views are displayed.
    return (aSplitView == _rootSplitView && [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"] == BLNarrowSize);
}

- (void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [self _recalculateTransforms];
    if (aSplitView == _rootSplitView)
        [self _layoutRootSplitViewWithParameters:[self _parameters]];
    else if (aSplitView == _weekSplitView)
        [self _layoutWeekSplitViewWithParameters:[self _parameters]];
    else if (aSplitView == _infoSplitView)
        [self _layoutInfoSplitViewWithParameters:[self _parameters]];
}

- (BOOL)splitView:(NSSplitView *)aSplitView shouldCollapseSubview:(NSView *)aSubview forDoubleClickOnDividerAtIndex:(NSInteger)aDividerIndex
{
    if (aSplitView == _rootSplitView && [aSubview tag] == WLLayoutInfoSplitViewTag)
        return YES;
    else if (aSplitView == _weekSplitView && [aSubview tag] == WLLayoutAllDayViewTag)
        return YES;
    else if (aSplitView == _infoSplitView && aDividerIndex == 0 && [aSubview tag] == WLLayoutDateViewTag)
        return YES;
    else if (aSplitView == _infoSplitView && aDividerIndex == 1 && [aSubview tag] == WLLayoutRightNowViewTag)
        return YES;
    else
        return NO;
}


#pragma mark Private
@synthesize _blotterWindowToRootSplitViewTransform;
@synthesize _rootSplitViewToBlotterWindowTransform;
@synthesize _blotterWindowToWeekSplitViewTransform;
@synthesize _weekSplitViewToBlotterWindowTransform;
@synthesize _blotterWindowToInfoSplitViewTransform;
@synthesize _infoSplitViewToBlotterWindowTransform;

- (void)_screenFrameDidChange
{
    IKApplicationPreferences *applicationPreferences = self.view.window.windowController;
    [applicationPreferences setSelectedRepresentationViewSize:[self preferredFrameSizeOfPaneView] animated:YES];
}

- (void)_calendarWindowSizeDidChange
{
    [self _adjustCalendarWindowViewFrame];
}

- (void)_layoutFrameDidChange
{
    [self _adjustCalendarWindowViewFrame];
}

- (void)_recalculateTransforms
{
    self._blotterWindowToRootSplitViewTransform = [[NSAffineTransform alloc] init];
    self._rootSplitViewToBlotterWindowTransform = [[NSAffineTransform alloc] init];
    self._blotterWindowToWeekSplitViewTransform = [[NSAffineTransform alloc] init];
    self._weekSplitViewToBlotterWindowTransform = [[NSAffineTransform alloc] init];
    self._blotterWindowToInfoSplitViewTransform = [[NSAffineTransform alloc] init];
    self._infoSplitViewToBlotterWindowTransform = [[NSAffineTransform alloc] init];

    NSRect layoutViewFrame = [_rootSplitView frame];
    DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSRect blotterViewFrame = [[[delegate.calendarWindowController window] contentView] frame];
    CGFloat rootSplitViewXDividersThickness = [_rootSplitView dividerThickness];
    CGFloat rootSplitViewYDividersThickness = 0.0;
    CGFloat weekSplitViewXDividerThickness = 0.0;
    CGFloat weekSplitViewYDividerThickness = [_weekSplitView dividerThickness];
    CGFloat infoSplitViewXDividerThickness = 0.0;
    CGFloat infoSplitViewYDividerThickness = 2 * [_infoSplitView dividerThickness];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"] == BLNarrowSize)
        rootSplitViewXDividersThickness = 0.0;

    [self._blotterWindowToRootSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - rootSplitViewXDividersThickness) / NSWidth(blotterViewFrame)
                                                      yBy:(NSHeight(layoutViewFrame) - rootSplitViewYDividersThickness) / NSHeight(blotterViewFrame)];
    [self._rootSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - rootSplitViewXDividersThickness)
                                                      yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - rootSplitViewYDividersThickness)];

    [self._blotterWindowToWeekSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - weekSplitViewXDividerThickness) / NSWidth(blotterViewFrame)
                                                      yBy:(NSHeight(layoutViewFrame) - weekSplitViewYDividerThickness) / NSHeight(blotterViewFrame)];
    [self._weekSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - weekSplitViewXDividerThickness)
                                                      yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - weekSplitViewYDividerThickness)];

    [self._blotterWindowToInfoSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - infoSplitViewXDividerThickness) / NSWidth(blotterViewFrame)
                                                      yBy:(NSHeight(layoutViewFrame) - infoSplitViewYDividerThickness) / NSHeight(blotterViewFrame)];
    [self._infoSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - infoSplitViewXDividerThickness)
                                                      yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - infoSplitViewYDividerThickness)];
}

- (void)_adjustCalendarWindowViewFrame
{
    DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSRect windowFrame = [delegate.calendarWindowController windowFrame];
    NSRect bounds = [_layoutControl bounds];
    // WLRecessedBoxShadow draws 1px horizontal white line at the bottom.
    bounds.size.height -= 1.0;
    bounds.origin.y += 1.0;
    // Add margin around calendar window view like on the position pref pane.
    bounds = NSInsetRect(bounds, 3.0, 3.0);
    NSSize viewFrameSize = NSMakeSize(2 * ceil(NSHeight(bounds) * windowFrame.size.width / windowFrame.size.height / 2),
                                      NSHeight(bounds));
    // Scale view Frame
    CGFloat scaleFactor = fmin(NSWidth(bounds) / viewFrameSize.width, NSHeight(bounds) / viewFrameSize.height);
    viewFrameSize.width *= scaleFactor;
    viewFrameSize.height *= scaleFactor;

    NSRect viewFrame = NSMakeRect(NSMinX(bounds) + (NSWidth(bounds) - viewFrameSize.width) / 2.0,
                                  NSMinY(bounds) + (NSHeight(bounds) - viewFrameSize.height) / 2.0,
                                  viewFrameSize.width,
                                  viewFrameSize.height);
    [_calendarWindowView setFrame:[_layoutControl centerScanRect:viewFrame]];
    [[_calendarWindowView layer] setNeedsLayout];
}

- (void)_layoutRootSplitViewWithParameters:(NSDictionary *)aParameters
{
    [_rootSplitView adjustSubviews];
    NSRect bounds = [_rootSplitView bounds];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"] != BLNarrowSize)
    {
        NSSize infoViewsSize = NSMakeSize([[aParameters objectForKey:@"InfoViewsWidth"] floatValue],
                                          0.0);
        infoViewsSize = [self._blotterWindowToRootSplitViewTransform transformSize:infoViewsSize];
        infoViewsSize.width = round(infoViewsSize.width);
        [_rootSplitView setPosition:fmin([_rootSplitView maxPossiblePositionOfDividerAtIndex:0], NSMinX(bounds) + infoViewsSize.width)
                   ofDividerAtIndex:0];
    }
    else
    {
        [_rootSplitView setPosition:NSMaxX(bounds) ofDividerAtIndex:0];
    }
}

- (void)_layoutWeekSplitViewWithParameters:(NSDictionary *)aParameters
{
    [_weekSplitView adjustSubviews];
    NSRect bounds = [_weekSplitView bounds];
    NSSize allDayViewSize = NSMakeSize(0.0, round([[aParameters objectForKey:@"AllDayViewHeight"] floatValue]));
    allDayViewSize = [self._blotterWindowToWeekSplitViewTransform transformSize:allDayViewSize];
    allDayViewSize.height = round(allDayViewSize.height);
    [_weekSplitView setPosition:fmin([_weekSplitView maxPossiblePositionOfDividerAtIndex:0], NSMinY(bounds) + allDayViewSize.height)
               ofDividerAtIndex:0];
}

- (void)_layoutInfoSplitViewWithParameters:(NSDictionary *)aParameters
{
    [_infoSplitView adjustSubviews];
    NSRect bounds = [_infoSplitView bounds];
    NSSize dateViewSize = NSMakeSize(0.0, [[aParameters objectForKey:@"DateViewHeight"] floatValue]);
    dateViewSize = [self._blotterWindowToInfoSplitViewTransform transformSize:dateViewSize];
    dateViewSize.height = round(dateViewSize.height);
    [_infoSplitView setPosition:fmin([_infoSplitView maxPossiblePositionOfDividerAtIndex:0], NSMinY(bounds) + dateViewSize.height)
               ofDividerAtIndex:0];


    NSSize tasksViewSize = NSMakeSize(0.0, [[aParameters objectForKey:@"TasksViewHeight"] floatValue]);
    tasksViewSize = [self._blotterWindowToInfoSplitViewTransform transformSize:tasksViewSize];
    tasksViewSize.height = round(tasksViewSize.height);
    NSView *dateView = [_infoSplitView viewWithTag:WLLayoutDateViewTag];
    NSParameterAssert(dateView != nil);
    [_infoSplitView setPosition:fmin([_infoSplitView maxPossiblePositionOfDividerAtIndex:1], NSMaxY([dateView frame]) + [_infoSplitView dividerThickness] + tasksViewSize.height)
               ofDividerAtIndex:1];
}

- (void)_layoutSplitViewsWithParameters:(NSDictionary *)aParameters
{
    [self _layoutRootSplitViewWithParameters:aParameters];
    [self _layoutWeekSplitViewWithParameters:aParameters];
    [self _layoutInfoSplitViewWithParameters:aParameters];
}

- (NSDictionary *)_parameters
{
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarLayout"] != WLCalendarCustomLayout)
        return [self _defaultParameters];
    else
        return [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
}

- (NSDictionary *)_defaultParameters
{
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];

    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithContentsOfURL:defaultsURL];
    DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];

    CGFloat taskViewHeight = 0;
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarLayout"])
    {
        case WLCalendarRightNowLayout:
            taskViewHeight = 0;
            break;
        case WLCalendarToDoLayout:
            taskViewHeight = [delegate.calendarWindowController fullTasksViewHeight];
            break;
        default:
            taskViewHeight = [delegate.calendarWindowController defaultTasksViewHeight];
    }
    [defaults setObject:@(taskViewHeight) forKey:@"TasksViewHeight"];

    return defaults;
}


#pragma mark NSViewController

- (void)loadView
{
    [super loadView];

    [self.view setFrameSize:[self preferredFrameSizeOfPaneView]];
    [self _adjustCalendarWindowViewFrame];
    DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_calendarWindowSizeDidChange)
                                                 name:NSWindowDidResizeNotification
                                               object:[delegate.calendarWindowController window]];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"CalendarLayout" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:WLScreenIdentifierKey options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_screenFrameDidChange)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:NSApp];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_layoutFrameDidChange)
                                                 name:NSViewFrameDidChangeNotification
                                               object:_layoutControl];
    [_layoutControl setPostsFrameChangedNotifications:YES];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"CalendarLayout"])
    {
        NSInteger calendarLayout = [[aChange objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (calendarLayout != WLCalendarCustomLayout)
        {
            NSDictionary *defaultParameters = [self _defaultParameters];
            [[NSUserDefaults standardUserDefaults] setObject:[defaultParameters objectForKey:@"TasksViewHeight"]
                                                      forKey:@"TasksViewHeight"];
            [[NSUserDefaults standardUserDefaults] setObject:[defaultParameters objectForKey:@"AllDayViewHeight"]
                                                      forKey:@"AllDayViewHeight"];
            [[NSUserDefaults standardUserDefaults] setObject:[defaultParameters objectForKey:@"DateViewHeight"]
                                                      forKey:@"DateViewHeight"];
            [[NSUserDefaults standardUserDefaults] setObject:[defaultParameters objectForKey:@"InfoViewsWidth"]
                                                      forKey:@"InfoViewsWidth"];
            [self _layoutSplitViewsWithParameters:defaultParameters];
        }
    }
    else if ([aKeyPath isEqualToString:WLScreenIdentifierKey])
        [self _screenFrameDidChange];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

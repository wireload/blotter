//
//  LayoutPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "LayoutPrefController.h"
#import "WLLayoutRootView.h"
#import "DeskboardAppDelegate.h"
#import "WLCalendarWindowController.h"
#import "WLPrefPaneView.h"


@implementation LayoutPrefController

- (void)dealloc {
    [_blotterWindowToInfoWidthSplitViewTransform release];
    [_infoWidthSplitViewToBlotterWindowTransform release];
    [_blotterWindowToAllDayHeightSplitViewTransform release];
    [_allDayHeightSplitViewToBlotterWindowTransform release];
    [_blotterWindowToDateHeightSplitViewTransform release];
    [_dateHeightSplitViewToBlotterWindowTransform release];
    [_blotterWindowToTasksHeightSplitViewTransform release];
    [_tasksHeightSplitViewToBlotterWindowTransform release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_mainView != nil)
    {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"CalendarLayout"];
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ScreenIdentifier"];
    }
    [super dealloc];
}


#pragma mark Methods

- (void)layoutSplitViewWithParameters:(id)aParameters
{
    NSSize infoViewsSize = NSMakeSize([[aParameters objectForKey:@"InfoViewsWidth"] floatValue], 0.0f);
    infoViewsSize = [_blotterWindowToInfoWidthSplitViewTransform transformSize:infoViewsSize];
    [_infoWidthSplitView setPosition:infoViewsSize.width ofDividerAtIndex:0];

    NSSize dateViewSize = NSMakeSize(0.0f, [[aParameters objectForKey:@"DateViewHeight"] floatValue]);
    dateViewSize = [_blotterWindowToDateHeightSplitViewTransform transformSize:dateViewSize];
    [_dateHeightSplitView setPosition:dateViewSize.height ofDividerAtIndex:0];

    NSSize tasksViewSize = NSMakeSize(0.0f, [[aParameters objectForKey:@"TasksViewHeight"] floatValue]);
    tasksViewSize = [_blotterWindowToTasksHeightSplitViewTransform transformSize:tasksViewSize];
    [_tasksHeightSplitView setPosition:tasksViewSize.height ofDividerAtIndex:0];

    NSSize allDayViewSize = NSMakeSize(0.0f, [[aParameters objectForKey:@"AllDayViewHeight"] floatValue]);
    allDayViewSize = [_blotterWindowToAllDayHeightSplitViewTransform transformSize:allDayViewSize];
    [_allDayHeightSplitView setPosition:allDayViewSize.height ofDividerAtIndex:0];
}

- (void)transformsDidChange
{
    _areSplitViewsBeenInitializing = YES;
    [_blotterWindowToInfoWidthSplitViewTransform release];
    [_infoWidthSplitViewToBlotterWindowTransform release];
    [_blotterWindowToAllDayHeightSplitViewTransform release];
    [_allDayHeightSplitViewToBlotterWindowTransform release];
    [_blotterWindowToDateHeightSplitViewTransform release];
    [_dateHeightSplitViewToBlotterWindowTransform release];
    [_blotterWindowToTasksHeightSplitViewTransform release];
    [_tasksHeightSplitViewToBlotterWindowTransform release];

    _blotterWindowToInfoWidthSplitViewTransform = [[NSAffineTransform alloc] init];
    _infoWidthSplitViewToBlotterWindowTransform = [[NSAffineTransform alloc] init];
    _blotterWindowToAllDayHeightSplitViewTransform = [_blotterWindowToInfoWidthSplitViewTransform retain];
    _allDayHeightSplitViewToBlotterWindowTransform = [_infoWidthSplitViewToBlotterWindowTransform retain];
    _blotterWindowToTasksHeightSplitViewTransform = [[NSAffineTransform alloc] init];
    _tasksHeightSplitViewToBlotterWindowTransform = [[NSAffineTransform alloc] init];
    _blotterWindowToDateHeightSplitViewTransform = [_blotterWindowToTasksHeightSplitViewTransform retain];
    _dateHeightSplitViewToBlotterWindowTransform = [_tasksHeightSplitViewToBlotterWindowTransform retain];

    NSRect layoutViewFrame = [_layoutView frame];
    DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSRect blotterViewFrame = [[delegate.calendarWindowController.window contentView] frame];
    // All split views have the same divider thickness.
    CGFloat dividerThickness = [_infoWidthSplitView dividerThickness];
    // _infoWidthSplitViewa and _allDayHeightSplitView have only 1 divider.
    // _dateHeightSplitView and _tasksHeightSplitView have 2 dividers.
    [_blotterWindowToInfoWidthSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - dividerThickness) / NSWidth(blotterViewFrame)
                                                 yBy:(NSHeight(layoutViewFrame) - dividerThickness) / NSHeight(blotterViewFrame)];
    [_infoWidthSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - dividerThickness)
                                                 yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - dividerThickness)];

    [_blotterWindowToTasksHeightSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - 2 * dividerThickness) / NSWidth(blotterViewFrame)
                                                             yBy:(NSHeight(layoutViewFrame) - 2 * dividerThickness) / NSHeight(blotterViewFrame)];
    [_tasksHeightSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - 2 * dividerThickness)
                                                             yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - 2 * dividerThickness)];
    [self layoutSplitViewWithParameters:[NSUserDefaults standardUserDefaults]];
    _areSplitViewsBeenInitializing = NO;
}

- (void)updatePreferredFrameSizeOfPaneView
{
    NSSize mainViewSize = [_mainView bounds].size;
    NSSize layoutControlSize = [_layoutControl frame].size;
    NSSize layoutControlMargin = NSMakeSize(mainViewSize.width - layoutControlSize.width,
                                            mainViewSize.height - layoutControlSize.height);
    // Width is persistant. Adjust height according to aspect ratio.
    WLCalendarWindowController *w = [(DeskboardAppDelegate *)[NSApp delegate] calendarWindowController];
    NSRect screenFrame = [[w windowScreen] visibleFrame];
    CGFloat aspectRatio = !NSEqualRects(screenFrame, NSZeroRect) ? screenFrame.size.width / screenFrame.size.height : 16.0f / 10.0f;
    CGFloat preferredLayoutControlHeight = (mainViewSize.width - layoutControlMargin.width) / aspectRatio;
    // Align frame.
    NSRect preferredLayoutControlFrame = [_layoutControl frame];
    preferredLayoutControlFrame.size.height = preferredLayoutControlHeight;
    preferredLayoutControlFrame = [_mainView centerScanRect:preferredLayoutControlFrame];
    preferredLayoutControlHeight = preferredLayoutControlFrame.size.height;

    _mainView.preferredFrameSize = NSMakeSize(mainViewSize.width,
                                              preferredLayoutControlHeight + layoutControlMargin.height);
    [self transformsDidChange];
}


#pragma mark SS_PreferencePaneProtocol

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"LayoutPrefPaneView" owner:self])
        {
            _defaultFrameSize = [_mainView frame].size;
            [self updatePreferredFrameSizeOfPaneView];
            DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(transformsDidChange)
                                                         name:NSWindowDidResizeNotification
                                                       object:delegate.calendarWindowController.window];
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"CalendarLayout" options:NSKeyValueObservingOptionNew context:NULL];
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"ScreenIdentifier" options:NSKeyValueObservingOptionNew context:NULL];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updatePreferredFrameSizeOfPaneView)
                                                         name:NSApplicationDidChangeScreenParametersNotification
                                                       object:NSApp];
        }
    }
    return _mainView;
}

- (NSString *)paneName
{
    return NSLocalizedStringFromTableInBundle(@"Layout", nil, [NSBundle bundleForClass:[self class]], @"Layout pref pane title");
}

- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Layout-Icon" ofType:@"png"]] autorelease];
}


- (NSString *)paneToolTip
{
    return NSLocalizedStringFromTableInBundle(@"Layout Preferences", nil, [NSBundle bundleForClass:[self class]], @"Layout pref pane tooltip");
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}


#pragma mark NSSplitViewDelegate

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
    if (_areSplitViewsBeenInitializing)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (!_areSplitViewsBeenResettingToDefault && [defaults integerForKey:@"CalendarLayout"] == WLCalendarNormalLayout)
        [defaults setInteger:WLCalendarCustomLayout forKey:@"CalendarLayout"];
    NSSplitView *splitView = [aNotification object];
    // A User shouldn't be able to rewrite defaults of info section while calendar size is Narrow.
    // E.g. before setting calendar size to Narrow size was 600. After setting calendar size to Narrow
    // width will be forced to a specific value (@see -[WLCalendarWindowController _applyNarrowSizeToViews),
    // but defaults will contain original setting (600). If the user drags divider of _infoWidthSplitView,
    // it won't be moved, but this method will be called and defaults will be overwritten.
    // To prevent this, we are checking CalendarSize.
    if (splitView == _infoWidthSplitView && [defaults integerForKey:@"CalendarSize"] != BLNarrowSize)
    {
        NSSize infoViewsSize = NSMakeSize([_dateHeightSplitView frame].size.width, 0.0f);
        NSSize infoViewsSizeOnBlotterWindow = [_infoWidthSplitViewToBlotterWindowTransform transformSize:infoViewsSize];
        NSLog(@"%f | %f", infoViewsSizeOnBlotterWindow.width, [[[[[NSApp delegate] calendarWindowController] window] contentView] frame].size.width - infoViewsSizeOnBlotterWindow.width);
//        CGFloat errorBar = infoViewsSizeOnBlotterWindow.width / infoViewsSize.width;
//        CGFloat maxDividerPosition = [splitView maxPossiblePositionOfDividerAtIndex:0];
        [defaults setFloat:floorf(infoViewsSizeOnBlotterWindow.width) forKey:@"InfoViewsWidth"];
    }
    else
    {
        for (NSView *v in [[aNotification object] subviews])
        {
            switch ([v tag]) {
                case WLLayoutDateViewTag: {
                    NSSize dateViewSize = NSMakeSize(0.0f, [v frame].size.height);
                    dateViewSize = [_dateHeightSplitViewToBlotterWindowTransform transformSize:dateViewSize];
                    [defaults setFloat:floorf(dateViewSize.height) forKey:@"DateViewHeight"];
                    break;
                }
                case WLLayoutTasksViewTag: {
                    NSSize tasksViewSize = NSMakeSize(0.0f, [v frame].size.height);
                    tasksViewSize = [_tasksHeightSplitViewToBlotterWindowTransform transformSize:tasksViewSize];
                    [defaults setFloat:floorf(tasksViewSize.height) forKey:@"TasksViewHeight"];
                    break;
                }
                case WLLayoutAllDayViewTag: {
                    NSSize allDayViewSize = NSMakeSize(0.0f, [v frame].size.height);
                    allDayViewSize = [_allDayHeightSplitViewToBlotterWindowTransform transformSize:allDayViewSize];
                    [defaults setFloat:floorf(allDayViewSize.height) forKey:@"AllDayViewHeight"];
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
        return roundf(aProposedPosition / 10.0f) * 10.0f;
    else
        return aProposedPosition;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMinCoordinate:(CGFloat)aProposedMinimumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (aSplitView == _infoWidthSplitView)
    {
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"] == BLNarrowSize)
            return [aSplitView bounds].size.width;
        else
            return 0;
    }
    else
        return aProposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)aProposedMaximumPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if (aSplitView == _infoWidthSplitView)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        CGFloat splitViewWidth = [aSplitView bounds].size.width;
        if ([defaults integerForKey:@"CalendarSize"] == BLNarrowSize)
            return splitViewWidth - [aSplitView dividerThickness];
        else
        {
            NSSize minWeekViewSize = NSMakeSize([defaults floatForKey:@"MinimumWeekViewWidth"], 0.0f);
            minWeekViewSize = [_blotterWindowToInfoWidthSplitViewTransform transformSize:minWeekViewSize];
            return splitViewWidth - [aSplitView dividerThickness] - minWeekViewSize.width;
        }
    }
    else
        return aProposedMaximumPosition;
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aSubview
{
    return (aSubview == _allDayHeightSplitView);
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"CalendarLayout"])
    {
        if ([[aChange objectForKey:NSKeyValueChangeNewKey] integerValue] == WLCalendarNormalLayout)
        {
            _areSplitViewsBeenResettingToDefault = YES;
            NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
            NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithContentsOfURL:defaultsURL];
            DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
            [defaults setObject:[NSNumber numberWithFloat:[delegate.calendarWindowController defaultTasksViewHeight]]
                         forKey:@"TasksViewHeight"];
            [self layoutSplitViewWithParameters:defaults];
            _areSplitViewsBeenResettingToDefault = NO;
        }
    }
    else if ([aKeyPath isEqualToString:@"ScreenIdentifier"])
        [self updatePreferredFrameSizeOfPaneView];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

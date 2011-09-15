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
    [super dealloc];
}


#pragma mark Methods

- (IBAction)restoreDefaults:(NSButton *)aButton
{
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithContentsOfURL:defaultsURL];
    DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
    [defaults setObject:[NSNumber numberWithFloat:[delegate.windowController defaultTasksViewHeight]]
                 forKey:@"TasksViewHeight"];
    [self layoutSplitViewWithParameters:defaults];
}

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

- (void)transformsDidChanged
{
    _splitViewsDidResizeSubviewsManually = YES;
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
    NSRect blotterViewFrame = [[delegate.windowController.window contentView] frame];
    // All split views have the same divider thickness.
    CGFloat dividerThickness = [_infoWidthSplitView dividerThickness];
    // _infoWidthSplitViewa and _allDayHeightSplitView have only 1 divider.
    // _dateHeightSplitView and _tasksHeightSplitView has 2 dividers.
    [_blotterWindowToInfoWidthSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - dividerThickness) / NSWidth(blotterViewFrame)
                                                 yBy:(NSHeight(layoutViewFrame) - dividerThickness) / NSHeight(blotterViewFrame)];
    [_infoWidthSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - dividerThickness)
                                                 yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - dividerThickness)];
    
    [_blotterWindowToTasksHeightSplitViewTransform scaleXBy:(NSWidth(layoutViewFrame) - 2 * dividerThickness) / NSWidth(blotterViewFrame)
                                                             yBy:(NSHeight(layoutViewFrame) - 2 * dividerThickness) / NSHeight(blotterViewFrame)];
    [_tasksHeightSplitViewToBlotterWindowTransform scaleXBy:NSWidth(blotterViewFrame) / (NSWidth(layoutViewFrame) - 2 * dividerThickness)
                                                             yBy:NSHeight(blotterViewFrame) / (NSHeight(layoutViewFrame) - 2 * dividerThickness)];
    [self layoutSplitViewWithParameters:[NSUserDefaults standardUserDefaults]];
    _splitViewsDidResizeSubviewsManually = NO;
}


#pragma mark SS_PreferencePaneProtocol

- (NSView *)paneView
{
    if (!_isViewLoaded)
    {
        if ([NSBundle loadNibNamed:@"LayoutPrefPaneView" owner:self])
        {
            [self transformsDidChanged];
            DeskboardAppDelegate *delegate = (DeskboardAppDelegate *)[[NSApplication sharedApplication] delegate];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(transformsDidChanged)
                                                         name:NSWindowDidResizeNotification
                                                       object:delegate.windowController.window];
            _isViewLoaded = YES;
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
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
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
    if (_splitViewsDidResizeSubviewsManually)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSSplitView *splitView = [aNotification object];
    if (splitView == _infoWidthSplitView)
    {
        NSSize infoViewsSize = NSMakeSize([_dateHeightSplitView frame].size.width, 0.0f);
        infoViewsSize = [_infoWidthSplitViewToBlotterWindowTransform transformSize:infoViewsSize];
        [[NSUserDefaults standardUserDefaults] setFloat:infoViewsSize.width forKey:@"InfoViewsWidth"];
    }
    else
    {
        for (NSView *v in [[aNotification object] subviews])
        {
            switch ([v tag]) {
                case WLLayoutDateViewTag: {
                    NSSize dateViewSize = NSMakeSize(0.0f, [v frame].size.height);
                    dateViewSize = [_dateHeightSplitViewToBlotterWindowTransform transformSize:dateViewSize];
                    [defaults setFloat:dateViewSize.height forKey:@"DateViewHeight"];
                    break;
                }
                case WLLayoutTasksViewTag: {
                    NSSize tasksViewSize = NSMakeSize(0.0f, [v frame].size.height);
                    tasksViewSize = [_tasksHeightSplitViewToBlotterWindowTransform transformSize:tasksViewSize];
                    [defaults setFloat:tasksViewSize.height forKey:@"TasksViewHeight"];
                    break;
                }
                case WLLayoutAllDayViewTag: {
                    NSSize allDayViewSize = NSMakeSize(0.0f, [v frame].size.height);
                    allDayViewSize = [_allDayHeightSplitViewToBlotterWindowTransform transformSize:allDayViewSize];
                    [defaults setFloat:allDayViewSize.height forKey:@"AllDayViewHeight"];
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

@end

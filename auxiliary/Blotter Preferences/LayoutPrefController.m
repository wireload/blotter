//
//  LayoutPrefController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "LayoutPrefController.h"
#import "WLLayoutRootView.h"


@implementation LayoutPrefController

#pragma mark Methods

- (IBAction)restoreDefaults:(NSButton *)aButton
{
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
    [self layoutSplitViewWithParameters:defaults];
}

- (void)layoutSplitViewWithParameters:(id)aParameters
{
    CGFloat infoViewsWidth = [[aParameters objectForKey:@"InfoViewsWidth"] floatValue];
    [_mainSplitView setPosition:([_mainSplitView frame].size.width - [_mainSplitView dividerThickness]) * infoViewsWidth ofDividerAtIndex:0];

    CGFloat dateViewHeight = [[aParameters objectForKey:@"DateViewHeight"] floatValue];
    [_infoSplitView setPosition:([_infoSplitView frame].size.height - [_infoSplitView dividerThickness]) * dateViewHeight ofDividerAtIndex:0];

    CGFloat tasksViewHeight = [[aParameters objectForKey:@"TasksViewHeight"] floatValue];
    [_tasksAndRightNowSplitView setPosition:([_tasksAndRightNowSplitView frame].size.height - [_tasksAndRightNowSplitView dividerThickness]) * tasksViewHeight
                           ofDividerAtIndex:0];
    CGFloat allDayViewHeight = [[aParameters objectForKey:@"AllDayViewHeight"] floatValue];
    [_weekSplitView setPosition:([_weekSplitView frame].size.height - [_weekSplitView dividerThickness]) * allDayViewHeight ofDividerAtIndex:0];
}


#pragma mark SS_PreferencePaneProtocol

- (NSView *)paneView
{
    if (!_isViewLoaded)
    {
        if ([NSBundle loadNibNamed:@"LayoutPrefPaneView" owner:self])
        {
            [self layoutSplitViewWithParameters:[NSUserDefaults standardUserDefaults]];
            // It's importatnt to set _isViewLoaded after lay out split views. Otherwise preferences will be damaged.
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
    if (!_isViewLoaded)
        return;

    NSSplitView *splitView = [aNotification object];
    if (splitView == _mainSplitView)
    {
        CGFloat width = [splitView frame].size.width - [splitView dividerThickness];
        [[NSUserDefaults standardUserDefaults] setFloat:[_infoSplitView frame].size.width / width forKey:@"InfoViewsWidth"];
    }
    else
    {
        for (NSView *v in [[aNotification object] subviews])
        {
            CGFloat height = [splitView frame].size.height - [splitView dividerThickness];
            switch ([v tag]) {
                case WLLayoutDateViewTag:
                    NSLog(@"%f", [v frame].size.height / height);
                    [[NSUserDefaults standardUserDefaults] setFloat:[v frame].size.height / height forKey:@"DateViewHeight"];
                    break;
                case WLLayoutTasksViewTag:
                    NSLog(@"%f", [v frame].size.height / height);
                    [[NSUserDefaults standardUserDefaults] setFloat:[v frame].size.height / height forKey:@"TasksViewHeight"];
                    break;
                case WLLayoutAllDayViewTag:
                    [[NSUserDefaults standardUserDefaults] setFloat:[v frame].size.height / height forKey:@"AllDayViewHeight"];
                    break;
                default:
                    break;
            }
        }
    }
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(CGFloat)aProposedPosition ofSubviewAt:(NSInteger)aDividerIndex
{
    if ([NSEvent modifierFlags] & NSAlternateKeyMask)
        return roundf(aProposedPosition / 10.0f) * 10.0f;
    else
        return aProposedPosition;
}

@end

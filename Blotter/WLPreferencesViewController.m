//
//  WLPreferencesViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 12/13/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>

#import "WLPreferencesViewController.h"


@implementation WLPreferencesViewController
{
    NSTabViewItem *_tabViewItem;
}

- (NSTabViewItem *)tabViewItem
{
    if (_tabViewItem == nil)
        _tabViewItem = [self makeTabViewItem];

    return _tabViewItem;
}

- (NSTabViewItem *)makeTabViewItem
{
    return [NSTabViewItem tabViewItemWithViewController:self];
}

- (void)viewControllerWillTransitionIn
{
}

- (void)viewControllerDidTransitionIn
{
}

- (void)viewControllerWillTransitionOut
{
}

- (void)viewControllerDidransitionOut
{
}

#pragma mark NSViewController

- (void)viewDidDisappear
{
    [super viewDidDisappear];
    [NSNotificationCenter.defaultCenter postNotificationName:WLAnimationShouldCancelNotification
                                                      object:self];
}

@end

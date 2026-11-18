//
//  WLPreferencesViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 7/30/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

#import "WLPreferencesTabViewController.h"


WLPreferencesIdentifier const WLGeneralPreferencesIdentifier = @"WLGeneralPreferences";
WLPreferencesIdentifier const WLShortcutsPreferencesIdentifier = @"WLShortcutsPreferences";
WLPreferencesIdentifier const WLPositioningPreferencesIdentifier = @"WLPositioningPreferences";
WLPreferencesIdentifier const WLLayoutPreferencesIdentifier = @"WLLayoutPreferences";
WLPreferencesIdentifier const WLCalendarsPreferencesIdentifier = @"WLCalendarsPreferences";
WLPreferencesIdentifier const WLAboutPreferencesIdentifier = @"WLAboutPreferences";


const NSViewControllerTransitionOptions WLViewControllerTransitionResize = 0x2000;


@implementation WLPreferencesTabViewController
{
    NSLayoutConstraint *_tabViewWidthAnimationConstraint;
    NSLayoutConstraint *_tabViewHeightAnimationConstraint;
    WLAnimationSequence *_runningTransitionAnimation;
}

#pragma mark Properties

- (WLPreferencesIdentifier)selectedPreferencesIdentifier
{
    NSParameterAssert(self.isViewLoaded);
    return self.tabViewItems[(NSUInteger)self.selectedTabViewItemIndex].identifier;
}

- (void)setSelectedPreferencesIdentifier:(WLPreferencesIdentifier)newSelectedPreferencesIdentifier
{
    NSParameterAssert(self.isViewLoaded);

    if (!newSelectedPreferencesIdentifier)
        newSelectedPreferencesIdentifier = WLGeneralPreferencesIdentifier;

    NSUInteger newSelectedIndex = [self.tabViewItems indexOfObjectPassingTest:^BOOL(NSTabViewItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.identifier isEqual:newSelectedPreferencesIdentifier];
    }];
    NSAssert(newSelectedIndex != NSNotFound, @"unexpected preferences identifier \"%@\"", newSelectedPreferencesIdentifier);
    self.selectedTabViewItemIndex = (NSInteger)newSelectedIndex;
}

#pragma mark NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)aToolbar
{
    // Insert flexible space just before the About item
    NSMutableArray<NSToolbarItemIdentifier> *identifiers = [[super toolbarDefaultItemIdentifiers:aToolbar] mutableCopy];
    [identifiers insertObject:NSToolbarFlexibleSpaceItemIdentifier atIndex:identifiers.count - 1];
    return identifiers.copy;
}

#pragma mark NSTabViewDelegate

- (BOOL)tabView:(NSTabView *)aTabView shouldSelectTabViewItem:(NSTabViewItem *)aTabViewItem
{
    return [super tabView:aTabView shouldSelectTabViewItem:aTabViewItem] && !_runningTransitionAnimation;
}

#pragma mark NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self willChangeValueForKey:@"generalController"];
    _generalController = [WLGeneralPreferencesViewController new];
    _generalController.tabViewItem.identifier = WLGeneralPreferencesIdentifier;
    [self addTabViewItem:_generalController.tabViewItem];
    [self didChangeValueForKey:@"generalController"];

    [self willChangeValueForKey:@"shortcutsController"];
    _shortcutsController = [WLShortcutsPreferencesViewController new];
    _shortcutsController.tabViewItem.identifier = WLShortcutsPreferencesIdentifier;
    [self addTabViewItem:_shortcutsController.tabViewItem];
    [self didChangeValueForKey:@"shortcutsController"];

    [self willChangeValueForKey:@"positioningController"];
    _positioningController = [WLPositioningPreferencesViewController new];
    _positioningController.tabViewItem.identifier = WLPositioningPreferencesIdentifier;
    [self addTabViewItem:_positioningController.tabViewItem];
    [self didChangeValueForKey:@"positioningController"];

    [self willChangeValueForKey:@"layoutController"];
    _layoutController = [WLLayoutPreferencesViewController new];
    _layoutController.tabViewItem.identifier = WLLayoutPreferencesIdentifier;
    [self addTabViewItem:_layoutController.tabViewItem];
    [self didChangeValueForKey:@"layoutController"];

    [self willChangeValueForKey:@"calendarsController"];
    _calendarsController = [WLCalendarsPreferencesViewController new];
    _calendarsController.tabViewItem.identifier = WLCalendarsPreferencesIdentifier;
    [self addTabViewItem:_calendarsController.tabViewItem];
    [self didChangeValueForKey:@"calendarsController"];

    [self willChangeValueForKey:@"aboutController"];
    _aboutController = [WLAboutPreferencesViewController new];
    _aboutController.tabViewItem.identifier = WLAboutPreferencesIdentifier;
    [self addTabViewItem:_aboutController.tabViewItem];
    [self didChangeValueForKey:@"aboutController"];

    _tabViewWidthAnimationConstraint = [self.tabView.widthAnchor constraintEqualToConstant:0.0];
    _tabViewWidthAnimationConstraint.priority = NSLayoutPriorityRequired;
    _tabViewWidthAnimationConstraint.identifier = @"WLPreferencesTabViewControllerWidth";

    _tabViewHeightAnimationConstraint = [self.tabView.heightAnchor constraintEqualToConstant:0.0];
    _tabViewHeightAnimationConstraint.priority = NSLayoutPriorityRequired;
    _tabViewHeightAnimationConstraint.identifier = @"WLPreferencesTabViewControllerHeight";
}

- (void)viewDidDisappear
{
    [super viewDidDisappear];
    [_runningTransitionAnimation cancel];
}

- (void)transitionFromViewController:(WLPreferencesViewController *)aFromViewController
                    toViewController:(WLPreferencesViewController *)aToViewController
                             options:(NSViewControllerTransitionOptions)anOptions
                   completionHandler:(void (^)(void))aCompletion
{
    if (anOptions != WLViewControllerTransitionResize)
    {
        [super transitionFromViewController:aFromViewController
                           toViewController:aToViewController
                                    options:anOptions
                          completionHandler:aCompletion];
        return;
    }

    [_runningTransitionAnimation cancel];

    [aToViewController viewControllerWillTransitionIn];
    [aFromViewController viewControllerWillTransitionOut];

    NSView *fromView = aFromViewController.view;
    NSView *contentView = fromView.superview;
    NSWindow *window = contentView.window;
    NSView *toView = aToViewController.view;
    NSSize toViewSize = toView.fittingSize;

    NSTimeInterval fadeOutAnimationDuration = 0.1;
    NSTimeInterval fadeInAnimationDuration = fadeOutAnimationDuration;

    if (@available(macOS 10.12, *))
    {
        if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion)
            fadeOutAnimationDuration = fadeInAnimationDuration = 0.0;
    }

    WLAnimationScene *fadeOutScene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence *aSequence) {
        fromView.animator.alphaValue = 0.0;
    }];
    fadeOutScene.completionHandler = ^(WLAnimationSequence *aSequence) {
        [fromView removeFromSuperview];
    };
    fadeOutScene.defaultDuration = @(fadeOutAnimationDuration);
    fadeOutScene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fadeOutScene.identifier = @"WLPreferencesTabViewControllerFadeOutAnimationScene";

    WLAnimationScene *resizeScene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence *aSequence) {
        self->_tabViewWidthAnimationConstraint.animator.constant = toViewSize.width;
        self->_tabViewHeightAnimationConstraint.animator.constant = toViewSize.height;
    }];
    resizeScene.preparationHandler = ^(WLAnimationSequence *aSequence) {
        self->_tabViewWidthAnimationConstraint.constant = contentView.frame.size.width;
        self->_tabViewHeightAnimationConstraint.constant = contentView.frame.size.height;
        [NSLayoutConstraint activateConstraints:@[
            self->_tabViewWidthAnimationConstraint,
            self->_tabViewHeightAnimationConstraint
        ]];
        window.movable = NO;
    };
    resizeScene.completionHandler = ^(WLAnimationSequence *aSequence) {
        window.movable = YES;
        [aFromViewController viewControllerDidransitionOut];
    };
    resizeScene.durationHandler = ^NSTimeInterval {
        return [window WL_animationResizeTimeForView:contentView newFrameSize:toViewSize];
    };
    resizeScene.identifier = @"WLPreferencesTabViewControllerResizeAnimationScene";

    WLAnimationScene *fadeInScene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence *aSequence) {
        toView.animator.alphaValue = 1.0;
    }];
    fadeInScene.preparationHandler = ^(WLAnimationSequence *aSequence) {
        toView.alphaValue = 0.0;

        // toView layout may have changed during the animation making custom constraints conflicting.
        // Trust the view to control its final size.
        // The downside is a possibility of a "jump" before the fade in.
        [NSLayoutConstraint deactivateConstraints:@[
            self->_tabViewWidthAnimationConstraint,
            self->_tabViewHeightAnimationConstraint
        ]];

        [contentView addSubview:toView];
    };
    fadeInScene.completionHandler = ^(WLAnimationSequence *aSequence) {
        [aToViewController viewControllerDidTransitionIn];
    };
    fadeInScene.defaultDuration = @(fadeInAnimationDuration);
    fadeInScene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fadeInScene.identifier = @"WLPreferencesTabViewControllerFadeInAnimationScene";

    WLAnimationSequence *nextAnimation = [WLAnimationSequence new];
    [nextAnimation.mutableScenes addObjectsFromArray:@[
        fadeOutScene,
        resizeScene,
        fadeInScene
    ]];

    WLAnimationSequence *previousAnimation = _runningTransitionAnimation;
    _runningTransitionAnimation = nextAnimation;
    [_runningTransitionAnimation runAfter:previousAnimation withCompletion:^(WLAnimationSequence *aSequence) {
        if (self->_runningTransitionAnimation == aSequence)
            self->_runningTransitionAnimation = nil;

        if (aCompletion)
            aCompletion();
    }];
}

@end

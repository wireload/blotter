//
//  WLPositioningPreferencesViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 11/8/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import "WLPositioningPreferencesViewController.h"
#import "WLPreferencesTabViewController.h"
#import "DeskboardAppDelegate.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


static NSUserInterfaceItemIdentifier const _WLWindowResizeSceneIdentifier = @"WLPositioningPreferencesWindowResizeScene";

static NSUserInterfaceItemIdentifier const _WLMockupResizeSceneIdentifier = @"WLPositioningPreferencesMockupResizeScene";

static NSUserInterfaceItemIdentifier const _WLEditingModeSceneIdentifier = @"WLPositioningPreferencesEditingModeScene";

static NSUserInterfaceItemIdentifier const _WLPositioningPreferencesControllerSequence = @"WLPositioningPreferencesControllerSequence";

static void *_WLCalendarWindowArrangementDidChangeContext = &_WLCalendarWindowArrangementDidChangeContext;


@implementation WLPositioningPreferencesViewController
{
    BOOL _isViewAppeared;
    WLAnimationSequence *_runningAnimation;
}

- (void)dealloc
{
    if (_isViewAppeared)
    {
        __auto_type defaults = NSUserDefaults.standardUserDefaults;
        [defaults removeObserver:self forKeyPath:WLCalendarSizeKey];
        [defaults removeObserver:self forKeyPath:WLCalendarPositionKey];
        [defaults removeObserver:self forKeyPath:WLCustomFrameFactorsKey];
        [defaults removeObserver:self forKeyPath:WLScreenUUIDKey];
    }

    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Methods

- (void)updateArrangementView:(BOOL)anIsAnimated
{
    NSParameterAssert(self.isViewLoaded);

    if (anIsAnimated)
    {
        __auto_type mockupResizeScene = [self animateMockupResize];
        __auto_type editingModeScene = [self animateEditingMode];
        __auto_type windowResizeScene = [self animateWindowResize];

        NSArray<WLAnimationScene *> *scenes = nil;

        switch (self.arrangementView.editingMode)
        {
            case WLWindowArrangementModePositioning:
                scenes = @[
                    windowResizeScene,
                    mockupResizeScene,
                    editingModeScene
                ];
                break;
            case WLWindowArrangementModeResizing:
                scenes = @[
                    editingModeScene,
                    mockupResizeScene,
                    windowResizeScene
                ];
                break;
        }

        if (_runningAnimation == nil)
        {
            __auto_type animation = [WLAnimationSequence new];
            animation.identifier = _WLPositioningPreferencesControllerSequence;
            [animation.mutableScenes addObjectsFromArray:scenes];

            _runningAnimation = animation;
            [_runningAnimation runWithCompletion:^(WLAnimationSequence *aSequence) {
                if (self->_runningAnimation == aSequence)
                    self->_runningAnimation = nil;
            }];
        }
        else
        {
            for (WLAnimationScene *scene in scenes)
            {
                __auto_type runningScene = [_runningAnimation sceneWithIdentifier:scene.identifier];

                if (runningScene)
                    [runningScene applyScene:scene];
                else
                    [_runningAnimation.mutableScenes addObject:scene];
            }
        }
    }
    else
    {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

        NSSize preferredArrangementViewSize = self.preferredArrangementViewSize;
        self.arrangementViewWidthConstraint.constant = preferredArrangementViewSize.width;
        self.arrangementViewHeightConstraint.constant = preferredArrangementViewSize.height;

        __auto_type editingMode = defaults.WL_calendarSize == BLCustomSize ? WLWindowArrangementModeResizing : WLWindowArrangementModePositioning;
        self.arrangementView.editingMode = editingMode;

        WLCalendarWindowController *windowController = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
        NSRect screenFrame = windowController.windowScreen.visibleFrame;
        NSSize minSize = windowController.minimumSize;
        minSize = NSMakeSize(minSize.width / NSWidth(screenFrame), minSize.height / NSHeight(screenFrame));
        self.arrangementView.mockupMinFrameSizeRatios = minSize;

        NSRect frameRatios = defaults.WL_customFrameFactors;
        frameRatios.origin.y = 1.0 - NSMaxY(frameRatios); // flip the coordinate from bottom-left origin (screen) to top-left (arrangement view)
        self.arrangementView.mockupFrameRatios = frameRatios;
    }
}

- (void)calendarWindowArrangementDidChange
{
    [self updateArrangementView:_isViewAppeared];
}

#pragma mark Animation

- (NSSize)preferredArrangementViewSize
{
    static const CGFloat ArrangementViewWidth = 400.0;

    WLCalendarWindowController *windowController = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
    NSRect screenFrame = windowController.windowScreen.visibleFrame;
    CGFloat screenAspectRatio = NSHeight(screenFrame) > 0.0 ? NSWidth(screenFrame) / NSHeight(screenFrame) : 16.0 / 10.0;
    NSSize preferredSize = NSMakeSize(ArrangementViewWidth, ArrangementViewWidth / screenAspectRatio);

    __auto_type editingMode = NSUserDefaults.standardUserDefaults.WL_calendarSize == BLCustomSize ? WLWindowArrangementModeResizing : WLWindowArrangementModePositioning;

    if (editingMode == WLWindowArrangementModeResizing)
    {
        preferredSize.width *= 2.0;
        preferredSize.height *= 2.0;
    }

    return [self.arrangementView drawingAlignedFrameSize:preferredSize forEditingMode:editingMode];
}

- (NSRect)mockupFrameRatiosForPosition:(BLPosition)aPosition size:(BLSize)aSize onScreen:(NSScreen *)aScreen
{
    DeskboardAppDelegate *appDelegate = (DeskboardAppDelegate *)NSApp.delegate;
    NSRect windowFrameOnScreen = [appDelegate.calendarWindowController windowFrameOnScreen:aScreen
                                                                              withPosition:aPosition
                                                                                      size:aSize];
    NSRect screenBounds = aScreen.visibleFrame;

    if (!NSContainsRect(screenBounds, windowFrameOnScreen))
    {
        // TODO: log error
    }

    NSRect frameRatios = NSMakeRect(fdim(NSMinX(windowFrameOnScreen), NSMinX(screenBounds)) / NSWidth(screenBounds),
                                    fdim(NSMinY(windowFrameOnScreen), NSMinY(screenBounds)) / NSHeight(screenBounds),
                                    NSWidth(windowFrameOnScreen) / NSWidth(screenBounds),
                                    NSHeight(windowFrameOnScreen) / NSHeight(screenBounds));
    frameRatios.origin.y = 1.0 - NSMaxY(frameRatios); // flip the coordinate from bottom-left origin (screen) to top-left (arrangement view)
    return frameRatios;
}

- (WLAnimationScene *)animateWindowResize
{
    NSSize newArrangementViewSize = [self preferredArrangementViewSize];

    __auto_type resizeScene = [WLAnimationScene sceneWithChanges:^(WLAnimationSequence *aSequence) {
        if (self.arrangementViewWidthConstraint.constant != newArrangementViewSize.width)
            self.arrangementViewWidthConstraint.animator.constant = newArrangementViewSize.width;

        if (self.arrangementViewHeightConstraint.constant != newArrangementViewSize.height)
            self.arrangementViewHeightConstraint.animator.constant = newArrangementViewSize.height;
    }];
    resizeScene.durationHandler = ^{
        NSParameterAssert(self.isViewLoaded);
        NSWindow *w = self.arrangementView.window;
        return [w WL_animationResizeTimeForView:self.arrangementView newFrameSize:newArrangementViewSize];
    };
    resizeScene.preparationHandler = ^(WLAnimationSequence *aSequence) {
        self.view.window.movable = NO;
    };
    resizeScene.cancellationHandler = ^(WLAnimationSequence *aSequence) {
        if (aSequence.stateReason == WLAnimationStateReasonFreezeAppearance)
        {
            // View is about to disappear: retain current size to avoid further UI updates.
            self.arrangementViewWidthConstraint.constant = self.arrangementViewWidthConstraint.constant;
            self.arrangementViewHeightConstraint.constant = self.arrangementViewHeightConstraint.constant;
        }
        else
        {
            self.arrangementViewWidthConstraint.constant = newArrangementViewSize.width;
            self.arrangementViewHeightConstraint.constant = newArrangementViewSize.height;
        }
    };
    resizeScene.completionHandler = ^(WLAnimationSequence *aSequence) {
        self.view.window.movable = YES;
        [self.arrangementView layoutSubtreeIfNeeded];
    };
    resizeScene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    resizeScene.identifier = _WLWindowResizeSceneIdentifier;
    return resizeScene;
}

- (WLAnimationScene *)animateMockupResize
{
    WLCalendarWindowController *windowController = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
    NSRect screenFrame = windowController.windowScreen.visibleFrame;
    NSSize minSize = windowController.minimumSize;
    minSize = NSMakeSize(minSize.width / NSWidth(screenFrame), minSize.height / NSHeight(screenFrame));

    NSRect frameRatios = NSUserDefaults.standardUserDefaults.WL_customFrameFactors;
    frameRatios.origin.y = 1.0 - NSMaxY(frameRatios);

    __auto_type scene = [_arrangementView animateFrameRatios:frameRatios minFrameSizeRatios:minSize];
    scene.identifier = _WLMockupResizeSceneIdentifier;
    return scene;
}

- (WLAnimationScene *)animateEditingMode
{
    __auto_type editingMode = NSUserDefaults.standardUserDefaults.WL_calendarSize == BLCustomSize ? WLWindowArrangementModeResizing : WLWindowArrangementModePositioning;
    __auto_type scene = [self.arrangementView animateEditingMode:editingMode];
    scene.identifier = _WLEditingModeSceneIdentifier;
    return scene;
}

#pragma mark WLWindowArrangementDelegate

- (NSRect)windowArrangement:(WLWindowArrangementView *)anArrangement didChangeMockupFrameRatios:(NSRect)newFrameRatios
{
    newFrameRatios.origin.y = 1.0 - NSMaxY(newFrameRatios); // flip the coordinate from top-left (arrangement view) to bottom-left origin (screen)
    NSUserDefaults.standardUserDefaults.WL_customFrameFactors = newFrameRatios;
    newFrameRatios.origin.y = 1.0 - NSMaxY(newFrameRatios); // restore the origin to top-left
    return newFrameRatios;
}

- (NSRect)windowArrangement:(WLWindowArrangementView *)anArrangement didChangeMockupPosition:(BLPosition)aPosition
{
    DeskboardAppDelegate *appDelegate = (DeskboardAppDelegate *)NSApp.delegate;
    NSScreen *screen = appDelegate.calendarWindowController.windowScreen;
    NSUserDefaults.standardUserDefaults.WL_calendarPosition = aPosition;
    return [self mockupFrameRatiosForPosition:aPosition
                                         size:NSUserDefaults.standardUserDefaults.WL_calendarSize
                                     onScreen:screen];
}

- (BOOL)windowArrangement:(WLWindowArrangementView *)anArrangement shouldAnimate:(WLWindowArrangementAnimation)anAnimation
{
    return _isViewAppeared;
}

#pragma mark WLPreferencesViewController

- (NSTabViewItem *)makeTabViewItem
{
    NSTabViewItem *t = [super makeTabViewItem];
    t.image = [NSImage imageNamed:@"preferences-positioning-icon"];
    t.label = NSLocalizedString(@"Positioning", @"Positioning preferences pane title");
    t.toolTip = NSLocalizedString(@"Position and Size Preferences", @"Positioning preferences pane tooltip");
    return t;
}

- (void)viewControllerWillTransitionIn
{
    [super viewControllerWillTransitionIn];
    [self calendarWindowArrangementDidChange];
}

- (void)viewControllerWillTransitionOut
{
    [_runningAnimation abortWithReason:WLAnimationStateReasonFreezeAppearance];
    [super viewControllerWillTransitionOut];
}

#pragma mark NSViewController

- (void)viewWillAppear
{
    [super viewWillAppear];

    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    [defaults addObserver:self
               forKeyPath:WLCalendarSizeKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                  context:_WLCalendarWindowArrangementDidChangeContext];
    [defaults addObserver:self
               forKeyPath:WLCalendarPositionKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:_WLCalendarWindowArrangementDidChangeContext];
    [defaults addObserver:self
               forKeyPath:WLCustomFrameFactorsKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:_WLCalendarWindowArrangementDidChangeContext];
    [defaults addObserver:self
               forKeyPath:WLScreenUUIDKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:_WLCalendarWindowArrangementDidChangeContext];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(calendarWindowArrangementDidChange)
                                               name:NSApplicationDidChangeScreenParametersNotification
                                             object:NSApp];

    _isViewAppeared = YES;

    [self calendarWindowArrangementDidChange];
}

- (void)viewDidDisappear
{
    _isViewAppeared = NO;
    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:WLCalendarSizeKey];
    [defaults removeObserver:self forKeyPath:WLCalendarPositionKey];
    [defaults removeObserver:self forKeyPath:WLCustomFrameFactorsKey];
    [defaults removeObserver:self forKeyPath:WLScreenUUIDKey];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_runningAnimation abortWithReason:WLAnimationStateReasonFreezeAppearance];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if (aContext == _WLCalendarWindowArrangementDidChangeContext)
    {
        if (![aChange[NSKeyValueChangeOldKey] isEqual:aChange[NSKeyValueChangeNewKey]])
        {
            __auto_type defaults = NSUserDefaults.standardUserDefaults;
            __auto_type size = defaults.WL_calendarSize;

            if (size != BLCustomSize && [@[WLScreenUUIDKey, WLCalendarPositionKey, WLCalendarSizeKey] containsObject:aKeyPath])
            {
                // Keep custom frame ratios on par with currently selected size and position
                // so that relative position of the mockup will be preserved when size is changed to BLCustomSize.
                __auto_type position = defaults.WL_calendarPosition;
                DeskboardAppDelegate *appDelegate = (DeskboardAppDelegate *)NSApp.delegate;
                NSScreen *screen = appDelegate.calendarWindowController.windowScreen;
                NSRect frameRatios = [self mockupFrameRatiosForPosition:position
                                                                   size:size
                                                               onScreen:screen];
                frameRatios.origin.y = 1.0 - NSMaxY(frameRatios); // flip the coordinate from top-left (arrangement view) to bottom-left origin (screen)

                defaults.WL_customFrameFactors = frameRatios;
            }
            else if (size == BLCustomSize && [aKeyPath isEqualToString:WLCustomFrameFactorsKey])
            {
                // Pick the best calendar position for current frame ratios.
                // Scores are assigned to all possible positions based on the area common with current frame ratios.
                // Non-center positions are prioritized such that the corner positions and the central position
                // have the highest and the lowest position correspondingly.
                NSRect frameRatios = defaults.WL_customFrameFactors;

                BLPosition matchingPosition = BLPositionCenterCenter;
                CGFloat bestScore = 0.0;
                CGFloat scoreMultiplier = 1.0;

                for (BLPosition position = 0; position < BLPositionCount; ++position)
                {
                    NSRect positionRatios = NSMakeRect(0.0, 0.0, 1.0 / 3.0, 1.0 / 3.0);

                    switch (position)
                    {
                        case BLPositionTopLeft:
                        case BLPositionCenterLeft:
                        case BLPositionBottomLeft:
                            positionRatios.origin.x = 0.0;
                            scoreMultiplier += 0.1;
                            break;

                        case BLPositionTopCenter:
                        case BLPositionCenterCenter:
                        case BLPositionBottomCenter:
                            positionRatios.origin.x = 1.0 / 3.0;
                            break;

                        case BLPositionTopRight:
                        case BLPositionCenterRight:
                        case BLPositionBottomRight:
                            positionRatios.origin.x = 2.0 / 3.0;
                            scoreMultiplier += 0.1;
                            break;
                    }

                    switch (position)
                    {
                        case BLPositionTopLeft:
                        case BLPositionTopCenter:
                        case BLPositionTopRight:
                            positionRatios.origin.y = 2.0 / 3.0;
                            scoreMultiplier += 0.1;
                            break;

                        case BLPositionCenterLeft:
                        case BLPositionCenterCenter:
                        case BLPositionCenterRight:
                            positionRatios.origin.y = 1.0 / 3.0;
                            break;

                        case BLPositionBottomLeft:
                        case BLPositionBottomCenter:
                        case BLPositionBottomRight:
                            positionRatios.origin.y = 0.0;
                            scoreMultiplier += 0.1;
                            break;
                    }

                    NSRect intersection = NSIntersectionRect(frameRatios, positionRatios);
                    CGFloat score = NSWidth(intersection) * NSHeight(intersection);

                    if (NSEqualRects(intersection, positionRatios))
                        score *= scoreMultiplier;

                    if (score > bestScore)
                    {
                        bestScore = score;
                        matchingPosition = position;
                    }
                }

                defaults.WL_calendarPosition = matchingPosition;
            }

            [self calendarWindowArrangementDidChange];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

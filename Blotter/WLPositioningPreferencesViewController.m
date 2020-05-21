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

static void *_WLFrameArrangementDidChangeContext = &_WLFrameArrangementDidChangeContext;


@implementation WLPositioningPreferencesViewController
{
    IBOutlet WLScreensController *_screensController;
    IBOutlet WLFrameArrangementView *_arrangementView;
    IBOutlet NSLayoutConstraint *_arrangementViewWidthConstraint;
    IBOutlet NSLayoutConstraint *_arrangementViewHeightConstraint;

    BOOL _isViewAppeared;
    WLAnimationSequence *_runningAnimation;
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

        switch (_arrangementView.editingMode)
        {
            case WLFrameArrangementModePositioning:
                scenes = @[
                    windowResizeScene,
                    mockupResizeScene,
                    editingModeScene
                ];
                break;
            case WLFrameArrangementModeResizing:
                scenes = @[
                    editingModeScene,
                    mockupResizeScene,
                    windowResizeScene
                ];
                break;
        }

        if (_runningAnimation.state != WLAnimationSequenceStateRunning)
        {
            __auto_type animation = [WLAnimationSequence new];
            animation.identifier = _WLPositioningPreferencesControllerSequence;
            [animation.mutableScenes addObjectsFromArray:scenes];

            __auto_type previousAnimation = _runningAnimation;
            _runningAnimation = animation;
            [_runningAnimation runAfter:previousAnimation withCompletion:^(WLAnimationSequence *aSequence) {
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
                    [runningScene mergeWithScene:scene];
                else
                    [_runningAnimation.mutableScenes addObject:scene];
            }
        }
    }
    else
    {
        [_runningAnimation abort];

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

        NSSize preferredArrangementViewSize = self.preferredArrangementViewSize;
        _arrangementViewWidthConstraint.constant = preferredArrangementViewSize.width;
        _arrangementViewHeightConstraint.constant = preferredArrangementViewSize.height;

        __auto_type editingMode = defaults.WL_calendarSize == BLCustomSize ? WLFrameArrangementModeResizing : WLFrameArrangementModePositioning;
        _arrangementView.editingMode = editingMode;

        __auto_type windowController = WLAppDelegate.calendarWindowController;
        NSRect screenFrame = windowController.windowScreen.visibleFrame;
        NSSize minSize = defaults.WL_minimumWindowSize;
        minSize = NSMakeSize(minSize.width / NSWidth(screenFrame), minSize.height / NSHeight(screenFrame));
        _arrangementView.mockupMinFrameSizeRatios = minSize;

        NSRect frameRatios = defaults.WL_customFrameFactors;
        frameRatios.origin.y = 1.0 - NSMaxY(frameRatios); // flip the coordinate from bottom-left origin (screen) to top-left (arrangement view)
        _arrangementView.mockupFrameRatios = frameRatios;
    }
}

- (void)screensDidChange:(NSNotification *)aNotification
{
    // Attaching new screen causes macOS to freeze and re-render the UI.
    // Animations do not look good under such conditions.
    [self updateArrangementView:NO];
}

#pragma mark Animation

- (NSSize)preferredArrangementViewSize
{
    static const CGFloat ArrangementViewLongestSideLength = 400.0;

    __auto_type windowController = WLAppDelegate.calendarWindowController;
    NSRect screenFrame = windowController.windowScreen.visibleFrame;
    CGFloat screenAspectRatio = NSHeight(screenFrame) > 0.0 ? NSWidth(screenFrame) / NSHeight(screenFrame) : 16.0 / 10.0;

    NSSize preferredSize = NSZeroSize;

    if (screenAspectRatio > 1.0)
    {
        preferredSize.width = ArrangementViewLongestSideLength;
        preferredSize.height = ArrangementViewLongestSideLength / screenAspectRatio;
    }
    else
    {
        preferredSize.width = ArrangementViewLongestSideLength * screenAspectRatio;
        preferredSize.height = ArrangementViewLongestSideLength;
    }

    __auto_type editingMode = NSUserDefaults.standardUserDefaults.WL_calendarSize == BLCustomSize ? WLFrameArrangementModeResizing : WLFrameArrangementModePositioning;

    if (editingMode == WLFrameArrangementModeResizing)
    {
        preferredSize.width *= 2.0;
        preferredSize.height *= 2.0;
    }

    return [_arrangementView drawingAlignedFrameSize:preferredSize forEditingMode:editingMode];
}

- (NSRect)mockupFrameRatiosForPosition:(BLPosition)aPosition size:(BLSize)aSize onScreen:(NSScreen *)aScreen
{
    NSMutableDictionary *preferences = [NSUserDefaults.standardUserDefaults.dictionaryRepresentation mutableCopy];
    preferences[WLCalendarSizeKey] = @(aSize);
    preferences[WLCalendarPositionKey] = @(aPosition);
    NSRect windowFrameOnScreen = [WLCalendarWindowController windowFrameOnScreen:aScreen preferences:preferences];
    NSRect screenBounds = aScreen.visibleFrame;
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
        if (self->_arrangementViewWidthConstraint.constant != newArrangementViewSize.width)
            self->_arrangementViewWidthConstraint.animator.constant = newArrangementViewSize.width;

        if (self->_arrangementViewHeightConstraint.constant != newArrangementViewSize.height)
            self->_arrangementViewHeightConstraint.animator.constant = newArrangementViewSize.height;
    }];
    resizeScene.durationHandler = ^{
        NSParameterAssert(self.isViewLoaded);
        NSWindow *w = self->_arrangementView.window;
        return [w WL_animationResizeTimeForView:self->_arrangementView newFrameSize:newArrangementViewSize];
    };
    resizeScene.preparationHandler = ^(WLAnimationSequence *aSequence) {
        self.view.window.movable = NO;
    };
    resizeScene.cancellationHandler = ^(WLAnimationSequence *aSequence) {
        if (aSequence.stateReason == WLAnimationStateReasonFreezeAppearance)
        {
            // View is about to disappear: retain current size to avoid further UI updates.
            self->_arrangementViewWidthConstraint.constant = self->_arrangementViewWidthConstraint.constant;
            self->_arrangementViewHeightConstraint.constant = self->_arrangementViewHeightConstraint.constant;
        }
        else
        {
            self->_arrangementViewWidthConstraint.constant = newArrangementViewSize.width;
            self->_arrangementViewHeightConstraint.constant = newArrangementViewSize.height;
        }
    };
    resizeScene.completionHandler = ^(WLAnimationSequence *aSequence) {
        self.view.window.movable = YES;
        // Make sure that the view has finalized layout before moving to the next scene.
        [self->_arrangementView layoutSubtreeIfNeeded];
    };
    resizeScene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    resizeScene.identifier = _WLWindowResizeSceneIdentifier;
    return resizeScene;
}

- (WLAnimationScene *)animateMockupResize
{
    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    NSRect screenFrame = WLAppDelegate.calendarWindowController.windowScreen.visibleFrame;
    NSSize minSize = defaults.WL_minimumWindowSize;
    minSize = NSMakeSize(minSize.width / NSWidth(screenFrame), minSize.height / NSHeight(screenFrame));

    NSRect frameRatios = defaults.WL_customFrameFactors;
    frameRatios.origin.y = 1.0 - NSMaxY(frameRatios);

    __auto_type scene = [_arrangementView animateFrameRatios:frameRatios minFrameSizeRatios:minSize];
    scene.identifier = _WLMockupResizeSceneIdentifier;
    return scene;
}

- (WLAnimationScene *)animateEditingMode
{
    __auto_type editingMode = NSUserDefaults.standardUserDefaults.WL_calendarSize == BLCustomSize ? WLFrameArrangementModeResizing : WLFrameArrangementModePositioning;
    __auto_type scene = [_arrangementView animateEditingMode:editingMode];
    scene.identifier = _WLEditingModeSceneIdentifier;
    return scene;
}

#pragma mark WLFrameArrangementDelegate

- (NSRect)frameArrangement:(WLFrameArrangementView *)anArrangement didChangeMockupFrameRatios:(NSRect)newFrameRatios
{
    newFrameRatios.origin.y = 1.0 - NSMaxY(newFrameRatios); // flip the coordinate from top-left (arrangement view) to bottom-left origin (screen)
    NSUserDefaults.standardUserDefaults.WL_customFrameFactors = newFrameRatios;
    newFrameRatios.origin.y = 1.0 - NSMaxY(newFrameRatios); // restore the origin to top-left
    return newFrameRatios;
}

- (NSRect)frameArrangement:(WLFrameArrangementView *)anArrangement didChangeMockupPosition:(BLPosition)aPosition
{
    NSScreen *screen = WLAppDelegate.calendarWindowController.windowScreen;
    NSUserDefaults.standardUserDefaults.WL_calendarPosition = aPosition;
    return [self mockupFrameRatiosForPosition:aPosition
                                         size:NSUserDefaults.standardUserDefaults.WL_calendarSize
                                     onScreen:screen];
}

- (BOOL)frameArrangement:(WLFrameArrangementView *)anArrangement shouldAnimate:(WLFrameArrangementAnimation)anAnimation
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
    [self updateArrangementView:NO];
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
                  context:_WLFrameArrangementDidChangeContext];
    [defaults addObserver:self
               forKeyPath:WLCalendarPositionKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:_WLFrameArrangementDidChangeContext];
    [defaults addObserver:self
               forKeyPath:WLCustomFrameFactorsKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:_WLFrameArrangementDidChangeContext];
    [defaults addObserver:self
               forKeyPath:WLScreenUUIDKey
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:_WLFrameArrangementDidChangeContext];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(screensDidChange:)
                                               name:NSApplicationDidChangeScreenParametersNotification
                                             object:NSApp];

    _isViewAppeared = YES;
}

- (void)viewDidDisappear
{
    _isViewAppeared = NO;

    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:WLCalendarSizeKey];
    [defaults removeObserver:self forKeyPath:WLCalendarPositionKey];
    [defaults removeObserver:self forKeyPath:WLCustomFrameFactorsKey];
    [defaults removeObserver:self forKeyPath:WLScreenUUIDKey];
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSApplicationDidChangeScreenParametersNotification
                                                object:NSApp];

    [_runningAnimation abortWithReason:WLAnimationStateReasonFreezeAppearance];

    [super viewDidDisappear];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if (aContext == _WLFrameArrangementDidChangeContext)
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
                NSScreen *screen = WLAppDelegate.calendarWindowController.windowScreen;
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

            [self updateArrangementView:_isViewAppeared];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

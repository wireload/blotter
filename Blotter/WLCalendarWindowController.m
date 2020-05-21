//
//  WLCalendarWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 3/17/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import <os/trace.h>

#import "WLCalendarWindowController.h"
#import "WLCalendarViewController.h"
#import "WLGraphics.h"
#import "WLScreensController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


static void *_WLScreenObservationContext = &_WLScreenObservationContext;
static void *_WLFrameObservationContext = &_WLFrameObservationContext;

static const NSUserInterfaceItemIdentifier _WLFadeOutAndActivateScene = @"WLFadeOutAndActivate";
static const NSUserInterfaceItemIdentifier _WLFadeOutAndDeactivateScene = @"WLFadeOutAndDeactivate";
static const NSUserInterfaceItemIdentifier _WLPartialFadeInScene = @"WLPartialFadeIn";
static const NSUserInterfaceItemIdentifier _WLFadeInScene = @"WLFadeIn";

static const NSTimeInterval _WLFadeTotalDuration = 0.25; // duration to change alphaValue from 0.0 to 1.0

static const CGFloat _WLFadedAlphaValue = 0.5;


static const NSEdgeInsets _WLShadowInsets = {.top = 6.0, .left = 9.0, .right = 9.0, .bottom = 12.0};
static const NSEdgeInsets _WLBorderInsets = {.top = 3.0, .left = 3.0, .right = 3.0, .bottom = 3.0};
static const NSEdgeInsets _WLLayoutInsets = {.top = 17.0, .left = 17.0, .right = 17.0, .bottom = 17.0};


static const NSSize BLNarrowMinimumSize = {.width = 308.0, .height = 718.0};
static const NSSize BLNormalMinimumSize = {.width = 950.0, .height = 718.0};


@implementation _WLCalendarWindow

- (instancetype)initWithContentRect:(NSRect)aContentRect
                          styleMask:(NSWindowStyleMask)aStyle
                            backing:(NSBackingStoreType)aBackingStoreType
                              defer:(BOOL)aFlag
{
    self = [super initWithContentRect:aContentRect
                            styleMask:aStyle
                              backing:aBackingStoreType
                                defer:aFlag];

    if (self)
    {
        self.hasShadow = NO;
        self.restorable = NO;
        self.hidesOnDeactivate = NO;
        self.releasedWhenClosed = NO;
        self.allowsToolTipsWhenApplicationIsInactive = NO;
        self.autorecalculatesKeyViewLoop = NO;
        if (@available(macOS 10.12, *))
        {
            self.tabbingMode = NSWindowTabbingModeDisallowed;
        }
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorFullScreenNone | NSWindowCollectionBehaviorFullScreenDisallowsTiling;
        self.animationBehavior = NSWindowAnimationBehaviorNone;
        self.ignoresMouseEvents = YES;
        self.canHide = NO;
        self.backgroundColor = NSColor.clearColor;
        self.opaque = NO;
    }

    return self;
}

@end


@implementation WLCalendarWindowController
{
    WLCalendarViewController *_calendarViewController;
    NSView *_activeBackgroundView;
    NSView *_inactiveBackgroundView;

    WLAnimationSequence *_runningAnimation;

    __weak NSLayoutConstraint *_windowWidthConstraint;
    __weak NSLayoutConstraint *_windowHeightConstraint;
}

- (instancetype)initWithWindow:(NSWindow *)aWindow
{
    if (aWindow == nil)
    {
        aWindow = [[_WLCalendarWindow alloc] initWithContentRect:NSZeroRect
                                                       styleMask:NSWindowStyleMaskBorderless
                                                         backing:NSBackingStoreBuffered
                                                           defer:YES];
        aWindow.delegate = self;
    }

    self = [super initWithWindow:aWindow];

    if (self)
    {
        __auto_type defaults = NSUserDefaults.standardUserDefaults;
        [defaults addObserver:self
                   forKeyPath:WLScreenUUIDKey
                      options:NSKeyValueObservingOptionNew
                      context:_WLScreenObservationContext];
        [defaults addObserver:self
                   forKeyPath:WLCalendarSizeKey
                      options:NSKeyValueObservingOptionNew
                      context:_WLFrameObservationContext];
        [defaults addObserver:self
                   forKeyPath:WLCalendarPositionKey
                      options:NSKeyValueObservingOptionNew
                      context:_WLFrameObservationContext];
        [defaults addObserver:self
                   forKeyPath:WLCustomFrameFactorsKey
                      options:NSKeyValueObservingOptionNew
                      context:_WLFrameObservationContext];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(_scheduleWindowScreenDidChange)
                                                   name:NSApplicationDidChangeScreenParametersNotification
                                                 object:NSApp];

        switch (_windowState)
        {
            case WLCalendarWindowStateInactiveFaded:
                [self _deactivate:self.window];
                self.window.alphaValue = _WLFadedAlphaValue;
                break;
            case WLCalendarWindowStateInactive:
                [self _deactivate:self.window];
                break;
            case WLCalendarWindowStateActive:
                [self _activate:self.window];
                break;
        }

        [self windowScreenDidChange];
        [self windowFrameDidChange];
    }

    return self;
}

- (void)dealloc
{
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(windowFrameDidChange) object:nil];
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(windowScreenDidChange) object:nil];

    __auto_type defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:WLScreenUUIDKey context:_WLScreenObservationContext];
    [defaults removeObserver:self forKeyPath:WLCustomFrameFactorsKey context:_WLFrameObservationContext];
    [defaults removeObserver:self forKeyPath:WLCalendarPositionKey context:_WLFrameObservationContext];
    [defaults removeObserver:self forKeyPath:WLCalendarSizeKey context:_WLFrameObservationContext];
}

#pragma mark Properties

+ (BOOL)automaticallyNotifiesObserversOfIsFadedOut
{
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsFadedOut
{
    return [NSSet setWithObject:@"windowState"];
}

- (WLCalendarViewController *)calendarViewController
{
    if (_calendarViewController == nil)
        _calendarViewController = [WLCalendarViewController new];

    return _calendarViewController;
}

- (void)setWindowState:(_WLCalendarWindowState)newState
{
    BOOL isAnimated = NO;

    if (_windowState <= WLCalendarWindowStateInactive && newState <= WLCalendarWindowStateInactive)
        isAnimated = self.window.occlusionState & NSWindowOcclusionStateVisible;
    else
        isAnimated = NSUserDefaults.standardUserDefaults.WL_animatesBringToFront;

    [self setWindowState:newState animated:isAnimated];
}

- (void)setWindowState:(_WLCalendarWindowState)newState animated:(BOOL)anIsAnimated
{
    __auto_type oldState = _windowState;

    _windowState = newState;

    if (oldState == newState)
    {
        if (!anIsAnimated)
            [_runningAnimation cancelWithReason:WLAnimationStateReasonFastForward];

        return;
    }

    if (anIsAnimated)
    {
        if (_runningAnimation.state != WLAnimationSequenceStateRunning)
        {
            __auto_type scenes = [NSMutableArray new];

            switch (newState)
            {
                case WLCalendarWindowStateInactiveFaded:
                    if (oldState == WLCalendarWindowStateActive)
                        [scenes addObject:[self animateFadeOutAndDeactivate]];

                    [scenes addObject:[self animatePartialFadeIn]];
                    break;
                case WLCalendarWindowStateInactive:
                    if (oldState == WLCalendarWindowStateActive)
                        [scenes addObject:[self animateFadeOutAndDeactivate]];

                    [scenes addObject:[self animateFadeIn]];
                    break;
                case WLCalendarWindowStateActive:
                    [scenes setArray:@[
                        [self animateFadeOutAndActivate],
                        [self animateFadeIn]
                    ]];
                    break;
            }

            __auto_type animation = [WLAnimationSequence new];
            [animation.mutableScenes setArray:scenes];

            __auto_type previousAnimation = _runningAnimation;
            _runningAnimation = animation;
            [_runningAnimation runAfter:previousAnimation withCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                if (self->_runningAnimation == aSequence)
                    self->_runningAnimation = nil;
            }];
        }
        else
        {
            NSParameterAssert(_runningAnimation.currentScene.state == WLAnimationSceneStateRunning);

            switch (newState)
            {
                case WLCalendarWindowStateInactiveFaded:
                    if (oldState == WLCalendarWindowStateInactive)
                    {
                        // FadeIn is the last scene of the Inactive animation.
                        // Its only difference from PartialFadeIn is target alphaValue
                        [[_runningAnimation sceneWithIdentifier:_WLFadeInScene] mergeWithScene:[self animatePartialFadeIn]];
                    }
                    else // WLCalendarWindowStateActive
                    {
                        if ([_runningAnimation.currentScene.identifier isEqual:_WLFadeOutAndActivateScene])
                        {
                            // FadeOutAndActivate did not yet complete and thus window
                            // is still in the Inactive state with wrong alphaValue.
                            [_runningAnimation.currentScene mergeWithScene:[self animatePartialFadeIn]];
                            [_runningAnimation.mutableScenes removeAllObjects];
                        }
                        else // _WLFadeInScene
                        {
                            NSParameterAssert([_runningAnimation.currentScene.identifier isEqual:_WLFadeInScene]);
                            NSParameterAssert(_runningAnimation.scenes.count == 0);

                            // FadeOutAndActivate has completed and the window is in the Active state.
                            // FadeIn only changes alphaValue and can be substituted with FadeOutAndDeactivate.
                            [_runningAnimation.currentScene mergeWithScene:[self animateFadeOutAndDeactivate]];
                            [_runningAnimation.mutableScenes addObject:[self animatePartialFadeIn]];
                        }
                    }
                    break;
                case WLCalendarWindowStateInactive:
                    if (oldState == WLCalendarWindowStateInactiveFaded)
                    {
                        // PartialFadeIn is the last scene of the InactiveFaded animation.
                        // Its only difference from FadeIn is target alphaValue.
                        [[_runningAnimation sceneWithIdentifier:_WLPartialFadeInScene] mergeWithScene:[self animateFadeIn]];
                    }
                    else // WLCalendarWindowStateActive
                    {
                        if ([_runningAnimation.currentScene.identifier isEqual:_WLFadeOutAndActivateScene])
                        {
                            // FadeOutAndActivate did not yet complete and thus window
                            // is still in the Inactive state with wrong alphaValue.
                            [_runningAnimation.currentScene mergeWithScene:[self animateFadeIn]];
                            [_runningAnimation.mutableScenes removeAllObjects];
                        }
                        else // _WLFadeInScene
                        {
                            // FadeOutAndActivate has completed and the window is in the Active state.
                            // FadeIn only changes alphaValue and can be substituted with FadeOutAndDeactivate.
                            NSParameterAssert([_runningAnimation.currentScene.identifier isEqual:_WLFadeInScene]);
                            NSParameterAssert(_runningAnimation.scenes.count == 0);

                            [_runningAnimation.currentScene mergeWithScene:[self animateFadeOutAndDeactivate]];
                            [_runningAnimation.mutableScenes addObject:[self animateFadeIn]];
                        }
                    }
                    break;
                case WLCalendarWindowStateActive:
                    if ([_runningAnimation.currentScene.identifier isEqual:_WLFadeOutAndDeactivateScene])
                    {
                        // _WLFadeOutAndDeactivate did not yet complete and thus window
                        // is still in the Active state with wrong alphaValue.
                        [_runningAnimation.currentScene mergeWithScene:[self animateFadeIn]];
                        [_runningAnimation.mutableScenes removeAllObjects];
                    }
                    else // _WLFadeInScene or _WLPartialFadeInScene
                    {
                        [_runningAnimation.currentScene mergeWithScene:[self animateFadeOutAndActivate]];
                        [_runningAnimation.mutableScenes addObject:[self animateFadeIn]];
                    }
                    break;
            }
        }
    }
    else
    {
        [_runningAnimation abort];

        __auto_type window = self.window;

        switch (newState)
        {
            case WLCalendarWindowStateInactive:
                [self _deactivate:window];
                window.alphaValue = 1.0;
                break;
            case WLCalendarWindowStateInactiveFaded:
                [self _deactivate:window];
                window.alphaValue = _WLFadedAlphaValue;
                break;
            case WLCalendarWindowStateActive:
                [self _activate:window];
                window.alphaValue = 1.0;
                break;
        }
    }
}

- (BOOL)isFadedOut
{
    return self.windowState == WLCalendarWindowStateInactiveFaded;
}

- (void)setIsFadedOut:(BOOL)isFadedOut
{
    if (isFadedOut)
        self.windowState = WLCalendarWindowStateInactiveFaded;
    else if (self.windowState == WLCalendarWindowStateInactiveFaded)
        self.windowState = WLCalendarWindowStateInactive;
}

#pragma mark Methods

+ (NSRect)windowFrameOnScreen:(NSScreen *)aScreen preferences:(nullable NSDictionary *)aPreferences
{
    if (!aPreferences)
        aPreferences = (NSDictionary *)NSUserDefaults.standardUserDefaults;

    if (!aScreen)
        aScreen = [self windowScreenWithPreferences:aPreferences];

    BLSize prefSize = [[aPreferences objectForKey:WLCalendarSizeKey] unsignedIntegerValue];
    BLPosition prefPosition = [[aPreferences objectForKey:WLCalendarPositionKey] unsignedIntegerValue];
    NSRect prefRatios = NSRectFromString([aPreferences objectForKey:WLCustomFrameFactorsKey]);

    NSRect screenFrame = aScreen.visibleFrame;
    NSRect windowFrame = NSZeroRect;

    if (prefSize != BLCustomSize)
    {
        static const NSSize Margin = {.width = 14.0, .height = 14.0};

        screenFrame = NSInsetRect(screenFrame, Margin.width, Margin.height);

        switch (prefSize)
        {
            case BLNarrowSize:
                windowFrame.size.width = BLNarrowMinimumSize.width;
                windowFrame.size.height = fmin(BLNarrowMinimumSize.height, NSHeight(screenFrame));
                break;
            case BLNormalSize:
                windowFrame.size.width = fmax(BLNormalMinimumSize.width, NSWidth(screenFrame) / 2);
                windowFrame.size.height = fmax(BLNormalMinimumSize.height, NSHeight(screenFrame) / 2);
                break;
            case BLFullSize:
                windowFrame.size = screenFrame.size;
                break;
            case BLCustomSize:
                __builtin_unreachable();
                break;
        }

        CGFloat px = 0.0;
        CGFloat py = 0.0;

        if (prefPosition == BLPositionTopCenter ||
            prefPosition == BLPositionCenterCenter ||
            prefPosition == BLPositionBottomCenter)
        {
            px = floor(NSWidth(screenFrame) / 2.0 - NSWidth(windowFrame) / 2.0);
        }
        else if (prefPosition == BLPositionTopRight ||
                 prefPosition == BLPositionCenterRight ||
                 prefPosition == BLPositionBottomRight)
        {
            px = NSWidth(screenFrame) - NSWidth(windowFrame);
        }

        if (prefPosition == BLPositionTopLeft ||
            prefPosition == BLPositionTopCenter ||
            prefPosition == BLPositionTopRight)
        {
            py = NSHeight(screenFrame) - NSHeight(windowFrame);
        }
        else if (prefPosition == BLPositionCenterLeft ||
                 prefPosition == BLPositionCenterCenter ||
                 prefPosition == BLPositionCenterRight)
        {
            py = NSHeight(screenFrame) / 2.0 - NSHeight(windowFrame) / 2.0;
        }

        windowFrame.origin = NSMakePoint(screenFrame.origin.x + px, screenFrame.origin.y + py);
    }
    else
    {
        windowFrame = NSMakeRect(NSMinX(screenFrame) + NSMinX(prefRatios) * NSWidth(screenFrame),
                                 NSMinY(screenFrame) + NSMinY(prefRatios) * NSHeight(screenFrame),
                                 NSWidth(prefRatios) * NSWidth(screenFrame),
                                 NSHeight(prefRatios) * NSHeight(screenFrame));
    }

    return [aScreen backingAlignedRect:windowFrame
                               options:NSAlignMinXNearest | NSAlignMaxYNearest | NSAlignWidthOutward | NSAlignHeightOutward];
}

+ (nullable NSScreen *)windowScreenWithPreferences:(nullable NSDictionary *)aPreferences
{
    if (!aPreferences)
        aPreferences = (NSDictionary *)NSUserDefaults.standardUserDefaults;

    __auto_type newScreen = [NSScreen WL_screenWithUUID:[aPreferences objectForKey:WLScreenUUIDKey]];

    if (!newScreen)
    {
        __auto_type screens = NSScreen.screens;

        if (screens.count)
            newScreen = screens[0];
    }

    return newScreen;
}

- (NSView *)makeActiveBackgroundView
{
    __auto_type effectsView = [NSVisualEffectView new];
    effectsView.translatesAutoresizingMaskIntoConstraints = NO;
    effectsView.state = NSVisualEffectStateActive;
    effectsView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    effectsView.maskImage = [NSImage imageNamed:@"calendar-background-active-mask"];

    if (@available(macOS 10.14, *))
        effectsView.material = NSVisualEffectMaterialHUDWindow;
    else
        effectsView.material = NSVisualEffectMaterialPopover;

    __auto_type backgroundView = [self _makeBackgroundView:YES];
    [effectsView addSubview:backgroundView];

    [NSLayoutConstraint activateConstraints:@[
        [effectsView.leftAnchor constraintEqualToAnchor:backgroundView.leftAnchor],
        [effectsView.topAnchor constraintEqualToAnchor:backgroundView.topAnchor],
        [effectsView.rightAnchor constraintEqualToAnchor:backgroundView.rightAnchor],
        [effectsView.bottomAnchor constraintEqualToAnchor:backgroundView.bottomAnchor]
    ]];

    return effectsView;
}

- (NSView *)makeInactiveBackgroundView
{
    return [self _makeBackgroundView:NO];
}

- (void)windowScreenDidChange
{
    __auto_type newScreen = [self.class windowScreenWithPreferences:nil];

    if (!newScreen)
        return;

    __auto_type newScreenVisibleFrame = newScreen.visibleFrame;
    BOOL shouldUpdateScreen = ![_windowScreen isEqual:newScreen];
    BOOL shouldUpdateScreenFrame = !NSEqualRects(_windowScreenVisibleFrame, newScreenVisibleFrame);

    if (shouldUpdateScreen)
        [self willChangeValueForKey:@"windowScreen"];

    if (shouldUpdateScreenFrame)
        [self willChangeValueForKey:@"windowScreenVisibleFrame"];

    _windowScreen = newScreen;
    _windowScreenVisibleFrame = newScreenVisibleFrame;

    if (shouldUpdateScreenFrame || shouldUpdateScreen)
        [self _performWindowFrameDidChange];

    if (shouldUpdateScreenFrame)
        [self didChangeValueForKey:@"windowScreenVisibleFrame"];

    if (shouldUpdateScreen)
        [self didChangeValueForKey:@"windowScreen"];
}

- (void)windowFrameDidChange
{
    __auto_type screen = self.windowScreen;

    if (!screen)
        return;

    __auto_type window = self.window;
    __auto_type contentView = window.contentView;

    NSParameterAssert(contentView != nil);

    __auto_type newWindowAlignmentFrame = [self.class windowFrameOnScreen:screen preferences:nil];

    // Window frame specified by the user is an alignment rect that does not include shadow.
    // Since the window uses custom shadow that is part of the background image
    // user's frame needs to be extended appropriately.

    __auto_type newWindowFrame = newWindowAlignmentFrame;
    __auto_type newContentViewFrame = [window convertRectFromScreen:newWindowFrame];
    newContentViewFrame = [contentView convertRect:newContentViewFrame fromView:nil];

    switch (_windowState)
    {
        case WLCalendarWindowStateInactiveFaded:
        case WLCalendarWindowStateInactive:
            newContentViewFrame.origin.x -= _WLShadowInsets.left;

            if (contentView.isFlipped)
                newContentViewFrame.origin.y -= _WLShadowInsets.top;
            else
                newContentViewFrame.origin.y -= _WLShadowInsets.bottom;

            newContentViewFrame.size.width += _WLShadowInsets.left + _WLShadowInsets.right;
            newContentViewFrame.size.height += _WLShadowInsets.top + _WLShadowInsets.bottom;
            newWindowFrame = [contentView convertRect:newContentViewFrame toView:nil];
            newWindowFrame = [window convertRectToScreen:newWindowFrame];
            break;
        case WLCalendarWindowStateActive:
            break;
    }

    _windowWidthConstraint.constant = NSWidth(newContentViewFrame);
    _windowHeightConstraint.constant = NSHeight(newContentViewFrame);

    BOOL shouldUpdateWindowAlignmentFrame = !NSEqualRects(_windowAlignmentFrame, newWindowAlignmentFrame);

    if (shouldUpdateWindowAlignmentFrame)
        [self willChangeValueForKey:@"windowAlignmentFrame"];

    _windowAlignmentFrame = newWindowAlignmentFrame;
    [window setFrameTopLeftPoint:NSMakePoint(NSMinX(newWindowFrame), NSMaxY(newWindowFrame))];

    if (shouldUpdateWindowAlignmentFrame)
        [self didChangeValueForKey:@"windowAlignmentFrame"];
}

- (WLAnimationScene *)animateFadeOutAndActivate
{
    __auto_type window = self.window;

    __auto_type scene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence * _Nonnull aSequence) {
        window.animator.alphaValue = 0.0;
    }];
    scene.completionHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        if (aSequence.state != WLAnimationSequenceStateAborting)
        {
            [self _activate:window];
            [window.contentView layoutSubtreeIfNeeded];
            [window orderBack:nil];
        }
    };
    scene.identifier = _WLFadeOutAndActivateScene;
    scene.durationHandler = ^{ return window.alphaValue * _WLFadeTotalDuration; };
    scene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    if (@available(macOS 10.12, *))
    {
        if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion)
        {
            scene.defaultDuration = @0.0;
            scene.durationHandler = nil;
        }
    }

    return scene;
}

- (WLAnimationScene *)animateFadeOutAndDeactivate
{
    __auto_type window = self.window;

    __auto_type scene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence * _Nonnull aSequence) {
        window.animator.alphaValue = 0.0;
    }];
    scene.completionHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        if (aSequence.state != WLAnimationSequenceStateAborting)
        {
            [self _deactivate:window];
            [window.contentView layoutSubtreeIfNeeded];
            [window orderBack:nil];
        }
    };
    scene.identifier = _WLFadeOutAndDeactivateScene;
    scene.durationHandler = ^{ return window.alphaValue * _WLFadeTotalDuration; };
    scene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    if (@available(macOS 10.12, *))
    {
        if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion)
        {
            scene.defaultDuration = @0.0;
            scene.durationHandler = nil;
        }
    }

    return scene;
}

- (WLAnimationScene *)animatePartialFadeIn
{
    __auto_type window = self.window;

    __auto_type scene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence * _Nonnull aSequence) {
        window.animator.alphaValue = _WLFadedAlphaValue;
    }];
    scene.completionHandler = WLAnimationHandlerNoop;
    scene.identifier = _WLPartialFadeInScene;
    scene.durationHandler = ^{ return fabs(_WLFadedAlphaValue - window.alphaValue) * _WLFadeTotalDuration; };
    scene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    if (@available(macOS 10.12, *))
    {
        if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion)
        {
            scene.defaultDuration = @0.0;
            scene.durationHandler = nil;
        }
    }

    return scene;
}

- (WLAnimationScene *)animateFadeIn
{
    __auto_type window = self.window;

    __auto_type scene = [WLAnimationScene sceneWithAnimatorChanges:^(WLAnimationSequence * _Nonnull aSequence) {
        window.animator.alphaValue = 1.0;
    }];
    scene.completionHandler = WLAnimationHandlerNoop;
    scene.identifier = _WLFadeInScene;
    scene.durationHandler = ^{ return (1.0 - window.alphaValue) * _WLFadeTotalDuration; };
    scene.defaultTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    if (@available(macOS 10.12, *))
    {
        if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion)
        {
            scene.defaultDuration = @0.0;
            scene.durationHandler = nil;
        }
    }

    return scene;
}

#pragma mark Private

- (NSView *)_makeBackgroundView:(BOOL)anIsActive
{
    static NSColor *NoisePatternColor = nil;
    static dispatch_once_t Once;
    dispatch_once(&Once, ^{
        __auto_type noiseImage = [NSImage imageNamed:@"calendar-background-noise"];
        __auto_type transparentNoiseImage = [NSImage imageWithSize:noiseImage.size
                                                           flipped:NO
                                                    drawingHandler:^BOOL(NSRect aDestinationRect)
        {
            [noiseImage drawInRect:aDestinationRect
                          fromRect:aDestinationRect
                         operation:NSCompositeSourceOver
                          fraction:1.0];
            [[NSColor.clearColor colorWithAlphaComponent:0.03] set];
            NSRectFillUsingOperation(aDestinationRect, NSCompositeDestinationIn);
            return YES;
        }];

        NoisePatternColor = [NSColor colorWithPatternImage:transparentNoiseImage];
    });

    __auto_type imageView = [NSImageView new];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.image = [NSImage imageNamed:anIsActive ? @"calendar-background-active" : @"calendar-background-inactive"];
    imageView.editable = NO;
    imageView.imageScaling = NSImageScaleAxesIndependently;
    imageView.imageAlignment = NSImageAlignCenter;
    imageView.imageFrameStyle = NSImageFrameNone;

    if (@available(macOS 10.15, *))
    {
        imageView.horizontalContentSizeConstraintActive = NO;
        imageView.verticalContentSizeConstraintActive = NO;
    }
    else
    {
        [imageView setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                            forOrientation:NSLayoutConstraintOrientationHorizontal];
        [imageView setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                            forOrientation:NSLayoutConstraintOrientationVertical];
    }

    NSEdgeInsets noiseInsets = NSEdgeInsetsMake(anIsActive ? _WLBorderInsets.left : (_WLShadowInsets.left + _WLBorderInsets.left),
                                                anIsActive ? _WLBorderInsets.top : (_WLShadowInsets.top + _WLBorderInsets.top),
                                                anIsActive ? _WLBorderInsets.right : (_WLShadowInsets.right + _WLBorderInsets.right),
                                                anIsActive ? _WLBorderInsets.bottom : (_WLShadowInsets.bottom + _WLBorderInsets.bottom));

    __auto_type noiseView = [NSBox new];
    noiseView.translatesAutoresizingMaskIntoConstraints = NO;
    noiseView.boxType = NSBoxCustom;
    noiseView.titlePosition = NSNoTitle;
    noiseView.fillColor = NSColor.WL_noisePattern;
    noiseView.borderWidth = 0.0;
    noiseView.cornerRadius = 5.0;

    __auto_type rootView = [NSView new];
    rootView.translatesAutoresizingMaskIntoConstraints = NO;
    rootView.canDrawSubviewsIntoLayer = YES;
    rootView.subviews = @[imageView, noiseView];

    [NSLayoutConstraint activateConstraints:@[
        [rootView.leftAnchor constraintEqualToAnchor:imageView.leftAnchor],
        [rootView.topAnchor constraintEqualToAnchor:imageView.topAnchor],
        [rootView.rightAnchor constraintEqualToAnchor:imageView.rightAnchor],
        [rootView.bottomAnchor constraintEqualToAnchor:imageView.bottomAnchor],

        [noiseView.leftAnchor constraintEqualToAnchor:rootView.leftAnchor constant:noiseInsets.left],
        [noiseView.topAnchor constraintEqualToAnchor:rootView.topAnchor constant:noiseInsets.top],
        [rootView.rightAnchor constraintEqualToAnchor:noiseView.rightAnchor constant:noiseInsets.right],
        [rootView.bottomAnchor constraintEqualToAnchor:noiseView.bottomAnchor constant:noiseInsets.bottom]
    ]];

    return rootView;
}

- (void)_scheduleWindowScreenDidChange
{
    NSParameterAssert(NSThread.isMainThread);
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(windowScreenDidChange) object:nil];
    [self performSelector:@selector(windowScreenDidChange) withObject:nil afterDelay:0.0];
}

- (void)_performWindowScreenDidChange
{
    NSParameterAssert(NSThread.isMainThread);
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(windowScreenDidChange) object:nil];
    [self windowScreenDidChange];
}

- (void)_scheduleWindowFrameDidChange
{
    NSParameterAssert(NSThread.isMainThread);
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(windowFrameDidChange) object:nil];
    [self performSelector:@selector(windowFrameDidChange) withObject:nil afterDelay:0.0];
}

- (void)_performWindowFrameDidChange
{
    NSParameterAssert(NSThread.isMainThread);
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(windowFrameDidChange) object:nil];
    [self windowFrameDidChange];
}

- (void)_activate:(NSWindow *)aWindow
{
    NSParameterAssert(_windowState == WLCalendarWindowStateActive);

    aWindow.hasShadow = YES;
    aWindow.level = NSFloatingWindowLevel;
    aWindow.collectionBehavior = (NSWindowCollectionBehaviorTransient |
                                  NSWindowCollectionBehaviorIgnoresCycle |
                                  NSWindowCollectionBehaviorFullScreenNone |
                                  NSWindowCollectionBehaviorFullScreenDisallowsTiling);

    if (!_activeBackgroundView)
        _activeBackgroundView = [self makeActiveBackgroundView];

    __auto_type calendarView = self.calendarViewController.view;
    [_activeBackgroundView addSubview:calendarView];

    [NSLayoutConstraint activateConstraints:@[
        [calendarView.leftAnchor constraintEqualToAnchor:_activeBackgroundView.leftAnchor
                                                constant:_WLBorderInsets.left + _WLLayoutInsets.left],
        [calendarView.topAnchor constraintEqualToAnchor:_activeBackgroundView.topAnchor
                                               constant:_WLBorderInsets.top + _WLLayoutInsets.top],
        [_activeBackgroundView.rightAnchor constraintEqualToAnchor:calendarView.rightAnchor
                                                          constant:_WLBorderInsets.right + _WLLayoutInsets.right],
        [_activeBackgroundView.bottomAnchor constraintEqualToAnchor:calendarView.bottomAnchor
                                                           constant:_WLBorderInsets.bottom + _WLLayoutInsets.bottom]
    ]];

    aWindow.contentView = _activeBackgroundView;
    [self _activateContentSizeConstraints:_activeBackgroundView];

    [self _performWindowFrameDidChange];
}

- (void)_deactivate:(NSWindow *)aWindow
{
    NSParameterAssert(_windowState == WLCalendarWindowStateInactiveFaded ||
                      _windowState == WLCalendarWindowStateInactive);

    aWindow.hasShadow = NO;
    // In 10.7+ window level of desktop elements is kCGDesktopWindowLevel + 21.
    aWindow.level = kCGDesktopWindowLevel + 15;
    aWindow.collectionBehavior = (NSWindowCollectionBehaviorCanJoinAllSpaces |
                                  NSWindowCollectionBehaviorTransient |
                                  NSWindowCollectionBehaviorIgnoresCycle |
                                  NSWindowCollectionBehaviorFullScreenNone |
                                  NSWindowCollectionBehaviorFullScreenDisallowsTiling);

    if (!_inactiveBackgroundView)
        _inactiveBackgroundView = [self makeInactiveBackgroundView];

    __auto_type calendarView = self.calendarViewController.view;
    [_inactiveBackgroundView addSubview:calendarView];

    [NSLayoutConstraint activateConstraints:@[
        [calendarView.leftAnchor constraintEqualToAnchor:_inactiveBackgroundView.leftAnchor
                                                constant:_WLShadowInsets.left + _WLBorderInsets.left + _WLLayoutInsets.left],
        [calendarView.topAnchor constraintEqualToAnchor:_inactiveBackgroundView.topAnchor
                                               constant:_WLShadowInsets.top + _WLBorderInsets.top + _WLLayoutInsets.top],
        [_inactiveBackgroundView.rightAnchor constraintEqualToAnchor:calendarView.rightAnchor
                                                            constant:_WLShadowInsets.right + _WLBorderInsets.right + _WLLayoutInsets.right],
        [_inactiveBackgroundView.bottomAnchor constraintEqualToAnchor:calendarView.bottomAnchor
                                                             constant:_WLShadowInsets.bottom + _WLBorderInsets.bottom + _WLLayoutInsets.bottom]
    ]];

    aWindow.contentView = _inactiveBackgroundView;
    [self _activateContentSizeConstraints:_inactiveBackgroundView];

    [self _performWindowFrameDidChange];
}

- (void)_activateContentSizeConstraints:(NSView *)aContentView
{
    NSParameterAssert(aContentView != nil);

    if (_windowWidthConstraint)
        _windowWidthConstraint.active = NO;

    if (_windowHeightConstraint)
        _windowHeightConstraint.active = NO;

    // arbitrary size to avoid a layout warning: actual values are set in -windowFrameDidChange
    [NSLayoutConstraint activateConstraints:@[
        (_windowWidthConstraint = [aContentView.widthAnchor constraintEqualToConstant:64.0]),
        (_windowHeightConstraint = [aContentView.heightAnchor constraintEqualToConstant:64.0])
    ]];
}

#pragma mark NSWindowController

- (void)showWindow:(id)aSender
{
    [self.window orderBack:aSender];
}

- (void)windowDidChangeScreen:(NSNotification *)aNotification
{
    if (!self.window.screen)
        [_runningAnimation cancelWithReason:WLAnimationStateReasonFastForward];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)aChange
                       context:(void *)aContext
{
    if (aContext == _WLScreenObservationContext)
        [self _scheduleWindowScreenDidChange];
    else if (aContext == _WLFrameObservationContext)
        [self _scheduleWindowFrameDidChange];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

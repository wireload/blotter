//
//  WLFrameArrangementView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 27.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WLDesktopMockupView.h"
#import "WLGraphics.h"
#import "WLFrameArrangementView.h"


static const CGFloat _WLCellWidth = 20.0;

static const CGFloat _WLBorderWidth = 2.0;

static const CGFloat _WLBorderRadius = 5.0;

static const CGFloat _WLGridLineWidth = 1.0;


#define DEBUG_EDITING DEBUG && 0


@implementation WLFrameArrangementView
{
    WLDesktopMockupView *_desktopView;
    WLFrameArrangementResizingGridAuxView *_resizingGridView;
    WLFrameArrangementPositioningGridAuxView *_positioningGridView;

#if DEBUG_EDITING
    NSBox *_editingGuideView;
#endif

    NSLayoutConstraint *_mockupLeftConstraint;
    NSLayoutConstraint *_mockupTopConstraint;
    NSLayoutConstraint *_mockupWidthConstraint;
    NSLayoutConstraint *_mockupHeightConstraint;
    NSLayoutConstraint *_mockupMinWidthConstraint;
    NSLayoutConstraint *_mockupMinHeightConstraint;

    NSLayoutGuide *_resizingGuide;
    NSLayoutConstraint *_resizingLeftConstraint;
    NSLayoutConstraint *_resizingTopConstraint;
    NSLayoutConstraint *_resizingRightConstraint;
    NSLayoutConstraint *_resizingBottomConstraint;
    NSLayoutConstraint *_resizingCenterXConstraint;
    NSLayoutConstraint *_resizingCenterYConstraint;
    NSLayoutConstraint *_resizingWidthConstraint;
    NSLayoutConstraint *_resizingHeightConstraint;
    NSLayoutConstraint *_resizingBoundingLeftConstraint;
    NSLayoutConstraint *_resizingBoundingTopConstraint;
    NSLayoutConstraint *_resizingBoundingRightConstraint;
    NSLayoutConstraint *_resizingBoundingBottomConstraint;
    NSLayoutConstraint *_resizingAspectRatioConstraint;
    NSLayoutConstraint *_resizingHandleLeftConstraint;
    NSLayoutConstraint *_resizingHandleTopConstraint;
    NSLayoutConstraint *_resizingHandleRightConstraint;
    NSLayoutConstraint *_resizingHandleBottomConstraint;
    NSRect _resizingFrameRatios;
    WLEdge _resizingHandle;
    NSSize _minResizingLayoutSize; // // in _resizingGridView's layout coordinate system
    NSRect _startingResizingDrawingRect; // in _resizingGridView's drawing coordinate system
    NSRect _startingResizingSnappedDrawingRect; // in _resizingGridView's drawing coordinate system

    NSLayoutGuide *_positioningGuide;
    NSLayoutConstraint *_positioningLeftConstraint;
    NSLayoutConstraint *_positioningTopConstraint;
    NSLayoutConstraint *_positioningWidthConstraint;
    NSLayoutConstraint *_positioningHeightConstraint;
    NSPoint _startingPositioningTopLeft; // in _positioningGridView's coordinate system

    NSPoint _startingPoint; // in view's coordinate system

    BOOL _isAnimating;
}

#pragma mark Properties

+ (BOOL)automaticallyNotifiesObserversOfEditingMode
{
    return NO;
}

- (void)setMockupFrameRatios:(NSRect)newRatios
{
    [self resizingDidCancel];
    [self positioningDidCancel];

    if (NSEqualRects(_mockupFrameRatios, newRatios))
        return;

    _mockupFrameRatios = newRatios;
    self.needsUpdateConstraints = YES;
}

- (void)setMockupMinFrameSizeRatios:(NSSize)newRatios
{
    [self resizingDidCancel];
    [self positioningDidCancel];

    if (NSEqualSizes(_mockupMinFrameSizeRatios, newRatios))
        return;

    _mockupMinFrameSizeRatios = newRatios;

    self.needsUpdateConstraints = YES;
    [self.window invalidateCursorRectsForView:self];
}

- (void)setEditingMode:(WLFrameArrangementMode)newEditingMode
{
    if (_editingMode == newEditingMode)
        return;

    [self willChangeValueForKey:@"editingMode"];
    _editingMode = newEditingMode;
    [self didChangeValueForKey:@"editingMode"];

    switch (newEditingMode)
    {
        case WLFrameArrangementModeResizing:
            self.handlesView.alphaValue = 1.0;
            [self positioningDidCancel];
            break;
        case WLFrameArrangementModePositioning:
            self.handlesView.alphaValue = 0.0;
            [self resizingDidCancel];
            break;
    }

    self.needsUpdateConstraints = YES;
}

- (BOOL)shouldSnapToGrid
{
    return _editingMode == WLFrameArrangementModeResizing && !(NSEvent.modifierFlags & NSControlKeyMask);
}

- (BOOL)shouldPreserveAspectRatio
{
    return _editingMode == WLFrameArrangementModeResizing && (NSEvent.modifierFlags & NSShiftKeyMask);
}

- (BOOL)shouldPreserveCenter
{
    return _editingMode == WLFrameArrangementModeResizing && (NSEvent.modifierFlags & NSAlternateKeyMask);
}

- (BOOL)isResizing
{
    return _resizingHandle != WLEdgeInvalid;
}

#pragma mark Methods

- (NSSize)drawingAlignedFrameSize:(NSSize)aSize forEditingMode:(WLFrameArrangementMode)anEditingMode
{
    aSize = NSMakeSize(fdim(aSize.width, _WLCellWidth), fdim(aSize.height, _WLCellWidth));

    switch (anEditingMode)
    {
        case WLFrameArrangementModeResizing:
            aSize = [_resizingGridView drawingAlignedFrameSize:aSize];
            break;
        case WLFrameArrangementModePositioning:
            aSize = [_positioningGridView drawingAlignedFrameSize:aSize];
            break;
    }

    return NSMakeSize(aSize.width + 2.0 * _WLCellWidth, aSize.height + 2.0 * _WLCellWidth);
}

- (WLAnimationScene *)animateFrameRatios:(NSRect)newFrameRatios minFrameSizeRatios:(NSSize)newMinSize
{
    __weak __auto_type weakSelf = self;
    __auto_type scene = [WLAnimationScene sceneWithChanges:^(WLAnimationSequence * _Nonnull aSequence) {
        __auto_type strongSelf = weakSelf;
        if (!strongSelf)
            return;

        strongSelf->_isAnimating = YES;

        strongSelf.mockupFrameRatios = newFrameRatios;
        strongSelf.mockupMinFrameSizeRatios = newMinSize;
        [strongSelf layoutSubtreeIfNeeded];
    }];
    scene.cancellationHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        [weakSelf.layer WL_performRecursively:^(CALayer * _Nonnull aLayer) {
            [aLayer WL_removeAnimationsWithPrefix:@"bounds"];
            [aLayer WL_removeAnimationsWithPrefix:@"position"];
        }];
    };
    scene.completionHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        __auto_type strongSelf = weakSelf;
        if (!strongSelf)
            return;

        strongSelf->_isAnimating = NO;
    };
    scene.defaultAllowsImplicitAnimation = @(YES);
    return scene;
}

- (WLAnimationScene *)animateEditingMode:(WLFrameArrangementMode)newEditingMode
{
    __weak __auto_type weakSelf = self;
    __auto_type scene = [WLAnimationScene sceneWithChanges:^(WLAnimationSequence * _Nonnull aSequence) {
        __auto_type strongSelf = weakSelf;
        if (!strongSelf)
            return;

        if (strongSelf.editingMode == newEditingMode)
            return;

        strongSelf->_isAnimating = YES;

        strongSelf.editingMode = newEditingMode;
        [strongSelf layoutSubtreeIfNeeded];

        // Pins are animated only when enough handle space
        // is "visible" outside of mockupView.
        __auto_type opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fillMode = kCAFillModeBoth;
        opacityAnimation.removedOnCompletion = NO; // see the completionHandler
        opacityAnimation.duration = NSAnimationContext.currentContext.duration * 0.5;

        switch (newEditingMode)
        {
            case WLFrameArrangementModeResizing:
                opacityAnimation.beginTime = [strongSelf.handlesView.layer convertTime:CACurrentMediaTime() fromLayer:nil] + NSAnimationContext.currentContext.duration * 0.5;
                opacityAnimation.fromValue = @0.0;
                opacityAnimation.toValue = @1.0;
                break;
            case WLFrameArrangementModePositioning:
                opacityAnimation.fromValue = @1.0;
                opacityAnimation.toValue = @0.0;
                break;
        }

        for (NSView *handleView in strongSelf.handlesView.subviews)
            [handleView.layer addAnimation:opacityAnimation forKey:@"opacity"];
    }];
    scene.cancellationHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        __auto_type strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf.handlesView.layer WL_performRecursively:^(CALayer * _Nonnull aLayer) {
            [aLayer WL_removeAnimationsWithPrefix:@"bounds"];
            [aLayer WL_removeAnimationsWithPrefix:@"position"];
            [aLayer removeAnimationForKey:@"opacity"];
        }];
    };
    scene.completionHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        __auto_type strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf.handlesView.layer WL_performRecursively:^(CALayer * _Nonnull aLayer) {
            [aLayer removeAnimationForKey:@"opacity"];
        }];

        strongSelf->_isAnimating = NO;
    };
    scene.defaultAllowsImplicitAnimation = @(YES);
    return scene;
}

- (void)resizingDidStartAtPoint:(NSPoint)aPoint handle:(WLEdge)aHandle
{
    if (self.isResizing)
        return;

    [self layoutSubtreeIfNeeded];

    _resizingHandle = aHandle;
    _startingPoint = aPoint;
    _startingResizingDrawingRect = [_resizingGridView drawingRectFromFrameRatios:_mockupFrameRatios];
    NSSize layoutScreenSize = _resizingGridView.layoutBounds.size;
    _minResizingLayoutSize = NSMakeSize(_mockupMinFrameSizeRatios.width * layoutScreenSize.width,
                                _mockupMinFrameSizeRatios.height * layoutScreenSize.height);
    _startingResizingSnappedDrawingRect = [_resizingGridView gridSnappedLayoutRect:[_resizingGridView layoutRectFromDrawingRect:_startingResizingDrawingRect]
                                                       withOptions:NSAlignAllEdgesNearest
                                                           minSize:_minResizingLayoutSize
                                                              edge:_resizingHandle];
    _startingResizingSnappedDrawingRect = [_resizingGridView drawingRectFromLayoutRect:_startingResizingSnappedDrawingRect];
    _resizingFrameRatios = _mockupFrameRatios;

    _resizingGuide = [NSLayoutGuide new];
    [self addLayoutGuide:_resizingGuide];
    [NSLayoutConstraint activateConstraints:@[
        [_resizingGuide.leftAnchor constraintGreaterThanOrEqualToAnchor:_resizingGridView.leftAnchor],
        [_resizingGuide.topAnchor constraintGreaterThanOrEqualToAnchor:_resizingGridView.topAnchor],
        [_resizingGuide.rightAnchor constraintLessThanOrEqualToAnchor:_resizingGridView.rightAnchor],
        [_resizingGuide.bottomAnchor constraintLessThanOrEqualToAnchor:_resizingGridView.bottomAnchor],
        [_resizingGuide.widthAnchor constraintGreaterThanOrEqualToConstant:_mockupMinWidthConstraint.constant],
        [_resizingGuide.heightAnchor constraintGreaterThanOrEqualToConstant:_mockupMinHeightConstraint.constant]
    ]];

    _resizingLeftConstraint = [_resizingGuide.leftAnchor constraintEqualToAnchor:_resizingGridView.leftAnchor];
    _resizingTopConstraint = [_resizingGuide.topAnchor constraintEqualToAnchor:_resizingGridView.topAnchor];
    _resizingRightConstraint = [_resizingGuide.rightAnchor constraintEqualToAnchor:_resizingGridView.leftAnchor];
    _resizingBottomConstraint = [_resizingGuide.bottomAnchor constraintEqualToAnchor:_resizingGridView.topAnchor];

    _resizingCenterXConstraint = [_resizingGuide.centerXAnchor constraintEqualToAnchor:_resizingGridView.leftAnchor];
    _resizingCenterYConstraint = [_resizingGuide.centerYAnchor constraintEqualToAnchor:_resizingGridView.topAnchor];
    _resizingWidthConstraint = [_resizingGuide.widthAnchor constraintEqualToConstant:NSWidth(_startingResizingDrawingRect)];
    _resizingHeightConstraint = [_resizingGuide.heightAnchor constraintEqualToConstant:NSHeight(_startingResizingDrawingRect)];
    _resizingBoundingLeftConstraint = [_resizingGuide.leftAnchor constraintGreaterThanOrEqualToAnchor:_resizingGridView.leftAnchor];
    _resizingBoundingTopConstraint = [_resizingGuide.topAnchor constraintGreaterThanOrEqualToAnchor:_resizingGridView.topAnchor];
    _resizingBoundingRightConstraint = [_resizingGuide.rightAnchor constraintLessThanOrEqualToAnchor:_resizingGridView.leftAnchor];
    _resizingBoundingBottomConstraint = [_resizingGuide.bottomAnchor constraintLessThanOrEqualToAnchor:_resizingGridView.topAnchor];

#if DEBUG_EDITING
    [self addSubview:_editingGuideView positioned:NSWindowAbove relativeTo:_mockupView];
    [NSLayoutConstraint activateConstraints:@[
        [_editingGuideView.leftAnchor constraintEqualToAnchor:_resizingGuide.leftAnchor],
        [_editingGuideView.topAnchor constraintEqualToAnchor:_resizingGuide.topAnchor],
        [_editingGuideView.rightAnchor constraintEqualToAnchor:_resizingGuide.rightAnchor],
        [_editingGuideView.bottomAnchor constraintEqualToAnchor:_resizingGuide.bottomAnchor]
    ]];
#endif

    [self.window makeFirstResponder:self]; // if it fails, it's not fatal: only flagsChanged dependы on being the first responder
    [self.window invalidateCursorRectsForView:self];


    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if ([self.delegate frameArrangement:self shouldAnimate:WLFrameArrangementAnimationResizingGridViewAppearance])
        {
            CALayer *presentationLayer = _resizingGridView.layer.presentationLayer;
            CGFloat currentValue = presentationLayer ? presentationLayer.opacity : _resizingGridView.alphaValue;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            context.duration = (1.0 - currentValue) * 0.2;
        }
        else
            context.duration = 0.0;

        _resizingGridView.animator.alphaValue = 1.0;
    } completionHandler:nil];
}

- (void)resizingDidContinueAtPoint:(NSPoint)aPoint
{
    if (!self.isResizing)
        return;

    BOOL shouldSnapToGrid = self.shouldSnapToGrid;
    BOOL shouldPreserveCenter = self.shouldPreserveCenter;
    BOOL shouldPreserveAspectRatio = self.shouldPreserveAspectRatio;
    NSRect startingDrawingRect = shouldSnapToGrid ? _startingResizingSnappedDrawingRect : _startingResizingDrawingRect;
    NSAlignmentOptions snappingOptions = NSAlignRectFlipped;
    NSMutableArray *activeConstraints = [NSMutableArray new];

    // Offsets are outward with respect to the currently active handle.
    // Positive values mean extension, negative values mean contraction.
    CGFloat xOffset = 0.0;
    CGFloat yOffset = 0.0;

    switch (_resizingHandle)
    {
        case WLEdgeLeft:
            xOffset = _startingPoint.x - aPoint.x;
            break;
        case WLEdgeTopLeft:
            xOffset = _startingPoint.x - aPoint.x;
            yOffset = _startingPoint.y - aPoint.y;
            break;
        case WLEdgeTop:
            yOffset = _startingPoint.y - aPoint.y;
            break;
        case WLEdgeTopRight:
            xOffset = aPoint.x - _startingPoint.x;
            yOffset = _startingPoint.y - aPoint.y;
            break;
        case WLEdgeRight:
            xOffset = aPoint.x - _startingPoint.x;
            break;
        case WLEdgeBottomRight:
            xOffset = aPoint.x - _startingPoint.x;
            yOffset = aPoint.y - _startingPoint.y;
            break;
        case WLEdgeBottom:
            yOffset = aPoint.y - _startingPoint.y;
            break;
        case WLEdgeBottomLeft:
            xOffset = _startingPoint.x - aPoint.x;
            yOffset = aPoint.y - _startingPoint.y;
            break;
        case WLEdgeCenter:
            xOffset = aPoint.x - _startingPoint.x;
            yOffset = aPoint.y - _startingPoint.y;
            break;
    }

    if (_resizingHandle == WLEdgeCenter)
    {
        snappingOptions |= NSAlignMinXNearest | NSAlignMinYNearest | NSAlignWidthOutward | NSAlignHeightOutward;

        _resizingLeftConstraint.constant = NSMinX(startingDrawingRect) + xOffset;
        _resizingLeftConstraint.priority = NSLayoutPriorityDefaultHigh;

        _resizingTopConstraint.constant = NSMinY(startingDrawingRect) + yOffset;
        _resizingTopConstraint.priority = NSLayoutPriorityDefaultHigh;

        _resizingWidthConstraint.constant = NSWidth(startingDrawingRect);
        _resizingWidthConstraint.priority = NSLayoutPriorityRequired - 1;

        _resizingHeightConstraint.constant = NSHeight(startingDrawingRect);
        _resizingHeightConstraint.priority = NSLayoutPriorityRequired - 1;

        [activeConstraints addObjectsFromArray:@[
            _resizingLeftConstraint,
            _resizingTopConstraint,
            _resizingWidthConstraint,
            _resizingHeightConstraint
        ]];
    }
    else
    {
        snappingOptions |= NSAlignAllEdgesNearest;

        CGFloat newAspectRatio = NSWidth(startingDrawingRect) / NSHeight(startingDrawingRect);
        if (newAspectRatio != _resizingAspectRatioConstraint.multiplier)
        {
            _resizingAspectRatioConstraint.active = NO;
            _resizingAspectRatioConstraint = [_resizingGuide.widthAnchor constraintEqualToAnchor:_resizingGuide.heightAnchor
                                                                                      multiplier:newAspectRatio];
            _resizingAspectRatioConstraint.priority = NSLayoutPriorityRequired - 1;
        }
        _resizingAspectRatioConstraint.active = shouldPreserveAspectRatio;

        if (shouldPreserveCenter)
        {
            _resizingCenterXConstraint.constant = NSMidX(startingDrawingRect);
            _resizingCenterXConstraint.priority = NSLayoutPriorityDefaultHigh;

            _resizingCenterYConstraint.constant = NSMidY(startingDrawingRect);
            _resizingCenterYConstraint.priority = NSLayoutPriorityDefaultHigh;

            _resizingWidthConstraint.constant = NSWidth(startingDrawingRect) + 2.0 * xOffset;
            _resizingWidthConstraint.priority = NSLayoutPriorityDefaultHigh + 1;

            _resizingHeightConstraint.constant = NSHeight(startingDrawingRect) + 2.0 * yOffset;
            _resizingHeightConstraint.priority = NSLayoutPriorityDefaultHigh + 1;

            _resizingBoundingLeftConstraint.constant = NSMinX(startingDrawingRect) - xOffset;
            _resizingBoundingLeftConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingBoundingTopConstraint.constant = NSMinY(startingDrawingRect) - yOffset;
            _resizingBoundingTopConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingBoundingRightConstraint.constant = NSMaxX(startingDrawingRect) + xOffset;
            _resizingBoundingRightConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingBoundingBottomConstraint.constant = NSMaxY(startingDrawingRect) + yOffset;
            _resizingBoundingBottomConstraint.priority = NSLayoutPriorityRequired - 1;

            switch (_resizingHandle)
            {
                case WLEdgeLeft:
                case WLEdgeRight:
                    _resizingWidthConstraint.priority = NSLayoutPriorityDefaultHigh + 2;
                    [activeConstraints addObjectsFromArray:@[
                        _resizingBoundingLeftConstraint,
                        _resizingBoundingRightConstraint
                    ]];
                    break;
                case WLEdgeTop:
                case WLEdgeBottom:
                    _resizingHeightConstraint.priority = NSLayoutPriorityDefaultHigh + 2;
                    [activeConstraints addObjectsFromArray:@[
                        _resizingBoundingTopConstraint,
                        _resizingBoundingBottomConstraint
                    ]];
                    break;
                case WLEdgeTopLeft:
                case WLEdgeTopRight:
                case WLEdgeBottomRight:
                case WLEdgeBottomLeft:
                    [activeConstraints addObjectsFromArray:@[
                        _resizingBoundingLeftConstraint,
                        _resizingBoundingTopConstraint,
                        _resizingBoundingRightConstraint,
                        _resizingBoundingBottomConstraint
                    ]];
                case WLEdgeCenter:
                    NSParameterAssert(NO);
                    break;
            }

            [activeConstraints addObjectsFromArray:@[
                _resizingCenterXConstraint,
                _resizingCenterYConstraint,
                _resizingWidthConstraint,
                _resizingHeightConstraint,
            ]];
        }
        else
        {
            _resizingLeftConstraint.constant = NSMinX(startingDrawingRect);
            _resizingLeftConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingTopConstraint.constant = NSMinY(startingDrawingRect);
            _resizingTopConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingRightConstraint.constant = NSMaxX(startingDrawingRect);
            _resizingRightConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingBottomConstraint.constant = NSMaxY(startingDrawingRect);
            _resizingBottomConstraint.priority = NSLayoutPriorityRequired - 1;

            _resizingCenterXConstraint.constant = NSMidX(startingDrawingRect);
            _resizingCenterXConstraint.priority = NSLayoutPriorityDefaultHigh - 1;

            _resizingCenterYConstraint.constant = NSMidY(startingDrawingRect);
            _resizingCenterYConstraint.priority = NSLayoutPriorityDefaultHigh - 1;

            switch (_resizingHandle)
            {
                case WLEdgeLeft:
                    _resizingLeftConstraint.constant -= xOffset;
                    _resizingLeftConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeTopLeft:
                    _resizingLeftConstraint.constant -= xOffset;
                    _resizingLeftConstraint.priority = NSLayoutPriorityDefaultHigh;
                    _resizingTopConstraint.constant -= yOffset;
                    _resizingTopConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeTop:
                    _resizingTopConstraint.constant -= yOffset;
                    _resizingTopConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeTopRight:
                    _resizingTopConstraint.constant -= yOffset;
                    _resizingTopConstraint.priority = NSLayoutPriorityDefaultHigh;
                    _resizingRightConstraint.constant += xOffset;
                    _resizingRightConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeRight:
                    _resizingRightConstraint.constant += xOffset;
                    _resizingRightConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeBottomRight:
                    _resizingRightConstraint.constant += xOffset;
                    _resizingRightConstraint.priority = NSLayoutPriorityDefaultHigh;
                    _resizingBottomConstraint.constant += yOffset;
                    _resizingBottomConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeBottom:
                    _resizingBottomConstraint.constant += yOffset;
                    _resizingBottomConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeBottomLeft:
                    _resizingLeftConstraint.constant -= xOffset;
                    _resizingLeftConstraint.priority = NSLayoutPriorityDefaultHigh;
                    _resizingBottomConstraint.constant += yOffset;
                    _resizingBottomConstraint.priority = NSLayoutPriorityDefaultHigh;
                    break;
                case WLEdgeCenter:
                    NSParameterAssert(NO);
                    break;
            }

            switch (_resizingHandle)
            {
                case WLEdgeTopLeft:
                case WLEdgeTopRight:
                case WLEdgeBottomRight:
                case WLEdgeBottomLeft:
                    [activeConstraints addObjectsFromArray:@[
                        _resizingLeftConstraint,
                        _resizingTopConstraint,
                        _resizingRightConstraint,
                        _resizingBottomConstraint
                    ]];
                    break;
                case WLEdgeLeft:
                case WLEdgeRight:
                    [activeConstraints addObjectsFromArray:@[
                        _resizingLeftConstraint,
                        _resizingRightConstraint,
                    ]];

                    if (shouldPreserveAspectRatio)
                        [activeConstraints addObjectsFromArray:@[
                            _resizingCenterYConstraint
                        ]];
                    else
                        [activeConstraints addObjectsFromArray:@[
                            _resizingTopConstraint,
                            _resizingBottomConstraint
                        ]];
                    break;
                case WLEdgeTop:
                case WLEdgeBottom:
                    [activeConstraints addObjectsFromArray:@[
                        _resizingTopConstraint,
                        _resizingBottomConstraint,
                    ]];

                    if (shouldPreserveAspectRatio)
                        [activeConstraints addObjectsFromArray:@[
                            _resizingCenterXConstraint
                        ]];
                    else
                        [activeConstraints addObjectsFromArray:@[
                            _resizingLeftConstraint,
                            _resizingRightConstraint
                        ]];
                    break;
                case WLEdgeCenter:
                    NSParameterAssert(NO);
                    break;
            }
        }
    }

    NSMutableArray *inactiveConstraints = [NSMutableArray arrayWithArray:@[
        _resizingLeftConstraint,
        _resizingTopConstraint,
        _resizingRightConstraint,
        _resizingBottomConstraint,
        _resizingCenterXConstraint,
        _resizingCenterYConstraint,
        _resizingWidthConstraint,
        _resizingHeightConstraint,
        _resizingBoundingLeftConstraint,
        _resizingBoundingTopConstraint,
        _resizingBoundingRightConstraint,
        _resizingBoundingBottomConstraint
    ]];
    [inactiveConstraints removeObjectsInArray:activeConstraints];
    [NSLayoutConstraint activateConstraints:activeConstraints];
    [NSLayoutConstraint deactivateConstraints:inactiveConstraints];
    [self layoutSubtreeIfNeeded];

    NSRect newDrawingFrame = [self convertRect:_resizingGuide.frame toView:_resizingGridView];
    NSRect newLayoutFrame = [_resizingGridView layoutRectFromDrawingRect:newDrawingFrame];

    if (shouldSnapToGrid)
    {
        newLayoutFrame = [_resizingGridView gridSnappedLayoutRect:newLayoutFrame
                                              withOptions:snappingOptions
                                                  minSize:_minResizingLayoutSize
                                                     edge:_resizingHandle];
    }

    _resizingFrameRatios = [_resizingGridView frameRatiosFromLayoutRect:newLayoutFrame];
    self.needsUpdateConstraints = YES;
}

- (void)resizingDidStopAtPoint:(NSPoint)aPoint
{
    if (!self.isResizing)
        return;

    [self willChangeValueForKey:@"mockupFrameRatios"];
    _mockupFrameRatios = [self.delegate frameArrangement:self didChangeMockupFrameRatios:_resizingFrameRatios];
    [self didChangeValueForKey:@"mockupFrameRatios"];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if ([self.delegate frameArrangement:self shouldAnimate:WLFrameArrangementAnimationResizingGridViewDisappearance])
        {
            CALayer *presentationLayer = _resizingGridView.layer.presentationLayer;
            CGFloat currentValue = presentationLayer ? presentationLayer.opacity : _resizingGridView.alphaValue;
            context.duration = currentValue * 0.2;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        }
        else
            context.duration = 0.0;

        _resizingGridView.animator.alphaValue = 0.0;
    } completionHandler:nil];

    [self resizingDidFinish];
}

- (void)resizingDidCancel
{
    if (!self.isResizing)
        return;

    _resizingGridView.alphaValue = 0.0;

    [self resizingDidFinish];
}

- (void)resizingDidFinish
{
    _resizingHandle = WLEdgeInvalid;
    _startingPoint = NSZeroPoint;
    _startingResizingDrawingRect = NSZeroRect;
    _minResizingLayoutSize = NSZeroSize;
    _startingResizingSnappedDrawingRect = NSZeroRect;
    _resizingFrameRatios = NSZeroRect;

    self.needsUpdateConstraints = YES;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        if ([self.delegate frameArrangement:self shouldAnimate:WLFrameArrangementAnimationMockupFrameUpdate])
            context.duration = 0.1;
        else
            context.duration = 0.0;

        context.allowsImplicitAnimation = YES;
        [self layoutSubtreeIfNeeded];
    } completionHandler:nil];

#if DEBUG_EDITING
    [_editingGuideView removeFromSuperview];
#endif

    [self removeLayoutGuide:_resizingGuide];
    _resizingGuide = nil;

    _resizingLeftConstraint = nil;
    _resizingTopConstraint = nil;
    _resizingRightConstraint = nil;
    _resizingBottomConstraint = nil;

    _resizingCenterXConstraint = nil;
    _resizingCenterYConstraint = nil;
    _resizingWidthConstraint = nil;
    _resizingHeightConstraint = nil;
    _resizingBoundingLeftConstraint = nil;
    _resizingBoundingTopConstraint = nil;
    _resizingBoundingRightConstraint = nil;
    _resizingBoundingBottomConstraint = nil;

    [self.window invalidateCursorRectsForView:self];
}

- (void)positioningDidStartAtPoint:(NSPoint)aPoint
{
    if (self.isPositioning)
        return;

    [self layoutSubtreeIfNeeded];

    _isPositioning = YES;
    _startingPoint = aPoint;
    _startingPositioningTopLeft = [_positioningGridView convertRect:self.mockupView.frame fromView:self].origin;

    _positioningGuide = [NSLayoutGuide new];
    [self addLayoutGuide:_positioningGuide];

    _positioningLeftConstraint = [_positioningGuide.leftAnchor constraintEqualToAnchor:_positioningGridView.leftAnchor];
    _positioningLeftConstraint.priority = NSLayoutPriorityDefaultHigh - 1;
    _positioningLeftConstraint.constant = _startingPositioningTopLeft.x;

    _positioningTopConstraint = [_positioningGuide.topAnchor constraintEqualToAnchor:_positioningGridView.topAnchor];
    _positioningTopConstraint.priority = NSLayoutPriorityDefaultHigh - 1;
    _positioningTopConstraint.constant = _startingPositioningTopLeft.y;

    [NSLayoutConstraint activateConstraints:@[
        [_positioningGuide.leftAnchor constraintGreaterThanOrEqualToAnchor:_positioningGridView.leftAnchor],
        [_positioningGuide.topAnchor constraintGreaterThanOrEqualToAnchor:_positioningGridView.topAnchor],
        [_positioningGuide.rightAnchor constraintLessThanOrEqualToAnchor:_positioningGridView.rightAnchor],
        [_positioningGuide.bottomAnchor constraintLessThanOrEqualToAnchor:_positioningGridView.bottomAnchor],
        _positioningLeftConstraint,
        _positioningTopConstraint,
        _positioningWidthConstraint = [_positioningGuide.widthAnchor constraintEqualToAnchor:_mockupView.widthAnchor],
        _positioningHeightConstraint = [_positioningGuide.heightAnchor constraintEqualToAnchor:_mockupView.heightAnchor]
    ]];

#if DEBUG_EDITING
    [self addSubview:_editingGuideView positioned:NSWindowAbove relativeTo:_mockupView];
    [NSLayoutConstraint activateConstraints:@[
        [_editingGuideView.leftAnchor constraintEqualToAnchor:_positioningGuide.leftAnchor],
        [_editingGuideView.topAnchor constraintEqualToAnchor:_positioningGuide.topAnchor],
        [_editingGuideView.rightAnchor constraintEqualToAnchor:_positioningGuide.rightAnchor],
        [_editingGuideView.bottomAnchor constraintEqualToAnchor:_positioningGuide.bottomAnchor]
    ]];
#endif

    [self.window makeFirstResponder:self]; // if it fails, it's not fatal: only flagsChanged dependы on being the first responder
    [self.window invalidateCursorRectsForView:self];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if ([self.delegate frameArrangement:self shouldAnimate:WLFrameArrangementAnimationPositioningGridViewAppearance])
        {
            CALayer *presentationLayer = _positioningGridView.layer.presentationLayer;
            CGFloat currentValue = presentationLayer ? presentationLayer.opacity : _positioningGridView.alphaValue;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            context.duration = (1.0 - currentValue) * 0.2;
        }
        else
            context.duration = 0.0;

        _positioningGridView.animator.alphaValue = 1.0;
    } completionHandler:nil];
}

- (void)positioningDidContinueAtPoint:(NSPoint)aPoint
{
    if (!self.isPositioning)
        return;

    NSSize offset = NSMakeSize(aPoint.x - _startingPoint.x,
                               aPoint.y - _startingPoint.y);

    _positioningLeftConstraint.constant = _startingPositioningTopLeft.x + offset.width;
    _positioningTopConstraint.constant = _startingPositioningTopLeft.y + offset.height;

    NSPoint locationInGridView = [_positioningGridView convertPoint:aPoint fromView:self];
    BOOL shouldAnimate = [self.delegate frameArrangement:self
                                           shouldAnimate:WLFrameArrangementAnimationPositioningGridViewGuideHover];
    [_positioningGridView highlightPosition:[_positioningGridView positionForPoint:locationInGridView]
                                   animated:shouldAnimate];

    self.needsUpdateConstraints = YES;
}

- (void)positioningDidStopAtPoint:(NSPoint)aPoint
{
    if (!self.isPositioning)
        return;

    NSPoint locationInGridView = [_positioningGridView convertPoint:aPoint fromView:self];
    BLPosition newPosition = [_positioningGridView positionForPoint:locationInGridView];
    NSRect frameRatios = [self.delegate frameArrangement:self didChangeMockupPosition:newPosition];

    [self willChangeValueForKey:@"mockupFrameRatios"];
    _mockupFrameRatios = frameRatios;
    [self didChangeValueForKey:@"mockupFrameRatios"];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if ([self.delegate frameArrangement:self shouldAnimate:WLFrameArrangementAnimationPositioningGridViewDisappearance])
        {
            CALayer *presentationLayer = _positioningGridView.layer.presentationLayer;
            CGFloat currentValue = presentationLayer ? presentationLayer.opacity : _positioningGridView.alphaValue;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            context.duration = currentValue * 0.2;
        }
        else
            context.duration = 0.0;

        _positioningGridView.animator.alphaValue = 0.0;
    } completionHandler:nil];

    [self positioningDidFinish];
}

- (void)positioningDidCancel
{
    if (!self.isPositioning)
        return;

    _positioningGridView.alphaValue = 0.0;

    [self positioningDidFinish];
}

- (void)positioningDidFinish
{
    if (!self.isPositioning)
        return;

    _isPositioning = NO;
    _startingPoint = NSZeroPoint;
    _startingPositioningTopLeft = NSZeroPoint;

    self.needsUpdateConstraints = YES;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        if ([self.delegate frameArrangement:self shouldAnimate:WLFrameArrangementAnimationMockupFrameUpdate])
            context.duration = 0.1;
        else
            context.duration = 0.0;

        context.allowsImplicitAnimation = YES;
        [self layoutSubtreeIfNeeded];
    } completionHandler:nil];

#if DEBUG_EDITING
    [_editingGuideView removeFromSuperview];
#endif

    [self removeLayoutGuide:_positioningGuide];
    _positioningGuide = nil;

    _positioningLeftConstraint = nil;
    _positioningTopConstraint = nil;
    _positioningWidthConstraint = nil;
    _positioningHeightConstraint = nil;

    [self.window invalidateCursorRectsForView:self];
}

- (WLFrameArrangementResizingGridAuxView *)makeResizingGridView
{
    WLFrameArrangementResizingGridAuxView *v = [WLFrameArrangementResizingGridAuxView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.alphaValue = 0.0;
    return v;
}

- (WLFrameArrangementPositioningGridAuxView *)makePositioningGridView
{
    WLFrameArrangementPositioningGridAuxView *v = [WLFrameArrangementPositioningGridAuxView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.alphaValue = 0.0;
    return v;
}

- (WLFrameArrangementHandlesAuxView *)makeHandlesView
{
    __auto_type v = [WLFrameArrangementHandlesAuxView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.alphaValue = 0.0;
    return v;
}

#pragma mark Private

#if DEBUG_EDITING

- (NSBox *)_makeEditingGuideView
{
    NSBox *v = [NSBox new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.boxType = NSBoxCustom;
    v.titlePosition = NSNoTitle;
    v.borderWidth = _WLBorderWidth;
    v.borderColor = [NSColor.redColor colorWithAlphaComponent:0.75];
    return v;
}

#endif

#pragma mark WLLayerBackedView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;

    _desktopView = [WLDesktopMockupView new];
    [self addSubview:_desktopView];
    [NSLayoutConstraint activateConstraints:@[
        [_desktopView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:_WLCellWidth],
        [_desktopView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-_WLCellWidth],
        [_desktopView.topAnchor constraintEqualToAnchor:self.topAnchor constant:_WLCellWidth],
        [_desktopView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-_WLCellWidth]
    ]];

    _resizingGridView = [self makeResizingGridView];
    [self addSubview:_resizingGridView];
    [NSLayoutConstraint activateConstraints:@[
        [_resizingGridView.leftAnchor constraintEqualToAnchor:_desktopView.leftAnchor],
        [_resizingGridView.rightAnchor constraintEqualToAnchor:_desktopView.rightAnchor],
        [_resizingGridView.topAnchor constraintEqualToAnchor:_desktopView.topAnchor],
        [_resizingGridView.bottomAnchor constraintEqualToAnchor:_desktopView.bottomAnchor]
    ]];

    _positioningGridView = [self makePositioningGridView];
    [self addSubview:_positioningGridView];
    [NSLayoutConstraint activateConstraints:@[
        [_positioningGridView.leftAnchor constraintEqualToAnchor:_desktopView.leftAnchor],
        [_positioningGridView.rightAnchor constraintEqualToAnchor:_desktopView.rightAnchor],
        [_positioningGridView.topAnchor constraintEqualToAnchor:_desktopView.topAnchor],
        [_positioningGridView.bottomAnchor constraintEqualToAnchor:_desktopView.bottomAnchor]
    ]];

    _mockupView = [WLCalendarMockupView new];
    [self addSubview:_mockupView];
    [NSLayoutConstraint activateConstraints:@[
        [_mockupView.leftAnchor constraintGreaterThanOrEqualToAnchor:_desktopView.leftAnchor],
        [_mockupView.topAnchor constraintGreaterThanOrEqualToAnchor:_desktopView.topAnchor],
        [_mockupView.rightAnchor constraintLessThanOrEqualToAnchor:_desktopView.rightAnchor],
        [_mockupView.bottomAnchor constraintLessThanOrEqualToAnchor:_desktopView.bottomAnchor],

        _mockupLeftConstraint = [_mockupView.leftAnchor constraintEqualToAnchor:_desktopView.leftAnchor],
        _mockupTopConstraint = [_mockupView.topAnchor constraintEqualToAnchor:_desktopView.topAnchor],
        _mockupWidthConstraint = [_mockupView.widthAnchor constraintEqualToConstant:0.0],
        _mockupHeightConstraint = [_mockupView.heightAnchor constraintEqualToConstant:0.0],

        _mockupMinWidthConstraint = [_mockupView.widthAnchor constraintGreaterThanOrEqualToConstant:0.0],
        _mockupMinHeightConstraint = [_mockupView.heightAnchor constraintGreaterThanOrEqualToConstant:0.0]
    ]];
    _mockupLeftConstraint.priority = NSLayoutPriorityDefaultHigh;
    _mockupTopConstraint.priority = NSLayoutPriorityDefaultHigh;
    _mockupWidthConstraint.priority = NSLayoutPriorityDefaultHigh;
    _mockupHeightConstraint.priority = NSLayoutPriorityDefaultHigh;

    _handlesView = [self makeHandlesView];
    [self addSubview:_handlesView positioned:NSWindowBelow relativeTo:_mockupView];
    [NSLayoutConstraint activateConstraints:@[
        (_resizingHandleLeftConstraint = [_handlesView.leftAnchor constraintEqualToAnchor:_mockupView.leftAnchor]),
        (_resizingHandleTopConstraint = [_handlesView.topAnchor constraintEqualToAnchor:_mockupView.topAnchor]),
        (_resizingHandleRightConstraint = [_handlesView.rightAnchor constraintEqualToAnchor:_mockupView.rightAnchor]),
        (_resizingHandleBottomConstraint = [_handlesView.bottomAnchor constraintEqualToAnchor:_mockupView.bottomAnchor])
    ]];

#if DEBUG_EDITING
    _editingGuideView = [self _makeEditingGuideView];
#endif

    _resizingHandle = WLEdgeInvalid;
    self.mockupFrameRatios = NSMakeRect(0.375, 0.375, 0.25, 0.25);
    self.editingMode = WLFrameArrangementModeResizing;
}

#pragma mark NSView

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)isFlipped
{
    return YES;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    NSPoint locationInView = [self convertPoint:aPoint fromView:self.superview];
    BOOL containsLocation = [self mouse:locationInView inRect:self.bounds];

    if (!containsLocation)
        return [super hitTest:locationInView];
    else if (_isAnimating)
        return nil;
    else
        return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
    NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
    return [self mouse:locationInView inRect:self.bounds];
}

- (BOOL)wantsUpdateLayer
{
    return YES;
}

- (void)updateLayer
{
    self.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
}

- (void)updateConstraints
{
    if (NSWidth(_mockupFrameRatios) < _mockupMinFrameSizeRatios.width ||
        NSHeight(_mockupFrameRatios) < _mockupMinFrameSizeRatios.height)
    {
        // TODO: Log error
    }

    NSSize screenSize = [_resizingGridView drawingRectFromLayoutRect:_resizingGridView.layoutBounds].size;
    _mockupMinWidthConstraint.constant = _mockupMinFrameSizeRatios.width * screenSize.width;
    _mockupMinHeightConstraint.constant = _mockupMinFrameSizeRatios.height * screenSize.height;

    NSRect mockupFrame = NSZeroRect;

    switch (_editingMode)
    {
        case WLFrameArrangementModeResizing:
        {
            _resizingHandleLeftConstraint.constant = -_WLCellWidth;
            _resizingHandleTopConstraint.constant = -_WLCellWidth;
            _resizingHandleRightConstraint.constant = _WLCellWidth;
            _resizingHandleBottomConstraint.constant = _WLCellWidth;

            if (self.isResizing)
                mockupFrame = [_resizingGridView drawingRectFromFrameRatios:_resizingFrameRatios];
            else
                mockupFrame = [_resizingGridView drawingRectFromFrameRatios:_mockupFrameRatios];

            _mockupLeftConstraint.constant = NSMinX(mockupFrame);
            _mockupTopConstraint.constant = NSMinY(mockupFrame);
            _mockupWidthConstraint.constant = NSWidth(mockupFrame);
            _mockupHeightConstraint.constant = NSHeight(mockupFrame);

            break;
        }
        case WLFrameArrangementModePositioning:
        {
            _resizingHandleLeftConstraint.constant = 0.0;
            _resizingHandleTopConstraint.constant = 0.0;
            _resizingHandleRightConstraint.constant = 0.0;
            _resizingHandleBottomConstraint.constant = 0.0;

            if (self.isPositioning)
            {
                _mockupLeftConstraint.constant = _positioningLeftConstraint.constant;
                _mockupTopConstraint.constant = _positioningTopConstraint.constant;
            }
            else
            {
                mockupFrame = [_positioningGridView drawingRectFromFrameRatios:_mockupFrameRatios];
                _mockupLeftConstraint.constant = NSMinX(mockupFrame);
                _mockupTopConstraint.constant = NSMinY(mockupFrame);
                _mockupWidthConstraint.constant = NSWidth(mockupFrame);
                _mockupHeightConstraint.constant = NSHeight(mockupFrame);
            }

            break;
        }
    }

    [super updateConstraints];
}

- (void)resetCursorRects
{
    [super resetCursorRects];

    if (_editingMode == WLFrameArrangementModeResizing)
    {
        if (!self.isResizing)
        {
            for (WLEdge i = 0; i < WLEdgeCount; ++i)
            {
                NSRect rect = [self convertRect:[_handlesView boundsForHandle:i] fromView:_handlesView];
                rect = NSIntersectionRect(rect, self.bounds);

                if (!NSIsEmptyRect(rect))
                    [self addCursorRect:rect cursor:[NSCursor WL_cursorForEdge:i]];
            }
        }
        else
        {
            [self addCursorRect:self.bounds cursor:[NSCursor WL_cursorForEdge:_resizingHandle]];
        }
    }
}

- (void)setFrameSize:(NSSize)newSize
{
    [self resizingDidCancel];
    [self positioningDidCancel];

    if (!NSEqualSizes(self.frame.size, newSize))
        self.needsUpdateConstraints = YES;

    [super setFrameSize:newSize];
}

- (void)viewWillMoveToWindow:(NSWindow *)aWindow
{
    [self resizingDidCancel];
    [self positioningDidCancel];
    [super viewWillMoveToWindow:aWindow];
}

- (void)viewWillMoveToSuperview:(NSView *)aSuperview
{
    [self resizingDidCancel];
    [self positioningDidCancel];
    [super viewWillMoveToSuperview:aSuperview];
}

#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self resizingDidCancel];
    [self positioningDidCancel];
    return [super resignFirstResponder];
}

- (void)mouseDown:(NSEvent *)anEvent
{
    switch (_editingMode) {
        case WLFrameArrangementModeResizing:
        {
            NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
            NSPoint locationInResizeView = [_handlesView convertPoint:locationInView fromView:self];
            WLEdge handle = [_handlesView handleForLocation:locationInResizeView];

            if (handle != WLEdgeInvalid)
            {
                [self resizingDidStartAtPoint:locationInView handle:handle];
                [self resizingDidContinueAtPoint:locationInView];
                return;
            }

            break;
        }
        case WLFrameArrangementModePositioning:
        {
            NSPoint locationInMockupView = [_mockupView convertPoint:anEvent.locationInWindow fromView:nil];

            if ([_mockupView mouse:locationInMockupView inRect:_mockupView.bounds])
            {
                NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
                [self positioningDidStartAtPoint:locationInView];
                [self positioningDidContinueAtPoint:locationInView];
                return;
            }

            break;
        }
    }

    [super mouseDown:anEvent];
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    if (self.isResizing)
    {
        NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
        [self resizingDidContinueAtPoint:locationInView];
    }
    else if (self.isPositioning)
    {
        NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
        [self positioningDidContinueAtPoint:locationInView];
    }
    else
        [super mouseDragged:anEvent];
}

- (void)mouseUp:(NSEvent *)anEvent
{
    if (self.isResizing)
    {
        NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
        [self resizingDidContinueAtPoint:locationInView];
        [self resizingDidStopAtPoint:locationInView];
    }
    else if (self.isPositioning)
    {
        NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
        [self positioningDidContinueAtPoint:locationInView];
        [self positioningDidStopAtPoint:locationInView];
    }
    else
        [super mouseUp:anEvent];
}

- (void)flagsChanged:(NSEvent *)anEvent
{
    if (self.isResizing)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
        [self resizingDidContinueAtPoint:locationInView];
    }

    [super flagsChanged:anEvent];
}

@end

#pragma mark - Resizing

static NSUserInterfaceItemIdentifier const _WLAttachmentAnimationIdentifier = @"WLAttachmentAnimation";

static NSUserInterfaceItemIdentifier const _WLDetachmentAnimationIdentifier = @"WLDetachmentAnimation";


@implementation WLFrameArrangementHandlesAuxView
{
    NSImageView *_handleViews[WLEdgeCount];
    NSLayoutGuide *_handleGuides[WLEdgeCount];
}

#pragma mark Methods

- (nullable NSImageView *)viewForHandle:(WLEdge)aHandle
{
    return _handleViews[aHandle];
}

- (WLEdge)handleForLocation:(NSPoint)aPoint
{
    for (WLEdge i = 0; i < WLEdgeCount; ++i)
    {
        if ([self mouse:aPoint inRect:_handleGuides[i].frame])
            return i;
    }

    return WLEdgeInvalid;
}

- (NSRect)boundsForHandle:(WLEdge)aHandle
{
    if (aHandle == WLEdgeInvalid)
        return NSZeroRect;

    return _handleGuides[aHandle].frame;
}

- (NSImageView *)makeHandleView:(WLEdge)aHandle
{
    NSImageView *v = [NSImageView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    switch (aHandle)
    {
        case WLEdgeTopLeft:
            v.image = [NSImage imageNamed:@"preferences-positioning-mockup-handle-top-left"];
            break;
        case WLEdgeTopRight:
            v.image = [NSImage imageNamed:@"preferences-positioning-mockup-handle-top-right"];
            break;
        case WLEdgeBottomLeft:
            v.image = [NSImage imageNamed:@"preferences-positioning-mockup-handle-bottom-left"];
            break;
        case WLEdgeBottomRight:
            v.image = [NSImage imageNamed:@"preferences-positioning-mockup-handle-bottom-right"];
            break;
        case WLEdgeTop:
        case WLEdgeBottom:
            v.image = [NSImage imageNamed:@"preferences-positioning-mockup-handle-horizontal"];
            break;
        case WLEdgeLeft:
        case WLEdgeRight:
            v.image = [NSImage imageNamed:@"preferences-positioning-mockup-handle-vertical"];
            break;
        case WLEdgeCenter:
            NSParameterAssert(NO);
            break;
    }
    v.editable = NO;
    v.imageScaling = NSImageScaleAxesIndependently;
    v.imageAlignment = NSImageAlignCenter;
    v.imageFrameStyle = NSImageFrameNone;
    return v;
}

#pragma mark WLLayerBackedView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;

    for (WLEdge i = 0; i < WLEdgeCount; ++i)
    {
        _handleGuides[i] = [NSLayoutGuide new];
        [self addLayoutGuide:_handleGuides[i]];

        if (i != WLEdgeCenter)
        {
            _handleViews[i] = [self makeHandleView:i];
            [self addSubview:_handleViews[i]];
        }
    }

    NSDictionary *views = @{
        @"topLeftView": _handleViews[WLEdgeTopLeft],
        @"topCenterView": _handleViews[WLEdgeTop],
        @"topRightView": _handleViews[WLEdgeTopRight],
        @"centerLeftView": _handleViews[WLEdgeLeft],
        @"centerRightView": _handleViews[WLEdgeRight],
        @"bottomLeftView": _handleViews[WLEdgeBottomLeft],
        @"bottomCenterView": _handleViews[WLEdgeBottom],
        @"bottomRightView": _handleViews[WLEdgeBottomRight],

        @"topLeftGuide": _handleGuides[WLEdgeTopLeft],
        @"topCenterGuide": _handleGuides[WLEdgeTop],
        @"topRightGuide": _handleGuides[WLEdgeTopRight],
        @"centerLeftGuide": _handleGuides[WLEdgeLeft],
        @"centerCenterGuide": _handleGuides[WLEdgeCenter],
        @"centerRightGuide": _handleGuides[WLEdgeRight],
        @"bottomLeftGuide": _handleGuides[WLEdgeBottomLeft],
        @"bottomCenterGuide": _handleGuides[WLEdgeBottom],
        @"bottomRightGuide": _handleGuides[WLEdgeBottomRight]
    };

    NSDictionary *metrics = @{
        @"w": @(_WLCellWidth)
    };

    __auto_type AddConstraints = ^(NSString *aFormat, NSLayoutFormatOptions anOptions) {
        NSArray *c = [NSLayoutConstraint constraintsWithVisualFormat:aFormat options:anOptions metrics:metrics views:views];
        [NSLayoutConstraint activateConstraints:c];
        return c;
    };

    AddConstraints(@"H:|[topLeftGuide(w)][topCenterGuide(>=w)][topRightGuide(w)]|", 0);
    AddConstraints(@"H:|[centerLeftGuide(w)][centerCenterGuide(>=w)][centerRightGuide(w)]|", 0);
    AddConstraints(@"H:|[bottomLeftGuide(w)][bottomCenterGuide(>=w)][bottomRightGuide(w)]|", 0);
    AddConstraints(@"V:|[topLeftGuide(w)][centerLeftGuide(>=w)][bottomLeftGuide(w)]|", 0);
    AddConstraints(@"V:|[topCenterGuide(w)][centerCenterGuide(>=w)][bottomCenterGuide(w)]|", 0);
    AddConstraints(@"V:|[topRightGuide(w)][centerRightGuide(>=w)][bottomRightGuide(w)]|", 0);

    static const CGFloat HandleOffset = (_WLCellWidth + _WLBorderWidth) / 2.0;

    AddConstraints(@"H:|-(>=0)-[topLeftView]-(>=0)-[topCenterView]-(>=0)-[topRightView]-(>=0)-|", NSLayoutFormatAlignAllTop);
    AddConstraints(@"H:|-(>=0)-[bottomLeftView]-(>=0)-[bottomCenterView]-(>=0)-[bottomRightView]-(>=0)-|", NSLayoutFormatAlignAllBottom);
    AddConstraints(@"V:|-(>=0)-[topLeftView]-(>=0)-[centerLeftView]-(>=0)-[bottomLeftView]-(>=0)-|", NSLayoutFormatAlignAllLeft);
    AddConstraints(@"V:|-(>=0)-[topRightView]-(>=0)-[centerRightView]-(>=0)-[bottomRightView]-(>=0)-|", NSLayoutFormatAlignAllRight);
    [NSLayoutConstraint activateConstraints:@[
        [[views[@"centerLeftView"] centerXAnchor] constraintEqualToAnchor:self.leftAnchor constant:HandleOffset],
        [[views[@"centerLeftView"] centerYAnchor] constraintEqualToAnchor:self.centerYAnchor],

        [[views[@"topCenterView"] centerXAnchor] constraintEqualToAnchor:self.centerXAnchor],
        [[views[@"topCenterView"] centerYAnchor] constraintEqualToAnchor:self.topAnchor constant:HandleOffset],

        [[views[@"centerRightView"] centerXAnchor] constraintEqualToAnchor:self.rightAnchor constant:-HandleOffset],
        [[views[@"centerRightView"] centerYAnchor] constraintEqualToAnchor:self.centerYAnchor],

        [[views[@"bottomCenterView"] centerXAnchor] constraintEqualToAnchor:self.centerXAnchor],
        [[views[@"bottomCenterView"] centerYAnchor] constraintEqualToAnchor:self.bottomAnchor constant:-HandleOffset]
    ]];
}

#pragma mark NSView

- (BOOL)isOpaque
{
    return NO;
}

- (BOOL)wantsUpdateLayer
{
    return YES;
}

- (void)updateLayer
{
    self.layer.borderWidth = _WLBorderWidth;
    self.layer.borderColor = NSColor.whiteColor.CGColor;
    self.layer.cornerRadius = _WLBorderRadius;
}

@end


@implementation WLFrameArrangementResizingGridAuxView

#pragma mark Properties

+ (NSSet<NSString *> *)keyPathsForValuesAffectingLayoutBounds
{
    return [NSSet setWithObject:@"bounds"];
}

- (NSRect)layoutBounds
{
    return NSMakeRect(0.0, 0.0, NSWidth(self.bounds) + _WLGridLineWidth, NSHeight(self.bounds) + _WLGridLineWidth);
}

#pragma mark Methods

- (NSRect)gridSnappedLayoutRect:(NSRect)aRect
                    withOptions:(NSAlignmentOptions)anOptions
                        minSize:(NSSize)aMinSize
                           edge:(WLEdge)anEdge
{
    NSRect snappedRect = WLConstrainedIntegralRect(aRect,
                                                   anOptions | WLAlignTiebreakerInward | NSAlignRectFlipped,
                                                   _WLCellWidth / 2.0,
                                                   aMinSize,
                                                   anEdge);
    return snappedRect;
}

- (NSRect)layoutRectFromFrameRatios:(NSRect)aFrameRatios
{
    NSRect layoutBounds = self.layoutBounds;
    NSRect layoutRect = NSMakeRect(NSMinX(aFrameRatios) * NSWidth(layoutBounds),
                                   NSMinY(aFrameRatios) * NSHeight(layoutBounds),
                                   NSWidth(aFrameRatios) * NSWidth(layoutBounds),
                                   NSHeight(aFrameRatios) * NSHeight(layoutBounds));
    layoutRect = [self backingAlignedRect:layoutRect options:NSAlignAllEdgesNearest];
    return layoutRect;
}

- (NSRect)drawingRectFromFrameRatios:(NSRect)aFrameRatios
{
    return [self drawingRectFromLayoutRect:[self layoutRectFromFrameRatios:aFrameRatios]];
}

- (NSRect)frameRatiosFromLayoutRect:(NSRect)aLayoutRect
{
    NSRect layoutBounds = self.layoutBounds;
    return NSMakeRect(NSMinX(aLayoutRect) / NSWidth(layoutBounds),
                      NSMinY(aLayoutRect) / NSHeight(layoutBounds),
                      NSWidth(aLayoutRect) / NSWidth(layoutBounds),
                      NSHeight(aLayoutRect) / NSHeight(layoutBounds));
}

- (NSRect)drawingRectFromLayoutRect:(NSRect)aLayoutRect
{
    // See the comment in -layoutRectFromDrawingRect:

    NSRect drawingBounds = self.bounds;
    NSRect borderlessLayoutBounds = NSInsetRect(self.layoutBounds, _WLGridLineWidth, _WLGridLineWidth);
    NSRect localRect = NSZeroRect;

    if (NSMinX(aLayoutRect) > NSMinX(borderlessLayoutBounds))
        localRect.origin.x = NSMinX(aLayoutRect) - _WLGridLineWidth;
    else
        localRect.origin.x = NSMinX(drawingBounds);

    if (NSMinY(aLayoutRect) > NSMinY(borderlessLayoutBounds))
        localRect.origin.y = NSMinY(aLayoutRect) - _WLGridLineWidth;
    else
        localRect.origin.y = NSMinY(drawingBounds);

    if (NSMaxX(aLayoutRect) < NSMaxX(borderlessLayoutBounds))
        localRect.size.width = NSMaxX(aLayoutRect) - NSMinX(localRect);
    else
        localRect.size.width = NSMaxX(drawingBounds) - NSMinX(localRect);

    if (NSMaxY(aLayoutRect) < NSMaxY(borderlessLayoutBounds))
        localRect.size.height = NSMaxY(aLayoutRect) - NSMinY(localRect);
    else
        localRect.size.height = NSMaxY(drawingBounds) - NSMinY(localRect);

    return localRect;
}

- (NSRect)layoutRectFromDrawingRect:(NSRect)aDrawingRect
{
    // Drawing gridline is always located at the last _WLGridLineWidth points of a grid cell.
    //
    // Location of the layout gridline depends on the edge:
    //  - For MinX and MinY it's the first _WLGridLineWidth points of the cell
    //  - For MaxX and MaxY it's the last _WLGridLineWidth points of the cell
    //
    // Adjustment therefore depends on the exact location of aDrawingRect with respect to grid cells.

    NSRect drawingBounds = self.bounds;
    NSRect layoutBounds = self.layoutBounds;
    aDrawingRect = NSIntersectionRect(aDrawingRect, drawingBounds);
    NSRect layoutRect = aDrawingRect;

    if (NSMinX(aDrawingRect) == NSMinX(drawingBounds))
    {
        layoutRect.origin.x = NSMinX(layoutBounds);
        layoutRect.size.width = NSWidth(layoutRect) - _WLGridLineWidth;
    }
    else
    {
        layoutRect.origin.x += _WLGridLineWidth;
        layoutRect.size.width -= _WLGridLineWidth;
    }

    if (NSMaxX(aDrawingRect) == NSMaxX(drawingBounds))
        layoutRect.size.width = NSMaxX(layoutBounds) - NSMinX(layoutRect);

    if (NSMinY(aDrawingRect) == NSMinY(drawingBounds))
    {
        layoutRect.origin.y = NSMinY(layoutBounds);
        layoutRect.size.height = NSHeight(layoutRect) - _WLGridLineWidth;
    }
    else
    {
        layoutRect.origin.y += _WLGridLineWidth;
        layoutRect.size.height -= _WLGridLineWidth;
    }

    if (NSMaxY(aDrawingRect) == NSMaxY(drawingBounds))
        layoutRect.size.height = NSMaxY(layoutBounds) - NSMinY(layoutRect);

    return layoutRect;
}

- (NSSize)drawingAlignedFrameSize:(NSSize)aSize
{
    return NSMakeSize(_WLCellWidth * ceil(aSize.width / _WLCellWidth) - _WLGridLineWidth,
                      _WLCellWidth * ceil(aSize.height / _WLCellWidth) - _WLGridLineWidth);
}

#pragma mark WLLayerBackedView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
}

#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    NSRect userBounds = self.bounds;

    if (NSIsEmptyRect(userBounds))
        return;

    static NSImage *PatternImage = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        PatternImage = [NSImage imageWithSize:NSMakeSize(_WLCellWidth, _WLCellWidth)
                                      flipped:NO
                               drawingHandler:^BOOL (NSRect dstRect)
        {
            [NSGraphicsContext saveGraphicsState];
            CGContextRef context = NSGraphicsContext.currentContext.CGContext;
            CGContextSetShouldAntialias(context, NO);
            CGContextSetLineWidth(context, _WLGridLineWidth);

            NSRect deviceBounds = CGContextConvertRectToDeviceSpace(context, userBounds);
            CGFloat scaleFactor = NSHeight(deviceBounds) / NSHeight(userBounds);

            // Make sure the guide pixels are drawn exactly at the end of the cell:
            // @1x: [ ] [x] [ ]
            //         ^
            // @2x: [ ] [ ] [x] [x] [ ] [ ]
            //                 ^
            CGFloat offset = scaleFactor == 1.0 ? 0.0 : _WLGridLineWidth / 2.0;

            CGContextSetStrokeColorWithColor(context, [NSColor.whiteColor colorWithAlphaComponent:0.5].CGColor);
            CGContextMoveToPoint(context, offset, 0.0);
            CGContextAddLineToPoint(context, offset, _WLCellWidth);
            CGContextMoveToPoint(context, 0.0, offset);
            CGContextAddLineToPoint(context, _WLCellWidth, offset);
            CGContextStrokePath(context);

            CGContextSetStrokeColorWithColor(context, [NSColor.whiteColor colorWithAlphaComponent:0.25].CGColor);
            CGContextMoveToPoint(context, _WLCellWidth / 2.0 + offset, _WLGridLineWidth);
            CGContextAddLineToPoint(context, _WLCellWidth / 2.0 + offset, _WLCellWidth);
            CGContextMoveToPoint(context, _WLGridLineWidth, _WLCellWidth / 2.0 + offset);
            CGContextAddLineToPoint(context, _WLCellWidth, _WLCellWidth / 2.0 + offset);
            CGContextStrokePath(context);
            [NSGraphicsContext restoreGraphicsState];

            return YES;
        }];
    });

    NSColor *patternColor = [NSColor colorWithPatternImage:PatternImage];
    [patternColor setFill];
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    NSPoint bottomLeftInWindow = [self convertPoint:NSMakePoint(NSMinX(self.bounds), NSMaxY(self.bounds)) toView:nil];
    // First make sure that the pattern is aligned with the bottom-left corner of the view.
    // Then offset the phase to hide part of the border that is adjacent to view's bounds.
    NSSize phase = NSMakeSize(remainder(bottomLeftInWindow.x, PatternImage.size.width) - _WLGridLineWidth,
                              remainder(bottomLeftInWindow.y, PatternImage.size.height) - _WLGridLineWidth);
    CGContextSetPatternPhase(context, phase);
    NSRectFill(self.bounds);
}

@end

#pragma mark - Positioning

// [x][x]
static const CGFloat _WLGuideLineLength = 2.0;

// [ ][ ][ ]
static const CGFloat _WLGuideGapLength = 3.0;

// [x][x][ ][ ][ ]
static const CGFloat _WLGuidePatternLength = _WLGuideLineLength + _WLGuideGapLength;

static const CGFloat _WLGuideLineWidth = _WLGuideLineLength / 2.0;

static const CGFloat _WLGuideViewSpacing = 10.0;


@implementation WLFrameArrangementPositioningGridAuxView
{
    NSBox *_guideViews[BLPositionCount];
    BLPosition _highlightedPosition;
}

#pragma mark Methods

- (NSView *)makeGuideView
{
    NSBox *v = [NSBox new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.boxType = NSBoxCustom;
    v.titlePosition = NSNoTitle;
    v.fillColor = [NSColor.blackColor colorWithAlphaComponent:0.1];
    v.borderWidth = 0.0;
    return v;
}

- (NSSize)drawingAlignedFrameSize:(NSSize)aSize
{
    // Size is adjusted so that pattern around the guide views can be drawn perfectly.
    NSSize contentSize = NSMakeSize(fdim(aSize.width, 4.0 * _WLGuideViewSpacing),
                                    fdim(aSize.height, 4.0 * _WLGuideViewSpacing));
    CGFloat guideWidth = round((contentSize.width / 3.0) / _WLGuidePatternLength) * _WLGuidePatternLength + _WLGuideLineLength;
    CGFloat guideHeight = round((contentSize.height / 3.0) / _WLGuidePatternLength) * _WLGuidePatternLength + _WLGuideLineLength;
    return NSMakeSize(3.0 * guideWidth + 4.0 * _WLGuideViewSpacing,
                      3.0 * guideHeight + 4.0 * _WLGuideViewSpacing);
}

- (BLPosition)positionForPoint:(NSPoint)aPoint
{
    NSRect bounds = self.bounds;

    NSPoint topLeftThird = NSMakePoint(NSMinX(bounds) + NSWidth(bounds) / 3.0,
                                       NSMinY(bounds) + NSHeight(bounds) / 3.0);
    NSPoint topRightThird = NSMakePoint(NSMinX(bounds) + 2.0 * NSWidth(bounds) / 3.0,
                                        NSMinY(bounds) + NSHeight(bounds) / 3.0);

    if (aPoint.x < topLeftThird.x && aPoint.y < topLeftThird.y)
        return BLPositionTopLeft;
    else if (aPoint.x < topRightThird.x && aPoint.y < topRightThird.y)
        return BLPositionTopCenter;
    else if (aPoint.x >= topRightThird.x && aPoint.y < topRightThird.y)
        return BLPositionTopRight;

    NSPoint bottomLeftThird = NSMakePoint(NSMinX(bounds) + NSWidth(bounds) / 3.0,
                                          NSMinY(bounds) + 2.0 * NSHeight(bounds) / 3.0);
    NSPoint bottomRightThird = NSMakePoint(NSMinX(bounds) + 2.0 * NSWidth(bounds) / 3.0,
                                           NSMinY(bounds) + 2.0 * NSHeight(bounds) / 3.0);

    if (aPoint.x < bottomLeftThird.x && aPoint.y < bottomLeftThird.y)
        return BLPositionCenterLeft;
    else if (aPoint.x < bottomRightThird.x && aPoint.y < bottomRightThird.y)
        return BLPositionCenterCenter;
    else if (aPoint.x >= bottomRightThird.x && aPoint.y < bottomRightThird.y)
        return BLPositionCenterRight;
    else if (aPoint.x < bottomLeftThird.x && aPoint.y >= bottomLeftThird.y)
        return BLPositionBottomLeft;
    else if (aPoint.x < bottomRightThird.x && aPoint.y >= bottomLeftThird.y)
        return BLPositionBottomCenter;
    else // if (aPoint.x >= bottomRightThird.x && aPoint.y >= bottomLeftThird.y)
        return BLPositionBottomRight;
}

- (NSRect)drawingRectFromFrameRatios:(NSRect)aFrameRatios
{
    NSRect bounds = self.bounds;
    return NSMakeRect(NSMinX(aFrameRatios) * NSWidth(bounds),
                      NSMinY(aFrameRatios) * NSHeight(bounds),
                      NSWidth(aFrameRatios) * NSWidth(bounds),
                      NSHeight(aFrameRatios) * NSHeight(bounds));
}

- (void)highlightPosition:(BLPosition)aPosition animated:(BOOL)anIsAnimated
{
    if (aPosition == _highlightedPosition)
        return;

    _highlightedPosition = aPosition;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        context.duration = anIsAnimated ? 0.15 : 0.0;

        for (BLPosition position = 0; position < BLPositionCount; ++position)
        {
            if (position == _highlightedPosition)
                _guideViews[position].animator.fillColor = [NSColor.blackColor colorWithAlphaComponent:0.5];
            else
                _guideViews[position].animator.fillColor = [NSColor.blackColor colorWithAlphaComponent:0.1];
        }
    } completionHandler:nil];
}

#pragma mark WLLayerBackedView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;

    for (BLPosition position = 0; position < BLPositionCount; ++position)
    {
        __auto_type v = [self makeGuideView];
        [self addSubview:v];
        _guideViews[position] = v;
    }

    NSStackView *topView = [NSStackView stackViewWithViews:@[
        _guideViews[BLPositionTopLeft],
        _guideViews[BLPositionTopCenter],
        _guideViews[BLPositionTopRight],
    ]];
    topView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    topView.spacing = _WLGuideViewSpacing + 2.0 * _WLGuideLineWidth;
    topView.distribution = NSStackViewDistributionFillEqually;

    NSStackView *centerView = [NSStackView stackViewWithViews:@[
        _guideViews[BLPositionCenterLeft],
        _guideViews[BLPositionCenterCenter],
        _guideViews[BLPositionCenterRight],
    ]];
    centerView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    centerView.spacing = _WLGuideViewSpacing + 2.0 * _WLGuideLineWidth;
    centerView.distribution = NSStackViewDistributionFillEqually;

    NSStackView *bottomView = [NSStackView stackViewWithViews:@[
        _guideViews[BLPositionBottomLeft],
        _guideViews[BLPositionBottomCenter],
        _guideViews[BLPositionBottomRight],
    ]];
    bottomView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    bottomView.spacing = _WLGuideViewSpacing + 2.0 * _WLGuideLineWidth;
    bottomView.distribution = NSStackViewDistributionFillEqually;

    NSStackView *verticalView = [NSStackView new];
    verticalView.translatesAutoresizingMaskIntoConstraints = NO;
    verticalView.orientation = NSUserInterfaceLayoutOrientationVertical;
    verticalView.spacing = _WLGuideViewSpacing + 2.0 * _WLGuideLineWidth;
    verticalView.distribution = NSStackViewDistributionFillEqually;
    verticalView.edgeInsets = NSEdgeInsetsMake(_WLGuideViewSpacing + _WLGuideLineWidth,
                                               _WLGuideViewSpacing + _WLGuideLineWidth,
                                               _WLGuideViewSpacing + _WLGuideLineWidth,
                                               _WLGuideViewSpacing + _WLGuideLineWidth);
    [verticalView setViews:@[topView, centerView, bottomView] inGravity:NSStackViewGravityTop];

    [self addSubview:verticalView];
    [NSLayoutConstraint activateConstraints:@[
        [verticalView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [verticalView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [verticalView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [verticalView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    NSRect userBounds = self.bounds;

    if (NSIsEmptyRect(userBounds))
        return;

    CGContextRef cgContext = NSGraphicsContext.currentContext.CGContext;

    [NSColor.clearColor setFill];
    NSRectFill(aDirtyRect);

    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = _WLGuideLineWidth;
    path.lineCapStyle = NSLineCapStyleButt;
    CGFloat pattern[] = {2.0, 3.0};
    [path setLineDash:pattern count:sizeof(pattern) / sizeof(CGFloat) phase:0.0];

    NSRect deviceBounds = CGContextConvertRectToDeviceSpace(cgContext, userBounds);
    CGFloat scaleFactor = NSHeight(deviceBounds) / NSHeight(userBounds);

    // Core graphics coordinate points between pixels:
    // @1x: [x] [|]
    //     ^
    //
    // @2x: [x] [x] [|]
    //      [x] [x] [|]
    //         ^
    CGFloat pixelDrawingOffset = scaleFactor == 1.0 ? _WLGuideLineWidth : _WLGuideLineWidth / 2.0;

    for (BLPosition position = 0; position < BLPositionCount; ++position)
    {
        __auto_type guide = _guideViews[position];
        NSRect guideFrameInView = [self convertRect:guide.bounds fromView:guide];
        NSRect guideFrameInViewWithFrame = NSInsetRect(guideFrameInView, -_WLGuideLineWidth, -_WLGuideLineWidth);

        if (![self needsToDrawRect:guideFrameInViewWithFrame])
            continue;

        // Draw left border.
        [path moveToPoint:NSMakePoint(NSMinX(guideFrameInView) - pixelDrawingOffset, NSMinY(guideFrameInView) - _WLGuideLineLength / 2.0)];
        [path relativeLineToPoint:NSMakePoint(0.0, NSHeight(guideFrameInView) + _WLGuideLineLength)];

        // Draw top border.
        [path moveToPoint:NSMakePoint(NSMinX(guideFrameInView) - _WLGuideLineLength / 2.0, NSMinY(guideFrameInView) - pixelDrawingOffset)];
        [path relativeLineToPoint:NSMakePoint(NSWidth(guideFrameInView) + 2.0 * _WLGuideLineLength, 0.0)];

        // Draw right border.
        [path moveToPoint:NSMakePoint(NSMaxX(guideFrameInView) + pixelDrawingOffset, NSMinY(guideFrameInView) - _WLGuideLineLength / 2.0)];
        [path relativeLineToPoint:NSMakePoint(0.0, NSHeight(guideFrameInView) + 2.0 * _WLGuideLineLength)];

        // Draw bottom border.
        [path moveToPoint:NSMakePoint(NSMinX(guideFrameInView) - _WLGuideLineLength / 2.0, NSMaxY(guideFrameInView) + pixelDrawingOffset)];
        [path relativeLineToPoint:NSMakePoint(NSWidth(guideFrameInView) + 2.0 * _WLGuideLineLength, 0.0)];
    }

    CGContextSetShouldAntialias(cgContext, NO);
    [[NSColor.whiteColor colorWithAlphaComponent:0.9] setStroke];
    [path stroke];
}

@end

#pragma mark -

@implementation NSCursor (WLFrameArrangementView)

+ (NSCursor *)WL_cursorForEdge:(WLEdge)anEdge
{
    switch (anEdge)
    {
        case WLEdgeTopLeft:
            return [NSCursor WL_resizeUpLeftCursor];
        case WLEdgeTop:
            return [NSCursor WL_resizeUpDownCursor];
        case WLEdgeTopRight:
            return [NSCursor WL_resizeUpRightCursor];
        case WLEdgeLeft:
            return [NSCursor WL_resizeLeftRightCursor];
        case WLEdgeCenter:
            return [NSCursor openHandCursor];
        case WLEdgeRight:
            return [NSCursor WL_resizeLeftRightCursor];
        case WLEdgeBottomLeft:
            return [NSCursor WL_resizeDownLeftCursor];
        case WLEdgeBottom:
            return [NSCursor WL_resizeUpDownCursor];
        case WLEdgeBottomRight:
            return [NSCursor WL_resizeDownRightCursor];
        default:
            return [NSCursor arrowCursor];
    }
}

+ (NSCursor *)WL_cursorFromImage:(NSString *)aFilename
{
    NSImage *i = [NSImage imageNamed:aFilename];
    return [[NSCursor alloc] initWithImage:i hotSpot:NSMakePoint(i.size.width / 2, i.size.height / 2)];
}

+ (NSCursor *)WL_resizeDownLeftCursor {
    static dispatch_once_t onceToken;
    static NSCursor *DownLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        DownLeftCursor = [self WL_cursorFromImage:@"cursor-resize-northeastsouthwest"];
    });
    return DownLeftCursor;
}

+ (NSCursor *)WL_resizeDownRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *DownRightCursor = nil;
    dispatch_once(&onceToken, ^{
        DownRightCursor = [self WL_cursorFromImage:@"cursor-resize-northwestsoutheast"];
    });
    return DownRightCursor;
}

+ (NSCursor *)WL_resizeLeftRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [self WL_cursorFromImage:@"cursor-resize-eastwest"];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpDownCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [self WL_cursorFromImage:@"cursor-resize-northsouth"];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpLeftCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [self WL_cursorFromImage:@"cursor-resize-northwestsoutheast"];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpRightCursor = nil;
    dispatch_once(&onceToken, ^{
        UpRightCursor = [self WL_cursorFromImage:@"cursor-resize-northeastsouthwest"];
    });
    return UpRightCursor;
}

@end

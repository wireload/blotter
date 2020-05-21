//
//  WLLayerHostedView.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 @file
 Properties of view's layer that are still managed by AppKit:
    Mac OS X 10.8+:
        - geometryFlipped
        - bounds
        - frame
        - position
        - anchorPoint
        - transform
        - shadow[Color, Offset, Opacity, Radius, Path]
        - hidden
        - filters
        - compositingFilter

    macOS 10.13+:
        - zPosition
        - anchorPointZ
        - affineTransform
        - masksToBounds
        - opaque
        - layoutManager

 Layout:
    - View must use -setNeedsUpdateConstraints: to ensure that -updateConstraints will get called before the layout pass
    - If there are no constraints yet and no views in the hierarchy return YES from +requiresConstraintBasedLayout,
        it is still possible for -updateConstraints to get called when Auto Layout is not yet set up.
        The view thus must not imply that Auto Layout is enabled. (macOS 10.13 Release Notes)
    - If -updateConstraints is implemented but +requiresConstraintBasedLayout is not, starting with 10.12 AppKit
        will consider that view requires constrains and will enable Auto Layout (macOS 10.12 Release Notes)
    - To update constraints during live resize, override -updateConstraints and then call -setNeedsUpdateConstraints:
        when necessary (macOS 10.12 Release Notes)
    - View must use -setNeedsLayout: to ensure that -layout will get called during the layout pass
    - -layout is called for layer-backed views that responded YES for -wantsUpdateLayer even outside of Auto Layout
        and can be used to modify the view hierarchy (macOS 10.8 Release Notes)
    - Sublayers of view's layer appear behind subviews (macOS 10.13 Release Notes)
    - Layout is applied in deferred manner; view cannot rely on the frames of any subviews inside -layout
        To circumvent call -layoutSubtreeIfNeeded
    - Avoid adding and removing constraints; activate and deactivate them instead (Mac OS X 10.10 Release Notes)
    - Use integral values for width and height of sublayers (Core Animation Programming Guide - Positioning and Sizing Sublayers)
    - Overriding -[CALayer layoutSublayers] prevernts CoreAnimation to use its constraints and autoresizing masks (Core Animation Programming Guide)
    - In layer-backed views, view's coordinates match layer's coordinates

 Drawing:
    - It is recommended to mark window's contentView as layer-backed so that all subviews can inherit it
    - Overriding -makeBackingLayer to return custom view effectively makes view layer-hosting
    - Starting with 10.13 if an NSView does not explicitly set the -wantsLayer property, AppKit determines in runtime
      whether the view actually gets a dedicated layer or shares a layer with other siblings and/or ancestors.
      To benefit from this behavior the view must implement both -updateLayer and -draw:
      (macOS 10.13 Release Notes)
    - Starting with 10.14 an NSView should generally avoid setting the -wantsLayer property and use -wantsUpdateLayer instead
      (macOS 10.14 Release Notes, WWDC 2018, Session 209)
    - -canDrawConcurrently has no effect on layer-hosting views and views with any of its ancestors having
        -canDrawSubviewsIntoLayer set (based on the private -[NSView _reallyCanDrawConcurrently])
    - -canDrawSubviewsIntoLayer make view and all its descendants to ignore wantsUpdateLayer and updateLayer (docs)
    - -canDrawSubviewsIntoLayer requires layerContentsRedrawPolicy to not be NSViewLayerContentsRedrawNever (Mac OS X 10.10 Release Notes)
    - Layers with directly attached filters require hosting view to have layerUsesCoreImageFilters being set;
        filters attached to the hosting view do not require this property to be set (Mac OS X 10.9 Release Notes)
    - When -isOpaque returns NO view will have LCD smoothing disabled; to re-enable use CGContextSetShouldSmoothFonts before drwaing (Mac OS X 10.8 Release Notes)
    - NSTextField magically smoothes text even when background is opaque (WWDC 2012, Session 217)
    - Override -preservesContentDuringLiveResize to return YES and -setFrameSize: to manually mark areas that needs display
    - -setNeedsDisplay: does not invalidate overlapping views (both subviews and siblings) (WWDC 2012, Session 217)
    - Consider changing -layerContentsRedrawPolicy to other than NSViewLayerContentsRedrawDuringViewResize
    - -[CALayer contentsCenter] can be used for tiling
    - Live resize drawing can be optimized by enabling preservesContentDuringLiveResize and manually invalidating
        areas (View Programming Guide - Optimizing View Drawing - Preserve Window Content)
    - Core Graphics coordinates point between pixels; e.g. (0, 0) point top-left or bottom right "border"
        depending on whether context is flipped
    - When coordinate does not fall exactly between pixels and antialiasing is disabled position is rounded towards
        native Core Graphics axes: towards top and towards right
    - When line width is odd and antialiasing is disabled it is rounded up so that
        equal number of pixels are drawn to the left and to the right of the coordinate

 Animation:
    - +[NSAnimationContext beginGrouping] / +[NSAnimationContext endGrouping] properly sync with Core Animation
        starting with Mac OS X 10.11 (Mac OS X 10.11 Release Notes)
    - If layerContentsRedrawPolicy is set to NSViewLayerContentsRedrawOnSetNeedsDisplay, then AppKit does not call
        setFrameSize: repeatedly but utilizes CoreAnimation instead; it's true for other properties too
        will implication that during the animation view's properties would return the final values (Mac OS X 10.8 Release Notes)
    - -[NSAnimationContext allowsImplicitAnimation] is automatically set to YES when the animator proxy is used;
        to opt out create an animation group and set this property to NO explicitly (Mac OS X 10.8 Release Notes)
    - -[NSAnimationContext allowsImplicitAnimation] only works for some properties (WWDC 2013, Session 213)
    - -[NSAnimationContext allowsImplicitAnimation] has no effect on -[NSLayoutConstraint constant]
    - Changes may be coaslesced if view did not have a chance to display; either specify changes in
        the separate animation group or by setting initial value explicitly in CAAnimation (Mac OS X 10.8 Release Notes)
    - Set the NSAnimationSlowMotionOnShift default to YES to slow down most of the animations for debugging

 Don't(s):
    - Don't call -[CALayer setDelegate:] of view's layer unless it's custom (either assigned directly via -[NSView setLayer:]
        or by returning a custom layer from -[NSView makeBackingLayer] (macOS 10.13 Release Notes)
    - Don't modify the layoutManager property of view's layer: behavior is undefined (macOS 10.13 Release Notes)
    - Don't modify geometry of view's layer (of any view!) in -[CALayer layoutSublayers]
        or -[CALayerDelegate layoutSublayersOfLayer:]. Use -[NSView layout] instead and use only
        NSView's properties (macOS 10.13 Release Notes)
    - Don't set -needsLayout from -layout: it will result in the second layout pass (macOS 10.12 Release Notes)
    - Don't invalidate constraints from -layout
    - Don't use resizeSubviewsWithOldSize:/resizeWithOldSuperviewSize: when using constraint-based layout (macOS 10.12 Release Notes)

 Known AppKit Bugs:
    all:
        - layer's bounds cannot be animated to a negative size even for additive animations;
          animate layer's bounds.size instead (http://www.openradar.me/12085417)
    macOS 10.13-:
        - view's layer erroneously received -viewWillDraw (macOS 10.13 Release Notes)
        - constraints could be updated for only a portion of view's hierarchy before performing layout
            i.e. some constraints might be deferred beyond -layoutSubtreeIfNeeded (macOS 10.13 Release Notes)
    macOS 10.12-:
        - CoreAnimation triggered -[NSView layout] out of band with the rest of layout passes masking
            missing needsLayout = YES (macOS 10.12 Release Notes)
        - Changing view's frame size didn't set needsLayout (macOS 10.12 Release Notes, addressed by WLLayerView)
    macOS 10.8-:
        - Returning NSNull from -[CALayer animationForKey:] / -[CALayer defaultAnimationForKey] incorrectly caused
            the default animation to happen (Mac OS X 10.9 Release Notes)
        - -[CALayer layer:shouldInheritContentsScale:fromWindow:] returning YES invalidate display of NSView, not layer
        - Even with layerContentsRedrawPolicy set to NSViewLayerContentsRedrawOnSetNeedsDisplay, view and layer could
            still be incorrectly invalidated on frame changes (Mac OS X 10.8 Release Notes)

 Debugging Tricks:
    macOS 10.12+:
        - Set NSViewLayoutFeedbackLoopDebuggingThreshold # to debug layout loops (macOS 10.12 Release Notes)
        - Use `po [_NSViewLayoutFeedbackLoopDebugger layoutFeedbackLoopDebugger]` to print info about layout loops in the debugger (WWDC 2016, Session 236)
        - Set NSViewLayoutStrictMode YES to detect redundant layouts;
            additionally set NSViewLayoutStrictModeThrowsException YES to throw an exception (macOS 10.12 Release Notes)
    macOS 10.7+:
        - Set NSViewRaiseOnInvalidFrames to detect invalid frame origins and sizes
        - Use the -[NSLayoutConstraint asciiArtDescription] method to log constraint's description

 Performance Tricks:
    macos 10.15+:
        - Subclasses of NSView that calculate custom intrinsic sizes can signal to the layout engine that
          it should ignore them by setting the horizontalContentSizeConstraintActive / verticalContentSizeConstraintActive
          properties to win some performance when external constraints determine view's size

 @see Core Animation Programming Guide: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/
 @see High Resolution Guidelines for OS X: https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Introduction/Introduction.html#//apple_ref/doc/uid/TP40012302-CH1-SW1
 @see WWDC 2012, Session 217: https://developer.apple.com/videos/play/wwdc2012/217/
 @see WWDC 2013, Session 213: https://developer.apple.com/videos/play/wwdc2013/213/
 @see WWDC 2018, Session 209: https://developer.apple.com/videos/play/wwdc2018/209/
 */

@interface NSView (WLLayerView)

/*!
 For macOS 10.11 and below invalidate the layout.
 */
- (void)WL_setFrameSize:(NSSize)newSize NS_REQUIRES_SUPER;

/*!
 For macOS 10.11 and below invalidate the layout.
*/
- (void)WL_setBoundsSize:(NSSize)newSize NS_REQUIRES_SUPER;

@end


@interface _WLLayerView : NSView

/*!
 Overridden to use -WL_setFrameSize:
 */
- (void)setFrameSize:(NSSize)newSize NS_REQUIRES_SUPER;

/*!
Overridden to use -WL_setBoundsSize:
*/
- (void)setBoundsSize:(NSSize)newSize NS_REQUIRES_SUPER;

/*!
 Stop all animations applied to the root layer and its subtree.
 */
- (void)stopAnimations;

/*!
 Pause all animations applied to the root layer and its subtree.
 */
- (void)pauseAnimations;

/*!
 Resume all previously paused animations applied to the root layer and its subtree.
 */
- (void)resumeAnimations;

- (void)performWhileAnimationsPaused:(NS_NOESCAPE void (^)(void))aBlock;

@end


/*!
 @discussion
 layerContentsRedrawPolicy unconditionally defaults to NSViewLayerContentsRedrawOnSetNeedsDisplay.
 */
@interface WLLayerBackedView : _WLLayerView

/*!
Initialize the view to be backed by a layer.

@discussion
Called by all initializers and therefore is a good place to provide common initialization logic
such as setting the layerContentsRedrawPolicy property.
*/
- (void)prepareForBackingLayer NS_REQUIRES_SUPER;

@end


@interface WLLayerHostingView : _WLLayerView <CALayerDelegate>

/*!
 Initialize the view to host a layer.

 @discussion
 Called by all initializers and therefore is a good place to provide common initialization logic
 such as setting the layerContentsRedrawPolicy property.
 */
- (void)prepareForHostingLayers NS_REQUIRES_SUPER;

/*!
 Make new root layer.

 @discussion
 View is assigned as a delegate for the root layer.
 */
- (CALayer *)makeHostedLayer;

/*!
 Return YES for layers with non-NSImage contents.
 */
- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow;

/*!
 Overridden to return nil.
 */
- (nullable id <CAAction>)actionForLayer:(CALayer *)aLayer forKey:(NSString *)aKey;

@end


@interface _WLLayerControl : NSControl

/*!
 Overridden to use -WL_setFrameSize:
 */
- (void)setFrameSize:(NSSize)newSize NS_REQUIRES_SUPER;

/*!
Overridden to use -WL_setBoundsSize:
*/
- (void)setBoundsSize:(NSSize)newSize NS_REQUIRES_SUPER;

@end


@interface WLLayerBackedControl : _WLLayerControl

/*!
Initialize the control to be backed by a layer.

@discussion
Called by all initializers and therefore is a good place to provide common initialization logic
such as setting the layerContentsRedrawPolicy property.
*/
- (void)prepareForBackingLayer NS_REQUIRES_SUPER;

@end


/*!
 View that draws its content with a block.

 @discussion
 The redraw policy is set to NSViewLayerContentsRedrawDuringViewResize.
 */
@interface WLDrawingLayerBackedView : WLLayerBackedView

@property (nonatomic, nullable, copy) void (^drawingBlock)(__kindof WLDrawingLayerBackedView *aView, NSRect aDirtyRect);

@end


/*!
 Minimal subclass that only flips NSView's coordinate system.
 */
@interface WLFlippedView : NSView

@end


@interface NSView (WLAdditions)

/*!
 Distribute rect in receiver's coordinate system according to given constraints by using Auto Layout.

 @param aRect
 Rect in view's coordiate system that is distributed. Distribution is done along the non-zero axis.

 @discussion
 Sizes may be fractional as they are aligned with respect to the space frame.
 The layout is done strictly within provided space, provided constraints are adjusted if necessary.

 @note -[NSView layoutSubtreeIfNeeded] is called on the receiver.

 @note Distributed size may be smaller than its min size by 1 pixel due to rounding.
 */
- (NSArray<NSNumber *> *)WL_distributeRect:(NSRect)aRect
                                  minSizes:(NSArray<NSNumber *> *)aMinSizes
                                  maxSizes:(NSArray<NSNumber *> *)aMaxSizes
                            preferredSizes:(NSArray<NSNumber *> *)aPreferredSizes;

@end

NS_ASSUME_NONNULL_END

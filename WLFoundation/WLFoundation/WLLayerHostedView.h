//
//  WLLayerHostedView.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
    If you want to change layerContentsRedrawPolicy, you MUST do this _after_ makeLayers. Otherwise your value will be overwritten.
 */
@interface WLLayerHostedView : NSView /* <CALayerDelegate> */

/*!
 @abstract  Stops animations applied to layer tree of the view.
 */
- (void)stopAnimations;

/*!
 @abstract  Pauses animations applied to layer tree of the view.
 */
- (void)pauseAnimations;

/*!
 @abstract  Resumes animations applied to layer tree of the view.
 */
- (void)resumeAnimations;

/*!
 @abstract      Sets view's layer to [self makeRootLayer].
 @discussion    Method takes effect only if current layer property is nil.

 In pre Mountain Lion (10.8) it also:
 - Ensures that Root Layer's geometryFlipped matches Layer Hosting View's isFlipped
 @see           -makeRootLayer
 */
- (void)makeLayers;

/*!
 @abstract      Settings up root layer for -makeLayers.
 */
- (CALayer *)makeRootLayer;

- (void)setNeedsLayout;

- (void)layoutIfNeeded;

- (BOOL)needsLayout;


#pragma mark NSView

/*!
    @abstract   In addition to basic NSView implementation, it sends displayIfNeeded to the whole subtree.
 */
- (void)displayIfNeeded;

/*!
    @abstract   Overridden to always return 0.0
 */
- (CGFloat)boundsRotation;

/*!
    @abstract   Overridden to ignore newAngle.
 */

/*!
    @abstract   Overridden to stop any performing animation on subtree.
    Sends setNeedsLayout to itself if size is changed.
 */
- (void)setFrameSize:(NSSize)newSize;

/*!
    @abstract   Overridden to return YES.
 */
- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow;

/*!
    @abstract   Overridden to return nil.
 */
- (id <CAAction>)actionForLayer:(CALayer *)aLayer forKey:(NSString *)aKey;

@end

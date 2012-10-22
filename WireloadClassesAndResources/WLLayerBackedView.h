//
//  WLLayerBackedView.h
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLLayerBackedView : NSView

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
 @discussion    You can send this message only once.
 
 It also ensures that Root Layer's geometryFlipped matches Layer Hosting View's isFlipped.
 We have to do this due to differences introduced in ML.
 @see           -makeRootLayer
 */
- (void)makeLayers;

/*!
 @abstract      Settings up root layer for -makeLayers.
 */
- (CALayer *)makeRootLayer;

- (void)layoutIfNeeded;

@end

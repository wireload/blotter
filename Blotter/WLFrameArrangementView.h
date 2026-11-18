//
//  WLFrameArrangementView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 27.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import <WLFoundation/WLFoundation.h>

#import "WLGraphics.h"
#import "WLCalendarMockupView.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


NS_ASSUME_NONNULL_BEGIN

/*!
 @const WLFrameArrangementModePositioning Arrange the window using sticky areas.

 @const WLFrameArrangementModeResizing Arrange the window by manually adjusting its position and size.
 */
typedef NS_OPTIONS(NSUInteger, WLFrameArrangementMode)
{
    WLFrameArrangementModePositioning = 1 << 0,
    WLFrameArrangementModeResizing = 1 << 1
};


typedef NS_ENUM(NSUInteger, WLFrameArrangementAnimation)
{
    WLFrameArrangementAnimationResizingGridViewAppearance,
    WLFrameArrangementAnimationResizingGridViewDisappearance,
    WLFrameArrangementAnimationPositioningGridViewAppearance,
    WLFrameArrangementAnimationPositioningGridViewDisappearance,
    WLFrameArrangementAnimationPositioningGridViewGuideHover,
    WLFrameArrangementAnimationMockupFrameUpdate
};


@protocol WLFrameArrangementDelegate;
@class WLFrameArrangementResizingGridAuxView;
@class WLFrameArrangementPositioningGridAuxView;
@class WLFrameArrangementHandlesAuxView;


/*!
 Control to resize and position a window.

 @discussion
 The control displays a mockup of the the window that a user may edit by modifying the mockupFrameRatios.

 There are two editing modes:
    1. WLFrameArrangementModePositioning in which the mockup can only change position and only by using
       the predefined areas
    2. WLFrameArrangementModeResizing in which the user has all control

 The -drawingAlignedFrameSize:forEditingMode: method allows to calculate view's size for pixel-perfect
 drawing for the current editingmode.

 @see editingMode
 */
@interface WLFrameArrangementView : WLLayerBackedView

@property (weak) id<WLFrameArrangementDelegate> delegate;

/*!
 Area taken by the mockup frame with respect to view's coordinates (top left being the origin)
 when size is BLCustomSize.

 @discussion
 All values are decimal such as:
    - NSMinX ∈ [0.0, 1.0)
    - NSMinY ∈ [0.0, 1.0)
    - NSMaxX ∈ (0.0, 1.0]
    - NSMaxY ∈ (0.0, 1.0]

 @see mockupMinimumFrameSizeRatios
 */
@property (nonatomic) NSRect mockupFrameRatios;

/*!
 Minimum area that mockup can occupy.
 */
@property (nonatomic) NSSize mockupMinFrameSizeRatios;

@property (nonatomic) WLFrameArrangementMode editingMode;

/*!
 Whether mockup frame should snap to grid during resizing.
 */
@property (readonly) BOOL shouldSnapToGrid;

/*!
 Whether mockup aspect ratio should be preserved during resizing.
 */
@property (readonly) BOOL shouldPreserveAspectRatio;

/*!
 Whether mockup frame is anchored at its center during resizing.
 */
@property (readonly) BOOL shouldPreserveCenter;

/*!
 Whether mockup is being resized.
 */
@property (readonly) BOOL isResizing;

/*!
 Whether the mockup is being positioned.
 */
@property (readonly) BOOL isPositioning;

@property (strong, readonly) WLCalendarMockupView *mockupView;

@property (strong, readonly) WLFrameArrangementHandlesAuxView *handlesView;

/*!
 Return an animation scene that modifies mockup frame.
 */
- (WLAnimationScene *)animateFrameRatios:(NSRect)newFrameRatios minFrameSizeRatios:(NSSize)newMinSize;

/*!
 Return an animation scene that modifies editing mode.s
 */
- (WLAnimationScene *)animateEditingMode:(WLFrameArrangementMode)newEditingMode;

/*!
 Called when resizing begins.
 */
- (void)resizingDidStartAtPoint:(NSPoint)aPoint handle:(WLEdge)aHandle;

/*!
 Called when resizing continues.
 */
- (void)resizingDidContinueAtPoint:(NSPoint)aPoint;

/*!
 Called when resizing is stopped such as all chances should be preserved.
*/
- (void)resizingDidStopAtPoint:(NSPoint)aPoint;

/*!
 Called when resizing is stopped such as all changes should be discarded.
 */
- (void)resizingDidCancel;

/*!
 Called after resizing is completed, regardless whether it's stopped or cancelled.
 */
- (void)resizingDidFinish;

/*!
 Called when positioning begins.
 */
- (void)positioningDidStartAtPoint:(NSPoint)aPoint;

/*!
 Called when positioning continues.
 */
- (void)positioningDidContinueAtPoint:(NSPoint)aPoint;

/*!
 Called when positioning is stopped such as all chances should be preserved.
 */
- (void)positioningDidStopAtPoint:(NSPoint)aPoint;

/*!
 Called when positioning is stopped such as all changes should be discarded.
 */
- (void)positioningDidCancel;

/*!
 Called after positioning is completed, regardless whether it's stopped or cancelled.
 */
- (void)positioningDidFinish;

- (WLFrameArrangementResizingGridAuxView *)makeResizingGridView;

- (WLFrameArrangementPositioningGridAuxView *)makePositioningGridView;

- (WLFrameArrangementHandlesAuxView *)makeHandlesView;

/*!
 Align frame size for the best visuals.
 */
- (NSSize)drawingAlignedFrameSize:(NSSize)aSize forEditingMode:(WLFrameArrangementMode)anEditingMode;

@end


/*!
 Handles that user can drag to resize the mockup.
 */
@interface WLFrameArrangementHandlesAuxView : WLLayerBackedView

- (nullable NSImageView *)viewForHandle:(WLEdge)aHandle;

/*!
 Handle for a given point in view coordinates.

 @return Handle that is under the point. The invalid handle otherwise.
 */
- (WLEdge)handleForLocation:(NSPoint)aPoint;

/*!
 Rect for the handle in view's coordinates.

 @discussion
 Returns the empty rect if view is detached or if handle is invalid.
 */
- (NSRect)boundsForHandle:(WLEdge)aHandle;

- (NSImageView *)makeHandleView:(WLEdge)aHandle;

@end

/*!
 Grid View for custom resizing.

 It represents 3 coordinate systems:
    1. Drawing coordinate system which is also NSView's native coordinate system for drawing
    2. Layout coordinate system that takes into account that guide lines take space

 Sepration of the drawing and layout coordinate systems allows to render rectangles in a way that
 makes them appear perfectly aligned with the guide lines.
 */
@interface WLFrameArrangementResizingGridAuxView : WLLayerBackedView

@property (readonly) NSRect layoutBounds;

/*!
 Snap given layout rect to the grid.
 */
- (NSRect)gridSnappedLayoutRect:(NSRect)aRect
                    withOptions:(NSAlignmentOptions)anOptions
                        minSize:(NSSize)aMinSize
                           edge:(WLEdge)anEdge;

- (NSRect)layoutRectFromFrameRatios:(NSRect)aFrameRatios;

- (NSRect)drawingRectFromFrameRatios:(NSRect)aFrameRatios;

/*!
 @param aLayoutRect A rect in view's layout coordinate system.
 */
- (NSRect)frameRatiosFromLayoutRect:(NSRect)aLayoutRect;

/*!
 @param aLayoutRect A rect in view's layout coordinate system.
 */
- (NSRect)drawingRectFromLayoutRect:(NSRect)aLayoutRect;

/*!
 @param aDrawingRect A rect in view's drawing coordinate system.
 */
- (NSRect)layoutRectFromDrawingRect:(NSRect)aDrawingRect;

/*!
 Adjust the size for pixel-perfect drawing.

 @param aSize A size in view's drawing coordinate system.
 */
- (NSSize)drawingAlignedFrameSize:(NSSize)aSize;

@end


/*!
 Auxiliary view that draws, animates and manages positioning grid view.

 @discussion
 The arrangement view aligns view's frame to match the desktop view.
 */
@interface WLFrameArrangementPositioningGridAuxView : WLLayerBackedView

/*!
 Make new guide view that is highlighted when hovered.
 */
- (NSBox *)makeGuideView;

/*!
 Adjust the size for pixel-perfect drawing.

 @param aSize A size in view's coordinate system.
 */
- (NSSize)drawingAlignedFrameSize:(NSSize)aSize;

/*!
 Return mockup position for a given point.

 @param aPoint A point in view's coordinate system.
 */
- (BLPosition)positionForPoint:(NSPoint)aPoint;

/*!
 Drawing rect in local coordinate system from ratios.
 */
- (NSRect)drawingRectFromFrameRatios:(NSRect)aFrameRatios;

/*!
 Highlight the guide that corresponds to aPosition.

 @param aPosition A position to highlight.

 @param anIsAnimated Whether highlighting should be animated.
 */
- (void)highlightPosition:(BLPosition)aPosition animated:(BOOL)anIsAnimated;

@end


@protocol WLFrameArrangementDelegate

/*!
 Verify and adjust mockup frame ratios/
 */
- (NSRect)frameArrangement:(WLFrameArrangementView *)anArrangement didChangeMockupFrameRatios:(NSRect)newFrameRatios;

/*!
 Verify and adjust mockup frame ratios for the selected position.
*/
- (NSRect)frameArrangement:(WLFrameArrangementView *)anArrangement didChangeMockupPosition:(BLPosition)aPosition;

/*!
 Whether the view should run the animation.

 @discussion
 In addition to -[WLFrameArrangementView animate…] methods that allow external code to animate certain properties
 the view may also schedule animations on its own in response to user actions. This method allows the delegate
 to opt out from running the latter.
 */
- (BOOL)frameArrangement:(WLFrameArrangementView *)anArrangement shouldAnimate:(WLFrameArrangementAnimation)anAnimation;

@end


@interface NSCursor (WLFrameArrangementView)

+ (NSCursor *)WL_cursorForEdge:(WLEdge)anEdge;

+ (NSCursor *)WL_resizeDownLeftCursor;

+ (NSCursor *)WL_resizeDownRightCursor;

+ (NSCursor *)WL_resizeLeftRightCursor;

+ (NSCursor *)WL_resizeUpDownCursor;

+ (NSCursor *)WL_resizeUpLeftCursor;

+ (NSCursor *)WL_resizeUpRightCursor;

@end

NS_ASSUME_NONNULL_END

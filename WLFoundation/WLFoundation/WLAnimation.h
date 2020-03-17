//
//  WLAnimation.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 2/28/20.
//  Copyright © 2020 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import <WLFoundation/NSObject+WLAnimationTracking.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Proxy that allows weakly references to CAAnimation delegate.
 */
@interface WLWeakAnimationDelegateProxy : NSObject <CAAnimationDelegate>

- (instancetype)initWithDelegate:(id<CAAnimationDelegate>)aDelegate;

@property (weak, readonly) id<CAAnimationDelegate> delegate;

@end


@interface WLBasicAnimation : CABasicAnimation <NSUserInterfaceItemIdentification>
@end


@interface CALayer (WLAnimation)

- (void)WL_performRecursively:(NS_NOESCAPE void (^)(CALayer *aLayer))aBlock;

- (nullable NSArray<NSString *> *)WL_animationKeysWithPrefix:(NSString *)aPrefix;

- (void)WL_removeAnimationsWithPrefix:(NSString *)aPrefix;

@end


@interface CATransaction (WLAnimation)

+ (void)WL_performWithDisabledActions:(NS_NOESCAPE void (^)(void))aBlock;

@end


@interface NSWindow (WLAnimation)

- (NSTimeInterval)WL_animationResizeTimeForView:(NSView *)aView newFrameSize:(NSSize)newSize;

@end

#pragma mark - WLInterpolation

@interface CAMediaTimingFunction (WLInterpolation)

- (float)WL_valueForTime:(float)aTime;

- (instancetype)WL_reversed;

@end


@interface CABasicAnimation (WLInterpolation)

/*!
 Duration of a single repeat in local time units.

 @discussion
 If the `autoreverse` property is set the value is double of the `duration` property.
 */
@property (nonatomic, readonly) NSTimeInterval WL_singleRepeatDuration;

/*!
 Total animation duration of all repeats in local time units.

 @discussion
 To convert total duration to parent's time units divide by `speed`.
 */
@property (nonatomic, readonly) NSTimeInterval WL_totalDuration;

/*!
 Calculate fraction on the value scale from fraction on the `duration` time scale.

 @param aTime Time fraction to convert into a value.
 */
- (float)WL_valueForTime:(float)aTime;

@end


@interface CASpringAnimation (WLInterpolation)

- (float)WL_valueForTime:(float)aTime;

@end


@interface CALayer (WLInterpolation)

- (NSTimeInterval)WL_remainingTimeForAnimation:(CAAnimation *)anAnimation;

- (CGFloat)WL_progressForAnimation:(CAAnimation *)anAnimation;

@end

#pragma mark - WLAnimationTracking

/*!
 @group Animation Tracking

 When animation tracking is enabled via +[NSAnimationContext WL_enableAnimationTracking],
 it is possible to collection animations scheduled for execution within an NSAnimationContext group.

 To enable collection you must associate an instance of NSMutableArray with the completion block right before
 the group is started:

 @code
 dispatch_block_t completion = ^{ ... };

 NSMutableArray *traces = [NSMutableArray new];
 objc_setAssociatedObject(completion, &WLTransactionsToken, traces, OBJC_ASSOCIATION_RETAIN);
 [NSAnimationContext runAnimationGroup:^(NSAnimationContext *aContext) { ... } completionHandler:completion];
 // ... work with the traces object ...
 objc_setAssociatedObject(completion, &WLTransactionsToken, nil, OBJC_ASSOCIATION_ASSIGN);
 @endcode

 It must be an array since the same completion handler may be shared with multiple nested animation groups.
 The last object is always the most comprehensive and contains all animations that were scheduled within the group
 itself and all nested groups.
 */

/*!
 Token to access animations associated with the animation context completion handler.
 */
extern NSString * const WLTransactionsToken;

/*!
 Trace of an added animation.
 */
@interface WLAnimationTrace : NSObject

/*!
 Object the animation is added to.
 */
@property (weak) id target;

/*!
 The animation object that was added.

 @note Core Animation may copy the object and then further modify it.
 */
@property (strong) CAAnimation *animation;

/*!
 Key associated with the added animation.
 */
@property (nullable, copy) NSString *key;

/*!
 Call stack when the animation was added.
 */
@property (nullable, copy) NSArray<NSString *> *callStackSymbols;

@end


/*!
 Trace of all animations added to an animation context.
 */
@interface WLTransactionTrace : NSObject
/*!
 Animations added to the current context.
 */
@property (copy) NSArray<WLAnimationTrace *> *animations;

/*!
 Call stack when the animations were commited by +[NSAnimationContext endGrouping].
 */
@property (nullable, copy) NSArray<NSString *> *callStackSymbols;

@end


/*!
 Track animations added within currently active animation contexts.

 @discussion
 Animations are attached to the completion handler active at the time group ended via Objective-C associated objects API.
 */
@interface NSAnimationContext (WLAnimationTracking)

/*!
 Animations for the stack of currently active animation contexts.
 */
@property (class, nullable, readonly) NSMutableArray<NSMutableArray<WLAnimationTrace *> *> *WL_animationsStack;

/*!
 Enable animation tracking

 @discussion
 It's safe to call this method multiple times.
 */
+ (void)WL_enableAnimationTracking;

/*!
 Swizzled with -[NSAnimationContext beginGrouping] when animation tracking is enabled.
 */
+ (void)WL_beginGrouping;

/*!
 Swizzled with -[NSAnimationContext endGrouping] when animation tracking is enabled.
 */
+ (void)WL_endGrouping;

/*!
 Add an animation trace to the currently active animation contexts.
 */
+ (void)WL_addAnimationTrace:(WLAnimationTrace *)aTrace;

@end


@interface CALayer (WLAnimationTracking)

/*!
 Swizzled with -[CALayer addAnimation:forKey:] when animation tracking is enabled.
 */
- (void)WL_addAnimation:(CAAnimation *)anAnimation forKey:(NSString *)aKey;

@end


@interface NSProxy (WLAnimationTracking)

/*!
 Swizzled with -[_NSObjectAnimator setValue:forKey:] when animation tracking is enabled.
 */
- (void)WLAnimationTracking_setValue:(id)aValue forKey:(NSString *)aKey;

@end

NS_ASSUME_NONNULL_END

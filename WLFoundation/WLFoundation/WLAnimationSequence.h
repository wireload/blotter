//
//  WLAnimationSequence.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 8/2/19.
//  Copyright © 2019 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


/*!
 @file

 @see WWDC 2014, Session 236, Building Interruptible and Responsive Interactions: https://devstreaming-cdn.apple.com/videos/wwdc/2014/236xxwk3fv82sx2/236/236_hd_building_interruptible_and_responsive_interactions.mov

 @see WWDC 2017, Session 230, Advanced Animations with UIKit: https://developer.apple.com/videos/play/wwdc2017/230
    Although it's about UIKit, it's a good starting point to think about animations

 @see CAMediaTiming Cheat Sheet: http://ronnqvi.st/images/CAMediaTiming%20cheat%20sheet.pdf
 */

NS_ASSUME_NONNULL_BEGIN

#define WLAnimated(object, animated) ((animated) ? (object).animator : (object))


typedef NS_ENUM(NSInteger, WLAnimationSequenceState) {
    WLAnimationSequenceStateNone = 0,
    WLAnimationSequenceStateRunning,
    WLAnimationSequenceStatePausing,
    WLAnimationSequenceStatePaused,
    WLAnimationSequenceStateCancelling,
    WLAnimationSequenceStateAborting,
    WLAnimationSequenceStateAborted,
    WLAnimationSequenceStateCompleted
};


typedef NS_ENUM(NSInteger, WLAnimationSceneState) {
    WLAnimationSceneStateNone = 0,
    WLAnimationSceneStateRunning,
    WLAnimationSceneStateCancelling,
    WLAnimationSceneStateCompleted
};


typedef NSInteger WLAnimationStateReason NS_TYPED_EXTENSIBLE_ENUM;
extern const WLAnimationStateReason WLAnimationStateReasonInherit;
extern const WLAnimationStateReason WLAnimationStateReasonNone;
static const WLAnimationStateReason WLAnimationStateReasonUser = 1000;

/*!
 Automatically cancelled due to notification from the owner.
 */
extern const WLAnimationStateReason WLAnimationStateReasonOwnerDidNotify;

/*!
 Automatically cancelled because the application did hide.
 */
extern const WLAnimationStateReason WLAnimationStateReasonAppDidHide;

/*!
 Automatically cancelled because the application is about to terminate.
 */
extern const WLAnimationStateReason WLAnimationStateReasonAppWillTerminate;

/*!
 Automatically aborted because the preceding sequence did abort.
 */
extern const WLAnimationStateReason WLAnimationStateReasonPrecedingSequenceDidAbort;

/*!
 Cancelled or aborted to retain currently presented appearance.
 */
extern const WLAnimationStateReason WLAnimationStateReasonFreezeAppearance;

/*!
 Cancelled or aborted to fast forward animation to the final appearance.
 */
extern const WLAnimationStateReason WLAnimationStateReasonFastForward;


/*!
 Owner of the WLAnimationSequence can post this notification to cancel the sequence.
 */
extern NSNotificationName const WLAnimationShouldCancelNotification;


/*!
 @const WLAnimationCancellationPolicyOnOwnerDealloc
 Interrupt when the owner gets deallocated.

 @const WLAnimationCancellationPolicyOnOwnerNotification
 Interrupt when the owner posts the WLAnimationShouldInterrupt notification.

 @const WLAnimationAutoCancellationPolicyOnAppHide
 Interrupt when the NSApplicationDidHideNotification notification is posted.

 @const WLAnimationAutoCancellationPolicyOnAppTermination
 Interrupt when the NSApplicationWillTerminateNotification is posted.
 */
typedef NS_OPTIONS(NSUInteger, WLAnimationCancellationPolicy) {
    WLAnimationCancellationPolicyNone = 0,
    WLAnimationCancellationPolicyOnOwnerDealloc = 1 << 0,
    WLAnimationCancellationPolicyOnOwnerNotification = 1 << 1,
    WLAnimationCancellationPolicyOnAppHide = 1 << 2,
    WLAnimationCancellationPolicyOnAppTermination = 1 << 3
};


@class WLAnimationSequence;


typedef void (^WLAnimationHandler)(WLAnimationSequence *aSequence);

static const WLAnimationHandler WLAnimationHandlerNoop = ^(WLAnimationSequence *aSequence){};


typedef NS_OPTIONS(NSUInteger, WLAnimationSceneMergePolicy) {
    WLAnimationSceneMergePolicyMergeAll = 0,
    WLAnimationSceneMergePolicyPreservePreparationHandler,
    WLAnimationSceneMergePolicyPreserveDefaultDuration,
    WLAnimationSceneMergePolicyPreserveDefaultTimingFunction,
    WLAnimationSceneMergePolicyPreserveDefaultAllowsImplicitAnimation,
    WLAnimationSceneMergePolicyPreserveDurationHandler,
    WLAnimationSceneMergePolicyPreserveCancellationHandler,
    WLAnimationSceneMergePolicyPreserveCompletionHandler,
    WLAnimationSceneMergePolicyPreserveIdentifier
};


/*!
 An execution unit inside WLAnimationSequence that actually schedules the animations.
 */
@interface WLAnimationScene : NSObject <NSUserInterfaceItemIdentification>

/*!
 Preparation actions run within a dedicated group preceding the changes.

 @discussion
 If actual animations are driven by Core Animation the initial values
 must be set within a separate transaction to avoid being coalesced (which would result in no animation).

 The handler is executed even if the scene is cancelled before it had a chance to run. In that case,
 scene's state will be WLAnimationSceneStateCancelling and not WLAnimationSceneStateRunning.
 */
@property (nullable, copy) WLAnimationHandler preparationHandler;

/*!
 Animation actions, e.g. using the animator proxy.

 @note The handler is not executed if the scene is cancelled before it had a chance to run.
 */
@property (nonatomic, nullable, copy) WLAnimationHandler changesHandler;

/*!
 Cancellation actions that all changes to their final values effectively ending all animations.
 */
@property (nullable, copy) WLAnimationHandler cancellationHandler;

/*!
 Completion actions after the animation completes.

 @discussion
 Use the state property to determine whether the scene was cancelled.
 */
@property (nullable, copy) WLAnimationHandler completionHandler;

/*!
 Default animation duration.

 @discussion
 Defaults to nil meaning that the value will be inherited from the context when the owning sequence is scheduled to run.

 If the NSAnimationSlowMotionOnShift argument is set to YES, animation is slowed down by a factor of 10.

 @see durationHandler
 @see NSAnimationContext/duration
 */
@property (nullable, copy) NSNumber *defaultDuration;

/*!
 Default animation timing function.

 @discussion
 Defaults to nil meaning that the value will be inherited from the context when the owning sequence is scheduled to run.

 @see NSAnimationContext/timingFunction
 */
@property (nullable, strong) CAMediaTimingFunction *defaultTimingFunction;

/*!
 Whether implicit animation is allowed by default.

 @discussion
 Defaults to nil meaning that the value will be inherited from the context when the owning sequence is scheduled to run.

 @see NSAnimationContext/allowsImplicitAnimation
 */
@property (nullable, copy) NSNumber *defaultAllowsImplicitAnimation;

/*!
 Current state of the animation scene.
 */
@property (readonly) WLAnimationSceneState state;

/*!
 Duration of the scene.

 @discussion
 If constant duration set via the defaultDuration property is not sufficiant, dynamic duration can be provided
 via a block.

 The handler is re-evaluted for every change and may be updated while the scene is running.

 @see defaultDuration
 */
@property (nullable, copy) NSTimeInterval (^durationHandler)(void);

+ (instancetype)sceneWithChanges:(WLAnimationHandler)aChangesHandler;

/*!
 Scene with NSAnimatableProeprtyContainer-style animations only.

 @discussion
 Animations that are added solely through the animator proxy can be easily removed by re-assigning
 the same values through the animator proxy but with 0.0 duration. This allows to create the cancellation handler
 automatically.
 */
+ (instancetype)sceneWithAnimatorChanges:(WLAnimationHandler)aChangesHandler;

- (instancetype)initWithChanges:(WLAnimationHandler)aChangesHandler;

/*!
 Run the scene.
 */
- (void)run:(WLAnimationSequence *)aSequence;

/*!
 Mark animation for cancellation.

 @discussion
 If the scene is already running, calls the cancellation handler (if present).
 If not, the cancellation handler (if present) will be called upon run.
 */
- (void)cancel;

/*!
 Add additional changes to the scene.

 @discussion
 If the scene is already running, runs the changes immediately. If not,
 the changes are queued and executed in order after changesHandler.

 The scene completes only after all changes complete.

 @throws NSInternalInconsistencyException if the scene is cancelling or already completed.
 */
- (void)addChanges:(WLAnimationHandler)aChangesHandler;

/*!
 Immediately apply changes as part of the scene.

 @discussion
 This method allows to "attach" animations that run outside of the sequence.

 The scene completes only after all changes complete.

 @throws NSInternalInconsistencyException if the scene is cancelling or already completed.
 */
- (void)runChanges:(NS_NOESCAPE void (^)(void))aBlock;

- (void)mergeWithScene:(WLAnimationScene *)aScene;

/*!
 Apply changes from aScene to the current scene.

 @param aScene Scene to be applied.

 @param aPolicy Rules that allow to preserve certain properties of the receiver.

 @discussion
 aScene is consumed in the process and its state is changed to Completed.

 Only non-nil handlers are used as replacements. To intentionally remove a handler
 specify the WLAnimationHandlerNoop block.

 One practical application is to replace the scene in-place.

 @throws NSInternalInconsistencyException if aScene is already a part of some sequence.

 @throws NSInternalInconsistencyException if the scene is cancelling or already completed.
 */
- (void)mergeWithScene:(WLAnimationScene *)aScene policy:(WLAnimationSceneMergePolicy)aPolicy;

/*!
 Set duration of the current animation context by taking into account whether slow motion is requested
 by the sequence and whether Cocoa's automatic slow motion is requested.

 @see NSAnimationSlowMotionOnShift
 */
- (void)scaleAndSetAnimationContextDuration:(NSTimeInterval)aDuration;

@end


@interface WLAnimationSequence : NSObject <NSUserInterfaceItemIdentification>
{
    @public
    BOOL _reentryCanary;
}

/*!
 Current state of the animation sequence.
 */
@property (readonly) WLAnimationSequenceState state;

/*!
 Why the animation was transitioned to the current state.
 */
@property (readonly) WLAnimationStateReason stateReason;

@property (nonatomic, readonly, getter=isFinished) BOOL finished;

@property (nonatomic, readonly, getter=isRunning) BOOL running;

/*!
 Scene that is currently running. 
 */
@property (nullable, readonly) WLAnimationScene *currentScene;

/*!
 Cancellation actions that fast-forward all animations specified in the sequence
 and bring all changes to their final values.
 */
@property (nullable, copy) WLAnimationHandler cancellationHandler;

/*!
 Owner of the sequence that is conveniently available through the sequence itself.

 @discussion
 The sequence keeps a weak reference to the owner which is turned strong
 for the duration of KVO notifications and completion blocks.
 */
@property (nullable, weak) id owner;

/*!
 Sequence is automatically cancelled when conditions specified by the policy become true.

 @throws Setter will throw if the sequence is already running or has completed.
 */
@property (nonatomic) WLAnimationCancellationPolicy autoCancellationPolicy;

/*!
 Pending scenes yet to be executed.

 @note KVO-observable

 @see mutableScenes
 */
@property (readonly, strong) NSArray<WLAnimationScene *> *scenes;

@property (nonatomic, readonly, strong) NSMutableArray<WLAnimationScene *> *mutableScenes;

- (nullable WLAnimationScene *)sceneWithIdentifier:(NSUserInterfaceItemIdentifier)anIdentifier;

- (BOOL)containsScene:(WLAnimationScene *)aScene;

- (void)run;

- (void)runWithCompletion:(WLAnimationHandler)aCompletion;

- (void)runWithReason:(WLAnimationStateReason)aReason;

- (void)runWithReason:(WLAnimationStateReason)aReason completion:(nullable WLAnimationHandler)aCompletion;

- (void)runAfter:(nullable WLAnimationSequence *)aSequence;

- (void)runAfter:(nullable WLAnimationSequence *)aSequence withCompletion:(nullable WLAnimationHandler)aCompletion;

- (void)runAfter:(nullable WLAnimationSequence *)aSequence withReason:(WLAnimationStateReason)aReason;

/*!
 Run the sequence after the specified sequence completes.

 @param aSequence The sequence to run after. If nil, runs immediately.

 @note
 If the sequence has no scenes, it calls the completion handler immediately.
*/
- (void)runAfter:(nullable WLAnimationSequence *)aSequence
      withReason:(WLAnimationStateReason)aReason
      completion:(nullable WLAnimationHandler)aCompletion;


- (void)pause;

- (void)pauseWithCompletion:(nullable WLAnimationHandler)aCompletion;

- (void)pauseWithReason:(WLAnimationStateReason)aReason;

/*!
 Pause the sequence.

 @param aCompletion Completion handler that is run once currently running scene completes.

 @discussion
 The sequence can be paused before it's run. Once run, paused sequence will not run any scenes until resumed.
*/
- (void)pauseWithReason:(WLAnimationStateReason)aReason completion:(nullable WLAnimationHandler)aCompletion;


- (void)resume;

/*!
 Resume previously paused sequence.
 */
- (void)resumeWithReason:(WLAnimationStateReason)aReason;


- (void)cancel;

/*!
 Mark the sequence for cancellation.

 @discussion
 Cancel the current scene and then either cancel'n'run the remaining scenes
 or call sequence's cancellation handler and complete.

 @see cancellationHandler
 */
- (void)cancelWithReason:(WLAnimationStateReason)aReason;


- (void)abort;

/*!
 Mark the sequence for abortion.

 @discussion
 Cancel the current scene and once it finishes, complete the sequence.
 */
- (void)abortWithReason:(WLAnimationStateReason)aReason;

/*!
 Called when the current scene completes.

 @param aScene Scene that just completed. If nil then the sequence has just started.
 */
- (void)sceneDidComplete:(nullable WLAnimationScene *)aScene;

@end

NS_ASSUME_NONNULL_END

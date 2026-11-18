//
//  WLAnimationSequence.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 8/2/19.
//  Copyright © 2019 Wireload. All rights reserved.
//

#import <objc/runtime.h>
#import <os/trace.h>
#import <os/activity.h>

#import "WLAnimationSequence.h"
#import "WLAnimation.h"
#import "WLLog.h"


const WLAnimationStateReason WLAnimationStateReasonInherit = -1;

const WLAnimationStateReason WLAnimationStateReasonNone = 0;

const WLAnimationStateReason WLAnimationStateReasonOwnerDidNotify = 1;

const WLAnimationStateReason WLAnimationStateReasonAppDidHide = 2;

const WLAnimationStateReason WLAnimationStateReasonAppWillTerminate = 3;

const WLAnimationStateReason WLAnimationStateReasonPrecedingSequenceDidAbort = 4;

const WLAnimationStateReason WLAnimationStateReasonFreezeAppearance = 5;

const WLAnimationStateReason WLAnimationStateReasonFastForward = 6;


static const dispatch_time_t _WLAnimationCancellationTolerance = 100000000; // 100ms


NSNotificationName const WLAnimationShouldCancelNotification = @"WLAnimationCancelInterrupt";


void _WLNoReentryScopeEnter(BOOL *aVar)
{
    if (*aVar)
        [NSException raise:NSInternalInconsistencyException format:@"the method is not reentrable"];

    *aVar = YES;
}

void _WLNoReentryScopeLeave(BOOL **aVar)
{
    **aVar = NO;
}

#define _WLNoReentryScope(var, aVarPtr) \
__attribute__((__cleanup__(_WLNoReentryScopeLeave))) BOOL *var = aVarPtr; \
_WLNoReentryScopeEnter(var);
#define WLNoReentryScope(aVarPtr) _WLNoReentryScope(OS_CONCAT(WLNoReentryScope, __COUNTER__), aVarPtr)


static const WLLogName _WLAnimationLog = @"net.wireload.blotter.mac.Animation";


@interface WLAnimationSequence ()
@property (class, readonly) BOOL willAppKitSlowMotion;
@property (weak) WLAnimationSequence *linkedSequence;
@property BOOL shouldSlowMotion;
@property NSTimeInterval defaultDuration;
@property CAMediaTimingFunction *defaultTimingFunction;
@property BOOL defaultAllowsImplicitAnimations;
@end


@implementation WLAnimationScene
{
    __weak WLAnimationSequence *_owningSequence;
    NSMutableArray<WLAnimationHandler> *_changes;
    NSUInteger _pendingChangesCount;
    WLAnimationSceneState _nextState;
    BOOL _isPreparing;

    WLAnimationTrace *_preparationTrace;
    NSMutableArray<WLAnimationTrace *> *_changesTraces;
    WLAnimationTrace *_cancellationTrace;
}

+ (instancetype)sceneWithChanges:(WLAnimationHandler)aChangesHandler
{
    return [[self alloc] initWithChanges:aChangesHandler];
}

+ (instancetype)sceneWithAnimatorChanges:(WLAnimationHandler)aChangesHandler
{
    WLAnimationScene *instance = [self sceneWithChanges:aChangesHandler];
    instance.cancellationHandler = aChangesHandler;
    return instance;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _changes = [NSMutableArray new];
        _changesTraces = [NSMutableArray new];
        _nextState = WLAnimationSceneStateRunning;
    }

    return self;
}

- (instancetype)initWithChanges:(WLAnimationHandler)aChangesHandler
{
    self = [self init];

    if (self)
    {
        self.changesHandler = aChangesHandler;
    }

    return self;
}

- (void)dealloc
{
    switch (_state)
    {
        case WLAnimationSceneStateNone:
            [[WLLog logForName:_WLAnimationLog] logDebug:@"%@ was allocated but not used", self];
            break;
        case WLAnimationSceneStateCompleted:
            break;
        case WLAnimationSceneStateRunning:
        case WLAnimationSceneStateCancelling:
            [[WLLog logForName:_WLAnimationLog] logError:@"cannot deallocate %@ while in state %lu", self, _state];
            NSAssert(NO, @"cannot deallocate %@ while in state %lu", self, _state);
            break;
    }
}

#pragma mark Properties
@dynamic changesHandler;
@synthesize identifier;

- (WLAnimationHandler)changesHandler
{
    return _changes.count ? _changes[0] : nil;
}

- (void)setChangesHandler:(WLAnimationHandler)newHandler
{
    if (_state == WLAnimationSceneStateCompleted)
        [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];

    _changes[0] = [newHandler copy];
}

#pragma mark Methods

- (void)run:(WLAnimationSequence *)aSequence
{
    if (_state != WLAnimationSceneStateNone)
        [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];

    _owningSequence = aSequence;

    os_activity_initiate("-[WLAnimationScene cancel]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        switch (_nextState)
        {
            case WLAnimationSceneStateRunning:
            case WLAnimationSceneStateCancelling:
                [self _prepareAndRunOrCancel:aSequence];
                break;
            case WLAnimationSceneStateNone:
            case WLAnimationSceneStateCompleted:
                [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _nextState];
                break;
        }
    }));
}

- (void)cancel
{
    os_activity_initiate("-[WLAnimationScene cancel]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        switch (_state)
        {
            case WLAnimationSceneStateNone:
                _nextState = WLAnimationSceneStateCancelling;
                break;
            case WLAnimationSceneStateRunning:
                if (_isPreparing)
                    _nextState = WLAnimationSceneStateCancelling;
                else
                {
                    [self willChangeValueForKey:@"state"];
                    _state = WLAnimationSceneStateCancelling;
                    [self _cancel:_owningSequence andComplete:NO];
                }
                break;
            case WLAnimationSceneStateCancelling:
                break;
            case WLAnimationSceneStateCompleted:
                [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
                break;
        }
    }));
}

- (void)addChanges:(WLAnimationHandler)aChangesHandler
{
    os_activity_initiate("-[WLAnimationScene addChanges:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        __auto_type owningSequence = _owningSequence;

        switch (_state)
        {
            case WLAnimationSceneStateNone:
                [_changes addObject:[aChangesHandler copy]];
                break;
            case WLAnimationSceneStateRunning:
            {
                if (_isPreparing)
                    [_changes addObject:[aChangesHandler copy]];
                else
                {
                    [self runChanges:^{
                        WLNoReentryScope(&owningSequence->_reentryCanary);
                        aChangesHandler(owningSequence);
                    }];
                }
                break;
            }
            case WLAnimationSceneStateCancelling:
            case WLAnimationSceneStateCompleted:
                [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
                break;
        }
    }));
}

- (void)runChanges:(NS_NOESCAPE void (^)(void))aBlock
{
    os_activity_initiate("-[WLAnimationScene runChanges:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        switch (_state)
        {
            case WLAnimationSceneStateNone:
            case WLAnimationSceneStateRunning:
            {
                __auto_type completion = ^{
                    self->_pendingChangesCount -= 1;

                    if (self->_state != WLAnimationSceneStateNone && !self->_isPreparing)
                        [self _completeIfNeeded:self->_owningSequence];
                };

                __auto_type traces = [NSAnimationContext WL_runAnimationGroup:^(NSAnimationContext * _Nonnull aContext) {
                    self->_pendingChangesCount += 1;
                    [self _configureAnimationContext];

                    aBlock();
                } completionHandler:completion];

                if (traces.count)
                    [_changesTraces addObject:traces.lastObject]; // last object contains animations from all nested groups

                break;
            }
            case WLAnimationSceneStateCancelling:
            case WLAnimationSceneStateCompleted:
                [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
                break;
        }
    }));
}

- (void)mergeWithScene:(WLAnimationScene *)aScene
{
    [self mergeWithScene:aScene policy:WLAnimationSceneMergePolicyMergeAll];
}

- (void)mergeWithScene:(WLAnimationScene *)aScene policy:(WLAnimationSceneMergePolicy)aPolicy
{
    {
        __auto_type owningSequence = aScene->_owningSequence;
        if (owningSequence)
            [NSException raise:NSInvalidArgumentException format:@"aScene is already added to %@", owningSequence];
    }

#define WLSetIfNotNil(aTo, aFrom) \
    { \
        __auto_type aFromVar = aFrom; \
        if (aFromVar != nil) \
            aTo = aFromVar; \
    }


    switch (_state)
    {
        case WLAnimationSceneStateNone:
            if ((aPolicy & WLAnimationSceneMergePolicyPreservePreparationHandler) == 0)
                WLSetIfNotNil(self.preparationHandler, aScene.preparationHandler);

            [_changes removeAllObjects];
        case WLAnimationSceneStateRunning:
            if ((aPolicy & WLAnimationSceneMergePolicyPreserveDefaultDuration) == 0)
                WLSetIfNotNil(self.defaultDuration, aScene.defaultDuration);

            if ((aPolicy & WLAnimationSceneMergePolicyPreserveDefaultTimingFunction) == 0)
                WLSetIfNotNil(self.defaultTimingFunction, aScene.defaultTimingFunction);

            if ((aPolicy & WLAnimationSceneMergePolicyPreserveDefaultAllowsImplicitAnimation) == 0)
                WLSetIfNotNil(self.defaultAllowsImplicitAnimation, aScene.defaultAllowsImplicitAnimation);

            if ((aPolicy & WLAnimationSceneMergePolicyPreserveDurationHandler) == 0)
                WLSetIfNotNil(self.durationHandler, aScene.durationHandler);

            if ((aPolicy & WLAnimationSceneMergePolicyPreserveCancellationHandler) == 0)
                WLSetIfNotNil(self.cancellationHandler, aScene.cancellationHandler);

            if ((aPolicy & WLAnimationSceneMergePolicyPreserveCompletionHandler) == 0)
                WLSetIfNotNil(self.completionHandler, aScene.completionHandler);

            if ((aPolicy & WLAnimationSceneMergePolicyPreserveIdentifier) == 0)
                WLSetIfNotNil(self.identifier, aScene.identifier);

            for (WLAnimationHandler c in aScene->_changes)
                [self addChanges:c];

            break;
        case WLAnimationSceneStateCancelling:
        case WLAnimationSceneStateCompleted:
            [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
            break;
    }

#undef WLSetIfNotNil

    [aScene->_changes removeAllObjects];
    [aScene willChangeValueForKey:@"state"];
    aScene->_state = WLAnimationSceneStateCompleted;
    [aScene didChangeValueForKey:@"state"];
}

- (void)scaleAndSetAnimationContextDuration:(NSTimeInterval)aDuration
{
    __auto_type context = NSAnimationContext.currentContext;
    __auto_type owningSequence = _owningSequence;

    if (owningSequence.shouldSlowMotion && ![[owningSequence class] willAppKitSlowMotion])
        context.duration = aDuration * 10.0;
    else if (!owningSequence.shouldSlowMotion && [[owningSequence class] willAppKitSlowMotion])
        context.duration = aDuration / 10.0;
    else
        context.duration = aDuration;
}

#pragma mark Private

- (void)_configureAnimationContext
{
    NSAnimationContext *context = NSAnimationContext.currentContext;
    __auto_type owningSequence = _owningSequence;

    NSTimeInterval duration = owningSequence.defaultDuration;

    if (_durationHandler)
        duration = _durationHandler();
    else if (_defaultDuration != nil)
        duration = [_defaultDuration doubleValue];

    [self scaleAndSetAnimationContextDuration:duration];

    if (_defaultTimingFunction)
        context.timingFunction = _defaultTimingFunction;
    else
        context.timingFunction = owningSequence.defaultTimingFunction;

    if (_defaultAllowsImplicitAnimation)
        context.allowsImplicitAnimation = [_defaultAllowsImplicitAnimation boolValue];
    else
        context.allowsImplicitAnimation = owningSequence.defaultAllowsImplicitAnimations;
}

- (void)_prepareAndRunOrCancel:(WLAnimationSequence *)aSequence
{
    NSParameterAssert(_state == WLAnimationSceneStateNone);

    __auto_type completion = ^{
        switch (self->_nextState)
        {
            case WLAnimationSceneStateRunning:
                [self _run:aSequence];
                break;
            case WLAnimationSceneStateCancelling:
                [self _cancel:aSequence andComplete:YES];
                break;
            case WLAnimationSceneStateNone:
            case WLAnimationSceneStateCompleted:
                [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", self->_state];
                break;
        }

        self->_isPreparing = NO;
    };

    {
        // With a non-noop preparation handler change of state is span across multiple animation transactions.
        // It's initiated here and finished by either run or cancel.

        WLNoReentryScope(&aSequence->_reentryCanary);
        [self willChangeValueForKey:@"state"];
        self->_state = _nextState;
        _isPreparing = YES;
    }

    if (!_preparationHandler || _preparationHandler == WLAnimationHandlerNoop)
    {
        completion();
        return;
    }

    __auto_type traces = [NSAnimationContext WL_runAnimationGroup:^(NSAnimationContext * _Nonnull aContext) {
        WLNoReentryScope(&aSequence->_reentryCanary);

        aContext.duration = 0.0;
        aContext.allowsImplicitAnimation = NO;
        self->_preparationHandler(aSequence);
    } completionHandler:completion];

    _preparationTrace = traces.lastObject; // last object contains animations from all nested groups
}

- (void)_run:(WLAnimationSequence *)aSequence
{
    NSParameterAssert(_state == WLAnimationSceneStateRunning);

    __auto_type completion = ^{
        self->_pendingChangesCount -= 1;
        [self _completeIfNeeded:aSequence];
    };

    __auto_type traces = [NSAnimationContext WL_runAnimationGroup:^(NSAnimationContext * _Nonnull aContext) {
        WLNoReentryScope(&aSequence->_reentryCanary);

        _pendingChangesCount += 1;

        [self _configureAnimationContext];

        while (_changes.count)
        {
            if (_changes[0] != WLAnimationHandlerNoop)
                _changes[0](aSequence);

            [_changes removeObjectAtIndex:0];
        }

        [self didChangeValueForKey:@"state"];

    } completionHandler:completion];

    if (traces.count)
        [_changesTraces addObject:traces.lastObject]; // last object contains animations from all nested groups
}

-(void)_cancel:(WLAnimationSequence *)aSequence andComplete:(BOOL)aShouldComplete
{
    NSParameterAssert(_state == WLAnimationSceneStateCancelling);

    if (!_cancellationHandler || _cancellationHandler == WLAnimationHandlerNoop)
    {
        [self didChangeValueForKey:@"state"];

        if (aShouldComplete)
            [self _completeIfNeeded:aSequence];

        return;
    }

    __auto_type completion = ^{
        if (aShouldComplete)
            [self _completeIfNeeded:aSequence];
    };

    __auto_type traces = [NSAnimationContext WL_runAnimationGroup:^(NSAnimationContext * _Nonnull aContext) {
        WLNoReentryScope(&aSequence->_reentryCanary);

        aContext.duration = 0.0;
        aContext.allowsImplicitAnimation = NO;
        _cancellationHandler(aSequence);
        [self didChangeValueForKey:@"state"];
    } completionHandler:completion];

    _cancellationTrace = traces.lastObject;
}

- (void)_completeIfNeeded:(WLAnimationSequence *)aSequence
{
    NSParameterAssert(_state == WLAnimationSceneStateRunning ||
                      _state == WLAnimationSceneStateCancelling);
    NSParameterAssert(aSequence != nil);

    if (_pendingChangesCount != 0)
        return;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull aContext) {
        WLNoReentryScope(&aSequence->_reentryCanary);

        aContext.duration = 0.0;
        aContext.allowsImplicitAnimation = NO;

        [self willChangeValueForKey:@"state"];

        if (self->_completionHandler && _completionHandler != WLAnimationHandlerNoop)
            self->_completionHandler(aSequence);

        self->_state = WLAnimationSceneStateCompleted;
        [self didChangeValueForKey:@"state"];
    } completionHandler:nil];

    [_changes removeAllObjects];
    [aSequence sceneDidComplete:self];
}

#pragma mark NSObject

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p; %@, preparation=%@, changes=%@, cancellation=%@>",
            self.className, self, self.identifier,
            _preparationTrace.debugDescription,
            [_changesTraces valueForKey:@"debugDescription"],
            _cancellationTrace.debugDescription];
}

@end


@implementation WLAnimationSequence
{
    NSMutableArray<WLAnimationScene *> *_scenes;

    WLAnimationSequenceState _nextState; // state for the next scheduled scene
    WLAnimationStateReason _nextReason; // reason for the next scheduled scene
    WLAnimationStateReason _nextRunReason; // reason for the next scheduled run / resume

    BOOL _isRunScheduled;
    WLAnimationHandler _runCompletion;

    NSMutableArray<WLAnimationHandler> *_pauseCompletions;

    dispatch_time_t _cancellationRequestedAt;

    BOOL _isCurrentSceneCancelled;
    BOOL _isSequenceCancelled;

    BOOL _defaultAllowsImplicitAnimations;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _pauseCompletions = [NSMutableArray new];
        _scenes = [NSMutableArray new];
        _nextState = WLAnimationSequenceStateRunning;
    }

    return self;
}

- (void)dealloc
{
    switch (_state)
    {
        case WLAnimationSequenceStateNone:
            [[WLLog logForName:_WLAnimationLog] logDebug:@"%@ was allocated but not used", self];
            break;
        case WLAnimationSequenceStatePausing:
        case WLAnimationSequenceStatePaused:
        case WLAnimationSequenceStateRunning:
        case WLAnimationSequenceStateCancelling:
            [[WLLog logForName:_WLAnimationLog] logError:@"%@ is being deallocated while in-use", self];
            [self abort];
            break;
        case WLAnimationSequenceStateAborting:
        case WLAnimationSequenceStateAborted:
        case WLAnimationSequenceStateCompleted:
            break;
    }
}

#pragma mark Properties
@synthesize identifier;

+ (BOOL)automaticallyNotifiesObserversOfLinkedSequence
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfShouldSlowMotion
{
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingFinished
{
    return [NSSet setWithObject:@"state"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingRunning
{
    return [NSSet setWithObject:@"state"];
}

+ (BOOL)willAppKitSlowMotion
{
    __auto_type defaults = [NSUserDefaults.standardUserDefaults volatileDomainForName:NSArgumentDomain];
    BOOL willSlowMotion = [[defaults objectForKey:@"NSAnimationSlowMotionOnShift"] boolValue];;
    willSlowMotion = willSlowMotion && (NSEvent.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) == NSEventModifierFlagShift;
    return willSlowMotion;
}

- (void)setAutoCancellationPolicy:(WLAnimationCancellationPolicy)newAutoCancellationPolicy
{
    if (_state != WLAnimationSequenceStateNone)
        [NSException raise:NSInternalInconsistencyException
                    format:@"cannot change the policy: the sequence has invalid state %lu", _state];

    _autoCancellationPolicy = newAutoCancellationPolicy;
}

- (BOOL)isFinished
{
    switch (_state)
    {
        case WLAnimationSequenceStateNone:
        case WLAnimationSequenceStateRunning:
        case WLAnimationSequenceStatePausing:
        case WLAnimationSequenceStatePaused:
        case WLAnimationSequenceStateCancelling:
        case WLAnimationSequenceStateAborting:
            return NO;
        case WLAnimationSequenceStateAborted:
        case WLAnimationSequenceStateCompleted:
            return YES;
    }
}

- (BOOL)isRunning
{
    switch (_state)
    {
        case WLAnimationSequenceStateNone:
        case WLAnimationSequenceStatePaused:
        case WLAnimationSequenceStateAborted:
        case WLAnimationSequenceStateCompleted:
            return NO;
        case WLAnimationSequenceStateRunning:
        case WLAnimationSequenceStatePausing:
        case WLAnimationSequenceStateCancelling:
        case WLAnimationSequenceStateAborting:
            return YES;
    }
}

- (NSMutableArray<WLAnimationScene *> *)mutableScenes
{
    return [self mutableArrayValueForKey:@"scenes"];
}

- (NSUInteger)countOfScenes
{
    return _scenes.count;
}

- (WLAnimationScene *)objectInScenesAtIndex:(NSUInteger)anIndex
{
    return [_scenes objectAtIndex:anIndex];
}

- (void)insertObject:(WLAnimationScene *)aScene inScenesAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert(aScene.state == WLAnimationSceneStateNone);

    [_scenes insertObject:aScene atIndex:anIndex];
}

- (void)removeObjectFromScenesAtIndex:(NSUInteger)anIndex
{
    [_scenes removeObjectAtIndex:anIndex];
}

#pragma mark Methods

- (void)run
{
    [self runAfter:nil withReason:_nextRunReason completion:nil];
}

- (void)runWithCompletion:(WLAnimationHandler)aCompletion
{
    [self runAfter:nil withReason:_nextRunReason completion:aCompletion];
}

- (void)runWithReason:(WLAnimationStateReason)aReason
{
    [self runAfter:nil withReason:aReason completion:nil];
}

- (void)runWithReason:(WLAnimationStateReason)aReason completion:(WLAnimationHandler)aCompletion
{
    [self runAfter:nil withReason:aReason completion:aCompletion];
}

- (void)runAfter:(WLAnimationSequence *)aSequence
{
    [self runAfter:aSequence withReason:_nextRunReason completion:nil];
}

- (void)runAfter:(WLAnimationSequence *)aSequence withCompletion:(WLAnimationHandler)aCompletion
{
    [self runAfter:aSequence withReason:_nextRunReason completion:aCompletion];
}

- (void)runAfter:(WLAnimationSequence *)aSequence withReason:(WLAnimationStateReason)aReason
{
    [self runAfter:aSequence withReason:aReason completion:nil];
}

- (void)runAfter:(WLAnimationSequence *)aSequence
      withReason:(WLAnimationStateReason)aReason
      completion:(WLAnimationHandler)aCompletion
{
    NSParameterAssert(NSThread.isMainThread);

    aReason = (aReason == WLAnimationStateReasonInherit) ? _nextRunReason : aReason;

    os_activity_initiate("-[WLAnimationSequence runAfter:withReason:completion:]", OS_ACTIVITY_FLAG_DEFAULT, ^{
        os_trace_debug("reason %ld", aReason);

        if (_isRunScheduled)
            [NSException raise:NSInternalInconsistencyException format:@"cannot run animation sequence more than once"];

        _isRunScheduled = YES;

        _nextRunReason = aReason;
        _runCompletion = aCompletion;
        [self _captureDefaultAnimationSettings];

        if (aSequence && aSequence.state != WLAnimationSequenceStateCompleted && aSequence.state != WLAnimationSequenceStateAborted)
            aSequence.linkedSequence = self;
        else if (aSequence && aSequence.state == WLAnimationSequenceStateAborted)
        {
            [self abortWithReason:WLAnimationStateReasonPrecedingSequenceDidAbort];
            [self _run];
        }
        else
            [self _run];
    });
}

- (void)pause
{
    [self pauseWithReason:WLAnimationStateReasonNone completion:nil];
}

- (void)pauseWithCompletion:(WLAnimationHandler)aCompletion
{
    [self pauseWithReason:WLAnimationStateReasonNone completion:aCompletion];
}

- (void)pauseWithReason:(WLAnimationStateReason)aReason
{
    [self pauseWithReason:aReason completion:nil];
}

- (void)pauseWithReason:(WLAnimationStateReason)aReason completion:(WLAnimationHandler)aCompletion
{
    NSParameterAssert(NSThread.isMainThread);

    aReason = (aReason == WLAnimationStateReasonInherit) ? _stateReason : aReason;

    os_activity_initiate("-[WLAnimationSequence pauseWithReason:completion:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        os_trace_debug("reason %ld", aReason);

        if (aCompletion)
            [_pauseCompletions addObject:aCompletion];

        switch (_state)
        {
            case WLAnimationSequenceStateNone:
                switch (_nextState)
                {
                    case WLAnimationSequenceStateRunning:
                        _nextState = WLAnimationSequenceStatePausing;
                        _nextReason = aReason;
                        break;
                    case WLAnimationSequenceStatePausing:
                    case WLAnimationSequenceStateCancelling:
                    case WLAnimationSequenceStateAborting:
                        break;
                    case WLAnimationSequenceStateNone:
                    case WLAnimationSequenceStatePaused:
                    case WLAnimationSequenceStateAborted:
                    case WLAnimationSequenceStateCompleted:
                        [NSException raise:NSInternalInconsistencyException format:@"invalid next state %lu", _nextState];
                        break;
                }

                break;
            case WLAnimationSequenceStateRunning:
                [self _setState:WLAnimationSequenceStatePausing withReason:aReason];
                [self _cancelCurrentSceneIfNeeded];
                break;
            case WLAnimationSequenceStatePausing:
                _nextState = WLAnimationSequenceStatePausing;
                break;
            case WLAnimationSequenceStateCancelling:
            case WLAnimationSequenceStateAborting:
                break;
            case WLAnimationSequenceStatePaused:
            case WLAnimationSequenceStateAborted:
            case WLAnimationSequenceStateCompleted:
                if (_pauseCompletions.count)
                {
                    WLNoReentryScope(&_reentryCanary);
                    _pauseCompletions.lastObject(self);
                    [_pauseCompletions removeLastObject];
                }
                break;
        }
    }));
}

- (void)resume
{
    [self resumeWithReason:_nextRunReason];
}

- (void)resumeWithReason:(WLAnimationStateReason)aReason
{
    NSParameterAssert(NSThread.isMainThread);

    aReason = (aReason == WLAnimationStateReasonInherit) ? _stateReason : aReason;

    os_activity_initiate("-[WLAnimationSequence resumeWithReason:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        os_trace_debug("reason %ld", aReason);

        switch (_state)
        {
            case WLAnimationSequenceStateNone:
                switch (_nextState)
                {
                    case WLAnimationSequenceStateRunning:
                    case WLAnimationSequenceStatePausing:
                    {
                        _nextRunReason = aReason;
                        _nextReason = aReason;
                        _nextState = WLAnimationSequenceStateRunning;
                        break;
                    }
                    case WLAnimationSequenceStateCancelling:
                    case WLAnimationSequenceStateAborting:
                        break;
                    case WLAnimationSequenceStateNone:
                    case WLAnimationSequenceStatePaused:
                    case WLAnimationSequenceStateAborted:
                    case WLAnimationSequenceStateCompleted:
                        [NSException raise:NSInternalInconsistencyException format:@"invalid next state %lu", _nextState];
                        break;
                }

                break;
            case WLAnimationSequenceStatePausing:
                _nextRunReason = aReason;
                _nextState = WLAnimationSequenceStateRunning;
                break;
            case WLAnimationSequenceStatePaused:
                _nextRunReason = aReason;
                [self _setState:WLAnimationSequenceStateRunning withReason:aReason];
                [self _runNextScene];
                break;
            case WLAnimationSequenceStateRunning:
            case WLAnimationSequenceStateCancelling:
            case WLAnimationSequenceStateAborting:
            case WLAnimationSequenceStateAborted:
            case WLAnimationSequenceStateCompleted:
                break;
        }
    }));
}

- (void)cancel
{
    [self cancelWithReason:WLAnimationStateReasonNone];
}

- (void)cancelWithReason:(WLAnimationStateReason)aReason
{
    NSParameterAssert(NSThread.isMainThread);

    aReason = (aReason == WLAnimationStateReasonInherit) ? _stateReason : aReason;

    os_activity_initiate("-[WLAnimationSequence cancelWithReason:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        os_trace_debug("reason %ld", aReason);

        switch (_state)
        {
            case WLAnimationSequenceStateNone:
                switch (_nextState)
                {
                    case WLAnimationSequenceStateRunning:
                    case WLAnimationSequenceStatePausing:
                    {
                        _nextReason = aReason;
                        _nextState = WLAnimationSequenceStateCancelling;
                        break;
                    }
                    case WLAnimationSequenceStateCancelling:
                    case WLAnimationSequenceStateAborting:
                        break;
                    case WLAnimationSequenceStateNone:
                    case WLAnimationSequenceStatePaused:
                    case WLAnimationSequenceStateAborted:
                    case WLAnimationSequenceStateCompleted:
                        [NSException raise:NSInternalInconsistencyException format:@"invalid next state %lu", _nextState];
                        break;
                }

                break;
            case WLAnimationSequenceStateRunning:
            case WLAnimationSequenceStatePausing:
                [self _setState:WLAnimationSequenceStateCancelling withReason:aReason];
                [self _cancelCurrentSceneIfNeeded];
                [self _cancelSequenceIfNeeded];
                break;
            case WLAnimationSequenceStatePaused:
                [self _setState:WLAnimationSequenceStateCancelling withReason:aReason];
                [self _runNextScene];
                break;
            case WLAnimationSequenceStateCancelling:
            case WLAnimationSequenceStateAborting:
            case WLAnimationSequenceStateAborted:
            case WLAnimationSequenceStateCompleted:
                break;
        }
    }));
}

- (void)abort
{
    [self abortWithReason:WLAnimationStateReasonNone];
}

- (void)abortWithReason:(WLAnimationStateReason)aReason
{
    NSParameterAssert(NSThread.isMainThread);

    aReason = (aReason == WLAnimationStateReasonInherit) ? self.stateReason : aReason;

    os_activity_initiate("-[WLAnimationSequence abortWithReason:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        os_trace_debug("reason %ld", aReason);

        switch (_state)
        {
            case WLAnimationSequenceStateNone:
                switch (_nextState)
                {
                    case WLAnimationSequenceStateRunning:
                    case WLAnimationSequenceStatePausing:
                    case WLAnimationSequenceStateCancelling:
                    {
                        _nextReason = aReason;
                        _nextState = WLAnimationSequenceStateAborting;
                        break;
                    }
                    case WLAnimationSequenceStateAborting:
                        break;
                    case WLAnimationSequenceStateNone:
                    case WLAnimationSequenceStatePaused:
                    case WLAnimationSequenceStateAborted:
                    case WLAnimationSequenceStateCompleted:
                        [NSException raise:NSInternalInconsistencyException format:@"invalid next state %lu", _nextState];
                        break;
                }

                break;
            case WLAnimationSequenceStateRunning:
            case WLAnimationSequenceStatePausing:
            case WLAnimationSequenceStateCancelling:
                [self _setState:WLAnimationSequenceStateAborting withReason:aReason];
                [self _cancelCurrentSceneIfNeeded];
                [self _cancelSequenceIfNeeded];
                break;
            case WLAnimationSequenceStatePaused:
                [self _setState:WLAnimationSequenceStateAborted withReason:aReason];
                [self _sequenceDidComplete];
                break;
            case WLAnimationSequenceStateAborting:
            case WLAnimationSequenceStateAborted:
            case WLAnimationSequenceStateCompleted:
                break;
        }
    }));
}

- (void)sceneDidComplete:(WLAnimationScene *)aScene;
{
    NSParameterAssert(aScene == _currentScene);

    os_activity_initiate("-[WLAnimationSequence sceneDidComplete:]", OS_ACTIVITY_FLAG_DEFAULT, (^{
        if (!_scenes.count)
        {
            switch (_state) {
                case WLAnimationSequenceStateRunning:
                case WLAnimationSequenceStatePausing:
                    [self _performPauseCompletionsWithState:_state reason:_nextRunReason];
                    [self _setState:WLAnimationSequenceStateCompleted withReason:_nextRunReason];
                    [self _sequenceDidComplete];
                    break;
                case WLAnimationSequenceStateCancelling:
                    [self _performPauseCompletionsWithState:_state reason:_stateReason];
                    [self _setState:WLAnimationSequenceStateCompleted withReason:_stateReason];
                    [self _sequenceDidComplete];
                    break;
                case WLAnimationSequenceStateAborting:
                    [self _performPauseCompletionsWithState:_state reason:_stateReason];
                    [self _setState:WLAnimationSequenceStateAborted withReason:_stateReason];
                    [self _sequenceDidComplete];
                    break;
                case WLAnimationSequenceStateNone:
                case WLAnimationSequenceStatePaused:
                case WLAnimationSequenceStateAborted:
                case WLAnimationSequenceStateCompleted:
                    [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
                    break;
            }
        }
        else
        {
            switch (_state)
            {
                case WLAnimationSequenceStateRunning:
                    [self _runNextScene];
                    break;
                case WLAnimationSequenceStatePausing:
                    [self _performPauseCompletionsWithState:_state reason:_stateReason];

                    switch (_nextState)
                    {
                        case WLAnimationSequenceStateRunning:
                            [self _setState:WLAnimationSequenceStateRunning withReason:_nextRunReason];
                            [self _runNextScene];
                            break;
                        case WLAnimationSequenceStatePausing:
                            [self _setState:WLAnimationSequenceStatePaused withReason:_stateReason];
                            break;
                        case WLAnimationSequenceStateCancelling:
                        case WLAnimationSequenceStateAborting:
                        case WLAnimationSequenceStateNone:
                        case WLAnimationSequenceStatePaused:
                        case WLAnimationSequenceStateAborted:
                        case WLAnimationSequenceStateCompleted:
                            break;
                    }

                    break;
                case WLAnimationSequenceStateCancelling:
                    [self _logCancellationDuration];

                    if ([self _cancelSequenceIfNeeded])
                    {
                        [self _performPauseCompletionsWithState:_state reason:_stateReason];
                        [self _setState:WLAnimationSequenceStateCompleted withReason:_stateReason];
                        [self _sequenceDidComplete];
                    }
                    else
                        [self _runNextScene];

                    break;
                case WLAnimationSequenceStateAborting:
                    [self _logCancellationDuration];

                    [self _performPauseCompletionsWithState:_state reason:_stateReason];
                    [self _setState:WLAnimationSequenceStateAborted withReason:_stateReason];
                    [self _sequenceDidComplete];
                    break;
                case WLAnimationSequenceStateNone:
                case WLAnimationSequenceStatePaused:
                case WLAnimationSequenceStateAborted:
                case WLAnimationSequenceStateCompleted:
                    [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
                    break;
            }
        }
    }));
}

#pragma mark Scene Lookup

- (nullable WLAnimationScene *)sceneWithIdentifier:(NSUserInterfaceItemIdentifier)anIdentifier
{
    if ([_currentScene.identifier isEqual:anIdentifier])
        return _currentScene;
    else
    {
        NSUInteger i = [_scenes indexOfObjectPassingTest:^BOOL(WLAnimationScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.identifier isEqual:anIdentifier];
        }];

        if (i != NSNotFound)
            return _scenes[i];
        else
            return nil;
    }
}

- (BOOL)containsScene:(WLAnimationScene *)aScene
{
    return [_currentScene isEqual:aScene] || [_scenes containsObject:aScene];
}

#pragma mark Private

- (void)_setState:(WLAnimationSequenceState)newState withReason:(WLAnimationStateReason)newReason
{
    NSParameterAssert(newReason != WLAnimationStateReasonInherit);

    WLNoReentryScope(&_reentryCanary);

    BOOL shouldChangeState = newState != _state;
    BOOL shouldChangeReason = newReason != _stateReason;

    if (shouldChangeState)
        [self willChangeValueForKey:@"state"];

    if (shouldChangeReason)
        [self willChangeValueForKey:@"stateReason"];

    _state = newState;
    _stateReason = newReason;

    if (shouldChangeReason)
        [self didChangeValueForKey:@"stateReason"];

    if (shouldChangeState)
        [self didChangeValueForKey:@"state"];
}

- (void)_cancelCurrentSceneIfNeeded
{
    if (_isCurrentSceneCancelled)
        return;

    os_trace_debug("#Animation cancelling current scene");
    [_currentScene cancel];
    _cancellationRequestedAt = dispatch_time(DISPATCH_TIME_NOW, 0);
    _isCurrentSceneCancelled = YES;
}

- (BOOL)_cancelSequenceIfNeeded
{
    if (!_isSequenceCancelled && _cancellationHandler && _cancellationHandler != WLAnimationHandlerNoop)
    {
        os_trace_debug("#Animation cancelling sequence");
        _cancellationRequestedAt = dispatch_time(DISPATCH_TIME_NOW, 0);
        _isSequenceCancelled = YES;
        WLNoReentryScope(&_reentryCanary);
        _cancellationHandler(self);
        return YES;
    }
    else
        return _isSequenceCancelled;
}

- (void)_performPauseCompletionsWithState:(WLAnimationSequenceState)aState reason:(WLAnimationStateReason)aReason
{
    if (_pauseCompletions.count)
    {
        [self _setState:aState withReason:aReason];

        while (_pauseCompletions.count)
        {
            _pauseCompletions[0](self);
            [_pauseCompletions removeObjectAtIndex:0];
        }
    }
}

- (void)_captureDefaultAnimationSettings
{
    NSAnimationContext *context = NSAnimationContext.currentContext;

    _shouldSlowMotion = [self.class willAppKitSlowMotion];

    // If NSAnimationSlowMotion is set then motion is already slowed down by AppKit.
    if ([[CATransaction valueForKey:@"NSAnimationSlowMotion"] boolValue])
        _defaultDuration = context.duration / 10.0;
    else
        _defaultDuration = context.duration;

    _defaultTimingFunction = context.timingFunction;
    _defaultAllowsImplicitAnimations = context.allowsImplicitAnimation;
}

- (void)_run
{
    [self _registerAutoCancellationObservers];

    NSParameterAssert(_nextState == WLAnimationSequenceStateRunning ||
                      _nextState == WLAnimationSequenceStatePausing ||
                      _nextState == WLAnimationSequenceStateCancelling ||
                      _nextState == WLAnimationSequenceStateAborting);

    WLAnimationStateReason nextReason = WLAnimationStateReasonNone;

    switch (_nextState)
    {
        case WLAnimationSequenceStateRunning:
            nextReason = _nextRunReason;
            break;
        case WLAnimationSequenceStateCancelling:
        case WLAnimationSequenceStatePausing:
        case WLAnimationSequenceStateAborting:
            nextReason = _nextReason;
            break;
        case WLAnimationSequenceStateNone:
        case WLAnimationSequenceStatePaused:
        case WLAnimationSequenceStateAborted:
        case WLAnimationSequenceStateCompleted:
            [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
            break;
    }

    [self _performPauseCompletionsWithState:_nextState reason:nextReason];
    [self _setState:_nextState withReason:nextReason];
    [self sceneDidComplete:_currentScene];
}

- (void)_runLinkedSequence
{
    __auto_type linkedSequence = self.linkedSequence;
    self.linkedSequence = nil;

    if (linkedSequence)
    {
        if (_state == WLAnimationSequenceStateAborted)
            [linkedSequence abortWithReason:WLAnimationStateReasonPrecedingSequenceDidAbort];

        [linkedSequence _run];
    }
}

- (void)_runNextScene
{
    NSParameterAssert(_state == WLAnimationSequenceStateRunning ||
                      _state == WLAnimationSequenceStateCancelling);

    if (!_scenes.count)
    {
        [self sceneDidComplete:_currentScene];
        return;
    }

    {
        WLNoReentryScope(&_reentryCanary);
        [self willChangeValueForKey:@"currentScene"];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"scenes"];
        _isCurrentSceneCancelled = NO;
        _currentScene = _scenes[0];
        [_scenes removeObjectAtIndex:0];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"scenes"];
        [self didChangeValueForKey:@"currentScene"];
    }

    switch (_state)
    {
        case WLAnimationSequenceStateRunning:
            [_currentScene run:self];
            break;
        case WLAnimationSequenceStateCancelling:
            [self _cancelCurrentSceneIfNeeded];
            [_currentScene run:self];
            break;
        case WLAnimationSequenceStateNone:
        case WLAnimationSequenceStatePausing:
        case WLAnimationSequenceStatePaused:
        case WLAnimationSequenceStateAborting:
        case WLAnimationSequenceStateAborted:
        case WLAnimationSequenceStateCompleted:
            [NSException raise:NSInternalInconsistencyException format:@"invalid state %lu", _state];
            break;
    }
}

- (void)_sequenceDidComplete
{
    NSParameterAssert(!_pauseCompletions.count);
    NSParameterAssert(_state == WLAnimationSequenceStateAborted || _state == WLAnimationSequenceStateCompleted);

    [self _unregisterAutoCancellationObservers];

    os_trace_debug("#Animation completing sequence with %lu remaining scenes", _scenes.count);

    {
        WLNoReentryScope(&_reentryCanary);
        __auto_type allScenesIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _scenes.count)];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:allScenesIndexes forKey:@"scenes"];
        [_scenes removeAllObjects];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:allScenesIndexes forKey:@"scenes"];
    }

    _currentScene = nil;

    if (_runCompletion)
    {
        WLNoReentryScope(&_reentryCanary);
        _runCompletion(self);
    }

    _runCompletion = nil;

    [self _runLinkedSequence];
}

- (void)_logCancellationDuration
{
    dispatch_time_t cancellationCompletedAt = dispatch_time(DISPATCH_TIME_NOW, 0);
    dispatch_time_t cancellationDuration = cancellationCompletedAt - _cancellationRequestedAt;

    if (cancellationDuration > _WLAnimationCancellationTolerance)
        os_trace_error("#Animation cancellation took too long: %llu", cancellationDuration);
}

- (void)_registerAutoCancellationObservers
{
    id owner = _owner;

    if (self.autoCancellationPolicy & WLAnimationCancellationPolicyOnAppHide)
    {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(_applicationDidHide:)
                                                   name:NSApplicationDidHideNotification
                                                 object:NSApp];
    }

    if (self.autoCancellationPolicy & WLAnimationCancellationPolicyOnAppTermination)
    {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(_applicationWillTerminate:)
                                                   name:NSApplicationWillTerminateNotification
                                                 object:NSApp];
    }

    if (owner && self.autoCancellationPolicy & WLAnimationCancellationPolicyOnOwnerNotification)
    {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(_ownerDidNotify:)
                                                   name:WLAnimationShouldCancelNotification
                                                 object:owner];
    }
}

- (void)_unregisterAutoCancellationObservers
{
    id owner = _owner;

    if (self.autoCancellationPolicy & WLAnimationCancellationPolicyOnAppHide)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSApplicationDidHideNotification
                                                    object:NSApp];
    }

    if (self.autoCancellationPolicy & WLAnimationCancellationPolicyOnAppTermination)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSApplicationWillTerminateNotification
                                                    object:NSApp];
    }

    if (owner && self.autoCancellationPolicy & WLAnimationCancellationPolicyOnOwnerNotification)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:WLAnimationShouldCancelNotification
                                                    object:owner];
    }
}

- (void)_applicationDidHide:(NSNotification *)aNotification
{
    NSParameterAssert(_state != WLAnimationSequenceStateCompleted && _state != WLAnimationSequenceStateAborted);
    [self cancelWithReason:WLAnimationStateReasonAppDidHide];
}

- (void)_applicationWillTerminate:(NSNotification *)aNotification
{
    NSParameterAssert(_state != WLAnimationSequenceStateCompleted && _state != WLAnimationSequenceStateAborted);
    [self cancelWithReason:WLAnimationStateReasonAppWillTerminate];
}

- (void)_ownerDidNotify:(NSNotification *)aNotification
{
    NSParameterAssert(_state != WLAnimationSequenceStateCompleted && _state != WLAnimationSequenceStateAborted);
    [self cancelWithReason:WLAnimationStateReasonOwnerDidNotify];
}

#pragma mark NSObject

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p; %@>", self.className, self, self.identifier];
}

@end

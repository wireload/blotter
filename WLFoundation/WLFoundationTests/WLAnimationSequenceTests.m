//
//  WLAnimationSequenceTests.m
//  WLFoundationTests
//
//  Created by Ilya Kulakov on 12/18/19.
//  Copyright © 2019 Wireload. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <WLFoundation/WLFoundation.h>


@interface WLAnimationSequenceTests : XCTestCase

@property WLAnimationSequence *sequence;

@end


@implementation WLAnimationSequenceTests

- (void)setUp
{
    _sequence = [WLAnimationSequence new];
}

- (XCTestExpectation *)callbackExpectationWithDescription:(NSString *)aDescription
{
    __auto_type e = [self expectationWithDescription:aDescription];
    e.assertForOverFulfill = YES;
    return e;
}

#pragma mark - Only Run Once

- (void)testSequenceCanBeOnlyRunOnce
{
    [self.sequence run];
    XCTAssertThrows([self.sequence run]);
}

- (void)testPausedSequenceCanBeOnlyRunOnce
{
    [self.sequence pause];
    [self.sequence run];
    XCTAssertThrows([self.sequence run]);
}

- (void)testResumedSeqenceCanBeOnlyRunOnce
{
    [self.sequence resume];
    [self.sequence run];
    XCTAssertThrows([self.sequence run]);
}

- (void)testCancelledSeqenceCanBeOnlyRunOnce
{
    [self.sequence cancel];
    [self.sequence run];
    XCTAssertThrows([self.sequence run]);
}

#pragma mark - Before Run

- (void)test_SequenceState_BeforeRun
{
    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateNone);
    XCTAssertEqual(self.sequence.stateReason, WLAnimationStateReasonNone);
}

- (void)test_SequenceState_Pause_BeforeRun
{
    [self.sequence pauseWithReason:42];
    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateNone);
    XCTAssertEqual(self.sequence.stateReason, WLAnimationStateReasonNone);
}

- (void)test_SequenceState_Resume_BeforeRun
{
    [self.sequence resumeWithReason:42];
    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateNone);
    XCTAssertEqual(self.sequence.stateReason, WLAnimationStateReasonNone);
}

- (void)test_SequenceState_Cancel_BeforeRun
{
    [self.sequence cancelWithReason:42];
    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateNone);
    XCTAssertEqual(self.sequence.stateReason, WLAnimationStateReasonNone);
}

- (void)test_SequenceState_Abort_BeforeRun
{
    [self.sequence abortWithReason:42];
    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateNone);
    XCTAssertEqual(self.sequence.stateReason, WLAnimationStateReasonNone);
}

- (void)test_PauseCompletionIsDelayed_BeforeRun
{
    [XCTContext runActivityNamed:@"Pause Only" block:^(id<XCTActivity> activity) {
        __auto_type isCalled = [self callbackExpectationWithDescription:@"pause completion"];
        isCalled.inverted = YES;
        [self.sequence pauseWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
            [isCalled fulfill];
        }];
        [self waitForExpectations:@[isCalled] timeout:0.0];
    }];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    // All methods return `void`.
    NSArray<NSValue *> *actions = @[
        [NSValue valueWithPointer:@selector(pause)],
        [NSValue valueWithPointer:@selector(resume)],
        [NSValue valueWithPointer:@selector(cancel)],
        [NSValue valueWithPointer:@selector(abort)]
    ];

    for (NSValue *a in actions)
    {
        SEL action = (SEL)a.pointerValue;

        [XCTContext runActivityNamed:[NSString stringWithFormat:@"%@ Before Pause", NSStringFromSelector(action).capitalizedString]
                               block:^(id<XCTActivity> anActivity)
        {
            __auto_type isCalled = [self callbackExpectationWithDescription:@"pause completion"];
            isCalled.inverted = YES;
            [self.sequence performSelector:action];
            [self.sequence pauseWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                [isCalled fulfill];
            }];
            [self waitForExpectations:@[isCalled] timeout:0.0];
        }];

        [XCTContext runActivityNamed:[NSString stringWithFormat:@"%@ After Pause", NSStringFromSelector(action).capitalizedString]
                               block:^(id<XCTActivity> anActivity)
         {
            __auto_type isCalled = [self callbackExpectationWithDescription:@"pause completion"];
            isCalled.inverted = YES;
            [self.sequence pauseWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                [isCalled fulfill];
            }];
            [self.sequence performSelector:action];
            [self waitForExpectations:@[isCalled] timeout:0.0];
        }];
    }

#pragma clang diagnostic pop
}

#pragma mark - After Run (Empty)

- (void)test_RunCompletionIsCalledImmediately_AfterRun_IfEmpty
{
    __auto_type isCalled = [self callbackExpectationWithDescription:@"run completion"];
    [self.sequence runWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
        [isCalled fulfill];
    }];
    [self waitForExpectations:@[isCalled] timeout:0.0];
}

- (void)test_PauseCompletionIsRunImmediately_AfterRun_IfEmpty
{
    [XCTContext runActivityNamed:@"Pause Only" block:^(id<XCTActivity> activity) {
        __auto_type isPauseCompletionCalled = [self callbackExpectationWithDescription:@"pause completion"];
        __auto_type isRunCompletionCalled = [self callbackExpectationWithDescription:@"run completion"];

        __auto_type sequence = [WLAnimationSequence new];

        [sequence pauseWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
            [isPauseCompletionCalled fulfill];
        }];

        [sequence runWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
            [isRunCompletionCalled fulfill];
        }];

        [self waitForExpectations:@[isPauseCompletionCalled, isRunCompletionCalled] timeout:0.0 enforceOrder:YES];
    }];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    // All methods return `void`.
    NSArray<NSValue *> *actions = @[
        [NSValue valueWithPointer:@selector(pause)],
        [NSValue valueWithPointer:@selector(resume)],
        [NSValue valueWithPointer:@selector(cancel)],
        [NSValue valueWithPointer:@selector(abort)]
    ];

    for (NSValue *a in actions)
    {
        SEL action = (SEL)a.pointerValue;

        [XCTContext runActivityNamed:[NSString stringWithFormat:@"%@ Before Pause", NSStringFromSelector(action).capitalizedString]
                               block:^(id<XCTActivity> anActivity)
         {
            __auto_type isPauseCompletionCalled = [self callbackExpectationWithDescription:@"pause completion"];
            __auto_type isRunCompletionCalled = [self callbackExpectationWithDescription:@"run completion"];

            __auto_type sequence = [WLAnimationSequence new];

            [sequence performSelector:action];

            [sequence pauseWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                [isPauseCompletionCalled fulfill];
            }];

            [sequence runWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                [isRunCompletionCalled fulfill];
            }];

            [self waitForExpectations:@[isPauseCompletionCalled, isRunCompletionCalled] timeout:0.0 enforceOrder:YES];
        }];

        [XCTContext runActivityNamed:[NSString stringWithFormat:@"%@ After Pause", NSStringFromSelector(action).capitalizedString]
                               block:^(id<XCTActivity> anActivity)
         {
            __auto_type isPauseCompletionCalled = [self callbackExpectationWithDescription:@"pause completion"];
            __auto_type isRunCompletionCalled = [self callbackExpectationWithDescription:@"run completion"];

            __auto_type sequence = [WLAnimationSequence new];

            [sequence pauseWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                [isPauseCompletionCalled fulfill];
            }];

            [sequence performSelector:action];

            [sequence runWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
                [isRunCompletionCalled fulfill];
            }];

            [self waitForExpectations:@[isPauseCompletionCalled, isRunCompletionCalled] timeout:0.0 enforceOrder:YES];
        }];
    }

#pragma clang diagnostic pop
}

- (void)test_SequenceState_Pause_AfterRun_Empty
{
    [self.sequence pauseWithReason:42 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStatePausing);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence runWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCompleted);
        XCTAssertEqual(aSequence.stateReason, 43);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateCompleted);
    XCTAssertEqual(self.sequence.stateReason, 43);
}

- (void)test_SequenceState_Resume_Pause_AfterRun_Empty
{
    [self.sequence resumeWithReason:42];
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStatePausing);
        XCTAssertEqual(aSequence.stateReason, 43);
    }];
    [self.sequence runWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCompleted);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateCompleted);
    XCTAssertEqual(self.sequence.stateReason, 42);
}

- (void)test_SequenceState_Pause_Resume_AfterRun_Empty
{
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateRunning);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence resumeWithReason:42];
    [self.sequence runWithCompletion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCompleted);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateCompleted);
    XCTAssertEqual(self.sequence.stateReason, 42);
}

- (void)test_SequenceState_Pause_Pause_AfterRun_Empty
{
    [self.sequence pauseWithReason:42 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStatePausing);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStatePausing);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence runWithReason:44 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCompleted);
        XCTAssertEqual(aSequence.stateReason, 44);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateCompleted);
    XCTAssertEqual(self.sequence.stateReason, 44);
}

- (void)test_SequenceState_Cancel_Pause_AfterRun_Empty
{
    [self.sequence cancelWithReason:42];
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCancelling);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence runWithReason:44 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCompleted);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateCompleted);
    XCTAssertEqual(self.sequence.stateReason, 42);
}

- (void)test_SequenceState_Pause_Cancel_AfterRun_Empty
{
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCancelling);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence cancelWithReason:42];
    [self.sequence runWithReason:44 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateCompleted);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateCompleted);
    XCTAssertEqual(self.sequence.stateReason, 42);
}

- (void)test_SequenceState_Abort_Pause_AfterRun_Empty
{
    [self.sequence abortWithReason:42];
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateAborting);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence runWithReason:44 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateAborted);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateAborted);
    XCTAssertEqual(self.sequence.stateReason, 42);
}

- (void)test_SequenceState_Pause_Abort_AfterRun_Empty
{
    [self.sequence pauseWithReason:43 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateAborting);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];
    [self.sequence abortWithReason:42];
    [self.sequence runWithReason:44 completion:^(WLAnimationSequence * _Nonnull aSequence) {
        XCTAssertNil(aSequence.currentScene);
        XCTAssertEqual(aSequence.state, WLAnimationSequenceStateAborted);
        XCTAssertEqual(aSequence.stateReason, 42);
    }];

    XCTAssertNil(self.sequence.currentScene);
    XCTAssertEqual(self.sequence.state, WLAnimationSequenceStateAborted);
    XCTAssertEqual(self.sequence.stateReason, 42);
}

#pragma mark -

- (void)test_SequenceCancellationIsCalledImmediately_AfterRun
{
    [self.sequence.mutableScenes addObject:[WLAnimationScene sceneWithChanges:^(WLAnimationSequence * _Nonnull aSequence) {}]];

    __auto_type isCalled = [self callbackExpectationWithDescription:@"sequence cancellation"];
    self.sequence.cancellationHandler = ^(WLAnimationSequence * _Nonnull aSequence) {
        [isCalled fulfill];
    };
    [self.sequence cancel];
    [self.sequence run];
    [self waitForExpectations:@[isCalled] timeout:0.0];
}

@end

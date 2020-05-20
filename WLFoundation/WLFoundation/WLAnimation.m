//
//  WLAnimation.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 2/28/20.
//  Copyright © 2020 Wireload. All rights reserved.
//

#import <objc/runtime.h>

#import "WLAnimation.h"


@implementation WLWeakAnimationDelegateProxy

- (instancetype)initWithDelegate:(id<CAAnimationDelegate>)aDelegate
{
    self = [self init];

    if (self)
        _delegate = aDelegate;

    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [_delegate respondsToSelector:aSelector];
}

- (void)animationDidStart:(CAAnimation *)anAnimation
{
    __auto_type strongDelegate = self.delegate;

    if ([strongDelegate respondsToSelector:@selector(animationDidStart:)])
        [strongDelegate animationDidStart:anAnimation];
}

- (void)animationDidStop:(CAAnimation *)anAnimation finished:(BOOL)anIsFinished
{
    __auto_type strongDelegate = self.delegate;

    if ([strongDelegate respondsToSelector:@selector(animationDidStop:finished:)])
        [strongDelegate animationDidStop:anAnimation finished:anIsFinished];
}

@end


@implementation WLBasicAnimation

#pragma mark NSUserInterfaceItemIdentification
@synthesize identifier;

#pragma mark CAAnimation

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    self.identifier = [aCoder decodeObjectOfClass:NSString.class forKey:@"WLIdentifier"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [self encodeWithCoder:aCoder];
    [aCoder encodeObject:self.identifier forKey:@"WLIdentifier"];
}

- (id)copyWithZone:(NSZone *)aZone
{
    WLBasicAnimation *c = [super copyWithZone:aZone];
    c.identifier = [self.identifier copy];
    return c;
}

@end


@implementation CALayer (WLAnimation)

- (void)WL_performRecursively:(NS_NOESCAPE void (^)(CALayer *aLayer))aBlock
{
    aBlock(self);
    for (CALayer *l in self.sublayers)
        [l WL_performRecursively:aBlock];
}

- (NSArray<NSString *> *)WL_animationKeysWithPrefix:(NSString *)aPrefix
{
    __auto_type p = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", aPrefix];
    return [self.animationKeys filteredArrayUsingPredicate:p];
}

- (void)WL_removeAnimationsWithPrefix:(NSString *)aPrefix
{
    for (NSString *k in [self WL_animationKeysWithPrefix:aPrefix])
        [self removeAnimationForKey:k];
}

@end


@implementation CATransaction (WLBlocks)

+ (void)WL_performWithDisabledActions:(NS_NOESCAPE void (^)(void))aBlock
{
    BOOL old = [self disableActions];

    [self setDisableActions:YES];
    aBlock();
    [self setDisableActions:old];
}

@end


@implementation NSWindow (WLAnimation)

- (NSTimeInterval)WL_animationResizeTimeForView:(NSView *)aView newFrameSize:(NSSize)newSize
{
    NSAssert(aView.window == self, @"view must belong to the window");

    NSRect currentViewFrameOnScreen = [aView convertRect:aView.bounds toView:nil];
    currentViewFrameOnScreen = [aView.window convertRectToScreen:currentViewFrameOnScreen];

    CGFloat scale = NSWidth(currentViewFrameOnScreen) / NSWidth(aView.frame);
    NSSize diff = NSMakeSize((newSize.width - NSWidth(aView.frame)) * scale,
                             (newSize.height - NSHeight(aView.frame) * scale));

    NSRect newWindowFrameOnScreen = self.frame;
    newWindowFrameOnScreen.size.width += diff.width;
    newWindowFrameOnScreen.size.height += diff.height;

    if (aView.superview.isFlipped)
        newWindowFrameOnScreen.origin.y -= diff.height;

    return [self animationResizeTime:newWindowFrameOnScreen];
}

@end

#pragma mark - WLInterpolation

static NSString* const _WLPolynomialCoefficientsToken = @"WLPolynomialCoefficientsToken";

static const float _WLEpsilon = 1e-5f;

typedef struct {
    float cx;
    float bx;
    float ax;
    float cy;
    float by;
    float ay;
} PolynomialCoefficients;


@implementation CAMediaTimingFunction (WLInterpolation)

NS_INLINE float xAtT(float t, PolynomialCoefficients coeffs)
{
    // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
    return ((coeffs.ax * t + coeffs.bx) * t + coeffs.cx) * t;
}

NS_INLINE float derivativeXAtT(float t, PolynomialCoefficients coeffs)
{
    return (3.f * coeffs.ax * t + 2.f * coeffs.bx) * t + coeffs.cx;
}

NS_INLINE float yAtT(float t, PolynomialCoefficients coeffs)
{
    return ((coeffs.ay * t + coeffs.by) * t + coeffs.cy) * t;
}

NS_INLINE float tWithX(float x, PolynomialCoefficients coeffs)
{
    // Given an x value, find a parametric value it came from (t is not the time).
    float t0 = 0.f;
    float t1 = 0.f;
    float t2 = x;
    float x2 = 0.f;
    float d2 = 0.f;

    // First try a few iterations of Newton's method -- normally very fast
    for (int i = 0; i < 8; i++)
    {
        x2 = xAtT(t2, coeffs) - x;
        if (isless(fabsf(x2), _WLEpsilon))
            return t2;

        d2 = derivativeXAtT(t2, coeffs);
        if (isless(fabsf(d2), 1e-6f /* fixed tolerance for small denominators */))
            break;

        t2 -= x2 / d2;
    }

    // Fall back to the bissection method for reliability
    t0 = 0.f;
    t1 = 1.f;
    t2 = x;

    if (isless(t2, t0))
        return t0;

    if (isgreater(t2, t1))
        return t1;

    while (isless(t0, t1))
    {
        x2 = xAtT(t2, coeffs);
        if (isless(fabsf(x2 - x), _WLEpsilon))
            return t2;

        if (isgreater(x, x2))
            t0 = t2;
        else
            t1 = t2;

        t2 = (t1 - t0) * 0.5f + t0;
    }

    // Failure
    return t2;
}

- (instancetype)WL_reversed
{
    float c1[2] = { 0.0f };
    float c2[2] = { 0.0f };

    [self getControlPointAtIndex:1 values:c1];
    [self getControlPointAtIndex:2 values:c2];

    return [self.class functionWithControlPoints:1.0f - c2[0] :1.0f - c2[1] :1.0f - c1[0] :1.0f - c1[1]];
}

// Implementation borrowed from WebKit:
//   http://opensource.apple.com/source/WebCore/WebCore-7537.70/platform/graphics/UnitBezier.h
// Reproduces the results returned by the private _solveForInput: method
- (float)WL_valueForTime:(float)aTime
{
    if (isless(aTime, 0.f))
        aTime = 0.f;
    else if (isgreater(aTime, 1.f))
        aTime = 1.f;

    PolynomialCoefficients coeffs;
    memset(&coeffs, 0, sizeof(PolynomialCoefficients));

    NSValue *value = objc_getAssociatedObject(self, &_WLPolynomialCoefficientsToken);

    if (!value)
    {
        float p1[2] = {0.0};
        [self getControlPointAtIndex:1 values:p1];

        float p2[2] = {0.0};
        [self getControlPointAtIndex:2 values:p2];

        // Cubic Bézier curve parametric equations
        coeffs.cx = 3.f * p1[0];
        coeffs.bx = 3.f * (p2[0] - p1[0]) - coeffs.cx;
        coeffs.ax = 1.f - coeffs.cx - coeffs.bx;

        coeffs.cy = 3.f * p1[1];
        coeffs.by = 3.f * (p2[1] - p1[1]) - coeffs.cy;
        coeffs.ay = 1.f - coeffs.cy - coeffs.by;

        value = [NSValue value:&coeffs withObjCType:@encode(PolynomialCoefficients)];
        objc_setAssociatedObject(self, &_WLPolynomialCoefficientsToken, value, OBJC_ASSOCIATION_RETAIN);
    }
    else
        [value getValue:&coeffs];

    float t = tWithX(aTime, coeffs);
    return yAtT(t, coeffs);
}

@end


@implementation CABasicAnimation (WLInterpolation)

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_singleRepeatDuration
{
    return [NSSet setWithObjects:@"autoreverses", @"duration", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_totalDuration
{
    return [NSSet setWithObjects:@"WL_singleRepeatDuration", @"repeatDuration", @"repeatCount", nil];
}

- (NSTimeInterval)WL_singleRepeatDuration
{
    return self.autoreverses ? 2.0 * self.duration : self.duration;
}

- (NSTimeInterval)WL_totalDuration
{
    __auto_type duration = self.duration;

    if (duration == 0.0)
        return 0.0;

    __auto_type repeatDuration = self.repeatDuration;

    if (repeatDuration != 0.0)
        return repeatDuration;
    else
    {
        __auto_type repeatCount = self.repeatCount;

        if (repeatCount != 0.0)
            return self.WL_singleRepeatDuration * repeatCount;
        else
            return self.WL_singleRepeatDuration;
    }
}

- (float)WL_valueForTime:(float)aTime
{
    if (self.timingFunction)
        return [self.timingFunction WL_valueForTime:aTime];
    else
        return [[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear] WL_valueForTime:aTime];
}

@end


@implementation CASpringAnimation (WLInterpolation)

- (float)WL_valueForTime:(float)aTime
{
    if (isless(aTime, 0.f))
        aTime = 0.f;
    else if (isgreater(aTime, 1.f))
        aTime = 1.f;

    aTime *= (float)self.duration;

    const float b = (float)self.damping;
    const float m = (float)self.mass;
    const float k = (float)self.stiffness;
    const float v0 = (float)self.initialVelocity;

    NSParameterAssert(m > 0);
    NSParameterAssert(k > 0);
    NSParameterAssert(b > 0);

    const float beta = b / (m + m);
    const float omega0 = sqrtf(k / m);
    const float x0 = -1.0f;

    if (beta < omega0)
    {
        // Underdamped
        const float envelope = expf(-beta * aTime);
        const float omega1 = sqrtf((omega0 * omega0) - (beta * beta));
        return -x0 + envelope * (x0 * cosf(omega1 * aTime) + ((beta * x0 + v0) / omega1) * sinf(omega1 * aTime));
    }
    else if (beta == omega0)
    {
        // Critically damped
        const float envelope = expf(-beta * aTime);
        return -x0 + envelope * (x0 + (beta * x0 + v0) * aTime);
    }
    else
    {
        // Overdamped
        const float envelope = expf(-beta * aTime);
        const float omega2 = sqrtf((beta * beta) - (omega0 * omega0));
        return -x0 + envelope * (x0 * coshf(omega2 * aTime) + ((beta * x0 + v0) / omega2) * sinhf(omega2 * aTime));
    }
}

@end


@implementation CALayer (WLInterpolation)

- (NSTimeInterval)WL_remainingTimeForAnimation:(CAAnimation *)anAnimation
{
    NSTimeInterval elapsed = [self convertTime:CACurrentMediaTime() fromLayer:nil] - anAnimation.beginTime;

    if (elapsed <= 0.0)
        return anAnimation.duration;
    else if (elapsed > anAnimation.duration)
        return 0.0;
    else
        return anAnimation.duration - elapsed;
}

- (CGFloat)WL_progressForAnimation:(CAAnimation *)anAnimation
{
    return 1.0 - [self WL_remainingTimeForAnimation:anAnimation] / anAnimation.duration;
}

@end



#pragma mark - WLAnimationTracking

NSString * const WLTransactionsToken = @"WLTransactions";


@implementation WLAnimationTrace

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p; target=%@, animation=%@, key=%@>",
            self.className, self,
            self.target,
            self.animation.debugDescription,
            self.key];
}

@end


@implementation WLTransactionTrace

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p; animations=%@>",
            self.className,
            self,
            [self.animations valueForKey:@"debugDescription"]];
}

@end


@implementation NSAnimationContext (WLAnimationTracking)

static NSString * const _WLAnimationsStackToken = @"WLAnimationsStackToken";

+ (void)WL_enableAnimationTracking
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        method_exchangeImplementations(class_getClassMethod(NSAnimationContext.class, @selector(beginGrouping)),
                                       class_getClassMethod(NSAnimationContext.class, @selector(WL_beginGrouping)));

        method_exchangeImplementations(class_getClassMethod(NSAnimationContext.class, @selector(endGrouping)),
                                       class_getClassMethod(NSAnimationContext.class, @selector(WL_endGrouping)));

        method_exchangeImplementations(class_getInstanceMethod(CALayer.class, @selector(addAnimation:forKey:)),
                                       class_getInstanceMethod(CALayer.class, @selector(WL_addAnimation:forKey:)));

        method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"_NSObjectAnimator"), @selector(setValue:forKey:)),
                                       class_getInstanceMethod(NSProxy.class, @selector(WLAnimationTracking_setValue:forKey:)));

        objc_setAssociatedObject(self, &_WLAnimationsStackToken, [NSMutableArray new], OBJC_ASSOCIATION_RETAIN);
    });
}

+ (NSMutableArray *)WL_animationsStack
{
    return objc_getAssociatedObject(self, &_WLAnimationsStackToken);
}

+ (void)WL_beginGrouping
{
    [self.WL_animationsStack addObject:[NSMutableArray new]];
    [self WL_beginGrouping];
}

+ (void)WL_endGrouping
{
    WLTransactionTrace *trace = [WLTransactionTrace new];
    trace.animations = self.WL_animationsStack.lastObject;
    __auto_type callStack = NSThread.callStackSymbols;
    callStack = [callStack objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, callStack.count - 1)]];
    trace.callStackSymbols = callStack;
    [self.WL_animationsStack removeLastObject];

    __auto_type completionHandler = NSAnimationContext.currentContext.completionHandler;
    if (completionHandler)
    {
        // Completion handler may be associated with more than one transaction.
        NSMutableArray *transactionTraces = objc_getAssociatedObject(completionHandler, &WLTransactionsToken);
        if (transactionTraces)
            [transactionTraces addObject:trace];
    }

    [self WL_endGrouping];
}

+ (void)WL_addAnimationTrace:(WLAnimationTrace *)aTrace
{
    for (NSMutableArray *animations in self.WL_animationsStack)
        [animations addObject:aTrace];
}

@end


@implementation CALayer (WLAnimationTracking)

- (void)WL_addAnimation:(CAAnimation *)anAnimation forKey:(NSString *)aKey
{
    WLAnimationTrace *trace = [WLAnimationTrace new];
    trace.target = self;
    trace.animation = anAnimation;
    trace.key = aKey;
    __auto_type callStack = NSThread.callStackSymbols;
    callStack = [callStack objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, callStack.count - 1)]];
    trace.callStackSymbols = callStack;
    [NSAnimationContext WL_addAnimationTrace:trace];

    [self WL_addAnimation:anAnimation forKey:aKey];
}

@end


@implementation NSProxy (WLAnimationTracking)

- (void)WLAnimationTracking_setValue:(id)aValue forKey:(NSString *)aKey
{
    [self WLAnimationTracking_setValue:aValue forKey:aKey];

    Ivar _targetIvar = class_getInstanceVariable(NSClassFromString(@"_NSObjectAnimator"), "_target");
    id target = object_getIvar(self, _targetIvar);

    __auto_type animations = [target WL_animationManagerAnimations].allValues;
    for (CAAnimation *a in animations)
    {
        WLAnimationTrace *trace = [WLAnimationTrace new];
        trace.target = target;
        trace.animation = a;
        trace.key = aKey;
        __auto_type callStack = NSThread.callStackSymbols;
        callStack = [callStack objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, callStack.count - 1)]];
        trace.callStackSymbols = callStack;
        [NSAnimationContext WL_addAnimationTrace:trace];
    }
}

@end

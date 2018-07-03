//
//  WLLayerHostedView.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "WLLayerHostedView.h"
#import "CALayer+WLBlocks.h"


@implementation WLLayerHostedView

#pragma mark Methods

- (void)stopAnimations
{
    [self.layer WL_applyBlockToTree:^(CALayer *aLayer)
    {
        [aLayer removeAllAnimations];
    }];
}

- (void)pauseAnimations
{
    [self.layer WL_applyBlockToTree:^(CALayer *aLayer)
    {
        CFTimeInterval pausedTime = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil];
        aLayer.speed = 0.0;
        aLayer.timeOffset = pausedTime;
    }];
}

- (void)resumeAnimations
{
    [self.layer WL_applyBlockToTree:^(CALayer *aLayer)
    {
            CFTimeInterval pausedTime = aLayer.timeOffset;
            aLayer.speed = 1.0;
            aLayer.timeOffset = 0.0;
            aLayer.beginTime = 0.0;
            CFTimeInterval timeSincePause = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
            aLayer.beginTime = timeSincePause;
    }];
}

- (void)makeLayers
{
    if (self.layer)
        return;

    CALayer *rootLayer = [self makeRootLayer];
    self.layer = rootLayer;
    self.wantsLayer = YES;
}

- (CALayer *)makeRootLayer
{
    return [CALayer layer];
}

- (void)setNeedsLayout
{
    [self.layer setNeedsLayout];
}

- (void)layoutIfNeeded
{
    [self.layer layoutIfNeeded];
}

- (BOOL)needsLayout
{
    return [self.layer needsLayout];
}


#pragma mark CALayerDelegate

- (id <CAAction>)actionForLayer:(CALayer *)aLayer forKey:(NSString *)aKey
{
    return nil;
}

- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow
{
    return YES;
}


#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [self stopAnimations];

#ifdef DEBUG_LAYERS
    NSLog(@"set frame size: %@", NSStringFromSize(newSize));
#endif

    CGSize oldBoundsSize = self.layer.bounds.size;
    [super setFrameSize:newSize];
    CGSize newBoundsSize = self.layer.bounds.size;

    if (!CGSizeEqualToSize(oldBoundsSize, newBoundsSize))
        [self setNeedsLayout];
}

- (void)setBoundsRotation:(CGFloat)newAngle
{
    NSLog(@"Bounds rotation is always 0.0. New value (%f) is ignored", newAngle);
    return;
}

- (CGFloat)boundsRotation
{
    return 0.0;
}

- (void)displayIfNeeded
{
    [super displayIfNeeded];
    [[self layer] WL_applyBlockToTree:^(CALayer *aLayer)
    {
        [aLayer displayIfNeeded];
    }];
}

- (BOOL)wantsUpdateLayer
{
    return NO;
}

@end

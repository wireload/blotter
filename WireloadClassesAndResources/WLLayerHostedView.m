//
//  WLLayerHostedView.m
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "WLLayerHostedView.h"
#import "CALayer+WLBlocks.h"


static NSString *const _WLIsLayerPausedKey = @"WLLayerBackedView_IsLayerPaused";


@implementation WLLayerHostedView

#pragma mark Methods

- (void)stopAnimations
{
    [[self layer] WL_applyBlockToTree:^(CALayer *aLayer)
    {
        [aLayer removeAllAnimations];
    }];
}

- (void)pauseAnimations
{
    [[self layer] WL_applyBlockToTree:^(CALayer *aLayer)
    {
        [aLayer setValue:[NSNumber numberWithBool:YES] forKey:_WLIsLayerPausedKey];
        CFTimeInterval pausedTime = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil];
        aLayer.speed = 0.0;
        aLayer.timeOffset = pausedTime;
    }];
}

- (void)resumeAnimations
{
    [[self layer] WL_applyBlockToTree:^(CALayer *aLayer)
    {
        if ([[aLayer valueForKey:_WLIsLayerPausedKey] boolValue])
        {
            CFTimeInterval pausedTime = aLayer.timeOffset;
            aLayer.speed = 1.0;
            aLayer.timeOffset = 0.0;
            aLayer.beginTime = 0.0;
            CFTimeInterval timeSincePause = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
            aLayer.beginTime = timeSincePause;
        }
    }];
}

- (void)makeLayers
{
    NSAssert(![self wantsLayer], @"You cannot make layers twice.");

    CALayer *rootLayer = [self makeRootLayer];
    rootLayer.geometryFlipped = [self isFlipped];
    [self setLayer:rootLayer];
    [self setWantsLayer:YES];
}

- (CALayer *)makeRootLayer
{
    return [CALayer layer];
}

- (void)layoutIfNeeded
{
    [[self layer] layoutIfNeeded];
}


#pragma mark NSView

- (void)displayIfNeeded
{
    [super displayIfNeeded];
    [[self layer] WL_applyBlockToTree:^(CALayer *aLayer)
    {
        [aLayer displayIfNeeded];
    }];
}

- (void)setFrameSize:(NSSize)newSize
{
    [self stopAnimations];
#ifdef DEBUG_LAYERS
    NSLog(@"set frame size: %@", NSStringFromSize(newSize));
#endif
    [super setFrameSize:newSize];
    CALayer *rootLayer = [self layer];
    NSParameterAssert(rootLayer != nil);
    [rootLayer setNeedsLayout];
    if ([CATransaction disableActions])
    {
        [self layoutIfNeeded];
        [self displayIfNeeded];
    }
}

@end

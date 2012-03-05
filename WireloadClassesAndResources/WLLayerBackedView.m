//
//  WLLayerBackedView.m
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "WLLayerBackedView.h"
#import "CALayer+WLBlocks.h"


static NSString *const _WLIsLayerPausedKey = @"WLLayerBackedView_IsLayerPaused";


@implementation WLLayerBackedView

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
    [self setLayer:[self makeRootLayer]];
    [self setWantsLayer:YES];
}

- (CALayer *)makeRootLayer
{
    return [CALayer layer];
}


#pragma mark NSView

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
        [rootLayer layoutIfNeeded];
}

@end

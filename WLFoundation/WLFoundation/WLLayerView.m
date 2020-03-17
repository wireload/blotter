//
//  WLLayerHostedView.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 06/03/2012.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "WLAnimation.h"
#import "WLLayerView.h"


static NSString * const _WLLayerSpeedToken = @"WLLayerSpeed";


@implementation NSView (WLLayerView)

- (void)WL_setFrameSize:(NSSize)newSize
{
    if (@available(macOS 10.12, *)) {}
    else
        self.needsLayout = YES;
}

- (void)WL_setBoundsSize:(NSSize)newSize
{
    if (@available(macOS 10.12, *)) {}
    else
        self.needsLayout = YES;
}

@end


@implementation _WLLayerView

#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self WL_setFrameSize:newSize];
}

- (void)setBoundsSize:(NSSize)newSize
{
    [super setBoundsSize:newSize];
    [self WL_setBoundsSize:newSize];
}

- (void)stopAnimations
{
    [self.layer WL_performRecursively:^(CALayer *aLayer) {
        [aLayer removeAllAnimations];
    }];
}

- (void)pauseAnimations
{
    [self.layer WL_performRecursively:^(CALayer *aLayer) {
        objc_setAssociatedObject(aLayer, &_WLLayerSpeedToken, @(aLayer.speed), OBJC_ASSOCIATION_RETAIN);
        CFTimeInterval pausedTime = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil];
        aLayer.speed = 0.0f;
        aLayer.timeOffset = pausedTime;
    }];
}

- (void)resumeAnimations
{
    [self.layer WL_performRecursively:^(CALayer *aLayer) {
        NSNumber *speed = objc_getAssociatedObject(aLayer, &_WLLayerSpeedToken);
        objc_setAssociatedObject(aLayer, &_WLLayerSpeedToken, nil, OBJC_ASSOCIATION_ASSIGN);

        CFTimeInterval pausedTime = aLayer.timeOffset;
        aLayer.speed = speed != nil ? speed.floatValue : 1.0f;
        aLayer.timeOffset = 0.0;
        aLayer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [aLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        aLayer.beginTime = timeSincePause / aLayer.speed;
    }];
}

- (void)performWhileAnimationsPaused:(NS_NOESCAPE void (^)(void))aBlock
{
    [self pauseAnimations];
    aBlock();
    [self resumeAnimations];
}

@end


@implementation WLLayerBackedView

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

#pragma mark Methods

- (void)prepareForBackingLayer
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.wantsLayer = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

@end


@implementation WLLayerHostingView

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
        [self prepareForHostingLayers];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self prepareForHostingLayers];

    return self;
}

#pragma mark Methods

- (void)prepareForHostingLayers
{
    if (self.layer)
        return;

    CALayer *l = [self makeHostedLayer];

    NSWindow *window = self.window;
    if (window && ![l.contents isKindOfClass:NSImage.class])
        l.contentsScale = window.backingScaleFactor;

    l.delegate = self;

    self.layer = l;
    self.wantsLayer = YES;
}

- (CALayer *)makeHostedLayer
{
    return [CALayer layer];
}

#pragma mark CALayerDelegate

- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aScale fromWindow:(NSWindow *)aWindow
{
    // There was a bug in AppKit implementation before 10.14 when this method
    // was called for layers with contents being an instance of NSImage.
    // Returning YES then would cause layer to redraw effectively discarding NSImage.
    if (@available(macOS 10.14, *))
        return YES;
    else
        return ![aLayer.contents isKindOfClass:NSImage.class];
}

- (id <CAAction>)actionForLayer:(CALayer *)aLayer forKey:(NSString *)aKey
{
    return nil;
}

#pragma mark NSView

- (void)addSubview:(NSView *)aView
{
    NSParameterAssert(NO);
    NSLog(@"Cannot add subview to a layer-hosted view");
}

@end


@implementation _WLLayerControl

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self WL_setFrameSize:newSize];
}

- (void)setBoundsSize:(NSSize)newSize
{
    [super setBoundsSize:newSize];
    [self WL_setBoundsSize:newSize];
}

@end


@implementation WLLayerBackedControl

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self prepareForBackingLayer];

    return self;
}

#pragma mark Methods

- (void)prepareForBackingLayer
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.wantsLayer = YES;
}

@end

//
//  WLViewFade.m
//  Blotter
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import "WLViewFade.h"


@implementation WLViewFade

- (id)initWithView:(NSView *)aView
{
    self = [super init];
    if (self != nil)
    {
        view = [aView retain];
    }
    return self;
}

- (void)dealloc
{
    [_fadeOutTimer invalidate];
    [view release];
    [super dealloc];
}


#pragma mark Properties
@synthesize view;

- (void)setView:(NSView *)newFadeView
{
    NSAssert([newFadeView wantsLayer], @"View must be either layer-backed or host its own layer.");

    [newFadeView retain];
    [view release];
    view = newFadeView;
}


#pragma mark Methods

- (void)fadeIn
{
    [_fadeOutTimer invalidate];
    _fadeOutTimer = nil;
    if ([view alphaValue] < 1.0)
        [view setAlphaValue:1.0];
}

- (void)scheduleFadeOutTimer
{
    [_fadeOutTimer invalidate];
    _fadeOutTimer = nil;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"AutoFade"])
        return;
    NSInteger fadeSeconds = [[NSUserDefaults standardUserDefaults] integerForKey:@"AutoFadeSeconds"];
    if (fadeSeconds < 1)
        fadeSeconds = 60;
    _fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:fadeSeconds target:self selector:@selector(_fadeOut) userInfo:nil repeats:NO];
}

- (BOOL)isFadeOutTimerScheduled
{
    return (_fadeOutTimer != nil);
}


#pragma mark Private

- (void)_fadeOut
{
    _fadeOutTimer = nil;
    if ([view alphaValue] > 0.5)
        [[view animator] setAlphaValue:0.5];
}

@end

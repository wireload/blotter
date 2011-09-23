//
//  BLFadeController.m
//  Blotter
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import "BLFadeController.h"


@implementation BLFadeController

- (id)initWithView:(NSView *)aView
{
    if (self = [super init])
    {
        [self setFadeView:aView];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(_applicationDidBecomeActive:)
                                   name:NSApplicationDidBecomeActiveNotification
                                 object:NSApp];
        [notificationCenter addObserver:self
                               selector:@selector(_applicationDidResignActive:)
                                   name:NSApplicationDidResignActiveNotification
                                 object:NSApp];
    }
    return self;
}

- (void)dealloc
{
    [_fadeOutTimer invalidate];
    [fadeView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Properties
@synthesize fadeView;

- (void)setFadeView:(NSView *)newFadeView
{
    NSAssert([newFadeView wantsLayer], @"View must be either layer-backed or host its own layer.");
    [newFadeView retain];
    [fadeView release];
    fadeView = newFadeView;
}


#pragma mark Methods

- (void)fadeIn
{
    [_fadeOutTimer invalidate];
    _fadeOutTimer = nil;
    if ([fadeView alphaValue] < 1.0)
        [fadeView setAlphaValue:1.0];
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


#pragma mark Private

- (void)_fadeOut
{
    _fadeOutTimer = nil;
    if ([fadeView alphaValue] > 0.5)
        [[fadeView animator] setAlphaValue:0.5];
}

- (void)_applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self fadeIn];
}

- (void)_applicationDidResignActive:(NSNotification *)aNotification
{
    [self scheduleFadeOutTimer];
}

@end

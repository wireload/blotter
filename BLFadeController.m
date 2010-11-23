//
//  BLFadeController.m
//  Blotter
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import "BLFadeController.h"


@implementation BLFadeController

@synthesize fadeView;

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *viewDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"NO", @"AutoFade",
                                  @"60", @"AutoFadeSeconds",
                                  nil];

    [defaults registerDefaults:viewDefaults];
}

- (id)initWithView:(NSView *)aView
{
    if (self = [super init])
    {
        [self setFadeView:aView];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:NSApp];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidResignActive:)
                                                     name:NSApplicationDidResignActiveNotification
                                                   object:NSApp];

        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.AutoFade"
                                                                     options:0
                                                                     context:NULL];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.AutoFadeSeconds"
                                                                     options:NSKeyValueObservingOptionInitial
                                                                     context:NULL];
    }

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"values.AutoFade"] || [keyPath isEqualToString:@"values.AutoFadeSeconds"])
    {
        [self createFadeOutTimer];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self fadeIn];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [self createFadeOutTimer];
}

- (void)fadeIn
{
    if ([fadeView alphaValue] < 1.0)
    {
        /*[NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.1];
        [[self animator] setAlphaValue:1.0];
        [NSAnimationContext endGrouping];*/
        [fadeView setAlphaValue:1.0];
    }
}

- (void)fadeOut
{
    if ([fadeView alphaValue] > 0.5)
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[fadeView animator] setAlphaValue:0.5];
        [NSAnimationContext endGrouping];
    }
}

- (void)createFadeOutTimer
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldFade = [defaults boolForKey:@"AutoFade"];

    [fadeOutTimer invalidate];
    [fadeOutTimer release];
    fadeOutTimer = nil;

    if (!shouldFade || [NSApp isActive])
    {
        [self fadeIn];
    }
    else
    {
        int fadeSeconds = [defaults integerForKey:@"AutoFadeSeconds"];
        if (fadeSeconds < 1)
            fadeSeconds = 60;

        NSLog(@"Fade out in %d seconds", fadeSeconds);

        fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:fadeSeconds target:self selector:@selector(fadeOut) userInfo:nil repeats:NO];
        [fadeOutTimer retain];
    }
}

@end

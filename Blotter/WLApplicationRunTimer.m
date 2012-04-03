//
//  WLApplicationRunTimer.m
//  Blotter
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLApplicationRunTimer.h"
#import <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>


NSString* const WLApplicationRunTimerDidFireNotification = @"WLApplicationRunTimerDidFireNotification";


@implementation WLApplicationRunTimer

- (id)init
{
    return [self initWithDelayDefaultsKey:@"" isFiredDefaultsKey:@"" elapsedSecondsDefaultsKey:@""];
}

- (id)initWithDelayDefaultsKey:(NSString *)aDelayKey isFiredDefaultsKey:(NSString *)aIsFiredKey elapsedSecondsDefaultsKey:(NSString *)anElapsedSecondsDefaultsKey
{
    self = [super init];
    if (self != nil)
    {
        _start = mach_absolute_time();
        _delayKey = [aDelayKey copy];
        _isFiredKey = [aIsFiredKey copy];
        _elapsedSecondsKey = [anElapsedSecondsDefaultsKey copy];
        _defaultsAccessQueue = dispatch_queue_create("WLApplicationRunTimer queue", NULL);
    }
    return self;
}

- (void)dealloc
{
    [_delayKey release];
    [_isFiredKey release];
    [_elapsedSecondsKey release];
    dispatch_release(_defaultsAccessQueue);
    [super dealloc];
}


#pragma makr Methods

- (void)reset
{
    if (_elapsedSecondsKey == nil || _isFiredKey == nil)
        return;

    dispatch_async(_defaultsAccessQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setDouble:0.0 forKey:_elapsedSecondsKey];
        [defaults setBool:NO forKey:_isFiredKey];
        _start = mach_absolute_time();
    });
}

- (void)tick
{
    if (_delayKey == nil || _elapsedSecondsKey == nil || _isFiredKey == nil)
        return;

    dispatch_async(_defaultsAccessQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:_isFiredKey])
        {
            uint64_t end = mach_absolute_time();
            uint64_t elapsed = end - _start;
            Nanoseconds elapsedNano = AbsoluteToNanoseconds(*(AbsoluteTime *)&elapsed);
            uint64_t elapsedNanoInt = elapsedNano.hi;
            elapsedNanoInt <<= 32;
            elapsedNanoInt += elapsedNano.lo;
            NSTimeInterval elapsedSeconds = [defaults doubleForKey:_elapsedSecondsKey];
            if (elapsedSeconds < 0.0)
                elapsedSeconds = 0.0;
            elapsedSeconds += (double)elapsedNanoInt * 1e-9;
            NSTimeInterval delay = [defaults doubleForKey:_delayKey];
            BOOL isFired = NO;
            if (elapsedSeconds >= delay)
            {
                elapsedSeconds = delay;
                isFired = YES;
            }
            [defaults setDouble:elapsedSeconds forKey:_elapsedSecondsKey];
            if (isFired)
            {
                [defaults setBool:YES forKey:_isFiredKey];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:WLApplicationRunTimerDidFireNotification object:self];
                });
            }
            else
                _start = mach_absolute_time();
        }
    });
}

@end

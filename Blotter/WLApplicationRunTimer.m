//
//  WLApplicationRunTimer.m
//  Blotter
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>
#import "WLApplicationRunTimer.h"


NSString* const WLApplicationRunTimerDidFireNotification = @"WLApplicationRunTimerDidFireNotification";


@implementation WLApplicationRunTimer
{
    uint64_t _start;
    dispatch_queue_t _defaultsAccessQueue;
}

- (instancetype)initWithDelayDefaultsKey:(NSString *)aDelayKey isFiredDefaultsKey:(NSString *)anIsFiredKey elapsedSecondsDefaultsKey:(NSString *)anElapsedSecondsDefaultsKey
{
    if (![aDelayKey length] || ![anIsFiredKey length] || ![anElapsedSecondsDefaultsKey length])
        return nil;

    self = [super init];

    if (self)
    {
        _start = mach_absolute_time();
        _delayDefaultsKey = [aDelayKey copy];
        _isFiredDefaultsKey = [anIsFiredKey copy];
        _elapsedSecondsDefaultsKey = [anElapsedSecondsDefaultsKey copy];
        _defaultsAccessQueue = dispatch_queue_create("WLApplicationRunTimer queue", NULL);
    }
    return self;
}

- (instancetype)init
{
    return [self initWithDelayDefaultsKey:@"" isFiredDefaultsKey:@"" elapsedSecondsDefaultsKey:@""];
}

- (void)dealloc
{
    dispatch_release(_defaultsAccessQueue);
}


#pragma makr Methods

- (void)reset
{
    dispatch_async(_defaultsAccessQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setDouble:0.0 forKey:self.elapsedSecondsDefaultsKey];
        [defaults setBool:NO forKey:self.isFiredDefaultsKey];
        _start = mach_absolute_time();
    });
}

- (void)tick
{
    dispatch_async(_defaultsAccessQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([defaults boolForKey:self.isFiredDefaultsKey])
            return;

        uint64_t end = mach_absolute_time();
        uint64_t elapsed = end - _start;
        Nanoseconds elapsedNano = AbsoluteToNanoseconds(UInt64ToUnsignedWide(elapsed));
        NSTimeInterval elapsedSeconds = [defaults doubleForKey:self.elapsedSecondsDefaultsKey];

        if (elapsedSeconds < 0.0)
            elapsedSeconds = 0.0;

        elapsedSeconds += (double)(UnsignedWideToUInt64(elapsedNano)) * 1e-9;
        NSTimeInterval delay = [defaults doubleForKey:self.delayDefaultsKey];

        if (delay < 0.0)
            delay = 0.0;

        BOOL isFired = NO;

        if (elapsedSeconds >= delay)
        {
            elapsedSeconds = delay + 1.0;
            isFired = YES;
        }

        [defaults setDouble:elapsedSeconds forKey:self.elapsedSecondsDefaultsKey];

        if (isFired)
        {
            [defaults setBool:YES forKey:self.isFiredDefaultsKey];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:WLApplicationRunTimerDidFireNotification object:self];
            });
        }
        else
            _start = mach_absolute_time();
    });
}

@end

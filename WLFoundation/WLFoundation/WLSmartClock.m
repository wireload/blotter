//
//  WLSmartClock.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 20.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLSmartClock.h"
#import "IKPowerSources.h"
#import "WLASLLog.h"


@implementation WLSmartClock
{
    NSTimer *_nextMinuteTimer;
    NSTimer *_nextDayTimer;

    WLASLLog *_log;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _calendar = [[NSCalendar currentCalendar] copy];
        _date = [NSDate date];
        _log = [[WLASLLog alloc] initWithName:@"WLSmartClock"];

        NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
        [n addObserver:self
              selector:@selector(localeDidChange:)
                  name:NSCurrentLocaleDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(systemClockDidChange:)
                  name:NSSystemClockDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(timeZoneDidChange:)
                  name:NSSystemTimeZoneDidChangeNotification
                object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(dateDidChange)
                                                                   name:NSWorkspaceDidWakeNotification
                                                                 object:nil];

        [self scheduleNextMinuteTimer];
        [self scheduleNextDayTimer];
    }

    return self;
}

- (void)dealloc
{
    [_nextMinuteTimer invalidate];
    [_nextDayTimer invalidate];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calendarDidChange) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dateDidChange) object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}


#pragma mark Properties
@synthesize calendar = _calendar;

- (NSCalendar *)calendar
{
    return [_calendar copy];
}


#pragma mark Methods

+ (instancetype)defaultSmartClock
{
    static WLSmartClock *Clock = nil;
    static dispatch_once_t Once;
    dispatch_once(&Once, ^
    {
        Clock = [[self alloc] init];
    });
    return Clock;
}

- (void)localeDidChange:(NSNotification *)aNotification
{
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0;
    [self performSelector:@selector(calendarDidChange) withObject:nil afterDelay:AnyDelay];
}

- (void)systemClockDidChange:(NSNotification *)aNotification
{
    // http://groups.google.com/group/cocoa-unbound/browse_thread/thread/46fe3433cfef6a97#
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        static const NSTimeInterval AnyDelay = 0.5;
        [self performSelector:@selector(dateDidChange) withObject:nil afterDelay:AnyDelay];
    }
    else
        [self dateDidChange];
}

- (void)timeZoneDidChange:(NSNotification *)aNotification
{
    [self calendarDidChange];
}

- (void)scheduleNextMinuteTimer
{
    [_nextMinuteTimer invalidate];
    NSDate *nextFireDate = nil;
    NSTimeInterval interval = 0.0;
    [_calendar rangeOfUnit:NSMinuteCalendarUnit startDate:&nextFireDate interval:&interval forDate:self.date];

    if (IKGetProvidingPowerSourceType() != IKACPowerType)
    {
        static dispatch_once_t Once;
        static NSDateComponents *BatteryDelayComponents = nil;
        dispatch_once(&Once, ^
        {
            BatteryDelayComponents = [[NSDateComponents alloc] init];
            BatteryDelayComponents.minute = 5;
        });
        nextFireDate = [_calendar dateByAddingComponents:BatteryDelayComponents toDate:nextFireDate options:0];
    }
    else
        nextFireDate = [nextFireDate dateByAddingTimeInterval:interval];

    _nextMinuteTimer = [[NSTimer alloc] initWithFireDate:nextFireDate
                                                interval:0.0
                                                  target:self
                                                selector:@selector(nextMinuteTimerDidFire)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextMinuteTimer forMode:NSDefaultRunLoopMode];
}

- (void)scheduleNextDayTimer
{
    [_nextDayTimer invalidate];
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [_calendar rangeOfUnit:NSDayCalendarUnit startDate:&startDate interval:&interval forDate:self.date];
    _nextDayTimer = [[NSTimer alloc] initWithFireDate:[startDate dateByAddingTimeInterval:interval]
                                             interval:0.0
                                               target:self
                                             selector:@selector(nextDayTimerDidFire)
                                             userInfo:nil
                                              repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
}

- (void)nextMinuteTimerDidFire
{
    _nextMinuteTimer = nil;
    [self dateDidChange];
}

- (void)nextDayTimerDidFire
{
    _nextDayTimer = nil;
    [self dateDidChange];
}

- (void)calendarDidChange
{
    NSCalendar *newCalendar = [[NSCalendar currentCalendar] copy];
#ifdef DEBUG
    [_log logDebug:@"Calendar did change: %@ -> %@", _calendar, newCalendar];
#endif
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calendarDidChange) object:nil];
    [self willChangeValueForKey:@"calendar"];
    _calendar = newCalendar;
    [self didChangeValueForKey:@"calendar"];
    [self scheduleNextDayTimer];
    [self scheduleNextMinuteTimer];
}

- (void)dateDidChange
{
    NSDate *newDate = [NSDate date];
#ifdef DEBUG
    [_log logDebug:@"Date did change: %@ -> %@", _date, newDate];
#endif
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dateDidChange) object:nil];
    [self willChangeValueForKey:@"date"];
    _date = newDate;
    [self didChangeValueForKey:@"date"];
    [self scheduleNextMinuteTimer];
    [self scheduleNextDayTimer];
}

@end

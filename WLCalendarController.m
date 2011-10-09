//
//  WLCalendarData.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarController.h"
#import "IKPowerSources.h"


@implementation WLCalendarController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        calendar = [[NSCalendar autoupdatingCurrentCalendar] retain];
        date = [[NSDate date] retain];
        calCalendars = [[self _calendarsToDisplay] copy];

        NSNotificationCenter *n = [NSNotificationCenter defaultCenter];
        [n addObserver:self
              selector:@selector(_localeDidChange:)
                  name:NSCurrentLocaleDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_clockDidChange:)
                  name:NSSystemClockDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_timeZoneDidChange:)
                  name:NSSystemTimeZoneDidChangeNotification
                object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(_clockDidChange:)
                                                                   name:NSWorkspaceDidWakeNotification
                                                                 object:nil];

        [userDefaults addObserver:self
                       forKeyPath:@"Calendars"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        [userDefaults addObserver:self
                       forKeyPath:@"DisplayAllCalendars"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        [self _updateDate];
        [self _scheduleNextMinuteTimer];
        [self _scheduleNextDayTimer];
    }
    return self;
}

- (void)dealloc
{
    [calendar release];
    [date release];
    [calCalendars release];
    [_nextMinuteTimer invalidate];
    [_nextDayTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:@"Calendars"];
    [userDefaults removeObserver:self forKeyPath:@"DisplayAllCalendars"];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendar;
@synthesize date;
@synthesize calCalendars;


#pragma mark Methods

+ (WLCalendarController *)sharedController
{
    static dispatch_once_t onceToken;
    static WLCalendarController *sharedController;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}


#pragma mark Private

- (void)_localeDidChange:(NSNotification *)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateCalendar) object:nil];
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0f;
    [self performSelector:@selector(_updateCalendar) withObject:nil afterDelay:AnyDelay];
}

- (void)_updateCalendar
{
    self.calendar = [NSCalendar autoupdatingCurrentCalendar];
    [self _updateDate];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (void)_scheduleNextMinuteTimer
{
    [_nextMinuteTimer invalidate];
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [self.calendar rangeOfUnit:NSMinuteCalendarUnit startDate:&startDate interval:&interval forDate:self.date];
    if (IKGetProvidingPowerSourceType() != IKACPowerType)
    {
        NSRange secondsRange = [self.calendar maximumRangeOfUnit:NSSecondCalendarUnit];
        static const NSTimeInterval BatteryModifier = 5;
        interval = BatteryModifier * secondsRange.length;
    }
    _nextMinuteTimer = [[NSTimer alloc] initWithFireDate:[startDate dateByAddingTimeInterval:interval]
                                                interval:0.0
                                                  target:self
                                                selector:@selector(_nextMinute)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextMinuteTimer forMode:NSDefaultRunLoopMode];
    [_nextMinuteTimer release];
}

- (void)_updateDate
{
    self.date = [NSDate date];
}

- (void)_scheduleNextDayTimer
{
    [_nextDayTimer invalidate];
    NSDate *startDate = nil;
    NSTimeInterval interval = 0.0;
    [self.calendar rangeOfUnit:NSDayCalendarUnit startDate:&startDate interval:&interval forDate:self.date];
    _nextDayTimer = [[NSTimer alloc] initWithFireDate:[startDate dateByAddingTimeInterval:interval]
                                             interval:0.0
                                               target:self
                                             selector:@selector(_nextDay)
                                             userInfo:nil
                                              repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
    [_nextDayTimer release];
}

- (void)_nextDay
{
    _nextDayTimer = nil;

    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [self.calendar components:NSWeekCalendarUnit | NSDayCalendarUnit fromDate:now];
    NSDateComponents *representedComponents = [calendar components:NSWeekCalendarUnit | NSDayCalendarUnit fromDate:self.date];
    // Though accuracy of NSTimer is documented as 50-100ms, we must ensure day is actually changed.
    if ([nowComponents day] != [representedComponents day] || [nowComponents week] != [representedComponents week])
    {
        [self _updateDate];
        [self _scheduleNextDayTimer];
    }
    else
        [self performSelector:@selector(_nextDay) withObject:nil afterDelay:0.1];
}

- (void)_nextMinute
{
    _nextMinuteTimer = nil;
    [self _updateDate];
    [self _scheduleNextMinuteTimer];
}

- (void)_clockDidChange:(NSNotification *)aNotification
{
    // http://groups.google.com/group/cocoa-unbound/browse_thread/thread/46fe3433cfef6a97#
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateClock) object:nil];
        [self performSelector:@selector(_updateClock) withObject:nil afterDelay:0.5];
    }
    else
        [self _updateClock];
}

- (void)_updateClock
{
    [self _updateDate];
    [self _scheduleNextMinuteTimer];
    [self _scheduleNextDayTimer];
}

- (void)_timeZoneDidChange:(NSNotification *)aNotification
{
    [self _updateCalendar];
    [self _scheduleNextMinuteTimer];
    [self _scheduleNextDayTimer];
}

- (NSArray *)_calendarsToDisplay
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayAllCalendars"])
        return [[CalCalendarStore defaultCalendarStore] calendars];
    else
    {
        NSArray *selectedCalendarDicts = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Calendars"];
        NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:[selectedCalendarDicts count]];
        for (NSDictionary *d in selectedCalendarDicts)
        {
            if ([[d objectForKey:@"check"] boolValue])
            {
                CalCalendar *c = [[CalCalendarStore defaultCalendarStore] calendarWithUID:[d objectForKey:@"uid"]];
                if (c != nil)
                    [calendars addObject:c];
            }
        }
        return calendars;
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"DisplayAllCalendars"] || [aKeyPath isEqualToString:@"Calendars"])
        self.calCalendars = [self _calendarsToDisplay];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end

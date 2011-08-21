//
//  WLCalendarData.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarController.h"
#import "NSDate+WLDayBoundaries.h"


@implementation WLCalendarController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
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

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults addObserver:self
                       forKeyPath:@"Calendars"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        [userDefaults addObserver:self
                       forKeyPath:@"DisplayAllCalendars"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:@"Calendars"];
    [userDefaults removeObserver:self forKeyPath:@"DisplayAllCalendars"];
    [calendar release];
    [date release];
    [calCalendars release];
    [_minuteTimer invalidate];
    [_nextDayTimer invalidate];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendar;
@synthesize date;
@synthesize calCalendars;


#pragma mark Methods


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
    [self _scheduleNextDayTimer];
    [self _scheduleMinuteTimer];
}

- (void)_scheduleMinuteTimer
{
    [_minuteTimer invalidate];
    NSRange minutesRange = [calendar maximumRangeOfUnit:NSSecondCalendarUnit];
    _minuteTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)minutesRange.length
                                                    target:self
                                                  selector:@selector(_updateDate)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)_scheduleNextDayTimer
{
    [_nextDayTimer invalidate];
    NSDateComponents *oneDayComponents = [[NSDateComponents alloc] init];
    [oneDayComponents setDay:1];
    NSDate *nextDay = [self.calendar dateByAddingComponents:oneDayComponents toDate:self.date options:0];
    [oneDayComponents release];
    nextDay = [nextDay WL_upperBoundaryWithCalendar:calendar];
    _nextDayTimer = [[NSTimer alloc] initWithFireDate:nextDay
                                         interval:0.0
                                           target:self
                                         selector:@selector(_nextDay)
                                         userInfo:nil
                                          repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
    [_nextDayTimer release];
}

- (void)_updateDate
{
    self.date = [NSDate date];
}

- (void)_nextDay
{
    [self _updateDate];
    [self _scheduleNextDayTimer];
}

- (void)_clockDidChange:(NSNotification *)aNotification
{
    // http://groups.google.com/group/cocoa-unbound/browse_thread/thread/46fe3433cfef6a97#
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateDate) object:nil];
        [self performSelector:@selector(_updateDate) withObject:nil afterDelay:0.5];
    }
    else
        [self _updateDate];
}

- (void)_timeZoneDidChange:(NSNotification *)aNotification
{
    [self _updateCalendar];
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

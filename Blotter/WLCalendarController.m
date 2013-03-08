//
//  WLCalendarData.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLCalendarController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLCalendarsController.h"
#import "DeskboardAppDelegate.h"


@interface WLCalendarController (/*Private*/)

@property (nonatomic, retain) NSCalendar *calendar;

@property (nonatomic, retain) NSDate *date;

@property (nonatomic, copy) NSArray *calCalendarsToDisplay;

@property (nonatomic, copy) NSArray *calEventCalendarsToDisplay;

@property (nonatomic, copy) NSArray *calReminderCalendarsToDisplay;

@property(nonatomic, copy) NSArray *calCalendars;

@property(nonatomic, copy) NSArray *calEventCalendars;

@property(nonatomic, copy) NSArray *calReminderCalendars;

@end


@implementation WLCalendarController
{
}

+ (WLCalendarController *)sharedController
{
    static dispatch_once_t onceToken;
    static WLCalendarController *sharedController = nil;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        NSNotificationCenter *n = [NSNotificationCenter defaultCenter];

        [n addObserver:self
              selector:@selector(_calCalendarsDidChange:)
                  name:WLCalCalendarsDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_calCalendarsDidChange:)
                  name:WLCalCalendarsToDisplayDidChangeNotification
                object:nil];

        calendar = [[NSCalendar autoupdatingCurrentCalendar] retain];
        date = [[NSDate date] retain];
        calCalendarsToDisplay = [[self _calCalendarsToDisplay] copy];
        calEventCalendarsToDisplay = [[self calEventCalendarsFromCalCalendars:[self _calCalendarsToDisplayEvents]] copy];
        calReminderCalendarsToDisplay = [[self calReminderCalendarsFromCalCalendars:[self _calCalendarsToDisplayReminders]] copy];
        calCalendars = [[self _calCalendars] copy];
        calEventCalendars = [[self calEventCalendarsFromCalCalendars:calCalendars] copy];
        calReminderCalendars = [[self calReminderCalendarsFromCalCalendars:calCalendars] copy];

        [n addObserver:self
              selector:@selector(_localeDidChange:)
                  name:NSCurrentLocaleDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_systemClockDidChange:)
                  name:NSSystemClockDidChangeNotification
                object:nil];
        [n addObserver:self
              selector:@selector(_timeZoneDidChange:)
                  name:NSSystemTimeZoneDidChangeNotification
                object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(updateDate)
                                                                   name:NSWorkspaceDidWakeNotification
                                                                 object:nil];

        [self _scheduleNextDayTimer];
        [self _scheduleNextMinuteTimer];
    }
    return self;
}

- (void)dealloc
{
    [calendar release];
    [date release];
    [calCalendarsToDisplay release];
    [calEventCalendarsToDisplay release];
    [calReminderCalendarsToDisplay release];
    [calCalendars release];
    [calEventCalendars release];
    [calReminderCalendars release];
    [_nextMinuteTimer invalidate];
    [_nextDayTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCalendar) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDate) object:nil];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendar;
@synthesize date;
@synthesize calCalendarsToDisplay;
@synthesize calEventCalendarsToDisplay;
@synthesize calReminderCalendarsToDisplay;
@synthesize calCalendars;
@synthesize calEventCalendars;
@synthesize calReminderCalendars;


#pragma mark Methods

- (void)updateCalendar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCalendar) object:nil];
    self.calendar = [NSCalendar autoupdatingCurrentCalendar];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (void)updateDate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDate) object:nil];
    self.date = [NSDate date];
    [self _scheduleNextDayTimer];
    [self _scheduleNextMinuteTimer];
}

- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    return [aCalCalendars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CalCalendar *c, NSDictionary *b)
    {
        WLCalEntityMask types = [[WLCalendarStore systemStore] calendarWithIdentifier:c.uid].allowedEntityTypes;
        return types == WLCalEntityMaskUnknown || (types & WLCalEntityMaskEvent) != 0;
    }]];
}

- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars
{
    return [aCalCalendars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CalCalendar *c, NSDictionary *b) {
        WLCalEntityMask types = [[WLCalendarStore systemStore] calendarWithIdentifier:c.uid].allowedEntityTypes;
        return types == WLCalEntityMaskUnknown || (types & WLCalEntityMaskReminder) != 0;
    }]];
}


#pragma mark Private

- (void)_localeDidChange:(NSNotification *)aNotification
{
    // NSCurrentLocaleDidChangeNotification may be posted multiple times for 1 change (meaning user's change in the sys prefs).
    // Don't annoy the user with multiple updates.
    static const NSTimeInterval AnyDelay = 1.0;
    [self performSelector:@selector(updateCalendar) withObject:nil afterDelay:AnyDelay];
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
                                                selector:@selector(_nextMinuteTimerDidFire)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextMinuteTimer forMode:NSDefaultRunLoopMode];
    [_nextMinuteTimer release];
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
                                             selector:@selector(_nextDayTimerDidFire)
                                             userInfo:nil
                                              repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_nextDayTimer forMode:NSDefaultRunLoopMode];
    [_nextDayTimer release];
}

- (void)_nextDayTimerDidFire
{
    _nextDayTimer = nil;
    [self updateDate];
}

- (void)_nextMinuteTimerDidFire
{
    _nextMinuteTimer = nil;
    [self updateDate];
}

- (void)_systemClockDidChange:(NSNotification *)aNotification
{
    // http://groups.google.com/group/cocoa-unbound/browse_thread/thread/46fe3433cfef6a97#
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        static const NSTimeInterval AnyDelay = 0.5;
        [self performSelector:@selector(updateDate) withObject:nil afterDelay:AnyDelay];
    }
    else
        [self updateDate];
}

- (void)_timeZoneDidChange:(NSNotification *)aNotification
{
    [self updateCalendar];
}

- (void)_calCalendarsDidChange:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        self.calCalendarsToDisplay = [self _calCalendarsToDisplay];
        self.calEventCalendarsToDisplay = [self calEventCalendarsFromCalCalendars:[self _calCalendarsToDisplayEvents]];
        self.calReminderCalendarsToDisplay = [self calReminderCalendarsFromCalCalendars:[self _calCalendarsToDisplayReminders]];
        self.calCalendars = [self _calCalendars];
        self.calEventCalendars = [self calEventCalendarsFromCalCalendars:calCalendars];
        self.calReminderCalendars = [self calReminderCalendarsFromCalCalendars:calCalendars];
    });
}

- (NSArray *)_calCalendarsToDisplayEvents
{
    NSMutableArray *csCalendars = [NSMutableArray array];

    for (NSObject<WLCalCalendar> *c in [[[[NSApp delegate] calendarWindowController] calendarsController] calEventCalendarsToDisplayForStore:[WLCalendarStore systemStore]])
    {
        CalCalendar *csCalendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:c.calendarIdentifier];
        [csCalendars addObject:csCalendar];
    }

    return csCalendars;
}

- (NSArray *)_calCalendarsToDisplayReminders
{
    NSMutableArray *csCalendars = [NSMutableArray array];

    for (NSObject<WLCalCalendar> *c in [[[[NSApp delegate] calendarWindowController] calendarsController] calReminderCalendarsToDisplayForStore:[WLCalendarStore systemStore]])
    {
        CalCalendar *csCalendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:c.calendarIdentifier];
        [csCalendars addObject:csCalendar];
    }

    return csCalendars;
}

- (NSArray *)_calCalendarsToDisplay
{
    NSMutableArray *csCalendars = [NSMutableArray array];

    for (NSObject<WLCalCalendar> *c in [[[[NSApp delegate] calendarWindowController] calendarsController] calCalendarsToDisplayForStore:[WLCalendarStore systemStore]])
    {
        CalCalendar *csCalendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:c.calendarIdentifier];
        [csCalendars addObject:csCalendar];
    }

    return csCalendars;
}

- (NSArray *)_calCalendars
{
    NSMutableArray *csCalendars = [NSMutableArray array];

    for (NSObject<WLCalCalendar> *c in [[[[NSApp delegate] calendarWindowController] calendarsController] calCalendarsForStore:[WLCalendarStore systemStore]])
    {
        CalCalendar *csCalendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:c.calendarIdentifier];
        [csCalendars addObject:csCalendar];
    }

    return csCalendars;
}

@end

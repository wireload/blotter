//
//  CalendarAdapter.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import <CalendarStore/CalendarStore.h>

#import "CalendarAdapter.h"
#import "NSDate-Utilities.h"
#import "NSColor-Utilities.h"

static void * volatile sharedInstance = nil;

@implementation CalendarAdapter

@synthesize focusDate;
@synthesize beginningDate;
@synthesize endDate;

+ (CalendarAdapter *)sharedCalendarAdapter
{
    // http://stackoverflow.com/questions/145154/what-does-your-objective-c-singleton-look-like/2449664#2449664
    while (!sharedInstance)
    {
        CalendarAdapter *temp = [[self alloc] init];
        if(!OSAtomicCompareAndSwapPtrBarrier(0x0, temp, &sharedInstance))
            [temp release];
    }
    return sharedInstance;
}

- (NSArray *)calendarsToDisplay {
    static NSArray *_cachedCalendars = nil;

    if (_cachedCalendars == nil || _shouldUpdateCalendars) {
        NSArray *allCalendars = [[CalCalendarStore defaultCalendarStore] calendars];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"DisplayAllCalendars"]) {
            return allCalendars;
        }
        else {
            NSArray *userCalendars = [defaults arrayForKey:@"Calendars"];
            NSIndexSet *indexes = [allCalendars indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                                passingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                    NSUInteger i = [userCalendars indexOfObject:obj
                                                                                                  inSortedRange:NSMakeRange(0, [userCalendars count])
                                                                                                        options:NSBinarySearchingFirstEqual
                                                                                                usingComparator:^(id left, id right) {
                                                                                                    return [[left valueForKey:@"uid"] compare:[right valueForKey:@"uid"]];
                                                                                                }];
                                                                    if (i != NSNotFound) {
                                                                        return [[[userCalendars objectAtIndex:i] objectForKey:@"check"] boolValue];
                                                                    }
                                                                    else {
                                                                        return NO;
                                                                    }
                                                                }];
            [_cachedCalendars release];
            _cachedCalendars = [[allCalendars objectsAtIndexes:indexes] retain];
            _shouldUpdateCalendars = NO;
        }
    }
    return _cachedCalendars;
}

+ (void)initialize {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *viewDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
							   nil, @"ShowDate",
                               @"NO", @"RollingCalendar",
							   nil];

    [defaults registerDefaults:viewDefaults];
}

- (id)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(calendarsChanged:)
                                                     name:CalCalendarsChangedExternallyNotification
                                                   object:[CalCalendarStore defaultCalendarStore]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(eventsChanged:)
                                                     name:CalEventsChangedExternallyNotification
                                                   object:[CalCalendarStore defaultCalendarStore]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tasksChanged:)
                                                     name:CalTasksChangedExternallyNotification
                                                   object:[CalCalendarStore defaultCalendarStore]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dateChanged)
                                                     name:NSSystemClockDidChangeNotification
                                                   object:nil];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.RollingCalendar"
                                                                     options:0
                                                                     context:NULL];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.PerDayDate"
                                                                     options:0
                                                                     context:NULL];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.Calendars"
                                                                     options:NSKeyValueObservingOptionNew
                                                                     context:NULL];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.DisplayAllCalendars"
                                                                     options:NSKeyValueObservingOptionNew
                                                                     context:NULL];

        [self createTomorrowTimer];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // NSLog(@"Updating due to %@ setting change", keyPath);
    _shouldUpdateCalendars = YES;
    [self _postCalendarChanged];
}

- (void)createTomorrowTimer
{
    [tomorrowTimer invalidate];
    [tomorrowTimer release];

    tomorrowTimer = [[[NSTimer alloc] initWithFireDate:[NSDate midnight]
                     interval:60 * 60 * 24
                       target:self
                     selector:@selector(dateChanged)
                     userInfo:nil
                      repeats:NO] retain];
    [[NSRunLoop mainRunLoop] addTimer:tomorrowTimer forMode:NSDefaultRunLoopMode];
}

- (void)dateChanged
{
    // NSLog(@"dateChanged");
    [self _postCalendarChanged];
    [self createTomorrowTimer];
}

- (void)calendarsChanged:(NSNotification *)aNotification
{
    // NSLog(@"calendarsChanged: %@", aNotification);
    // TODO Only react if something visible changes.
    [self _postCalendarChanged];
}

- (void)eventsChanged:(NSNotification *)aNotification
{
    // NSLog(@"eventsChanged: %@", aNotification);
    // TODO Only react if something visible changes.
    [self _postCalendarChanged];
}

- (void)tasksChanged:(NSNotification *)aNotification
{
    // NSLog(@"tasksChanged: %@", aNotification);
    // TODO Only react if something visible changes.
    [self _postCalendarChanged];
}

- (void)_postCalendarChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CalendarAdapterChangedNotification" object:self];
}

- (void)focusDateRangeAround:(NSDate *)aDate
{
    [self setFocusDate:aDate];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    // This makes the week begin on Monday, Sunday or any other day depending on the locale.
    [gregorian setLocale:[NSLocale currentLocale]];

    if ([defaults boolForKey:@"RollingCalendar"])
    {
        // focusDate is now simply the first day.
        [self setBeginningDate:[aDate firstMoment]];
    }
    else
    {
        NSDate *tmpDate;
        [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&tmpDate interval:NULL forDate:aDate];
        [self setBeginningDate:tmpDate];
    }

    NSDateComponents *offsetComponents = [[[NSDateComponents alloc] init] autorelease];
    [offsetComponents setDay:7];
    [self setEndDate:[gregorian dateByAddingComponents:offsetComponents toDate:beginningDate options:0]];
}

- (NSArray *)currentEvents
{
    NSPredicate *eventsForThisWeek = [CalCalendarStore eventPredicateWithStartDate:beginningDate endDate:endDate calendars:[self calendarsToDisplay]];
    NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsForThisWeek];

    NSMutableArray *r = [NSMutableArray array];
    for (int i = 0; i < [events count]; i++)
    {
        NSMutableDictionary *jsonEvent = [NSMutableDictionary new];
        NSMutableDictionary *jsonCalendar = [NSMutableDictionary new];

        CalEvent *event = [events objectAtIndex:i];

        [jsonCalendar setValue:[[event calendar] title]                 forKey:@"title"];
        [jsonCalendar setValue:[[[event calendar] color] hexString]     forKey:@"color"];
        [jsonEvent setValue:jsonCalendar                                forKey:@"calendar"];
        [jsonEvent setValue:[event title]                               forKey:@"title"];
        [jsonEvent setValue:[event location]                            forKey:@"location"];
        [jsonEvent setValue:[[event startDate] description]             forKey:@"startDate"];
        [jsonEvent setValue:[[event endDate] description]               forKey:@"endDate"];
        [jsonEvent setValue:[NSNumber numberWithBool:[event isAllDay]]  forKey:@"isAllDay"];

        [r addObject:jsonEvent];

        [jsonEvent autorelease];
        [jsonCalendar autorelease];
    }

    return r;
}

- (NSArray *)currentTasks
{
    NSPredicate *predicate = [CalCalendarStore taskPredicateWithUncompletedTasks:[self calendarsToDisplay]];
    NSArray *tasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:predicate];

    NSMutableArray *r = [NSMutableArray array];
    for (int i = 0; i < [tasks count]; i++)
    {
        NSMutableDictionary *jsonTask = [NSMutableDictionary new];
        NSMutableDictionary *jsonCalendar = [NSMutableDictionary new];

        CalTask *task = [tasks objectAtIndex:i];

        [jsonCalendar setValue:[[task calendar] title]                  forKey:@"title"];
        [jsonCalendar setValue:[[[task calendar] color] hexString]      forKey:@"color"];
        [jsonTask setValue:jsonCalendar                                 forKey:@"calendar"];
        [jsonTask setValue:[task title]                                 forKey:@"title"];
        CalPriority priority = [task priority];
        if (priority == CalPriorityNone) {
            // Tasks without priority must go after tasks that have
            priority = CalPriorityLow + 1;
        }
        [jsonTask setValue:[NSNumber numberWithInteger:priority]        forKey:@"priority"];

        NSDate *dueDate = [task dueDate];
        if (dueDate == nil) {
            // Tasks without due date must go after tasks that have
            dueDate = [NSDate distantFuture];
        }
        [jsonTask setValue:dueDate                                      forKey:@"dueDate"];
        // [jsonTask setValue:[NSNumber numberWithBool:[task isCompleted]] forKey:@"isCompleted"];

        [r addObject:jsonTask];

        [jsonTask autorelease];
        [jsonCalendar autorelease];
    }

    NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES], nil];
    [r sortUsingDescriptors:sortDescriptors];

    return r;

}

- (NSDictionary *)currentCalendar
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Maybe use a fixed date for testing.
    NSString *focusDateString = [defaults stringForKey:@"ShowDate"];
    if (focusDateString != nil)
    {
        NSDate *aDate = [NSDate dateWithString:focusDateString];
        NSLog(@"Showing date %@", aDate);
        [self focusDateRangeAround:aDate];
    }
    else
    {
        [self focusDateRangeAround:[NSDate date]];
    }

    //[self focusDateRangeAround:[NSDate date]];

    NSMutableDictionary *jsonCalendar = [NSMutableDictionary dictionaryWithCapacity:10];

    NSMutableArray *dayNames = [NSMutableArray array];
    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];

    for (int j = 0; j < 7; j++)
    {
        NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
        [components setDay:j];

        NSDate *dayDate = [gregorian dateByAddingComponents:components toDate:beginningDate options:0];

        // FIXME Might need to make this more locale sensitive.
        NSString *dayFormat = [defaults boolForKey:@"PerDayDate"] ? @"%a, %e %b" : @"%A";
        [dayNames addObject:[dayDate descriptionWithCalendarFormat:dayFormat timeZone:nil
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]];
    }

    NSMutableArray *hourNames = [NSMutableArray array];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    for (int j = 0; j < 24; j++)
    {
        NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
        [components setHour:j];

        NSDate *dayDate = [gregorian dateFromComponents:components];

        [hourNames addObject:[dateFormatter stringFromDate:dayDate]];
    }

    [jsonCalendar setValue:focusDate forKey:@"date"];
    [jsonCalendar setValue:beginningDate forKey:@"beginningDate"];
    [jsonCalendar setValue:endDate forKey:@"endDate"];
    [jsonCalendar setValue:dayNames forKey:@"dayNames"];
    [jsonCalendar setValue:hourNames forKey:@"hourNames"];
    [jsonCalendar setValue:[self currentEvents] forKey:@"events"];
    [jsonCalendar setValue:[self currentTasks] forKey:@"tasks"];

    return jsonCalendar;
}

- (void)dealloc
{
    [self setEndDate:nil];
    [self setBeginningDate:nil];
    [self setFocusDate:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

@end

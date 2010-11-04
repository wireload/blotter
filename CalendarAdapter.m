//
//  CalendarAdapter.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import <YAJL/YAJL.h>
#import <CalendarStore/CalendarStore.h>

#import "CalendarAdapter.h"
#import "NSColor-Utilities.h"

static void * volatile sharedInstance = nil;

@implementation CalendarAdapter

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

- (id)init
{
    if (self = [super init])
    {
        beginningDate = nil;
        endDate = nil;
    }
    return self;
}

- (void)setDateRangeToCurrentWeek
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    // This makes the week begin on Monday, Sunday or any other day depending on the locale.
    [gregorian setLocale:[NSLocale currentLocale]];

    NSDate *today = [[NSDate alloc] init];
    [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginningDate interval:NULL forDate:today];
    [today autorelease];

    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:7];
    endDate = [gregorian dateByAddingComponents:offsetComponents toDate:beginningDate options:0];
    [offsetComponents autorelease];

    [gregorian autorelease];
}

- (NSArray *)jsonEvents
{
    NSPredicate *eventsForThisWeek = [CalCalendarStore eventPredicateWithStartDate:beginningDate endDate:endDate calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
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

- (NSString *)calendarAsJSON
{
    [self setDateRangeToCurrentWeek];

    NSMutableDictionary *jsonCalendar = [NSMutableDictionary dictionaryWithCapacity:10];

    [jsonCalendar setValue:[beginningDate description] forKey:@"beginningDate"];
    [jsonCalendar setValue:[endDate description] forKey:@"endDate"];
    [jsonCalendar setValue:[self jsonEvents] forKey:@"events"];

    NSString *JSONString = [jsonCalendar yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "];

    return JSONString;
}

@end

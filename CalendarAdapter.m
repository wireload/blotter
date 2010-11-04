//
//  CalendarAdapter.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <YAJL/YAJL.h>
#import <CalendarStore/CalendarStore.h>

#import "CalendarAdapter.h"
#import "NSColor-Utilities.h"

@implementation CalendarAdapter

+ (NSString *)calendarAsJSON
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setLocale:[NSLocale currentLocale]];

    NSDate *today = [[NSDate alloc] init];
    NSDate *beginningOfWeek = nil;
    [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek interval:NULL forDate:today];
    [today autorelease];

    NSDate *endOfWeek = nil;
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:7];
    endOfWeek = [gregorian dateByAddingComponents:offsetComponents toDate:beginningOfWeek options:0];
    [offsetComponents autorelease];

    [gregorian autorelease];

    NSPredicate *eventsForThisWeek = [CalCalendarStore eventPredicateWithStartDate:beginningOfWeek endDate:endOfWeek calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
    NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsForThisWeek];

    NSMutableArray *r = [NSMutableArray array];
    for (int i = 0; i < [events count]; i++)
    {
        NSMutableDictionary *jsonEvent = [NSMutableDictionary new];
        NSMutableDictionary *jsonCalendar = [NSMutableDictionary new];

        CalEvent *event = [events objectAtIndex:i];

        [jsonCalendar setValue:[[event calendar] title] forKey:@"title"];
        [jsonCalendar setValue:[[[event calendar] color] hexString] forKey:@"color"];
        [jsonEvent setValue:jsonCalendar forKey:@"calendar"];
        [jsonEvent setValue:[event title] forKey:@"title"];
        [jsonEvent setValue:[event location] forKey:@"location"];
        [jsonEvent setValue:[[event startDate] description] forKey:@"startDate"];
        [jsonEvent setValue:[[event endDate] description] forKey:@"endDate"];
        [jsonEvent setValue:[NSNumber numberWithBool:[event isAllDay]] forKey:@"isAllDay"];

        [r addObject:jsonEvent];

        [jsonEvent autorelease];
        [jsonCalendar autorelease];
    }

    NSString *JSONString = [r yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "];

    return JSONString;
}

@end

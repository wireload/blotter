//
//  NSDate-Utilities.m
//  Blotter
//
//  Created by Alexander Ljungberg on 21/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import "NSDate-Utilities.h"


@implementation NSDate (Utilities)

- (id)JSON {
    return [self description];
}

+ (NSDate *)midnight
{
    // From http://stackoverflow.com/questions/181459/is-there-a-better-way-to-find-midnight-tomorrow
    NSDate *today = [NSDate date];

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = 1;
    NSDate *tomorrow = [gregorian dateByAddingComponents:components toDate:today options:0];
    [components release];
    [gregorian release];

    NSDate *tomorrowMidnight = [tomorrow firstMoment];

    // NSLog(@"tomorrowMidnight: %@", tomorrowMidnight);
    return tomorrowMidnight;
}

- (NSDate *)firstMoment
{
    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];

    NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    components = [gregorian components:unitFlags fromDate:self];
    components.hour = 0;
    components.minute = 0;

    NSDate *firstMoment = [gregorian dateFromComponents:components];
    return firstMoment;
}

@end

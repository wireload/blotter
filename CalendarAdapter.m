//
//  CalendarAdapter.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "CalendarAdapter.h"

#import <YAJL/YAJL.h>

@implementation CalendarAdapter

+ (NSString *)calendarAsJSON
{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
    NSString *JSONString = [dict yajl_JSONString];

    return JSONString;
}

@end

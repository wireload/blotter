//
//  NSDate+ISO8601.m
//  Blotter
//
//  Created by Ilya Kulakov on 13.04.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSDate+ISO8601.h"


@interface NSDate (ISO8601)

+ (NSDate *)dateFromISO8601String:(NSString *)anISO8601string;

- (NSString *)iso8601;

@end

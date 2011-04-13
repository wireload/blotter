//
//  NSDate+ISO8601.h
//  Blotter
//
//  Created by Ilya Kulakov on 13.04.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDate+ISO8601.h"


static NSDateFormatter *_dateFormatter = nil;

@implementation NSDate (ISO8601)

+ (NSDate *)dateFromISO8601String:(NSString *)anISO8601string
{
    if (anISO8601string != nil)
    {
        @synchronized (self)
        {
            if (_dateFormatter == nil)
            {
                _dateFormatter = [[NSDateFormatter alloc] init];
                [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
            }
        }
        return [_dateFormatter dateFromString:anISO8601string];
    }
    else
    {
        return nil;
    }
}

- (NSString *)iso8601
{
    @synchronized ([self class])
    {
        if (_dateFormatter == nil)
        {
            _dateFormatter = [[NSDateFormatter alloc] init];
            [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
        }
    }
    return [_dateFormatter stringFromDate:self];
}

@end

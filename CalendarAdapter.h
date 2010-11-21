//
//  CalendarAdapter.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CalendarAdapter : NSObject {
    NSDate *beginningDate;
    NSDate *endDate;
}

+ (CalendarAdapter *)sharedCalendarAdapter;

- (NSDictionary *)currentCalendar;

@end

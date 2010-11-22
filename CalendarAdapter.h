//
//  CalendarAdapter.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CalendarAdapter : NSObject {
    NSDate* focusDate;
    NSDate* beginningDate;
    NSDate* endDate;
}

@property (retain) NSDate*  focusDate;
@property (retain) NSDate*  beginningDate;
@property (retain) NSDate*  endDate;

+ (CalendarAdapter *)sharedCalendarAdapter;

- (NSDictionary *)currentCalendar;

- (void)calendarsChanged:(NSNotification *)aNotification;
- (void)eventsChanged:(NSNotification *)aNotification;
- (void)tasksChanged:(NSNotification *)aNotification;
- (void)_postCalendarChanged;

@end

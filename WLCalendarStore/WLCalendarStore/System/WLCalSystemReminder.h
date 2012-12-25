//
//  WLCalSystemReminder.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalTask.h>
#import <WLCalendarStore/WLCalSystemCalendarItem.h>
#import <WLCalendarStore/WLCalReminder.h>


@interface WLCalSystemReminder : WLCalSystemCalendarItem <WLCalReminder>

- (WLCalSystemReminder *)initWithCSReminder:(CalTask *)aCSReminder calCalendar:(id <WLCalCalendar>)aCalendar;

@end

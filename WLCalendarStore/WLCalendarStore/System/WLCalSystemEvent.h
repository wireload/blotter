//
//  WLCalSystemEvent.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalEvent.h>
#import <WLCalendarStore/WLCalSystemCalendarItem.h>
#import <WLCalendarStore/WLCalEvent.h>
#import <WLCalendarStore/WLCalTypes.h>


@interface WLCalSystemEvent : WLCalSystemCalendarItem <WLCalEvent>

/*!
    @param  aCurrentCalendar Value of +[NSCalendar currentCalendar] at the time when events was fetched.
 */
- (WLCalSystemEvent *)initWithCSEvent:(CalEvent *)aCSEvent calCalendar:(NSObject <WLCalCalendar> *)aCalCalendar currentCalendar:(NSCalendar *)aCurrentCalendar;

@end

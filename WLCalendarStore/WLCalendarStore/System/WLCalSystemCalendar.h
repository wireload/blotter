//
//  WLCalSystemCalendar.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalSystemObject.h>
#import <WLCalendarStore/WLCalCalendar.h>
#import <CalendarStore/CalCalendar.h>


@interface WLCalSystemCalendar : WLCalSystemObject <WLCalCalendar>

- (instancetype)initWithStore:(id <WLCalStore>)aStore
                   csCalendar:(CalCalendar *)aCSCalendar
           allowedEntityTypes:(WLCalEntityMask)anAllowedEntityTypes;

@end

//
//  WLCalSystemCalendarItem.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalSystemObject.h>
#import <WLCalendarStore/WLCalCalendar.h>
#import <WLCalendarStore/WLCalCalendarItem.h>

@interface WLCalSystemCalendarItem : NSObject <WLCalCalendarItem>
{
    NSObject<WLCalCalendar> *_calendar;
    NSString *_notes;
    NSURL *_URL;
    NSString *_title;
    NSDate *_lastModifiedDate;
    NSString *_location;
    NSString *_itemIdentifier;
}

@end

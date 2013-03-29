//
//  WLCalCalendarItem
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 25.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalObject.h>
#import <WLCalendarStore/WLCalCalendar.h>


@protocol WLCalCalendarItem <NSObject>

@property (readonly) NSObject <WLCalCalendar> *calendar;

@property (copy, readonly) NSString *notes;

@property (copy, readonly) NSURL *URL;

@property (copy, readonly) NSString *title;

@property (copy, readonly) NSDate *lastModifiedDate;

@property (copy, readonly) NSString *location;

@property (copy, readonly) NSString *itemIdentifier;

@property (readonly) BOOL hasRecurrenceRules;

@end

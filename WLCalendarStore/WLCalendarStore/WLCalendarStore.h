//
//  WLCalendarStore.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 27.09.12.
//
//

#import <Foundation/Foundation.h>
#import "WLCalStore.h"
#import <WLCalendarStore/WLCalObject.h>
#import <WLCalendarStore/WLCalCalendar.h>
#import <WLCalendarStore/WLCalCalendarItem.h>
#import <WLCalendarStore/WLCalEvent.h>
#import <WLCalendarStore/WLCalReminder.h>
#import <WLCalendarStore/WLCalTypes.h>


@interface WLCalendarStore : NSObject

+ (id <WLCalStore>)systemStore;

@end


extern NSComparator WLCalCalendarsComparator;

extern NSComparator WLCalEventsComparator;

extern NSComparator WLCalRemindersComparator;


extern NSString *WLCalSystemStoreChecksCalendarsAgainstICalKey;

extern NSString *WLCalSystemStoreAllowsAdvancedCalendarTypeCheckKey;


extern NSString *WLCalStoreDidChangeNotification;

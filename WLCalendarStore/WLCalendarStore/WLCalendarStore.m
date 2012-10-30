//
//  WLCalendarStore.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 27.09.12.
//
//

#import "WLCalendarStore.h"
#import "WLCalSystemStore.h"


NSComparator WLCalCalendarsComparator = ^(NSObject<WLCalCalendar> *aCalendar1, NSObject<WLCalCalendar> *aCalendar2)
{
    return [[aCalendar1 valueForKey:@"calendarIdentifier"] compare:[aCalendar2 valueForKey:@"calendarIdentifier"]];
};

NSComparator WLCalEventsComparator = ^(NSObject<WLCalEvent> *anEvent1, NSObject<WLCalEvent> *anEvent2)
{
    return [[anEvent1 valueForKey:@"itemIdentifier"] compare:[anEvent2 valueForKey:@"itemIdentifier"]];
};

NSComparator WLCalRemindersComparator = ^(NSObject<WLCalReminder> *aReminder1, NSObject<WLCalReminder> *aReminder2)
{
    return [[aReminder1 valueForKey:@"itemIdentifier"] compare:[aReminder2 valueForKey:@"itemIdentifier"]];
};


NSString *WLCalStoreDidChangeNotification = @"WLCalStoreDidChangeNotification";


@implementation WLCalendarStore

+ (id <WLCalStore>)systemStore
{
    return [[WLCalSystemStore alloc] init];
}

@end

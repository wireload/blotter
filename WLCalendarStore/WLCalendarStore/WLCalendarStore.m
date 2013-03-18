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
    NSComparisonResult r = [[anEvent1 valueForKeyPath:@"calendar.calendarIdentifier"] compare:[anEvent2 valueForKeyPath:@"calendar.calendarIdentifier"]];

    if (r == NSOrderedSame)
        [[anEvent1 valueForKey:@"itemIdentifier"] compare:[anEvent2 valueForKey:@"itemIdentifier"]];

    if (r == NSOrderedSame)
        r = [[anEvent1 valueForKey:@"startDate"] compare:[anEvent2 valueForKey:@"startDate"]];

    if (r == NSOrderedSame)
        r = [[anEvent1 valueForKey:@"endDate"] compare:[anEvent2 valueForKey:@"endDate"]];

    return r;
};

NSComparator WLCalRemindersComparator = ^(NSObject<WLCalReminder> *aReminder1, NSObject<WLCalReminder> *aReminder2)
{
    NSComparisonResult r = [[aReminder1 valueForKeyPath:@"calendar.calendarIdentifier"] compare:[aReminder2 valueForKeyPath:@"calendar.calendarIdentifier"]];

    if (r == NSOrderedSame)
        r = [[aReminder1 valueForKey:@"itemIdentifier"] compare:[aReminder2 valueForKey:@"itemIdentifier"]];

    return r;
};


NSString *WLCalStoreDidChangeNotification = @"WLCalStoreDidChangeNotification";


@implementation WLCalendarStore

+ (NSObject <WLCalStore> *)systemStore
{
    static dispatch_once_t OncePredicate;
    static WLCalSystemStore *SystemStore = nil;
    dispatch_once(&OncePredicate, ^
    {
        SystemStore = [[WLCalSystemStore alloc] init];
    });
    return SystemStore;
}

@end

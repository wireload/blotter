//
//  WLCalendarStore.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 27.09.12.
//
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalStore.h>
#import <WLCalendarStore/WLCalObject.h>
#import <WLCalendarStore/WLCalCalendar.h>
#import <WLCalendarStore/WLCalCalendarItem.h>
#import <WLCalendarStore/WLCalEvent.h>
#import <WLCalendarStore/WLCalReminder.h>
#import <WLCalendarStore/WLCalTypes.h>


/*!
    @brief      Determines, whether list of available calendars is checked against the iCal app.

    @discussion Both CalCalendarStore and EventKit has problems some calendars (like delegates). The work around is to get list of calendars
                directly from iCal. UIDs of returned arrays can be further used to access delegate calendars via CalCalendarStore (EventKit refuses to accept them).

                To enable this functionality, you should set YES for this key in NSUserDefaults.
 */
static NSString* const WLCalSystemStoreChecksCalendarsAgainstICalKey = @"WLCalSystemStoreChecksCalendarsAgainstICal";

/*!
    @brief      Determines whether advanced calendar type checking is allowed.

    @discussion On 10.6 it's impossible to test whether a given calendar allows only reminders or only events. The work around is to try to create
                both reminder and event. If item can be created, then calendar allows a given type.

                To enable this functionality, you should set YES for this key in NSUserDefaults.
 */
static NSString* const WLCalSystemStoreAllowsAdvancedCalendarTypeCheckKey = @"WLCalSystemStoreAllowsAdvancedCalendarTypeCheck";


@interface WLCalendarStore : NSObject

+ (NSObject <WLCalStore> *)systemStore;

@end

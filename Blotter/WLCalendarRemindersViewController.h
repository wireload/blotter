//
//  WLCalendarRemindersViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 09.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLCalendarRemindersController.h"
#import "WLCalendarRemindersView.h"


/*!
    @brief      Controller of the WLCalendarRemindersView. Manages displaying and transition (animation) of reminders.

    @discussion Represented object is an instance of WLCalendarRemindersController.

                If represented object is not set, you are responsible for setting reminders.

                If it's set, the controller will observe incomplete reminders as well as changes of time zone and locale.
                It will automatically update reminders. Therefore you MUST not attempt to modify reminders manually.
 */
@interface WLCalendarRemindersViewController : WLViewController <WLCalendarTasksViewDataSource>

/*!
    @brief  Sets reminders represented by receiver's view.

 */
- (void)setReminders:(NSArray *)newReminders sortedUsingComparator:(NSComparator)aComparator animated:(BOOL)isAnimated;

/*!
    @brief      Returns default comparator used for sorting.

    @discussion Sorts reminders by due date, priority, calendar title, title and UID in that order.
                It depends on current time zone and locale settings, because some reminders may represent floating date.

                Returned comparator cannot be called concurrently.
 */
- (NSComparator)makeRemindersComparator;

/*!
    @brief  Called in response to WLCalendarRemindersDidChangeNotification.
 */
- (void)remindersDidChange:(NSNotification *)aNotification;

/*!
    @brief  Called in response to NSSystemTimeZoneDidChangeNotification.
 */
- (void)timeZoneDidChange:(NSNotification *)aNotification;

/*!
    @brief  Called in response to NSCurrentLocaleDidChangeNotification.
 */
- (void)localeDidChange:(NSNotification *)aNotification;

/*!
    @brief  Re-sorts reminders with new comparator.
 */
- (void)remindersComparatorDidChange;

@end

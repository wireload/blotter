//
//  WLCalRemindersPredicate
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 05.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, WLCalReminderCompletionMask)
{
    WLCalReminderCompletionMaskNothing = 0,
    WLCalReminderCompletionMaskComplete = 1 << 0,
    WLCalReminderCompletionMaskIncomplete = 1 << 1,
    WLCalReminderCompletionMaskAny = WLCalReminderCompletionMaskComplete | WLCalReminderCompletionMaskIncomplete
};


/*!
    @brief  Determines filter predicate for reminders from used store.
 */
@interface WLCalRemindersPredicate : NSObject <NSCopying>

/*!
    @brief      Calendars used to get reminders.
    @discussion nil means any calendar.
    Defaults to nil.
 */
@property (readonly) NSArray *calendarIdentifiers;

/*!
    @brief      Completion mask used to get reminders.
    @discussion Defaults to WLCalReminderCompletionMaskIncomplete.
 */
@property (readonly) WLCalReminderCompletionMask completionMask;

- (instancetype)initWithCompletionMask:(WLCalReminderCompletionMask)aCompletionMask calendarIdentifiers:(NSArray *)aCalendarIdentifiers;

+ (instancetype)predicateWithCompletionMask:(WLCalReminderCompletionMask)aCompletionMask calendarIdentifiers:(NSArray *)aCalendarIdentifiers;

@end

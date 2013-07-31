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

@property (readonly) NSSet *calendarIdentifiers;

@property (readonly) WLCalReminderCompletionMask completionMask;

- (instancetype)initWithCompletionMask:(WLCalReminderCompletionMask)aCompletionMask calendarIdentifiers:(NSSet *)aCalendarIdentifiers;

+ (instancetype)predicateWithCompletionMask:(WLCalReminderCompletionMask)aCompletionMask calendarIdentifiers:(NSSet *)aCalendarIdentifiers;

@end

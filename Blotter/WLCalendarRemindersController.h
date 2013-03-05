//
//  WLCalendarRemindersController.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalendarStore.h>


/*
    @brief      The notification which is posted when calendar reminders are changed.

    @discussion User Info dictionary representes reminders per completion mask. The receiver should query this dictionary using the same completion mask
                it used to addObservedCompletionMask.
 */
extern NSString *WLCalendarRemindersDidChangeNotification;


/*!
    @brief  The instance of WLCalendarEventsController listens to updates of calendar stores, fetches reminders for observed completion masks and
            for given calendar identifiers and posts WLCalendarEventsDidChangeNotification.
            Users should not make any expectations about target thread of this notification.

    @see    WLCalendarRemindersDidChangeNotification
 */
@interface WLCalendarRemindersController : NSObject

/*!
    @brief  Instances of objects that adapt WLCalStore protocol which the receiver observes.
 */
@property (copy, readonly) NSArray *calStores;

/*!
    @brief      Initialized the receiver with aStores.

    @discussion Designated initializer.
 */
- (instancetype)initWithCalStores:(NSArray *)aStores;

/*!
    @brief  Returns currently observed completion mask.
 */
- (WLCalReminderCompletionMask)observedCompletionMask;

/*!
    @brief      Adds aCompletionMask to currently observed completion mask or increments its count.

    @discussion Subsequent adds are counted therefore you have to remove the same aCompletionMask as many times as you added it.
 */
- (void)addObservedCompletionMask:(WLCalReminderCompletionMask)aCompletionMask;

/*!
    @brief  Removes aCompletionMask from currently observed completion mask or decrements its count.
 */
- (void)removeObservedCompletionMask:(WLCalReminderCompletionMask)aCompletionMask;

/*!
    @brief  Cleans currently observed observed completion mask.
 */
- (void)removeAllObservedCompletionMasks;

/*!
    @brief  Sets calendar identifiers for a given store.
 */
- (void)setObservedCalendarIdentifiers:(NSSet *)aCalendarIdentifiers forStore:(NSObject<WLCalStore> *)aStore;

/*!
    @brief  Returns calendar identifiers for a given store.
 */
- (NSArray *)observedCalendarIdentifiersForStore:(NSObject<WLCalStore> *)aStore;

/*!
    @brief      Fetches all reminders on background thread with given priority.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchCalRemindersWithPriority:(NSOperationQueuePriority)aPriority;

/*!
    @brief      Fetches reminders for aCompletionMask on background thread with given priority.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchCalRemindersForCompletionMask:(WLCalReminderCompletionMask)aCompletionMask priority:(NSOperationQueuePriority)aPriority;

/*!
    @brief      Called when an observed store posts WLCalStoreDidChangeNotification.

    @discussion You SHOULD not call this method directly.
 */
- (void)calStoreDidChange:(NSNotification *)aNotification;

/*!
    @brief      Called when either calendar identifiers or observed ranges are changed.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchPredicateDidChange;

@end

//
//  WLCalendarEventsController.h
//  Blotter
//
//  Created by Ilya Kulakov on 28.12.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalendarStore.h>


/*
    @brief      The notification which is posted when calendar events are changed.

    @discussion User Info dictionary representes events per date range. The receiver should query this dictionary using the same date range
                it used to addObservedDateRange.
                If value for observed range is nil, the receiver should interpret value as "nothing changed" and therefore ignore the notification.
 */
extern NSString *WLCalendarEventsDidChangeNotification;


/*!
    @brief  The instance of WLCalendarEventsController listens to updates of calendar stores, fetches events within observed date ranges and
            for given calendar identifiers and posts WLCalendarEventsDidChangeNotification.
            Users should not make any expectations about target thread of this notification.

    @see    WLCalendarEventsDidChangeNotification
 */
@interface WLCalendarEventsController : NSObject

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
    @brief  Returns currently observed date ranges.
 */
- (NSSet *)observedDateRanges;

/*!
    @brief      Adds aRange to currently observed date ranges or increments its count.

    @discussion Subsequent adds are counted therefore you have to remove the same aRange as many times as you added it.
 */
- (void)addObservedDateRange:(WLDateRange *)aRange;

/*!
    @brief  Removes aRange from currently observed date ranges or decrements its count.
 */
- (void)removeObservedDateRange:(WLDateRange *)aRange;

/*!
    @brief  Removes all observed date ranges.
 */
- (void)removeAllObservedDateRanges;

/*!
    @brief  Sets calendar identifiers for a given store.
 */
- (void)setObservedCalendarIdentifiers:(NSArray *)aCalendarIdentifiers forStore:(NSObject<WLCalStore> *)aStore;

/*!
    @brief  Returns calendar identifiers for a given store.
 */
- (NSArray *)observedCalendarIdentifiersForStore:(NSObject<WLCalStore> *)aStore;

/*!
    @brief      Optimizes date ranges.

    @discussion The goal of optimization is to reduce number of calls to the store by uniting date ranges.
 */
- (NSArray *)optimizeDateRanges:(NSArray *)aRanges;

/*!
    @brief      Fetches all cal events on background thread with given priority.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchCalEventsWithPriority:(NSOperationQueuePriority)aPriority;

/*!
    @brief      Fetches cal events within given date ranges on background thread with given priority.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchCalEventsForDateRanges:(NSSet *)aRanges priority:(NSOperationQueuePriority)aPriority;

/*!
    @brief  Synchronously fetches and returns events within aRange.

    @param  aRange Date range of events.
 */
- (NSArray *)calEventsForDateRange:(WLDateRange *)aRange;

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

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


extern NSString *WLCalendarEventsDidChangeNotification;


/*!
    @brief  The instance of WLCalendarEventsController listens to updates of calendar stores, fetches events within observed date ranges and
            for given calendar identifiers and posts WLCalendarEventsDidChangeNotification.
 */
@interface WLCalendarEventsController : NSObject

- (instancetype)initWithCalStores:(NSArray *)aStores;

@property (copy, readonly) NSArray *calStores;

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
- (void)setObservedCalendarIdentifiers:(NSSet *)aCalendarIdentifiers forStore:(NSObject<WLCalStore> *)aStore;

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
    @brief  Fetches all cal events on background thread with given priority.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchCalEventsWithPriority:(NSOperationQueuePriority)aPriority;

/*!
    @brief      Fetches cal events within given date ranges on background thread with given priority.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchCalEventsForDateRanges:(NSSet *)aRanges priority:(NSOperationQueuePriority)aPriority;

/*!
    @brief  Called when store posts WLCalStoreDidChangeNotification.

    @discussion You SHOULD not call this method directly.
 */
- (void)calStoreDidChange:(NSNotification *)aNotification;

/*!
    @brief  Called when either calendar identifiers or observed ranges are changed.

    @discussion You SHOULD not call this method directly.
 */
- (void)fetchPredicateDidChange;

@end

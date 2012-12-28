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


typedef NS_ENUM(NSUInteger, WLCalendarEventsCachePolicy)
{
    WLCalendarEventsIgnoresCache,
    WLCalendarEventsGroupsEventsByDay
};


@interface WLCalendarEventsController : NSObject

- (instancetype)initWithCalStores:(NSArray *)aStores;

@property (nonatomic, copy) NSCalendar *calendar;

@property (nonatomic) WLCalendarEventsCachePolicy cachePolicy;

/*!
    @brief  Sets observed range of anObserver to aRange.
 */
- (NSArray *)setObserver:(NSObject *)anObserver forEventsInDateRange:(WLDateRange *)aRange;

/*!
    @brief  Extends observed range of anObserver by aRange.
 */
- (NSArray *)addObserver:(NSObject *)anObserver forEventsInDateRange:(WLDateRange *)aRange;

/*!
    @brief      Reduces observed range of anObserver by aRange. If aRange can contain and overlap current observed range.

    @discussion If aRange contains all observed ranges of anObserver, the call is similar to -removeObserver:
 */
- (void)removeObserver:(NSObject *)anObserver forEventsInDateRange:(WLDateRange *)aRange;

/*!
    @brief  Removes anObserver from all observed ranges.
 */
- (void)removeObserver:(NSObject *)anObserver;

/*!
    @brief  Removes all observers from all observed ranges.
 */
- (void)removeAllObservers;

- (void)invalidateCaches;

@end

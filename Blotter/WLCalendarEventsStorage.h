//
//  WLCalendarEventsStorage.h
//  Blotter
//
//  Created by Ilya Kulakov on 19.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>


NS_ASSUME_NONNULL_BEGIN


/*!
    @brief      WLCalendarEventsStorage represents events split into chunks.
                Each chunk is represented by a date range which in turn represents calendar unit.
                If an event intersects more than one calendar unit, it's split into as many parts as calendar units it intersects.
 
    @discussion Not Thread Safe.
 */
@interface WLCalendarEventsStorage : NSObject

/*!
    @brief  Returns events represented by the storage.
 */
@property (readonly) NSArray *events;

/*
    @brief  Returns calendar used to split events into parts.
 */
@property (readonly) NSCalendar *calendar;

/*!
    @brief  Returns calendar unit used to split events into parts.
 */
@property (readonly) NSCalendarUnit calendarUnit;

- (instancetype)init NS_UNAVAILABLE;

/*!
    @brief      Initializes new storage with events split into aUnits using aCalendar.

    @param      anEvents Events represented by the storage.

    @param      aCalendar Calendar used to perform calendaric calculations.

    @param      aUnit Calendar unit used to perform calendaric calculations.

    @discussion Designated initializer.
 */
- (instancetype)initWithEvents:(NSArray *)anEvents calendar:(NSCalendar *)aCalendar unit:(NSCalendarUnit)aUnit NS_DESIGNATED_INITIALIZER;

/*!
    @brief      Returns all day events that lie within aDateRange.

    @param      aDateRange Date range of all day events.

    @discussion Aligns aDateRange outward using calendar and calendar unit.
 */
- (NSArray *)allDayEventsWithinDateRange:(WLDateRange *)aDateRange;

/*!
    @brief  Returns all day events that lie within aDate's date range.

    @param  aDate Date that defines date range of all day events.
 */
- (NSArray *)allDayEventsForDate:(NSDate *)aDate;

/*!
    @brief  Returns day events that lie within aDateRange.

    @param      aDateRange Date range of all day events.

    @discussion Aligns aDateRange outward using calendar and calendar unit.
 */
- (NSArray *)dayEventsWithinDateRange:(WLDateRange *)aDateRange;

/*!
    @brief  Returns day events that lie within aDate's date range.

    @param  aDate Date that defines date range of day events.
 */
- (NSArray *)dayEventsForDate:(NSDate *)aDate;

@end


NS_ASSUME_NONNULL_END

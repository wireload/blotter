//
//  WLDateRange.h
//  Blotter
//
//  Created by Ilya Kulakov on 25.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
    @brief  Indicates relative position of one date range (or date) to another.
 */
typedef NS_ENUM(NSUInteger, WLPositionRelativeToRange)
{
    WLEarlierThanRange = NSOrderedAscending,
    WLWithinRange = NSOrderedSame,
    WLLaterThanRange = NSOrderedDescending,
    WLOverlapsRange
};


/*!
    @brief  Represents date range.
 */
@interface WLDateRange : NSObject <NSCopying>

/*!
    @brief  Start date of range.
 */
@property (copy, readonly) NSDate *startDate;

/*!
    @brief  End date of range.
 */
@property (copy, readonly) NSDate *endDate;

/*!
    @brief      Initializes date range with given start and end dates.

    @param      aStartDate Start date of range. If nil, -[NSDate date] is used.

    @param      anEndDate End date of range. If nil, -[NSDate date] is used.

    @discussion Designated initializer.
 */
- (instancetype)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate;

/*!
    @brief  Instantiates new date range with given start and end dates.

    @see    -initWithStartDate:endDate:
 */
+ (instancetype)dateRangeWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate;

/*!
    @brief      Instantiates empty date range (which start date is equal to end date).
 */
+ (instancetype)emptyDateRange;

/*!
    @brief      Returns date range which is a union of the receiver and aDateRange.

    @param      aDateRange Another date range. MUST NOT be nil.

    @result     Returns union of the receiver and aDateRange.

    @discussion If there is a gap between the receiver and aDateRange, it'll be a part of the result.
 */
- (WLDateRange *)dateRangeByUnitingWithDateRange:(WLDateRange *)aDateRange;

/*!
    @brief       Determines position of aDate relative to the receiver.

    @param      aDate Date to compare. MUST NOT be nil.

    @result     Returns position of the date relative to the receiver.

    @discussion If aDate is equal to endDate of the receiver, it's considered to lie later.
 */
- (WLPositionRelativeToRange)positionOfDate:(NSDate *)aDate;

/*!
    @brief      Determines whether the receiver and aRange intersects.

    @param      aRange Range to compare. MAY be nil.

    @result     Returns YES if the receiver and aRange intersect.
 */
- (BOOL)intersectsRange:(WLDateRange *)aRange;

/*
    @brief      Determines whether the receiver and aRange intersect and position of aRange relative to the receiver.

    @param      aRange Range to compare. MUST NOT be nil.

    @param      outPosition Will contain position of aRange relative to the receiver. MUST NOT be NULL.

    @result     Returns YES if the receiver and aRange intersect.

    @discussion [] - self, {} - aRange
                YES and:
                    WLEarlierThanRange, then { [ } ]
                    WLOverlapsRange, then { [ ] } or { [ ]}/{ [ }] or {[ ] }/[{ ] } or {[] } or { []}
                    WLWithinRange, then [ { } ] or [ { }]/[ { ]} or [{ } ]/{[ } ] or [{} ] or [{ }]/{[ ]} or [{}]/{[]}
                    WLLaterThanRange, then [ { ] }
                NO and:
                    WLEarlierThanRange, then { } [ ] or {}[]
                    WLLaterThanRange, then [ ] { } or [ ]{ }/[ {] }/[ {}]
 */
- (BOOL)intersectsRange:(WLDateRange *)aRange position:(WLPositionRelativeToRange *)outPosition;

/*!
    @brief  Determines whether range is empty.

    @result YES if startDate is equal to endDate. Otherwise NO.
 */
- (BOOL)isEmpty;

@end


typedef NS_ENUM(NSUInteger, WLDateRangeAlignmentOptions)
{
    WLAlignStartDateInward = 1 << 0,
    WLAlignEndDateInward = 1 << 1,
    WLAlignStartDateOutward = 1 << 2,
    WLAlignEndDateOutward = 1 << 3,
    WLAlignStartDateNearest = 1 << 4,
    WLAlignEndDateNearest = 1 << 5,

    WLAlignInward = WLAlignStartDateInward | WLAlignEndDateInward,
    WLAlignOutward = WLAlignStartDateOutward | WLAlignEndDateOutward,
    WLAlignNearest = WLAlignStartDateNearest | WLAlignEndDateNearest
};


@interface WLDateRange (Alignment)

/*!
    @brief      Aligns aCalendarUnit of the receiver.

    @param      aCalendarUnit Calendar unit of the receiver for alignment.

    @param      aCalendar Instance of NSCalendar used for alignment. May be nil (means current calendar).

    @param      anOptions Alignment options.

    @throws     NSInternalInconsistencyException

    @discussion If the underlying system (NSCalendar) is unable to align aCalendarUnit, 
                NSInternalInconsistencyException is thrown.
 */
- (WLDateRange *)dateRangeByAligningCalendarUnit:(NSCalendarUnit)aCalendarUnit calendar:(NSCalendar *)aCalendar options:(WLDateRangeAlignmentOptions)anOptions;

@end


@interface WLDateRange (Split)

/*!
    @brief      Splits the receiver into an array using aCalendarUnit.

    @param      aCalendarUnit

    @param      aCalendar Instance of NSCalendar used for splitting. May be nil (means current calendar).

    @throws     NSInternalInconsistencyException

    @discussion Result is guaranteed to be sorted by start date.
                If the underlying system (NSCalendar) is unable to split the receiver into aCalendarUnit,
                NSInternalInconsistencyException is thrown.
                If the receiver is reverted (that is, end date is earlier than start date),
                NSInternalInconsistencyException is thrown.
 */
- (NSArray *)splitIntoCalendarUnits:(NSCalendarUnit)aCalendarUnit calendar:(NSCalendar *)aCalendar;

@end

//
//  WLDateRange.h
//  Blotter
//
//  Created by Ilya Kulakov on 25.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSUInteger, WLPositionRelativeToRange)
{
    WLEarlierThanRange = NSOrderedAscending,
    WLWithinRange = NSOrderedSame,
    WLLaterThanRange = NSOrderedDescending,
    WLOverlapsRange
};


@interface WLDateRange : NSObject <NSCopying, NSMutableCopying>
{
    NSDate *startDate;
    NSDate *endDate;
}

@property (copy, readonly) NSDate *startDate;

@property (copy, readonly) NSDate *endDate;

+ (instancetype)dateRangeWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate;

+ (instancetype)emptyDateRange;

- (instancetype)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate;

- (WLDateRange *)dateRangeByUnitingWithDateRange:(WLDateRange *)aDateRange;

- (WLPositionRelativeToRange)positionOfDate:(NSDate *)aDate;

- (BOOL)intersectsRange:(WLDateRange *)aRange;

/*
 [] - self, {} - aRange
 YES and:
    WLEarlierThanRange, then { [ } ]
    WLOverlapsRange, then { [ ] }
    WLWithinRange, then [ { } ]
    WLLaterThanRange, then [ { ] }
 NO and:
    WLEarlierThanRange, then {} []
    WLLaterThanRange, then [] {}
 */
- (BOOL)intersectsRange:(WLDateRange *)aRange position:(WLPositionRelativeToRange *)outPosition;

- (BOOL)isEmpty;

@end

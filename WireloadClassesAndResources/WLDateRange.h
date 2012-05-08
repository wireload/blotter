//
//  WLDateRange.h
//  Blotter
//
//  Created by Ilya Kulakov on 25.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum
{
    WLEarlierThanRange = NSOrderedAscending,
    WLWithinRange = NSOrderedSame,
    WLLaterThanRange = NSOrderedDescending,
    WLOverlapsRange
} WLPositionRelativeToRange;


@interface WLDateRange : NSObject {
    NSDate *startDate;
    NSDate *endDate;
}

@property (retain) NSDate *startDate;

@property (retain) NSDate *endDate;

+ (id)dateRangeWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate;

- (id)initWithStartDate:(NSDate *)aStartDate endDate:(NSDate *)anEndDate;

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

@end

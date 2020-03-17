//
//  WLDateRangeTests.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 28.12.12.
//  Copyright (c) 2012 Wireload. All rights reserved.
//

#import "WLDateRange.h"


@implementation WLDateRangeTests

- (void)testInitWithStartDateEndDate
{
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [startDate dateByAddingTimeInterval:10];
    WLDateRange *range = [[WLDateRange alloc] initWithStartDate:startDate endDate:endDate];

    XCTAssertEqualObjects(startDate, range.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(endDate, range.endDate, @"End dates don't match");
}

- (void)testInitWithEndDateStartDate
{
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [endDate dateByAddingTimeInterval:10];
    WLDateRange *range = [[WLDateRange alloc] initWithStartDate:startDate endDate:endDate];

    XCTAssertEqualObjects(endDate, range.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(startDate, range.endDate, @"End dates don't match");
}

- (void)testEmptyDateRange
{
    WLDateRange *dateRange = [WLDateRange emptyDateRange];
    XCTAssertTrue([dateRange isEmpty], @"Date range is not empty");
}

- (void)testDateRangeByUnitingWithDateRangeNil
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    XCTAssertThrows([r1 dateRangeByUnitingWithDateRange:nil], @"Exception is not thrown");
}

- (void)testDateRangeByUnitingWithDateRangeEarlier
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:10];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    WLDateRange *u = [r1 dateRangeByUnitingWithDateRange:r2];

    XCTAssertEqualObjects(startDate1, u.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(endDate2, u.endDate, @"End dates don't match");
}

- (void)testDateRangeByUnitingWithDateRangeEarlierIntersects
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    WLDateRange *u = [r1 dateRangeByUnitingWithDateRange:r2];

    XCTAssertEqualObjects(startDate1, u.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(endDate2, u.endDate, @"End dates don't match");
}

- (void)testDateRangeByUnitingWithDateRangeWithin
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    WLDateRange *u = [r1 dateRangeByUnitingWithDateRange:r2];

    XCTAssertEqualObjects(startDate2, u.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(endDate2, u.endDate, @"End dates don't match");
}

- (void)testDateRangeByUnitingWithDateRangeLaterIntersects
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-10];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:-5];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    WLDateRange *u = [r1 dateRangeByUnitingWithDateRange:r2];

    XCTAssertEqualObjects(startDate2, u.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(endDate1, u.endDate, @"End dates don't match");
}

- (void)testDateRangeByUnitingWithDateRangeLater
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    WLDateRange *u = [r1 dateRangeByUnitingWithDateRange:r2];

    XCTAssertEqualObjects(startDate2, u.startDate, @"Start dates don't match");
    XCTAssertEqualObjects(endDate1, u.endDate, @"End dates don't match");
}

- (void)testPositionOfDateNil
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    XCTAssertThrows([r1 positionOfDate:nil], @"Exception is not thrown");
}

- (void)testPositionOfDateEarlier
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = [r1.startDate dateByAddingTimeInterval:-10];
    XCTAssertEqual(WLEarlierThanRange, [r1 positionOfDate:date], @"Date is not earlier");
}

- (void)testPositionOfDateWithin
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = [r1.startDate dateByAddingTimeInterval:5];
    XCTAssertEqual(WLWithinRange, [r1 positionOfDate:date], @"Date is not within");
}

- (void)testPositionOfDateLater
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = [r1.endDate dateByAddingTimeInterval:5];
    XCTAssertEqual(WLLaterThanRange, [r1 positionOfDate:date], @"Date is not later");
}

- (void)testPositionOfStartDate
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = r1.startDate;
    XCTAssertEqual(WLWithinRange, [r1 positionOfDate:date], @"Date is not within");
}

- (void)testPositionOfEndDate
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = r1.endDate;
    XCTAssertEqual(WLLaterThanRange, [r1 positionOfDate:date], @"Date is not later");
}

- (void)testIntersectsRange1Earlier2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:10];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    XCTAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Earlier2Touch
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = endDate1;
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    XCTAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Earlier2Intersect
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    XCTAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    XCTAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2CommonStartDate
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = startDate1;
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    XCTAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2CommonStartDateEmpty
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = startDate1;
    NSDate *startDate2 = startDate1;
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    XCTAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2CommonEndDate
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = endDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    XCTAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within1
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    XCTAssertTrue([r1 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within1Empty
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    XCTAssertTrue([r1 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Later2Intersect
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-10];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:-5];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    XCTAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Later2Touch
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = startDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    XCTAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Later2TouchEmpty
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = startDate1;
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = startDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    XCTAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Later2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    XCTAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRangePositionNULL
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:10];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    XCTAssertThrows([r1 intersectsRange:r2 position:NULL], @"Exception is not thrown");
}

- (void)testIntersectsRangePosition1Earlier2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:10];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"1 is not earlier than 2");

    XCTAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"2 is not later than 1");
}

- (void)testIntersectsRangePosition1Earlier2Touch
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = endDate1;
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"1 is not earlier than 2");

    XCTAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"2 is not later than 1");
}

- (void)testIntersectsRangePosition1Earlier2Intersect
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"1 is not earlier than 2");

    XCTAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"2 is not earlier than 1");
}

- (void)testIntersectsRangePosition1Within2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLWithinRange, p, @"1 is not within 2");

    XCTAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLOverlapsRange, p, @"2 does not overlap 1");
}

- (void)testIntersectsRangePosition1Within2CommonStartDate
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = startDate1;
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLWithinRange, p, @"1 is not within 2");

    XCTAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLOverlapsRange, p, @"2 does not overlap 1");
}

- (void)testIntersectsRangePosition1Within2CommonStartDateEmpty
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = startDate1;
    NSDate *startDate2 = startDate1;
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLWithinRange, p, @"1 is not within 2");

    XCTAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLOverlapsRange, p, @"2 does not overlap 1");
}

- (void)testIntersectsRangePosition1Within2CommonEndDate
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = endDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLWithinRange, p, @"1 is not within 2");

    XCTAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLOverlapsRange, p, @"2 does not overlap 1");
}

- (void)testIntersectsRangePosition1Within1
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLPositionRelativeToRange p;
    XCTAssertTrue([r1 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLWithinRange, p, @"Position is not within");
}

- (void)testIntersectsRangePosition1Within1Empty
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    WLPositionRelativeToRange p;
    XCTAssertTrue([r1 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLWithinRange, p, @"Position is not within");
}

- (void)testIntersectsRangePosition1Later2Intersect
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-10];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:-5];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"1 is not later than 2");

    XCTAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"2 is not earlier than 1");
}

- (void)testIntersectsRangePosition1Later2Touch
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = startDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"1 is not later than 2");

    XCTAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"2 is not earlier than 1");
}

- (void)testIntersectsRangePosition1Later2TouchEmpty
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = startDate1;
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = startDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"1 is not later than 2");

    XCTAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"2 is not earlier than 1");
}


- (void)testIntersectsRangePosition1Later2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];

    WLPositionRelativeToRange p;
    XCTAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLEarlierThanRange, p, @"1 is not later than 2");

    XCTAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    XCTAssertEqual(WLLaterThanRange, p, @"2 is not earlier than 1");
}

- (void)testIsEmpty
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    XCTAssertTrue([r1 isEmpty], @"Range is not empty");

    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    XCTAssertFalse([r2 isEmpty], @"Range is empty");
}

- (void)testDateRangeByAligningCalendarUnitCalendarOptions
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0]; // to simplify debugging in Xcode, where summary shows dates in +0000 tz.
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];

    NSDateComponents *startDayComponents = [NSDateComponents new];
    [startDayComponents setDay:1];
    [startDayComponents setHour:10];
    NSDate *startDayAMMoment = [calendar dateByAddingComponents:startDayComponents toDate:date options:0]; // 02 10:00:00
    [startDayComponents setDay:1];
    [startDayComponents setHour:14];
    NSDate *startDayPMMoment = [calendar dateByAddingComponents:startDayComponents toDate:date options:0]; // 02 14:00:00
    NSDate *startDayFirstMoment = nil; // 02 00:00:00
    NSTimeInterval startDayInterval;
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&startDayFirstMoment interval:&startDayInterval forDate:startDayPMMoment];
    NSDate *startDayLastMoment = [startDayFirstMoment dateByAddingTimeInterval:startDayInterval]; // 03 00:00:00

    NSDateComponents *endDayComponents = [NSDateComponents new];
    [endDayComponents setDay:2];
    [endDayComponents setHour:10];
    NSDate *endDayAMMoment = [calendar dateByAddingComponents:endDayComponents toDate:date options:0]; // 03 10:00:00
    [startDayComponents setDay:2];
    [startDayComponents setHour:14];
    NSDate *endDayPMMoment = [calendar dateByAddingComponents:startDayComponents toDate:date options:0]; // 03 14:00:00
    NSDate *endDayFirstMoment = nil; // 03 00:00:00
    NSTimeInterval endDayInterval; //
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&endDayFirstMoment interval:&endDayInterval forDate:endDayAMMoment];
    NSDate *endDayLastMoment = [endDayFirstMoment dateByAddingTimeInterval:endDayInterval]; // 04 00:00:00

#define WLAssertAlignment(aRange, anOptions, anExpectedRange) \
    { \
        WLDateRange *r = [aRange dateRangeByAligningCalendarUnit:NSCalendarUnitDay calendar:calendar options:anOptions]; \
        XCTAssertEqualObjects(r, anExpectedRange); \
    }

    // Test alignment within a calendar unit.
    WLDateRange *startDayRange = [WLDateRange dateRangeWithStartDate:startDayFirstMoment endDate:startDayLastMoment]; // {02 00:00:00, 03 00:00:00}
    WLDateRange *startDayFirstMomentRange = [WLDateRange dateRangeWithStartDate:startDayFirstMoment endDate:startDayFirstMoment]; // {02 00:00:00, 02 00:00:00}
    WLDateRange *startDayLastMomentRange = [WLDateRange dateRangeWithStartDate:startDayLastMoment endDate:startDayLastMoment]; // {03 00:00:00, 03 00:00:00}

    WLAssertAlignment(startDayRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayRange);

    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayFirstMomentRange);
    WLAssertAlignment(startDayFirstMomentRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayFirstMomentRange);

    WLDateRange *startDayAMRange = [WLDateRange dateRangeWithStartDate:startDayFirstMoment endDate:startDayAMMoment]; // {02 00:00:00, 02 10:00:00}
    WLAssertAlignment(startDayAMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayFirstMomentRange);

    WLDateRange *startDayAMMomentRange = [WLDateRange dateRangeWithStartDate:startDayAMMoment endDate:startDayAMMoment]; // {02 10:00:00, 02 10:00:00}
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMMomentRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayFirstMomentRange);

    WLDateRange *startDayAMPMRange = [WLDateRange dateRangeWithStartDate:startDayAMMoment endDate:startDayPMMoment]; // {02 10:00:00, 02 14:00:00}
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayAMPMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayRange);

    WLDateRange *startDayPMMomentRange = [WLDateRange dateRangeWithStartDate:startDayPMMoment endDate:startDayPMMoment]; // {02 14:00:00, 02 14:00:00}
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayFirstMomentRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayPMMomentRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayLastMomentRange);

    WLDateRange *startDayPMRange = [WLDateRange dateRangeWithStartDate:startDayPMMoment endDate:startDayLastMoment]; // {02 14:00:00, 03 00:00:00}
    WLAssertAlignment(startDayPMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayPMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayLastMomentRange);

    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateInward | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateOutward | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateNearest | WLAlignEndDateOutward, startDayLastMomentRange);
    WLAssertAlignment(startDayLastMomentRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayLastMomentRange);

    // Test alignment across calendar units.
    WLDateRange *endDayRange = [WLDateRange dateRangeWithStartDate:endDayFirstMoment endDate:endDayLastMoment]; // {03 00:00:00, 03 00:00:00}
    WLDateRange *range = [WLDateRange dateRangeWithStartDate:startDayFirstMoment endDate:endDayLastMoment]; // {02 00:00:00, 04 00:00:00}

    WLAssertAlignment(range, WLAlignStartDateInward | WLAlignEndDateInward, range);
    WLAssertAlignment(range, WLAlignStartDateInward | WLAlignEndDateOutward, range);
    WLAssertAlignment(range, WLAlignStartDateInward | WLAlignEndDateNearest, range);
    WLAssertAlignment(range, WLAlignStartDateOutward | WLAlignEndDateInward, range);
    WLAssertAlignment(range, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(range, WLAlignStartDateOutward | WLAlignEndDateNearest, range);
    WLAssertAlignment(range, WLAlignStartDateNearest | WLAlignEndDateInward, range);
    WLAssertAlignment(range, WLAlignStartDateNearest | WLAlignEndDateOutward, range);
    WLAssertAlignment(range, WLAlignStartDateNearest | WLAlignEndDateNearest, range);

    WLDateRange *spentAMRange = [WLDateRange dateRangeWithStartDate:startDayFirstMoment endDate:endDayAMMoment]; // {02 00:00:00, 03 10:00:00}
    WLAssertAlignment(spentAMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(spentAMRange, WLAlignStartDateInward | WLAlignEndDateOutward, range);
    WLAssertAlignment(spentAMRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(spentAMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(spentAMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(spentAMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(spentAMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(spentAMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, range);
    WLAssertAlignment(spentAMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayRange);

    WLDateRange *spentPMRange = [WLDateRange dateRangeWithStartDate:startDayFirstMoment endDate:endDayPMMoment]; // {02 00:00:00, 03 14:00:00}
    WLAssertAlignment(spentPMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(spentPMRange, WLAlignStartDateInward | WLAlignEndDateOutward, range);
    WLAssertAlignment(spentPMRange, WLAlignStartDateInward | WLAlignEndDateNearest, range);
    WLAssertAlignment(spentPMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(spentPMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(spentPMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, range);
    WLAssertAlignment(spentPMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(spentPMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, range);
    WLAssertAlignment(spentPMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, range);

    WLDateRange *remainingAMRange = [WLDateRange dateRangeWithStartDate:startDayAMMoment endDate:endDayLastMoment]; // {02 10:00:00, 04 00:00:00}
    WLAssertAlignment(remainingAMRange, WLAlignStartDateInward | WLAlignEndDateInward, endDayRange);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateInward | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateInward | WLAlignEndDateNearest, endDayRange);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateOutward | WLAlignEndDateInward, range);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, range);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateNearest | WLAlignEndDateInward, range);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, range);
    WLAssertAlignment(remainingAMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, range);

    WLDateRange *remainingPMRange = [WLDateRange dateRangeWithStartDate:startDayPMMoment endDate:endDayLastMoment]; // {02 14:00:00, 04 00:00:00}
    WLAssertAlignment(remainingPMRange, WLAlignStartDateInward | WLAlignEndDateInward, endDayRange);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateInward | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateInward | WLAlignEndDateNearest, endDayRange);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateOutward | WLAlignEndDateInward, range);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, range);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateNearest | WLAlignEndDateInward, endDayRange);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(remainingPMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, endDayRange);

    WLDateRange *amAMRange = [WLDateRange dateRangeWithStartDate:startDayAMMoment endDate:endDayAMMoment]; // {02 10:00:00, 03 10:00:00}
    WLAssertAlignment(amAMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(amAMRange, WLAlignStartDateInward | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(amAMRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(amAMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(amAMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(amAMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(amAMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(amAMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, range);
    WLAssertAlignment(amAMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayRange);

    WLDateRange *amPMRange = [WLDateRange dateRangeWithStartDate:startDayAMMoment endDate:endDayPMMoment]; // {02 10:00:00, 03 14:00:00}
    WLAssertAlignment(amPMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(amPMRange, WLAlignStartDateInward | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(amPMRange, WLAlignStartDateInward | WLAlignEndDateNearest, endDayRange);
    WLAssertAlignment(amPMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(amPMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(amPMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, range);
    WLAssertAlignment(amPMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(amPMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, range);
    WLAssertAlignment(amPMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, range);

    WLDateRange *pmAMRange = [WLDateRange dateRangeWithStartDate:startDayPMMoment endDate:endDayAMMoment]; // {02 14:00:00, 03 10:00:00}
    WLAssertAlignment(pmAMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateInward | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateInward | WLAlignEndDateNearest, startDayLastMomentRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(pmAMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, startDayRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(pmAMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, startDayLastMomentRange);

    WLDateRange *pmPMRange = [WLDateRange dateRangeWithStartDate:startDayPMMoment endDate:endDayPMMoment]; // {02 14:00:00, 03 14:00:00}
    WLAssertAlignment(pmPMRange, WLAlignStartDateInward | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(pmPMRange, WLAlignStartDateInward | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(pmPMRange, WLAlignStartDateInward | WLAlignEndDateNearest, endDayRange);
    WLAssertAlignment(pmPMRange, WLAlignStartDateOutward | WLAlignEndDateInward, startDayRange);
    WLAssertAlignment(pmPMRange, WLAlignStartDateOutward | WLAlignEndDateOutward, range);
    WLAssertAlignment(pmPMRange, WLAlignStartDateOutward | WLAlignEndDateNearest, range);
    WLAssertAlignment(pmPMRange, WLAlignStartDateNearest | WLAlignEndDateInward, startDayLastMomentRange);
    WLAssertAlignment(pmPMRange, WLAlignStartDateNearest | WLAlignEndDateOutward, endDayRange);
    WLAssertAlignment(pmPMRange, WLAlignStartDateNearest | WLAlignEndDateNearest, endDayRange);

#undef WLAssertAlignment
}

- (void)testSplitIntoCalendarUnitsCalendar
{
    NSDateComponents *startDateComponents = [NSDateComponents new];
    [startDateComponents setDay:1];
    [startDateComponents setHour:14];

    NSDateComponents *endDateComponents = [NSDateComponents new];
    [endDateComponents setDay:3];
    [endDateComponents setHour:11 ];

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *startDate = [calendar dateByAddingComponents:startDateComponents toDate:date options:0];
    NSDate *endDate = [calendar dateByAddingComponents:endDateComponents toDate:date options:0];

    NSDate *startDateStart = nil;
    NSTimeInterval startDateInterval;
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&startDateStart interval:&startDateInterval forDate:startDate];
    NSDate *startDateEnd = [startDateStart dateByAddingTimeInterval:startDateInterval];

    NSDate *endDateStart = nil;
    NSTimeInterval endDateInterval;
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&endDateStart interval:&endDateInterval forDate:endDate];

    WLDateRange *r = [WLDateRange dateRangeWithStartDate:startDate endDate:endDate];
    NSArray *a = [r splitIntoCalendarUnits:NSCalendarUnitDay calendar:calendar];
    NSArray *e = @[
        [WLDateRange dateRangeWithStartDate:startDate endDate:startDateEnd],
        [WLDateRange dateRangeWithStartDate:startDateEnd endDate:endDateStart],
        [WLDateRange dateRangeWithStartDate:endDateStart endDate:endDate]
    ];
    XCTAssertEqualObjects(e, a, @"Parts are not equal");
}

@end

//
//  WLDateRangeTests.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 28.12.12.
//  Copyright (c) 2012 Wireload. All rights reserved.
//

#import "WLDateRangeTests.h"


@implementation WLDateRangeTests

- (void)testInitWithStartDateEndDate
{
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [startDate dateByAddingTimeInterval:10];
    WLDateRange *range = [[WLDateRange alloc] initWithStartDate:startDate endDate:endDate];

    STAssertEqualObjects(startDate, range.startDate, @"Start dates don't match");
    STAssertEqualObjects(endDate, range.endDate, @"End dates don't match");
}

- (void)testInitWithEndDateStartDate
{
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [endDate dateByAddingTimeInterval:10];
    WLDateRange *range = [[WLDateRange alloc] initWithStartDate:startDate endDate:endDate];

    STAssertEqualObjects(endDate, range.startDate, @"Start dates don't match");
    STAssertEqualObjects(startDate, range.endDate, @"End dates don't match");
}

- (void)testEmptyDateRange
{
    WLDateRange *dateRange = [WLDateRange emptyDateRange];
    STAssertTrue([dateRange isEmpty], @"Date range is not empty");
}

- (void)testDateRangeByUnitingWithDateRangeNil
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    STAssertThrows([r1 dateRangeByUnitingWithDateRange:nil], @"Exception is not thrown");
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

    STAssertEqualObjects(startDate1, u.startDate, @"Start dates don't match");
    STAssertEqualObjects(endDate2, u.endDate, @"End dates don't match");
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

    STAssertEqualObjects(startDate1, u.startDate, @"Start dates don't match");
    STAssertEqualObjects(endDate2, u.endDate, @"End dates don't match");
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

    STAssertEqualObjects(startDate2, u.startDate, @"Start dates don't match");
    STAssertEqualObjects(endDate2, u.endDate, @"End dates don't match");
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

    STAssertEqualObjects(startDate2, u.startDate, @"Start dates don't match");
    STAssertEqualObjects(endDate1, u.endDate, @"End dates don't match");
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

    STAssertEqualObjects(startDate2, u.startDate, @"Start dates don't match");
    STAssertEqualObjects(endDate1, u.endDate, @"End dates don't match");
}

- (void)testPositionOfDateNil
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    STAssertThrows([r1 positionOfDate:nil], @"Exception is not thrown");
}

- (void)testPositionOfDateEarlier
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = [r1.startDate dateByAddingTimeInterval:-10];
    STAssertEquals(WLEarlierThanRange, [r1 positionOfDate:date], @"Date is not earlier");
}

- (void)testPositionOfDateWithin
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = [r1.startDate dateByAddingTimeInterval:5];
    STAssertEquals(WLWithinRange, [r1 positionOfDate:date], @"Date is not within");
}

- (void)testPositionOfDateLater
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = [r1.endDate dateByAddingTimeInterval:5];
    STAssertEquals(WLLaterThanRange, [r1 positionOfDate:date], @"Date is not later");
}

- (void)testPositionOfStartDate
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = r1.startDate;
    STAssertEquals(WLWithinRange, [r1 positionOfDate:date], @"Date is not within");
}

- (void)testPositionOfEndDate
{
    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[[NSDate date] dateByAddingTimeInterval:10]];
    NSDate *date = r1.endDate;
    STAssertEquals(WLLaterThanRange, [r1 positionOfDate:date], @"Date is not later");
}

- (void)testIntersectsRange1Earlier2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:10];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    STAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Earlier2Touch
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = endDate1;
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    STAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Earlier2Intersect
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    STAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    STAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2CommonStartDate
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = startDate1;
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    STAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2CommonStartDateEmpty
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = startDate1;
    NSDate *startDate2 = startDate1;
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    STAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within2CommonEndDate
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-5];
    NSDate *endDate2 = endDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    STAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within1
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    STAssertTrue([r1 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Within1Empty
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    STAssertTrue([r1 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Later2Intersect
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-10];
    NSDate *endDate2 = [endDate1 dateByAddingTimeInterval:-5];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertTrue([r1 intersectsRange:r2], @"Ranges do not intersect");
    STAssertTrue([r2 intersectsRange:r1], @"Ranges do not intersect");
}

- (void)testIntersectsRange1Later2Touch
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = startDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    STAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Later2TouchEmpty
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = startDate1;
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = startDate1;

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    STAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRange1Later2
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [startDate1 dateByAddingTimeInterval:-15];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertFalse([r1 intersectsRange:r2], @"Ranges intersect");
    STAssertFalse([r2 intersectsRange:r1], @"Ranges intersect");
}

- (void)testIntersectsRangePositionNULL
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];
    NSDate *startDate2 = [endDate1 dateByAddingTimeInterval:10];
    NSDate *endDate2 = [startDate2 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDate2 endDate:endDate2];
    STAssertThrows([r1 intersectsRange:r2 position:NULL], @"Exception is not thrown");
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
    STAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    STAssertEquals(WLLaterThanRange, p, @"1 is not earlier than 2");

    STAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    STAssertEquals(WLEarlierThanRange, p, @"2 is not later than 1");
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
    STAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    STAssertEquals(WLLaterThanRange, p, @"1 is not earlier than 2");

    STAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    STAssertEquals(WLEarlierThanRange, p, @"2 is not later than 1");
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
    STAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLLaterThanRange, p, @"1 is not earlier than 2");

    STAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLEarlierThanRange, p, @"2 is not earlier than 1");
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
    STAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLWithinRange, p, @"1 is not within 2");

    STAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLOverlapsRange, p, @"2 does not overlap 1");
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
    STAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLWithinRange, p, @"1 is not within 2");

    STAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLOverlapsRange, p, @"2 does not overlap 1");
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
    STAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLWithinRange, p, @"1 is not within 2");

    STAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLOverlapsRange, p, @"2 does not overlap 1");
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
    STAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLWithinRange, p, @"1 is not within 2");

    STAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLOverlapsRange, p, @"2 does not overlap 1");
}

- (void)testIntersectsRangePosition1Within1
{
    NSDate *startDate1 = [NSDate date];
    NSDate *endDate1 = [startDate1 dateByAddingTimeInterval:10];

    WLDateRange *r1 = [WLDateRange dateRangeWithStartDate:startDate1 endDate:endDate1];
    WLPositionRelativeToRange p;
    STAssertTrue([r1 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLWithinRange, p, @"Position is not within");
}

- (void)testIntersectsRangePosition1Within1Empty
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    WLPositionRelativeToRange p;
    STAssertTrue([r1 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLWithinRange, p, @"Position is not within");
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
    STAssertTrue([r1 intersectsRange:r2 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLEarlierThanRange, p, @"1 is not later than 2");

    STAssertTrue([r2 intersectsRange:r1 position:&p], @"Ranges do not intersect");
    STAssertEquals(WLLaterThanRange, p, @"2 is not earlier than 1");
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
    STAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    STAssertEquals(WLEarlierThanRange, p, @"1 is not later than 2");

    STAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    STAssertEquals(WLLaterThanRange, p, @"2 is not earlier than 1");
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
    STAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    STAssertEquals(WLEarlierThanRange, p, @"1 is not later than 2");

    STAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    STAssertEquals(WLLaterThanRange, p, @"2 is not earlier than 1");
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
    STAssertFalse([r1 intersectsRange:r2 position:&p], @"Ranges intersect");
    STAssertEquals(WLEarlierThanRange, p, @"1 is not later than 2");

    STAssertFalse([r2 intersectsRange:r1 position:&p], @"Ranges intersect");
    STAssertEquals(WLLaterThanRange, p, @"2 is not earlier than 1");
}

- (void)testIsEmpty
{
    WLDateRange *r1 = [WLDateRange emptyDateRange];
    STAssertTrue([r1 isEmpty], @"Range is not empty");

    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:[NSDate date] endDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    STAssertFalse([r2 isEmpty], @"Range is empty");
}

- (void)testDateRangeByAligningCalendarUnitCalendarOptions
{
    NSDateComponents *startDateComponents = [NSDateComponents new];
    [startDateComponents setDay:1];
    [startDateComponents setHour:14];

    NSDateComponents *endDateComponents = [NSDateComponents new];
    [endDateComponents setDay:3];
    [endDateComponents setHour:11 ];

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *startDate = [calendar dateByAddingComponents:startDateComponents toDate:date options:0];
    NSDate *endDate = [calendar dateByAddingComponents:endDateComponents toDate:date options:0];

    NSDate *startDateStart = nil;
    NSTimeInterval startDateInterval;
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&startDateStart interval:&startDateInterval forDate:startDate];
    NSDate *startDateEnd = [startDateStart dateByAddingTimeInterval:startDateInterval];
    NSDate *startDateNearest = fabs([startDateStart timeIntervalSinceDate:startDate]) <= fabs([startDateEnd timeIntervalSinceDate:startDate]) ? startDateStart : startDateEnd;

    NSDate *endDateStart = nil;
    NSTimeInterval endDateInterval;
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&endDateStart interval:&endDateInterval forDate:endDate];
    NSDate *endDateEnd = [endDateStart dateByAddingTimeInterval:endDateInterval];
    NSDate *endDateNearest = fabs([endDateEnd timeIntervalSinceDate:endDate]) <= fabs([endDateStart timeIntervalSinceDate:endDate]) ? endDateEnd : endDateStart;

    WLDateRange *r = [WLDateRange dateRangeWithStartDate:startDate endDate:endDate];

    WLDateRange *a1 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateInward | WLAlignEndDateInward];
    WLDateRange *e1 = [WLDateRange dateRangeWithStartDate:startDateEnd endDate:endDateStart];
    STAssertEqualObjects(e1, a1, @"Date ranges are not equal");

    WLDateRange *a2 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateInward | WLAlignEndDateOutward];
    WLDateRange *e2 = [WLDateRange dateRangeWithStartDate:startDateEnd endDate:endDateEnd];
    STAssertEqualObjects(e2, a2, @"Date ranges are not equal");

    WLDateRange *a3 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateInward | WLAlignEndDateNearest];
    WLDateRange *e3 = [WLDateRange dateRangeWithStartDate:startDateEnd endDate:endDateNearest];
    STAssertEqualObjects(e3, a3, @"Date ranges are not equal");

    WLDateRange *a4 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateOutward | WLAlignEndDateInward];
    WLDateRange *e4 = [WLDateRange dateRangeWithStartDate:startDateStart endDate:endDateStart];
    STAssertEqualObjects(e4, a4, @"Date ranges are not equal");

    WLDateRange *a5 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateOutward | WLAlignEndDateOutward];
    WLDateRange *e5 = [WLDateRange dateRangeWithStartDate:startDateStart endDate:endDateEnd];
    STAssertEqualObjects(e5, a5, @"Date ranges are not equal");

    WLDateRange *a6 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateOutward | WLAlignEndDateNearest];
    WLDateRange *e6 = [WLDateRange dateRangeWithStartDate:startDateStart endDate:endDateNearest];
    STAssertEqualObjects(e6, a6, @"Date ranges are not equal");

    WLDateRange *a7 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateNearest | WLAlignEndDateInward];
    WLDateRange *e7 = [WLDateRange dateRangeWithStartDate:startDateNearest endDate:endDateStart];
    STAssertEqualObjects(e7, a7, @"Date ranges are not equal");

    WLDateRange *a8 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateNearest | WLAlignEndDateOutward];
    WLDateRange *e8 = [WLDateRange dateRangeWithStartDate:startDateNearest endDate:endDateEnd];
    STAssertEqualObjects(e8, a8, @"Date ranges are not equal");

    WLDateRange *a9 = [r dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateNearest | WLAlignEndDateNearest];
    WLDateRange *e9 = [WLDateRange dateRangeWithStartDate:startDateNearest endDate:endDateNearest];
    STAssertEqualObjects(e9, a9, @"Date ranges are not equal");

    // Test already aligned date range.
    WLDateRange *r2 = [WLDateRange dateRangeWithStartDate:startDateStart endDate:startDateEnd];

    WLDateRange *a10 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateInward | WLAlignEndDateInward];
    STAssertEqualObjects(r2, a10, @"Date ranges are not equal");

    WLDateRange *a11 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateInward | WLAlignEndDateOutward];
    STAssertEqualObjects(r2, a11, @"Date ranges are not equal");

    WLDateRange *a12 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateInward | WLAlignEndDateNearest];
    STAssertEqualObjects(r2, a12, @"Date ranges are not equal");

    WLDateRange *a13 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateOutward | WLAlignEndDateInward];
    STAssertEqualObjects(r2, a13, @"Date ranges are not equal");

    WLDateRange *a14 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateOutward | WLAlignEndDateOutward];
    STAssertEqualObjects(r2, a14, @"Date ranges are not equal");

    WLDateRange *a15 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateOutward | WLAlignEndDateNearest];
    STAssertEqualObjects(r2, a15, @"Date ranges are not equal");

    WLDateRange *a16 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateNearest | WLAlignEndDateInward];
    STAssertEqualObjects(r2, a16, @"Date ranges are not equal");

    WLDateRange *a17 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateNearest | WLAlignEndDateOutward];
    STAssertEqualObjects(r2, a17, @"Date ranges are not equal");

    WLDateRange *a18 = [r2 dateRangeByAligningCalendarUnit:NSDayCalendarUnit calendar:calendar options:WLAlignStartDateNearest | WLAlignEndDateNearest];
    STAssertEqualObjects(r2, a18, @"Date ranges are not equal");
}

- (void)testSplitIntoCalendarUnitsCalendar
{
    NSDateComponents *startDateComponents = [NSDateComponents new];
    [startDateComponents setDay:1];
    [startDateComponents setHour:14];

    NSDateComponents *endDateComponents = [NSDateComponents new];
    [endDateComponents setDay:3];
    [endDateComponents setHour:11 ];

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *startDate = [calendar dateByAddingComponents:startDateComponents toDate:date options:0];
    NSDate *endDate = [calendar dateByAddingComponents:endDateComponents toDate:date options:0];

    NSDate *startDateStart = nil;
    NSTimeInterval startDateInterval;
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&startDateStart interval:&startDateInterval forDate:startDate];
    NSDate *startDateEnd = [startDateStart dateByAddingTimeInterval:startDateInterval];

    NSDate *endDateStart = nil;
    NSTimeInterval endDateInterval;
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&endDateStart interval:&endDateInterval forDate:endDate];

    WLDateRange *r = [WLDateRange dateRangeWithStartDate:startDate endDate:endDate];
    NSArray *a = [r splitIntoCalendarUnits:NSDayCalendarUnit calendar:calendar];
    NSArray *e = @[
        [WLDateRange dateRangeWithStartDate:startDate endDate:startDateEnd],
        [WLDateRange dateRangeWithStartDate:startDateEnd endDate:endDateStart],
        [WLDateRange dateRangeWithStartDate:endDateStart endDate:endDate]
    ];
    STAssertEqualObjects(e, a, @"Parts are not equal");
}

@end

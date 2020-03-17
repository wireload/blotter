//
//  NSArray+WLDelta.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 07.10.12.
//  Copyright (c) 2012 Wireload. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>


static const NSComparator comparator = ^(id left, id right) { return [left compare:right]; };


@implementation NSArray_WLDelta_Tests

- (void)testIndexesOfInsertedObjects_throwsException
{
    NSArray *a = @[@1, @2];
    XCTAssertThrows([a WL_indexesOfInsertedObjects:NULL relativeToArray:nil sortedUsingComparator:nil], @"No exception for nil array and nil comparator");
    XCTAssertThrows([a WL_indexesOfInsertedObjects:NULL relativeToArray:nil sortedUsingComparator:comparator], @"No exception for nil array");
    XCTAssertThrows([a WL_indexesOfInsertedObjects:NULL relativeToArray:@[@1] sortedUsingComparator:nil], @"No exception for nil comparator");
}

- (void)testIndexesOfInsertedObjects_above_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@1, @2];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;
    NSIndexSet *rightArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSIndexSet *leftArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_above_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@1, @2, @3];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;
    NSIndexSet *rightArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSIndexSet *leftArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_above_inclusive_overflow
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@1, @2, @3, @4];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @1
    [rightArrayExpectedIndexes addIndex:1]; // @2
    [rightArrayExpectedIndexes addIndex:3]; // @4

    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @1
    [leftArrayExpectedIndexes addIndex:1]; // @2
    [leftArrayExpectedIndexes addIndex:3]; // @4

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_below_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@10, @11];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;
    NSIndexSet *rightArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSIndexSet *leftArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 2)];
    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_below_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@9, @10, @11];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;
    NSIndexSet *rightArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
    NSIndexSet *leftArrayExpectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 2)];
    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_below_inclusive_overflow
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@8, @9, @10, @11];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @8
    [rightArrayExpectedIndexes addIndex:2]; // @10
    [rightArrayExpectedIndexes addIndex:3]; // @11

    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:2]; // @8
    [leftArrayExpectedIndexes addIndex:4]; // @10
    [leftArrayExpectedIndexes addIndex:5]; // @11

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_inside_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@4, @7];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @7
    [rightArrayExpectedIndexes addIndex:1]; // @2

    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:1]; // @4
    [leftArrayExpectedIndexes addIndex:3]; // @7

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_inside_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@4, @6, @7];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @4
    [rightArrayExpectedIndexes addIndex:2]; // @7

    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:1]; // @4
    [leftArrayExpectedIndexes addIndex:3]; // @7

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_exclusive_inside_exclusive_below_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @4, @7, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:1]; // @4
    [rightArrayExpectedIndexes addIndex:2]; // @7
    [rightArrayExpectedIndexes addIndex:3]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_exclusive_inside_exclusive_below_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @4, @7, @9, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:1]; // @4
    [rightArrayExpectedIndexes addIndex:2]; // @7
    [rightArrayExpectedIndexes addIndex:4]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_exclusive_inside_inclusive_below_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @4, @6, @7, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:1]; // @4
    [rightArrayExpectedIndexes addIndex:3]; // @7
    [rightArrayExpectedIndexes addIndex:4]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_exclusive_inside_inclusive_below_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @4, @6, @7, @9, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:1]; // @4
    [rightArrayExpectedIndexes addIndex:3]; // @7
    [rightArrayExpectedIndexes addIndex:5]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_inclusive_inside_exclusive_below_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @3, @4, @7, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:2]; // @4
    [rightArrayExpectedIndexes addIndex:3]; // @7
    [rightArrayExpectedIndexes addIndex:4]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_inclusive_inside_exclusive_below_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @3, @4, @7, @9, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:2]; // @4
    [rightArrayExpectedIndexes addIndex:3]; // @7
    [rightArrayExpectedIndexes addIndex:5]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_inclusive_inside_inclusive_below_exclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @3, @4, @6, @7, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:2]; // @4
    [rightArrayExpectedIndexes addIndex:4]; // @7
    [rightArrayExpectedIndexes addIndex:5]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

- (void)testIndexesOfInsertedObjects_mixed_above_inclusive_inside_inclusive_below_inclusive
{
    NSArray *leftArray = @[@3, @6, @9];
    NSIndexSet *leftArrayIndexes = nil;

    NSArray *rightArray = @[@2, @3, @4, @6, @7, @9, @10];
    __autoreleasing NSIndexSet *rightArrayIndexes = NULL;

    NSMutableIndexSet *rightArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [rightArrayExpectedIndexes addIndex:0]; // @2
    [rightArrayExpectedIndexes addIndex:2]; // @4
    [rightArrayExpectedIndexes addIndex:4]; // @7
    [rightArrayExpectedIndexes addIndex:6]; // @10


    NSMutableIndexSet *leftArrayExpectedIndexes = [NSMutableIndexSet indexSet];
    [leftArrayExpectedIndexes addIndex:0]; // @2
    [leftArrayExpectedIndexes addIndex:2]; // @4
    [leftArrayExpectedIndexes addIndex:4]; // @7
    [leftArrayExpectedIndexes addIndex:6]; // @10

    leftArrayIndexes = [leftArray WL_indexesOfInsertedObjects:&rightArrayIndexes relativeToArray:rightArray sortedUsingComparator:comparator];
    XCTAssertEqualObjects(leftArrayIndexes, leftArrayExpectedIndexes, @"Wrong Result indexes");
    XCTAssertEqualObjects(rightArrayIndexes, rightArrayExpectedIndexes, @"Wrong Output indexes");
}

@end

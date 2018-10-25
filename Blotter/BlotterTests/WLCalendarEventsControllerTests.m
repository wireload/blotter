//
//  WLCalendarEventsControllerTests.m
//  Blotter
//
//  Created by Ilya Kulakov on 21.03.13.
//  Copyright (c) 2013 WireLoad. All rights reserved.
//

#import "WLCalendarEventsControllerTests.h"
#import "WLCalendarEventsController.h"
#import <WLCalendarStore/WLCalendarStore.h>


@implementation WLCalendarEventsControllerTests

- (void)testAddEmptyObservedRange
{
    WLCalendarEventsController *c = [[WLCalendarEventsController alloc] initWithCalStores:@[[WLCalendarStore systemStore]]];
    [c addObservedDateRange:[WLDateRange emptyDateRange]];
    XCTAssertTrue([[c observedDateRanges] count] == 0, @"Observed date ranges are not empty");
}

- (void)testAddNilObservedRange
{
    WLCalendarEventsController *c = [[WLCalendarEventsController alloc] initWithCalStores:@[[WLCalendarStore systemStore]]];
    [c addObservedDateRange:nil];
    XCTAssertTrue([[c observedDateRanges] count] == 0, @"Observed date ranges are not empty");
}

@end

//
//  NSDate+WLDayBoundaries.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (WLDayBoundaries)

- (NSDate *)upperBoundaryWithCalendar:(NSCalendar *)calendar;

- (NSDate *)lowerBoundaryWithCalendar:(NSCalendar *)calendar;

@end

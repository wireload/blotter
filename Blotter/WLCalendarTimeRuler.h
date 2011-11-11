//
//  WLCalendarTimeRuler.h
//  Blotter
//
//  Created by Ilya Kulakov on 17.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol WLCalendarTimeRuler

/*!
 @abstract Returns number of hours represented by a time ruler.
 */
- (NSUInteger)numberOfHours;

/*!
 @abstract      Converts a given date into hour. 
 @discussion    You can use result to calculate offset for the time of given date.
 Integral part represents hours, fractional part represents minutes: 13:45 -> 13.75
 @result        Min value SHOULD be 0.0, max value SHOULD be [self numberOfHours] * [self heightOfHour].
 */
- (CGFloat)hourForDate:(NSDate *)aDate;

@end

//
//  WLCalendarTimeRuler.h
//  Blotter
//
//  Created by Ilya Kulakov on 17.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLHourRange.h"


@protocol WLCalendarTimeRuler

- (CGFloat)originOffset;

/*!
 @abstract  Determines inclusive hour range represented by time ruler.
 */
- (WLHourRange)hourRange;

/*!
 @abstract  Returns location of aHour on time ruler.
 */
- (CGFloat)locationForHour:(CGFloat)aHour;

/*!
 @abstract  Returns length of aHourRange on time ruler.
 */
- (CGFloat)lengthForHourRange:(WLHourRange)aHourRange;

/*!
 @abstract  Returns localized marker for integer part of aHour.
 */
- (NSString *)markerForHour:(NSUInteger)aHour;

/*!
 @abstract      Converts a given date into hour.
 @discussion    You can use result to calculate offset for the time of given date.
 Integral part represents hours, fractional part represents minutes: 13:45 -> 13.75 (assuming 60 minutes/hour).
 @result        Min and Max values MUST lie within hourRange.
 */
- (CGFloat)hourForDate:(NSDate *)aDate;

@end

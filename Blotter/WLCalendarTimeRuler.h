//
//  WLCalendarTimeRuler.h
//  Blotter
//
//  Created by Ilya Kulakov on 17.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLHourRange.h"


/*!
 */
@protocol WLCalendarTimeRuler

- (WLHourRange)hourRange;

- (CGFloat)originOffset;

- (CGFloat)positionForHour:(CGFloat)aHour;

- (CGFloat)heightForHourRange:(WLHourRange)aHourRange;

/*!
 @abstract      Converts a given date into hour.
 @discussion    You can use result to calculate offset for the time of given date.
 Integral part represents hours, fractional part represents minutes: 13:45 -> 13.75
 @result        Min value MUST be 0.0, max value MUST be [self numberOfHours].
 */
- (CGFloat)hourForDate:(NSDate *)aDate;

- (NSString *)markerForHour:(CGFloat)aHour;

@end

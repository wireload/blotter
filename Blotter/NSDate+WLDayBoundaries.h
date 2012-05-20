//
//  NSDate+WLDayBoundaries.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 @abstract  Provides methods to manipulate NSDate in terms of day boundaries.
 */
@interface NSDate (WLDayBoundaries)

/*!
 @abstract  Returns first appearance of the date in day boundaries according to aCalendar.
 */
- (NSDate *)WL_startOfDay:(NSCalendar *)aCalendar;

/*!
 @abstract  Returns last appearance of the date in day boundaries according to aCalendar.
 */
- (NSDate *)WL_endOfDay:(NSCalendar *)aCalendar;

/*!
 @abstract  Returns floor(date + 1 aCalendar's hour).
 */
- (NSDate *)WL_nextHourDate:(NSCalendar *)aCalendar;

/*!
 @abstract  Returns noon of the date according to aCalendar.
 */
- (NSDate *)WL_noon:(NSCalendar *)aCalendar;

@end

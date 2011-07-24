//
//  WLCalendarTimeRuler.h
//  Blotter
//
//  Created by Ilya Kulakov on 17.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol WLCalendarTimeRuler

@property (assign, readonly) NSUInteger numberOfHours;

@property (assign, readonly) CGFloat heightOfHour;

- (CGFloat)hourForDate:(NSDate *)aDate;

@end

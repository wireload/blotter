//
//  WLCalendarDateView.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "BLCalendarFramer.h"


@interface WLCalendarDateView : NSView /*<CALayoutManager>*/{
    CATextLayer *_monthDayLayer;
    CATextLayer *_monthAndYearLayer;
    CATextLayer *_weekdayLayer;
}

@property (nonatomic, copy) NSString *monthDay;

@property (nonatomic, copy) NSString *monthAndYear;

@property (nonatomic, copy) NSString *weekday;

- (void)createLayers;


- (CATextLayer *)_setupMonthDayLayer;

- (CATextLayer *)_setupMonthAndYearLayer;

- (CATextLayer *)_setupWeekdayLayer;

@end

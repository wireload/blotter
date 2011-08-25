//
//  WLCalendarDateView.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WLCalendarTextLayer.h"


@interface WLCalendarDateView : NSView /*<CALayoutManager>*/{
    WLCalendarTextLayer *_monthDayLayer;
    WLCalendarTextLayer *_monthAndYearLayer;
    WLCalendarTextLayer *_weekdayLayer;
}

@property (nonatomic, copy) NSString *monthDay;

@property (nonatomic, copy) NSString *monthAndYear;

@property (nonatomic, copy) NSString *weekday;

- (void)createLayers;


- (WLCalendarTextLayer *)_setupMonthDayLayer;

- (WLCalendarTextLayer *)_setupMonthAndYearLayer;

- (WLCalendarTextLayer *)_setupWeekdayLayer;

@end

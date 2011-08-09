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


@interface WLCalendarDateView : NSView {
    BLSize fontSize;

    CATextLayer *_monthDayLayer;
    CATextLayer *_monthAndYearLayer;
    CATextLayer *_weekdayLayer;
}

@property (nonatomic) BLSize fontSize;

@property (nonatomic, copy) NSString *monthDay;

@property (nonatomic, copy) NSString *monthAndYear;

@property (nonatomic, copy) NSString *weekday;

- (void)setupLayersAnimated:(BOOL)isAnimated;


- (CALayer *)_setupRootLayer;

- (CATextLayer *)_setupMonthDayLayer;

- (CATextLayer *)_setupMonthAndYearLayer;

- (CATextLayer *)_setupWeekdayLayer;

- (void)_setFontSize:(BLSize)newFontSize;

@end

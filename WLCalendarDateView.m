//
//  WLCalendarDateView.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarDateView.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarDateView
@dynamic monthDay;
@dynamic monthAndYear;
@dynamic weekday;

- (void)setupLayersAnimated:(BOOL)isAnimated
{
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    CALayer *root = [self _setupRootLayer];
    root.layoutManager = self;
    _monthDayLayer = [self _setupMonthDayLayer];
    [root addSublayer:_monthDayLayer];
    _monthAndYearLayer = [self _setupMonthAndYearLayer];
    [root addSublayer:_monthAndYearLayer];
    _weekdayLayer = [self _setupWeekdayLayer];
    [root addSublayer:_weekdayLayer];
    [self setLayer:root];
    [self setWantsLayer:YES];
    [CATransaction commit];
}

- (NSString *)monthDay
{
    return _monthDayLayer.string;
}

- (void)setMonthDay:(NSString *)newMonthDay
{
    _monthDayLayer.string = newMonthDay;
}

- (NSString *)monthAndYear
{
    return _monthAndYearLayer.string;
}

- (void)setMonthAndYear:(NSString *)newMonthAndYear
{
    _monthAndYearLayer.string = newMonthAndYear;
}

- (NSString *)weekday
{
    return _weekdayLayer.string;
}

- (void)setWeekday:(NSString *)newWeekday
{
    _weekdayLayer.string = newWeekday;
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    static const CGFloat YPaddingBetweenLayers = 5.0f;

    CGFloat w = aLayer.bounds.size.width;
    _monthDayLayer.frame = CGRectIntegral(CGRectMake(0.0f, 0.0f, w, 130.0f));

    _monthAndYearLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMaxY(_monthDayLayer.frame) + YPaddingBetweenLayers, w, 24.0f));

    _weekdayLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMaxY(_monthAndYearLayer.frame) + YPaddingBetweenLayers, w, 24.0f));
}


#pragma mark Private

- (CALayer *)_setupRootLayer
{
    CALayer *l = [CALayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.geometryFlipped = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif
    }];
    return l;
}

- (CATextLayer *)_setupMonthDayLayer
{
    CATextLayer *l = [CATextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.fontSize = 144.0f;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}

- (CATextLayer *)_setupMonthAndYearLayer
{
    CATextLayer *l = [CATextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.fontSize = 24.0f;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}

- (CATextLayer *)_setupWeekdayLayer
{
    CATextLayer *l = [CATextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.fontSize = 24.0f;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}

@end

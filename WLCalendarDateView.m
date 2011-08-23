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

- (void)createLayers
{
    [self setWantsLayer:YES];
    CALayer *root = [self layer];
    _monthDayLayer = [self _setupMonthDayLayer];
    [root addSublayer:_monthDayLayer];
    _monthAndYearLayer = [self _setupMonthAndYearLayer];
    [root addSublayer:_monthAndYearLayer];
    _weekdayLayer = [self _setupWeekdayLayer];
    [root addSublayer:_weekdayLayer];
}

- (NSString *)monthDay
{
    return _monthDayLayer.string;
}

- (void)setMonthDay:(NSString *)newMonthDay
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");
    _monthDayLayer.string = newMonthDay;
}

- (NSString *)monthAndYear
{
    return _monthAndYearLayer.string;
}

- (void)setMonthAndYear:(NSString *)newMonthAndYear
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");
    _monthAndYearLayer.string = newMonthAndYear;
}

- (NSString *)weekday
{
    return _weekdayLayer.string;
}

- (void)setWeekday:(NSString *)newWeekday
{
    NSAssert([self wantsLayer], @"You MUST call -createLayers before.");
    _weekdayLayer.string = newWeekday;
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    static const CGFloat YPaddingBetweenLayers = 5.0f;

    CGFloat w = aLayer.bounds.size.width;
    _monthDayLayer.frame = CGRectIntegral(CGRectMake(0.0f, NSMaxY([self bounds]) - 170.0f, w, 170.0f));
    _monthAndYearLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMinY(_monthDayLayer.frame) - YPaddingBetweenLayers - 26.0f, w, 26.0f));
    _weekdayLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMinY(_monthAndYearLayer.frame) - YPaddingBetweenLayers - 26.0f, w, 26.0f));
}


#pragma mark Private

- (CATextLayer *)_setupMonthDayLayer
{
    CATextLayer *l = [CATextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.fontSize = 200.0f;
        l.font = [NSFont fontWithName:@"Helvetica" size:200.0f];
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
        l.fontSize = 26.0f;
        l.font = [NSFont fontWithName:@"Helvetica" size:26.0f];
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
        l.fontSize = 26.0f;
        l.font = [NSFont fontWithName:@"Helvetica" size:26.0f];
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}


#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

@end

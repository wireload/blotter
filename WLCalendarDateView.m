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
#import "NSColor+WLCalendar.h"


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
    CGSize preferredSize = [_monthDayLayer preferredFrameSize];
    _monthDayLayer.frame = CGRectIntegral(CGRectMake(0.0f, 0.0f, w, 170));
    preferredSize = [_monthAndYearLayer preferredFrameSize];
    _monthAndYearLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMaxY(_monthDayLayer.frame) + YPaddingBetweenLayers, w, preferredSize.height));
    preferredSize = [_monthAndYearLayer preferredFrameSize];
    _weekdayLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMaxY(_monthAndYearLayer.frame) + YPaddingBetweenLayers, w, preferredSize.height));
}


#pragma mark Private

- (WLCalendarTextLayer *)_setupMonthDayLayer
{
    WLCalendarTextLayer *l = [WLCalendarTextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.font =  (CTFontRef)[(id)CTFontCreateWithName(CFSTR("Helvetica"), 200.0f, nil) autorelease];
        l.stringShadowColor = [[NSColor WL_dateShadowColor] WL_CGColor];
        l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}

- (WLCalendarTextLayer *)_setupMonthAndYearLayer
{
    WLCalendarTextLayer *l = [WLCalendarTextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.font = (CTFontRef)[(id)CTFontCreateWithName(CFSTR("Helvetica"), 26.0f, nil) autorelease];
        l.stringShadowColor = [[NSColor WL_dateShadowColor] WL_CGColor];
        l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}

- (WLCalendarTextLayer *)_setupWeekdayLayer
{
    WLCalendarTextLayer *l = [WLCalendarTextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.foregroundColor = [[NSColor whiteColor] WL_CGColor];
        l.alignmentMode = kCAAlignmentCenter;
        l.font = (CTFontRef)[(id)CTFontCreateWithName(CFSTR("Helvetica"), 26.0f, nil) autorelease];
        l.stringShadowColor = [[NSColor WL_dateShadowColor] WL_CGColor];
        l.needsDisplayOnBoundsChange = YES;
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

- (CALayer *)makeBackingLayer
{
    CALayer *l = [super makeBackingLayer];
    [CATransaction WL_performWithDisabledActions:^{
        l.delegate = self;
        l.geometryFlipped = YES;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    }];
    return l;
}

@end

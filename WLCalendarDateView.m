//
//  WLCalendarDateView.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarDateView.h"
#import "CATextLayer+WLStringSize.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarDateView
@synthesize fontSize;
@dynamic monthDay;
@dynamic monthAndYear;
@dynamic weekday;

- (void)setupLayersAnimated:(BOOL)isAnimated
{
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    CALayer *root = [self _setupRootLayer];
    _monthDayLayer = [self _setupMonthDayLayer];
    [root addSublayer:_monthDayLayer];
    _monthAndYearLayer = [self _setupMonthAndYearLayer];
    [root addSublayer:_monthAndYearLayer];
    _weekdayLayer = [self _setupWeekdayLayer];
    [root addSublayer:_weekdayLayer];
    [self setLayer:root];
    [self setWantsLayer:YES];
    [self _setFontSize:fontSize];
    [CATransaction commit];
}

- (void)setFontSize:(BLSize)newFontSize
{
    if (fontSize != newFontSize)
        [self _setFontSize:newFontSize];
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
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}

- (void)_setFontSize:(BLSize)newFontSize
{
    fontSize = newFontSize;
    [CATransaction WL_performWithDisabledActions:^{
        switch (fontSize) {
            case BLNarrowSize:
                _monthDayLayer.fontSize = 36.0f;
                _monthAndYearLayer.fontSize = 12.0f;
                _weekdayLayer.fontSize = 12.0f;
                break;
            case BLNormalSize:
            case BLFullSize:
                _monthDayLayer.fontSize = 144.0f;
                _monthAndYearLayer.fontSize = 24.0f;
                _weekdayLayer.fontSize = 24.0f;
                break;
        }

        static const CGFloat YPaddingBetweenLayers = 5.0f;

        CGFloat w = [self layer].bounds.size.width;
        CGFloat h = [_monthDayLayer WL_maxStringHeightForWidth:w];
        _monthDayLayer.frame = CGRectIntegral(CGRectMake(0.0f, 0.0f, w, h));

        h = [_monthAndYearLayer WL_maxStringHeightForWidth:w];
        _monthAndYearLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMaxY(_monthDayLayer.frame) + YPaddingBetweenLayers, w, h));

        h = [_weekdayLayer WL_maxStringHeightForWidth:w];
        _weekdayLayer.frame = CGRectIntegral(CGRectMake(0.0f, CGRectGetMaxY(_monthAndYearLayer.frame) + YPaddingBetweenLayers, w, h));
    }];
}

@end

//
//  WLCalendarTimeIndicatorLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 03.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLCalendarTimeIndicatorLayer.h"
#import "NSColor+WLCalendar.h"


@implementation WLCalendarTimeIndicatorLayer
@dynamic color;

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"color"])
        return (id)[[NSColor WL_timelineLineColor] CGColor];
    else if ([aKey isEqualToString:@"needsDisplayOnBoundsChange"])
        return @(YES);
    else
        return [super defaultValueForKey:aKey];
}

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"color"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);

    CGContextSetShadowWithColor(aContext, CGSizeMake(0.0,  -1.0), 0, [[NSColor WL_timelineLineShadowColor] CGColor]);

    static const CGFloat lengths[] = { 3.0, 3.0 };
    CGContextSetLineDash(aContext, 0, lengths, sizeof(lengths) / sizeof(CGFloat));
    CGContextSetLineWidth(aContext, 1.0);
    CGContextSetAllowsAntialiasing(aContext, NO);
    CGContextMoveToPoint(aContext, CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - 1.0);
    CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - 1.0);
    CGContextSetStrokeColorWithColor(aContext, self.color);
    CGContextStrokePath(aContext);
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    return CGSizeMake(self.frame.size.width, 2.0);
}

@end

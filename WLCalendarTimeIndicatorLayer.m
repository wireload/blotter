//
//  WLCalendarTimeIndicatorLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 03.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTimeIndicatorLayer.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarTimeIndicatorLayer
@dynamic color;

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"color"])
        return (id)[[NSColor blackColor] WL_CGColor];
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
    static const CGFloat lengths[] = {10.0f, 2.0f};
    CGContextSetLineDash(aContext, 0, lengths, sizeof(lengths) / sizeof(float));
    CGContextMoveToPoint(aContext, CGRectGetMinX(self.bounds), CGRectGetMidY(self.bounds));
    CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMidY(self.bounds));
    CGContextSetStrokeColorWithColor(aContext, self.color);
    CGContextStrokePath(aContext);
    CGContextRestoreGState(aContext);
}

@end
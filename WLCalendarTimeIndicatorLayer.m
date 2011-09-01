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
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    CGContextSaveGState(aContext);
    
    CGContextSetShadow(aContext, CGSizeMake(0.0f,  -1.0f), 5);
    
    CGContextSetLineWidth(aContext, 1.0f);
    CGContextMoveToPoint(aContext, CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds));
    CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
    CGContextSetStrokeColorWithColor(aContext, self.color);
    CGContextStrokePath(aContext);
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    return CGSizeMake(self.frame.size.width, 2.0f);
}

@end
